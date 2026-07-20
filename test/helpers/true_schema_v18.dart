/// Builds a physical SQLite file at schema version 18 (pre–Phase 6B.1.1).
///
/// Tables and existing objects come from a current [AppDatabase.forTesting]
/// probe. Phase 6B.1.1 eligibility triggers are deliberately omitted and
/// `user_version` is set to 18 so [AppDatabase.forFile] runs the authentic
/// 18→19 upgrade path.
library;

import 'dart:io';

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

const _phase6b11Triggers = {
  'validate_funding_source_eligibility',
  'validate_release_destination_eligibility',
};

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
  final objectRows = await probe
      .customSelect(
        "SELECT type, name, sql FROM sqlite_master "
        "WHERE type IN ('trigger', 'index') "
        "AND name NOT LIKE 'sqlite_%' AND sql IS NOT NULL",
      )
      .get();
  await probe.close();

  final raw = sqlite3.sqlite3.open(path);
  raw.execute('PRAGMA foreign_keys = OFF');
  for (final row in tableRows) {
    raw.execute(row.read<String>('sql'));
  }
  for (final row in objectRows) {
    final name = row.read<String>('name');
    if (_phase6b11Triggers.contains(name)) continue;
    raw.execute(row.read<String>('sql'));
  }
  raw.execute('PRAGMA user_version = 18');
  raw.execute('PRAGMA foreign_keys = ON');
  raw.close();

  final check = sqlite3.sqlite3.open(path);
  expect(check.select('PRAGMA user_version').first['user_version'], 18);
  for (final name in _phase6b11Triggers) {
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
