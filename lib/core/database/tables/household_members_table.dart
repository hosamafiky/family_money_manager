import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/tables/households_table.dart';

/// Drift table definition for the `household_members` table.
///
/// Each row represents a named member of a household (primary user, spouse,
/// or child). Members are referenced by account ownership and display UI.
///
/// Row type: [DbHouseholdMember].
@DataClassName('DbHouseholdMember')
class HouseholdMembers extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text().references(Households, #id)();
  TextColumn get displayName => text()();

  /// role: 'primary_user' | 'spouse' | 'child'
  TextColumn get role => text()();

  /// lifecycle: 'active' | 'archived'
  TextColumn get lifecycle => text().withDefault(const Constant('active'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
