import 'package:family_money_manager/features/household/data/household_repository.dart';
import 'package:family_money_manager/features/household/domain/household_identity.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';

/// In-memory fake implementation of [HouseholdRepository] for unit/widget tests.
final class FakeHouseholdRepository implements HouseholdRepository {
  final List<HouseholdIdentity> _households = [];
  final List<HouseholdMember> _members = [];

  void seedHousehold(HouseholdIdentity household) => _households.add(household);

  void seedMember(HouseholdMember member) => _members.add(member);

  @override
  Future<HouseholdIdentity?> findHousehold(String householdId) async =>
      _households.where((h) => h.id == householdId).firstOrNull;

  @override
  Future<HouseholdIdentity> createHousehold({
    required String id,
    required String displayName,
    required String currencyCode,
    required String ownerUserId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final household = HouseholdIdentity(
      id: id,
      displayName: displayName,
      currencyCode: currencyCode,
      createdAt: now,
      updatedAt: now,
    );
    _households.add(household);
    return household;
  }

  @override
  Future<HouseholdIdentity> updateHouseholdName({
    required String id,
    required String displayName,
  }) async {
    final idx = _households.indexWhere((h) => h.id == id);
    if (idx < 0) throw HouseholdNotFoundError(id);
    final now = DateTime.now().toUtc().toIso8601String();
    final updated = HouseholdIdentity(
      id: id,
      displayName: displayName,
      currencyCode: _households[idx].currencyCode,
      createdAt: _households[idx].createdAt,
      updatedAt: now,
    );
    _households[idx] = updated;
    return updated;
  }

  @override
  Future<HouseholdMember> addMember({
    required String id,
    required String householdId,
    required String displayName,
    required MemberRole role,
  }) async {
    if (role == MemberRole.spouse) {
      final existing = _members
          .where(
            (m) =>
                m.householdId == householdId &&
                m.role == MemberRole.spouse &&
                !m.isArchived,
          )
          .firstOrNull;
      if (existing != null) throw DuplicateSpouseError();
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final member = HouseholdMember(
      id: id,
      householdId: householdId,
      displayName: displayName,
      role: role,
      lifecycle: MemberLifecycle.active,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
    _members.add(member);
    return member;
  }

  @override
  Future<HouseholdMember?> findMember({
    required String memberId,
    required String householdId,
  }) async => _members
      .where((m) => m.id == memberId && m.householdId == householdId)
      .firstOrNull;

  @override
  Future<List<HouseholdMember>> listMembers(String householdId) async =>
      _members.where((m) => m.householdId == householdId).toList();

  @override
  Future<HouseholdMember> renameMember({
    required String memberId,
    required String householdId,
    required String displayName,
  }) async {
    final idx = _members.indexWhere(
      (m) => m.id == memberId && m.householdId == householdId,
    );
    if (idx < 0) throw MemberNotFoundError(memberId);
    final now = DateTime.now().toUtc().toIso8601String();
    final updated = HouseholdMember(
      id: memberId,
      householdId: householdId,
      displayName: displayName,
      role: _members[idx].role,
      lifecycle: _members[idx].lifecycle,
      isArchived: _members[idx].isArchived,
      createdAt: _members[idx].createdAt,
      updatedAt: now,
    );
    _members[idx] = updated;
    return updated;
  }

  @override
  Future<HouseholdMember> archiveMember({
    required String memberId,
    required String householdId,
  }) async {
    final idx = _members.indexWhere(
      (m) => m.id == memberId && m.householdId == householdId,
    );
    if (idx < 0) throw MemberNotFoundError(memberId);
    if (_members[idx].role == MemberRole.primaryUser) {
      throw CannotArchivePrimaryUserError();
    }
    if (_members[idx].isArchived) {
      throw MemberAlreadyArchivedError(memberId);
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final updated = HouseholdMember(
      id: memberId,
      householdId: householdId,
      displayName: _members[idx].displayName,
      role: _members[idx].role,
      lifecycle: MemberLifecycle.archived,
      isArchived: true,
      createdAt: _members[idx].createdAt,
      updatedAt: now,
    );
    _members[idx] = updated;
    return updated;
  }
}
