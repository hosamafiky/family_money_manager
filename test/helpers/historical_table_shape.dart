/// Removes columns that did not exist yet from a materialized historical
/// schema file.
///
/// The `true_schema_v*` helpers build their table shapes by dumping
/// `CREATE TABLE` DDL from a *current* [AppDatabase] probe. That shortcut is
/// only sound while no column has been added to a pre-existing table since the
/// version being materialized — and each helper's own doc comment asserts
/// exactly that. The moment a migration adds a column, every fixture claiming
/// to be older than it silently starts out already carrying it, and the
/// migration under test either no-ops or fails on a duplicate column.
///
/// Drift's `createTable` issues `CREATE TABLE IF NOT EXISTS`, so a fixture that
/// over-supplies a whole *table* is merely inaccurate. `addColumn` has no such
/// guard, so a fixture that over-supplies a *column* is a hard failure — which
/// is the useful signal, and why this is fixed in the fixture rather than by
/// making the production migration tolerant. A v19 database in the field does
/// not have `reversal_reason`; a fixture that does is simply lying.
///
/// Columns are dropped from the freshly created, still-empty tables before the
/// historical trigger/index fixture is applied, so `DROP COLUMN` never has to
/// contend with an index or trigger that references them.
library;

import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// A column added to an already-existing table by a migration.
///
/// New tables do not belong here — [_addedColumns] only covers `addColumn`
/// steps, since those are the ones that break a materialized fixture.
final class _AddedColumn {
  const _AddedColumn({
    required this.schemaVersion,
    required this.table,
    required this.column,
  });

  /// The `schemaVersion` this column first shipped in.
  final int schemaVersion;
  final String table;
  final String column;
}

/// Every column added to a pre-existing table at or after schema 13.
///
/// Nothing earlier is listed because the oldest fixture is v12; a column added
/// at v12 or before is legitimately present in all of them.
///
/// Add an entry here whenever a migration calls `Migrator.addColumn`.
const _addedColumns = <_AddedColumn>[
  _AddedColumn(
    schemaVersion: 20,
    table: 'operations',
    column: 'reversal_reason',
  ),
];

/// Drops every column newer than [schemaVersion] from [db].
///
/// Call immediately after creating the tables and before applying the
/// historical objects fixture.
void stripColumnsNewerThan(sqlite3.Database db, int schemaVersion) {
  for (final added in _addedColumns) {
    if (added.schemaVersion > schemaVersion) {
      db.execute('ALTER TABLE "${added.table}" DROP COLUMN "${added.column}"');
    }
  }
}
