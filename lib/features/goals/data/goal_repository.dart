import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
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

  /// Creates a goal and its dedicated reserve account atomically.
  ///
  /// Idempotency:
  /// - Same key + same payload → returns existing goal.
  /// - Same key + different payload → [AppDuplicateConflict].
  Future<AppResult<SavingsGoal>> createGoal({
    required SavingsGoal goal,
    required GoalRevision initialRevision,
    required FinancialAccount reserveAccount,
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
}
