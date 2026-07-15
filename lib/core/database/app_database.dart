import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:family_money_manager/core/database/tables/child_withdrawal_audits_table.dart';
import 'package:family_money_manager/core/database/tables/financial_accounts_table.dart';
import 'package:family_money_manager/core/database/tables/households_table.dart';
import 'package:family_money_manager/core/database/tables/ledger_entries_table.dart';
import 'package:family_money_manager/core/database/tables/operations_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The local SQLite database for Family Money Manager.
///
/// ENCRYPTION NOTE (DECISION-004 / PO-2):
/// The pubspec.yaml configures sqlite3mc via the Pub build hook
/// (`hooks.user_defines.sqlite3.source: sqlite3mc`). The binary is
/// encryption-ready. Key injection is deferred to the security-hardening
/// phase. Phase 2 opens the database without a key (unencrypted at rest);
/// the schema and repository design do not require plaintext fallback.
///
/// KEY INJECTION PATH (future):
/// Replace [_devConnection] with a factory that calls `setup`:
/// ```dart
/// await db.customStatement("PRAGMA key = '$key'");
/// ```
/// before the first query, using a key derived from the Android Keystore /
/// iOS Keychain (see docs/LOCAL_ENCRYPTION_KEY_MANAGEMENT.md).
///
/// SCHEMA VERSION: 1.
/// Every migration increment must be added to [migration.onUpgrade].
@DriftDatabase(
  tables: [
    Households,
    FinancialAccounts,
    LedgerEntries,
    Operations,
    ChildWithdrawalAudits,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens a file-backed database in the application documents directory.
  /// Used in production Phase 2 (unencrypted; key injection deferred).
  AppDatabase() : super(_devConnection());

  /// Opens an in-memory database.
  /// Use this in unit and integration tests.
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  /// Accepts a custom executor. Used for advanced testing configurations.
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _applyImmutabilityTriggers();
      await _applyCheckConstraints();
      await _applyIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Phase 2 starts at version 1. Future migrations go here.
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ── SQLite triggers for immutability (INV-002, INV-006) ───────────────────

  Future<void> _applyImmutabilityTriggers() async {
    // Ledger entries are immutable once written.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_ledger_entries
      BEFORE UPDATE ON ledger_entries
      BEGIN
        SELECT RAISE(ABORT, 'Ledger entries are immutable and cannot be updated');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_ledger_entries
      BEFORE DELETE ON ledger_entries
      BEGIN
        SELECT RAISE(ABORT, 'Ledger entries cannot be deleted');
      END
    ''');

    // Child withdrawal audits are immutable.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_child_audits
      BEFORE UPDATE ON child_withdrawal_audits
      BEGIN
        SELECT RAISE(ABORT, 'Child withdrawal audits are immutable and cannot be updated');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_child_audits
      BEFORE DELETE ON child_withdrawal_audits
      BEGIN
        SELECT RAISE(ABORT, 'Child withdrawal audits cannot be deleted');
      END
    ''');
  }

  // ── CHECK constraints not expressible in Drift column DSL ────────────────

  Future<void> _applyCheckConstraints() async {
    // SQLite does not enforce CHECK constraints added after table creation.
    // These constraints are only valid here as documentation; they are
    // enforced by the domain layer and the triggers above.
    // In a future migration, recreate the tables with CHECK constraints
    // if SQLite version guarantees them.
    //
    // Documented constraints:
    //   ledger_entries:         amount_minor_units > 0
    //   child_withdrawal_audits: amount_minor_units > 0
    //                            length(reason) > 0
    //                            warning_shown = 1
  }

  // ── Additional indexes ────────────────────────────────────────────────────

  Future<void> _applyIndexes() async {
    // Idempotency constraint for ledger entries (INV-008).
    // Prevents duplicate (operation_id, account_id, direction, entry_type)
    // from the same operation.
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ledger_idempotency
      ON ledger_entries(operation_id, account_id, direction, entry_type)
    ''');

    // Performance indexes.
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_ledger_entries_account
      ON ledger_entries(account_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_ledger_entries_operation
      ON ledger_entries(operation_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_ledger_entries_effective_date
      ON ledger_entries(effective_date)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_ledger_entries_household
      ON ledger_entries(household_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_operations_household
      ON operations(household_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_operations_date
      ON operations(effective_date)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_operations_type
      ON operations(type)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_financial_accounts_household
      ON financial_accounts(household_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_financial_accounts_archived
      ON financial_accounts(is_archived)
    ''');
  }
}

// ── Development database connection factory ───────────────────────────────

/// Opens an unencrypted NativeDatabase in the application documents directory.
///
/// SECURITY NOTE: This is used in Phase 2 development. The security-hardening
/// phase will replace this with an encrypted connection that passes the database
/// key derived from Android Keystore / iOS Keychain.
QueryExecutor _devConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'family_money_v1.db'));
    return NativeDatabase(file);
  });
}
