import 'package:drift_flutter/drift_flutter.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.withExecutor(
    driftDatabase(name: 'family_money_manager'),
  );
  ref.onDispose(db.close);
  return db;
});
