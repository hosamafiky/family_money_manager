/// Append-only database constraint tests (Phase 2A §4).
///
/// Verifies that the triggers created in [AppDatabase.onCreate] prevent
/// UPDATE and DELETE on every append-only financial table.
///
/// These tests bypass the Dart repository layer and issue raw SQL to prove
/// that database-level constraints catch violations independently of the
/// application code.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async => db.close());

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> insertHousehold() async {
    await db.customStatement(
      'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
      "VALUES ('hh-1', 'Test', 'user-1', '2024-01-01', '2024-01-01')",
    );
  }

  Future<void> insertAccount(String id) async {
    await db.customStatement(
      'INSERT INTO financial_accounts '
      '(id, household_id, name, type, owner_type, fund_purpose, currency_code, '
      ' created_at, updated_at, created_by) '
      "VALUES ('$id', 'hh-1', 'Account $id', 'personalCashWallet', 'user', "
      "        'available', 'EGP', '2024-01-01', '2024-01-01', 'user-1')",
    );
  }

  Future<void> insertOperation(String id) async {
    await db.customStatement(
      'INSERT INTO operations '
      '(id, household_id, type, effective_date, recorded_at, total_amount_minor_units, '
      ' currency_code, created_by, created_at, updated_at) '
      "VALUES ('$id', 'hh-1', 'income', '2024-01-01', '2024-01-01T00:00:00Z', 10000, "
      "        'EGP', 'user-1', '2024-01-01', '2024-01-01')",
    );
  }

  Future<void> insertLedgerEntry(
    String id,
    String operationId,
    String accountId,
  ) async {
    await db.customStatement(
      'INSERT INTO ledger_entries '
      '(id, operation_id, household_id, account_id, direction, amount_minor_units, '
      ' currency_code, entry_type, effective_date, recorded_at, created_by) '
      "VALUES ('$id', '$operationId', 'hh-1', '$accountId', 'credit', 10000, "
      "        'EGP', 'income', '2024-01-01', '2024-01-01T00:00:00Z', 'user-1')",
    );
  }

  Future<void> insertChildAudit(
    String id,
    String operationId,
    String accountId,
  ) async {
    await db.customStatement(
      'INSERT INTO child_withdrawal_audits '
      '(id, operation_id, household_id, account_id, amount_minor_units, reason, '
      ' beneficiary, confirmed_at, confirmed_by, created_at) '
      "VALUES ('$id', '$operationId', 'hh-1', '$accountId', 5000, 'School', "
      "        'child', '2024-01-01T00:00:00Z', 'user-1', '2024-01-01')",
    );
  }

  // ── Ledger entries: immutable ─────────────────────────────────────────────

  group('ledger_entries – immutable (trigger: no_update_ledger_entries)', () {
    test('UPDATE on ledger_entries raises SqliteException', () async {
      await insertHousehold();
      await insertAccount('acc-1');
      await insertOperation('op-1');
      await insertLedgerEntry('entry-1', 'op-1', 'acc-1');

      expect(
        () => db.customStatement(
          "UPDATE ledger_entries SET amount_minor_units = 1 WHERE id = 'entry-1'",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('DELETE from ledger_entries raises SqliteException', () async {
      await insertHousehold();
      await insertAccount('acc-1');
      await insertOperation('op-1');
      await insertLedgerEntry('entry-1', 'op-1', 'acc-1');

      expect(
        () => db.customStatement(
          "DELETE FROM ledger_entries WHERE id = 'entry-1'",
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  // ── Child withdrawal audits: immutable ───────────────────────────────────

  group('child_withdrawal_audits – immutable (trigger: no_update_child_audits)', () {
    test('UPDATE on child_withdrawal_audits raises SqliteException', () async {
      await insertHousehold();
      await insertAccount('acc-p');

      // Insert the operation directly with the withdrawal type (no UPDATE needed).
      await db.customStatement(
        'INSERT INTO operations '
        '(id, household_id, type, effective_date, recorded_at, total_amount_minor_units, '
        ' currency_code, created_by, created_at, updated_at) '
        "VALUES ('op-cfw', 'hh-1', 'child_fund_withdrawal', '2024-01-01', '2024-01-01T00:00:00Z', "
        "        5000, 'EGP', 'user-1', '2024-01-01', '2024-01-01')",
      );
      await insertChildAudit('audit-1', 'op-cfw', 'acc-p');

      expect(
        () => db.customStatement(
          "UPDATE child_withdrawal_audits SET reason = 'changed' WHERE id = 'audit-1'",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test(
      'DELETE from child_withdrawal_audits raises SqliteException',
      () async {
        await insertHousehold();
        await insertAccount('acc-p');
        await insertOperation('op-cfw2');
        await insertChildAudit('audit-2', 'op-cfw2', 'acc-p');

        expect(
          () => db.customStatement(
            "DELETE FROM child_withdrawal_audits WHERE id = 'audit-2'",
          ),
          throwsA(isA<SqliteException>()),
        );
      },
    );
  });

  // ── Operations: restricted update ────────────────────────────────────────

  group('operations – restricted update (trigger: restrict_operations_update)', () {
    test('UPDATE of type raises SqliteException', () async {
      await insertHousehold();
      await insertOperation('op-r1');

      expect(
        () => db.customStatement(
          "UPDATE operations SET type = 'expense' WHERE id = 'op-r1'",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('UPDATE of household_id raises SqliteException', () async {
      await insertHousehold();
      await insertOperation('op-r2');

      expect(
        () => db.customStatement(
          "UPDATE operations SET household_id = 'other' WHERE id = 'op-r2'",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('UPDATE of total_amount_minor_units raises SqliteException', () async {
      await insertHousehold();
      await insertOperation('op-r3');

      expect(
        () => db.customStatement(
          'UPDATE operations SET total_amount_minor_units = 1 WHERE id = \'op-r3\'',
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('UPDATE of is_reversed and reversed_by is allowed', () async {
      await insertHousehold();
      await insertOperation('op-r4');

      // This should NOT throw — marking as reversed is the only permitted update.
      await db.customStatement(
        "UPDATE operations "
        "SET is_reversed = 1, reversed_by = 'op-rev', updated_at = '2024-06-01' "
        "WHERE id = 'op-r4'",
      );

      final row = await db
          .customSelect("SELECT is_reversed FROM operations WHERE id = 'op-r4'")
          .getSingleOrNull();
      expect(row?.read<int>('is_reversed'), 1);
    });

    test('DELETE from operations raises SqliteException', () async {
      await insertHousehold();
      await insertOperation('op-r5');

      expect(
        () => db.customStatement("DELETE FROM operations WHERE id = 'op-r5'"),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  // ── CHECK enforcement: amount_minor_units > 0 ────────────────────────────

  group('CHECK triggers – amount_minor_units > 0', () {
    test('inserting ledger_entry with amount=0 raises SqliteException', () async {
      await insertHousehold();
      await insertAccount('acc-chk');
      await insertOperation('op-chk');

      expect(
        () => db.customStatement(
          'INSERT INTO ledger_entries '
          '(id, operation_id, household_id, account_id, direction, amount_minor_units, '
          ' currency_code, entry_type, effective_date, recorded_at, created_by) '
          "VALUES ('e-bad', 'op-chk', 'hh-1', 'acc-chk', 'credit', 0, "
          "        'EGP', 'income', '2024-01-01', '2024-01-01', 'user-1')",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('inserting ledger_entry with amount=-1 raises SqliteException', () async {
      await insertHousehold();
      await insertAccount('acc-neg');
      await insertOperation('op-neg');

      expect(
        () => db.customStatement(
          'INSERT INTO ledger_entries '
          '(id, operation_id, household_id, account_id, direction, amount_minor_units, '
          ' currency_code, entry_type, effective_date, recorded_at, created_by) '
          "VALUES ('e-neg', 'op-neg', 'hh-1', 'acc-neg', 'credit', -500, "
          "        'EGP', 'income', '2024-01-01', '2024-01-01', 'user-1')",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('inserting audit with amount=0 raises SqliteException', () async {
      await insertHousehold();
      await insertAccount('acc-a0');
      await insertOperation('op-a0');

      expect(
        () => db.customStatement(
          'INSERT INTO child_withdrawal_audits '
          '(id, operation_id, household_id, account_id, amount_minor_units, reason, '
          ' beneficiary, confirmed_at, confirmed_by, created_at) '
          "VALUES ('aud-bad', 'op-a0', 'hh-1', 'acc-a0', 0, 'reason', "
          "        'child', '2024-01-01', 'user-1', '2024-01-01')",
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  // ── CHECK enforcement: warning_shown and reason ───────────────────────────

  group('CHECK triggers – audit fields', () {
    test('inserting audit with warning_shown=0 raises SqliteException', () async {
      await insertHousehold();
      await insertAccount('acc-ws');
      await insertOperation('op-ws');

      expect(
        () => db.customStatement(
          'INSERT INTO child_withdrawal_audits '
          '(id, operation_id, household_id, account_id, amount_minor_units, reason, '
          ' beneficiary, confirmed_at, confirmed_by, warning_shown, created_at) '
          "VALUES ('aud-ws', 'op-ws', 'hh-1', 'acc-ws', 100, 'reason', "
          "        'child', '2024-01-01', 'user-1', 0, '2024-01-01')",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('inserting audit with empty reason raises SqliteException', () async {
      await insertHousehold();
      await insertAccount('acc-er');
      await insertOperation('op-er');

      expect(
        () => db.customStatement(
          'INSERT INTO child_withdrawal_audits '
          '(id, operation_id, household_id, account_id, amount_minor_units, reason, '
          ' beneficiary, confirmed_at, confirmed_by, created_at) '
          "VALUES ('aud-er', 'op-er', 'hh-1', 'acc-er', 100, '  ', "
          "        'child', '2024-01-01', 'user-1', '2024-01-01')",
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  // ── FK trigger: ledger_entries.operation_id ───────────────────────────────

  group('FK trigger – ledger_entries.operation_id must reference operations', () {
    test(
      'inserting entry with non-existent operation_id raises SqliteException',
      () async {
        await insertHousehold();
        await insertAccount('acc-fk');

        expect(
          () => db.customStatement(
            'INSERT INTO ledger_entries '
            '(id, operation_id, household_id, account_id, direction, amount_minor_units, '
            ' currency_code, entry_type, effective_date, recorded_at, created_by) '
            "VALUES ('e-fk', 'GHOST_OP', 'hh-1', 'acc-fk', 'credit', 100, "
            "        'EGP', 'income', '2024-01-01', '2024-01-01', 'user-1')",
          ),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test(
      'inserting entry with operation in different household raises SqliteException',
      () async {
        await insertHousehold();
        await db.customStatement(
          'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
          "VALUES ('hh-2', 'Other', 'user-1', '2024-01-01', '2024-01-01')",
        );
        await insertOperation('op-hh1'); // belongs to hh-1
        await db.customStatement(
          "INSERT INTO financial_accounts "
          "(id, household_id, name, type, owner_type, fund_purpose, currency_code, "
          " created_at, updated_at, created_by) "
          "VALUES ('acc-hh2', 'hh-2', 'Acc', 'wallet', 'user', 'general', 'EGP', "
          "        '2024-01-01', '2024-01-01', 'user-1')",
        );

        // Entry claims to belong to hh-2 but operation is in hh-1
        expect(
          () => db.customStatement(
            'INSERT INTO ledger_entries '
            '(id, operation_id, household_id, account_id, direction, amount_minor_units, '
            ' currency_code, entry_type, effective_date, recorded_at, created_by) '
            "VALUES ('e-cross', 'op-hh1', 'hh-2', 'acc-hh2', 'credit', 100, "
            "        'EGP', 'income', '2024-01-01', '2024-01-01', 'user-1')",
          ),
          throwsA(isA<SqliteException>()),
        );
      },
    );
  });

  // ── FK trigger: child_withdrawal_audits.operation_id ─────────────────────

  group('FK trigger – child_withdrawal_audits cross-profile rejection', () {
    test(
      'audit in different household than operation raises SqliteException',
      () async {
        await insertHousehold();
        await db.customStatement(
          'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
          "VALUES ('hh-3', 'Third', 'user-1', '2024-01-01', '2024-01-01')",
        );
        await insertOperation('op-cross');
        await insertAccount('acc-cross');

        expect(
          () => db.customStatement(
            'INSERT INTO child_withdrawal_audits '
            '(id, operation_id, household_id, account_id, amount_minor_units, reason, '
            ' beneficiary, confirmed_at, confirmed_by, created_at) '
            "VALUES ('aud-cross', 'op-cross', 'hh-3', 'acc-cross', 100, 'reason', "
            "        'child', '2024-01-01', 'user-1', '2024-01-01')",
          ),
          throwsA(isA<SqliteException>()),
        );
      },
    );
  });

  // ── UNIQUE: one audit per operation ──────────────────────────────────────

  group('UNIQUE constraint – one child_withdrawal_audit per operation', () {
    test('second audit for same operation raises SqliteException', () async {
      await insertHousehold();
      await insertAccount('acc-uniq');
      await insertOperation('op-uniq');
      await insertChildAudit('aud-uniq-1', 'op-uniq', 'acc-uniq');

      expect(
        () => db.customStatement(
          'INSERT INTO child_withdrawal_audits '
          '(id, operation_id, household_id, account_id, amount_minor_units, reason, '
          ' beneficiary, confirmed_at, confirmed_by, created_at) '
          "VALUES ('aud-uniq-2', 'op-uniq', 'hh-1', 'acc-uniq', 100, 'second', "
          "        'child', '2024-01-01', 'user-1', '2024-01-01')",
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
