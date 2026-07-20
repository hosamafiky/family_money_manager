/// Phase 6B.1.1 – Authentic physical schema-18 → 19 migration.
///
/// Starts from a true v18 file (no 6B.1.1 eligibility triggers), inserts
/// stable fixture IDs, opens current [AppDatabase], and asserts data
/// preservation plus installation of the new triggers.
library;

import 'dart:io';

import 'package:family_money_manager/core/database/app_database.dart';
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
      before.close();

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
