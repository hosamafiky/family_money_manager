import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/tables/households_table.dart';

/// Drift table definition for the `budgets` table (Phase 5A).
///
/// A budget plan defines a spending limit for a given currency, period,
/// and optional filter dimensions (category, scope, spender, beneficiary,
/// payment account).
///
/// MUTABILITY: name, limit_minor_units, filter fields, and is_archived may
/// be updated. Currency code and period type are immutable after creation.
///
/// IDEMPOTENCY: (household_id, idempotency_key) must be unique. A second
/// call with the same key and same payload returns the existing row. A second
/// call with the same key but different payload returns AppDuplicateConflict.
///
/// Row type: [DbBudget].
@DataClassName('DbBudget')
class Budgets extends Table {
  /// Stable client-generated UUID. Primary key.
  TextColumn get id => text()();

  /// FK to households.id.
  TextColumn get householdId => text().references(Households, #id)();

  /// User-visible budget name.
  TextColumn get name => text()();

  /// ISO 4217 currency code. Immutable after creation.
  TextColumn get currencyCode => text()();

  /// Spending limit in currency minor units.
  IntColumn get limitMinorUnits => integer()();

  /// 'monthly' or 'fixed'. Immutable after creation.
  TextColumn get periodType => text()();

  /// ISO date yyyy-MM-dd inclusive start (only for periodType = 'fixed').
  TextColumn get fixedStartDate => text().nullable()();

  /// ISO date yyyy-MM-dd exclusive end (only for periodType = 'fixed').
  TextColumn get fixedEndDate => text().nullable()();

  /// Optional category code filter.
  TextColumn get filterCategoryCode => text().nullable()();

  /// Optional expense scope code filter.
  TextColumn get filterScopeCode => text().nullable()();

  /// Optional spender member UUID filter.
  TextColumn get filterSpenderMemberId => text().nullable()();

  /// Optional beneficiary member UUID filter.
  TextColumn get filterBeneficiaryMemberId => text().nullable()();

  /// Optional payment account ID filter.
  TextColumn get filterPaymentAccountId => text().nullable()();

  /// 0 = active, 1 = archived.
  IntColumn get isArchived => integer().withDefault(const Constant(0))();

  /// Stable fingerprint of creation payload for idempotency conflict detection.
  TextColumn get idempotencyKey => text()();

  /// JSON-like serialized creation payload (for same-key-different-payload check).
  TextColumn get idempotencyPayload => text()();

  /// UTC ISO 8601 creation timestamp.
  TextColumn get createdAt => text()();

  /// UTC ISO 8601 last-updated timestamp.
  TextColumn get updatedAt => text()();

  /// Schema version for this row (always 1 in Phase 5A).
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
