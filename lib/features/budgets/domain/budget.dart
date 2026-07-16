/// Immutable domain entities — no Flutter, Drift, or JSON dependencies.
library;

/// Stable client-generated budget identifier.
typedef BudgetId = String;

/// Period type for a budget.
enum BudgetPeriodType { monthly, fixed }

/// Status derived from budget progress.
enum BudgetUsageState {
  noSpending, // 0%
  onTrack, // > 0% and < 80%
  nearLimit, // >= 80% and < 100%
  limitReached, // == 100%
  overBudget, // > 100%
}

/// Defines when a budget applies.
sealed class BudgetPeriodDefinition {
  const BudgetPeriodDefinition();
}

final class MonthlyBudgetPeriod extends BudgetPeriodDefinition {
  const MonthlyBudgetPeriod();
}

final class FixedBudgetPeriod extends BudgetPeriodDefinition {
  const FixedBudgetPeriod({
    required this.startDateInclusive,
    required this.endDateExclusive,
  });

  /// ISO 8601 date string yyyy-MM-dd (inclusive start).
  final String startDateInclusive;

  /// ISO 8601 date string yyyy-MM-dd (exclusive end).
  final String endDateExclusive;
}

/// Filters controlling which expenses count toward this budget.
final class BudgetFilter {
  const BudgetFilter({
    this.categoryCode,
    this.scopeCode,
    this.spenderMemberId,
    this.beneficiaryMemberId,
    this.paymentAccountId,
  });

  final String? categoryCode;
  final String? scopeCode;
  final String? spenderMemberId;
  final String? beneficiaryMemberId;
  final String? paymentAccountId;

  bool get hasAnyFilter =>
      categoryCode != null ||
      scopeCode != null ||
      spenderMemberId != null ||
      beneficiaryMemberId != null ||
      paymentAccountId != null;

  BudgetFilter copyWith({
    Object? categoryCode = _absent,
    Object? scopeCode = _absent,
    Object? spenderMemberId = _absent,
    Object? beneficiaryMemberId = _absent,
    Object? paymentAccountId = _absent,
  }) {
    return BudgetFilter(
      categoryCode: categoryCode == _absent
          ? this.categoryCode
          : categoryCode as String?,
      scopeCode: scopeCode == _absent ? this.scopeCode : scopeCode as String?,
      spenderMemberId: spenderMemberId == _absent
          ? this.spenderMemberId
          : spenderMemberId as String?,
      beneficiaryMemberId: beneficiaryMemberId == _absent
          ? this.beneficiaryMemberId
          : beneficiaryMemberId as String?,
      paymentAccountId: paymentAccountId == _absent
          ? this.paymentAccountId
          : paymentAccountId as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetFilter &&
          other.categoryCode == categoryCode &&
          other.scopeCode == scopeCode &&
          other.spenderMemberId == spenderMemberId &&
          other.beneficiaryMemberId == beneficiaryMemberId &&
          other.paymentAccountId == paymentAccountId;

  @override
  int get hashCode => Object.hash(
    categoryCode,
    scopeCode,
    spenderMemberId,
    beneficiaryMemberId,
    paymentAccountId,
  );
}

// Sentinel for distinguishing null from absent in copyWith.
const _absent = Object();

/// Core budget planning object.
/// Does not contain money. Does not move money. Does not create accounts.
final class BudgetPlan {
  const BudgetPlan({
    required this.id,
    required this.householdId,
    required this.name,
    required this.currencyCode,
    required this.limitMinorUnits,
    required this.periodDefinition,
    required this.filter,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    required this.idempotencyKey,
    required this.idempotencyPayload,
  });

  final BudgetId id;
  final String householdId;
  final String name;
  final String currencyCode;
  final int limitMinorUnits;
  final BudgetPeriodDefinition periodDefinition;
  final BudgetFilter filter;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;
  final String idempotencyKey;
  final String idempotencyPayload;
}

/// A single expense transaction row contributing to budget consumption.
final class BudgetTransactionRow {
  const BudgetTransactionRow({
    required this.operationId,
    required this.effectiveDate,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.categoryCode,
    required this.note,
    required this.isReversed,
  });

  final String operationId;
  final String effectiveDate;
  final int amountMinorUnits;
  final String currencyCode;
  final String? categoryCode;
  final String? note;
  final bool isReversed;
}

/// Computed budget progress for a specific period.
final class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.periodStart,
    required this.periodEnd,
    required this.consumedMinorUnits,
    required this.limitMinorUnits,
    required this.currencyCode,
    required this.matchingTransactionCount,
    required this.usageState,
    required this.drillDown,
  });

  final BudgetPlan budget;
  final String periodStart;
  final String periodEnd;
  final int consumedMinorUnits;
  final int limitMinorUnits;
  final String currencyCode;
  final int matchingTransactionCount;
  final BudgetUsageState usageState;
  final List<BudgetTransactionRow> drillDown;

  int get remainingMinorUnits => limitMinorUnits - consumedMinorUnits;

  /// Percentage used, as integer 0–(possibly >100). Never uses floating-point money.
  /// Returns null when limitMinorUnits == 0.
  int? get percentageUsed => limitMinorUnits == 0
      ? null
      : (consumedMinorUnits * 100) ~/ limitMinorUnits;
}

/// Computes [BudgetUsageState] from consumed and limit amounts.
BudgetUsageState computeUsageState({
  required int consumedMinorUnits,
  required int limitMinorUnits,
}) {
  if (limitMinorUnits == 0) return BudgetUsageState.noSpending;
  if (consumedMinorUnits == 0) return BudgetUsageState.noSpending;
  final pct = (consumedMinorUnits * 100) ~/ limitMinorUnits;
  if (pct >= 100) {
    if (consumedMinorUnits == limitMinorUnits) {
      return BudgetUsageState.limitReached;
    }
    return BudgetUsageState.overBudget;
  }
  if (pct >= 80) return BudgetUsageState.nearLimit;
  return BudgetUsageState.onTrack;
}
