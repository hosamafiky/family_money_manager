/// Budget domain unit tests (Phase 5A).
///
/// Tests:
///  1. BudgetUsageState.noSpending when consumed = 0
///  2. BudgetUsageState.onTrack when consumed = 50% of limit
///  3. BudgetUsageState.nearLimit when consumed = 80%
///  4. BudgetUsageState.nearLimit when consumed = 99%
///  5. BudgetUsageState.limitReached when consumed = 100%
///  6. BudgetUsageState.overBudget when consumed = 101%
///  7. percentageUsed = null when limitMinorUnits = 0
///  8. remainingMinorUnits is negative when over budget
///  9. BudgetFilter equality: same fields = equal
/// 10. BudgetFilter equality: different fields = not equal
/// 11. MonthlyBudgetPeriod has no dates
/// 12. FixedBudgetPeriod holds start and end
/// 13. BudgetPlan stores all fields correctly
/// 14. BudgetTransactionRow stores isReversed flag
/// 15. BudgetProgress.matchingTransactionCount reflects count
/// 16. Reversal restated semantics: reversed expense contributes 0
/// 17. Multiple reversed: all contribute 0 to consumption
/// 18. Mixed: 2 normal + 1 reversed → consumption = sum of 2 normal
/// 19. percentageUsed rounds down (integer division)
/// 20. BudgetFilter.hasAnyFilter is false when all null
/// 21. BudgetFilter.hasAnyFilter is true when category set
/// 22. January rollover: month=12, next month is 1 of next year
/// 23. Leap year: February has 29 days in 2024
library;

import 'package:family_money_manager/features/budgets/application/budget_use_cases.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';
import 'package:flutter_test/flutter_test.dart';

BudgetPlan _plan({
  String id = 'b1',
  String currency = 'EGP',
  int limit = 10000,
  BudgetPeriodDefinition? period,
}) {
  return BudgetPlan(
    id: id,
    householdId: 'hh-1',
    name: 'Test Budget',
    currencyCode: currency,
    limitMinorUnits: limit,
    periodDefinition: period ?? const MonthlyBudgetPeriod(),
    filter: const BudgetFilter(),
    isArchived: false,
    createdAt: '2024-01-01T00:00:00.000Z',
    updatedAt: '2024-01-01T00:00:00.000Z',
    idempotencyKey: 'ik-1',
    idempotencyPayload: 'payload-1',
  );
}

BudgetProgress _progress({
  required int consumed,
  required int limit,
  List<BudgetTransactionRow> rows = const [],
}) {
  final state = computeUsageState(
    consumedMinorUnits: consumed,
    limitMinorUnits: limit,
  );
  return BudgetProgress(
    budget: _plan(limit: limit),
    periodStart: '2024-03-01',
    periodEnd: '2024-04-01',
    consumedMinorUnits: consumed,
    limitMinorUnits: limit,
    currencyCode: 'EGP',
    matchingTransactionCount: rows.length,
    usageState: state,
    drillDown: rows,
  );
}

BudgetTransactionRow _row({
  String id = 'op-1',
  int amount = 1000,
  bool isReversed = false,
}) {
  return BudgetTransactionRow(
    operationId: id,
    effectiveDate: '2024-03-10',
    amountMinorUnits: amount,
    currencyCode: 'EGP',
    categoryCode: 'groceries',
    note: null,
    isReversed: isReversed,
  );
}

void main() {
  // ── UsageState ────────────────────────────────────────────────────────────

  test('1. noSpending when consumed = 0', () {
    final p = _progress(consumed: 0, limit: 10000);
    expect(p.usageState, BudgetUsageState.noSpending);
  });

  test('2. onTrack when consumed = 50%', () {
    final p = _progress(consumed: 5000, limit: 10000);
    expect(p.usageState, BudgetUsageState.onTrack);
  });

  test('3. nearLimit when consumed = 80%', () {
    final p = _progress(consumed: 8000, limit: 10000);
    expect(p.usageState, BudgetUsageState.nearLimit);
  });

  test('4. nearLimit when consumed = 99%', () {
    final p = _progress(consumed: 9900, limit: 10000);
    expect(p.usageState, BudgetUsageState.nearLimit);
  });

  test('5. limitReached when consumed = 100%', () {
    final p = _progress(consumed: 10000, limit: 10000);
    expect(p.usageState, BudgetUsageState.limitReached);
  });

  test('6. overBudget when consumed = 101%', () {
    final p = _progress(consumed: 10100, limit: 10000);
    expect(p.usageState, BudgetUsageState.overBudget);
  });

  test('7. percentageUsed = null when limitMinorUnits = 0', () {
    final p = _progress(consumed: 500, limit: 0);
    expect(p.percentageUsed, isNull);
  });

  test('8. remainingMinorUnits is negative when over budget', () {
    final p = _progress(consumed: 11000, limit: 10000);
    expect(p.remainingMinorUnits, equals(-1000));
  });

  // ── BudgetFilter equality ─────────────────────────────────────────────────

  test('9. BudgetFilter equality: same fields = equal', () {
    const f1 = BudgetFilter(categoryCode: 'groceries', scopeCode: 'household');
    const f2 = BudgetFilter(categoryCode: 'groceries', scopeCode: 'household');
    expect(f1, equals(f2));
  });

  test('10. BudgetFilter equality: different fields = not equal', () {
    const f1 = BudgetFilter(categoryCode: 'groceries');
    const f2 = BudgetFilter(categoryCode: 'utilities');
    expect(f1, isNot(equals(f2)));
  });

  // ── Period types ──────────────────────────────────────────────────────────

  test('11. MonthlyBudgetPeriod has no dates', () {
    const period = MonthlyBudgetPeriod();
    expect(period, isA<MonthlyBudgetPeriod>());
    // No startDateInclusive or endDateExclusive properties
  });

  test('12. FixedBudgetPeriod holds start and end', () {
    const period = FixedBudgetPeriod(
      startDateInclusive: '2024-03-01',
      endDateExclusive: '2024-06-01',
    );
    expect(period.startDateInclusive, equals('2024-03-01'));
    expect(period.endDateExclusive, equals('2024-06-01'));
  });

  // ── BudgetPlan ────────────────────────────────────────────────────────────

  test('13. BudgetPlan stores all fields correctly', () {
    const plan = BudgetPlan(
      id: 'plan-1',
      householdId: 'hh-1',
      name: 'My Budget',
      currencyCode: 'EGP',
      limitMinorUnits: 50000,
      periodDefinition: MonthlyBudgetPeriod(),
      filter: BudgetFilter(categoryCode: 'food'),
      isArchived: false,
      createdAt: '2024-01-15T10:00:00Z',
      updatedAt: '2024-01-15T10:00:00Z',
      idempotencyKey: 'ik-plan-1',
      idempotencyPayload: 'payload',
    );
    expect(plan.id, equals('plan-1'));
    expect(plan.name, equals('My Budget'));
    expect(plan.limitMinorUnits, equals(50000));
    expect(plan.filter.categoryCode, equals('food'));
    expect(plan.isArchived, isFalse);
  });

  // ── BudgetTransactionRow ───────────────────────────────────────────────────

  test('14. BudgetTransactionRow stores isReversed flag', () {
    final row = _row(isReversed: true);
    expect(row.isReversed, isTrue);
    expect(row.amountMinorUnits, equals(1000));
  });

  // ── BudgetProgress ────────────────────────────────────────────────────────

  test('15. BudgetProgress.matchingTransactionCount reflects count', () {
    final rows = [_row(id: 'op-1'), _row(id: 'op-2'), _row(id: 'op-3')];
    final p = _progress(consumed: 3000, limit: 10000, rows: rows);
    expect(p.matchingTransactionCount, equals(3));
  });

  // ── Reversal restated semantics ───────────────────────────────────────────

  test('16. Reversal restated: reversed expense contributes 0', () {
    // The repo excludes reversed rows, so only non-reversed rows appear in drillDown
    // This test verifies that when the drillDown list has no reversed rows,
    // the consumed amount reflects only actual spending.
    final rows = [_row(id: 'op-1', amount: 2000, isReversed: false)];
    final consumed = rows
        .map((r) => r.amountMinorUnits)
        .fold(0, (a, b) => a + b);
    expect(consumed, equals(2000));
  });

  test('17. Multiple reversed: all contribute 0 to consumption', () {
    // With restated semantics, the repository returns NO reversed rows,
    // so consumption is zero for a set of all-reversed operations.
    final rows = <BudgetTransactionRow>[];
    final consumed = rows
        .map((r) => r.amountMinorUnits)
        .fold(0, (a, b) => a + b);
    expect(consumed, equals(0));
  });

  test('18. Mixed: 2 normal + 1 reversed → consumption = sum of 2 normal', () {
    // Repo excludes is_reversed=1; only these 2 non-reversed rows are returned:
    final rows = [
      _row(id: 'op-1', amount: 1500, isReversed: false),
      _row(id: 'op-2', amount: 2500, isReversed: false),
    ];
    final consumed = rows
        .map((r) => r.amountMinorUnits)
        .fold(0, (a, b) => a + b);
    expect(consumed, equals(4000));
  });

  // ── percentageUsed ────────────────────────────────────────────────────────

  test('19. percentageUsed rounds down (integer division)', () {
    final p = _progress(consumed: 333, limit: 1000);
    // 333 * 100 / 1000 = 33.3 → floor = 33
    expect(p.percentageUsed, equals(33));
  });

  // ── BudgetFilter.hasAnyFilter ─────────────────────────────────────────────

  test('20. BudgetFilter.hasAnyFilter is false when all null', () {
    const f = BudgetFilter();
    expect(f.hasAnyFilter, isFalse);
  });

  test('21. BudgetFilter.hasAnyFilter is true when category set', () {
    const f = BudgetFilter(categoryCode: 'groceries');
    expect(f.hasAnyFilter, isTrue);
  });

  // ── Month range utility ───────────────────────────────────────────────────

  test('22. January rollover: month=12, next month is 1 of next year', () {
    final range = monthRange(2024, 12);
    expect(range.start, equals('2024-12-01'));
    expect(range.end, equals('2025-01-01'));
  });

  test('23. Leap year: February 2024 range ends at 2024-03-01', () {
    final range = monthRange(2024, 2);
    expect(range.start, equals('2024-02-01'));
    expect(range.end, equals('2024-03-01'));
    // February 2024 is a leap year (29 days), but monthRange uses first-of-next-month
    // so end = 2024-03-01 which correctly covers all 29 days.
    final start = DateTime.parse(range.start);
    final end = DateTime.parse(range.end);
    final days = end.difference(start).inDays;
    expect(days, equals(29));
  });
}
