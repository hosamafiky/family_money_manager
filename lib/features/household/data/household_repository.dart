import 'package:family_money_manager/features/household/domain/household_identity.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';

abstract interface class HouseholdRepository {
  Future<HouseholdIdentity?> findHousehold(String householdId);
  Future<HouseholdIdentity> createHousehold({
    required String id,
    required String displayName,
    required String currencyCode,
    required String ownerUserId,
  });
  Future<HouseholdIdentity> updateHouseholdName({required String id, required String displayName});

  Future<HouseholdMember> addMember({
    required String id,
    required String householdId,
    required String displayName,
    required MemberRole role,
  });
  Future<HouseholdMember?> findMember({required String memberId, required String householdId});
  Future<List<HouseholdMember>> listMembers(String householdId);
  Future<HouseholdMember> renameMember({
    required String memberId,
    required String householdId,
    required String displayName,
  });
  Future<HouseholdMember> archiveMember({required String memberId, required String householdId});
}

// ── Domain errors ──────────────────────────────────────────────────────────

final class HouseholdNotFoundError extends Error {
  HouseholdNotFoundError(this.householdId);
  final String householdId;
}

final class MemberNotFoundError extends Error {
  MemberNotFoundError(this.memberId);
  final String memberId;
}

final class DuplicateSpouseError extends Error {
  DuplicateSpouseError();
}

final class MemberAlreadyArchivedError extends Error {
  MemberAlreadyArchivedError(this.memberId);
  final String memberId;
}

final class CannotArchivePrimaryUserError extends Error {
  CannotArchivePrimaryUserError();
}
