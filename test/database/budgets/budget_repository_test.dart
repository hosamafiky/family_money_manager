/// Budget repository database tests (Phase 5A).
///
/// Tests:
///  1. Create budget — stored and retrieved correctly
///  2. Create budget — idempotency: same key + same payload → returns existing
///  3. Create budget — conflicting idempotency: same key + different payload → AppDuplicateConflict
///  4. Create budget — cross-household isolation: same key in different household is separate
///  5. Update budget name — updates only name
///  6. Update budget limit — updates limit
///  7. Update budget filter — stored correctly
///  8. Archive budget — sets is_archived
///  9. Restore budget — clears is_archived
/// 10. List budgets — excludes archived by default
/// 11. List budgets — includes archived when flag set
/// 12. List budgets — isolated per household
/// 13. getBudgetTransactions — returns only expense operations (not income)
/// 14. getBudgetTransactions — returns only matching currency
/// 15. getBudgetTransactions — respects date range (inclusive start, exclusive end)
/// 16. getBudgetTransactions — category filter works (AND semantics)
/// 17. getBudgetTransactions — scope filter works
/// 18. getBudgetTransactions — spender filter works
/// 19. getBudgetTransactions — beneficiary filter works
/// 20. getBudgetTransactions — payment account filter works
/// 21. getBudgetTransactions — combined filters (date + category) use intersection
/// 22. getBudgetTransactions — excludes reversed expenses (restated semantics)
/// 23. getBudgetTransactions — excludes reversal operations themselves
/// 24. getBudgetTransactions — backdated expense appears in correct period
/// 25. getBudgetTransactions — same-period reversal: expense reversed in same period → 0
/// 26. getBudgetTransactions — cross-period reversal: expense reversed later → still in original period
/// 27. getBudgetTransactions — multiple currencies: EGP budget only sees EGP expenses
/// 28. getBudgetTransactions — transfer excluded
/// 29. getBudgetTransactions — opening balance excluded
/// 30. getBudgetTransactions — adjustment excluded
/// 31. Phase 4B gate: dashboard total == report total
/// 32. Phase 4B gate: spouse-wallet reversals correct
/// 33. Budget mutations do not write to operations table (no money moved)
/// 34. report_vs_budget semantic distinction: cross-period reversal appears in report, not in budget
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/budgets/data/drift_budget_repository.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';
import 'package:family_money_manager/features/dashboard/data/drift_dashboard_query_repository.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/reports/data/drift_report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-budget-test';
const _hh2 = 'hh-budget-test-2';

void main() {
  late AppDatabase db;
  late DriftBudgetRepository budgetRepo;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftDashboardQueryRepository dashRepo;
  late DriftReportQueryRepository reportRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    budgetRepo = DriftBudgetRepository(db);
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

  BudgetPlan plan0({
    String id = 'budget-1',
    String householdId = _hh,
    String name = 'Groceries',
    String currency = 'EGP',
    int limit = 50000,
    BudgetPeriodDefinition? period,
    BudgetFilter filter = const BudgetFilter(),
    String idempotencyKey = 'ik-1',
    String idempotencyPayload = 'payload-1',
  }) {
    return BudgetPlan(
      id: id,
      householdId: householdId,
      name: name,
      currencyCode: currency,
      limitMinorUnits: limit,
      periodDefinition: period ?? const MonthlyBudgetPeriod(),
      filter: filter,
      isArchived: false,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
      idempotencyKey: idempotencyKey,
      idempotencyPayload: idempotencyPayload,
    );
  }

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
    String? scopeCode,
    String? spenderMemberId,
    String? beneficiaryMemberId,
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
        spenderMemberId: spenderMemberId,
        beneficiaryMemberId: beneficiaryMemberId,
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

  // ── Create / CRUD tests ──────────────────────────────────────────────────

  test('1. Create budget — stored and retrieved correctly', () async {
    final plan = plan0();
    final result = await budgetRepo.createBudget(plan);
    expect(result, isA<AppOk<BudgetPlan>>());

    final found = await budgetRepo.findBudgetById(plan.id);
    expect(found, isA<AppOk<BudgetPlan?>>());
    final retrieved = (found as AppOk<BudgetPlan?>).value;
    expect(retrieved, isNotNull);
    expect(retrieved!.name, equals('Groceries'));
    expect(retrieved.limitMinorUnits, equals(50000));
    expect(retrieved.currencyCode, equals('EGP'));
  });

  test('2. Idempotency: same key + same payload → returns existing', () async {
    final plan = plan0();
    await budgetRepo.createBudget(plan);

    final second = await budgetRepo.createBudget(plan);
    expect(second, isA<AppOk<BudgetPlan>>());
    // Same plan returned
    final value = (second as AppOk<BudgetPlan>).value;
    expect(value.id, equals(plan.id));
  });

  test('3. Idempotency conflict: same key + different payload → AppDuplicateConflict', () async {
    final plan = plan0(idempotencyKey: 'same-key', idempotencyPayload: 'payload-A');
    await budgetRepo.createBudget(plan);

    final conflict = plan0(
      id: 'budget-2',
      idempotencyKey: 'same-key',
      idempotencyPayload: 'payload-B',
    );
    final result = await budgetRepo.createBudget(conflict);
    expect(result, isA<AppDuplicateConflict<BudgetPlan>>());
  });

  test('4. Cross-household isolation: same key in different household is separate', () async {
    final plan1 = plan0(householdId: _hh, idempotencyKey: 'cross-key');
    final plan2 = plan0(id: 'budget-hh2', householdId: _hh2, idempotencyKey: 'cross-key');

    final r1 = await budgetRepo.createBudget(plan1);
    final r2 = await budgetRepo.createBudget(plan2);
    expect(r1, isA<AppOk<BudgetPlan>>());
    expect(r2, isA<AppOk<BudgetPlan>>());
  });

  test('5. Update budget name — updates only name', () async {
    final plan = plan0();
    await budgetRepo.createBudget(plan);

    final updated = BudgetPlan(
      id: plan.id,
      householdId: plan.householdId,
      name: 'New Name',
      currencyCode: plan.currencyCode,
      limitMinorUnits: plan.limitMinorUnits,
      periodDefinition: plan.periodDefinition,
      filter: plan.filter,
      isArchived: plan.isArchived,
      createdAt: plan.createdAt,
      updatedAt: '2024-02-01T00:00:00Z',
      idempotencyKey: plan.idempotencyKey,
      idempotencyPayload: plan.idempotencyPayload,
    );
    await budgetRepo.updateBudget(updated);

    final found = await budgetRepo.findBudgetById(plan.id);
    final retrieved = (found as AppOk<BudgetPlan?>).value!;
    expect(retrieved.name, equals('New Name'));
    expect(retrieved.limitMinorUnits, equals(50000));
  });

  test('6. Update budget limit — updates limit', () async {
    final plan = plan0();
    await budgetRepo.createBudget(plan);

    final updated = BudgetPlan(
      id: plan.id,
      householdId: plan.householdId,
      name: plan.name,
      currencyCode: plan.currencyCode,
      limitMinorUnits: 75000,
      periodDefinition: plan.periodDefinition,
      filter: plan.filter,
      isArchived: plan.isArchived,
      createdAt: plan.createdAt,
      updatedAt: '2024-02-01T00:00:00Z',
      idempotencyKey: plan.idempotencyKey,
      idempotencyPayload: plan.idempotencyPayload,
    );
    await budgetRepo.updateBudget(updated);

    final found = await budgetRepo.findBudgetById(plan.id);
    expect((found as AppOk<BudgetPlan?>).value!.limitMinorUnits, equals(75000));
  });

  test('7. Update budget filter — stored correctly', () async {
    final plan = plan0();
    await budgetRepo.createBudget(plan);

    final withFilter = BudgetPlan(
      id: plan.id,
      householdId: plan.householdId,
      name: plan.name,
      currencyCode: plan.currencyCode,
      limitMinorUnits: plan.limitMinorUnits,
      periodDefinition: plan.periodDefinition,
      filter: const BudgetFilter(categoryCode: 'groceries'),
      isArchived: plan.isArchived,
      createdAt: plan.createdAt,
      updatedAt: '2024-02-01T00:00:00Z',
      idempotencyKey: plan.idempotencyKey,
      idempotencyPayload: plan.idempotencyPayload,
    );
    await budgetRepo.updateBudget(withFilter);

    final found = await budgetRepo.findBudgetById(plan.id);
    expect((found as AppOk<BudgetPlan?>).value!.filter.categoryCode, equals('groceries'));
  });

  test('8. Archive budget — sets is_archived', () async {
    final plan = plan0();
    await budgetRepo.createBudget(plan);
    await budgetRepo.archiveBudget(plan.id);

    final found = await budgetRepo.findBudgetById(plan.id);
    expect((found as AppOk<BudgetPlan?>).value!.isArchived, isTrue);
  });

  test('9. Restore budget — clears is_archived', () async {
    final plan = plan0();
    await budgetRepo.createBudget(plan);
    await budgetRepo.archiveBudget(plan.id);
    await budgetRepo.restoreBudget(plan.id);

    final found = await budgetRepo.findBudgetById(plan.id);
    expect((found as AppOk<BudgetPlan?>).value!.isArchived, isFalse);
  });

  test('10. List budgets — excludes archived by default', () async {
    await budgetRepo.createBudget(plan0(id: 'b1', idempotencyKey: 'ik-b1'));
    await budgetRepo.createBudget(plan0(id: 'b2', idempotencyKey: 'ik-b2', name: 'Other'));
    await budgetRepo.archiveBudget('b2');

    final result = await budgetRepo.listBudgets(householdId: _hh);
    final plans = (result as AppOk<List<BudgetPlan>>).value;
    expect(plans.length, equals(1));
    expect(plans.first.id, equals('b1'));
  });

  test('11. List budgets — includes archived when flag set', () async {
    await budgetRepo.createBudget(plan0(id: 'b1', idempotencyKey: 'ik-b1'));
    await budgetRepo.createBudget(
      plan0(id: 'b2', idempotencyKey: 'ik-b2', name: 'Archived Budget'),
    );
    await budgetRepo.archiveBudget('b2');

    final result = await budgetRepo.listBudgets(householdId: _hh, includeArchived: true);
    final plans = (result as AppOk<List<BudgetPlan>>).value;
    expect(plans.length, equals(2));
  });

  test('12. List budgets — isolated per household', () async {
    await budgetRepo.createBudget(plan0(id: 'b-hh1', idempotencyKey: 'ik-hh1', householdId: _hh));
    await budgetRepo.createBudget(plan0(id: 'b-hh2', idempotencyKey: 'ik-hh2', householdId: _hh2));

    final hh1Result = await budgetRepo.listBudgets(householdId: _hh);
    final hh1Plans = (hh1Result as AppOk<List<BudgetPlan>>).value;
    expect(hh1Plans.length, equals(1));
    expect(hh1Plans.first.householdId, equals(_hh));
  });

  // ── getBudgetTransactions tests ───────────────────────────────────────────

  test('13. getBudgetTransactions — returns only expense operations', () async {
    final acc = await createAccount(id: 'acc-bt-1', householdId: _hh);
    await income(_hh, acc, 'op-inc-bt', 5000, '2024-03-10');
    await expense(_hh, acc, 'op-exp-bt', 2000, '2024-03-15');

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    expect(rows.length, equals(1));
    expect(rows.first.amountMinorUnits, equals(2000));
  });

  test('14. getBudgetTransactions — returns only matching currency', () async {
    final egpAcc = await createAccount(id: 'acc-egp', householdId: _hh);
    final usdAcc = await createAccount(id: 'acc-usd', householdId: _hh, currency: 'USD');
    await income(_hh, egpAcc, 'op-inc-egp', 10000, '2024-03-01');
    await income(_hh, usdAcc, 'op-inc-usd', 500, '2024-03-01', currency: 'USD');
    await expense(_hh, egpAcc, 'op-exp-egp', 3000, '2024-03-10');
    await expense(_hh, usdAcc, 'op-exp-usd', 200, '2024-03-10', currency: 'USD');

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    expect(rows.length, equals(1));
    expect(rows.first.currencyCode, equals('EGP'));
    expect(rows.first.amountMinorUnits, equals(3000));
  });

  test(
    '15. getBudgetTransactions — respects date range (inclusive start, exclusive end)',
    () async {
      final acc = await createAccount(id: 'acc-dr', householdId: _hh);
      await income(_hh, acc, 'op-inc-dr', 20000, '2024-03-01');
      await expense(_hh, acc, 'op-exp-before', 1000, '2024-02-28');
      await expense(_hh, acc, 'op-exp-start', 2000, '2024-03-01');
      await expense(_hh, acc, 'op-exp-mid', 3000, '2024-03-15');
      await expense(_hh, acc, 'op-exp-end', 4000, '2024-04-01');

      final result = await budgetRepo.getBudgetTransactions(
        householdId: _hh,
        currencyCode: 'EGP',
        periodStart: '2024-03-01',
        periodEnd: '2024-04-01',
        filter: const BudgetFilter(),
      );
      final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
      expect(rows.length, equals(2));
      final total = rows.map((r) => r.amountMinorUnits).fold(0, (a, b) => a + b);
      expect(total, equals(5000));
    },
  );

  test('16. getBudgetTransactions — category filter works', () async {
    final acc = await createAccount(id: 'acc-cat', householdId: _hh);
    await income(_hh, acc, 'op-inc-cat', 20000, '2024-03-01');
    await expense(_hh, acc, 'op-groc', 1500, '2024-03-10', categoryCode: 'groceries');
    await expense(_hh, acc, 'op-util', 2000, '2024-03-15', categoryCode: 'utilities');

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(categoryCode: 'groceries'),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    expect(rows.length, equals(1));
    expect(rows.first.amountMinorUnits, equals(1500));
  });

  test('17. getBudgetTransactions — scope filter works', () async {
    final acc = await createAccount(id: 'acc-scope', householdId: _hh);
    await income(_hh, acc, 'op-inc-scope', 20000, '2024-03-01');
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: 'op-household',
        householdId: _hh,
        sourceAccountId: acc,
        amountMinorUnits: 3000,
        currencyCode: 'EGP',
        effectiveDate: '2024-03-10',
        createdBy: 'test',
        scope: ExpenseScope.household,
      ),
    );
    await expense(_hh, acc, 'op-personal', 2000, '2024-03-15');

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(scopeCode: 'household'),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    expect(rows.length, equals(1));
    expect(rows.first.amountMinorUnits, equals(3000));
  });

  test('18. getBudgetTransactions — spender filter works', () async {
    final acc = await createAccount(id: 'acc-spender', householdId: _hh);
    await income(_hh, acc, 'op-inc-spender', 20000, '2024-03-01');
    await expense(_hh, acc, 'op-sp-alice', 1000, '2024-03-10', spenderMemberId: 'member-alice');
    await expense(_hh, acc, 'op-sp-bob', 2000, '2024-03-15', spenderMemberId: 'member-bob');

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(spenderMemberId: 'member-alice'),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    expect(rows.length, equals(1));
    expect(rows.first.amountMinorUnits, equals(1000));
  });

  test('19. getBudgetTransactions — beneficiary filter works', () async {
    final acc = await createAccount(id: 'acc-bene', householdId: _hh);
    await income(_hh, acc, 'op-inc-bene', 20000, '2024-03-01');
    await expense(_hh, acc, 'op-bn-alice', 1500, '2024-03-10', beneficiaryMemberId: 'member-alice');
    await expense(_hh, acc, 'op-bn-none', 2500, '2024-03-15');

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(beneficiaryMemberId: 'member-alice'),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    expect(rows.length, equals(1));
    expect(rows.first.amountMinorUnits, equals(1500));
  });

  test('20. getBudgetTransactions — payment account filter works', () async {
    final acc1 = await createAccount(id: 'acc-pay1', householdId: _hh);
    final acc2 = await createAccount(id: 'acc-pay2', householdId: _hh);
    await income(_hh, acc1, 'op-inc-pay1', 20000, '2024-03-01');
    await income(_hh, acc2, 'op-inc-pay2', 10000, '2024-03-01');
    await expense(_hh, acc1, 'op-exp-pay1', 3000, '2024-03-10');
    await expense(_hh, acc2, 'op-exp-pay2', 4000, '2024-03-12');

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(paymentAccountId: 'acc-pay1'),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    expect(rows.length, equals(1));
    expect(rows.first.amountMinorUnits, equals(3000));
  });

  test('21. Combined filters (date + category) use intersection semantics', () async {
    final acc = await createAccount(id: 'acc-combined', householdId: _hh);
    await income(_hh, acc, 'op-inc-comb', 20000, '2024-03-01');
    await expense(_hh, acc, 'op-groc-mar', 1000, '2024-03-10', categoryCode: 'groceries');
    await expense(_hh, acc, 'op-util-mar', 2000, '2024-03-15', categoryCode: 'utilities');
    await expense(_hh, acc, 'op-groc-apr', 500, '2024-04-02', categoryCode: 'groceries');

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(categoryCode: 'groceries'),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    // Should be ONLY March groceries
    expect(rows.length, equals(1));
    expect(rows.first.amountMinorUnits, equals(1000));
  });

  test('22. getBudgetTransactions — excludes reversed expenses (restated)', () async {
    final acc = await createAccount(id: 'acc-rev-ex', householdId: _hh);
    await income(_hh, acc, 'op-inc-rev-ex', 20000, '2024-03-01');
    await expense(_hh, acc, 'op-exp-to-rev', 3000, '2024-03-10');
    await reversal(_hh, 'op-exp-to-rev', 'rev-op-exp', '2024-03-11');
    await expense(_hh, acc, 'op-exp-keep', 1500, '2024-03-15');

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    // Only the non-reversed expense
    expect(rows.length, equals(1));
    expect(rows.first.amountMinorUnits, equals(1500));
  });

  test('23. getBudgetTransactions — excludes reversal operations themselves', () async {
    final acc = await createAccount(id: 'acc-rev-op', householdId: _hh);
    await income(_hh, acc, 'op-inc-rev-op', 20000, '2024-03-01');
    await expense(_hh, acc, 'op-exp-rev', 5000, '2024-03-05');
    await reversal(_hh, 'op-exp-rev', 'rev-op-rev', '2024-03-10');

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    // Neither the reversed expense nor the reversal operation
    expect(rows, isEmpty);
  });

  test('24. getBudgetTransactions — backdated expense in correct period', () async {
    final acc = await createAccount(id: 'acc-back', householdId: _hh);
    await income(_hh, acc, 'op-inc-back', 20000, '2024-03-01');
    await expense(_hh, acc, 'op-back-jan', 4000, '2024-01-15');
    await expense(_hh, acc, 'op-back-mar', 2000, '2024-03-10');

    final janResult = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-01-01',
      periodEnd: '2024-02-01',
      filter: const BudgetFilter(),
    );
    final marResult = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(),
    );

    final janRows = (janResult as AppOk<List<BudgetTransactionRow>>).value;
    final marRows = (marResult as AppOk<List<BudgetTransactionRow>>).value;
    expect(janRows.length, equals(1));
    expect(janRows.first.amountMinorUnits, equals(4000));
    expect(marRows.length, equals(1));
    expect(marRows.first.amountMinorUnits, equals(2000));
  });

  test('25. Same-period reversal: expense reversed same period → excluded', () async {
    final acc = await createAccount(id: 'acc-sp-rev', householdId: _hh);
    await income(_hh, acc, 'op-inc-sp-rev', 20000, '2024-03-01');
    await expense(_hh, acc, 'op-exp-sp', 3000, '2024-03-05');
    await reversal(_hh, 'op-exp-sp', 'rev-sp', '2024-03-07');

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    expect(rows, isEmpty);
  });

  test('26. Cross-period reversal: original expense still excluded in its period', () async {
    final acc = await createAccount(id: 'acc-cp-rev', householdId: _hh);
    await income(_hh, acc, 'op-inc-cp-rev', 20000, '2024-03-01');
    await expense(_hh, acc, 'op-cp-exp', 5000, '2024-03-10');
    await reversal(_hh, 'op-cp-exp', 'rev-cp', '2024-04-05');

    // In restated view: March budget should NOT include this expense since it is reversed
    final marResult = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(),
    );
    final marRows = (marResult as AppOk<List<BudgetTransactionRow>>).value;
    // Restated: is_reversed=1 means excluded from budget (even if reversal is in April)
    expect(marRows, isEmpty);
  });

  test('27. Multiple currencies: EGP budget only sees EGP expenses', () async {
    final egpAcc = await createAccount(id: 'acc-mc-egp', householdId: _hh);
    final usdAcc = await createAccount(id: 'acc-mc-usd', householdId: _hh, currency: 'USD');
    await income(_hh, egpAcc, 'op-inc-mc-egp', 20000, '2024-03-01');
    await income(_hh, usdAcc, 'op-inc-mc-usd', 1000, '2024-03-01', currency: 'USD');
    await expense(_hh, egpAcc, 'op-exp-mc-egp', 2000, '2024-03-10');
    await expense(_hh, usdAcc, 'op-exp-mc-usd', 300, '2024-03-10', currency: 'USD');

    final egpResult = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(),
    );
    final egpRows = (egpResult as AppOk<List<BudgetTransactionRow>>).value;
    expect(egpRows.length, equals(1));
    expect(egpRows.every((r) => r.currencyCode == 'EGP'), isTrue);
  });

  test('28. getBudgetTransactions — transfer excluded', () async {
    final acc1 = await createAccount(id: 'acc-tr1', householdId: _hh);
    final acc2 = await createAccount(id: 'acc-tr2', householdId: _hh);
    await income(_hh, acc1, 'op-inc-tr', 20000, '2024-03-01');
    await ledgerRepo.executeTransfer(
      ExecuteTransferParams(
        operationId: 'op-transfer',
        householdId: _hh,
        sourceAccountId: acc1,
        destinationAccountId: acc2,
        amountMinorUnits: 5000,
        currencyCode: 'EGP',
        effectiveDate: '2024-03-10',
        createdBy: 'test',
      ),
    );

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(),
    );
    final rows = (result as AppOk<List<BudgetTransactionRow>>).value;
    expect(rows, isEmpty);
  });

  test('29. getBudgetTransactions — opening balance excluded', () async {
    final acc = await createAccount(id: 'acc-ob', householdId: _hh);
    await ledgerRepo.recordOpeningBalance(
      RecordOpeningBalanceParams(
        operationId: 'op-ob',
        householdId: _hh,
        accountId: acc,
        amountMinorUnits: 100000,
        currencyCode: 'EGP',
        effectiveDate: '2024-03-01',
        createdBy: 'test',
      ),
    );

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(),
    );
    expect((result as AppOk<List<BudgetTransactionRow>>).value, isEmpty);
  });

  test('30. getBudgetTransactions — adjustment excluded', () async {
    final acc = await createAccount(id: 'acc-adj', householdId: _hh);
    await income(_hh, acc, 'op-inc-adj', 20000, '2024-03-01');
    await ledgerRepo.recordAdjustment(
      RecordAdjustmentParams(
        operationId: 'op-adj',
        householdId: _hh,
        accountId: acc,
        adjustmentAmountMinorUnits: -500,
        currencyCode: 'EGP',
        effectiveDate: '2024-03-10',
        createdBy: 'test',
        reason: 'correction',
      ),
    );

    final result = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-03-01',
      periodEnd: '2024-04-01',
      filter: const BudgetFilter(),
    );
    expect((result as AppOk<List<BudgetTransactionRow>>).value, isEmpty);
  });

  // ── Phase 4B gate tests (cross-query consistency) ─────────────────────────

  test('31. Dashboard total == report total for same period and filters', () async {
    final acc = await createAccount(id: 'acc-gate-b', householdId: _hh);
    await income(_hh, acc, 'op-gate-b-inc', 10000, '2024-05-10');
    await expense(_hh, acc, 'op-gate-b-exp1', 1500, '2024-05-12');
    await expense(_hh, acc, 'op-gate-b-exp2', 2500, '2024-05-20');

    final period = DashboardPeriod.custom(startDate: '2024-05-01', endDate: '2024-06-01');

    final dashFlows = await dashRepo.periodFlow(householdId: _hh, period: period);
    final reportFlows = await reportRepo.incomeExpenseFlow(
      FinancialReportRequest(householdId: _hh, period: period),
    );

    final dashExp = dashFlows
        .where((f) => f.currencyCode == 'EGP')
        .map((f) => f.grossExpenseMinorUnits)
        .fold(0, (a, b) => a + b);
    final reportExp = reportFlows
        .where((r) => r.currencyCode == 'EGP')
        .map((r) => r.grossExpenseMinorUnits)
        .fold(0, (a, b) => a + b);

    expect(dashExp, equals(4000));
    expect(reportExp, equals(4000));
    expect(dashExp, equals(reportExp));
  });

  test('32. Spouse-wallet reversals: all metrics correct', () async {
    await createAccount(id: 'hs-gate', householdId: _hh, type: 'homeSavingsCash');
    await createAccount(id: 'sw-gate', householdId: _hh, type: 'spouseCashWallet');
    await income(_hh, 'hs-gate', 'op-inc-sw-gate', 20000, '2024-05-01');

    await ledgerRepo.executeTransfer(
      ExecuteTransferParams(
        operationId: 'transfer-sw-gate',
        householdId: _hh,
        sourceAccountId: 'hs-gate',
        destinationAccountId: 'sw-gate',
        amountMinorUnits: 5000,
        currencyCode: 'EGP',
        effectiveDate: '2024-05-03',
        createdBy: 'test',
      ),
    );
    await expense(_hh, 'sw-gate', 'op-sw-exp', 2000, '2024-05-05');
    await reversal(_hh, 'op-sw-exp', 'rev-sw-exp', '2024-05-06');

    final period = DashboardPeriod.custom(startDate: '2024-05-01', endDate: '2024-06-01');
    final swReport = await reportRepo.spouseWalletReports(
      FinancialReportRequest(householdId: _hh, period: period),
    );

    expect(swReport.length, equals(1));
    final sw = swReport.first;
    expect(sw.periodFundedMinorUnits, equals(5000));
    expect(sw.periodSpentMinorUnits, equals(2000));
    expect(sw.periodReversalEffectMinorUnits, isNonZero);
    // Balance: 5000 funded - 2000 spent + reversal credit
    expect(sw.currentBalanceMinorUnits, equals(5000));
  });

  // ── Section 5: Budget mutations must NOT write to the operations table ─────

  test('33. Budget mutations do not write to operations table (no money moved)', () async {
    // Verify 0 operations before any budget work.
    Future<int> countOps() async {
      final rows = await db.customSelect('SELECT COUNT(*) AS cnt FROM operations').get();
      return rows.first.read<int>('cnt');
    }

    expect(await countOps(), equals(0), reason: 'should start with 0 ops');

    // 1. Create budget.
    final plan = plan0(id: 'budget-no-money', idempotencyKey: 'ik-no-money');
    await budgetRepo.createBudget(plan);
    expect(await countOps(), equals(0), reason: 'create must not write ops');

    // 2. Update budget.
    final updated = BudgetPlan(
      id: plan.id,
      householdId: plan.householdId,
      name: 'Updated Name',
      currencyCode: plan.currencyCode,
      limitMinorUnits: 99000,
      periodDefinition: plan.periodDefinition,
      filter: plan.filter,
      isArchived: plan.isArchived,
      createdAt: plan.createdAt,
      updatedAt: plan.updatedAt,
      idempotencyKey: plan.idempotencyKey,
      idempotencyPayload: plan.idempotencyPayload,
    );
    await budgetRepo.updateBudget(updated);
    expect(await countOps(), equals(0), reason: 'update must not write ops');

    // 3. Archive budget.
    await budgetRepo.archiveBudget(plan.id);
    expect(await countOps(), equals(0), reason: 'archive must not write ops');

    // 4. Restore budget.
    await budgetRepo.restoreBudget(plan.id);
    expect(await countOps(), equals(0), reason: 'restore must not write ops');
  });

  // ── Section 10: Report append-only vs budget restated distinction ──────────

  test('34. report_vs_budget semantic distinction: cross-period reversal', () async {
    // Expense in January; reversal in February.
    // Report: January STILL shows the gross expense (append-only).
    // Budget: January shows 0 consumption (restated — is_reversed=1 excluded).
    final acc = await createAccount(id: 'acc-sem-dist', householdId: _hh);
    await income(_hh, acc, 'op-sd-inc', 20000, '2024-01-01');
    await expense(_hh, acc, 'op-sd-exp', 6000, '2024-01-15');
    await reversal(_hh, 'op-sd-exp', 'rev-sd', '2024-02-03');

    // — Budget view (restated) —
    final budgetJan = await budgetRepo.getBudgetTransactions(
      householdId: _hh,
      currencyCode: 'EGP',
      periodStart: '2024-01-01',
      periodEnd: '2024-02-01',
      filter: const BudgetFilter(),
    );
    final budgetRows = (budgetJan as AppOk<List<BudgetTransactionRow>>).value;
    // Reversed expense is excluded → 0 consumption in January budget.
    expect(budgetRows, isEmpty, reason: 'budget restated: reversed expense excluded');

    // — Report view (append-only) —
    final reportJan = await reportRepo.incomeExpenseFlow(
      FinancialReportRequest(
        householdId: _hh,
        period: DashboardPeriod.custom(startDate: '2024-01-01', endDate: '2024-02-01'),
      ),
    );
    final janEgp = reportJan.firstWhere((r) => r.currencyCode == 'EGP');
    // Report shows the original expense (append-only); reversal not yet in Jan.
    expect(
      janEgp.grossExpenseMinorUnits,
      equals(6000),
      reason: 'report append-only: original expense still visible in Jan',
    );
    expect(
      janEgp.expenseReversalMinorUnits,
      equals(0),
      reason: 'report append-only: reversal was in Feb, not Jan',
    );
  });
}
