import 'package:drift/drift.dart';

import 'package:family_money_manager/core/database/tables/financial_accounts_table.dart';
import 'package:family_money_manager/core/database/tables/households_table.dart';
import 'package:family_money_manager/core/database/tables/operations_table.dart';

/// Drift table definition for the `child_withdrawal_audits` table.
///
/// IMMUTABILITY: No UPDATE or DELETE is ever issued against this table.
/// A planned BEFORE UPDATE / BEFORE DELETE trigger enforces this at the
/// database engine level (applied in [AppDatabase.onCreate]).
///
/// ATOMIC WRITE: Every row is written in the same SQLite transaction as the
/// corresponding [childFundWithdrawal] ledger entry (INV-006, INV-007).
///
/// UNIQUE CONSTRAINT: One audit record per operation (the unique index on
/// [operationId] is declared here so Drift generates it).
///
/// Row type: [DbChildWithdrawalAudit].
@DataClassName('DbChildWithdrawalAudit')
class ChildWithdrawalAudits extends Table {
  TextColumn get id => text()();

  TextColumn get operationId => text().references(Operations, #id)();

  TextColumn get householdId => text().references(Households, #id)();

  TextColumn get accountId => text().references(FinancialAccounts, #id)();

  /// Always positive; CHECK enforced in migration SQL.
  IntColumn get amountMinorUnits => integer()();

  /// Mandatory non-empty reason. CHECK(length(reason) > 0) enforced in migration.
  TextColumn get reason => text()();

  /// HouseholdMemberRole code.
  TextColumn get beneficiary => text()();

  /// UTC ISO 8601 timestamp of user confirmation.
  TextColumn get confirmedAt => text()();
  TextColumn get confirmedBy => text()();

  /// Must always be true. CHECK(warning_shown = 1) enforced in migration.
  BoolColumn get warningShown => boolean().withDefault(const Constant(true))();

  BoolColumn get biometricConfirmed => boolean().withDefault(const Constant(false))();

  TextColumn get createdAt => text()();

  /// SyncStatus code.
  TextColumn get syncStatus => text().withDefault(const Constant('local'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (operation_id)'];
}
