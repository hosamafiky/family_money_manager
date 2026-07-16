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
/// SCHEMA VERSIONS:
///   1 — Phase 2:  Initial schema (5 tables, immutability triggers, indexes)
///   2 — Phase 2A: idempotency_key column; restricted-update trigger on
///                 operations; FK-enforcement trigger on ledger_entries;
///                 CHECK-enforcement triggers for amount_minor_units > 0,
///                 warning_shown = 1, reason non-empty; scoped idempotency index.
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _applyImmutabilityTriggers();
      await _applyAppendOnlyTriggers();
      await _applyCheckEnforcementTriggers();
      await _applyForeignKeyEnforcementTriggers();
      await _applyIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        // v1 → v2: add idempotency_key column and new triggers/indexes.
        await m.addColumn(operations, operations.idempotencyKey);
        await _applyAppendOnlyTriggers();
        await _applyCheckEnforcementTriggers();
        await _applyForeignKeyEnforcementTriggers();
        await _applyScopedIdempotencyIndex();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ── Immutability triggers (INV-002, INV-006) — no update or delete ────────

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

  // ── Restricted-update trigger for operations (Phase 2A) ───────────────────
  //
  // Operations may only have [is_reversed], [reversed_by], and [updated_at]
  // mutated after creation. All other columns are append-only in practice.
  // This trigger enforces that restriction at the database engine level.

  Future<void> _applyAppendOnlyTriggers() async {
    // Only is_reversed, reversed_by, and updated_at may change.
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS restrict_operations_update '
      'BEFORE UPDATE ON operations '
      'WHEN NEW.id != OLD.id OR NEW.household_id != OLD.household_id '
      '  OR NEW.type != OLD.type OR NEW.effective_date != OLD.effective_date '
      '  OR NEW.recorded_at != OLD.recorded_at '
      '  OR NEW.total_amount_minor_units != OLD.total_amount_minor_units '
      '  OR NEW.currency_code != OLD.currency_code '
      '  OR NEW.created_by != OLD.created_by OR NEW.created_at != OLD.created_at '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Operations are append-only: only is_reversed, reversed_by, and updated_at may change'); "
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS no_delete_operations '
      'BEFORE DELETE ON operations '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Operations cannot be deleted; use a reversal operation instead'); "
      'END',
    );
  }

  // ── CHECK-enforcement triggers (Phase 2A) ─────────────────────────────────
  //
  // SQLite CHECK constraints added after table creation are not enforced.
  // These BEFORE INSERT triggers enforce the same rules reliably.

  Future<void> _applyCheckEnforcementTriggers() async {
    // ledger_entries: amount_minor_units > 0
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_ledger_entry_amount
      BEFORE INSERT ON ledger_entries
      WHEN NEW.amount_minor_units <= 0
      BEGIN
        SELECT RAISE(ABORT, 'ledger_entries.amount_minor_units must be > 0');
      END
    ''');

    // child_withdrawal_audits: amount_minor_units > 0
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_audit_amount
      BEFORE INSERT ON child_withdrawal_audits
      WHEN NEW.amount_minor_units <= 0
      BEGIN
        SELECT RAISE(ABORT, 'child_withdrawal_audits.amount_minor_units must be > 0');
      END
    ''');

    // child_withdrawal_audits: warning_shown must be 1 (true)
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_audit_warning_shown
      BEFORE INSERT ON child_withdrawal_audits
      WHEN NEW.warning_shown != 1
      BEGIN
        SELECT RAISE(ABORT, 'child_withdrawal_audits.warning_shown must be true (1)');
      END
    ''');

    // child_withdrawal_audits: reason must be non-empty
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_audit_reason
      BEFORE INSERT ON child_withdrawal_audits
      WHEN length(trim(NEW.reason)) = 0
      BEGIN
        SELECT RAISE(ABORT, 'child_withdrawal_audits.reason must not be empty');
      END
    ''');

    // operations: total_amount_minor_units must be >= 0
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_operation_amount
      BEFORE INSERT ON operations
      WHEN NEW.total_amount_minor_units < 0
      BEGIN
        SELECT RAISE(ABORT, 'operations.total_amount_minor_units must be >= 0');
      END
    ''');
  }

  // ── Foreign-key enforcement triggers (Phase 2A) ───────────────────────────
  //
  // Drift does not add FK from ledger_entries.operation_id → operations.id
  // because the column was defined as a plain TextColumn without .references().
  // A BEFORE INSERT trigger enforces the referential integrity at runtime.
  // (The FK from ledger_entries.account_id → financial_accounts is defined via
  // the Drift table DSL and enforced by PRAGMA foreign_keys = ON.)

  Future<void> _applyForeignKeyEnforcementTriggers() async {
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS fk_ledger_entry_operation_id '
      'BEFORE INSERT ON ledger_entries '
      'WHEN NOT EXISTS ('
      '  SELECT 1 FROM operations '
      '  WHERE id = NEW.operation_id AND household_id = NEW.household_id'
      ') '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'ledger_entries.operation_id must reference an existing operations.id in the same household'); "
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS fk_audit_operation_household '
      'BEFORE INSERT ON child_withdrawal_audits '
      'WHEN NOT EXISTS ('
      '  SELECT 1 FROM operations '
      '  WHERE id = NEW.operation_id AND household_id = NEW.household_id'
      ') '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'child_withdrawal_audits.operation_id must reference an operation in the same household'); "
      'END',
    );
  }

  // ── Indexes ───────────────────────────────────────────────────────────────

  Future<void> _applyIndexes() async {
    // The leg-level unique index prevents duplicate entries per operation leg.
    // It is NOT the primary idempotency mechanism (that is the PK on operations.id
    // and the scoped idempotency_key index below).
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

    await _applyScopedIdempotencyIndex();
  }

  /// Scoped idempotency: (household_id, idempotency_key) must be unique
  /// for all operations that provide an explicit idempotency key.
  /// NULL idempotency_key is excluded from the unique constraint
  /// (partial index using WHERE idempotency_key IS NOT NULL).
  Future<void> _applyScopedIdempotencyIndex() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_operations_idempotency_key
      ON operations(household_id, idempotency_key)
      WHERE idempotency_key IS NOT NULL
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
