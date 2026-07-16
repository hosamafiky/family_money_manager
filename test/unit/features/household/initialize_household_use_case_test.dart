/// Tests for [InitializeHouseholdUseCase] (Phase 3A.1 §10).
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/household/application/household_use_cases.dart';
import 'package:family_money_manager/features/household/domain/household_identity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_household_repository.dart';

void main() {
  late FakeHouseholdRepository repo;
  late InitializeHouseholdUseCase useCase;

  setUp(() {
    repo = FakeHouseholdRepository();
    useCase = InitializeHouseholdUseCase(householdRepository: repo);
  });

  group('InitializeHouseholdUseCase', () {
    test(
      'empty household name → AppValidationFailure(field: householdName)',
      () async {
        final result = await useCase.execute(
          householdName: '  ',
          primaryMemberName: 'Ahmed',
          currencyCode: 'EGP',
        );

        expect(result, isA<AppValidationFailure<HouseholdIdentity>>());
        final failure = result as AppValidationFailure<HouseholdIdentity>;
        expect(failure.field, 'householdName');
      },
    );

    test(
      'empty primary member name → AppValidationFailure(field: primaryMemberName)',
      () async {
        final result = await useCase.execute(
          householdName: 'My Family',
          primaryMemberName: '',
          currencyCode: 'EGP',
        );

        expect(result, isA<AppValidationFailure<HouseholdIdentity>>());
        final failure = result as AppValidationFailure<HouseholdIdentity>;
        expect(failure.field, 'primaryMemberName');
      },
    );

    test('valid inputs → AppOk with household identity', () async {
      final result = await useCase.execute(
        householdName: 'Al-Rashid Family',
        primaryMemberName: 'Omar',
        currencyCode: 'EGP',
      );

      expect(result, isA<AppOk<HouseholdIdentity>>());
      final ok = result as AppOk<HouseholdIdentity>;
      expect(ok.value.id, InitializeHouseholdUseCase.defaultHouseholdId);
      expect(ok.value.displayName, 'Al-Rashid Family');
    });

    test(
      'second call with same ID → AppOk with existing household (idempotent)',
      () async {
        final r1 = await useCase.execute(
          householdName: 'First Name',
          primaryMemberName: 'First Person',
          currencyCode: 'EGP',
        );
        expect(r1, isA<AppOk<HouseholdIdentity>>());

        final r2 = await useCase.execute(
          householdName: 'Second Name',
          primaryMemberName: 'Second Person',
          currencyCode: 'USD',
        );
        expect(r2, isA<AppOk<HouseholdIdentity>>());

        // Returns the ORIGINAL household, not the new name.
        final original = (r1 as AppOk<HouseholdIdentity>).value;
        final returned = (r2 as AppOk<HouseholdIdentity>).value;
        expect(returned.id, original.id);
        expect(returned.displayName, original.displayName);
      },
    );
  });
}
