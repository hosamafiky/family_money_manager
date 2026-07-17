/// Protected funds report DB tests (Phase 4B).
///
/// Tests:
/// 1. Funding counted (income into protected account)
/// 2. Withdrawal counted with audit reason
/// 3. Beneficiary recorded in audit
/// 4. Reversal of withdrawal counted
/// 5. Closing balance reconciles
/// 6. Current vs period balance distinct
/// 7. Child fund separate from other protected
/// 8. Household isolation
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/reports/data/drift_report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-pf';
const _hh2 = 'hh-pf-2';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftReportQueryRepository reportRepo;

  final ts = DateTime.utc(2024, 6, 1, 12);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    reportRepo = DriftReportQueryRepository(db);

    for (final h in [_hh, _hh2]) {
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('$h', 'PF HH $h', 'u1', '2024-01-01', '2024-01-01')",
      );
    }
  });

  tearDown(() async => db.close());

  Future<String> createProtectedAccount(
    String id, {
    String householdId = _hh,
    String type = 'childProtectedFund',
  }) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Protected Fund $id',
        type: FinancialAccountType.fromCode(type),
        ownerType: AccountOwnerType.child,
        fundPurpose: FundPurpose.childProtected,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: true,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'test',
      ),
    );
    return id;
  }

  Future<void> fund(
    String accId,
    String opId,
    int amount,
    String date, {
    String householdId = _hh,
  }) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: opId,
        householdId: householdId,
        destinationAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  ChildWithdrawalAuditParams makeAudit({
    required String opId,
    required String accId,
    required int amount,
    String reason = 'School fees',
    String householdId = _hh,
    HouseholdMemberRole beneficiary = HouseholdMemberRole.child,
  }) => ChildWithdrawalAuditParams(
    auditId: 'audit-$opId',
    operationId: opId,
    householdId: householdId,
    accountId: accId,
    amountMinorUnits: amount,
    reason: reason,
    beneficiary: beneficiary,
    confirmedAt: ts,
    confirmedBy: 'test',
    warningShown: true,
  );

  Future<void> withdraw(
    String accId,
    String opId,
    int amount,
    String date, {
    String reason = 'School fees',
    String householdId = _hh,
  }) async {
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: opId,
        householdId: householdId,
        sourceAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: date,
        createdBy: 'test',
      ),
      auditParams: makeAudit(
        opId: opId,
        accId: accId,
        amount: amount,
        reason: reason,
        householdId: householdId,
      ),
    );
  }

  FinancialReportRequest req(String start, String end, {String householdId = _hh}) {
    return FinancialReportRequest(
      householdId: householdId,
      period: DashboardPeriod.custom(startDate: start, endDate: end),
    );
  }

  group('report_protected_funds_db', () {
    test('1. Funding counted (income into protected account)', () async {
      final acc = await createProtectedAccount('pf-1');
      await fund(acc, 'op-pf-1-fund', 10000, '2025-01-05');

      final result = await reportRepo.protectedFundsReports(req('2025-01-01', '2025-02-01'));
      final summary = result.firstWhere((r) => r.accountId == acc);
      expect(summary.fundingMinorUnits, 10000);
    });

    test('2. Withdrawal counted with audit reason', () async {
      final acc = await createProtectedAccount('pf-2');
      await fund(acc, 'op-pf-2-fund', 15000, '2025-01-01');
      await withdraw(acc, 'op-pf-2-wd', 3000, '2025-01-15', reason: 'Medical expenses');

      final result = await reportRepo.protectedFundsReports(req('2025-01-01', '2025-02-01'));
      final summary = result.firstWhere((r) => r.accountId == acc);
      expect(summary.withdrawalMinorUnits, 3000);
      expect(summary.withdrawalAudits.isNotEmpty, isTrue);
      expect(summary.withdrawalAudits.first.reason, 'Medical expenses');
    });

    test('3. Beneficiary recorded in audit', () async {
      final acc = await createProtectedAccount('pf-3');
      await fund(acc, 'op-pf-3-fund', 15000, '2025-01-01');
      await withdraw(acc, 'op-pf-3-wd', 2000, '2025-01-10');

      final result = await reportRepo.protectedFundsReports(req('2025-01-01', '2025-02-01'));
      final summary = result.firstWhere((r) => r.accountId == acc);
      expect(
        summary.withdrawalAudits.first.beneficiaryMemberId.isNotEmpty,
        isTrue,
        reason: 'Beneficiary role stored in audit',
      );
    });

    test('4. Reversal of withdrawal counted', () async {
      final acc = await createProtectedAccount('pf-4');
      await fund(acc, 'op-pf-4-fund', 20000, '2025-01-01');
      await withdraw(acc, 'op-pf-4-wd', 5000, '2025-01-10');
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'op-pf-4-rev',
          originalOperationId: 'op-pf-4-wd',
          householdId: _hh,
          effectiveDate: '2025-01-20',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.protectedFundsReports(req('2025-01-01', '2025-02-01'));
      final summary = result.firstWhere((r) => r.accountId == acc);
      expect(summary.reversalEffectMinorUnits, 5000, reason: 'Reversal restores funds');
    });

    test('5. Closing balance reconciles', () async {
      final acc = await createProtectedAccount('pf-5');
      await fund(acc, 'op-pf-5-fund', 12000, '2025-01-05');
      await withdraw(acc, 'op-pf-5-wd', 3000, '2025-01-15');

      final result = await reportRepo.protectedFundsReports(req('2025-01-01', '2025-02-01'));
      final summary = result.firstWhere((r) => r.accountId == acc);
      // closing = 12000 - 3000 = 9000
      expect(summary.closingBalanceMinorUnits, 9000);
    });

    test('6. Current balance differs from period closing when post-period ops exist', () async {
      final acc = await createProtectedAccount('pf-6');
      await fund(acc, 'op-pf-6-fund-jan', 10000, '2025-01-05');
      // Post-period withdrawal
      await withdraw(acc, 'op-pf-6-wd-feb', 2000, '2025-02-10');

      final result = await reportRepo.protectedFundsReports(req('2025-01-01', '2025-02-01'));
      final summary = result.firstWhere((r) => r.accountId == acc);
      // Period closing = 10000 (no Feb activity in Jan period)
      expect(summary.closingBalanceMinorUnits, 10000);
      // Current = 10000 - 2000 = 8000
      expect(summary.currentBalanceMinorUnits, 8000);
      expect(
        summary.closingBalanceMinorUnits != summary.currentBalanceMinorUnits,
        isTrue,
        reason: 'Period closing ≠ current when post-period ops exist',
      );
    });

    test('7. Multiple protected accounts reported separately', () async {
      final acc1 = await createProtectedAccount('pf-7a');
      final acc2 = await createProtectedAccount('pf-7b');
      await fund(acc1, 'op-pf-7a-fund', 5000, '2025-01-05');
      await fund(acc2, 'op-pf-7b-fund', 8000, '2025-01-05');

      final result = await reportRepo.protectedFundsReports(req('2025-01-01', '2025-02-01'));
      final s1 = result.firstWhere((r) => r.accountId == acc1);
      final s2 = result.firstWhere((r) => r.accountId == acc2);
      expect(s1.fundingMinorUnits, 5000);
      expect(s2.fundingMinorUnits, 8000);
    });

    test('8. Household isolation', () async {
      final acc1 = await createProtectedAccount('pf-8a');
      final acc2 = await createProtectedAccount('pf-8b', householdId: _hh2);
      await fund(acc1, 'op-pf-8a', 5000, '2025-01-05');
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-pf-8b',
          householdId: _hh2,
          destinationAccountId: acc2,
          amountMinorUnits: 9000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-05',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.protectedFundsReports(
        req('2025-01-01', '2025-02-01', householdId: _hh),
      );
      expect(
        result.any((r) => r.accountId == acc2),
        isFalse,
        reason: 'HH2 account not in HH1 report',
      );
    });
  });
}
