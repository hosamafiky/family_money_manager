import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/tables/financial_accounts_table.dart';

/// Drift table definition for the `goals` table (Phase 5B).
///
/// A savings goal pairs a definition (name, target, purpose) with a dedicated
/// goalReserve financial account. The reserve account balance is NEVER stored
/// here — it is derived from the ledger on every read (FINANCIAL_MODEL §3).
///
/// MUTABILITY: status, completed_at, archived_at may be updated via status
/// transitions. All other fields are immutable after creation.
///
/// IDEMPOTENCY: (household_id, idempotency_key) must be unique.
///
/// Row type: [DbGoal].
@DataClassName('DbGoal')
class GoalsTable extends Table {
  /// Stable client-generated UUID. Primary key.
  TextColumn get id => text()();

  /// FK to households.id.
  TextColumn get householdId => text()();

  /// FK to financial_accounts.id — the dedicated goalReserve account.
  TextColumn get reserveAccountId => text().references(FinancialAccounts, #id)();

  /// ISO 4217 currency code. Immutable after creation.
  TextColumn get currencyCode => text()();

  /// 'active', 'targetReached', 'completed', 'archived'.
  TextColumn get status => text()();

  /// Unique per (household_id, idempotency_key).
  TextColumn get idempotencyKey => text()();

  /// Serialised creation-payload fingerprint for conflict detection.
  TextColumn get idempotencyPayload => text()();

  /// UTC ISO 8601 creation timestamp.
  TextColumn get createdAt => text()();

  /// Set when status = 'completed'.
  TextColumn get completedAt => text().nullable()();

  /// Set when status = 'archived'.
  TextColumn get archivedAt => text().nullable()();

  /// Schema version for forward-compatibility (always 1 in Phase 5B).
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'goals';
}

/// Drift table definition for the `goal_revisions` table (Phase 5B).
///
/// Append-only audit trail of every change to goal definition.
/// Currency is immutable across revisions.
///
/// Row type: [DbGoalRevision].
@DataClassName('DbGoalRevision')
class GoalRevisionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(GoalsTable, #id)();
  TextColumn get householdId => text()();
  TextColumn get name => text()();

  /// Stable non-localized code from [GoalPurpose.code].
  TextColumn get purposeCode => text()();

  /// Target amount in currency minor units.
  IntColumn get targetMinorUnits => integer()();

  /// ISO 4217 currency code. Matches the parent goal currency.
  TextColumn get currencyCode => text()();

  /// UTC ISO 8601 timestamp.
  TextColumn get createdAt => text()();

  /// Human-readable reason for this revision.
  TextColumn get revisionReason => text()();

  /// Optional ISO date (yyyy-MM-dd).
  TextColumn get targetDate => text().nullable()();

  /// Optional household member UUID.
  TextColumn get beneficiaryMemberId => text().nullable()();

  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'goal_revisions';
}

/// Drift table definition for the `goal_movements` table (Phase 5B).
///
/// Links each funding or release ledger transfer to the owning goal.
/// Append-only: no UPDATE or DELETE is ever issued on this table.
///
/// Row type: [DbGoalMovement].
@DataClassName('DbGoalMovement')
class GoalMovementsTable extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(GoalsTable, #id)();
  TextColumn get householdId => text()();

  /// References [operations.id] of the underlying ledger transfer.
  TextColumn get transferOperationId => text()();

  /// 'funding' or 'release'.
  TextColumn get movementType => text()();

  /// UTC ISO 8601 timestamp.
  TextColumn get createdAt => text()();

  /// Required when movementType = 'release'.
  TextColumn get releaseReason => text().nullable()();

  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'goal_movements';
}
