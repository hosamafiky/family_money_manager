/// Phase 6A.3 — Migration restart safety clarity (schema 16→18).
///
/// Restart safety for Phase 6A / 6A.2 DDL is **idempotent migration statements**
/// (`CREATE … IF NOT EXISTS`, `DROP TRIGGER IF EXISTS` + recreate). Drift does
/// **not** wrap `onUpgrade` in one SQLite transaction that rolls back all DDL
/// on abort; `user_version` is bumped only after a successful upgrade pass.
///
/// This file proves fail-inject → inspect stuck state → reopen recovers with
/// each schema-17/18 object present exactly once. It does **not** claim
/// transactional rollback of partial DDL.
library;

import 'dart:io';

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../helpers/true_schema_v16.dart';

void main() {
  test('MIG-6A3-1. Fail-inject mid-upgrade: stuck state, reopen completes once', () async {
    final path = await materializeTrueSchemaV16File();
    addTearDown(() async {
      final dir = Directory(p.dirname(path));
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    // Seed financial rows that must survive recovery.
    final seed = sqlite3.sqlite3.open(path);
    seed.execute(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('hh-mig3', 'Mig3', 'u1', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    seed.execute(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) VALUES "
      "('acct-mig3', 'hh-mig3', 'Cash', 'personalCashWallet', 'user', 'available', "
      "'EGP', 1, 0, 1, 0, 1, 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    seed.execute(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
      "destination_account_id, description) VALUES "
      "('op-mig3', 'hh-mig3', 'income', '2024-01-01', '2024-01-01T00:00:00Z', "
      "9000, 'EGP', 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z', "
      "'acct-mig3', 'seed')",
    );
    seed.execute(
      "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
      "direction, amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "('op-mig3_credit', 'op-mig3', 'hh-mig3', 'acct-mig3', 'credit', 9000, "
      "'EGP', 'income', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
    );
    seed.close();

    // --- Injected failure state: partial schema-17 table, user_version stuck ---
    final raw = sqlite3.sqlite3.open(path);
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
    // Intentionally leave certificate_revisions / events / triggers missing,
    // and leave user_version at 16 (simulates crash before version bump).
    raw.execute('PRAGMA user_version = 16');
    raw.close();

    // Assert state immediately after injected failure.
    final stuck = sqlite3.sqlite3.open(path);
    expect(stuck.select('PRAGMA user_version').first['user_version'], 16);
    expect(
      stuck
          .select(
            "SELECT COUNT(*) AS c FROM sqlite_master "
            "WHERE type='table' AND name='savings_certificates'",
          )
          .first['c'],
      1,
    );
    expect(
      stuck
          .select(
            "SELECT COUNT(*) AS c FROM sqlite_master "
            "WHERE type='table' AND name='certificate_events'",
          )
          .first['c'],
      0,
    );
    expect(
      stuck
          .select(
            "SELECT COUNT(*) AS c FROM sqlite_master "
            "WHERE type='trigger' AND name='prevent_negative_account_balance'",
          )
          .first['c'],
      0,
    );
    expect(
      stuck
          .select(
            "SELECT COUNT(*) AS c FROM sqlite_master "
            "WHERE type='trigger' AND name='validate_certificate_purchase_event'",
          )
          .first['c'],
      0,
    );
    // Existing financial rows intact.
    expect(
      stuck
          .select(
            "SELECT amount_minor_units FROM ledger_entries WHERE id='op-mig3_credit'",
          )
          .first['amount_minor_units'],
      9000,
    );
    stuck.close();

    // Reopen with current AppDatabase — idempotent upgrade completes.
    final db = AppDatabase.forFile(path);
    addTearDown(db.close);

    expect(
      (await db.customSelect('PRAGMA user_version').get()).first.read<int>(
        'user_version',
      ),
      // The current version, not a literal: the claim under test is that a
      // reopen finishes the upgrade, which stays true as versions are added.
      db.schemaVersion,
    );

    Future<int> objectCount(String type, String name) async =>
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM sqlite_master "
                  "WHERE type='$type' AND name='$name'",
                )
                .get())
            .first
            .read<int>('c');

    // Every schema-17 object exactly once.
    expect(await objectCount('table', 'savings_certificates'), 1);
    expect(await objectCount('table', 'certificate_revisions'), 1);
    expect(await objectCount('table', 'certificate_events'), 1);
    expect(
      await objectCount('index', 'idx_savings_certificates_idempotency'),
      1,
    );
    expect(
      await objectCount('trigger', 'validate_certificate_purchase_event'),
      1,
    );
    expect(
      await objectCount('trigger', 'validate_certificate_redemption_event'),
      1,
    );
    expect(
      await objectCount('trigger', 'validate_certificate_profit_event'),
      1,
    );

    // Every schema-18 object exactly once.
    expect(await objectCount('trigger', 'prevent_negative_account_balance'), 1);

    // Financial rows still intact after recovery.
    expect(
      (await db
              .customSelect(
                "SELECT amount_minor_units FROM ledger_entries "
                "WHERE id='op-mig3_credit'",
              )
              .get())
          .first
          .read<int>('amount_minor_units'),
      9000,
    );

    // Relevant triggers operate after recovery (overdraft rejected).
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
      "VALUES ('op-over3', 'hh-mig3', 'expense', '2024-01-02', '2024-01-02T00:00:00Z', "
      "50000, 'EGP', 'test', '2024-01-02T00:00:00Z', '2024-01-02T00:00:00Z')",
    );
    await expectLater(
      () => db.customStatement(
        "INSERT INTO ledger_entries "
        "(id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, "
        "recorded_at, created_by) VALUES "
        "('op-over3_debit', 'op-over3', 'hh-mig3', 'acct-mig3', 'debit', 50000, "
        "'EGP', 'expense', '2024-01-02', '2024-01-02T00:00:00Z', 'test')",
      ),
      throwsA(anything),
    );
  });
}
