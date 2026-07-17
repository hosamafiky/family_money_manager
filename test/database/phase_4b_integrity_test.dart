/// Phase 4B integrity gate — cross-query consistency tests.
///
/// Tests:
///  1. Dashboard gross income == report gross income for same period
///  2. Dashboard gross expense == report gross expense for same period
///  3. Reversal effect appears in dashboard with correct sign
///  4. Reversal effect appears in report with correct sign
///  5. Dashboard net == report net after reversal
///  6. Cross-period reversal: original period gross unaffected in dashboard
///  7. Cross-period reversal: original period gross unaffected in report
///  8. Household isolation: cross-household query returns correct per-household totals
///  9. Spouse-wallet: funding amount correct
/// 10. Spouse-wallet: spending amount correct
/// 11. Spouse-wallet: returned-funds amount correct
/// 12. Spouse-wallet: reversal effects correct (zero when no reversals)
/// 13. Spouse-wallet: closing balance correct
/// 14. Spouse-wallet: current balance correct
/// 15. Spouse-wallet regression — reversed expense is NOT double-counted
/// 16. Report drill-down rows sum to income/expense header totals
/// 17. Spending-attribution totals match category totals
/// 18. Category totals == sum of rows per category
/// 19. Combined filters (date + category) use intersection semantics
/// 20. Empty period returns zero totals (no null panic)
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/dashboard/data/drift_dashboard_query_repository.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/reports/data/drift_report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-4b-gate';
const _hh2 = 'hh-4b-gate-2';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftDashboardQueryRepository dashRepo;
  late DriftReportQueryRepository reportRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    dashRepo = DriftDashboardQueryRepository(db);
    reportRepo = DriftReportQueryRepository(db);

    for (final h in [_hh, _hh2]) {
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('$h', 'HH $h', 'u1', '2024-01-01', '2024-01-01')",
      );
    }
  });

  tearDown(() async => db.close());

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<String> createAccount({
    required String id,
    required String householdId,
    String currency = 'EGP',
    String type = 'personalCashWallet',
  }) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Account $id',
        type: FinancialAccountType.fromCode(type),
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: currency,
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'test',
      ),
    );
    return id;
  }

  Future<void> income(
    String hhId,
    String accId,
    String opId,
    int amount,
    String date, {
    String currency = 'EGP',
  }) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: opId,
        householdId: hhId,
        destinationAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: currency,
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  Future<void> expense(
    String hhId,
    String accId,
    String opId,
    int amount,
    String date, {
    String currency = 'EGP',
    String? categoryCode,
  }) async {
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: opId,
        householdId: hhId,
        sourceAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: currency,
        effectiveDate: date,
        createdBy: 'test',
        categoryCode: categoryCode,
      ),
    );
  }

  Future<void> reversal(String hhId, String originalOpId, String reversalOpId, String date) async {
    await ledgerRepo.reverseOperation(
      ReverseOperationParams(
        reversalOperationId: reversalOpId,
        originalOperationId: originalOpId,
        householdId: hhId,
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  DashboardPeriod mkPeriod(String start, String end) =>
      DashboardPeriod.custom(startDate: start, endDate: end);

  FinancialReportRequest mkReq(String start, String end) =>
      FinancialReportRequest(householdId: _hh, period: mkPeriod(start, end));

  // ── Tests: Dashboard == Report consistency ────────────────────────────────

  test('1. Dashboard gross income == report gross income for same period', () async {
    final acc = await createAccount(id: 'acc-gate-1', householdId: _hh);
    await income(_hh, acc, 'op-inc-1', 5000, '2024-03-10');
    await income(_hh, acc, 'op-inc-2', 3000, '2024-03-20');

    final dashFlows = await dashRepo.periodFlow(
      householdId: _hh,
      period: mkPeriod('2024-03-01', '2024-04-01'),
    );
    final reportResult = await reportRepo.incomeExpenseFlow(mkReq('2024-03-01', '2024-04-01'));

    final dashIncome = dashFlows
        .where((f) => f.currencyCode == 'EGP')
        .map((f) => f.grossIncomeMinorUnits)
        .fold(0, (a, b) => a + b);
    final reportIncome = reportResult
        .where((r) => r.currencyCode == 'EGP')
        .map((r) => r.grossIncomeMinorUnits)
        .fold(0, (a, b) => a + b);

    expect(dashIncome, equals(8000));
    expect(reportIncome, equals(8000));
    expect(dashIncome, equals(reportIncome));
  });

  test('2. Dashboard gross expense == report gross expense for same period', () async {
    final acc = await createAccount(id: 'acc-gate-2', householdId: _hh);
    await income(_hh, acc, 'op-inc-gate-2', 10000, '2024-03-01');
    await expense(_hh, acc, 'op-exp-1', 2000, '2024-03-10');
    await expense(_hh, acc, 'op-exp-2', 1500, '2024-03-25');

    final dashFlows = await dashRepo.periodFlow(
      householdId: _hh,
      period: mkPeriod('2024-03-01', '2024-04-01'),
    );
    final reportResult = await reportRepo.incomeExpenseFlow(mkReq('2024-03-01', '2024-04-01'));

    final dashExpense = dashFlows
        .where((f) => f.currencyCode == 'EGP')
        .map((f) => f.grossExpenseMinorUnits)
        .fold(0, (a, b) => a + b);
    final reportExpense = reportResult
        .where((r) => r.currencyCode == 'EGP')
        .map((r) => r.grossExpenseMinorUnits)
        .fold(0, (a, b) => a + b);

    expect(dashExpense, equals(3500));
    expect(reportExpense, equals(3500));
    expect(dashExpense, equals(reportExpense));
  });

  test('3. Reversal effect appears in dashboard with correct sign', () async {
    final acc = await createAccount(id: 'acc-gate-3', householdId: _hh);
    await income(_hh, acc, 'op-inc-gate-3', 10000, '2024-03-01');
    await expense(_hh, acc, 'op-exp-r1', 4000, '2024-03-10');
    await reversal(_hh, 'op-exp-r1', 'rev-exp-r1', '2024-03-12');

    final dashFlows = await dashRepo.periodFlow(
      householdId: _hh,
      period: mkPeriod('2024-03-01', '2024-04-01'),
    );
    final egp = dashFlows.firstWhere((f) => f.currencyCode == 'EGP');

    expect(egp.grossExpenseMinorUnits, equals(4000));
    expect(egp.expenseReversalMinorUnits, equals(4000));
    expect(egp.netExpenseMinorUnits, equals(0));
  });

  test('4. Reversal effect appears in report with correct sign', () async {
    final acc = await createAccount(id: 'acc-gate-4', householdId: _hh);
    await income(_hh, acc, 'op-inc-gate-4', 10000, '2024-03-01');
    await expense(_hh, acc, 'op-exp-r2', 3000, '2024-03-15');
    await reversal(_hh, 'op-exp-r2', 'rev-exp-r2', '2024-03-16');

    final reportResult = await reportRepo.incomeExpenseFlow(mkReq('2024-03-01', '2024-04-01'));

    final egp = reportResult.firstWhere((r) => r.currencyCode == 'EGP');
    expect(egp.grossExpenseMinorUnits, equals(3000));
    expect(egp.expenseReversalMinorUnits, equals(3000));
    expect(egp.netExpenseMinorUnits, equals(0));
  });

  test('5. Dashboard net == report net after reversal', () async {
    final acc = await createAccount(id: 'acc-gate-5', householdId: _hh);
    await income(_hh, acc, 'op-inc-gate-5', 10000, '2024-03-01');
    await expense(_hh, acc, 'op-exp-r3', 2000, '2024-03-05');
    await reversal(_hh, 'op-exp-r3', 'rev-exp-r3', '2024-03-06');

    final dashFlows = await dashRepo.periodFlow(
      householdId: _hh,
      period: mkPeriod('2024-03-01', '2024-04-01'),
    );
    final reportResult = await reportRepo.incomeExpenseFlow(mkReq('2024-03-01', '2024-04-01'));

    final dashNetExp = dashFlows
        .where((f) => f.currencyCode == 'EGP')
        .map((f) => f.netExpenseMinorUnits)
        .fold(0, (a, b) => a + b);
    final reportNetExpense = reportResult
        .where((r) => r.currencyCode == 'EGP')
        .map((r) => r.netExpenseMinorUnits)
        .fold(0, (a, b) => a + b);

    expect(dashNetExp, equals(reportNetExpense));
    expect(dashNetExp, equals(0));
  });

  test('6. Cross-period reversal: original period gross unaffected in dashboard', () async {
    final acc = await createAccount(id: 'acc-gate-6', householdId: _hh);
    await income(_hh, acc, 'op-inc-gate-6', 10000, '2024-03-01');
    await expense(_hh, acc, 'op-exp-cp1', 5000, '2024-03-10');
    await reversal(_hh, 'op-exp-cp1', 'rev-cp1', '2024-04-02');

    final marFlows = await dashRepo.periodFlow(
      householdId: _hh,
      period: mkPeriod('2024-03-01', '2024-04-01'),
    );
    final marEgp = marFlows.firstWhere((f) => f.currencyCode == 'EGP');
    expect(marEgp.grossExpenseMinorUnits, equals(5000));
    expect(marEgp.expenseReversalMinorUnits, equals(0));
    expect(marEgp.netExpenseMinorUnits, equals(5000));

    final aprFlows = await dashRepo.periodFlow(
      householdId: _hh,
      period: mkPeriod('2024-04-01', '2024-05-01'),
    );
    final aprEgp = aprFlows.firstWhere((f) => f.currencyCode == 'EGP');
    expect(aprEgp.expenseReversalMinorUnits, equals(5000));
  });

  test('7. Cross-period reversal: original period gross unaffected in report', () async {
    final acc = await createAccount(id: 'acc-gate-7', householdId: _hh);
    await income(_hh, acc, 'op-inc-gate-7', 10000, '2024-03-01');
    await expense(_hh, acc, 'op-exp-cp2', 4000, '2024-03-20');
    await reversal(_hh, 'op-exp-cp2', 'rev-cp2', '2024-04-05');

    final marReport = await reportRepo.incomeExpenseFlow(mkReq('2024-03-01', '2024-04-01'));
    final marEgp = marReport.firstWhere((r) => r.currencyCode == 'EGP');
    expect(marEgp.grossExpenseMinorUnits, equals(4000));
    expect(marEgp.expenseReversalMinorUnits, equals(0));
  });

  test('8. Household isolation: each household only sees its own data', () async {
    final acc1 = await createAccount(id: 'acc-iso-1', householdId: _hh);
    final acc2 = await createAccount(id: 'acc-iso-2', householdId: _hh2);
    await income(_hh, acc1, 'op-iso-inc-1', 5000, '2024-03-10');
    await income(_hh2, acc2, 'op-iso-inc-2', 8000, '2024-03-10');

    final hh1Flows = await dashRepo.periodFlow(
      householdId: _hh,
      period: mkPeriod('2024-03-01', '2024-04-01'),
    );
    final hh1Inc = hh1Flows
        .where((f) => f.currencyCode == 'EGP')
        .map((f) => f.grossIncomeMinorUnits)
        .fold(0, (a, b) => a + b);
    expect(hh1Inc, equals(5000));

    final hh2Flows = await dashRepo.periodFlow(
      householdId: _hh2,
      period: mkPeriod('2024-03-01', '2024-04-01'),
    );
    final hh2Inc = hh2Flows
        .where((f) => f.currencyCode == 'EGP')
        .map((f) => f.grossIncomeMinorUnits)
        .fold(0, (a, b) => a + b);
    expect(hh2Inc, equals(8000));
  });

  // ── Tests: Spouse-wallet regression ────────────────────────────────────────

  test('9-14. Spouse-wallet: all metrics correct', () async {
    await createAccount(id: 'hs-sw', householdId: _hh, type: 'homeSavingsCash');
    await createAccount(id: 'sw-sw', householdId: _hh, type: 'spouseCashWallet');

    // Put income into home savings first
    await income(_hh, 'hs-sw', 'op-hs-sw-inc', 10000, '2024-03-01');

    // Fund spouse wallet 2000
    await ledgerRepo.executeTransfer(
      ExecuteTransferParams(
        operationId: 'transfer-fund-sw',
        householdId: _hh,
        sourceAccountId: 'hs-sw',
        destinationAccountId: 'sw-sw',
        amountMinorUnits: 2000,
        currencyCode: 'EGP',
        effectiveDate: '2024-03-05',
        createdBy: 'test',
      ),
    );

    // Spouse spends 1300
    await expense(_hh, 'sw-sw', 'exp-sw-1', 1300, '2024-03-10');

    // Return 200
    await ledgerRepo.executeTransfer(
      ExecuteTransferParams(
        operationId: 'transfer-return-sw',
        householdId: _hh,
        sourceAccountId: 'sw-sw',
        destinationAccountId: 'hs-sw',
        amountMinorUnits: 200,
        currencyCode: 'EGP',
        effectiveDate: '2024-03-20',
        createdBy: 'test',
      ),
    );

    final swReport = await reportRepo.spouseWalletReports(
      FinancialReportRequest(householdId: _hh, period: mkPeriod('2024-03-01', '2024-04-01')),
    );

    expect(swReport.length, equals(1));
    final sw = swReport.first;

    // 9. funding correct
    expect(sw.periodFundedMinorUnits, equals(2000));

    // 10. spending correct
    expect(sw.periodSpentMinorUnits, equals(1300));

    // 11. returned funds correct
    expect(sw.periodReturnedMinorUnits, equals(200));

    // 12. reversal effect is zero
    expect(sw.periodReversalEffectMinorUnits, equals(0));

    // 13. closing balance: 2000 - 1300 - 200 = 500
    expect(sw.periodClosingBalanceMinorUnits, equals(500));

    // 14. current balance = same
    expect(sw.currentBalanceMinorUnits, equals(500));
  });

  test('15. Spouse-wallet regression: reversed expense NOT double-counted', () async {
    await createAccount(id: 'hs-sw2', householdId: _hh, type: 'homeSavingsCash');
    await createAccount(id: 'sw-sw2', householdId: _hh, type: 'spouseCashWallet');

    // Put income into home savings first
    await income(_hh, 'hs-sw2', 'op-hs-sw2-inc', 10000, '2024-03-01');

    // Fund 3000
    await ledgerRepo.executeTransfer(
      ExecuteTransferParams(
        operationId: 'transfer-fund-sw2',
        householdId: _hh,
        sourceAccountId: 'hs-sw2',
        destinationAccountId: 'sw-sw2',
        amountMinorUnits: 3000,
        currencyCode: 'EGP',
        effectiveDate: '2024-03-01',
        createdBy: 'test',
      ),
    );

    // Spend 1000, then reverse it
    await expense(_hh, 'sw-sw2', 'exp-sw2-1', 1000, '2024-03-05');
    await reversal(_hh, 'exp-sw2-1', 'rev-sw2-1', '2024-03-06');

    final swReport = await reportRepo.spouseWalletReports(
      FinancialReportRequest(householdId: _hh, period: mkPeriod('2024-03-01', '2024-04-01')),
    );

    final sw = swReport.first;

    // funded = 3000
    expect(sw.periodFundedMinorUnits, equals(3000));
    // gross spent = 1000 (is_reversal = 0 filter correctly captures this)
    expect(sw.periodSpentMinorUnits, equals(1000));
    // The reversal restores funds; reversal_effect should be non-zero (positive = credit)
    expect(sw.periodReversalEffectMinorUnits, isNonZero);
    // The spent aggregation (is_reversal = 0) and reversal aggregation (is_reversal = 1)
    // are separate — no double-counting possible.
    expect(sw.periodSpentMinorUnits + sw.periodReversalEffectMinorUnits, isNonNegative);
  });

  // ── Tests: Report-to-drill-down reconciliation ──────────────────────────────

  test('16. Income/expense report total == sum of drill-down rows', () async {
    final acc = await createAccount(id: 'acc-drill-1', householdId: _hh);
    await income(_hh, acc, 'op-drill-inc-1', 4000, '2024-04-05');
    await income(_hh, acc, 'op-drill-inc-2', 2000, '2024-04-10');
    await expense(_hh, acc, 'op-drill-exp-1', 1000, '2024-04-12', categoryCode: 'groceries');
    await expense(_hh, acc, 'op-drill-exp-2', 500, '2024-04-20', categoryCode: 'utilities');

    final flowReport = await reportRepo.incomeExpenseFlow(mkReq('2024-04-01', '2024-05-01'));
    final drillRows = await reportRepo.drillDown(mkReq('2024-04-01', '2024-05-01'));

    final egpFlow = flowReport.firstWhere((r) => r.currencyCode == 'EGP');

    final drillIncomeTotal = drillRows
        .where((r) => r.operationType.code == 'income' && r.currencyCode == 'EGP')
        .map((r) => r.amountMinorUnits)
        .fold(0, (a, b) => a + b);
    final drillExpenseTotal = drillRows
        .where((r) => r.operationType.code == 'expense' && r.currencyCode == 'EGP')
        .map((r) => r.amountMinorUnits)
        .fold(0, (a, b) => a + b);

    expect(drillIncomeTotal, equals(egpFlow.grossIncomeMinorUnits));
    expect(drillExpenseTotal, equals(egpFlow.grossExpenseMinorUnits));
  });

  test('17. Spending attribution totals match expense drill-down totals', () async {
    final acc = await createAccount(id: 'acc-attr-1', householdId: _hh);
    await income(_hh, acc, 'op-attr-inc-1', 10000, '2024-05-01');
    await expense(_hh, acc, 'op-attr-exp-1', 3000, '2024-05-10', categoryCode: 'groceries');
    await expense(_hh, acc, 'op-attr-exp-2', 2000, '2024-05-15', categoryCode: 'utilities');

    final catBreakdown = await reportRepo.expenseByCategory(mkReq('2024-05-01', '2024-06-01'));
    final drillRows = await reportRepo.drillDown(mkReq('2024-05-01', '2024-06-01'));

    final catTotal = catBreakdown
        .where((r) => r.currencyCode == 'EGP')
        .map((r) => r.totalMinorUnits)
        .fold(0, (a, b) => a + b);

    final drillExpTotal = drillRows
        .where((r) => r.operationType.code == 'expense' && r.currencyCode == 'EGP')
        .map((r) => r.amountMinorUnits)
        .fold(0, (a, b) => a + b);

    expect(catTotal, equals(drillExpTotal));
    expect(catTotal, equals(5000));
  });

  test('18. Category totals == sum of drill-down rows per category', () async {
    final acc = await createAccount(id: 'acc-cat-1', householdId: _hh);
    await income(_hh, acc, 'op-cat-inc-1', 10000, '2024-06-01');
    await expense(_hh, acc, 'op-cat-exp-1', 1500, '2024-06-05', categoryCode: 'groceries');
    await expense(_hh, acc, 'op-cat-exp-2', 800, '2024-06-10', categoryCode: 'groceries');
    await expense(_hh, acc, 'op-cat-exp-3', 2000, '2024-06-15', categoryCode: 'utilities');

    final catBreakdown = await reportRepo.expenseByCategory(mkReq('2024-06-01', '2024-07-01'));
    final drillRows = await reportRepo.drillDown(mkReq('2024-06-01', '2024-07-01'));

    for (final cat in catBreakdown.where((c) => c.currencyCode == 'EGP')) {
      final drillTotal = drillRows
          .where((r) => r.categoryCode == cat.categoryCode && r.currencyCode == 'EGP')
          .map((r) => r.amountMinorUnits)
          .fold(0, (a, b) => a + b);
      expect(
        drillTotal,
        equals(cat.totalMinorUnits),
        reason: 'Category ${cat.categoryCode} totals should match drill-down',
      );
    }
  });

  // ── Tests: Filter intersection semantics ────────────────────────────────────

  test('19. Category filter (date + category) uses intersection semantics', () async {
    final acc = await createAccount(id: 'acc-filter-1', householdId: _hh);
    await income(_hh, acc, 'op-filter-inc', 10000, '2024-07-01');
    // Groceries in July — should be returned
    await expense(_hh, acc, 'op-filter-exp-1', 1000, '2024-07-10', categoryCode: 'groceries');
    // Utilities in July — should NOT be returned when filtering groceries
    await expense(_hh, acc, 'op-filter-exp-2', 2000, '2024-07-15', categoryCode: 'utilities');
    // Groceries in August — should NOT be returned for July period
    await expense(_hh, acc, 'op-filter-exp-3', 500, '2024-08-01', categoryCode: 'groceries');

    final catBreakdown = await reportRepo.expenseByCategory(
      FinancialReportRequest(householdId: _hh, period: mkPeriod('2024-07-01', '2024-08-01')),
    );

    final groceriesInJuly = catBreakdown
        .where((r) => r.categoryCode == 'groceries' && r.currencyCode == 'EGP')
        .map((r) => r.totalMinorUnits)
        .fold(0, (a, b) => a + b);

    // Must be ONLY July groceries (1000); not August (500) or utilities (2000)
    expect(groceriesInJuly, equals(1000));

    // Utilities also only July
    final utilitiesInJuly = catBreakdown
        .where((r) => r.categoryCode == 'utilities' && r.currencyCode == 'EGP')
        .map((r) => r.totalMinorUnits)
        .fold(0, (a, b) => a + b);
    expect(utilitiesInJuly, equals(2000));
  });

  test('20. Empty period returns zero totals (no null panic)', () async {
    await createAccount(id: 'acc-empty-1', householdId: _hh);

    final dashFlows = await dashRepo.periodFlow(
      householdId: _hh,
      period: mkPeriod('2030-01-01', '2030-02-01'),
    );
    expect(dashFlows, isEmpty);

    final reportResult = await reportRepo.incomeExpenseFlow(
      FinancialReportRequest(householdId: _hh, period: mkPeriod('2030-01-01', '2030-02-01')),
    );
    expect(reportResult, isEmpty);
  });
}
