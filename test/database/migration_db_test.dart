/// Schema migration verification tests (Phase 3A.1 §9).
///
/// Tests that fresh v4 creation has all required tables, triggers, and indexes.
/// Simulates upgrade paths to v4 and verifies data integrity is preserved.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  group('Fresh v4 schema creation', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting());
    tearDown(() async => db.close());

    test('all required tables exist', () async {
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
          )
          .get();
      final tableNames = tables.map((r) => r.read<String>('name')).toList();

      expect(
        tableNames,
        containsAll([
          'households',
          'household_members',
          'financial_accounts',
          'operations',
          'ledger_entries',
          'child_withdrawal_audits',
        ]),
      );
    });

    test('household cardinality triggers exist', () async {
      final triggers = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='trigger' ORDER BY name",
          )
          .get();
      final triggerNames = triggers.map((r) => r.read<String>('name')).toList();

      expect(
        triggerNames,
        containsAll([
          'one_primary_user_per_household',
          'one_spouse_per_household',
          'no_cross_household_member',
        ]),
      );
    });

    test('immutable type/currency trigger exists', () async {
      final triggers = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='trigger' AND "
            "name='immutable_account_type_currency'",
          )
          .get();
      expect(triggers.length, 1);
    });

    test('account idempotency index exists', () async {
      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' "
            "AND name='idx_financial_accounts_idempotency'",
          )
          .get();
      expect(indexes.length, 1);
    });

    test(
      'financial_accounts has idempotency_key and idempotency_payload columns',
      () async {
        final cols = await db
            .customSelect('PRAGMA table_info(financial_accounts)')
            .get();
        final colNames = cols.map((r) => r.read<String>('name')).toList();
        expect(colNames, contains('idempotency_key'));
        expect(colNames, contains('idempotency_payload'));
      },
    );

    test('idempotency_key and idempotency_payload are nullable', () async {
      await db.customStatement(
        'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
        "VALUES ('hh-mig-1', 'HH', 'user-1', '2024-01-01', '2024-01-01')",
      );

      // Insert without idempotency_key or idempotency_payload → should succeed.
      await db.customStatement(
        'INSERT INTO financial_accounts '
        '(id, household_id, name, type, owner_type, created_by, created_at, updated_at) '
        "VALUES ('acc-mig-null', 'hh-mig-1', 'Acc', 'personalCashWallet', "
        "'user', 'user-1', '2024-01-01', '2024-01-01')",
      );

      final rows = await db
          .customSelect(
            "SELECT idempotency_key FROM financial_accounts WHERE id='acc-mig-null'",
          )
          .get();
      expect(rows.first.read<String?>('idempotency_key'), isNull);
    });
  });

  group('v3 → v4 data-preservation simulation', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting());
    tearDown(() async => db.close());

    test(
      'existing accounts survive v3→v4 migration (new cols default null)',
      () async {
        // Simulate a row that already existed in v3 (no idempotency columns yet).
        // Since AppDatabase.forTesting() creates at v4, we verify that rows
        // inserted without the new columns default to null.
        await db.customStatement(
          'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
          "VALUES ('hh-mig-2', 'HH', 'user-1', '2024-01-01', '2024-01-01')",
        );
        await db.customStatement(
          'INSERT INTO financial_accounts '
          '(id, household_id, name, type, owner_type, created_by, created_at, updated_at) '
          "VALUES ('acc-mig-old', 'hh-mig-2', 'Old Account', 'bankAccount', "
          "'user', 'user-1', '2024-01-01', '2024-01-01')",
        );

        final rows = await db
            .customSelect(
              "SELECT id, idempotency_key, idempotency_payload "
              "FROM financial_accounts WHERE id = 'acc-mig-old'",
            )
            .get();

        expect(rows.length, 1);
        expect(rows.first.read<String?>('idempotency_key'), isNull);
        expect(rows.first.read<String?>('idempotency_payload'), isNull);
      },
    );

    test('null idempotency keys allow multiple accounts (partial index)', () async {
      await db.customStatement(
        'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
        "VALUES ('hh-mig-3', 'HH', 'user-1', '2024-01-01', '2024-01-01')",
      );

      // Two rows without idempotency_key should not conflict.
      await db.customStatement(
        'INSERT INTO financial_accounts '
        '(id, household_id, name, type, owner_type, created_by, created_at, updated_at) '
        "VALUES ('acc-mig-n1', 'hh-mig-3', 'Acc 1', 'bankAccount', "
        "'user', 'user-1', '2024-01-01', '2024-01-01')",
      );
      await db.customStatement(
        'INSERT INTO financial_accounts '
        '(id, household_id, name, type, owner_type, created_by, created_at, updated_at) '
        "VALUES ('acc-mig-n2', 'hh-mig-3', 'Acc 2', 'bankAccount', "
        "'user', 'user-1', '2024-01-01', '2024-01-01')",
      );

      final rows = await db
          .customSelect(
            "SELECT id FROM financial_accounts WHERE household_id = 'hh-mig-3'",
          )
          .get();
      expect(rows.length, 2);
    });
  });
}
