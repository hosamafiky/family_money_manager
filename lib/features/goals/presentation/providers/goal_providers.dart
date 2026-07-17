import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/goals/application/goal_use_cases.dart';
import 'package:family_money_manager/features/goals/data/drift_goal_repository.dart';
import 'package:family_money_manager/features/goals/data/goal_repository.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Repository ────────────────────────────────────────────────────────────

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return DriftGoalRepository(ref.watch(appDatabaseProvider));
});

// ── Use-case providers ────────────────────────────────────────────────────

final createGoalUseCaseProvider = Provider<CreateGoalUseCase>((ref) {
  return CreateGoalUseCase(
    goalRepository: ref.watch(goalRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
  );
});

final fundGoalUseCaseProvider = Provider<FundGoalUseCase>((ref) {
  return FundGoalUseCase(
    goalRepository: ref.watch(goalRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
  );
});

final releaseGoalFundsUseCaseProvider = Provider<ReleaseGoalFundsUseCase>((
  ref,
) {
  return ReleaseGoalFundsUseCase(
    goalRepository: ref.watch(goalRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
  );
});

final getGoalProgressUseCaseProvider = Provider<GetGoalProgressUseCase>((ref) {
  return GetGoalProgressUseCase(ref.watch(goalRepositoryProvider));
});

final updateGoalRevisionUseCaseProvider = Provider<UpdateGoalRevisionUseCase>((
  ref,
) {
  return UpdateGoalRevisionUseCase(ref.watch(goalRepositoryProvider));
});

final completeGoalUseCaseProvider = Provider<CompleteGoalUseCase>((ref) {
  return CompleteGoalUseCase(ref.watch(goalRepositoryProvider));
});

final archiveGoalUseCaseProvider = Provider<ArchiveGoalUseCase>((ref) {
  return ArchiveGoalUseCase(ref.watch(goalRepositoryProvider));
});

final restoreGoalUseCaseProvider = Provider<RestoreGoalUseCase>((ref) {
  return RestoreGoalUseCase(ref.watch(goalRepositoryProvider));
});

// ── Data providers ────────────────────────────────────────────────────────

/// Lists goals (active by default) for a household.
final goalsProvider =
    FutureProvider.family<AppResult<List<SavingsGoal>>, String>((
      ref,
      householdId,
    ) {
      final repo = ref.watch(goalRepositoryProvider);
      return repo.listGoals(householdId: householdId);
    });

/// Full progress snapshot for a single goal.
final goalProgressProvider =
    FutureProvider.family<AppResult<GoalProgress>, String>((ref, goalId) {
      final useCase = ref.watch(getGoalProgressUseCaseProvider);
      return useCase.execute(goalId);
    });

/// Single goal detail (raw entity, without derived progress).
final goalDetailProvider =
    FutureProvider.family<AppResult<SavingsGoal?>, String>((ref, goalId) {
      final repo = ref.watch(goalRepositoryProvider);
      return repo.findGoalById(goalId);
    });
