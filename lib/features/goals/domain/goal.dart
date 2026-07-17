/// Immutable domain types for the Savings Goals feature.
///
/// No Flutter, Drift, or JSON dependencies.
/// All monetary values use integer minor units (e.g. cents/piastres).
library;

/// Stable client-generated identifier for a savings goal.
typedef GoalId = String;

/// Lifecycle status of a savings goal.
enum GoalStatus { active, targetReached, completed, archived }

/// Whether money is flowing into or out of a goal reserve.
enum GoalMovementType { funding, release }

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
/// Independent from [GoalStatus].
enum GoalProgressState {
  /// Balance is exactly zero.
  notStarted,

  /// 0 < balance < target.
  inProgress,

  /// balance >= target (at or above target).
  targetReached,

  /// balance > target (strictly over).
  overfunded,
}

/// A single funding or release movement linking a ledger transfer to a goal.
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
  });

  final String id;
  final GoalId goalId;
  final String householdId;

  /// The [operations.id] of the underlying ledger transfer.
  final String transferOperationId;

  final GoalMovementType movementType;

  /// UTC ISO 8601 timestamp.
  final String createdAt;

  /// Required when [movementType] == [GoalMovementType.release].
  final String? releaseReason;
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

  // ── Convenience delegators ───────────────────────────────────────────────

  String get name => currentRevision.name;
  GoalPurpose get purpose => currentRevision.purpose;
  int get targetMinorUnits => currentRevision.targetMinorUnits;
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
      (goal.targetMinorUnits - reserveBalanceMinorUnits).clamp(0, goal.targetMinorUnits);

  /// How much the reserve exceeds the target. Zero when at or under target.
  int get overfundedMinorUnits =>
      (reserveBalanceMinorUnits - goal.targetMinorUnits).clamp(0, reserveBalanceMinorUnits);

  bool get isTargetReached => reserveBalanceMinorUnits >= goal.targetMinorUnits;

  /// Percentage funded as an integer (0–possibly >100).
  /// Returns null when target == 0.
  int? get percentageFunded =>
      goal.targetMinorUnits == 0 ? null : (reserveBalanceMinorUnits * 100) ~/ goal.targetMinorUnits;
}
