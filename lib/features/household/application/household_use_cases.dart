import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/household/data/household_repository.dart';
import 'package:family_money_manager/features/household/domain/household_identity.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:uuid/uuid.dart';

final class GetHouseholdUseCase {
  const GetHouseholdUseCase(this._repo);
  final HouseholdRepository _repo;

  Future<AppResult<HouseholdIdentity>> execute(String householdId) async {
    try {
      final hh = await _repo.findHousehold(householdId);
      if (hh == null) return const AppNotFound();
      return AppOk(hh);
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}

final class ListMembersUseCase {
  const ListMembersUseCase(this._repo);
  final HouseholdRepository _repo;

  Future<AppResult<List<HouseholdMember>>> execute(String householdId) async {
    try {
      return AppOk(await _repo.listMembers(householdId));
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}

final class AddMemberUseCase {
  const AddMemberUseCase(this._repo);
  final HouseholdRepository _repo;
  static const _uuid = Uuid();

  Future<AppResult<HouseholdMember>> execute({
    required String householdId,
    required String displayName,
    required MemberRole role,
  }) async {
    if (displayName.trim().isEmpty) {
      return const AppValidationFailure(
        field: 'displayName',
        messageKey: 'error_member_name_empty',
      );
    }
    try {
      final member = await _repo.addMember(
        id: _uuid.v4(),
        householdId: householdId,
        displayName: displayName.trim(),
        role: role,
      );
      return AppOk(member);
    } on DuplicateSpouseError {
      return const AppDuplicateConflict<HouseholdMember>(
        messageKey: 'error_spouse_duplicate',
      );
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}

final class RenameMemberUseCase {
  const RenameMemberUseCase(this._repo);
  final HouseholdRepository _repo;

  Future<AppResult<HouseholdMember>> execute({
    required String memberId,
    required String householdId,
    required String displayName,
  }) async {
    if (displayName.trim().isEmpty) {
      return const AppValidationFailure(
        field: 'displayName',
        messageKey: 'error_member_name_empty',
      );
    }
    try {
      final member = await _repo.renameMember(
        memberId: memberId,
        householdId: householdId,
        displayName: displayName.trim(),
      );
      return AppOk(member);
    } on MemberNotFoundError {
      return const AppNotFound();
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}

final class ArchiveMemberUseCase {
  const ArchiveMemberUseCase(this._repo);
  final HouseholdRepository _repo;

  Future<AppResult<HouseholdMember>> execute({
    required String memberId,
    required String householdId,
  }) async {
    try {
      final member = await _repo.archiveMember(
        memberId: memberId,
        householdId: householdId,
      );
      return AppOk(member);
    } on CannotArchivePrimaryUserError {
      return const AppValidationFailure(
        field: 'role',
        messageKey: 'error_cannot_archive_primary_user',
      );
    } on MemberAlreadyArchivedError {
      return const AppDuplicateConflict(
        messageKey: 'error_member_already_archived',
      );
    } on MemberNotFoundError {
      return const AppNotFound();
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}
