import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/features/budgets/data/budget_repository.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';
import 'package:uuid/uuid.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

const _uuid = Uuid();

String _nowUtc() => DateTime.now().toUtc().toIso8601String();

/// Derives the inclusive start and exclusive end for the current calendar month.
({String start, String end}) currentMonthRange() {
  final now = DateTime.now().toUtc();
  final start =
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-01';
  final nextMonth = now.month == 12
      ? DateTime(now.year + 1, 1, 1)
      : DateTime(now.year, now.month + 1, 1);
  final end =
      '${nextMonth.year.toString().padLeft(4, '0')}-'
      '${nextMonth.month.toString().padLeft(2, '0')}-01';
  return (start: start, end: end);
}

/// Derives the inclusive start and exclusive end for a given calendar month.
({String start, String end}) monthRange(int year, int month) {
  final start =
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-01';
  final nextYear = month == 12 ? year + 1 : year;
  final nextMonth = month == 12 ? 1 : month + 1;
  final end =
      '${nextYear.toString().padLeft(4, '0')}-'
      '${nextMonth.toString().padLeft(2, '0')}-01';
  return (start: start, end: end);
}

/// Builds a normalized idempotency payload string from budget creation params.
String buildIdempotencyPayload({
  required String householdId,
  required String name,
  required String currencyCode,
  required int limitMinorUnits,
  required BudgetPeriodDefinition periodDefinition,
  required BudgetFilter filter,
}) {
  final periodStr = switch (periodDefinition) {
    MonthlyBudgetPeriod() => 'monthly',
    FixedBudgetPeriod(:final startDateInclusive, :final endDateExclusive) =>
      'fixed:$startDateInclusive:$endDateExclusive',
  };
  return 'hh=$householdId|name=$name|cur=$currencyCode|'
      'limit=$limitMinorUnits|period=$periodStr|'
      'cat=${filter.categoryCode}|scope=${filter.scopeCode}|'
      'spender=${filter.spenderMemberId}|beneficiary=${filter.beneficiaryMemberId}|'
      'account=${filter.paymentAccountId}';
}

// ── CreateBudgetUseCase ────────────────────────────────────────────────────

final class CreateBudgetUseCase {
  const CreateBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<AppResult<BudgetPlan>> execute({
    required String householdId,
    required String name,
    required String currencyCode,
    required int limitMinorUnits,
    required BudgetPeriodDefinition periodDefinition,
    required BudgetFilter filter,
    String? idempotencyKey,
  }) async {
    if (name.trim().isEmpty) {
      return const AppValidationFailure(field: 'name', messageKey: 'errorBudgetNameEmpty');
    }
    if (limitMinorUnits <= 0) {
      return const AppValidationFailure(
        field: 'limitMinorUnits',
        messageKey: 'errorBudgetLimitZero',
      );
    }

    try {
      Currency.fromCode(currencyCode);
    } catch (_) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorBudgetCurrencyRequired',
      );
    }

    if (periodDefinition is FixedBudgetPeriod) {
      if (periodDefinition.startDateInclusive.compareTo(periodDefinition.endDateExclusive) >= 0) {
        return const AppValidationFailure(
          field: 'endDate',
          messageKey: 'errorBudgetEndBeforeStart',
        );
      }
    }

    final now = _nowUtc();
    final id = _uuid.v4();
    final payload = buildIdempotencyPayload(
      householdId: householdId,
      name: name.trim(),
      currencyCode: currencyCode,
      limitMinorUnits: limitMinorUnits,
      periodDefinition: periodDefinition,
      filter: filter,
    );

    final plan = BudgetPlan(
      id: id,
      householdId: householdId,
      name: name.trim(),
      currencyCode: currencyCode,
      limitMinorUnits: limitMinorUnits,
      periodDefinition: periodDefinition,
      filter: filter,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
      idempotencyKey: idempotencyKey ?? id,
      idempotencyPayload: payload,
    );

    return _repository.createBudget(plan);
  }
}

// ── UpdateBudgetUseCase ────────────────────────────────────────────────────

final class UpdateBudgetUseCase {
  const UpdateBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<AppResult<BudgetPlan>> execute({
    required String budgetId,
    required String householdId,
    String? name,
    int? limitMinorUnits,
    BudgetFilter? filter,
  }) async {
    final findResult = await _repository.findBudgetById(budgetId);
    if (findResult is! AppOk<BudgetPlan?>) return const AppPersistenceFailure();
    final existing = findResult.value;
    if (existing == null) return const AppNotFound();
    if (existing.householdId != householdId) {
      return const AppIsolationViolation();
    }

    final newName = name?.trim() ?? existing.name;
    if (newName.isEmpty) {
      return const AppValidationFailure(field: 'name', messageKey: 'errorBudgetNameEmpty');
    }

    final newLimit = limitMinorUnits ?? existing.limitMinorUnits;
    if (newLimit <= 0) {
      return const AppValidationFailure(
        field: 'limitMinorUnits',
        messageKey: 'errorBudgetLimitZero',
      );
    }

    final updated = BudgetPlan(
      id: existing.id,
      householdId: existing.householdId,
      name: newName,
      currencyCode: existing.currencyCode,
      limitMinorUnits: newLimit,
      periodDefinition: existing.periodDefinition,
      filter: filter ?? existing.filter,
      isArchived: existing.isArchived,
      createdAt: existing.createdAt,
      updatedAt: _nowUtc(),
      idempotencyKey: existing.idempotencyKey,
      idempotencyPayload: existing.idempotencyPayload,
    );

    return _repository.updateBudget(updated);
  }
}

// ── ArchiveBudgetUseCase ───────────────────────────────────────────────────

final class ArchiveBudgetUseCase {
  const ArchiveBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<AppResult<void>> execute(String budgetId) => _repository.archiveBudget(budgetId);
}

// ── RestoreBudgetUseCase ───────────────────────────────────────────────────

final class RestoreBudgetUseCase {
  const RestoreBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<AppResult<void>> execute(String budgetId) => _repository.restoreBudget(budgetId);
}

// ── GetBudgetUseCase ───────────────────────────────────────────────────────

final class GetBudgetUseCase {
  const GetBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<AppResult<BudgetPlan?>> execute(String budgetId) => _repository.findBudgetById(budgetId);
}

// ── ListBudgetsUseCase ─────────────────────────────────────────────────────

final class ListBudgetsUseCase {
  const ListBudgetsUseCase(this._repository);

  final BudgetRepository _repository;

  Future<AppResult<List<BudgetPlan>>> execute({
    required String householdId,
    bool includeArchived = false,
  }) => _repository.listBudgets(householdId: householdId, includeArchived: includeArchived);
}

// ── GetBudgetProgressUseCase ───────────────────────────────────────────────

final class GetBudgetProgressUseCase {
  const GetBudgetProgressUseCase(this._repository);

  final BudgetRepository _repository;

  Future<AppResult<BudgetProgress>> execute({
    required String budgetId,
    String? overridePeriodStart,
    String? overridePeriodEnd,
  }) async {
    final findResult = await _repository.findBudgetById(budgetId);
    if (findResult is! AppOk<BudgetPlan?>) return const AppPersistenceFailure();
    final plan = findResult.value;
    if (plan == null) return const AppNotFound();

    final ({String start, String end}) periodRange;
    switch (plan.periodDefinition) {
      case MonthlyBudgetPeriod():
        if (overridePeriodStart != null && overridePeriodEnd != null) {
          periodRange = (start: overridePeriodStart, end: overridePeriodEnd);
        } else {
          periodRange = currentMonthRange();
        }
      case FixedBudgetPeriod(:final startDateInclusive, :final endDateExclusive):
        periodRange = (start: startDateInclusive, end: endDateExclusive);
    }

    final txResult = await _repository.getBudgetTransactions(
      householdId: plan.householdId,
      currencyCode: plan.currencyCode,
      periodStart: periodRange.start,
      periodEnd: periodRange.end,
      filter: plan.filter,
    );

    if (txResult is! AppOk<List<BudgetTransactionRow>>) {
      return const AppPersistenceFailure();
    }
    final rows = txResult.value;

    final consumed = rows.map((r) => r.amountMinorUnits).fold(0, (a, b) => a + b);

    final usageState = computeUsageState(
      consumedMinorUnits: consumed,
      limitMinorUnits: plan.limitMinorUnits,
    );

    return AppOk(
      BudgetProgress(
        budget: plan,
        periodStart: periodRange.start,
        periodEnd: periodRange.end,
        consumedMinorUnits: consumed,
        limitMinorUnits: plan.limitMinorUnits,
        currencyCode: plan.currencyCode,
        matchingTransactionCount: rows.length,
        usageState: usageState,
        drillDown: rows,
      ),
    );
  }
}

// ── GetBudgetHistoryUseCase ────────────────────────────────────────────────

final class GetBudgetHistoryUseCase {
  const GetBudgetHistoryUseCase(this._repository);

  final BudgetRepository _repository;

  /// Returns progress for the last [numberOfMonths] calendar months.
  /// Only meaningful for [MonthlyBudgetPeriod] budgets.
  Future<AppResult<List<BudgetProgress>>> execute({
    required String budgetId,
    int numberOfMonths = 6,
  }) async {
    final findResult = await _repository.findBudgetById(budgetId);
    if (findResult is! AppOk<BudgetPlan?>) return const AppPersistenceFailure();
    final plan = findResult.value;
    if (plan == null) return const AppNotFound();

    final now = DateTime.now().toUtc();
    final history = <BudgetProgress>[];

    for (var i = 0; i < numberOfMonths; i++) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final range = monthRange(targetDate.year, targetDate.month);

      final txResult = await _repository.getBudgetTransactions(
        householdId: plan.householdId,
        currencyCode: plan.currencyCode,
        periodStart: range.start,
        periodEnd: range.end,
        filter: plan.filter,
      );

      if (txResult is! AppOk<List<BudgetTransactionRow>>) continue;
      final rows = txResult.value;

      final consumed = rows.map((r) => r.amountMinorUnits).fold(0, (a, b) => a + b);

      history.add(
        BudgetProgress(
          budget: plan,
          periodStart: range.start,
          periodEnd: range.end,
          consumedMinorUnits: consumed,
          limitMinorUnits: plan.limitMinorUnits,
          currencyCode: plan.currencyCode,
          matchingTransactionCount: rows.length,
          usageState: computeUsageState(
            consumedMinorUnits: consumed,
            limitMinorUnits: plan.limitMinorUnits,
          ),
          drillDown: rows,
        ),
      );
    }

    return AppOk(history);
  }
}

// ── GetBudgetTransactionsUseCase ──────────────────────────────────────────

final class GetBudgetTransactionsUseCase {
  const GetBudgetTransactionsUseCase(this._repository);

  final BudgetRepository _repository;

  Future<AppResult<List<BudgetTransactionRow>>> execute({
    required String householdId,
    required String currencyCode,
    required String periodStart,
    required String periodEnd,
    required BudgetFilter filter,
  }) => _repository.getBudgetTransactions(
    householdId: householdId,
    currencyCode: currencyCode,
    periodStart: periodStart,
    periodEnd: periodEnd,
    filter: filter,
  );
}
