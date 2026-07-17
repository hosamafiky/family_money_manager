import 'package:drift/drift.dart';

import 'package:family_money_manager/core/database/tables/financial_accounts_table.dart';
import 'package:family_money_manager/core/database/tables/households_table.dart';

// ignore: unused_import — used by @ReferenceName annotation
// Drift manager name-clash fix: two FK columns pointing to the same table.
// See https://drift.simonbinder.eu/docs/manager/#name-clashes

/// Drift table definition for the `operations` table.
///
/// An operation groups one or more ledger entries into a single financial event.
/// It serves as the unit of idempotency (primary key is the client-generated
/// operationId).
///
/// MUTABILITY: Only [isReversed] and [reversedBy] may ever be updated after
/// initial creation. All other fields are effectively immutable. The repository
/// enforces this by exposing only a targeted `markAsReversed` update method.
///
/// Row type: [DbOperation].
@DataClassName('DbOperation')
class Operations extends Table {
  /// Stable client-generated UUID. Primary key.
  TextColumn get id => text()();

  /// Explicit idempotency key scoped by [householdId].
  ///
  /// Defaults to [id] at the application layer when not supplied by the caller.
  /// A UNIQUE(household_id, idempotency_key) constraint is enforced via a
  /// custom index in [AppDatabase.onCreate] / schema-v2 migration.
  ///
  /// Distinguishes:
  /// - Same key + same operation_id → alreadyExists (safe retry)
  /// - Same key + different operation_id → conflict (caller error)
  TextColumn get idempotencyKey => text().nullable()();

  TextColumn get householdId => text().references(Households, #id)();

  /// OperationType code.
  TextColumn get type => text()();

  /// User-chosen effective date "YYYY-MM-DD".
  TextColumn get effectiveDate => text()();

  /// System UTC ISO 8601 timestamp.
  TextColumn get recordedAt => text()();

  TextColumn get description => text().nullable()();

  /// Income/expense category code.
  TextColumn get categoryCode => text().nullable()();

  /// ExpenseScope code.
  TextColumn get scope => text().nullable()();

  /// HouseholdMemberRole code.
  TextColumn get spenderRole => text().nullable()();

  /// HouseholdMemberRole code.
  TextColumn get beneficiaryRole => text().nullable()();

  @ReferenceName('sourceOperations')
  TextColumn get sourceAccountId =>
      text().nullable().references(FinancialAccounts, #id)();

  @ReferenceName('destinationOperations')
  TextColumn get destinationAccountId =>
      text().nullable().references(FinancialAccounts, #id)();

  /// Face amount in minor units (always positive).
  IntColumn get totalAmountMinorUnits => integer()();

  /// ISO 4217 currency code.
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();

  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurringRuleId => text().nullable()();

  /// JSON array of tag strings.
  TextColumn get tags => text().nullable()();

  /// Local path to an encrypted receipt image (display-layer only).
  TextColumn get receiptPath => text().nullable()();

  /// Set to true when a reversal operation has been applied (INV-002).
  /// This is the ONLY field that may be updated after creation.
  BoolColumn get isReversed => boolean().withDefault(const Constant(false))();

  /// The [id] of the reversal operation that cancelled this one.
  TextColumn get reversedBy => text().nullable()();

  TextColumn get createdBy => text()();
  TextColumn get createdAt => text()();

  /// Updated only when [isReversed] is set.
  TextColumn get updatedAt => text()();

  /// SyncStatus code.
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();

  @override
  Set<Column> get primaryKey => {id};
}
