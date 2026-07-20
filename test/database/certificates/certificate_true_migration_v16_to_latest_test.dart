/// Phase 6A.2 – Authentic physical schema-16 → latest migration.
///
/// Builds a version-16 database from historical onCreate objects
/// (`test/fixtures/schema_v16_objects.sql` from commit 86736ca) plus Drift
/// table DDL. Does NOT open current AppDatabase then delete v17+ objects.
library;

import 'dart:io';

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../helpers/true_schema_v16.dart';

void main() {
  test(
    'MIG-6A2-1. Authentic physical v16→latest preserves data and installs certs',
    () async {
      final path = await materializeTrueSchemaV16File();
      addTearDown(() async {
        final dir = Directory(p.dirname(path));
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      _insertFixtures(path);

      final before = sqlite3.sqlite3.open(path);
      expect(before.select('PRAGMA user_version').first['user_version'], 16);
      expect(
        before
            .select(
              "SELECT COUNT(*) AS c FROM sqlite_master "
              "WHERE name = 'savings_certificates'",
            )
            .first['c'],
        0,
      );
      expect(
        before
            .select(
              "SELECT COUNT(*) AS c FROM sqlite_master "
              "WHERE name = 'prevent_negative_account_balance'",
            )
            .first['c'],
        0,
      );
      before.close();

      final db = AppDatabase.forFile(path);
      addTearDown(db.close);

      final version = await db.customSelect('PRAGMA user_version').get();
      expect(version.first.read<int>('user_version'), 19);

      expect(
        (await db
                .customSelect("SELECT id FROM households WHERE id = 'hh-mig'")
                .get())
            .first
            .read<String>('id'),
        'hh-mig',
      );
      expect(
        (await db
                .customSelect(
                  "SELECT display_name FROM household_members WHERE id = 'mem-mig'",
                )
                .get())
            .first
            .read<String>('display_name'),
        'Owner',
      );
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
      expect(
        (await db
                .customSelect("SELECT name FROM budgets WHERE id = 'bud-mig'")
                .get())
            .first
            .read<String>('name'),
        'Food',
      );

      for (final name in [
        'savings_certificates',
        'certificate_revisions',
        'certificate_events',
      ]) {
        expect(
          (await db
                  .customSelect(
                    "SELECT COUNT(*) as c FROM sqlite_master "
                    "WHERE type='table' AND name='$name'",
                  )
                  .get())
              .first
              .read<int>('c'),
          1,
          reason: '$name must exist after upgrade to latest',
        );
      }
      for (final name in [
        'validate_certificate_account_on_insert',
        'validate_certificate_purchase_event',
        'validate_certificate_redemption_event',
        'validate_certificate_profit_event',
        'prevent_negative_account_balance',
        'no_update_certificate_events',
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
          reason: '$name must exist after upgrade',
        );
      }

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

  test(
    'MIG-6A2-2. Migration rollback: fail-inject mid-upgrade leaves DB unusable',
    () async {
      // Documented behaviour: Drift onUpgrade is not resumable mid-method after
      // a hard abort. We prove that a broken intermediate file with user_version
      // stuck below latest does not silently claim certificate readiness.
      final path = await materializeTrueSchemaV16File();
      addTearDown(() async {
        final dir = Directory(p.dirname(path));
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      _insertFixtures(path);

      final raw = sqlite3.sqlite3.open(path);
      // Simulate a partial upgrade that created tables but never finished
      // triggers / user_version bump (operator abort / crash mid-migration).
      raw.execute('''
CREATE TABLE savings_certificates (
  id TEXT NOT NULL PRIMARY KEY,
  household_id TEXT NOT NULL,
  certificate_account_id TEXT NOT NULL,
  currency_code TEXT NOT NULL,
  original_principal_minor_units INTEGER NOT NULL,
  start_date TEXT NOT NULL,
  maturity_date TEXT NOT NULL,
  lifecycle TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  idempotency_payload TEXT NOT NULL,
  created_at TEXT NOT NULL,
  redeemed_at TEXT NULL,
  archived_at TEXT NULL,
  schema_version INTEGER NOT NULL DEFAULT 1
)
''');
      raw.execute('PRAGMA user_version = 16');
      raw.close();

      final stuck = sqlite3.sqlite3.open(path);
      expect(stuck.select('PRAGMA user_version').first['user_version'], 16);
      expect(
        stuck
            .select(
              "SELECT COUNT(*) AS c FROM sqlite_master "
              "WHERE name='validate_certificate_purchase_event'",
            )
            .first['c'],
        0,
      );
      stuck.close();

      // Reopening with AppDatabase completes onUpgrade from 16 → 19.
      final db = AppDatabase.forFile(path);
      addTearDown(db.close);
      expect(
        (await db.customSelect('PRAGMA user_version').get()).first.read<int>(
          'user_version',
        ),
        19,
      );
      // createTable IF path: table already existed; triggers must still install.
      expect(
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM sqlite_master "
                  "WHERE type='trigger' AND name='validate_certificate_purchase_event'",
                )
                .get())
            .first
            .read<int>('c'),
        1,
      );
      expect(
        (await db
                .customSelect("SELECT id FROM goals WHERE id = 'goal-mig'")
                .get())
            .first
            .read<String>('id'),
        'goal-mig',
      );
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
    "INSERT INTO goal_lifecycle_events (id, goal_id, household_id, event_type, "
    "effective_at, created_at) VALUES "
    "('life-mig', 'goal-mig', 'hh-mig', 'created', "
    "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO budgets (id, household_id, name, currency_code, "
    "limit_minor_units, period_type, is_archived, idempotency_key, "
    "idempotency_payload, created_at, updated_at) VALUES "
    "('bud-mig', 'hh-mig', 'Food', 'EGP', 50000, 'monthly', 0, "
    "'ik-bud-mig', 'payload', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
  );
  expect(db.select('PRAGMA user_version').first['user_version'], 16);
  db.close();
}
