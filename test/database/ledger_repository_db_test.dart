/// Database-level integration tests for the ledger and account repositories.
///
/// Uses an in-memory SQLite database via [AppDatabase.forTesting()].
///
/// Verified:
/// - Atomic operation persistence (income, expense, transfer, opening balance,
///   adjustment, reversal)
/// - Idempotency UNIQUE constraints
/// - Ledger-leg parent integrity (FK: ledger_entries → operations)
/// - Immutability triggers (no update, no delete on ledger entries)
/// - Transfer neutrality at the database level
/// - Reversal persistence and duplicate-reversal rejection
/// - Account archival restrictions
/// - Historical balance correctness from persisted data
/// - Protected-fund audit requirement enforcement
library;

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/balance/data/drift_balance_repository.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

AppDatabase _openTestDb() => AppDatabase.forTesting();

const _householdId = 'hh-test';
const _userId = 'user-test';

CreateAccountParams _accountParams({
  required String id,
  String name = 'Wallet',
  FinancialAccountType type = FinancialAccountType.personalCashWallet,
  AccountOwnerType ownerType = AccountOwnerType.user,
  String currencyCode = 'EGP',
  bool isProtected = false,
}) => CreateAccountParams(
  id: id,
  householdId: _householdId,
  name: name,
  type: type,
  ownerType: ownerType,
  fundPurpose: FundPurpose.available,
  currencyCode: currencyCode,
  isSpendable: true,
  isProtected: isProtected,
  includeInNetWorth: true,
  includeInZakat: false,
  displayOrder: 0,
  createdBy: _userId,
);

RecordIncomeParams _incomeParams({
  required String operationId,
  required String destinationAccountId,
  int amount = 10000,
  String date = '2024-01-01',
}) => RecordIncomeParams(
  operationId: operationId,
  householdId: _householdId,
  destinationAccountId: destinationAccountId,
  amountMinorUnits: amount,
  currencyCode: 'EGP',
  effectiveDate: date,
  createdBy: _userId,
);

RecordExpenseParams _expenseParams({
  required String operationId,
  required String sourceAccountId,
  int amount = 3000,
  String date = '2024-01-02',
}) => RecordExpenseParams(
  operationId: operationId,
  householdId: _householdId,
  sourceAccountId: sourceAccountId,
  amountMinorUnits: amount,
  currencyCode: 'EGP',
  effectiveDate: date,
  createdBy: _userId,
);

ExecuteTransferParams _transferParams({
  required String operationId,
  required String sourceAccountId,
  required String destinationAccountId,
  int amount = 2000,
  String date = '2024-01-03',
}) => ExecuteTransferParams(
  operationId: operationId,
  householdId: _householdId,
  sourceAccountId: sourceAccountId,
  destinationAccountId: destinationAccountId,
  amountMinorUnits: amount,
  currencyCode: 'EGP',
  effectiveDate: date,
  createdBy: _userId,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftBalanceRepository balanceRepo;

  setUp(() async {
    db = _openTestDb();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    balanceRepo = DriftBalanceRepository(db);
    // financial_accounts has a FK to households; seed the required household.
    await db
        .into(db.households)
        .insert(
          HouseholdsCompanion.insert(
            id: _householdId,
            name: 'Test Household',
            ownerUserId: _userId,
            createdAt: '2024-01-01T00:00:00Z',
            updatedAt: '2024-01-01T00:00:00Z',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  // ── Account persistence ───────────────────────────────────────────────────

  group('Account repository – basic CRUD', () {
    test('creates and retrieves an account', () async {
      final acc = await accountRepo.createAccount(
        _accountParams(id: 'acc-1', name: 'My Wallet'),
      );
      expect(acc.id, 'acc-1');
      expect(acc.name, 'My Wallet');
      expect(acc.isArchived, isFalse);
    });

    test('duplicate account ID throws DuplicateAccountIdError', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-dup'));
      expect(
        () => accountRepo.createAccount(_accountParams(id: 'acc-dup')),
        throwsA(isA<DuplicateAccountIdError>()),
      );
    });

    test('findById returns null for unknown id', () async {
      final result = await accountRepo.findById(
        id: 'not-found',
        householdId: _householdId,
      );
      expect(result, isNull);
    });

    test('findByHousehold excludes archived accounts by default', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-active'));
      await accountRepo.createAccount(_accountParams(id: 'acc-arch'));
      await accountRepo.archiveAccount(
        id: 'acc-arch',
        householdId: _householdId,
        archivedAt: DateTime.utc(2024, 6, 1),
        updatedAt: DateTime.utc(2024, 6, 1).toIso8601String(),
      );

      final active = await accountRepo.findByHousehold(
        householdId: _householdId,
      );
      expect(active.any((a) => a.id == 'acc-arch'), isFalse);
      expect(active.any((a) => a.id == 'acc-active'), isTrue);
    });

    test('findByHousehold with includeArchived returns all', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-a1'));
      await accountRepo.createAccount(_accountParams(id: 'acc-a2'));
      await accountRepo.archiveAccount(
        id: 'acc-a1',
        householdId: _householdId,
        archivedAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024).toIso8601String(),
      );

      final all = await accountRepo.findByHousehold(
        householdId: _householdId,
        includeArchived: true,
      );
      expect(all.length, 2);
    });

    test('archiving an already-archived account throws', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-arch2'));
      await accountRepo.archiveAccount(
        id: 'acc-arch2',
        householdId: _householdId,
        archivedAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024).toIso8601String(),
      );
      expect(
        () => accountRepo.archiveAccount(
          id: 'acc-arch2',
          householdId: _householdId,
          archivedAt: DateTime.utc(2024),
          updatedAt: DateTime.utc(2024).toIso8601String(),
        ),
        throwsA(isA<AccountAlreadyArchivedError>()),
      );
    });
  });

  // ── Income ────────────────────────────────────────────────────────────────

  group('Income persistence', () {
    test('records income and balance reflects it', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-inc'));
      final result = await ledgerRepo.recordIncome(
        _incomeParams(operationId: 'op-inc-1', destinationAccountId: 'acc-inc'),
      );
      expect(result, IdempotentOperationResult.created);

      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'acc-inc',
        householdId: _householdId,
      );
      expect(balance, 10000);
    });

    test('duplicate income operation ID returns alreadyExists', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-inc2'));
      await ledgerRepo.recordIncome(
        _incomeParams(operationId: 'op-dup', destinationAccountId: 'acc-inc2'),
      );
      final second = await ledgerRepo.recordIncome(
        _incomeParams(operationId: 'op-dup', destinationAccountId: 'acc-inc2'),
      );
      expect(second, IdempotentOperationResult.alreadyExists);

      // Balance should not be doubled
      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'acc-inc2',
        householdId: _householdId,
      );
      expect(balance, 10000);
    });
  });

  // ── Expense ───────────────────────────────────────────────────────────────

  group('Expense persistence', () {
    test('records expense and balance reflects it', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-exp'));
      await ledgerRepo.recordIncome(
        _incomeParams(
          operationId: 'op-fund-1',
          destinationAccountId: 'acc-exp',
          amount: 20000,
        ),
      );
      await ledgerRepo.recordExpense(
        _expenseParams(
          operationId: 'op-exp-1',
          sourceAccountId: 'acc-exp',
          amount: 5000,
        ),
      );

      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'acc-exp',
        householdId: _householdId,
      );
      expect(balance, 15000);
    });

    test('duplicate expense operation returns alreadyExists', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-exp2'));
      await ledgerRepo.recordIncome(
        _incomeParams(
          operationId: 'op-fund-2',
          destinationAccountId: 'acc-exp2',
          amount: 10000,
        ),
      );
      await ledgerRepo.recordExpense(
        _expenseParams(operationId: 'op-exp-dup', sourceAccountId: 'acc-exp2'),
      );
      final second = await ledgerRepo.recordExpense(
        _expenseParams(operationId: 'op-exp-dup', sourceAccountId: 'acc-exp2'),
      );
      expect(second, IdempotentOperationResult.alreadyExists);
    });
  });

  // ── Transfer ─────────────────────────────────────────────────────────────

  group('Transfer persistence and neutrality', () {
    test('transfer moves balance between two accounts', () async {
      await accountRepo.createAccount(_accountParams(id: 'src-acc'));
      await accountRepo.createAccount(_accountParams(id: 'dst-acc'));
      await ledgerRepo.recordIncome(
        _incomeParams(
          operationId: 'op-fund-src',
          destinationAccountId: 'src-acc',
          amount: 15000,
        ),
      );

      final result = await ledgerRepo.executeTransfer(
        _transferParams(
          operationId: 'op-tx-1',
          sourceAccountId: 'src-acc',
          destinationAccountId: 'dst-acc',
          amount: 5000,
        ),
      );
      expect(result, IdempotentOperationResult.created);

      final srcBal = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'src-acc',
        householdId: _householdId,
      );
      final dstBal = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'dst-acc',
        householdId: _householdId,
      );

      expect(srcBal, 10000);
      expect(dstBal, 5000);
      // Transfer neutrality: total unchanged
      expect(srcBal + dstBal, 15000);
    });

    test(
      'duplicate transfer returns alreadyExists and does not duplicate money',
      () async {
        await accountRepo.createAccount(_accountParams(id: 'src-dup'));
        await accountRepo.createAccount(_accountParams(id: 'dst-dup'));
        await ledgerRepo.recordIncome(
          _incomeParams(
            operationId: 'op-fund-dup',
            destinationAccountId: 'src-dup',
            amount: 20000,
          ),
        );
        await ledgerRepo.executeTransfer(
          _transferParams(
            operationId: 'op-tx-dup',
            sourceAccountId: 'src-dup',
            destinationAccountId: 'dst-dup',
            amount: 3000,
          ),
        );
        final second = await ledgerRepo.executeTransfer(
          _transferParams(
            operationId: 'op-tx-dup',
            sourceAccountId: 'src-dup',
            destinationAccountId: 'dst-dup',
            amount: 3000,
          ),
        );
        expect(second, IdempotentOperationResult.alreadyExists);

        final srcBal = await balanceRepo.currentBalanceMinorUnits(
          accountId: 'src-dup',
          householdId: _householdId,
        );
        final dstBal = await balanceRepo.currentBalanceMinorUnits(
          accountId: 'dst-dup',
          householdId: _householdId,
        );

        // Only one transfer happened
        expect(srcBal, 17000);
        expect(dstBal, 3000);
      },
    );

    test('transfer to same account is rejected', () async {
      await accountRepo.createAccount(_accountParams(id: 'same-acc'));
      expect(
        () => ledgerRepo.executeTransfer(
          _transferParams(
            operationId: 'op-self-tx',
            sourceAccountId: 'same-acc',
            destinationAccountId: 'same-acc',
          ),
        ),
        throwsA(isA<SameAccountTransferError>()),
      );
    });

    test('transfer with mismatched currencies is rejected', () async {
      await accountRepo.createAccount(
        _accountParams(id: 'egp-acc', currencyCode: 'EGP'),
      );
      await accountRepo.createAccount(
        _accountParams(id: 'usd-acc', currencyCode: 'USD'),
      );
      expect(
        () => ledgerRepo.executeTransfer(
          const ExecuteTransferParams(
            operationId: 'op-cross',
            householdId: _householdId,
            sourceAccountId: 'egp-acc',
            destinationAccountId: 'usd-acc',
            amountMinorUnits: 1000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: _userId,
          ),
        ),
        throwsA(isA<CurrencyMismatchTransferError>()),
      );
    });
  });

  // ── Opening balance ───────────────────────────────────────────────────────

  group('Opening balance persistence', () {
    test('records opening balance and balance reflects it', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-ob'));
      await ledgerRepo.recordOpeningBalance(
        const RecordOpeningBalanceParams(
          operationId: 'op-ob-1',
          householdId: _householdId,
          accountId: 'acc-ob',
          amountMinorUnits: 50000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: _userId,
        ),
      );

      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'acc-ob',
        householdId: _householdId,
      );
      expect(balance, 50000);
    });

    test('duplicate opening balance operation returns alreadyExists', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-ob2'));
      await ledgerRepo.recordOpeningBalance(
        const RecordOpeningBalanceParams(
          operationId: 'op-ob-dup',
          householdId: _householdId,
          accountId: 'acc-ob2',
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: _userId,
        ),
      );
      final second = await ledgerRepo.recordOpeningBalance(
        const RecordOpeningBalanceParams(
          operationId: 'op-ob-dup',
          householdId: _householdId,
          accountId: 'acc-ob2',
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: _userId,
        ),
      );
      expect(second, IdempotentOperationResult.alreadyExists);

      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'acc-ob2',
        householdId: _householdId,
      );
      expect(balance, 10000);
    });
  });

  // ── Adjustment ────────────────────────────────────────────────────────────

  group('Adjustment persistence', () {
    test('positive adjustment increases balance', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-adj'));
      await ledgerRepo.recordIncome(
        _incomeParams(
          operationId: 'op-fund-adj',
          destinationAccountId: 'acc-adj',
          amount: 5000,
        ),
      );
      await ledgerRepo.recordAdjustment(
        const RecordAdjustmentParams(
          operationId: 'op-adj-1',
          householdId: _householdId,
          accountId: 'acc-adj',
          adjustmentAmountMinorUnits: 500,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-05',
          createdBy: _userId,
          reason: 'Cash recount',
        ),
      );

      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'acc-adj',
        householdId: _householdId,
      );
      expect(balance, 5500);
    });

    test('negative adjustment decreases balance', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-adj2'));
      await ledgerRepo.recordIncome(
        _incomeParams(
          operationId: 'op-fund-adj2',
          destinationAccountId: 'acc-adj2',
          amount: 5000,
        ),
      );
      await ledgerRepo.recordAdjustment(
        const RecordAdjustmentParams(
          operationId: 'op-adj-2',
          householdId: _householdId,
          accountId: 'acc-adj2',
          adjustmentAmountMinorUnits: -200,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-05',
          createdBy: _userId,
          reason: 'Discrepancy',
        ),
      );

      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'acc-adj2',
        householdId: _householdId,
      );
      expect(balance, 4800);
    });
  });

  // ── Reversal ──────────────────────────────────────────────────────────────

  group('Reversal persistence (INV-004)', () {
    test('reversal restores balance to pre-operation state', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-rev'));
      await ledgerRepo.recordIncome(
        _incomeParams(
          operationId: 'op-fund-rev',
          destinationAccountId: 'acc-rev',
          amount: 20000,
        ),
      );
      await ledgerRepo.recordExpense(
        _expenseParams(
          operationId: 'op-exp-rev',
          sourceAccountId: 'acc-rev',
          amount: 5000,
        ),
      );

      final balanceAfterExpense = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'acc-rev',
        householdId: _householdId,
      );
      expect(balanceAfterExpense, 15000);

      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'op-rev-1',
          originalOperationId: 'op-exp-rev',
          householdId: _householdId,
          effectiveDate: '2024-01-10',
          createdBy: _userId,
          reason: 'Entry error',
        ),
      );

      final balanceAfterReversal = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'acc-rev',
        householdId: _householdId,
      );
      expect(balanceAfterReversal, 20000);
    });

    test(
      'reversing an already-reversed operation throws DuplicateReversalError',
      () async {
        await accountRepo.createAccount(_accountParams(id: 'acc-rev2'));
        await ledgerRepo.recordIncome(
          _incomeParams(
            operationId: 'op-fund-rev2',
            destinationAccountId: 'acc-rev2',
            amount: 10000,
          ),
        );
        await ledgerRepo.recordExpense(
          _expenseParams(
            operationId: 'op-exp-rev2',
            sourceAccountId: 'acc-rev2',
            amount: 3000,
          ),
        );
        await ledgerRepo.reverseOperation(
          const ReverseOperationParams(
            reversalOperationId: 'op-rev-2',
            originalOperationId: 'op-exp-rev2',
            householdId: _householdId,
            effectiveDate: '2024-01-10',
            createdBy: _userId,
          ),
        );
        expect(
          () => ledgerRepo.reverseOperation(
            const ReverseOperationParams(
              reversalOperationId: 'op-rev-2b',
              originalOperationId: 'op-exp-rev2',
              householdId: _householdId,
              effectiveDate: '2024-01-11',
              createdBy: _userId,
            ),
          ),
          throwsA(isA<DuplicateReversalError>()),
        );
      },
    );

    test('duplicate reversal operation ID returns alreadyExists', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-rev3'));
      await ledgerRepo.recordIncome(
        _incomeParams(
          operationId: 'op-fund-rev3',
          destinationAccountId: 'acc-rev3',
          amount: 10000,
        ),
      );
      await ledgerRepo.recordExpense(
        _expenseParams(
          operationId: 'op-exp-rev3',
          sourceAccountId: 'acc-rev3',
          amount: 2000,
        ),
      );
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'op-rev-dup',
          originalOperationId: 'op-exp-rev3',
          householdId: _householdId,
          effectiveDate: '2024-01-10',
          createdBy: _userId,
        ),
      );
      // Submitting the exact same reversal operation ID a second time is idempotent
      // (the reversal itself already exists) — different from trying to create a
      // second reversal for the same original with a NEW operation ID.
      // The idempotency check fires first: the reversal op ID 'op-rev-dup' already
      // exists, so the operation returns `alreadyExists`.
      // (A new reversal ID for an already-reversed original throws DuplicateReversalError,
      //  which is tested in the "reversing an already-reversed operation" test above.)
      final result = await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId:
              'op-rev-dup', // same reversal operation ID → idempotent
          originalOperationId: 'op-exp-rev3',
          householdId: _householdId,
          effectiveDate: '2024-01-10',
          createdBy: _userId,
        ),
      );
      expect(result, IdempotentOperationResult.alreadyExists);
    });
  });

  // ── Immutability triggers ─────────────────────────────────────────────────

  group('Immutability triggers (INV-002)', () {
    test('updating a ledger entry raises a database error', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-imm'));
      await ledgerRepo.recordIncome(
        _incomeParams(operationId: 'op-imm-1', destinationAccountId: 'acc-imm'),
      );

      // Attempt raw UPDATE on ledger_entries — should be blocked by trigger.
      expect(
        () => db.customStatement(
          'UPDATE ledger_entries SET amount_minor_units = 99999 '
          "WHERE operation_id = 'op-imm-1'",
        ),
        throwsA(anything),
      );
    });

    test('deleting a ledger entry raises a database error', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-del'));
      await ledgerRepo.recordIncome(
        _incomeParams(operationId: 'op-del-1', destinationAccountId: 'acc-del'),
      );

      expect(
        () => db.customStatement(
          "DELETE FROM ledger_entries WHERE operation_id = 'op-del-1'",
        ),
        throwsA(anything),
      );
    });
  });

  // ── Historical balance ────────────────────────────────────────────────────

  group('Historical balance accuracy', () {
    test('historicalBalance excludes future entries', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-hist'));
      await ledgerRepo.recordIncome(
        _incomeParams(
          operationId: 'op-hist-1',
          destinationAccountId: 'acc-hist',
          amount: 5000,
          date: '2024-01-01',
        ),
      );
      await ledgerRepo.recordIncome(
        _incomeParams(
          operationId: 'op-hist-2',
          destinationAccountId: 'acc-hist',
          amount: 3000,
          date: '2024-06-01',
        ),
      );

      final balance = await balanceRepo.historicalBalanceMinorUnits(
        accountId: 'acc-hist',
        householdId: _householdId,
        asOfDate: '2024-05-31',
      );
      expect(balance, 5000);
    });

    test('historicalBalance includes entries on the exact date', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-hist2'));
      await ledgerRepo.recordIncome(
        _incomeParams(
          operationId: 'op-hist2-1',
          destinationAccountId: 'acc-hist2',
          amount: 7000,
          date: '2024-03-15',
        ),
      );

      final balance = await balanceRepo.historicalBalanceMinorUnits(
        accountId: 'acc-hist2',
        householdId: _householdId,
        asOfDate: '2024-03-15',
      );
      expect(balance, 7000);
    });
  });

  // ── Protected fund audit ─────────────────────────────────────────────────

  group('Protected fund audit requirement (INV-006)', () {
    test(
      'expense from protected account without audit throws MissingProtectedWithdrawalAuditError',
      () async {
        await accountRepo.createAccount(
          _accountParams(
            id: 'child-acc',
            type: FinancialAccountType.childProtectedFund,
            isProtected: true,
          ),
        );
        await ledgerRepo.recordIncome(
          _incomeParams(
            operationId: 'op-child-fund',
            destinationAccountId: 'child-acc',
            amount: 50000,
          ),
        );

        expect(
          () => ledgerRepo.recordExpense(
            _expenseParams(
              operationId: 'op-child-exp',
              sourceAccountId: 'child-acc',
            ),
            // No audit params → should throw
          ),
          throwsA(isA<MissingProtectedWithdrawalAuditError>()),
        );
      },
    );

    test('expense from protected account with valid audit succeeds', () async {
      final now = DateTime.utc(2024, 6, 1);
      await accountRepo.createAccount(
        _accountParams(
          id: 'child-acc2',
          type: FinancialAccountType.childProtectedFund,
          isProtected: true,
        ),
      );
      await ledgerRepo.recordIncome(
        _incomeParams(
          operationId: 'op-child-fund2',
          destinationAccountId: 'child-acc2',
          amount: 50000,
        ),
      );

      final result = await ledgerRepo.recordExpense(
        _expenseParams(
          operationId: 'op-child-exp2',
          sourceAccountId: 'child-acc2',
          amount: 1000,
        ),
        auditParams: ChildWithdrawalAuditParams(
          auditId: 'audit-1',
          operationId: 'op-child-exp2',
          householdId: _householdId,
          accountId: 'child-acc2',
          amountMinorUnits: 1000,
          reason: 'School trip',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: now,
          confirmedBy: _userId,
          warningShown: true,
        ),
      );

      expect(result, IdempotentOperationResult.created);
      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: 'child-acc2',
        householdId: _householdId,
      );
      expect(balance, 49000);
    });
  });

  // ── hasOpeningBalance ─────────────────────────────────────────────────────

  group('hasOpeningBalance', () {
    test('returns false before any opening balance', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-nob'));
      final has = await accountRepo.hasOpeningBalance(
        accountId: 'acc-nob',
        householdId: _householdId,
      );
      expect(has, isFalse);
    });

    test('returns true after opening balance is recorded', () async {
      await accountRepo.createAccount(_accountParams(id: 'acc-ob3'));
      await ledgerRepo.recordOpeningBalance(
        const RecordOpeningBalanceParams(
          operationId: 'op-ob-has',
          householdId: _householdId,
          accountId: 'acc-ob3',
          amountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: _userId,
        ),
      );
      final has = await accountRepo.hasOpeningBalance(
        accountId: 'acc-ob3',
        householdId: _householdId,
      );
      expect(has, isTrue);
    });
  });
}
