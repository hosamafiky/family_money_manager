/// Immutable domain types for the Savings Goals feature.
///
/// No Flutter, Drift, or JSON dependencies.
/// All monetary values use integer minor units (e.g. cents/piastres).
library;

/// Stable client-generated identifier for a savings goal.
typedef GoalId = String;

/// Persisted lifecycle status of a savings goal.
///
/// Phase 5B.8: only `active`, `completed`, and `archived` are persisted.
/// Funding progress (`notStarted` / `inProgress` / `targetReached` /
/// `overfunded`) is derived solely via [GoalProgressState] from the reserve
/// ledger balance vs the current target revision — never written to `goals.status`.
enum GoalStatus { active, completed, archived }

/// Whether money is flowing into or out of a goal reserve, or reversing a prior movement.
enum GoalMovementType { funding, release, reversal }

/// Lifecycle event category for [GoalLifecycleEvent].
enum GoalLifecycleEventType {
  created,
  completed,
  archived,
  restored;

  String get code => name;
}

/// The intended purpose of a savings goal.
enum GoalPurpose {
  emergencyFund,
  homePurchase,
  education,
  travel,
  majorPurchase,
  familyEvent,
  other;

  /// Stable non-localized code stored in the database.
  String get code => name;
}

/// Derived progress state — computed from balance vs target.
/// Independent from [GoalStatus]. Never persisted.
enum GoalProgressState {
  /// Balance is exactly zero.
  notStarted,

  /// 0 < balance < target.
  inProgress,

  /// balance == target (exact).
  targetReached,

  /// balance > target (strictly over).
  overfunded;

  /// Sole canonical derivation path: reserve balance vs current target.
  static GoalProgressState fromBalance(int balance, int target) {
    if (balance == 0) return GoalProgressState.notStarted;
    if (balance > target) return GoalProgressState.overfunded;
    if (balance == target) return GoalProgressState.targetReached;
    return GoalProgressState.inProgress;
  }
}

/// A single funding, release, or reversal movement linking a ledger transfer to a goal.
///
/// Append-only: no UPDATE or DELETE is ever issued on this record.
final class GoalMovement {
  const GoalMovement({
    required this.id,
    required this.goalId,
    required this.householdId,
    required this.transferOperationId,
    required this.movementType,
    required this.createdAt,
    this.releaseReason,
    this.reversalOfMovementId,
  });

  final String id;
  final GoalId goalId;
  final String householdId;

  /// The [operations.id] of the underlying ledger transfer or reversal operation.
  final String transferOperationId;

  final GoalMovementType movementType;

  /// UTC ISO 8601 timestamp.
  final String createdAt;

  /// Required when [movementType] == [GoalMovementType.release].
  final String? releaseReason;

  /// When [movementType] == [GoalMovementType.reversal], the ID of the
  /// original movement being reversed. Added in Phase 5B.4.
  final String? reversalOfMovementId;
}

/// An immutable lifecycle event recording a goal status transition.
///
/// Write-once: no UPDATE or DELETE is permitted (enforced by DB triggers).
final class GoalLifecycleEvent {
  const GoalLifecycleEvent({
    required this.id,
    required this.goalId,
    required this.householdId,
    required this.eventType,
    required this.effectiveAt,
    required this.createdAt,
    this.completionType,
    this.earlyCompletionReason,
    this.earlyCompletionConfirmed = false,
    this.idempotencyKey,
    this.actorMetadata,
  });

  final String id;
  final GoalId goalId;
  final String householdId;
  final GoalLifecycleEventType eventType;

  /// 'normal' or 'early' — only for [GoalLifecycleEventType.completed].
  final String? completionType;

  /// Non-empty when [completionType] == 'early'.
  final String? earlyCompletionReason;

  /// Must be true when [completionType] == 'early'.
  final bool earlyCompletionConfirmed;

  /// Optional per-call idempotency key scoped to the events table.
  final String? idempotencyKey;

  /// Arbitrary actor metadata (JSON string).
  final String? actorMetadata;

  /// Business-effective timestamp (ISO 8601 UTC).
  final String effectiveAt;

  /// Row-creation timestamp (ISO 8601 UTC).
  final String createdAt;
}

/// An auditable snapshot of goal definition at a point in time.
///
/// Append-only: a new revision is created for every definition change;
/// the existing revision is never updated.
final class GoalRevision {
  const GoalRevision({
    required this.id,
    required this.goalId,
    required this.householdId,
    required this.name,
    required this.purpose,
    required this.targetMinorUnits,
    required this.currencyCode,
    required this.createdAt,
    required this.revisionReason,
    this.targetDate,
    this.beneficiaryMemberId,
  });

  final String id;
  final GoalId goalId;
  final String householdId;
  final String name;
  final GoalPurpose purpose;

  /// Target amount in currency minor units. Must be > 0.
  final int targetMinorUnits;

  /// ISO 4217 currency code. Immutable across revisions.
  final String currencyCode;

  /// UTC ISO 8601 timestamp.
  final String createdAt;

  /// Human-readable reason for this revision (e.g. "initial", "target updated").
  final String revisionReason;

  /// Optional ISO 8601 date (yyyy-MM-dd) the user wants to reach the goal by.
  final String? targetDate;

  /// Optional household member ID of the primary beneficiary.
  final String? beneficiaryMemberId;
}

/// Core savings-goal entity.
///
/// Currency is immutable after creation.
/// The reserve account balance is NEVER stored here; it is derived from
/// the ledger on every read (FINANCIAL_MODEL §3).
final class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.householdId,
    required this.reserveAccountId,
    required this.currencyCode,
    required this.status,
    required this.currentRevision,
    required this.createdAt,
    required this.idempotencyKey,
    this.completedAt,
    this.archivedAt,
    this.earlyCompletionReason,
  });

  final GoalId id;
  final String householdId;

  /// The [financial_accounts.id] of the dedicated goalReserve account.
  final String reserveAccountId;

  /// ISO 4217 currency code. Immutable after creation.
  final String currencyCode;

  final GoalStatus status;

  /// The latest [GoalRevision] defining name, target, and purpose.
  final GoalRevision currentRevision;

  /// UTC ISO 8601 timestamp.
  final String createdAt;

  final String idempotencyKey;

  /// Set when status transitions to [GoalStatus.completed].
  final String? completedAt;

  /// Set when status transitions to [GoalStatus.archived].
  final String? archivedAt;

  /// Stored when earlyCompletion = true (Phase 5B.3).
  final String? earlyCompletionReason;

  // ── Convenience delegators ───────────────────────────────────────────────

  String get name => currentRevision.name;
  GoalPurpose get purpose => currentRevision.purpose;
  int get targetMinorUnits => currentRevision.targetMinorUnits;
}

/// Parameters for optional initial funding during goal creation.
///
/// When provided to [GoalRepository.createGoal], the transfer, ledger entries,
/// and movement are all inserted inside the same database transaction as the
/// goal row — guaranteeing full atomicity and rollback on any failure.
final class GoalInitialFunding {
  const GoalInitialFunding({
    required this.operationId,
    required this.idempotencyKey,
    required this.sourceAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.description,
    required this.movementId,
    required this.movementCreatedAt,
  });

  final String operationId;
  final String idempotencyKey;
  final String sourceAccountId;
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String description;
  final String movementId;
  final String movementCreatedAt;
}

/// Derived progress snapshot — never persisted.
///
/// Assembled by [GetGoalProgressUseCase] from live ledger data.
final class GoalProgress {
  const GoalProgress({
    required this.goal,
    required this.reserveBalanceMinorUnits,
    required this.currencyCode,
    required this.progressState,
    required this.movements,
    required this.revisions,
  });

  final SavingsGoal goal;

  /// Current ledger-derived balance of the reserve account.
  final int reserveBalanceMinorUnits;

  final String currencyCode;
  final GoalProgressState progressState;

  /// All funding and release movements, ordered by creation time.
  final List<GoalMovement> movements;

  /// All revisions, ordered by creation time (oldest first).
  final List<GoalRevision> revisions;

  // ── Derived values ───────────────────────────────────────────────────────

  int get targetMinorUnits => goal.targetMinorUnits;

  /// How much more needs to be funded to reach the target. Zero when at or over target.
  int get remainingMinorUnits =>
      (goal.targetMinorUnits - reserveBalanceMinorUnits).clamp(
        0,
        goal.targetMinorUnits,
      );

  /// How much the reserve exceeds the target. Zero when at or under target.
  int get overfundedMinorUnits =>
      (reserveBalanceMinorUnits - goal.targetMinorUnits).clamp(
        0,
        reserveBalanceMinorUnits,
      );

  bool get isTargetReached => reserveBalanceMinorUnits >= goal.targetMinorUnits;

  /// Percentage funded as an integer (0–possibly >100).
  /// Returns null when target == 0.
  int? get percentageFunded => goal.targetMinorUnits == 0
      ? null
      : (reserveBalanceMinorUnits * 100) ~/ goal.targetMinorUnits;
}
