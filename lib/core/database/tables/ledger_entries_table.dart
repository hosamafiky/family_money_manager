import 'package:drift/drift.dart';

import 'package:family_money_manager/core/database/tables/financial_accounts_table.dart';
import 'package:family_money_manager/core/database/tables/households_table.dart';

/// Drift table definition for the `ledger_entries` table.
///
/// IMMUTABILITY: No UPDATE or DELETE is ever issued against this table.
/// The repository exposes no update/delete methods.
/// Planned database-level enforcement: SQLite BEFORE UPDATE / BEFORE DELETE
/// triggers (applied in [AppDatabase.onCreate]).
///
/// [amountMinorUnits] has a CHECK(amount_minor_units > 0) to ensure only
/// positive values are stored. The sign of the financial effect is captured
/// by the [direction] column (credit|debit).
///
/// IDEMPOTENCY: The unique index on (operation_id, account_id, direction,
/// entry_type) prevents duplicate entries from the same operation (INV-008).
///
/// Row type: [DbLedgerEntry].
@DataClassName('DbLedgerEntry')
class LedgerEntries extends Table {
  TextColumn get id => text()();

  /// Groups all entries that belong to the same financial operation.
  TextColumn get operationId => text()();

  TextColumn get householdId => text().references(Households, #id)();

  TextColumn get accountId => text().references(FinancialAccounts, #id)();

  /// LedgerDirection: 'credit' or 'debit'.
  TextColumn get direction => text()();

  /// Always positive. CHECK(amount_minor_units > 0) enforced in migration.
  IntColumn get amountMinorUnits => integer()();

  /// ISO 4217 currency code.
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();

  /// LedgerEntryType code.
  TextColumn get entryType => text()();

  /// User-chosen date in "YYYY-MM-DD" format. May be backdated.
  TextColumn get effectiveDate => text()();

  /// System UTC ISO 8601 timestamp.
  TextColumn get recordedAt => text()();

  TextColumn get notes => text().nullable()();
  TextColumn get createdBy => text()();

  BoolColumn get isReversal => boolean().withDefault(const Constant(false))();

  /// When [isReversal] is true, points to the original entry's [id].
  TextColumn get reversalOfEntryId => text().nullable()();

  /// SyncStatus code.
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();

  /// JSON string for operation-specific supplementary data.
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
