import 'package:drift/drift.dart';

/// Drift table definition for the `households` table.
///
/// One household per application profile. Contains the root configuration
/// for all financial data scoped to that household.
///
/// Row type: [DbHousehold].
@DataClassName('DbHousehold')
class Households extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerUserId => text()();

  /// ISO 4217 currency code. Default 'EGP' for V1.
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();
  TextColumn get primaryLanguage => text().withDefault(const Constant('ar'))();
  TextColumn get memberUserName => text().withDefault(const Constant(''))();
  TextColumn get memberSpouseName => text().nullable()();
  TextColumn get memberChildName => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  /// Schema version for data migration. Current version: 1.
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
