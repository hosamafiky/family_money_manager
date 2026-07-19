import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/household/data/household_repository.dart';
import 'package:family_money_manager/features/household/domain/household_identity.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:uuid/uuid.dart';

/// Creates the household and primary member atomically on first launch.
///
/// Idempotent: a second call returns the existing household without error.
/// Uses fixed IDs so that re-running the use case always refers to the same
/// household row rather than creating duplicates.
final class InitializeHouseholdUseCase {
  const InitializeHouseholdUseCase({required HouseholdRepository householdRepository}) : _repo = householdRepository;

  final HouseholdRepository _repo;

  static const String defaultHouseholdId = 'household-v1';
  static const String defaultPrimaryMemberId = 'member-primary-v1';

  Future<AppResult<HouseholdIdentity>> execute({required String householdName, required String primaryMemberName, required String currencyCode}) async {
    if (householdName.trim().isEmpty) {
      return const AppValidationFailure(field: 'householdName', messageKey: 'error_member_name_empty');
    }
    if (primaryMemberName.trim().isEmpty) {
      return const AppValidationFailure(field: 'primaryMemberName', messageKey: 'error_member_name_empty');
    }

    try {
      // Idempotency: if the same household already exists with the same name,
      // return it (safe retry). If names differ, reject with a duplicate conflict
      // so callers know the household was already configured differently.
      final existing = await _repo.findHousehold(defaultHouseholdId);
      if (existing != null) {
        if (existing.displayName == householdName.trim()) {
          return AppOk(existing);
        }
        return const AppDuplicateConflict(messageKey: 'error_household_already_initialized');
      }

      final household = await _repo.createHousehold(
        id: defaultHouseholdId,
        displayName: householdName.trim(),
        currencyCode: currencyCode,
        ownerUserId: defaultPrimaryMemberId,
      );
      await _repo.addMember(id: defaultPrimaryMemberId, householdId: defaultHouseholdId, displayName: primaryMemberName.trim(), role: MemberRole.primaryUser);
      return AppOk(household);
    } on DuplicateSpouseError {
      return const AppDuplicateConflict(messageKey: 'error_household_already_initialized');
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}

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

  Future<AppResult<HouseholdMember>> execute({required String householdId, required String displayName, required MemberRole role}) async {
    if (displayName.trim().isEmpty) {
      return const AppValidationFailure(field: 'displayName', messageKey: 'error_member_name_empty');
    }
    try {
      final member = await _repo.addMember(id: _uuid.v4(), householdId: householdId, displayName: displayName.trim(), role: role);
      return AppOk(member);
    } on DuplicateSpouseError {
      return const AppDuplicateConflict<HouseholdMember>(messageKey: 'error_spouse_duplicate');
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}

final class RenameMemberUseCase {
  const RenameMemberUseCase(this._repo);
  final HouseholdRepository _repo;

  Future<AppResult<HouseholdMember>> execute({required String memberId, required String householdId, required String displayName}) async {
    if (displayName.trim().isEmpty) {
      return const AppValidationFailure(field: 'displayName', messageKey: 'error_member_name_empty');
    }
    try {
      final member = await _repo.renameMember(memberId: memberId, householdId: householdId, displayName: displayName.trim());
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

  Future<AppResult<HouseholdMember>> execute({required String memberId, required String householdId}) async {
    try {
      final member = await _repo.archiveMember(memberId: memberId, householdId: householdId);
      return AppOk(member);
    } on CannotArchivePrimaryUserError {
      return const AppValidationFailure(field: 'role', messageKey: 'error_cannot_archive_primary_user');
    } on MemberAlreadyArchivedError {
      return const AppDuplicateConflict(messageKey: 'error_member_already_archived');
    } on MemberNotFoundError {
      return const AppNotFound();
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}
