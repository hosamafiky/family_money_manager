import 'package:drift/drift.dart';

import 'package:family_money_manager/core/database/tables/households_table.dart';

/// Drift table definition for the `financial_accounts` table.
///
/// IMMUTABILITY RULE: The [type] column must NEVER be updated after a row is
/// inserted. This is enforced by the repository layer (no update-type method
/// is exposed). The database does not have a trigger for this in V1, but the
/// repository API makes it structurally impossible.
///
/// Row type: [DbFinancialAccount].
@DataClassName('DbFinancialAccount')
class FinancialAccounts extends Table {
  TextColumn get id => text()();

  TextColumn get householdId => text().references(Households, #id)();

  TextColumn get name => text()();

  /// FinancialAccountType code (immutable after creation).
  TextColumn get type => text()();

  /// AccountOwnerType code.
  TextColumn get ownerType => text()();

  /// FundPurpose code.
  TextColumn get fundPurpose =>
      text().withDefault(const Constant('available'))();

  /// ISO 4217 currency code.
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();

  BoolColumn get isSpendable => boolean().withDefault(const Constant(true))();
  BoolColumn get isProtected => boolean().withDefault(const Constant(false))();
  BoolColumn get includeInNetWorth =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get includeInZakat =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get archivedAt => text().nullable()();

  TextColumn get notes => text().nullable()();

  IntColumn get displayOrder => integer().withDefault(const Constant(0))();

  /// JSON string with type-specific extra fields (bank name, certificate data, gold weight, etc.).
  TextColumn get metadata => text().nullable()();

  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get createdBy => text()();

  /// SyncStatus code.
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();

  /// Caller-supplied idempotency key scoped to (household_id, idempotency_key).
  /// Nullable: accounts created without a key have no idempotency protection.
  TextColumn get idempotencyKey => text().nullable()();

  /// Stable serialised fingerprint of the creation payload.
  /// Stored alongside [idempotencyKey] so that same-key-different-payload
  /// conflicts can be detected without re-hashing on every lookup.
  TextColumn get idempotencyPayload => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
