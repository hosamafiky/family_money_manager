import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/features/household/data/household_repository.dart';
import 'package:family_money_manager/features/household/domain/household_identity.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';

final class DriftHouseholdRepository implements HouseholdRepository {
  const DriftHouseholdRepository(this._db);
  final AppDatabase _db;

  @override
  Future<HouseholdIdentity?> findHousehold(String householdId) async {
    final row = await (_db.select(
      _db.households,
    )..where((t) => t.id.equals(householdId))).getSingleOrNull();
    return row == null ? null : _toIdentity(row);
  }

  @override
  Future<HouseholdIdentity> createHousehold({
    required String id,
    required String displayName,
    required String currencyCode,
    required String ownerUserId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _db
        .into(_db.households)
        .insert(
          HouseholdsCompanion.insert(
            id: id,
            name: displayName,
            currencyCode: Value(currencyCode),
            ownerUserId: ownerUserId,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return _toIdentity(
      await (_db.select(_db.households)..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  @override
  Future<HouseholdIdentity> updateHouseholdName({
    required String id,
    required String displayName,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (_db.update(_db.households)..where((t) => t.id.equals(id))).write(
      HouseholdsCompanion(name: Value(displayName), updatedAt: Value(now)),
    );
    return _toIdentity(
      await (_db.select(_db.households)..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  @override
  Future<HouseholdMember> addMember({
    required String id,
    required String householdId,
    required String displayName,
    required MemberRole role,
  }) async {
    // V1 constraint: at most one active spouse per household.
    if (role == MemberRole.spouse) {
      final existing =
          await (_db.select(_db.householdMembers)..where(
                (t) =>
                    t.householdId.equals(householdId) &
                    t.role.equals(MemberRole.spouse.code) &
                    t.isArchived.equals(false),
              ))
              .getSingleOrNull();
      if (existing != null) throw DuplicateSpouseError();
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await _db
        .into(_db.householdMembers)
        .insert(
          HouseholdMembersCompanion.insert(
            id: id,
            householdId: householdId,
            displayName: displayName,
            role: role.code,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return _toMember(
      await (_db.select(_db.householdMembers)..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  @override
  Future<HouseholdMember?> findMember({
    required String memberId,
    required String householdId,
  }) async {
    final row = await (_db.select(
      _db.householdMembers,
    )..where((t) => t.id.equals(memberId) & t.householdId.equals(householdId))).getSingleOrNull();
    return row == null ? null : _toMember(row);
  }

  @override
  Future<List<HouseholdMember>> listMembers(String householdId) async {
    final rows =
        await (_db.select(_db.householdMembers)
              ..where((t) => t.householdId.equals(householdId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map(_toMember).toList();
  }

  @override
  Future<HouseholdMember> renameMember({
    required String memberId,
    required String householdId,
    required String displayName,
  }) async {
    final existing = await findMember(memberId: memberId, householdId: householdId);
    if (existing == null) throw MemberNotFoundError(memberId);
    final now = DateTime.now().toUtc().toIso8601String();
    await (_db.update(_db.householdMembers)
          ..where((t) => t.id.equals(memberId) & t.householdId.equals(householdId)))
        .write(HouseholdMembersCompanion(displayName: Value(displayName), updatedAt: Value(now)));
    return _toMember(
      await (_db.select(_db.householdMembers)..where((t) => t.id.equals(memberId))).getSingle(),
    );
  }

  @override
  Future<HouseholdMember> archiveMember({
    required String memberId,
    required String householdId,
  }) async {
    final existing = await findMember(memberId: memberId, householdId: householdId);
    if (existing == null) throw MemberNotFoundError(memberId);
    if (existing.role == MemberRole.primaryUser) {
      throw CannotArchivePrimaryUserError();
    }
    if (existing.isArchived) throw MemberAlreadyArchivedError(memberId);
    final now = DateTime.now().toUtc().toIso8601String();
    await (_db.update(
      _db.householdMembers,
    )..where((t) => t.id.equals(memberId) & t.householdId.equals(householdId))).write(
      HouseholdMembersCompanion(
        isArchived: const Value(true),
        lifecycle: Value(MemberLifecycle.archived.code),
        updatedAt: Value(now),
      ),
    );
    return _toMember(
      await (_db.select(_db.householdMembers)..where((t) => t.id.equals(memberId))).getSingle(),
    );
  }

  HouseholdIdentity _toIdentity(DbHousehold row) => HouseholdIdentity(
    id: row.id,
    displayName: row.name,
    currencyCode: row.currencyCode,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  HouseholdMember _toMember(DbHouseholdMember row) => HouseholdMember(
    id: row.id,
    householdId: row.householdId,
    displayName: row.displayName,
    role: MemberRole.fromCode(row.role),
    lifecycle: MemberLifecycle.fromCode(row.lifecycle),
    isArchived: row.isArchived,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
