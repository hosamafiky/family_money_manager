/// Parameters for completing a savings goal (Phase 5B.2).
library;

/// Parameters passed to [GoalRepository.completeGoal] and
/// [CompleteGoalUseCase.execute].
final class CompleteGoalParams {
  const CompleteGoalParams({
    required this.goalId,
    required this.householdId,
    this.earlyCompletion = false,
    this.earlyCompletionReason,
  });

  final String goalId;
  final String householdId;

  /// When true, the goal may be completed even if
  /// [GoalProgress.reserveBalanceMinorUnits] < [SavingsGoal.targetMinorUnits].
  final bool earlyCompletion;

  /// Required and non-empty when [earlyCompletion] is true.
  final String? earlyCompletionReason;
}
