/// Parameters for completing a savings goal (Phase 5B.2 / 5B.3 / 5B.7).
library;

/// Parameters passed to [GoalRepository.completeGoal] and
/// [CompleteGoalUseCase.execute].
final class CompleteGoalParams {
  const CompleteGoalParams({
    required this.goalId,
    required this.householdId,
    String? idempotencyKey,
    this.earlyCompletion = false,
    this.earlyCompletionConfirmed = false,
    this.earlyCompletionReason,
    this.actorMetadata,
  }) : idempotencyKey = idempotencyKey ?? goalId;

  final String goalId;
  final String householdId;

  /// Stable per-user-intent key. Household-scoped.
  ///
  /// Same key + equivalent normalised payload → original completion result.
  /// Same key + conflicting payload → [AppDuplicateConflict].
  final String idempotencyKey;

  /// When true, the goal may be completed even if
  /// [GoalProgress.reserveBalanceMinorUnits] < [SavingsGoal.targetMinorUnits].
  final bool earlyCompletion;

  /// Must be true when [earlyCompletion] is true; enforces explicit
  /// acknowledgment of the early-completion decision.
  final bool earlyCompletionConfirmed;

  /// Required and non-empty when [earlyCompletion] is true.
  final String? earlyCompletionReason;

  /// Optional actor metadata (JSON string) included in the completion payload.
  final String? actorMetadata;
}
