/// Phase 6A.1 — reports / budgets / spendable classification regressions.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/budgets/data/drift_budget_repository.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';
import 'package:family_money_manager/features/certificates/application/certificate_use_cases.dart';
import 'package:family_money_manager/features/certificates/data/drift_certificate_repository.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/dashboard/data/drift_dashboard_query_repository.dart';
import 'package:family_money_manager/features/dashboard/domain/dashboard_summary.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/reports/data/drift_report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_filter.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-6a1-cls';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accounts;
  late DriftLedgerRepository ledger;
  late CreateCertificateUseCase createUc;
  late RecordCertificateProfitUseCase profitUc;
  late RedeemCertificateUseCase redeemUc;
  late DriftReportQueryRepository reports;
  late DriftDashboardQueryRepository dashboard;
  late DriftBudgetRepository budgets;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accounts = DriftAccountRepository(db);
    ledger = DriftLedgerRepository(db);
    final certs = DriftCertificateRepository(db);
    createUc = CreateCertificateUseCase(
      certRepository: certs,
      accountRepository: accounts,
    );
    profitUc = RecordCertificateProfitUseCase(
      certRepository: certs,
      accountRepository: accounts,
    );
    redeemUc = RedeemCertificateUseCase(
      certRepository: certs,
      accountRepository: accounts,
    );
    reports = DriftReportQueryRepository(db);
    dashboard = DriftDashboardQueryRepository(db);
    budgets = DriftBudgetRepository(db);
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'HH', 'u1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<void> createAcct(String id, {String currency = 'EGP'}) async {
    await accounts.createAccount(
      CreateAccountParams(
        id: id,
        householdId: _hh,
        name: id,
        type: FinancialAccountType.bankAccount,
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
  }

  Future<void> credit(String id, int amount, {String currency = 'EGP'}) async {
    await ledger.recordIncome(
      RecordIncomeParams(
        operationId: 'inc-$id-$amount-$currency',
        householdId: _hh,
        destinationAccountId: id,
        amountMinorUnits: amount,
        currencyCode: currency,
        effectiveDate: '2024-01-01',
        createdBy: 'test',
      ),
    );
  }

  test('CLS-1. Purchase principal is neither income nor expense', () async {
    await createAcct('src');
    await credit('src', 200000);
    await createUc.execute(
      householdId: _hh,
      institutionName: 'Bank',
      currencyCode: 'EGP',
      principalMinorUnits: 50000,
      startDate: '2025-01-01',
      maturityDate: '2026-01-01',
      sourceAccountId: 'src',
      idempotencyKey: 'cls-1',
    );
    final flow = await reports.incomeExpenseFlow(
      FinancialReportRequest(
        householdId: _hh,
        period: DashboardPeriod.custom(
          startDate: '2024-01-01',
          endDate: '2027-01-01',
        ),
      ),
    );
    // Ordinary funding of source creates income; purchase must not add expense.
    final egp = flow.where((f) => f.currencyCode == 'EGP').first;
    expect(egp.grossExpenseMinorUnits, 0);
  });

  test('CLS-2. Redemption principal is neither income nor expense', () async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 200000);
    final cert =
        (await createUc.execute(
                  householdId: _hh,
                  institutionName: 'Bank',
                  currencyCode: 'EGP',
                  principalMinorUnits: 40000,
                  startDate: '2019-01-01',
                  maturityDate: '2020-01-01',
                  sourceAccountId: 'src',
                  idempotencyKey: 'cls-2',
                )
                as AppOk<SavingsCertificate>)
            .value;
    await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst',
      principalMinorUnits: 40000,
      idempotencyKey: 'cls-2-red',
    );
    final flow = await reports.incomeExpenseFlow(
      FinancialReportRequest(
        householdId: _hh,
        period: DashboardPeriod.custom(
          startDate: '2019-01-01',
          endDate: '2027-01-01',
        ),
      ),
    );
    final egp = flow.where((f) => f.currencyCode == 'EGP').first;
    expect(egp.grossExpenseMinorUnits, 0);
  });

  test('CLS-3. Certificate profit is ordinary income', () async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 200000);
    final cert =
        (await createUc.execute(
                  householdId: _hh,
                  institutionName: 'Bank',
                  currencyCode: 'EGP',
                  principalMinorUnits: 40000,
                  startDate: '2019-01-01',
                  maturityDate: '2020-01-01',
                  sourceAccountId: 'src',
                  idempotencyKey: 'cls-3',
                )
                as AppOk<SavingsCertificate>)
            .value;
    final before = await reports.incomeExpenseFlow(
      FinancialReportRequest(
        householdId: _hh,
        period: DashboardPeriod.custom(
          startDate: '2025-01-01',
          endDate: '2026-01-01',
        ),
      ),
    );
    final beforeIncome = before.isEmpty
        ? 0
        : before.first.grossIncomeMinorUnits;
    await profitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst',
      amountMinorUnits: 3333,
      idempotencyKey: 'cls-3-p',
      effectiveDate: '2025-06-01',
    );
    final after = await reports.incomeExpenseFlow(
      FinancialReportRequest(
        householdId: _hh,
        period: DashboardPeriod.custom(
          startDate: '2025-01-01',
          endDate: '2026-01-01',
        ),
      ),
    );
    expect(after.first.grossIncomeMinorUnits, beforeIncome + 3333);
  });

  test(
    'CLS-4. Purchase/redemption/profit do not consume expense budgets',
    () async {
      await createAcct('src');
      await createAcct('dst');
      await credit('src', 300000);
      const plan = BudgetPlan(
        id: 'b1',
        householdId: _hh,
        name: 'Food',
        currencyCode: 'EGP',
        limitMinorUnits: 100000,
        periodDefinition: MonthlyBudgetPeriod(),
        filter: BudgetFilter(categoryCode: 'groceries'),
        isArchived: false,
        createdAt: '2025-01-01T00:00:00Z',
        updatedAt: '2025-01-01T00:00:00Z',
        idempotencyKey: 'b1',
        idempotencyPayload: 'b1',
      );
      await budgets.createBudget(plan);
      final cert =
          (await createUc.execute(
                    householdId: _hh,
                    institutionName: 'Bank',
                    currencyCode: 'EGP',
                    principalMinorUnits: 50000,
                    startDate: '2019-01-01',
                    maturityDate: '2020-01-01',
                    sourceAccountId: 'src',
                    idempotencyKey: 'cls-4',
                  )
                  as AppOk<SavingsCertificate>)
              .value;
      await profitUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst',
        amountMinorUnits: 1000,
        idempotencyKey: 'cls-4-p',
        effectiveDate: '2025-01-10',
      );
      await redeemUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst',
        principalMinorUnits: 50000,
        idempotencyKey: 'cls-4-r',
      );
      final spent = await budgets.getBudgetTransactions(
        householdId: _hh,
        currencyCode: 'EGP',
        periodStart: '2025-01-01',
        periodEnd: '2025-02-01',
        filter: const BudgetFilter(categoryCode: 'groceries'),
      );
      expect(spent, isA<AppOk<List<BudgetTransactionRow>>>());
      expect((spent as AppOk<List<BudgetTransactionRow>>).value, isEmpty);
    },
  );

  test(
    'CLS-5. Certificate principal excluded from spendable; protected only while the term is unfinished',
    () async {
      await createAcct('src');
      await credit('src', 200000);
      final cert =
          (await createUc.execute(
                    householdId: _hh,
                    institutionName: 'Bank',
                    currencyCode: 'EGP',
                    principalMinorUnits: 75000,
                    startDate: '2025-01-01',
                    maturityDate: '2026-01-01',
                    sourceAccountId: 'src',
                    idempotencyKey: 'cls-5',
                  )
                  as AppOk<SavingsCertificate>)
              .value;
      final spendable = await dashboard.spendableBalances(householdId: _hh);
      final spendableEgp = spendable
          .where((b) => b.currencyCode == 'EGP')
          .fold<int>(0, (a, b) => a + b.totalMinorUnits);
      expect(spendableEgp, 125000); // 200k - 75k moved to non-spendable cert

      // Principal is never spendable, but it IS protected money for as long as
      // the term runs. Term here: 2025-01-01 → 2026-01-01.
      int protectedEgpOn(List<CurrencyAmountSummary> rows) => rows
          .where((b) => b.currencyCode == 'EGP')
          .fold<int>(0, (a, b) => a + b.totalMinorUnits);

      final duringTerm = await dashboard.protectedBalances(
        householdId: _hh,
        todayLocal: '2025-06-15',
      );
      expect(protectedEgpOn(duringTerm), 75000);

      // On the maturity date the term has ended: the principal is claimable
      // and must leave the protected bucket rather than stay hidden in it.
      final atMaturity = await dashboard.protectedBalances(
        householdId: _hh,
        todayLocal: '2026-01-01',
      );
      expect(protectedEgpOn(atMaturity), 0);

      final afterMaturity = await dashboard.protectedBalances(
        householdId: _hh,
        todayLocal: '2026-05-01',
      );
      expect(protectedEgpOn(afterMaturity), 0);
      // Certificate account itself is non-spendable.
      final acct = await accounts.findById(
        id: cert.certificateAccountId,
        householdId: _hh,
      );
      expect(acct!.isSpendable, isFalse);
      expect(acct.isProtected, isFalse);
    },
  );

  test('CLS-6. Currencies never combined in income flow', () async {
    await createAcct('src-egp', currency: 'EGP');
    await createAcct('src-usd', currency: 'USD');
    await createAcct('dst-egp', currency: 'EGP');
    await createAcct('dst-usd', currency: 'USD');
    await credit('src-egp', 100000, currency: 'EGP');
    await credit('src-usd', 10000, currency: 'USD');
    final cEgp =
        (await createUc.execute(
                  householdId: _hh,
                  institutionName: 'EGP Bank',
                  currencyCode: 'EGP',
                  principalMinorUnits: 10000,
                  startDate: '2019-01-01',
                  maturityDate: '2020-01-01',
                  sourceAccountId: 'src-egp',
                  idempotencyKey: 'cls-6-egp',
                )
                as AppOk<SavingsCertificate>)
            .value;
    final cUsd =
        (await createUc.execute(
                  householdId: _hh,
                  institutionName: 'USD Bank',
                  currencyCode: 'USD',
                  principalMinorUnits: 1000,
                  startDate: '2019-01-01',
                  maturityDate: '2020-01-01',
                  sourceAccountId: 'src-usd',
                  idempotencyKey: 'cls-6-usd',
                )
                as AppOk<SavingsCertificate>)
            .value;
    await profitUc.execute(
      certificateId: cEgp.id,
      householdId: _hh,
      destinationAccountId: 'dst-egp',
      amountMinorUnits: 111,
      idempotencyKey: 'cls-6-pe',
      effectiveDate: '2025-03-01',
    );
    await profitUc.execute(
      certificateId: cUsd.id,
      householdId: _hh,
      destinationAccountId: 'dst-usd',
      amountMinorUnits: 222,
      idempotencyKey: 'cls-6-pu',
      effectiveDate: '2025-03-01',
    );
    final flow = await reports.incomeExpenseFlow(
      FinancialReportRequest(
        householdId: _hh,
        period: DashboardPeriod.custom(
          startDate: '2025-01-01',
          endDate: '2026-01-01',
        ),
      ),
    );
    expect(flow.map((f) => f.currencyCode).toSet(), {'EGP', 'USD'});
    expect(
      flow.where((f) => f.currencyCode == 'EGP').first.grossIncomeMinorUnits,
      111,
    );
    expect(
      flow.where((f) => f.currencyCode == 'USD').first.grossIncomeMinorUnits,
      222,
    );
  });

  test('CLS-7. goalWithdrawal and certificateMaturity excluded helper', () {
    expect(
      OperationType.goalWithdrawal.isExcludedFromIncomeExpenseReports,
      isTrue,
    );
    expect(
      OperationType.certificateMaturity.isExcludedFromIncomeExpenseReports,
      isTrue,
    );
    expect(
      OperationType.certificateFunding.isExcludedFromIncomeExpenseReports,
      isTrue,
    );
    expect(OperationType.income.isExcludedFromIncomeExpenseReports, isFalse);
  });

  test('CLS-8. Account-flow reconciles certificate account', () async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 200000);
    final cert =
        (await createUc.execute(
                  householdId: _hh,
                  institutionName: 'Bank',
                  currencyCode: 'EGP',
                  principalMinorUnits: 60000,
                  startDate: '2019-01-01',
                  maturityDate: '2020-01-01',
                  sourceAccountId: 'src',
                  idempotencyKey: 'cls-8',
                )
                as AppOk<SavingsCertificate>)
            .value;
    final mid = await reports.accountFlows(
      FinancialReportRequest(
        householdId: _hh,
        period: DashboardPeriod.custom(
          startDate: '2018-01-01',
          endDate: '2021-01-01',
        ),
        filter: ReportFilter(accountIds: [cert.certificateAccountId]),
      ),
    );
    final midRow = mid.singleWhere(
      (r) => r.accountId == cert.certificateAccountId,
    );
    expect(midRow.closingBalanceMinorUnits, 60000);
    await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst',
      principalMinorUnits: 60000,
      idempotencyKey: 'cls-8-r',
    );
    final end = await reports.accountFlows(
      FinancialReportRequest(
        householdId: _hh,
        period: DashboardPeriod.custom(
          startDate: '2018-01-01',
          endDate: '2027-01-01',
        ),
        filter: ReportFilter(accountIds: [cert.certificateAccountId]),
      ),
    );
    final endRow = end.singleWhere(
      (r) => r.accountId == cert.certificateAccountId,
    );
    expect(endRow.closingBalanceMinorUnits, 0);
  });
}
