/// Phase 5B.7 – True physical schema-12 → latest migration.
///
/// Builds a version-12 database from historical onCreate objects
/// (`test/fixtures/schema_v12_objects.sql` from commit 3124346) plus Drift
/// table DDL. Does NOT open current AppDatabase then delete v13+ objects.
library;

import 'dart:io';

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../helpers/true_schema_v12.dart';

void main() {
  test(
    'MIG-TRUE-1. True physical v12→latest preserves IDs and installs v13+v15 objects',
    () async {
      final path = await materializeTrueSchemaV12File();
      addTearDown(() async {
        final dir = Directory(p.dirname(path));
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      _insertFixtures(path);

      final before = sqlite3.sqlite3.open(path);
      expect(before.select('PRAGMA user_version').first['user_version'], 12);
      expect(
        before
            .select(
              "SELECT COUNT(*) AS c FROM sqlite_master "
              "WHERE name = 'validate_goal_transfer_balanced_legs'",
            )
            .first['c'],
        0,
      );
      before.close();

      // Reopen with current AppDatabase → onUpgrade 12→15
      final db = AppDatabase.forFile(path);
      addTearDown(db.close);

      final version = await db.customSelect('PRAGMA user_version').get();
      expect(version.first.read<int>('user_version'), 15);

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
                  "SELECT amount_minor_units FROM ledger_entries "
                  "WHERE id = 'op-fund-mig_credit'",
                )
                .get())
            .first
            .read<int>('amount_minor_units'),
        25000,
      );

      for (final name in [
        'validate_reversal_movement_link',
        'goal_lifecycle_household_matches_goal',
        'validate_goal_transfer_balanced_legs',
        'validate_goal_reversal_balanced_legs',
        'reject_unsupported_goal_status_transition',
      ]) {
        expect(
          (await db
                  .customSelect(
                    "SELECT COUNT(*) as c FROM sqlite_master "
                    "WHERE type='trigger' AND name='$name'",
                  )
                  .get())
              .first
              .read<int>('c'),
          1,
          reason: '$name must exist after upgrade to v15',
        );
      }
      expect(
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM sqlite_master WHERE type='index' "
                  "AND name='idx_goal_movements_one_reversal_per_original'",
                )
                .get())
            .first
            .read<int>('c'),
        1,
      );
      expect(
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM sqlite_master WHERE type='index' "
                  "AND name='idx_goal_lifecycle_hh_idem'",
                )
                .get())
            .first
            .read<int>('c'),
        1,
      );

      final bal =
          (await db
                  .customSelect(
                    "SELECT COALESCE(SUM(CASE WHEN direction='credit' "
                    'THEN amount_minor_units ELSE -amount_minor_units END),0) AS bal '
                    "FROM ledger_entries WHERE account_id='acct-reserve'",
                  )
                  .get())
              .first
              .read<int>('bal');
      expect(bal, 25000);
    },
  );
}

void _insertFixtures(String path) {
  final db = sqlite3.sqlite3.open(path);
  db.execute(
    "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
    "VALUES ('hh-mig', 'Migration HH', 'u-mig', "
    "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO household_members "
    "(id, household_id, display_name, role, is_archived, created_at, updated_at) "
    "VALUES ('mem-mig', 'hh-mig', 'Owner', 'primary_user', 0, "
    "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
    "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
    "include_in_zakat, display_order, created_by, created_at, updated_at) VALUES "
    "('acct-src', 'hh-mig', 'Cash', 'personalCashWallet', 'user', 'available', "
    "'EGP', 1, 0, 1, 0, 1, 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
    "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
    "include_in_zakat, display_order, created_by, created_at, updated_at) VALUES "
    "('acct-reserve', 'hh-mig', 'Reserve', 'goalReserve', 'household', 'goalReserve', "
    "'EGP', 0, 0, 1, 0, 9999, 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
    "status, idempotency_key, idempotency_payload, created_at) VALUES "
    "('goal-mig', 'hh-mig', 'acct-reserve', 'EGP', 'active', 'ik-mig', "
    "'payload-mig', '2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO goal_revisions (id, goal_id, household_id, name, purpose_code, "
    "target_minor_units, currency_code, created_at, revision_reason) VALUES "
    "('rev-mig', 'goal-mig', 'hh-mig', 'Emergency', 'emergencyFund', 100000, "
    "'EGP', '2024-01-01T00:00:00Z', 'initial')",
  );
  db.execute(
    "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
    "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
    "source_account_id, destination_account_id, idempotency_key, description) VALUES "
    "('op-fund-mig', 'hh-mig', 'transfer', '2024-01-01', '2024-01-01T00:00:00Z', "
    "25000, 'EGP', 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z', "
    "'acct-src', 'acct-reserve', 'ik-fund-mig', 'goal funding')",
  );
  db.execute(
    "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
    "direction, amount_minor_units, currency_code, entry_type, effective_date, "
    "recorded_at, created_by) VALUES "
    "('op-fund-mig_debit', 'op-fund-mig', 'hh-mig', 'acct-src', 'debit', 25000, "
    "'EGP', 'transferOut', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
  );
  db.execute(
    "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
    "direction, amount_minor_units, currency_code, entry_type, effective_date, "
    "recorded_at, created_by) VALUES "
    "('op-fund-mig_credit', 'op-fund-mig', 'hh-mig', 'acct-reserve', 'credit', 25000, "
    "'EGP', 'transferIn', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
  );
  db.execute(
    "INSERT INTO operation_contexts (operation_id, household_id, is_recurring, "
    "note, created_at) VALUES "
    "('op-fund-mig', 'hh-mig', 0, 'funding context', '2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
    "movement_type, created_at) VALUES "
    "('mov-mig', 'goal-mig', 'hh-mig', 'op-fund-mig', 'funding', "
    "'2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO budgets (id, household_id, name, currency_code, "
    "limit_minor_units, period_type, is_archived, idempotency_key, "
    "idempotency_payload, created_at, updated_at) VALUES "
    "('bud-mig', 'hh-mig', 'Food', 'EGP', 50000, 'monthly', 0, "
    "'ik-bud-mig', 'payload', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
  );
  expect(db.select('PRAGMA user_version').first['user_version'], 12);
  db.close();
}
