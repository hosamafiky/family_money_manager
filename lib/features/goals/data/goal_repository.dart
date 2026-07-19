import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/goals/application/complete_goal_params.dart';
import 'package:family_money_manager/features/goals/data/goal_transfer_write_boundary.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';

/// Repository abstraction for savings-goal persistence.
///
/// ARCHITECTURE RULES:
/// - No widget or provider calls these methods directly; all access is
///   through an application-layer use case.
/// - No Drift types appear in any method signature.
/// - Goal reserve balance is NEVER stored as a column — it is derived from
///   the ledger on every read via [getReserveBalance].
/// - Movements and revisions are append-only (no UPDATE or DELETE).
abstract interface class GoalRepository {
  // ── Goal CRUD ─────────────────────────────────────────────────────────────

  /// Creates a goal, its dedicated reserve account, and optionally an initial
  /// funding transfer — all within a single database transaction.
  ///
  /// When [initialFunding] is provided and its [GoalInitialFunding.amountMinorUnits]
  /// is > 0, the method inserts:
  ///   - the transfer operation row,
  ///   - debit entry on the source account,
  ///   - credit entry on the reserve account,
  ///   - an operation context, and
  ///   - the goal movement record.
  ///
  /// A balance check is performed inside the transaction. If the source does
  /// not have sufficient funds [AppInsufficientFunds] is returned and every
  /// row (goal, revision, reserve account) is rolled back.
  ///
  /// Idempotency:
  /// - Same key + same payload → returns existing goal.
  /// - Same key + different payload → [AppDuplicateConflict].
  Future<AppResult<SavingsGoal>> createGoal({
    required SavingsGoal goal,
    required GoalRevision initialRevision,
    required FinancialAccount reserveAccount,
    GoalInitialFunding? initialFunding,
  });

  /// Finds a goal by its ID within the same household.
  Future<AppResult<SavingsGoal?>> findGoalById(String goalId);

  /// Lists goals for a household, optionally including archived ones.
  Future<AppResult<List<SavingsGoal>>> listGoals({
    required String householdId,
    bool includeArchived = false,
  });

  /// Updates the goal status (and optional timestamp fields).
  ///
  /// Only [status], [completedAt], and [archivedAt] may be mutated.
  Future<AppResult<void>> updateGoalStatus({
    required String goalId,
    required GoalStatus status,
    String? completedAt,
    String? archivedAt,
  });

  /// Marks a goal as completed and returns the updated [SavingsGoal].
  ///
  /// All business validation (balance check, early-completion reason) must
  /// be performed in the use case before calling this method. The repository
  /// only persists the status transition and [completedAt] timestamp.
  Future<AppResult<SavingsGoal>> completeGoal(CompleteGoalParams params);

  // ── Revisions ─────────────────────────────────────────────────────────────

  /// Appends a new revision record. Never updates existing revisions.
  Future<AppResult<void>> addRevision(GoalRevision revision);

  /// Returns all revisions for a goal, ordered by [createdAt] ascending.
  Future<AppResult<List<GoalRevision>>> getRevisions(String goalId);

  // ── Movements ─────────────────────────────────────────────────────────────

  /// Appends a new movement record. Never updates existing movements.
  Future<AppResult<void>> addMovement(GoalMovement movement);

  /// Returns all movements for a goal, ordered by [createdAt] ascending.
  Future<AppResult<List<GoalMovement>>> getMovements(String goalId);

  // ── Balance derivation ────────────────────────────────────────────────────

  /// Derives the current balance of the goal's reserve account from the
  /// ledger (sum of CREDITs minus sum of DEBITs on [reserveAccountId]).
  ///
  /// This is the canonical balance — it is never stored as a column.
  Future<AppResult<int>> getReserveBalance({
    required String reserveAccountId,
    required String householdId,
  });

  // ── Lifecycle events ──────────────────────────────────────────────────────

  /// Inserts an immutable lifecycle event for this goal.
  ///
  /// Idempotency:
  /// - Same [idempotencyKey] + same [eventType] → [AppOk] (idempotent replay).
  /// - Same [idempotencyKey] + different [eventType] → [AppDuplicateConflict].
  /// - No [idempotencyKey] → always inserts a new row.
  Future<AppResult<GoalLifecycleEvent>> insertLifecycleEvent(
    GoalLifecycleEvent event,
  );

  // ── Reversal movement lookup ──────────────────────────────────────────────

  /// Finds the goal movement linked to [transferOperationId], if any.
  ///
  /// Returns null wrapped in [AppOk] if no movement references this operation.
  Future<AppResult<GoalMovement?>> findMovementByOperationId(
    String transferOperationId,
  );

  /// Atomically funds a goal reserve (transfer + movement) in one transaction.
  ///
  /// Same scoped idempotency semantics as ledger transfers: equivalent payload
  /// → [GoalTransferWriteResult.alreadyExists]; conflicting payload →
  /// [AppDuplicateConflict].
  Future<AppResult<GoalTransferWriteResult>> fundGoalTransfer(
    GoalAssociatedTransferParams params,
  );

  /// Atomically releases funds from a goal reserve in one transaction.
  Future<AppResult<GoalTransferWriteResult>> releaseGoalTransfer(
    GoalAssociatedTransferParams params,
  );

  /// Atomically reverses a goal-linked (or non-goal) ledger transfer.
  ///
  /// Single transaction covering: idempotency lookup, original operation /
  /// movement validation, reversal operation insert, mirrored ledger entries,
  /// original mark-as-reversed, operation context, and — when a goal movement
  /// existed — the linked reversal movement (`reversal_of_movement_id`).
  ///
  /// Idempotency:
  /// - Same key + equivalent payload → [AppOk] (original reversal preserved).
  /// - Same key + conflicting payload → [AppDuplicateConflict].
  Future<AppResult<void>> reverseGoalTransfer({
    required String originalOperationId,
    required String reversalOperationId,
    required String householdId,
    required String effectiveDate,
    required String createdBy,
    String? reason,
    String? idempotencyKey,
  });
}
