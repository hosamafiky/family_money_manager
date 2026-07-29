import 'dart:io';

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'historical_table_shape.dart';

/// Builds a physical SQLite file at schema version 12 from historical DDL.
///
/// Tables come from Drift's current CREATE TABLE statements, with columns
/// added after v12 stripped back off by [stripColumnsNewerThan].
/// Triggers/indexes come from
/// `test/fixtures/schema_v12_objects.sql` extracted from commit `3124346`
/// onCreate — v13+ objects are never created then deleted.
Future<String> materializeTrueSchemaV12File() async {
  final dir = await Directory.systemTemp.createTemp('fmm_true_v12_');
  final path = p.join(dir.path, 'v12.db');

  // Harvest CREATE TABLE DDL from a current onCreate database (tables only).
  // Exclude tables introduced after schema v12 so onUpgrade can create them.
  final probe = AppDatabase.forTesting();
  final tableRows = await probe
      .customSelect(
        "SELECT sql FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' AND sql IS NOT NULL "
        "AND name NOT IN ("
        "'savings_certificates',"
        "'certificate_revisions',"
        "'certificate_events'"
        ")",
      )
      .get();
  await probe.close();

  final objectsSql = await File(
    p.join(Directory.current.path, 'test/fixtures/schema_v12_objects.sql'),
  ).readAsString();

  final raw = sqlite3.sqlite3.open(path);
  raw.execute('PRAGMA foreign_keys = OFF');
  for (final row in tableRows) {
    raw.execute(row.read<String>('sql'));
  }
  stripColumnsNewerThan(raw, 12);
  for (final stmt in _splitSqlStatements(objectsSql)) {
    raw.execute(stmt);
  }
  raw.execute('PRAGMA user_version = 12');
  raw.execute('PRAGMA foreign_keys = ON');
  raw.close();

  // Sanity: v13-only objects must be absent.
  final check = sqlite3.sqlite3.open(path);
  final v13 = check.select(
    "SELECT COUNT(*) AS c FROM sqlite_master "
    "WHERE name IN ("
    "'validate_reversal_movement_link',"
    "'idx_goal_movements_one_reversal_per_original',"
    "'goal_lifecycle_household_matches_goal',"
    "'idx_goal_lifecycle_hh_idem',"
    "'validate_goal_transfer_balanced_legs'"
    ")",
  );
  expect(v13.first['c'], 0);
  final ver = check.select('PRAGMA user_version');
  expect(ver.first['user_version'], 12);
  check.close();

  return path;
}

/// Opens [path] with the current [AppDatabase] so onUpgrade runs.
AppDatabase openCurrentSchemaOnFile(String path) => AppDatabase.forFile(path);

List<String> _splitSqlStatements(String sql) {
  // Statements in schema_v12_objects.sql are separated by blank lines.
  // Do not split on ';' inside CREATE TRIGGER ... BEGIN ... END bodies.
  final out = <String>[];
  final chunks = sql.split(RegExp(r'\n\s*\n'));
  for (final chunk in chunks) {
    final lines = chunk
        .split('\n')
        .where((l) => !l.trim().startsWith('--'))
        .join('\n')
        .trim();
    if (lines.isEmpty) continue;
    out.add(lines.endsWith(';') ? lines.substring(0, lines.length - 1) : lines);
  }
  return out;
}
