import 'package:family_money_manager/core/database/app_database.dart';

/// Creates an [AppDatabase] backed by an in-memory SQLite database.
///
/// Used in unit tests that require the `db.transaction(...)` function
/// without a real SQLite file.
AppDatabase createInMemoryDatabase() => AppDatabase.forTesting();
