import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:family_money_manager/core/database/tables/budgets_table.dart';
import 'package:family_money_manager/core/database/tables/child_withdrawal_audits_table.dart';
import 'package:family_money_manager/core/database/tables/financial_accounts_table.dart';
import 'package:family_money_manager/core/database/tables/goals_table.dart';
import 'package:family_money_manager/core/database/tables/household_members_table.dart';
import 'package:family_money_manager/core/database/tables/households_table.dart';
import 'package:family_money_manager/core/database/tables/ledger_entries_table.dart';
import 'package:family_money_manager/core/database/tables/operation_contexts_table.dart';
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
///   3 — Phase 3A: household_members table for named household members.
///   4 — Phase 3A.1: financial_accounts idempotency_key + idempotency_payload;
///                   household cardinality triggers (one primary_user, one spouse);
///                   immutable account type/currency trigger;
///                   scoped account idempotency index.
///   5 — Phase 3B: operation_contexts table (append-only rich metadata);
///                 FK + immutability triggers for operation_contexts.
///   6 — Phase 3B.1: stronger account-classification immutability;
///                   restrict_account_classification_update trigger (post-history
///                   lock for owner_type, fund_purpose, is_protected, is_spendable,
///                   include_in_net_worth, include_in_zakat, type, currency_code);
///                   restrict_child_fund_unprotect trigger (always).
///   7 — Phase 5A: budgets table for budget plans; idempotency index on budgets.
///   8 — Phase 5B: goals, goal_revisions, goal_movements tables for savings
///                 goals backed by dedicated goalReserve ledger accounts.
@DriftDatabase(
  tables: [
    Households,
    HouseholdMembers,
    FinancialAccounts,
    LedgerEntries,
    Operations,
    ChildWithdrawalAudits,
    OperationContexts,
    Budgets,
    GoalsTable,
    GoalRevisionsTable,
    GoalMovementsTable,
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
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _applyImmutabilityTriggers();
      await _applyAppendOnlyTriggers();
      await _applyCheckEnforcementTriggers();
      await _applyForeignKeyEnforcementTriggers();
      await _applyHouseholdConstraintTriggers();
      await _applyAccountMetadataImmutabilityTrigger();
      await _applyAccountClassificationImmutabilityTrigger();
      await _applyChildFundProtectionTrigger();
      await _applyOperationContextTriggers();
      await _applyIndexes();
      await _applyBudgetIdempotencyIndex();
      await _applyGoalIndexes();
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
      if (from <= 2) {
        // v2 → v3: create household_members table.
        await m.createTable(householdMembers);
      }
      if (from <= 3) {
        // v3 → v4: account idempotency columns, household cardinality triggers,
        // immutable type/currency trigger, scoped account idempotency index.
        await m.addColumn(financialAccounts, financialAccounts.idempotencyKey);
        await m.addColumn(financialAccounts, financialAccounts.idempotencyPayload);
        await _applyHouseholdConstraintTriggers();
        await _applyAccountMetadataImmutabilityTrigger();
        await _applyAccountIdempotencyIndex();
      }
      if (from <= 4) {
        // v4 → v5: operation_contexts table for rich transaction metadata.
        await m.createTable(operationContexts);
        await _applyOperationContextTriggers();
      }
      if (from <= 5) {
        // v5 → v6: stronger account-classification immutability triggers.
        await _applyAccountClassificationImmutabilityTrigger();
        await _applyChildFundProtectionTrigger();
      }
      if (from <= 6) {
        // v6 → v7: budgets table for Phase 5A budget planning.
        await m.createTable(budgets);
        await _applyBudgetIdempotencyIndex();
      }
      if (from <= 7) {
        // v7 → v8: goals, goal_revisions, goal_movements tables for Phase 5B.
        await m.createTable(goalsTable);
        await m.createTable(goalRevisionsTable);
        await m.createTable(goalMovementsTable);
        await _applyGoalIndexes();
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
    await _applyAccountIdempotencyIndex();
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

  // ── Household cardinality triggers (Phase 3A.1) ───────────────────────────
  //
  // Enforces V1 business rules at the database level:
  // - At most one active primary_user per household.
  // - At most one active spouse per household.
  // - Every household_members row must reference an existing household.

  Future<void> _applyHouseholdConstraintTriggers() async {
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS one_primary_user_per_household '
      'BEFORE INSERT ON household_members '
      "WHEN NEW.role = 'primary_user' AND NEW.is_archived = 0 "
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Only one active primary_user per household') "
      '  WHERE EXISTS ( '
      '    SELECT 1 FROM household_members '
      '    WHERE household_id = NEW.household_id '
      "      AND role = 'primary_user' "
      '      AND is_archived = 0 '
      '  ); '
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS one_spouse_per_household '
      'BEFORE INSERT ON household_members '
      "WHEN NEW.role = 'spouse' AND NEW.is_archived = 0 "
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Only one active spouse per household in V1') "
      '  WHERE EXISTS ( '
      '    SELECT 1 FROM household_members '
      '    WHERE household_id = NEW.household_id '
      "      AND role = 'spouse' "
      '      AND is_archived = 0 '
      '  ); '
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS no_cross_household_member '
      'BEFORE INSERT ON household_members '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'household_members.household_id must match household.id') "
      '  WHERE NOT EXISTS ( '
      '    SELECT 1 FROM households WHERE id = NEW.household_id '
      '  ); '
      'END',
    );
  }

  // ── Immutable account type and currency trigger (Phase 3A.1) ─────────────
  //
  // [type] and [currency_code] must never change after insertion.
  // This enforces the structural immutability rule at the DB engine level.

  Future<void> _applyAccountMetadataImmutabilityTrigger() async {
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS immutable_account_type_currency '
      'BEFORE UPDATE ON financial_accounts '
      'WHEN OLD.type != NEW.type OR OLD.currency_code != NEW.currency_code '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Account type and currency are immutable after creation'); "
      'END',
    );
  }

  // ── Post-history classification immutability trigger (Phase 3B.1) ────────
  //
  // Once an account has any ledger entries, the following classification fields
  // become immutable: type, currency_code, owner_type, fund_purpose,
  // is_protected, is_spendable, include_in_net_worth, include_in_zakat.
  //
  // Defense-in-depth: type and currency_code are ALSO blocked by the always-on
  // [_applyAccountMetadataImmutabilityTrigger]. This trigger adds the
  // post-history lock for the remaining fields as a DB-engine guarantee.

  Future<void> _applyAccountClassificationImmutabilityTrigger() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS restrict_account_classification_update
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN (
        (SELECT COUNT(*) FROM ledger_entries WHERE account_id = OLD.id) > 0
      )
      BEGIN
        SELECT CASE
          WHEN NEW.type != OLD.type THEN
            RAISE(ABORT, 'Account type is immutable once financial history exists')
          WHEN NEW.currency_code != OLD.currency_code THEN
            RAISE(ABORT, 'Account currency is immutable once financial history exists')
          WHEN NEW.owner_type != OLD.owner_type THEN
            RAISE(ABORT, 'Account owner_type is immutable once financial history exists')
          WHEN NEW.fund_purpose != OLD.fund_purpose THEN
            RAISE(ABORT, 'Account fund_purpose is immutable once financial history exists')
          WHEN NEW.is_protected != OLD.is_protected THEN
            RAISE(ABORT, 'Account is_protected is immutable once financial history exists')
          WHEN NEW.is_spendable != OLD.is_spendable THEN
            RAISE(ABORT, 'Account is_spendable is immutable once financial history exists')
          WHEN NEW.include_in_net_worth != OLD.include_in_net_worth THEN
            RAISE(ABORT, 'Account include_in_net_worth is immutable once financial history exists')
          WHEN NEW.include_in_zakat != OLD.include_in_zakat THEN
            RAISE(ABORT, 'Account include_in_zakat is immutable once financial history exists')
        END;
      END
    ''');
  }

  // ── Child-protected-fund protection trigger (Phase 3B.1) ─────────────────
  //
  // A childProtectedFund account must ALWAYS have is_protected = true.
  // This rule applies even BEFORE any financial history exists.
  // Attempting to clear the flag raises an abort regardless of history.

  Future<void> _applyChildFundProtectionTrigger() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS restrict_child_fund_unprotect
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN NEW.type = 'childProtectedFund' AND NEW.is_protected = 0
      BEGIN
        SELECT RAISE(ABORT, 'Child protected fund cannot have is_protected disabled');
      END
    ''');
  }

  // ── Operation-context triggers (Phase 3B) ─────────────────────────────────
  //
  // 1. FK enforcement: operation_id must reference an existing operations row.
  // 2. Append-only: no update or delete permitted once written.

  Future<void> _applyOperationContextTriggers() async {
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS fk_operation_context_operation_id '
      'BEFORE INSERT ON operation_contexts '
      'WHEN NOT EXISTS ( '
      '  SELECT 1 FROM operations WHERE id = NEW.operation_id '
      ') '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'operation_contexts.operation_id must reference an existing operations.id'); "
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS no_update_operation_contexts '
      'BEFORE UPDATE ON operation_contexts '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Operation contexts are immutable and cannot be updated'); "
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS no_delete_operation_contexts '
      'BEFORE DELETE ON operation_contexts '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Operation contexts cannot be deleted'); "
      'END',
    );
  }

  // ── Account idempotency index (Phase 3A.1) ────────────────────────────────

  Future<void> _applyAccountIdempotencyIndex() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_accounts_idempotency
      ON financial_accounts(household_id, idempotency_key)
      WHERE idempotency_key IS NOT NULL
    ''');
  }

  // ── Budget idempotency index (Phase 5A) ───────────────────────────────────

  Future<void> _applyBudgetIdempotencyIndex() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_idempotency
      ON budgets(household_id, idempotency_key)
    ''');
  }

  // ── Goal indexes (Phase 5B) ────────────────────────────────────────────────

  Future<void> _applyGoalIndexes() async {
    // One reserve account per goal, and each reserve account belongs to at
    // most one goal.
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goals_reserve_account
      ON goals(reserve_account_id)
    ''');
    // Scoped idempotency for goals.
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goals_idempotency
      ON goals(household_id, idempotency_key)
    ''');
    // Performance index for revision queries.
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_goal_revisions_goal
      ON goal_revisions(goal_id)
    ''');
    // Performance index for movement queries.
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_goal_movements_goal
      ON goal_movements(goal_id)
    ''');
    // Enables fast lookup of all movements for a given transfer operation.
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_goal_movements_operation
      ON goal_movements(transfer_operation_id)
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
