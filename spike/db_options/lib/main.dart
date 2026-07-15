// DISPOSABLE SPIKE — DECISION-004 only.
// No financial schema. No user data. Opens empty database only.
// Delete this file and spike/ after DECISION-004 is resolved.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'main.g.dart';

// Minimal empty database — no tables, no financial schema.
@DriftDatabase(tables: [])
class EmptyDatabase extends _$EmptyDatabase {
  EmptyDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return driftDatabase(name: 'spike_empty_test');
  });
}
