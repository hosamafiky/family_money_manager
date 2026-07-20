/// Builds a physical SQLite file at schema version 18 (pre–Phase 6B.1.1).
///
/// **Provenance**
/// - Historical schema-18 tip commit:
///   `47fd59676d5a9a06ac6d4ea6f9b6ae3c256e4729`
///   (`docs: set Phase 6B.1 report Final HEAD to tip`, last
///   `schemaVersion => 18` before Phase 6B.1.1).
/// - Fixture: `test/fixtures/schema_v18_objects.sql` — triggers/indexes
///   dumped from `AppDatabase.forTesting()` onCreate at that commit
///   (100 objects; eligibility triggers absent).
/// - Tables: Drift CREATE TABLE DDL from the *current* probe (table shapes
///   were unchanged 18→19; only eligibility triggers were added).
///
/// This is **not** “open schema 19 then delete triggers”. The two Phase
/// 6B.1.1 eligibility triggers are never created on the materialized file;
/// `user_version` is set to 18 so [AppDatabase.forFile] runs the authentic
/// 18→19 upgrade path.
library;

import 'dart:io';

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Materializes a true schema-18 database file without 6B.1.1 triggers.
Future<String> materializeTrueSchemaV18File() async {
  final dir = await Directory.systemTemp.createTemp('fmm_true_v18_');
  final path = p.join(dir.path, 'v18.db');

  final probe = AppDatabase.forTesting();
  final tableRows = await probe
      .customSelect(
        "SELECT sql FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' AND sql IS NOT NULL",
      )
      .get();
  await probe.close();

  final objectsSql = await File(
    p.join(Directory.current.path, 'test/fixtures/schema_v18_objects.sql'),
  ).readAsString();

  final raw = sqlite3.sqlite3.open(path);
  raw.execute('PRAGMA foreign_keys = OFF');
  for (final row in tableRows) {
    raw.execute(row.read<String>('sql'));
  }
  for (final stmt in _splitSqlStatements(objectsSql)) {
    raw.execute(stmt);
  }
  raw.execute('PRAGMA user_version = 18');
  raw.execute('PRAGMA foreign_keys = ON');
  raw.close();

  final check = sqlite3.sqlite3.open(path);
  expect(check.select('PRAGMA user_version').first['user_version'], 18);
  for (final name in [
    'validate_funding_source_eligibility',
    'validate_release_destination_eligibility',
  ]) {
    expect(
      check
          .select(
            "SELECT COUNT(*) AS c FROM sqlite_master WHERE name = '$name'",
          )
          .first['c'],
      0,
      reason: '$name must not exist on authentic v18',
    );
  }
  expect(
    check
        .select(
          "SELECT COUNT(*) AS c FROM sqlite_master "
          "WHERE name = 'prevent_negative_account_balance'",
        )
        .first['c'],
    1,
  );
  check.close();

  return path;
}

/// Opens [path] with the current [AppDatabase] so onUpgrade runs.
AppDatabase openCurrentSchemaOnFile(String path) => AppDatabase.forFile(path);

List<String> _splitSqlStatements(String sql) {
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
