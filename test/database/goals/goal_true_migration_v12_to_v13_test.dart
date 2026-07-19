/// Phase 5B.5 – True physical-file v12 → v13 migration test.
///
/// Does NOT treat fresh onCreate as migration evidence. Creates a physical
/// temporary SQLite file, materialises schema version 12 (by creating with the
/// current schema then stripping v13-only objects and pinning `user_version`),
/// inserts fixture rows, closes, reopens with [AppDatabase] (schemaVersion 13),
/// and asserts `onUpgrade` applied v13 objects while preserving all IDs.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'MIG-TRUE-1. Physical file v12→v13 preserves fixtures and applies hardening',
    () async {
      final dir = await Directory.systemTemp.createTemp('fmm_mig_v12_');
      final path = p.join(dir.path, 'test.db');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      // ── Phase A: materialise a v12 database on disk ─────────────────────────
      var db = AppDatabase.withExecutor(NativeDatabase(File(path)));

      // Strip v13-only objects that onCreate installed (schemaVersion is now 13).
      await db.customStatement(
        'DROP TRIGGER IF EXISTS validate_reversal_movement_link',
      );
      await db.customStatement(
        'DROP INDEX IF EXISTS idx_goal_movements_one_reversal_per_original',
      );
      await db.customStatement(
        'DROP TRIGGER IF EXISTS goal_lifecycle_household_matches_goal',
      );
      await db.customStatement(
        'DROP INDEX IF EXISTS idx_goal_lifecycle_hh_idem',
      );
      // Restore the pre-v13 global lifecycle idempotency index.
      await db.customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_lifecycle_events_idempotency
      ON goal_lifecycle_events(idempotency_key)
      WHERE idempotency_key IS NOT NULL
    ''');
      await db.customStatement('PRAGMA user_version = 12');

      // Fixture data spanning households, members, accounts, goals, ledger.
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('hh-mig', 'Migration HH', 'u-mig', "
        "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
      );
      await db.customStatement(
        "INSERT INTO household_members "
        "(id, household_id, display_name, role, is_archived, created_at, updated_at) "
        "VALUES ('mem-mig', 'hh-mig', 'Owner', 'primary_user', 0, "
        "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
      );
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) VALUES "
        "('acct-src', 'hh-mig', 'Cash', 'personalCashWallet', 'user', 'available', "
        "'EGP', 1, 0, 1, 0, 1, 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
      );
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) VALUES "
        "('acct-reserve', 'hh-mig', 'Reserve', 'goalReserve', 'household', 'goalReserve', "
        "'EGP', 0, 0, 1, 0, 9999, 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
      );
      await db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) VALUES "
        "('goal-mig', 'hh-mig', 'acct-reserve', 'EGP', 'active', 'ik-mig', "
        "'payload-mig', '2024-01-01T00:00:00Z')",
      );
      await db.customStatement(
        "INSERT INTO goal_revisions (id, goal_id, household_id, name, purpose_code, "
        "target_minor_units, currency_code, created_at, revision_reason) VALUES "
        "('rev-mig', 'goal-mig', 'hh-mig', 'Emergency', 'emergencyFund', 100000, "
        "'EGP', '2024-01-01T00:00:00Z', 'initial')",
      );
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "source_account_id, destination_account_id, idempotency_key, description) VALUES "
        "('op-fund-mig', 'hh-mig', 'transfer', '2024-01-01', '2024-01-01T00:00:00Z', "
        "25000, 'EGP', 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z', "
        "'acct-src', 'acct-reserve', 'ik-fund-mig', 'goal funding')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
        "direction, amount_minor_units, currency_code, entry_type, effective_date, "
        "recorded_at, created_by) VALUES "
        "('op-fund-mig_debit', 'op-fund-mig', 'hh-mig', 'acct-src', 'debit', 25000, "
        "'EGP', 'transferOut', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
        "direction, amount_minor_units, currency_code, entry_type, effective_date, "
        "recorded_at, created_by) VALUES "
        "('op-fund-mig_credit', 'op-fund-mig', 'hh-mig', 'acct-reserve', 'credit', 25000, "
        "'EGP', 'transferIn', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
      );
      await db.customStatement(
        "INSERT INTO operation_contexts (operation_id, household_id, is_recurring, "
        "note, created_at) VALUES "
        "('op-fund-mig', 'hh-mig', 0, 'funding context', '2024-01-01T00:00:00Z')",
      );
      await db.customStatement(
        "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
        "movement_type, created_at) VALUES "
        "('mov-mig', 'goal-mig', 'hh-mig', 'op-fund-mig', 'funding', "
        "'2024-01-01T00:00:00Z')",
      );
      await db.customStatement(
        "INSERT INTO budgets (id, household_id, name, currency_code, "
        "limit_minor_units, period_type, is_archived, idempotency_key, "
        "idempotency_payload, created_at, updated_at) VALUES "
        "('bud-mig', 'hh-mig', 'Food', 'EGP', 50000, 'monthly', 0, "
        "'ik-bud-mig', 'payload', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
      );

      // Confirm v13 trigger absent before upgrade.
      final beforeTriggers = await db
          .customSelect(
            "SELECT COUNT(*) as c FROM sqlite_master "
            "WHERE type = 'trigger' AND name = 'validate_reversal_movement_link'",
          )
          .get();
      expect(beforeTriggers.first.read<int>('c'), 0);

      final versionBefore = await db.customSelect('PRAGMA user_version').get();
      expect(versionBefore.first.read<int>('user_version'), 12);

      await db.close();

      // ── Phase B: reopen → onUpgrade 12→13 ───────────────────────────────────
      db = AppDatabase.withExecutor(NativeDatabase(File(path)));

      final versionAfter = await db.customSelect('PRAGMA user_version').get();
      expect(
        versionAfter.first.read<int>('user_version'),
        13,
        reason: 'onUpgrade must advance user_version to 13',
      );

      // Fixture IDs preserved.
      expect(
        (await db
                .customSelect("SELECT id FROM goals WHERE id = 'goal-mig'")
                .get())
            .first
            .read<String>('id'),
        'goal-mig',
      );
      expect(
        (await db
                .customSelect(
                  "SELECT amount_minor_units FROM ledger_entries WHERE id = 'op-fund-mig_credit'",
                )
                .get())
            .first
            .read<int>('amount_minor_units'),
        25000,
      );
      expect(
        (await db
                .customSelect(
                  "SELECT note FROM operation_contexts WHERE operation_id = 'op-fund-mig'",
                )
                .get())
            .first
            .read<String>('note'),
        'funding context',
      );
      expect(
        (await db
                .customSelect("SELECT id FROM budgets WHERE id = 'bud-mig'")
                .get())
            .first
            .read<String>('id'),
        'bud-mig',
      );

      // Lifecycle table still present.
      expect(
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM sqlite_master "
                  "WHERE type = 'table' AND name = 'goal_lifecycle_events'",
                )
                .get())
            .first
            .read<int>('c'),
        1,
      );

      // reversal_of_movement_id column present.
      final cols = await db
          .customSelect('PRAGMA table_info(goal_movements)')
          .get();
      expect(
        cols.any((r) => r.read<String>('name') == 'reversal_of_movement_id'),
        isTrue,
      );

      // v13 triggers / indexes active.
      expect(
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM sqlite_master "
                  "WHERE type = 'trigger' AND name = 'validate_reversal_movement_link'",
                )
                .get())
            .first
            .read<int>('c'),
        1,
      );
      expect(
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM sqlite_master "
                  "WHERE type = 'trigger' AND name = 'goal_lifecycle_household_matches_goal'",
                )
                .get())
            .first
            .read<int>('c'),
        1,
      );
      expect(
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM sqlite_master "
                  "WHERE type = 'index' AND name = 'idx_goal_movements_one_reversal_per_original'",
                )
                .get())
            .first
            .read<int>('c'),
        1,
      );
      expect(
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM sqlite_master "
                  "WHERE type = 'index' AND name = 'idx_goal_lifecycle_hh_idem'",
                )
                .get())
            .first
            .read<int>('c'),
        1,
      );

      // Reversal linkage validation active post-migration.
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
        "VALUES ('rev-bad', 'hh-mig', 'reversal', '2024-01-02', '2024-01-02T00:00:00Z', "
        "1, 'EGP', 'test', '2024-01-02T00:00:00Z', '2024-01-02T00:00:00Z')",
      );
      expect(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
          "movement_type, created_at) VALUES "
          "('mov-bad', 'goal-mig', 'hh-mig', 'rev-bad', 'reversal', '2024-01-02T00:00:00Z')",
        ),
        throwsA(isA<Exception>()),
      );

      // Progress reconciles from ledger (CREDIT − DEBIT on reserve).
      final bal =
          (await db
                  .customSelect(
                    "SELECT COALESCE(SUM(CASE WHEN direction = 'credit' THEN amount_minor_units "
                    "ELSE -amount_minor_units END), 0) AS bal FROM ledger_entries "
                    "WHERE account_id = 'acct-reserve' AND household_id = 'hh-mig'",
                  )
                  .get())
              .first
              .read<int>('bal');
      expect(bal, 25000);

      // Migration rollback on injected failure: Drift runs onUpgrade inside a
      // transaction when the underlying backend supports it. Documented as
      // architecture-dependent; we do not inject mid-migration aborts here.
      await db.close();
    },
  );
}
