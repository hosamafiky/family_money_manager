// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// ignore_for_file: type=lint
abstract class _$EmptyDatabase extends GeneratedDatabase {
  _$EmptyDatabase(QueryExecutor e) : super(e);
  $EmptyDatabaseManager get managers => $EmptyDatabaseManager(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [];
}

class $EmptyDatabaseManager {
  final _$EmptyDatabase _db;
  $EmptyDatabaseManager(this._db);
}
