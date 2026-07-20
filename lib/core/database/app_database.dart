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
part 'schema/app_database_core_schema.dart';
part 'schema/app_database_goal_schema.dart';
part 'schema/app_database_certificate_schema.dart';

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
///  18 — Phase 6A.2: prevent_negative_account_balance AFTER INSERT on
///                 ledger_entries; strengthened certificate purchase /
///                 redemption / profit event balanced-leg validators.
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
class AppDatabase extends _$AppDatabase
    with
        _AppDatabaseCoreSchema,
        _AppDatabaseGoalSchema,
        _AppDatabaseCertificateSchema {
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
  int get schemaVersion => 18;

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
      await _applyPhase6A2DebitSafetyAndCertEventHardening();
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
      if (from <= 17) {
        // v17 → v18: Phase 6A.2 — non-negative balance + cert event legs.
        await _applyPhase6A2DebitSafetyAndCertEventHardening();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
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
