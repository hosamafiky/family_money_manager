import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:family_money_manager/core/database/tables/budgets_table.dart';
import 'package:family_money_manager/core/database/tables/certificates_table.dart'
    show
        CertificateEventsTable,
        CertificateRevisionsTable,
        SavingsCertificatesTable;
import 'package:family_money_manager/core/database/tables/child_withdrawal_audits_table.dart';
import 'package:family_money_manager/core/database/tables/financial_accounts_table.dart';
import 'package:family_money_manager/core/database/tables/goals_table.dart'
    show
        GoalLifecycleEventsTable,
        GoalMovementsTable,
        GoalRevisionsTable,
        GoalsTable;
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
///                 goals backed by dedicated goalReserve ledger accounts;
///                 immutability triggers for goal_revisions and goal_movements.
///   9 — Phase 5B.1: goal-table field immutability trigger; delete-with-history
///                 guard; status-transition enforcement; reserve-account
///                 reclassification and archive-while-active guards; movements
///                 uniqueness + release-reason + operation-type triggers;
///                 beneficiary same-household trigger;
///                 UNIQUE INDEX on goal_movements.transfer_operation_id.
///  10 — Phase 5B.2: reserve is_spendable/is_protected immutability triggers;
///                 funding/release movement direction-validation triggers.
///  11 — Phase 5B.3: early_completion_reason column; goal-reserve INSERT
///                 validator; extended movement household triggers.
///  12 — Phase 5B.4: goal_lifecycle_events table (immutable event log);
///                 reversal_of_movement_id column on goal_movements;
///                 reserve owner_type = 'household' enforcement trigger;
///                 no_modify_reserve_owner_type trigger;
///                 goal_movement_transfer_type updated to allow 'reversal' ops.
///  13 — Phase 5B.5: validate_reversal_movement_link trigger;
///                 unique index one-reversal-per-original;
///                 lifecycle household-matches-goal trigger;
///                 household-scoped lifecycle idempotency index.
///  14 — Phase 5B.6: validate_goal_transfer_balanced_legs trigger —
///                 funding/release movements require exactly two balanced
///                 ledger legs matching operation source/destination.
///  15 — Phase 5B.7: validate_goal_reversal_balanced_legs trigger —
///                 reversal movements require balanced mirror legs, inverse
///                 accounts vs original, operation type reversal, and unique
///                 linkage; reject_unsupported_goal_status_transition alias.
///  16 — Phase 5B.8: migrate persisted targetReached → active; lifecycle
///                 status CHECK triggers (active/completed/archived only);
///                 status-transition triggers without targetReached.
///  17 — Phase 6A: savings_certificates, certificate_revisions,
///                 certificate_events; certificate account linkage &
///                 immutability triggers; event/revision append-only;
///                 purchase/profit/redemption financial validators.
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
    GoalLifecycleEventsTable,
    SavingsCertificatesTable,
    CertificateRevisionsTable,
    CertificateEventsTable,
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

  /// Opens a file-backed database at [path]. Used for multi-connection tests.
  AppDatabase.forFile(String path) : super(NativeDatabase(File(path)));

  @override
  int get schemaVersion => 17;

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
      await _applyGoalImmutabilityTriggers();
      await _applyGoalIndexes();
      await _applyGoalTableHardeningTriggers();
      await _applyReserveAccountHardeningTriggers();
      await _applyGoalMovementsHardeningTriggersV12();
      await _applyGoalRevisionBeneficiaryTrigger();
      await _applyGoalMovementsUniqueIndex();
      await _applyReserveSpendableProtectedTriggers();
      await _applyGoalMovementsDirectionTriggers();
      await _applyGoalReserveInsertValidatorV12();
      await _applyGoalMovementsHouseholdTriggers();
      await _applyReserveOwnerTypeTrigger();
      await _applyGoalLifecycleEventsTriggers();
      await _applyGoalLifecycleEventsIndex();
      await _applyPhase5B5ReversalAndLifecycleHardening();
      await _applyPhase5B6BalancedMovementTrigger();
      await _applyPhase5B7ReversalBalancedAndStatusTriggers();
      await _applyPhase5B8LifecycleProgressSeparation();
      await _applyPhase6ACertificateSchema();
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
        await m.addColumn(
          financialAccounts,
          financialAccounts.idempotencyPayload,
        );
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
        await _applyGoalImmutabilityTriggers();
        await _applyGoalIndexes();
      }
      if (from <= 8) {
        // v8 → v9: Phase 5B.1 hardening triggers and unique movement index.
        await _applyGoalTableHardeningTriggers();
        await _applyReserveAccountHardeningTriggers();
        await _applyGoalMovementsHardeningTriggers();
        await _applyGoalRevisionBeneficiaryTrigger();
        await _applyGoalMovementsUniqueIndex();
      }
      if (from <= 9) {
        // v9 → v10: Phase 5B.2 — movement validation triggers, reserve
        // spendable/protected locks.
        await _applyReserveSpendableProtectedTriggers();
        await _applyGoalMovementsDirectionTriggers();
      }
      if (from <= 10) {
        // v10 → v11: Phase 5B.3 — early_completion_reason column, goal-reserve
        // INSERT validator trigger, extended movement household triggers.
        await m.addColumn(goalsTable, goalsTable.earlyCompletionReason);
        await _applyGoalReserveInsertValidator();
        await _applyGoalMovementsHouseholdTriggers();
      }
      if (from <= 11) {
        // v11 → v12: Phase 5B.4 — goal_lifecycle_events table;
        // reversal_of_movement_id column; owner_type enforcement;
        // no_modify_reserve_owner_type trigger; lifecycle event triggers;
        // updated goal_movement_transfer_type (allows 'reversal' ops).
        await m.createTable(goalLifecycleEventsTable);
        await m.addColumn(
          goalMovementsTable,
          goalMovementsTable.reversalOfMovementId,
        );
        // Replace v11 trigger with v12 version that includes owner_type check.
        await customStatement(
          'DROP TRIGGER IF EXISTS validate_goal_reserve_on_insert',
        );
        await _applyGoalReserveInsertValidatorV12();
        // Replace v8/v9 trigger with v12 version that allows 'reversal' ops.
        await customStatement(
          'DROP TRIGGER IF EXISTS goal_movement_transfer_type',
        );
        await _applyGoalMovementsHardeningTriggersV12();
        await _applyReserveOwnerTypeTrigger();
        await customStatement(
          'DROP TRIGGER IF EXISTS fk_goal_lifecycle_event_household_id',
        );
        await _applyGoalLifecycleEventsTriggers();
        await _applyGoalLifecycleEventsIndex();
      }
      if (from <= 12) {
        // v12 → v13: Phase 5B.5 — reversal linkage triggers/index;
        // lifecycle household-match trigger; household-scoped idempotency.
        await _applyPhase5B5ReversalAndLifecycleHardening();
      }
      if (from <= 13) {
        // v13 → v14: Phase 5B.6 — balanced ledger legs for goal movements.
        await _applyPhase5B6BalancedMovementTrigger();
      }
      if (from <= 14) {
        // v14 → v15: Phase 5B.7 — reversal balanced legs + status alias.
        await _applyPhase5B7ReversalBalancedAndStatusTriggers();
      }
      if (from <= 15) {
        // v15 → v16: Phase 5B.8 — lifecycle/progress separation.
        await _applyPhase5B8LifecycleProgressSeparation();
      }
      if (from <= 16) {
        // v16 → v17: Phase 6A — savings certificates.
        await m.createTable(savingsCertificatesTable);
        await m.createTable(certificateRevisionsTable);
        await m.createTable(certificateEventsTable);
        await _applyPhase6ACertificateSchema();
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

  // ── Goal immutability triggers (Phase 5B) ─────────────────────────────────
  //
  // goal_revisions and goal_movements are append-only records. No application
  // code ever issues UPDATE or DELETE on these tables, but these triggers
  // enforce the constraint at the database engine level as a safety net.

  Future<void> _applyGoalImmutabilityTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_goal_revisions
      BEFORE UPDATE ON goal_revisions
      BEGIN
        SELECT RAISE(ABORT, 'goal_revisions are immutable and cannot be updated');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_goal_revisions
      BEFORE DELETE ON goal_revisions
      BEGIN
        SELECT RAISE(ABORT, 'goal_revisions cannot be deleted');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_goal_movements
      BEFORE UPDATE ON goal_movements
      BEGIN
        SELECT RAISE(ABORT, 'goal_movements are immutable and cannot be updated');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_goal_movements
      BEFORE DELETE ON goal_movements
      BEGIN
        SELECT RAISE(ABORT, 'goal_movements cannot be deleted');
      END
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

  // ── Goal table hardening triggers (Phase 5B.1) ────────────────────────────
  //
  // 1. Prevents updating immutable goal fields after creation.
  // 2. Prevents deleting a goal that has any linked revisions or movements.
  // 3. Enforces valid status transitions.

  Future<void> _applyGoalTableHardeningTriggers() async {
    // Block mutation of structural/identity fields.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_goal_immutable
      BEFORE UPDATE ON goals
      FOR EACH ROW
      WHEN NEW.household_id     != OLD.household_id
        OR NEW.reserve_account_id != OLD.reserve_account_id
        OR NEW.currency_code    != OLD.currency_code
        OR NEW.idempotency_key  != OLD.idempotency_key
        OR NEW.created_at       != OLD.created_at
      BEGIN
        SELECT RAISE(ABORT, 'goal immutable fields cannot be changed');
      END
    ''');

    // Prevent deleting a goal that has audit history.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_goal_with_history
      BEFORE DELETE ON goals
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'cannot delete goal with revisions or movements')
        WHERE EXISTS (SELECT 1 FROM goal_revisions WHERE goal_id = OLD.id)
           OR EXISTS (SELECT 1 FROM goal_movements WHERE goal_id = OLD.id);
      END
    ''');

    // Enforce recognised lifecycle status transitions (Phase 5B.8).
    // Valid: active→completed, active→archived,
    //        completed→archived, archived→active (restore).
    // Progress is never persisted — no targetReached transitions.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_status_valid_transition
      BEFORE UPDATE ON goals
      FOR EACH ROW
      WHEN NEW.status != OLD.status
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal status transition')
        WHERE NOT (
          (OLD.status = 'active'    AND NEW.status IN ('completed','archived'))
          OR (OLD.status = 'completed' AND NEW.status = 'archived')
          OR (OLD.status = 'archived'  AND NEW.status = 'active')
        );
      END
    ''');
  }

  // ── Reserve-account classification hardening (Phase 5B.1) ─────────────────
  //
  // 1. Prevents reclassifying a goalReserve account to any other type.
  //    (Defense-in-depth: immutable_account_type_currency already blocks all
  //    type changes; this trigger adds a clear semantic error message.)
  // 2. Prevents archiving a reserve account while its goal is still active.

  Future<void> _applyReserveAccountHardeningTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_retype_reserve_account
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.type != 'goalReserve'
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve account type cannot be changed');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_archive_active_reserve
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve'
        AND NEW.is_archived = 1
        AND OLD.is_archived = 0
      BEGIN
        SELECT RAISE(ABORT, 'cannot archive reserve account of an active goal')
        WHERE EXISTS (
          SELECT 1 FROM goals
          WHERE reserve_account_id = OLD.id
            AND status != 'archived'
        );
      END
    ''');
  }

  // ── Goal movements hardening (Phase 5B.1 / 5B.4) ─────────────────────────
  //
  // 1. Release movements must have a non-empty release_reason.
  // 2. The linked operation must exist and be of type 'transfer' (v11) or
  //    'reversal' (v12+, for reversal goal movements).
  //
  // Use [_applyGoalMovementsHardeningTriggersV12] for all fresh installs.
  // The legacy [_applyGoalMovementsHardeningTriggers] kept for reference;
  // call only during historical migration paths that don't reach v12 yet.

  Future<void> _applyGoalMovementsHardeningTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_movement_release_reason
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'release'
        AND (NEW.release_reason IS NULL OR length(trim(NEW.release_reason)) = 0)
      BEGIN
        SELECT RAISE(ABORT, 'release movement must have a non-empty release_reason');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_movement_transfer_type
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'goal movement must reference a transfer operation')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations
          WHERE id = NEW.transfer_operation_id
            AND type = 'transfer'
        );
      END
    ''');
  }

  Future<void> _applyGoalMovementsHardeningTriggersV12() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_movement_release_reason
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'release'
        AND (NEW.release_reason IS NULL OR length(trim(NEW.release_reason)) = 0)
      BEGIN
        SELECT RAISE(ABORT, 'release movement must have a non-empty release_reason');
      END
    ''');

    // In v12+, reversal goal movements reference a 'reversal' operation;
    // allow both 'transfer' and 'reversal' operation types.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_movement_transfer_type
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'goal movement must reference a transfer or reversal operation')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations
          WHERE id = NEW.transfer_operation_id
            AND type IN ('transfer', 'reversal')
        );
      END
    ''');
  }

  // ── Beneficiary household integrity (Phase 5B.1) ──────────────────────────
  //
  // Ensures that when a beneficiary_member_id is set on a goal revision,
  // that member belongs to the same household as the goal.

  Future<void> _applyGoalRevisionBeneficiaryTrigger() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_revision_beneficiary_same_household
      BEFORE INSERT ON goal_revisions
      FOR EACH ROW
      WHEN NEW.beneficiary_member_id IS NOT NULL
      BEGIN
        SELECT RAISE(ABORT, 'beneficiary must belong to same household as goal')
        WHERE NOT EXISTS (
          SELECT 1 FROM household_members hm
          JOIN goals g ON g.household_id = hm.household_id
          WHERE hm.id = NEW.beneficiary_member_id
            AND g.id  = NEW.goal_id
        );
      END
    ''');
  }

  // ── Goal movements unique-operation index (Phase 5B.1) ────────────────────
  //
  // Each transfer operation can link to at most one goal movement,
  // preventing duplicate movements for the same underlying transfer.

  Future<void> _applyGoalMovementsUniqueIndex() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_movements_unique_operation
      ON goal_movements(transfer_operation_id)
    ''');
  }

  // ── Reserve is_spendable / is_protected immutability (Phase 5B.2) ─────────
  //
  // A goalReserve account's is_spendable and is_protected columns must never
  // change after creation, regardless of whether financial history exists.
  // This is defence-in-depth on top of the post-history classification lock.

  Future<void> _applyReserveSpendableProtectedTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_reserve_spendable
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.is_spendable != OLD.is_spendable
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve is_spendable cannot be changed');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_reserve_protected
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.is_protected != OLD.is_protected
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve is_protected cannot be changed');
      END
    ''');
  }

  // ── Goal movement direction-validation triggers (Phase 5B.2) ─────────────
  //
  // Funding movements: the linked transfer operation must have the goal's
  // reserve account as destination.
  //
  // Release movements: the linked transfer operation must have the goal's
  // reserve account as source, AND the release_reason must be non-empty.

  Future<void> _applyGoalMovementsDirectionTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_funding_movement
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'funding'
      BEGIN
        SELECT RAISE(ABORT, 'funding movement: operation must be a transfer to the reserve')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations o
          JOIN goals g ON g.id = NEW.goal_id
          WHERE o.id = NEW.transfer_operation_id
            AND o.type = 'transfer'
            AND o.destination_account_id = g.reserve_account_id
            AND o.household_id = NEW.household_id
        );
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_release_movement
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'release'
      BEGIN
        SELECT RAISE(ABORT, 'release movement: operation must be a transfer from the reserve, reason required')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations o
          JOIN goals g ON g.id = NEW.goal_id
          WHERE o.id = NEW.transfer_operation_id
            AND o.type = 'transfer'
            AND o.source_account_id = g.reserve_account_id
            AND o.household_id = NEW.household_id
        )
        OR (NEW.release_reason IS NULL OR length(trim(NEW.release_reason)) = 0);
      END
    ''');
  }

  // ── Phase 5B.3: Goal-reserve INSERT validator (legacy, v11 only) ──────────
  //
  // Ensures every new goal row references an account that is a goalReserve
  // type in the same household with the same currency, is not spendable,
  // and is not protected.
  //
  // Use [_applyGoalReserveInsertValidatorV12] for all fresh installs and v12+
  // migrations — it additionally enforces owner_type = 'household'.

  Future<void> _applyGoalReserveInsertValidator() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_goal_reserve_on_insert
      BEFORE INSERT ON goals
      BEGIN
        SELECT RAISE(ABORT, 'goal reserve must be a goalReserve account in the same household with same currency')
        WHERE NOT EXISTS (
          SELECT 1 FROM financial_accounts fa
          WHERE fa.id = NEW.reserve_account_id
            AND fa.type = 'goalReserve'
            AND fa.household_id = NEW.household_id
            AND fa.currency_code = NEW.currency_code
            AND fa.is_spendable = 0
            AND fa.is_protected = 0
        );
      END
    ''');
  }

  // ── Phase 5B.4: Goal-reserve INSERT validator (v12) ───────────────────────
  //
  // Extended to also require owner_type = 'household', rejecting child,
  // spouse, and personal-owner reserves.

  Future<void> _applyGoalReserveInsertValidatorV12() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_goal_reserve_on_insert
      BEFORE INSERT ON goals
      BEGIN
        SELECT RAISE(ABORT, 'goal reserve must be a goalReserve account: correct type, household, currency, owner')
        WHERE NOT EXISTS (
          SELECT 1 FROM financial_accounts fa
          WHERE fa.id = NEW.reserve_account_id
            AND fa.type = 'goalReserve'
            AND fa.household_id = NEW.household_id
            AND fa.currency_code = NEW.currency_code
            AND fa.is_spendable = 0
            AND fa.is_protected = 0
            AND fa.owner_type = 'household'
        );
      END
    ''');
  }

  // ── Phase 5B.4: Reserve owner_type immutability trigger ──────────────────
  //
  // Prevents post-linkage mutation of owner_type on a goalReserve account.

  Future<void> _applyReserveOwnerTypeTrigger() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_reserve_owner_type
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.owner_type != OLD.owner_type
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve owner_type cannot be changed after linkage');
      END
    ''');
  }

  // ── Phase 5B.4: Goal lifecycle events triggers ────────────────────────────
  //
  // goal_lifecycle_events rows are write-once (no UPDATE or DELETE).

  Future<void> _applyGoalLifecycleEventsTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_goal_lifecycle_events
      BEFORE UPDATE ON goal_lifecycle_events
      BEGIN
        SELECT RAISE(ABORT, 'goal lifecycle events are immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_goal_lifecycle_events
      BEFORE DELETE ON goal_lifecycle_events
      BEGIN
        SELECT RAISE(ABORT, 'goal lifecycle events cannot be deleted');
      END
    ''');
    // Enforce household_id FK: the goal_lifecycle_events.household_id must
    // reference an existing row in households (simulated FK since the Drift
    // table definition uses plain TextColumn, not .references()).
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS fk_goal_lifecycle_event_household_id
      BEFORE INSERT ON goal_lifecycle_events
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'goal_lifecycle_events.household_id must reference a valid household')
        WHERE NOT EXISTS (
          SELECT 1 FROM households WHERE id = NEW.household_id
        );
      END
    ''');
  }

  // ── Phase 5B.4: Goal lifecycle events idempotency index ──────────────────

  Future<void> _applyGoalLifecycleEventsIndex() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_lifecycle_events_idempotency
      ON goal_lifecycle_events(idempotency_key)
      WHERE idempotency_key IS NOT NULL
    ''');
  }

  // ── Phase 5B.3: Extended movement household validation ────────────────────
  //
  // Validates that the operation's household, source/destination accounts'
  // households all match the movement's household_id.

  Future<void> _applyGoalMovementsHouseholdTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_funding_movement_household
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'funding'
      BEGIN
        SELECT RAISE(ABORT, 'funding movement validation failed: cross-household or wrong direction')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations o
          JOIN goals g ON g.id = NEW.goal_id
          JOIN financial_accounts src ON src.id = o.source_account_id
          JOIN financial_accounts dst ON dst.id = o.destination_account_id
          WHERE o.id = NEW.transfer_operation_id
            AND o.type = 'transfer'
            AND o.destination_account_id = g.reserve_account_id
            AND o.household_id = NEW.household_id
            AND g.household_id = NEW.household_id
            AND src.household_id = NEW.household_id
            AND dst.household_id = NEW.household_id
        );
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_release_movement_household
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'release'
      BEGIN
        SELECT RAISE(ABORT, 'release movement validation failed: cross-household or wrong direction')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations o
          JOIN goals g ON g.id = NEW.goal_id
          JOIN financial_accounts src ON src.id = o.source_account_id
          JOIN financial_accounts dst ON dst.id = o.destination_account_id
          WHERE o.id = NEW.transfer_operation_id
            AND o.type = 'transfer'
            AND o.source_account_id = g.reserve_account_id
            AND o.household_id = NEW.household_id
            AND g.household_id = NEW.household_id
            AND src.household_id = NEW.household_id
            AND dst.household_id = NEW.household_id
        )
        OR (NEW.release_reason IS NULL OR length(trim(NEW.release_reason)) = 0);
      END
    ''');
  }

  // ── Phase 5B.5: Reversal linkage + lifecycle household isolation ──────────

  Future<void> _applyPhase5B5ReversalAndLifecycleHardening() async {
    // Reversal movement must reference a valid original of the same
    // goal/household; the linked operation must be type = 'reversal'.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_reversal_movement_link
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.reversal_of_movement_id IS NOT NULL OR NEW.movement_type = 'reversal'
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal reversal linkage')
        WHERE NOT EXISTS (
          SELECT 1 FROM goal_movements orig
          JOIN operations o ON o.id = NEW.transfer_operation_id
          WHERE orig.id = NEW.reversal_of_movement_id
            AND orig.goal_id = NEW.goal_id
            AND orig.household_id = NEW.household_id
            AND orig.movement_type IN ('funding', 'release')
            AND o.type = 'reversal'
            AND o.household_id = NEW.household_id
        );
      END
    ''');

    // V1: at most one reversal movement per original movement.
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_movements_one_reversal_per_original
      ON goal_movements(reversal_of_movement_id)
      WHERE reversal_of_movement_id IS NOT NULL
    ''');

    // Lifecycle event household must equal the referenced goal's household.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_lifecycle_household_matches_goal
      BEFORE INSERT ON goal_lifecycle_events
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'lifecycle event household must match goal household')
        WHERE NOT EXISTS (
          SELECT 1 FROM goals g
          WHERE g.id = NEW.goal_id
            AND g.household_id = NEW.household_id
        );
      END
    ''');

    // Replace global unique idempotency with household-scoped uniqueness.
    await customStatement(
      'DROP INDEX IF EXISTS idx_goal_lifecycle_events_idempotency',
    );
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_lifecycle_hh_idem
      ON goal_lifecycle_events(household_id, idempotency_key)
      WHERE idempotency_key IS NOT NULL
    ''');
  }

  // ── Phase 5B.6: Balanced goal-transfer ledger linkage ─────────────────────
  //
  // Before a funding/release goal movement is inserted, prove the linked
  // operation has exactly one debit and one credit, amounts equal and positive,
  // accounts matching operation source/destination, and matching currency /
  // household. Additional legs are rejected.

  Future<void> _applyPhase5B6BalancedMovementTrigger() async {
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS validate_goal_transfer_balanced_legs '
      'BEFORE INSERT ON goal_movements '
      'FOR EACH ROW '
      "WHEN NEW.movement_type IN ('funding', 'release') "
      'BEGIN '
      '  SELECT RAISE( '
      '    ABORT, '
      "    'goal movement requires exactly two balanced ledger legs matching operation' "
      '  ) '
      '  WHERE ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      '  ) != 2 '
      '  OR ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      "      AND e.direction = 'debit' "
      '  ) != 1 '
      '  OR ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      "      AND e.direction = 'credit' "
      '  ) != 1 '
      '  OR NOT EXISTS ( '
      '    SELECT 1 '
      '    FROM operations o '
      "    JOIN ledger_entries d ON d.operation_id = o.id AND d.direction = 'debit' "
      "    JOIN ledger_entries c ON c.operation_id = o.id AND c.direction = 'credit' "
      '    WHERE o.id = NEW.transfer_operation_id '
      '      AND o.household_id = NEW.household_id '
      '      AND d.account_id = o.source_account_id '
      '      AND c.account_id = o.destination_account_id '
      '      AND d.amount_minor_units = c.amount_minor_units '
      '      AND d.amount_minor_units = o.total_amount_minor_units '
      '      AND d.amount_minor_units > 0 '
      '      AND c.amount_minor_units > 0 '
      '      AND d.currency_code = o.currency_code '
      '      AND c.currency_code = o.currency_code '
      '      AND d.household_id = o.household_id '
      '      AND c.household_id = o.household_id '
      '  ); '
      'END',
    );
  }

  // ── Phase 5B.7: Reversal balanced legs + explicit status-transition alias ──

  Future<void> _applyPhase5B7ReversalBalancedAndStatusTriggers() async {
    // Reversal goal movements must prove balanced inverse mirror legs.
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS validate_goal_reversal_balanced_legs '
      'BEFORE INSERT ON goal_movements '
      'FOR EACH ROW '
      "WHEN NEW.movement_type = 'reversal' "
      'BEGIN '
      '  SELECT RAISE( '
      '    ABORT, '
      "    'goal reversal movement requires balanced inverse ledger legs' "
      '  ) '
      '  WHERE NEW.reversal_of_movement_id IS NULL '
      '  OR ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      '  ) != 2 '
      '  OR ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      "      AND e.direction = 'debit' "
      '  ) != 1 '
      '  OR ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      "      AND e.direction = 'credit' "
      '  ) != 1 '
      '  OR NOT EXISTS ( '
      '    SELECT 1 '
      '    FROM operations rev '
      '    JOIN goal_movements orig_mov ON orig_mov.id = NEW.reversal_of_movement_id '
      '    JOIN operations orig ON orig.id = orig_mov.transfer_operation_id '
      "    JOIN ledger_entries d ON d.operation_id = rev.id AND d.direction = 'debit' "
      "    JOIN ledger_entries c ON c.operation_id = rev.id AND c.direction = 'credit' "
      '    WHERE rev.id = NEW.transfer_operation_id '
      "      AND rev.type = 'reversal' "
      '      AND rev.household_id = NEW.household_id '
      '      AND orig.household_id = NEW.household_id '
      '      AND orig_mov.goal_id = NEW.goal_id '
      '      AND orig_mov.household_id = NEW.household_id '
      "      AND orig_mov.movement_type IN ('funding', 'release') "
      '      AND orig.is_reversed = 1 '
      '      AND orig.reversed_by = rev.id '
      // Entry accounts must be the inverse of the original transfer accounts:
      // debit the original destination; credit the original source.
      '      AND d.account_id = orig.destination_account_id '
      '      AND c.account_id = orig.source_account_id '
      '      AND d.account_id = rev.source_account_id '
      '      AND c.account_id = rev.destination_account_id '
      '      AND d.amount_minor_units = c.amount_minor_units '
      '      AND d.amount_minor_units = rev.total_amount_minor_units '
      '      AND d.amount_minor_units = orig.total_amount_minor_units '
      '      AND d.amount_minor_units > 0 '
      '      AND c.amount_minor_units > 0 '
      '      AND d.currency_code = rev.currency_code '
      '      AND c.currency_code = rev.currency_code '
      '      AND rev.currency_code = orig.currency_code '
      '      AND d.household_id = rev.household_id '
      '      AND c.household_id = rev.household_id '
      '  ); '
      'END',
    );

    // Explicit product-policy alias (same allowed set as goal_status_valid_transition).
    // Forbidden: completed→active, archived→completed, targetReached, and any other path.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS reject_unsupported_goal_status_transition
      BEFORE UPDATE OF status ON goals
      FOR EACH ROW
      WHEN NEW.status != OLD.status
        AND NOT (
          (OLD.status = 'active' AND NEW.status IN ('completed','archived'))
          OR (OLD.status = 'completed' AND NEW.status = 'archived')
          OR (OLD.status = 'archived' AND NEW.status = 'active')
        )
      BEGIN
        SELECT RAISE(ABORT, 'unsupported goal status transition');
      END
    ''');
  }

  // ── Phase 5B.8: Lifecycle / derived-progress separation ───────────────────

  Future<void> _applyPhase5B8LifecycleProgressSeparation() async {
    // Drop transition triggers BEFORE migrating rows: the legacy allowed set
    // never included targetReached→active, so the data fix would abort.
    await customStatement(
      'DROP TRIGGER IF EXISTS goal_status_valid_transition',
    );
    await customStatement(
      'DROP TRIGGER IF EXISTS reject_unsupported_goal_status_transition',
    );
    await customStatement('DROP TRIGGER IF EXISTS check_goal_lifecycle_status');
    await customStatement(
      'DROP TRIGGER IF EXISTS check_goal_lifecycle_status_update',
    );

    // Migrate any persisted progress-as-lifecycle rows to active.
    // Does NOT insert completion lifecycle events.
    await customStatement(
      "UPDATE goals SET status = 'active' WHERE status = 'targetReached'",
    );

    // Recreate transition triggers without targetReached.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_status_valid_transition
      BEFORE UPDATE ON goals
      FOR EACH ROW
      WHEN NEW.status != OLD.status
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal status transition')
        WHERE NOT (
          (OLD.status = 'active'    AND NEW.status IN ('completed','archived'))
          OR (OLD.status = 'completed' AND NEW.status = 'archived')
          OR (OLD.status = 'archived'  AND NEW.status = 'active')
        );
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS reject_unsupported_goal_status_transition
      BEFORE UPDATE OF status ON goals
      FOR EACH ROW
      WHEN NEW.status != OLD.status
        AND NOT (
          (OLD.status = 'active' AND NEW.status IN ('completed','archived'))
          OR (OLD.status = 'completed' AND NEW.status = 'archived')
          OR (OLD.status = 'archived' AND NEW.status = 'active')
        )
      BEGIN
        SELECT RAISE(ABORT, 'unsupported goal status transition');
      END
    ''');

    // Reject invalid lifecycle values on INSERT / UPDATE OF status.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_goal_lifecycle_status
      BEFORE INSERT ON goals
      FOR EACH ROW
      WHEN NEW.status NOT IN ('active', 'completed', 'archived')
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal lifecycle status');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_goal_lifecycle_status_update
      BEFORE UPDATE OF status ON goals
      FOR EACH ROW
      WHEN NEW.status NOT IN ('active', 'completed', 'archived')
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal lifecycle status');
      END
    ''');
  }

  // ── Phase 6A: Savings certificates ────────────────────────────────────────

  Future<void> _applyPhase6ACertificateSchema() async {
    await _applyCertificateIndexes();
    await _applyCertificateImmutabilityTriggers();
    await _applyCertificateAccountHardeningTriggers();
    await _applyCertificateEventFinancialTriggers();
  }

  Future<void> _applyCertificateIndexes() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_savings_certificates_account
      ON savings_certificates(certificate_account_id)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_savings_certificates_idempotency
      ON savings_certificates(household_id, idempotency_key)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_savings_certificates_household
      ON savings_certificates(household_id, lifecycle, maturity_date)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_certificate_revisions_certificate
      ON certificate_revisions(certificate_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_certificate_events_certificate
      ON certificate_events(certificate_id, created_at)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_certificate_events_related_op
      ON certificate_events(related_operation_id)
      WHERE related_operation_id IS NOT NULL
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_certificate_events_idempotency
      ON certificate_events(household_id, idempotency_key)
      WHERE idempotency_key IS NOT NULL
    ''');
  }

  Future<void> _applyCertificateImmutabilityTriggers() async {
    // Revisions / events append-only.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_certificate_revisions
      BEFORE UPDATE ON certificate_revisions
      BEGIN
        SELECT RAISE(ABORT, 'certificate_revisions are immutable and cannot be updated');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_certificate_revisions
      BEFORE DELETE ON certificate_revisions
      BEGIN
        SELECT RAISE(ABORT, 'certificate_revisions cannot be deleted');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_certificate_events
      BEFORE UPDATE ON certificate_events
      BEGIN
        SELECT RAISE(ABORT, 'certificate_events are immutable and cannot be updated');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_certificate_events
      BEFORE DELETE ON certificate_events
      BEGIN
        SELECT RAISE(ABORT, 'certificate_events cannot be deleted');
      END
    ''');

    // Certificate structural immutability.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_certificate_immutable
      BEFORE UPDATE ON savings_certificates
      FOR EACH ROW
      WHEN NEW.household_id != OLD.household_id
        OR NEW.certificate_account_id != OLD.certificate_account_id
        OR NEW.currency_code != OLD.currency_code
        OR NEW.original_principal_minor_units != OLD.original_principal_minor_units
        OR NEW.start_date != OLD.start_date
        OR NEW.maturity_date != OLD.maturity_date
        OR NEW.idempotency_key != OLD.idempotency_key
        OR NEW.created_at != OLD.created_at
      BEGIN
        SELECT RAISE(ABORT, 'certificate immutable fields cannot be changed');
      END
    ''');

    // Lifecycle value CHECK.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_certificate_lifecycle_insert
      BEFORE INSERT ON savings_certificates
      FOR EACH ROW
      WHEN NEW.lifecycle NOT IN ('active', 'redeemed', 'archived')
      BEGIN
        SELECT RAISE(ABORT, 'invalid certificate lifecycle');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_certificate_lifecycle_update
      BEFORE UPDATE OF lifecycle ON savings_certificates
      FOR EACH ROW
      WHEN NEW.lifecycle NOT IN ('active', 'redeemed', 'archived')
      BEGIN
        SELECT RAISE(ABORT, 'invalid certificate lifecycle');
      END
    ''');

    // Valid lifecycle transitions: active→redeemed/archived; redeemed→archived;
    // archived→active (restore).
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS certificate_lifecycle_valid_transition
      BEFORE UPDATE OF lifecycle ON savings_certificates
      FOR EACH ROW
      WHEN NEW.lifecycle != OLD.lifecycle
        AND NOT (
          (OLD.lifecycle = 'active' AND NEW.lifecycle IN ('redeemed','archived'))
          OR (OLD.lifecycle = 'redeemed' AND NEW.lifecycle = 'archived')
          OR (OLD.lifecycle = 'archived' AND NEW.lifecycle = 'active')
        )
      BEGIN
        SELECT RAISE(ABORT, 'invalid certificate lifecycle transition');
      END
    ''');

    // No cascade financial delete: reject delete when events exist.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_certificate_with_history
      BEFORE DELETE ON savings_certificates
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'cannot delete certificate with history')
        WHERE EXISTS (
          SELECT 1 FROM certificate_events WHERE certificate_id = OLD.id
        )
        OR EXISTS (
          SELECT 1 FROM certificate_revisions WHERE certificate_id = OLD.id
        );
      END
    ''');

    // Event household must match certificate household.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS certificate_event_household_match
      BEFORE INSERT ON certificate_events
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'certificate event household mismatch')
        WHERE NOT EXISTS (
          SELECT 1 FROM savings_certificates sc
          WHERE sc.id = NEW.certificate_id
            AND sc.household_id = NEW.household_id
        );
      END
    ''');

    // Revision household must match.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS certificate_revision_household_match
      BEFORE INSERT ON certificate_revisions
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'certificate revision household mismatch')
        WHERE NOT EXISTS (
          SELECT 1 FROM savings_certificates sc
          WHERE sc.id = NEW.certificate_id
            AND sc.household_id = NEW.household_id
        );
      END
    ''');
  }

  Future<void> _applyCertificateAccountHardeningTriggers() async {
    // Validate certificate row references a proper certificate account.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_certificate_account_on_insert
      BEFORE INSERT ON savings_certificates
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT,
          'certificate account must be type certificate, same household/currency, non-spendable, not protected, household-owned')
        WHERE NOT EXISTS (
          SELECT 1 FROM financial_accounts fa
          WHERE fa.id = NEW.certificate_account_id
            AND fa.household_id = NEW.household_id
            AND fa.currency_code = NEW.currency_code
            AND fa.type = 'certificate'
            AND fa.is_spendable = 0
            AND fa.is_protected = 0
            AND fa.owner_type = 'household'
        );
      END
    ''');

    // Prevent retyping certificate accounts.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_retype_certificate_account
      BEFORE UPDATE OF type ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'certificate' AND NEW.type != 'certificate'
      BEGIN
        SELECT RAISE(ABORT, 'certificate account type cannot be changed');
      END
    ''');

    // Lock spendable / protected / owner on certificate accounts.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_certificate_spendable
      BEFORE UPDATE OF is_spendable ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'certificate' AND NEW.is_spendable != OLD.is_spendable
      BEGIN
        SELECT RAISE(ABORT, 'certificate is_spendable cannot be changed');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_certificate_protected
      BEFORE UPDATE OF is_protected ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'certificate' AND NEW.is_protected != OLD.is_protected
      BEGIN
        SELECT RAISE(ABORT, 'certificate is_protected cannot be changed');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_certificate_owner_type
      BEFORE UPDATE OF owner_type ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'certificate' AND NEW.owner_type != OLD.owner_type
      BEGIN
        SELECT RAISE(ABORT, 'certificate owner_type cannot be changed');
      END
    ''');
  }

  Future<void> _applyCertificateEventFinancialTriggers() async {
    // Purchase event must link a certificateFunding transfer INTO the cert account.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_certificate_purchase_event
      BEFORE INSERT ON certificate_events
      FOR EACH ROW
      WHEN NEW.event_type = 'purchased'
      BEGIN
        SELECT RAISE(ABORT, 'purchase event requires balanced transfer into certificate account')
        WHERE NEW.related_operation_id IS NULL
           OR NOT EXISTS (
             SELECT 1 FROM operations o
             JOIN savings_certificates sc ON sc.id = NEW.certificate_id
             WHERE o.id = NEW.related_operation_id
               AND o.household_id = NEW.household_id
               AND o.type = 'certificateFunding'
               AND o.destination_account_id = sc.certificate_account_id
               AND o.source_account_id IS NOT NULL
               AND o.source_account_id != sc.certificate_account_id
               AND o.total_amount_minor_units = NEW.amount_minor_units
               AND o.currency_code = NEW.currency_code
           )
           OR (
             SELECT COUNT(*) FROM ledger_entries le
             WHERE le.operation_id = NEW.related_operation_id
           ) != 2
           OR (
             SELECT SUM(CASE WHEN direction='credit' THEN amount_minor_units
                             ELSE -amount_minor_units END)
             FROM ledger_entries
             WHERE operation_id = NEW.related_operation_id
           ) != 0;
      END
    ''');

    // Redemption event must link a certificateMaturity transfer OUT of cert.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_certificate_redemption_event
      BEFORE INSERT ON certificate_events
      FOR EACH ROW
      WHEN NEW.event_type = 'redeemed'
      BEGIN
        SELECT RAISE(ABORT, 'redemption event requires balanced transfer out of certificate account')
        WHERE NEW.related_operation_id IS NULL
           OR NOT EXISTS (
             SELECT 1 FROM operations o
             JOIN savings_certificates sc ON sc.id = NEW.certificate_id
             WHERE o.id = NEW.related_operation_id
               AND o.household_id = NEW.household_id
               AND o.type = 'certificateMaturity'
               AND o.source_account_id = sc.certificate_account_id
               AND o.destination_account_id IS NOT NULL
               AND o.destination_account_id != sc.certificate_account_id
               AND o.total_amount_minor_units = NEW.amount_minor_units
               AND o.currency_code = NEW.currency_code
           )
           OR (
             SELECT COUNT(*) FROM ledger_entries le
             WHERE le.operation_id = NEW.related_operation_id
           ) != 2
           OR (
             SELECT SUM(CASE WHEN direction='credit' THEN amount_minor_units
                             ELSE -amount_minor_units END)
             FROM ledger_entries
             WHERE operation_id = NEW.related_operation_id
           ) != 0;
      END
    ''');

    // Profit event must link an income op with certificate_profit category.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_certificate_profit_event
      BEFORE INSERT ON certificate_events
      FOR EACH ROW
      WHEN NEW.event_type = 'profitReceived'
      BEGIN
        SELECT RAISE(ABORT, 'profit event requires income operation')
        WHERE NEW.related_operation_id IS NULL
           OR NOT EXISTS (
             SELECT 1 FROM operations o
             JOIN savings_certificates sc ON sc.id = NEW.certificate_id
             WHERE o.id = NEW.related_operation_id
               AND o.household_id = NEW.household_id
               AND o.type = 'income'
               AND o.category_code = 'certificate_profit'
               AND o.total_amount_minor_units = NEW.amount_minor_units
               AND o.currency_code = NEW.currency_code
               AND o.destination_account_id IS NOT NULL
               AND o.destination_account_id != sc.certificate_account_id
           )
           OR (
             SELECT COUNT(*) FROM ledger_entries le
             WHERE le.operation_id = NEW.related_operation_id
               AND le.direction = 'credit'
           ) != 1;
      END
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
