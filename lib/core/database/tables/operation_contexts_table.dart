import 'package:drift/drift.dart';

/// Drift table definition for the `operation_contexts` table.
///
/// Stores rich, stable metadata about an operation that does not fit in the
/// `operations` table:
/// - Stable member UUIDs for spender and beneficiary (as opposed to role codes
///   stored in the `operations` table, which are de-normalised snapshots).
/// - Per-operation recurring marker.
/// - Free-form note text.
///
/// APPEND-ONLY: This table is immutable after insertion. A `BEFORE UPDATE`
/// trigger (applied in [AppDatabase]) prevents any mutation.
///
/// FOREIGN KEY: [operationId] must reference an existing `operations.id`.
/// A `BEFORE INSERT` trigger enforces this constraint because Drift does not
/// generate FK DDL for plain [TextColumn] references in all configurations.
///
/// Row type: [DbOperationContext].
@DataClassName('DbOperationContext')
class OperationContexts extends Table {
  /// The parent operation's ID. Primary key.
  TextColumn get operationId => text()();

  /// The household this operation belongs to.
  TextColumn get householdId => text()();

  /// Stable member UUID for the person who spent / initiated the transaction.
  /// Not a role code — this never changes when members are renamed.
  TextColumn get spenderMemberId => text().nullable()();

  /// Stable member UUID for the person who benefits from the transaction.
  TextColumn get beneficiaryMemberId => text().nullable()();

  /// [ExpenseScope] code for expense and child-fund operations.
  TextColumn get expenseScope => text().nullable()();

  /// True when the user flagged this as a recurring transaction.
  /// Automatic scheduling is deferred to a future phase.
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  /// Human-readable note about recurring intent, e.g. 'recurring_marker_not_scheduled'.
  TextColumn get recurringNote => text().nullable()();

  /// Stable category code, mirrors [operations.category_code] for query
  /// convenience without a JOIN.
  TextColumn get categoryCode => text().nullable()();

  /// Optional free-text note from the user. Mirrors the [operations.description]
  /// field for structured-query access.
  TextColumn get note => text().nullable()();

  /// UTC ISO 8601 creation timestamp.
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {operationId};
}
