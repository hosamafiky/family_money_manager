/// Protected-account enforcement tests (Phase 2A §6).
///
/// Tests the net-effect rule:
/// - Any operation that reduces a protected child-owned account requires a
///   [ChildWithdrawalAuditParams] with matching operationId, accountId,
///   and householdId.
/// - Audit records with mismatched fields are rejected at the repository layer.
/// - Reversals of income into protected accounts also require audit.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
  });

  tearDown(() async => db.close());

  // ── Helpers ──────────────────────────────────────────────────────────────

  final ts = DateTime.utc(2024, 6, 1, 12);

  Future<void> insertHousehold(String id) async {
    await db.customStatement(
      'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
      "VALUES ('$id', 'HH $id', 'user-1', '2024-01-01', '2024-01-01')",
    );
  }

  Future<String> createAccount(
    String householdId, {
    String suffix = '1',
    bool isProtected = false,
    AccountOwnerType ownerType = AccountOwnerType.user,
    FinancialAccountType type = FinancialAccountType.personalCashWallet,
  }) async {
    final id = 'acc-$householdId-$suffix';
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

  ChildWithdrawalAuditParams audit({
    required String operationId,
    required String householdId,
    required String accountId,
    int amount = 3000,
  }) => ChildWithdrawalAuditParams(
    auditId: 'audit-${operationId.hashCode}',
    operationId: operationId,
    householdId: householdId,
    accountId: accountId,
    amountMinorUnits: amount,
    reason: 'School fees',
    beneficiary: HouseholdMemberRole.child,
    confirmedAt: ts,
    confirmedBy: 'user-1',
    warningShown: true,
  );

  Future<String> seedProtectedAccount(String householdId, String suffix) async {
    final accId = await createAccount(
      householdId,
      suffix: suffix,
      ownerType: AccountOwnerType.child,
      type: FinancialAccountType.childProtectedFund,
    );

    // Fund the account.
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: 'op-seed-$suffix',
        householdId: householdId,
        destinationAccountId: accId,
        amountMinorUnits: 20000,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'user-1',
      ),
    );

    return accId;
  }

  // ── Expense from protected account ────────────────────────────────────────

  group('Expense from protected account', () {
    test('without audit throws MissingProtectedWithdrawalAuditError', () async {
      await insertHousehold('hh-p1');
      final acc = await seedProtectedAccount('hh-p1', 'prot');

      await expectLater(
        ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-exp-prot',
            householdId: 'hh-p1',
            sourceAccountId: acc,
            amountMinorUnits: 3000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        ),
        throwsA(isA<MissingProtectedWithdrawalAuditError>()),
      );
    });

    test('with valid audit succeeds', () async {
      await insertHousehold('hh-p2');
      final acc = await seedProtectedAccount('hh-p2', 'prot2');

      const opId = 'op-exp-prot2';
      final result = await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: opId,
          householdId: 'hh-p2',
          sourceAccountId: acc,
          amountMinorUnits: 3000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
        auditParams: audit(
          operationId: opId,
          householdId: 'hh-p2',
          accountId: acc,
        ),
      );
      expect(result, IdempotentOperationResult.created);
    });

    test(
      'audit with mismatched operationId throws AuditOperationMismatchError',
      () async {
        await insertHousehold('hh-p3');
        final acc = await seedProtectedAccount('hh-p3', 'prot3');

        await expectLater(
          ledgerRepo.recordExpense(
            RecordExpenseParams(
              operationId: 'op-exp-prot3',
              householdId: 'hh-p3',
              sourceAccountId: acc,
              amountMinorUnits: 3000,
              currencyCode: 'EGP',
              effectiveDate: '2024-01-02',
              createdBy: 'user-1',
            ),
            auditParams: audit(
              operationId: 'WRONG_OP_ID', // mismatch
              householdId: 'hh-p3',
              accountId: acc,
            ),
          ),
          throwsA(isA<AuditOperationMismatchError>()),
        );
      },
    );

    test(
      'audit with mismatched accountId throws AuditAccountMismatchError',
      () async {
        await insertHousehold('hh-p4');
        final acc = await seedProtectedAccount('hh-p4', 'prot4');

        const opId = 'op-exp-prot4';
        await expectLater(
          ledgerRepo.recordExpense(
            RecordExpenseParams(
              operationId: opId,
              householdId: 'hh-p4',
              sourceAccountId: acc,
              amountMinorUnits: 3000,
              currencyCode: 'EGP',
              effectiveDate: '2024-01-02',
              createdBy: 'user-1',
            ),
            auditParams: audit(
              operationId: opId,
              householdId: 'hh-p4',
              accountId: 'WRONG_ACC', // mismatch
            ),
          ),
          throwsA(isA<AuditAccountMismatchError>()),
        );
      },
    );
  });

  // ── Transfer from protected account ──────────────────────────────────────

  group('Transfer from protected account', () {
    test('without audit throws MissingProtectedWithdrawalAuditError', () async {
      await insertHousehold('hh-tf1');
      final src = await seedProtectedAccount('hh-tf1', 'psrc');
      final dst = await createAccount('hh-tf1', suffix: 'dst');

      await expectLater(
        ledgerRepo.executeTransfer(
          ExecuteTransferParams(
            operationId: 'op-tf-prot',
            householdId: 'hh-tf1',
            sourceAccountId: src,
            destinationAccountId: dst,
            amountMinorUnits: 5000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        ),
        throwsA(isA<MissingProtectedWithdrawalAuditError>()),
      );
    });

    test('with valid audit succeeds', () async {
      await insertHousehold('hh-tf2');
      final src = await seedProtectedAccount('hh-tf2', 'psrc2');
      final dst = await createAccount('hh-tf2', suffix: 'dst2');

      const opId = 'op-tf-prot2';
      final result = await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: opId,
          householdId: 'hh-tf2',
          sourceAccountId: src,
          destinationAccountId: dst,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
        auditParams: audit(
          operationId: opId,
          householdId: 'hh-tf2',
          accountId: src,
          amount: 5000,
        ),
      );
      expect(result, IdempotentOperationResult.created);
    });
  });

  // ── Reversal that debits a protected account ──────────────────────────────

  group('Reversal of income into protected account', () {
    test('without audit throws MissingProtectedWithdrawalAuditError', () async {
      await insertHousehold('hh-rv1');
      final acc = await createAccount(
        'hh-rv1',
        ownerType: AccountOwnerType.child,
        type: FinancialAccountType.childProtectedFund,
      );

      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-inc-rv1',
          householdId: 'hh-rv1',
          destinationAccountId: acc,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

      // Reversing the income would DEBIT the protected account → requires audit.
      await expectLater(
        ledgerRepo.reverseOperation(
          const ReverseOperationParams(
            reversalOperationId: 'op-rev-rv1',
            originalOperationId: 'op-inc-rv1',
            householdId: 'hh-rv1',
            effectiveDate: '2024-01-05',
            createdBy: 'user-1',
          ),
        ),
        throwsA(isA<MissingProtectedWithdrawalAuditError>()),
      );
    });

    test('with valid audit succeeds', () async {
      await insertHousehold('hh-rv2');
      final acc = await createAccount(
        'hh-rv2',
        ownerType: AccountOwnerType.child,
        type: FinancialAccountType.childProtectedFund,
      );

      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-inc-rv2',
          householdId: 'hh-rv2',
          destinationAccountId: acc,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

      const revOpId = 'op-rev-rv2';
      final result = await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: revOpId,
          originalOperationId: 'op-inc-rv2',
          householdId: 'hh-rv2',
          effectiveDate: '2024-01-05',
          createdBy: 'user-1',
        ),
        auditParams: audit(
          operationId: revOpId,
          householdId: 'hh-rv2',
          accountId: acc,
          amount: 10000,
        ),
      );
      expect(result, IdempotentOperationResult.created);
    });

    test(
      'audit referencing wrong reversal operationId throws AuditOperationMismatchError',
      () async {
        await insertHousehold('hh-rv3');
        final acc = await createAccount(
          'hh-rv3',
          ownerType: AccountOwnerType.child,
          type: FinancialAccountType.childProtectedFund,
        );

        await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-inc-rv3',
            householdId: 'hh-rv3',
            destinationAccountId: acc,
            amountMinorUnits: 10000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );

        await expectLater(
          ledgerRepo.reverseOperation(
            const ReverseOperationParams(
              reversalOperationId: 'op-rev-rv3',
              originalOperationId: 'op-inc-rv3',
              householdId: 'hh-rv3',
              effectiveDate: '2024-01-05',
              createdBy: 'user-1',
            ),
            auditParams: audit(
              operationId: 'WRONG_OP', // should be 'op-rev-rv3'
              householdId: 'hh-rv3',
              accountId: acc,
            ),
          ),
          throwsA(isA<AuditOperationMismatchError>()),
        );
      },
    );
  });

  // ── Non-protected account: no audit required ──────────────────────────────

  group('Non-protected account: no audit required', () {
    test('expense without audit succeeds for non-protected account', () async {
      await insertHousehold('hh-np1');
      final acc = await createAccount('hh-np1');

      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-seed-np',
          householdId: 'hh-np1',
          destinationAccountId: acc,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

      final result = await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-exp-np',
          householdId: 'hh-np1',
          sourceAccountId: acc,
          amountMinorUnits: 2000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
      );
      expect(result, IdempotentOperationResult.created);
    });
  });
}
