import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/household/application/household_use_cases.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_household_repository.dart';

void main() {
  late FakeHouseholdRepository repo;

  setUp(() {
    repo = FakeHouseholdRepository();
  });

  group('AddMemberUseCase', () {
    test('empty displayName returns AppValidationFailure', () async {
      final useCase = AddMemberUseCase(repo);
      final result = await useCase.execute(
        householdId: 'hh1',
        displayName: '',
        role: MemberRole.child,
      );
      expect(result, isA<AppValidationFailure<HouseholdMember>>());
      final failure = result as AppValidationFailure<HouseholdMember>;
      expect(failure.field, 'displayName');
      expect(failure.messageKey, 'error_member_name_empty');
    });

    test('blank displayName (whitespace) returns AppValidationFailure', () async {
      final useCase = AddMemberUseCase(repo);
      final result = await useCase.execute(
        householdId: 'hh1',
        displayName: '   ',
        role: MemberRole.child,
      );
      expect(result, isA<AppValidationFailure<HouseholdMember>>());
    });

    test('valid child member returns AppOk', () async {
      final useCase = AddMemberUseCase(repo);
      final result = await useCase.execute(
        householdId: 'hh1',
        displayName: 'Ali',
        role: MemberRole.child,
      );
      expect(result, isA<AppOk<HouseholdMember>>());
      final member = (result as AppOk<HouseholdMember>).value;
      expect(member.displayName, 'Ali');
      expect(member.role, MemberRole.child);
    });

    test('duplicate spouse returns AppDuplicateConflict', () async {
      final useCase = AddMemberUseCase(repo);
      // Add first spouse.
      await useCase.execute(householdId: 'hh1', displayName: 'Sara', role: MemberRole.spouse);
      // Attempt to add a second spouse.
      final result = await useCase.execute(
        householdId: 'hh1',
        displayName: 'Fatima',
        role: MemberRole.spouse,
      );
      expect(result, isA<AppDuplicateConflict<HouseholdMember>>());
      final conflict = result as AppDuplicateConflict<HouseholdMember>;
      expect(conflict.messageKey, 'error_spouse_duplicate');
    });
  });

  group('RenameMemberUseCase', () {
    test('empty name returns AppValidationFailure', () async {
      final useCase = RenameMemberUseCase(repo);
      final result = await useCase.execute(memberId: 'm1', householdId: 'hh1', displayName: '');
      expect(result, isA<AppValidationFailure<HouseholdMember>>());
    });

    test('non-existent member returns AppNotFound', () async {
      final useCase = RenameMemberUseCase(repo);
      final result = await useCase.execute(
        memberId: 'not-exist',
        householdId: 'hh1',
        displayName: 'NewName',
      );
      expect(result, isA<AppNotFound<HouseholdMember>>());
    });
  });

  group('ArchiveMemberUseCase', () {
    Future<HouseholdMember> addMember(FakeHouseholdRepository r, MemberRole role) async {
      final addUseCase = AddMemberUseCase(r);
      final result = await addUseCase.execute(householdId: 'hh1', displayName: 'Test', role: role);
      return (result as AppOk<HouseholdMember>).value;
    }

    test('archive primary user returns AppValidationFailure', () async {
      final member = await addMember(repo, MemberRole.primaryUser);
      final useCase = ArchiveMemberUseCase(repo);
      final result = await useCase.execute(memberId: member.id, householdId: 'hh1');
      expect(result, isA<AppValidationFailure<HouseholdMember>>());
      final failure = result as AppValidationFailure<HouseholdMember>;
      expect(failure.messageKey, 'error_cannot_archive_primary_user');
    });

    test('archive non-existent member returns AppNotFound', () async {
      final useCase = ArchiveMemberUseCase(repo);
      final result = await useCase.execute(memberId: 'not-exist', householdId: 'hh1');
      expect(result, isA<AppNotFound<HouseholdMember>>());
    });

    test('archive child member returns AppOk', () async {
      final member = await addMember(repo, MemberRole.child);
      final useCase = ArchiveMemberUseCase(repo);
      final result = await useCase.execute(memberId: member.id, householdId: 'hh1');
      expect(result, isA<AppOk<HouseholdMember>>());
      final archived = (result as AppOk<HouseholdMember>).value;
      expect(archived.isArchived, isTrue);
    });

    test('archive already archived member returns AppDuplicateConflict', () async {
      final member = await addMember(repo, MemberRole.child);
      final useCase = ArchiveMemberUseCase(repo);
      // First archive.
      await useCase.execute(memberId: member.id, householdId: 'hh1');
      // Second archive attempt.
      final result = await useCase.execute(memberId: member.id, householdId: 'hh1');
      expect(result, isA<AppDuplicateConflict<HouseholdMember>>());
    });
  });
}
