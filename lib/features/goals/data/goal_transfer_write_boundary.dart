import 'package:family_money_manager/features/goals/domain/goal.dart';

/// Outcome of a goal-associated transfer write boundary.
enum GoalTransferWriteResult {
  /// Fresh insert of operation + legs + context + movement.
  created,

  /// Equivalent scoped idempotency replay; no new rows written.
  alreadyExists,
}

/// Kind of goal-associated transfer handled by the unified write boundary.
enum GoalAssociatedTransferKind { funding, release, reversal }

/// Steps used for failure injection inside the unified write boundary.
///
/// Production code defaults to [none]; tests pass non-none values via
/// `DriftGoalRepository(debugFailAfter: ...)`.
enum GoalTransferFailAfter {
  none,
  operationInsert,
  firstLedgerEntry,
  secondLedgerEntry,
  operationContext,
  goalMovement,
  preCommit,
}

/// Parameters for a funding or release transfer that also writes a goal movement.
final class GoalAssociatedTransferParams {
  const GoalAssociatedTransferParams.funding({
    required this.goalId,
    required this.householdId,
    required this.operationId,
    required this.idempotencyKey,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    required this.description,
    required this.movementId,
    required this.movementCreatedAt,
  }) : kind = GoalAssociatedTransferKind.funding,
       releaseReason = null;

  const GoalAssociatedTransferParams.release({
    required this.goalId,
    required this.householdId,
    required this.operationId,
    required this.idempotencyKey,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    required this.description,
    required this.movementId,
    required this.movementCreatedAt,
    required String this.releaseReason,
  }) : kind = GoalAssociatedTransferKind.release;

  final GoalAssociatedTransferKind kind;
  final String goalId;
  final String householdId;
  final String operationId;
  final String idempotencyKey;
  final String sourceAccountId;
  final String destinationAccountId;
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String createdBy;
  final String description;
  final String movementId;
  final String movementCreatedAt;
  final String? releaseReason;

  GoalMovementType get movementType => switch (kind) {
    GoalAssociatedTransferKind.funding => GoalMovementType.funding,
    GoalAssociatedTransferKind.release => GoalMovementType.release,
    GoalAssociatedTransferKind.reversal => GoalMovementType.reversal,
  };
}

/// Thrown by test-only fail-after hooks to abort the write transaction mid-flight.
final class GoalTransferInjectedFailure implements Exception {
  const GoalTransferInjectedFailure(this.after);

  final GoalTransferFailAfter after;

  @override
  String toString() => 'GoalTransferInjectedFailure($after)';
}

/// Steps used for failure injection inside goal lifecycle write boundaries
/// (complete / archive / restore).
///
/// Production code defaults to [none]; tests pass non-none values via
/// `DriftGoalRepository(debugLifecycleFailAfter: ...)`.
enum GoalLifecycleFailAfter {
  none,
  afterGoalValidation,
  afterBalanceCalculation,
  afterGoalStatusUpdate,
  afterCompletionTimestampUpdate,
  afterLifecycleEventInsertion,
  preCommit,
}

/// Thrown by test-only lifecycle fail-after hooks to abort mid-transaction.
final class GoalLifecycleInjectedFailure implements Exception {
  const GoalLifecycleInjectedFailure(this.after);

  final GoalLifecycleFailAfter after;

  @override
  String toString() => 'GoalLifecycleInjectedFailure($after)';
}
