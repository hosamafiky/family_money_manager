import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';

/// Abstract interface for budget persistence and transaction queries.
abstract interface class BudgetRepository {
  Future<AppResult<BudgetPlan>> createBudget(BudgetPlan plan);
  Future<AppResult<BudgetPlan>> updateBudget(BudgetPlan plan);
  Future<AppResult<void>> archiveBudget(String budgetId);
  Future<AppResult<void>> restoreBudget(String budgetId);
  Future<AppResult<BudgetPlan?>> findBudgetById(String budgetId);
  Future<AppResult<List<BudgetPlan>>> listBudgets({
    required String householdId,
    bool includeArchived = false,
  });

  /// Returns matching expense rows for budget consumption calculation.
  ///
  /// Uses **restated semantics**: reversed expenses (is_reversed = 1) contribute
  /// zero to budget consumption. This differs from the period-activity report
  /// model where every operation appears in its effective period.
  ///
  /// The query excludes:
  /// - Income, transfer, opening balance, adjustment operations.
  /// - Expense operations where is_reversed = 1 (fully reversed → zero consumed).
  /// - Reversal operations themselves (never negative consumption).
  ///
  /// Results are ordered by effective_date ASC, operation_id ASC.
  Future<AppResult<List<BudgetTransactionRow>>> getBudgetTransactions({
    required String householdId,
    required String currencyCode,
    required String periodStart,
    required String periodEnd,
    required BudgetFilter filter,
  });
}
