/// Phase 6A – True physical schema-16 → 17 migration with data survival.
///
/// Builds a schema-16 file by opening current onCreate then stripping Phase 6A
/// tables/triggers/indexes and setting `user_version = 16`. Populates
/// pre-6A rows, then reopening with [AppDatabase] proves `onUpgrade` runs.
library;

import 'dart:io';

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test('MIG-6A-1. True physical v16→v17 creates certificate tables', () async {
    final dir = await Directory.systemTemp.createTemp('fmm_true_v16_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final path = p.join(dir.path, 'v16.db');

    // Fresh current schema (v17).
    final seed = AppDatabase.forFile(path);
    await seed.customSelect('SELECT 1').get();
    await seed.close();

    final raw = sqlite3.sqlite3.open(path);
    raw.execute('PRAGMA foreign_keys = OFF');
    for (final name in [
      'validate_certificate_purchase_event',
      'validate_certificate_redemption_event',
      'validate_certificate_profit_event',
      'validate_certificate_account_on_insert',
      'no_retype_certificate_account',
      'no_modify_certificate_spendable',
      'no_modify_certificate_protected',
      'no_modify_certificate_owner_type',
      'no_update_certificate_revisions',
      'no_delete_certificate_revisions',
      'no_update_certificate_events',
      'no_delete_certificate_events',
      'no_update_certificate_immutable',
      'check_certificate_lifecycle_insert',
      'check_certificate_lifecycle_update',
      'certificate_lifecycle_valid_transition',
      'no_delete_certificate_with_history',
      'certificate_event_household_match',
      'certificate_revision_household_match',
    ]) {
      raw.execute('DROP TRIGGER IF EXISTS $name');
    }
    for (final name in [
      'idx_savings_certificates_account',
      'idx_savings_certificates_idempotency',
      'idx_savings_certificates_household',
      'idx_certificate_revisions_certificate',
      'idx_certificate_events_certificate',
      'idx_certificate_events_related_op',
      'idx_certificate_events_idempotency',
    ]) {
      raw.execute('DROP INDEX IF EXISTS $name');
    }
    raw.execute('DROP TABLE IF EXISTS certificate_events');
    raw.execute('DROP TABLE IF EXISTS certificate_revisions');
    raw.execute('DROP TABLE IF EXISTS savings_certificates');
    raw.execute('PRAGMA user_version = 16');
    raw.execute('PRAGMA foreign_keys = ON');
    raw.close();

    // Populate representative pre-6A data while still on schema 16.
    final pre = sqlite3.sqlite3.open(path);
    expect(pre.select('PRAGMA user_version').first['user_version'], 16);
    pre.execute(
      "INSERT OR IGNORE INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('hh-mig', 'Migrate HH', 'u1', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    pre.execute(
      "INSERT OR IGNORE INTO financial_accounts "
      "(id, household_id, name, type, owner_type, fund_purpose, currency_code, "
      "is_spendable, is_protected, include_in_net_worth, include_in_zakat, "
      "is_archived, display_order, created_by, created_at, updated_at) "
      "VALUES ('acc-mig', 'hh-mig', 'Cash', 'personalCashWallet', 'user', 'available', "
      "'EGP', 1, 0, 1, 0, 0, 0, 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    expect(
      pre
          .select(
            "SELECT COUNT(*) AS c FROM sqlite_master "
            "WHERE type='table' AND name='savings_certificates'",
          )
          .first['c'],
      0,
    );
    final hhCountBefore =
        pre
                .select(
                  "SELECT COUNT(*) AS c FROM households WHERE id='hh-mig'",
                )
                .first['c']
            as int;
    final accCountBefore =
        pre
                .select(
                  "SELECT COUNT(*) AS c FROM financial_accounts WHERE id='acc-mig'",
                )
                .first['c']
            as int;
    pre.close();

    final db = AppDatabase.forFile(path);
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').get();
    expect(version.first.read<int>('user_version'), 17);

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
      );
    }
    expect(
      (await db
              .customSelect(
                "SELECT COUNT(*) as c FROM sqlite_master "
                "WHERE type='trigger' AND name='validate_certificate_account_on_insert'",
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
                "WHERE type='trigger' AND name='validate_certificate_purchase_event'",
              )
              .get())
          .first
          .read<int>('c'),
      1,
    );

    // Pre-6A rows survive upgrade (onUpgrade, not onCreate evidence).
    expect(
      (await db
              .customSelect(
                "SELECT COUNT(*) as c FROM households WHERE id='hh-mig'",
              )
              .get())
          .first
          .read<int>('c'),
      hhCountBefore,
    );
    expect(
      (await db
              .customSelect(
                "SELECT COUNT(*) as c FROM financial_accounts WHERE id='acc-mig'",
              )
              .get())
          .first
          .read<int>('c'),
      accCountBefore,
    );
  });
}
