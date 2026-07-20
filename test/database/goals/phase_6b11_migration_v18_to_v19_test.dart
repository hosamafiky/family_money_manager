/// Phase 6B.1.1 / 6B.1.2 – Authentic physical schema-18 → 19 migration.
///
/// Provenance (see also [materializeTrueSchemaV18File]):
/// - Historical tip: `47fd59676d5a9a06ac6d4ea6f9b6ae3c256e4729`
/// - Objects fixture: `test/fixtures/schema_v18_objects.sql`
/// - Helper: `test/helpers/true_schema_v18.dart`
///
/// Flow:
/// 1. Materialize physical v18 file (no eligibility triggers; user_version=18)
/// 2. Insert stable fixture rows via raw sqlite3 (schema 19 never opened yet)
/// 3. Assert pre-migration: version 18, eligibility triggers absent
/// 4. Open current [AppDatabase.forFile] → authentic onUpgrade 18→19
/// 5. Assert IDs/history preserved + eligibility triggers installed
/// 6. Assert post-migration rejection + positive release/funding behavior
library;

import 'dart:io';

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/sqlite_contention_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../helpers/true_schema_v18.dart';

void main() {
  test(
    'MIG-6B11-1. Authentic physical v18→19 preserves IDs and installs eligibility triggers',
    () async {
      final path = await materializeTrueSchemaV18File();
      addTearDown(() async {
        final dir = Directory(p.dirname(path));
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      _insertFixtures(path);

      final before = sqlite3.sqlite3.open(path);
      expect(before.select('PRAGMA user_version').first['user_version'], 18);
      expect(
        before
            .select(
              "SELECT COUNT(*) AS c FROM sqlite_master "
              "WHERE name = 'validate_funding_source_eligibility'",
            )
            .first['c'],
        0,
      );
      expect(
        before
            .select(
              "SELECT COUNT(*) AS c FROM sqlite_master "
              "WHERE name = 'validate_release_destination_eligibility'",
            )
            .first['c'],
        0,
      );
      before.close();

      // Schema 19 is opened only here — authentic upgrade path.
      final db = AppDatabase.forFile(path);
      addTearDown(db.close);

      final version = await db.customSelect('PRAGMA user_version').get();
      expect(version.first.read<int>('user_version'), 19);

      expect(
        (await db
                .customSelect("SELECT id FROM households WHERE id = 'hh-6b11'")
                .get())
            .first
            .read<String>('id'),
        'hh-6b11',
      );
      expect(
        (await db
                .customSelect("SELECT id FROM goals WHERE id = 'goal-6b11'")
                .get())
            .first
            .read<String>('id'),
        'goal-6b11',
      );
      expect(
        (await db
                .customSelect(
                  "SELECT amount_minor_units FROM ledger_entries "
                  "WHERE id = 'op-fund-6b11_credit'",
                )
                .get())
            .first
            .read<int>('amount_minor_units'),
        15000,
      );
      expect(
        (await db
                .customSelect(
                  "SELECT id FROM goal_movements WHERE id = 'mov-6b11'",
                )
                .get())
            .first
            .read<String>('id'),
        'mov-6b11',
      );

      for (final name in [
        'validate_funding_source_eligibility',
        'validate_release_destination_eligibility',
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
          reason: '$name must exist after upgrade to 19',
        );
      }

      // Post-migration: certificate-type funding source rejected.
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) VALUES "
        "('cert-type-post', 'hh-6b11', 'CertType', 'certificate', 'household', "
        "'certificate', 'EGP', 0, 0, 1, 0, 50, 'test', "
        "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
      );
      // Seed principal so prevent_negative does not fire before eligibility.
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "idempotency_key, description) VALUES "
        "('op-seed-cert-post', 'hh-6b11', 'income', '2024-01-15', '2024-01-15T00:00:00Z', "
        "5000, 'EGP', 'test', '2024-01-15T00:00:00Z', '2024-01-15T00:00:00Z', "
        "'ik-seed-cert-post', 'seed')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
        "direction, amount_minor_units, currency_code, entry_type, effective_date, "
        "recorded_at, created_by) VALUES "
        "('op-seed-cert-post_c', 'op-seed-cert-post', 'hh-6b11', 'cert-type-post', "
        "'credit', 5000, 'EGP', 'income', '2024-01-15', '2024-01-15T00:00:00Z', 'test')",
      );
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "source_account_id, destination_account_id, idempotency_key, description) VALUES "
        "('op-bad-fund-post', 'hh-6b11', 'transfer', '2024-02-01', '2024-02-01T00:00:00Z', "
        "1000, 'EGP', 'test', '2024-02-01T00:00:00Z', '2024-02-01T00:00:00Z', "
        "'cert-type-post', 'reserve-6b11', 'ik-bad-fund-post', 'bypass')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
        "direction, amount_minor_units, currency_code, entry_type, effective_date, "
        "recorded_at, created_by) VALUES "
        "('op-bad-fund-post_d', 'op-bad-fund-post', 'hh-6b11', 'cert-type-post', "
        "'debit', 1000, 'EGP', 'transferOut', '2024-02-01', '2024-02-01T00:00:00Z', 'test')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
        "direction, amount_minor_units, currency_code, entry_type, effective_date, "
        "recorded_at, created_by) VALUES "
        "('op-bad-fund-post_c', 'op-bad-fund-post', 'hh-6b11', 'reserve-6b11', "
        "'credit', 1000, 'EGP', 'transferIn', '2024-02-01', '2024-02-01T00:00:00Z', 'test')",
      );
      try {
        await db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
          "movement_type, created_at) VALUES "
          "('mov-bad-fund-post', 'goal-6b11', 'hh-6b11', 'op-bad-fund-post', "
          "'funding', '2024-02-01T00:00:00Z')",
        );
        fail('Expected funding eligibility abort after migration');
      } catch (e) {
        expect(e.toString(), contains(kGoalFundingSourceEligibilityAbort));
      }

      // Post-migration: certificate-type release destination rejected.
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "source_account_id, destination_account_id, idempotency_key, description) VALUES "
        "('op-bad-rel-post', 'hh-6b11', 'transfer', '2024-02-01', '2024-02-01T00:00:00Z', "
        "1000, 'EGP', 'test', '2024-02-01T00:00:00Z', '2024-02-01T00:00:00Z', "
        "'reserve-6b11', 'cert-type-post', 'ik-bad-rel-post', 'bypass')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
        "direction, amount_minor_units, currency_code, entry_type, effective_date, "
        "recorded_at, created_by) VALUES "
        "('op-bad-rel-post_d', 'op-bad-rel-post', 'hh-6b11', 'reserve-6b11', "
        "'debit', 1000, 'EGP', 'transferOut', '2024-02-01', '2024-02-01T00:00:00Z', 'test')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
        "direction, amount_minor_units, currency_code, entry_type, effective_date, "
        "recorded_at, created_by) VALUES "
        "('op-bad-rel-post_c', 'op-bad-rel-post', 'hh-6b11', 'cert-type-post', "
        "'credit', 1000, 'EGP', 'transferIn', '2024-02-01', '2024-02-01T00:00:00Z', 'test')",
      );
      try {
        await db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
          "movement_type, created_at, release_reason) VALUES "
          "('mov-bad-rel-post', 'goal-6b11', 'hh-6b11', 'op-bad-rel-post', "
          "'release', '2024-02-01T00:00:00Z', 'bypass')",
        );
        fail('Expected release eligibility abort after migration');
      } catch (e) {
        expect(e.toString(), contains(kGoalReleaseDestinationEligibilityAbort));
      }

      // Post-migration positive: eligible standard release succeeds.
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) VALUES "
        "('dst-post', 'hh-6b11', 'Dest', 'bankAccount', 'user', 'available', "
        "'EGP', 1, 0, 1, 0, 2, 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
      );
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "source_account_id, destination_account_id, idempotency_key, description) VALUES "
        "('op-rel-post', 'hh-6b11', 'transfer', '2024-02-02', '2024-02-02T00:00:00Z', "
        "2000, 'EGP', 'test', '2024-02-02T00:00:00Z', '2024-02-02T00:00:00Z', "
        "'reserve-6b11', 'dst-post', 'ik-rel-post', 'release ok')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
        "direction, amount_minor_units, currency_code, entry_type, effective_date, "
        "recorded_at, created_by) VALUES "
        "('op-rel-post_d', 'op-rel-post', 'hh-6b11', 'reserve-6b11', "
        "'debit', 2000, 'EGP', 'transferOut', '2024-02-02', '2024-02-02T00:00:00Z', 'test')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
        "direction, amount_minor_units, currency_code, entry_type, effective_date, "
        "recorded_at, created_by) VALUES "
        "('op-rel-post_c', 'op-rel-post', 'hh-6b11', 'dst-post', "
        "'credit', 2000, 'EGP', 'transferIn', '2024-02-02', '2024-02-02T00:00:00Z', 'test')",
      );
      await db.customStatement(
        "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
        "movement_type, created_at, release_reason) VALUES "
        "('mov-rel-post', 'goal-6b11', 'hh-6b11', 'op-rel-post', "
        "'release', '2024-02-02T00:00:00Z', 'need cash')",
      );
      expect(
        (await db
                .customSelect(
                  "SELECT id FROM goal_movements WHERE id = 'mov-rel-post'",
                )
                .get())
            .first
            .read<String>('id'),
        'mov-rel-post',
      );
    },
  );
}

void _insertFixtures(String path) {
  final db = sqlite3.sqlite3.open(path);
  db.execute('PRAGMA foreign_keys = ON');
  db.execute(
    "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
    "VALUES ('hh-6b11', 'HH 6B11', 'u1', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
    "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
    "include_in_zakat, display_order, created_by, created_at, updated_at) VALUES "
    "('bank-6b11', 'hh-6b11', 'Bank', 'bankAccount', 'user', 'available', "
    "'EGP', 1, 0, 1, 0, 1, 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
    "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
    "include_in_zakat, display_order, created_by, created_at, updated_at) VALUES "
    "('reserve-6b11', 'hh-6b11', 'Reserve', 'goalReserve', 'household', 'goalReserve', "
    "'EGP', 0, 0, 1, 0, 9999, 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
    "status, idempotency_key, idempotency_payload, created_at) VALUES "
    "('goal-6b11', 'hh-6b11', 'reserve-6b11', 'EGP', 'active', 'ik-goal-6b11', "
    "'payload-6b11', '2024-01-01T00:00:00Z')",
  );
  db.execute(
    "INSERT INTO goal_revisions (id, goal_id, household_id, name, purpose_code, "
    "target_minor_units, currency_code, created_at, revision_reason) VALUES "
    "('rev-6b11', 'goal-6b11', 'hh-6b11', 'Trip', 'vacation', 100000, "
    "'EGP', '2024-01-01T00:00:00Z', 'initial')",
  );
  db.execute(
    "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
    "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
    "destination_account_id, idempotency_key, description) VALUES "
    "('op-open-6b11', 'hh-6b11', 'income', '2024-01-01', '2024-01-01T00:00:00Z', "
    "50000, 'EGP', 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z', "
    "'bank-6b11', 'ik-open-6b11', 'opening')",
  );
  db.execute(
    "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
    "direction, amount_minor_units, currency_code, entry_type, effective_date, "
    "recorded_at, created_by) VALUES "
    "('op-open-6b11_credit', 'op-open-6b11', 'hh-6b11', 'bank-6b11', 'credit', 50000, "
    "'EGP', 'income', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
  );
  db.execute(
    "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
    "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
    "source_account_id, destination_account_id, idempotency_key, description) VALUES "
    "('op-fund-6b11', 'hh-6b11', 'transfer', '2024-01-01', '2024-01-01T00:00:00Z', "
    "15000, 'EGP', 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z', "
    "'bank-6b11', 'reserve-6b11', 'ik-fund-6b11', 'goal funding')",
  );
  db.execute(
    "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
    "direction, amount_minor_units, currency_code, entry_type, effective_date, "
    "recorded_at, created_by) VALUES "
    "('op-fund-6b11_debit', 'op-fund-6b11', 'hh-6b11', 'bank-6b11', 'debit', 15000, "
    "'EGP', 'transferOut', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
  );
  db.execute(
    "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
    "direction, amount_minor_units, currency_code, entry_type, effective_date, "
    "recorded_at, created_by) VALUES "
    "('op-fund-6b11_credit', 'op-fund-6b11', 'hh-6b11', 'reserve-6b11', 'credit', 15000, "
    "'EGP', 'transferIn', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
  );
  db.execute(
    "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
    "movement_type, created_at) VALUES "
    "('mov-6b11', 'goal-6b11', 'hh-6b11', 'op-fund-6b11', 'funding', "
    "'2024-01-01T00:00:00Z')",
  );
  db.close();
}
