import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/features/budgets/application/budget_use_cases.dart';
import 'package:family_money_manager/features/budgets/data/budget_repository.dart';
import 'package:family_money_manager/features/budgets/data/drift_budget_repository.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Repository ────────────────────────────────────────────────────────────

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return DriftBudgetRepository(ref.watch(appDatabaseProvider));
});

// ── Use-case providers ────────────────────────────────────────────────────

final createBudgetUseCaseProvider = Provider<CreateBudgetUseCase>((ref) {
  return CreateBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

final updateBudgetUseCaseProvider = Provider<UpdateBudgetUseCase>((ref) {
  return UpdateBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

final archiveBudgetUseCaseProvider = Provider<ArchiveBudgetUseCase>((ref) {
  return ArchiveBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

final restoreBudgetUseCaseProvider = Provider<RestoreBudgetUseCase>((ref) {
  return RestoreBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

final listBudgetsUseCaseProvider = Provider<ListBudgetsUseCase>((ref) {
  return ListBudgetsUseCase(ref.watch(budgetRepositoryProvider));
});

final getBudgetProgressUseCaseProvider = Provider<GetBudgetProgressUseCase>((ref) {
  return GetBudgetProgressUseCase(ref.watch(budgetRepositoryProvider));
});

final getBudgetHistoryUseCaseProvider = Provider<GetBudgetHistoryUseCase>((ref) {
  return GetBudgetHistoryUseCase(ref.watch(budgetRepositoryProvider));
});

// ── Data providers ────────────────────────────────────────────────────────

/// List budgets (active only by default) for a household.
final budgetsProvider = FutureProvider.family<AppResult<List<BudgetPlan>>, String>((
  ref,
  householdId,
) {
  final useCase = ref.watch(listBudgetsUseCaseProvider);
  return useCase.execute(householdId: householdId);
});

/// Budget progress for a single budget (current period).
final budgetProgressProvider = FutureProvider.family<AppResult<BudgetProgress>, String>((
  ref,
  budgetId,
) {
  final useCase = ref.watch(getBudgetProgressUseCaseProvider);
  return useCase.execute(budgetId: budgetId);
});

/// Budget history for monthly budgets (last 6 months by default).
final budgetHistoryProvider = FutureProvider.family<AppResult<List<BudgetProgress>>, String>((
  ref,
  budgetId,
) {
  final useCase = ref.watch(getBudgetHistoryUseCaseProvider);
  return useCase.execute(budgetId: budgetId, numberOfMonths: 6);
});

/// Single budget detail (plan only, no progress calculation).
final budgetDetailProvider = FutureProvider.family<AppResult<BudgetPlan?>, String>((ref, budgetId) {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.findBudgetById(budgetId);
});
