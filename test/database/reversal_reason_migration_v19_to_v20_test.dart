/// Authentic v19 → v20 migration: a reason column on the reversal row.
///
/// Flow:
/// 1. Build a physical v19 database (schema 19 objects, `user_version = 19`)
/// 2. Insert a household, an operation and an existing reversal via raw sqlite3
/// 3. Assert pre-migration: version 19, no `reversal_reason` column
/// 4. Open the current [AppDatabase] so the real `onUpgrade` runs
/// 5. Assert the rows survived untouched, the column exists and reads NULL,
///    and the append-only guard now covers it
library;

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Columns a v19 `operations` row had — the v20 column is deliberately absent.
const _v19Operations = '''
CREATE TABLE operations (
  id TEXT NOT NULL PRIMARY KEY,
  household_id TEXT NOT NULL,
  type TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  recorded_at TEXT NOT NULL,
  description TEXT,
  total_amount_minor_units INTEGER NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'EGP',
  is_reversed INTEGER NOT NULL DEFAULT 0,
  reversed_by TEXT,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''';

Future<String> _materialiseV19() async {
  final dir = await Directory.systemTemp.createTemp('fmm_v19_');
  final path = p.join(dir.path, 'app.sqlite');
  final db = sqlite3.sqlite3.open(path);

  db
    ..execute(_v19Operations)
    ..execute('''
      CREATE TABLE households (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        owner_user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''')
    // The guard as it stood at v19: it does not mention reversal_reason,
    // because the column did not exist.
    ..execute(
      'CREATE TRIGGER restrict_operations_update '
      'BEFORE UPDATE ON operations '
      'WHEN NEW.id != OLD.id OR NEW.household_id != OLD.household_id '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Operations are append-only'); "
      'END',
    )
    ..execute('PRAGMA user_version = 19')
    ..close();

  return path;
}

void _seed(String path) {
  final db = sqlite3.sqlite3.open(path);
  db
    ..execute(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('hh-1', 'Household', 'u1', '2024-01-01', '2024-01-01')",
    )
    // The original entry, and the reversal that already cancelled it. Both
    // predate the column, so neither has a reason to migrate.
    ..execute(
      "INSERT INTO operations (id, household_id, type, effective_date, "
      "recorded_at, total_amount_minor_units, currency_code, is_reversed, "
      "reversed_by, created_by, created_at, updated_at) VALUES "
      "('op-original', 'hh-1', 'expense', '2026-07-09', '2026-07-09T10:00:00Z', "
      "127500, 'EGP', 1, 'op-reversal', 'u1', '2026-07-09', '2026-07-12')",
    )
    ..execute(
      "INSERT INTO operations (id, household_id, type, effective_date, "
      "recorded_at, total_amount_minor_units, currency_code, is_reversed, "
      "reversed_by, created_by, created_at, updated_at) VALUES "
      "('op-reversal', 'hh-1', 'reversal', '2026-07-12', '2026-07-12T09:00:00Z', "
      "127500, 'EGP', 0, NULL, 'u1', '2026-07-12', '2026-07-12')",
    )
    ..close();
}

List<String> _columnsOf(String path, String table) {
  final db = sqlite3.sqlite3.open(path);
  final rows = db.select('PRAGMA table_info($table)');
  final names = [for (final r in rows) r['name'] as String];
  db.close();
  return names;
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('MIG-20. v19 → v20 adds reversal_reason and preserves every row', () async {
    final path = await _materialiseV19();
    addTearDown(() async {
      final dir = Directory(p.dirname(path));
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    _seed(path);

    // ── Pre-migration ─────────────────────────────────────────────────────
    final before = sqlite3.sqlite3.open(path);
    expect(before.select('PRAGMA user_version').first['user_version'], 19);
    before.close();
    expect(_columnsOf(path, 'operations'), isNot(contains('reversal_reason')));

    // ── The real migration ────────────────────────────────────────────────
    final db = AppDatabase.forFile(path);
    await db.customSelect('SELECT 1').get();
    await db.close();

    // ── Post-migration ────────────────────────────────────────────────────
    final after = sqlite3.sqlite3.open(path);
    addTearDown(after.close);

    expect(after.select('PRAGMA user_version').first['user_version'], 20);
    expect(_columnsOf(path, 'operations'), contains('reversal_reason'));

    // Nothing was rewritten: both rows survive with their identities and
    // their reversal lineage intact.
    final ops = after.select('SELECT * FROM operations ORDER BY id');
    expect(ops.length, 2);

    final original = ops.firstWhere((r) => r['id'] == 'op-original');
    expect(original['is_reversed'], 1);
    expect(original['reversed_by'], 'op-reversal');
    expect(original['total_amount_minor_units'], 127500);

    final reversal = ops.firstWhere((r) => r['id'] == 'op-reversal');
    expect(reversal['type'], 'reversal');
    // History recorded without a reason keeps NULL. There is no reason to
    // invent for an entry that was made before the field existed.
    expect(reversal['reversal_reason'], isNull);
  });

  test('MIG-20. a recorded reason cannot be edited afterwards', () async {
    final path = await _materialiseV19();
    addTearDown(() async {
      final dir = Directory(p.dirname(path));
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    _seed(path);

    final db = AppDatabase.forFile(path);
    await db.customSelect('SELECT 1').get();
    await db.close();

    final after = sqlite3.sqlite3.open(path);
    addTearDown(after.close);

    // A reason that could be rewritten after the fact would make the audit
    // trail a draft, so the append-only guard was rebuilt to cover it.
    expect(
      () => after.execute(
        "UPDATE operations SET reversal_reason = 'rewritten' "
        "WHERE id = 'op-reversal'",
      ),
      throwsA(isA<sqlite3.SqliteException>()),
    );

    // The columns that were always mutable still are.
    after.execute(
      "UPDATE operations SET is_reversed = 1, updated_at = '2026-07-20' "
      "WHERE id = 'op-reversal'",
    );
    expect(after.select("SELECT is_reversed FROM operations WHERE id = 'op-reversal'").first['is_reversed'], 1);
  });
}
