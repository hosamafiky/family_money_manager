/// Expense workflow DB tests (Phase 3B §10).
///
/// Uses real AppDatabase.forTesting() + DriftLedgerRepository.
///
/// Tests:
///  1. Valid expense → debit entry + operation + context created.
///  2. Amount 0 rejected at domain params level.
///  3. Archived account rejected.
///  4. Insufficient funds rejected.
///  5. Cross-household account rejected.
///  6. is_recurring stored correctly.
///  7. Protected account requires audit (MissingProtectedWithdrawalAuditError).
///  8. Protected audit written atomically with operation.
///  9. Concurrent overspending simulation: only ONE of two sequential
///     expense operations succeeds after the first drains the balance.
/// 10. Idempotent retry: same operation ID → alreadyExists, no duplicate debit.
/// 11. Conflicting retry: same idempotency key, different operation ID → conflict.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
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

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftBalanceRepository balanceRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    balanceRepo = DriftBalanceRepository(db);
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('hh-exp', 'Expense HH', 'user-1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<String> createAccount({
    String suffix = '1',
    bool isProtected = false,
    AccountOwnerType ownerType = AccountOwnerType.user,
    FinancialAccountType type = FinancialAccountType.personalCashWallet,
    String householdId = 'hh-exp',
  }) async {
    final id = 'acc-exp-$suffix';
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Account $suffix',
        type: type,
        ownerType: ownerType,
        fundPurpose: type == FinancialAccountType.childProtectedFund
            ? FundPurpose.childProtected
            : FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: isProtected,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'user-1',
      ),
    );
    return id;
  }

  Future<void> fund(String accountId, int amount) => ledgerRepo.recordIncome(
    RecordIncomeParams(
      operationId: 'op-fund-${accountId.hashCode}',
      householdId: 'hh-exp',
      destinationAccountId: accountId,
      amountMinorUnits: amount,
      currencyCode: 'EGP',
      effectiveDate: '2024-01-01',
      createdBy: 'user-1',
    ),
  );

  ChildWithdrawalAuditParams makeAudit({
    required String operationId,
    required String accountId,
    int amount = 3000,
  }) => ChildWithdrawalAuditParams(
    auditId: 'audit-${operationId.hashCode.abs()}',
    operationId: operationId,
    householdId: 'hh-exp',
    accountId: accountId,
    amountMinorUnits: amount,
    reason: 'School fees',
    beneficiary: HouseholdMemberRole.child,
    confirmedAt: DateTime.utc(2024, 6, 1, 12),
    confirmedBy: 'user-1',
    warningShown: true,
  );

  group('Expense persistence', () {
    test(
      '1: valid expense → debit entry, operation, context created',
      () async {
        final acc = await createAccount(suffix: 't1');
        await fund(acc, 20000);

        final result = await ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-exp-t1',
            householdId: 'hh-exp',
            sourceAccountId: acc,
            amountMinorUnits: 5000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );
        expect(result, IdempotentOperationResult.created);

        // Operation row.
        final opRows = await db
            .customSelect("SELECT type FROM operations WHERE id = 'op-exp-t1'")
            .get();
        expect(opRows.length, 1);
        expect(opRows.first.read<String>('type'), 'expense');

        // Debit entry.
        final entryRows = await db
            .customSelect(
              "SELECT direction, amount_minor_units FROM ledger_entries "
              "WHERE operation_id = 'op-exp-t1'",
            )
            .get();
        expect(entryRows.length, 1);
        expect(entryRows.first.read<String>('direction'), 'debit');
        expect(entryRows.first.read<int>('amount_minor_units'), 5000);

        // Context row.
        final ctxRows = await db
            .customSelect(
              "SELECT operation_id FROM operation_contexts "
              "WHERE operation_id = 'op-exp-t1'",
            )
            .get();
        expect(ctxRows.length, 1);

        final balance = await balanceRepo.currentBalanceMinorUnits(
          accountId: acc,
          householdId: 'hh-exp',
        );
        expect(balance, 15000);
      },
    );

    test('2: amount 0 rejected at domain params level', () {
      expect(
        () => RecordExpenseParams(
          operationId: 'op-exp-t2',
          householdId: 'hh-exp',
          sourceAccountId: 'acc-exp-t2',
          amountMinorUnits: 0,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('3: archived account rejected with ArchivedAccountError', () async {
      final acc = await createAccount(suffix: 't3');
      await fund(acc, 10000);
      await db.customStatement(
        "UPDATE financial_accounts SET is_archived = 1 WHERE id = '$acc'",
      );

      await expectLater(
        ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-exp-t3',
            householdId: 'hh-exp',
            sourceAccountId: acc,
            amountMinorUnits: 1000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        ),
        throwsA(isA<ArchivedAccountError>()),
      );
    });

    test(
      '4: insufficient funds rejected with InsufficientFundsError',
      () async {
        final acc = await createAccount(suffix: 't4');
        await fund(acc, 1000);

        await expectLater(
          ledgerRepo.recordExpense(
            RecordExpenseParams(
              operationId: 'op-exp-t4',
              householdId: 'hh-exp',
              sourceAccountId: acc,
              amountMinorUnits: 5000, // more than the 1000 balance
              currencyCode: 'EGP',
              effectiveDate: '2024-01-02',
              createdBy: 'user-1',
            ),
          ),
          throwsA(isA<InsufficientFundsError>()),
        );
      },
    );

    test('5: cross-household account rejected', () async {
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('hh-exp-other', 'Other', 'user-1', '2024-01-01', '2024-01-01')",
      );
      final acc = await createAccount(
        suffix: 't5',
        householdId: 'hh-exp-other',
      );

      // Try to fund from hh-exp (wrong household).
      await expectLater(
        ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-exp-t5',
            householdId: 'hh-exp',
            sourceAccountId: acc, // belongs to hh-exp-other
            amountMinorUnits: 100,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('6: is_recurring stored correctly in operation_contexts', () async {
      final acc = await createAccount(suffix: 't6');
      await fund(acc, 10000);

      await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-exp-t6',
          householdId: 'hh-exp',
          sourceAccountId: acc,
          amountMinorUnits: 500,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
          isRecurring: true,
        ),
      );

      final ctxRows = await db
          .customSelect(
            "SELECT is_recurring, recurring_note FROM operation_contexts "
            "WHERE operation_id = 'op-exp-t6'",
          )
          .get();
      expect(ctxRows.length, 1);
      expect(ctxRows.first.read<bool>('is_recurring'), isTrue);
      expect(
        ctxRows.first.read<String?>('recurring_note'),
        'recurring_marker_not_scheduled',
      );
    });

    test(
      '7: protected account requires audit (MissingProtectedWithdrawalAuditError)',
      () async {
        final acc = await createAccount(
          suffix: 't7',
          ownerType: AccountOwnerType.child,
          type: FinancialAccountType.childProtectedFund,
        );
        await fund(acc, 20000);

        await expectLater(
          ledgerRepo.recordExpense(
            RecordExpenseParams(
              operationId: 'op-exp-t7',
              householdId: 'hh-exp',
              sourceAccountId: acc,
              amountMinorUnits: 3000,
              currencyCode: 'EGP',
              effectiveDate: '2024-01-02',
              createdBy: 'user-1',
            ),
          ),
          throwsA(isA<MissingProtectedWithdrawalAuditError>()),
        );
      },
    );

    test('8: protected audit written atomically with operation', () async {
      final acc = await createAccount(
        suffix: 't8',
        ownerType: AccountOwnerType.child,
        type: FinancialAccountType.childProtectedFund,
      );
      await fund(acc, 20000);

      const opId = 'op-exp-t8';
      await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: opId,
          householdId: 'hh-exp',
          sourceAccountId: acc,
          amountMinorUnits: 3000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
        auditParams: makeAudit(operationId: opId, accountId: acc),
      );

      // Both the operation and its audit must exist.
      final opRows = await db
          .customSelect("SELECT id FROM operations WHERE id = '$opId'")
          .get();
      expect(opRows.length, 1);

      final auditRows = await db
          .customSelect(
            "SELECT id FROM child_withdrawal_audits WHERE operation_id = '$opId'",
          )
          .get();
      expect(auditRows.length, 1);
    });

    test('9: concurrent overspending — only first expense succeeds after '
        'balance is drained', () async {
      final acc = await createAccount(suffix: 't9');
      await fund(acc, 5000);

      // First expense succeeds (5000 balance available).
      final r1 = await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-exp-t9a',
          householdId: 'hh-exp',
          sourceAccountId: acc,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
      );
      expect(r1, IdempotentOperationResult.created);

      // Second expense fails — balance is now 0.
      await expectLater(
        ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-exp-t9b',
            householdId: 'hh-exp',
            sourceAccountId: acc,
            amountMinorUnits: 1,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        ),
        throwsA(isA<InsufficientFundsError>()),
      );

      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: acc,
        householdId: 'hh-exp',
      );
      expect(balance, 0);
    });

    test(
      '10: idempotent retry — same operation ID → alreadyExists, no duplicate debit',
      () async {
        final acc = await createAccount(suffix: 't10');
        await fund(acc, 10000);

        const opId = 'op-exp-t10';
        final r1 = await ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: opId,
            householdId: 'hh-exp',
            sourceAccountId: acc,
            amountMinorUnits: 2000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );
        expect(r1, IdempotentOperationResult.created);

        final r2 = await ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: opId,
            householdId: 'hh-exp',
            sourceAccountId: acc,
            amountMinorUnits: 2000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );
        expect(r2, IdempotentOperationResult.alreadyExists);

        final balance = await balanceRepo.currentBalanceMinorUnits(
          accountId: acc,
          householdId: 'hh-exp',
        );
        expect(balance, 8000); // 10000 - 2000 (only once)
      },
    );

    test(
      '11: same idempotency key, different operation ID — equivalent → alreadyExists; conflict on amount',
      () async {
        final acc = await createAccount(suffix: 't11');
        await fund(acc, 10000);
        const idemKey = 'exp-idem-key-t11';

        await ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-exp-t11a',
            idempotencyKey: idemKey,
            householdId: 'hh-exp',
            sourceAccountId: acc,
            amountMinorUnits: 1000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );

        final r2 = await ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-exp-t11b',
            idempotencyKey: idemKey,
            householdId: 'hh-exp',
            sourceAccountId: acc,
            amountMinorUnits: 1000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );
        expect(r2, IdempotentOperationResult.alreadyExists);

        final r3 = await ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-exp-t11c',
            idempotencyKey: idemKey,
            householdId: 'hh-exp',
            sourceAccountId: acc,
            amountMinorUnits: 1500,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );
        expect(r3, IdempotentOperationResult.conflict);
      },
    );
  });
}
