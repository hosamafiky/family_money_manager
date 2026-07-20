import 'dart:io';

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Builds a physical SQLite file at schema version 16 from historical DDL.
///
/// Tables come from Drift's current CREATE TABLE statements (excluding
/// Phase 6A certificate tables). Triggers/indexes come from
/// `test/fixtures/schema_v16_objects.sql` extracted from commit `86736ca`
/// onCreate — certificate objects are never created then deleted.
Future<String> materializeTrueSchemaV16File() async {
  final dir = await Directory.systemTemp.createTemp('fmm_true_v16_');
  final path = p.join(dir.path, 'v16.db');

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
    p.join(Directory.current.path, 'test/fixtures/schema_v16_objects.sql'),
  ).readAsString();

  final raw = sqlite3.sqlite3.open(path);
  raw.execute('PRAGMA foreign_keys = OFF');
  for (final row in tableRows) {
    raw.execute(row.read<String>('sql'));
  }
  for (final stmt in _splitSqlStatements(objectsSql)) {
    raw.execute(stmt);
  }
  raw.execute('PRAGMA user_version = 16');
  raw.execute('PRAGMA foreign_keys = ON');
  raw.close();

  final check = sqlite3.sqlite3.open(path);
  final cert = check.select(
    "SELECT COUNT(*) AS c FROM sqlite_master "
    "WHERE name IN ("
    "'savings_certificates',"
    "'certificate_revisions',"
    "'certificate_events',"
    "'validate_certificate_purchase_event',"
    "'prevent_negative_account_balance'"
    ")",
  );
  expect(cert.first['c'], 0);
  expect(check.select('PRAGMA user_version').first['user_version'], 16);
  expect(
    check
        .select(
          "SELECT COUNT(*) AS c FROM sqlite_master "
          "WHERE name = 'check_goal_lifecycle_status'",
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
