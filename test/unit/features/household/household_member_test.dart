import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemberRole', () {
    test('primaryUser code is primary_user', () {
      expect(MemberRole.primaryUser.code, 'primary_user');
    });

    test('spouse code is spouse', () {
      expect(MemberRole.spouse.code, 'spouse');
    });

    test('child code is child', () {
      expect(MemberRole.child.code, 'child');
    });

    test('fromCode roundtrips all roles', () {
      for (final role in MemberRole.values) {
        expect(MemberRole.fromCode(role.code), role);
      }
    });

    test('fromCode throws for unknown code', () {
      expect(() => MemberRole.fromCode('unknown'), throwsArgumentError);
    });
  });

  group('MemberLifecycle', () {
    test('active code is active', () {
      expect(MemberLifecycle.active.code, 'active');
    });

    test('archived code is archived', () {
      expect(MemberLifecycle.archived.code, 'archived');
    });

    test('fromCode roundtrips all lifecycles', () {
      for (final lc in MemberLifecycle.values) {
        expect(MemberLifecycle.fromCode(lc.code), lc);
      }
    });

    test('fromCode throws for unknown code', () {
      expect(() => MemberLifecycle.fromCode('deleted'), throwsArgumentError);
    });
  });

  group('HouseholdMember factory', () {
    HouseholdMember validMember({
      String id = 'm1',
      String householdId = 'hh1',
      String displayName = 'Alice',
      MemberRole role = MemberRole.primaryUser,
      MemberLifecycle lifecycle = MemberLifecycle.active,
      bool isArchived = false,
    }) => HouseholdMember(
      id: id,
      householdId: householdId,
      displayName: displayName,
      role: role,
      lifecycle: lifecycle,
      isArchived: isArchived,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

    test('creates a valid member', () {
      final member = validMember();
      expect(member.id, 'm1');
      expect(member.displayName, 'Alice');
      expect(member.role, MemberRole.primaryUser);
      expect(member.isActive, isTrue);
    });

    test('trims whitespace from displayName', () {
      final member = validMember(displayName: '  Bob  ');
      expect(member.displayName, 'Bob');
    });

    test('empty id throws ArgumentError', () {
      expect(() => validMember(id: ''), throwsArgumentError);
    });

    test('empty householdId throws ArgumentError', () {
      expect(() => validMember(householdId: ''), throwsArgumentError);
    });

    test('blank displayName throws ArgumentError', () {
      expect(() => validMember(displayName: '   '), throwsArgumentError);
    });

    test('empty displayName throws ArgumentError', () {
      expect(() => validMember(displayName: ''), throwsArgumentError);
    });

    test('isActive is true when not archived', () {
      final member = validMember(isArchived: false);
      expect(member.isActive, isTrue);
    });

    test('isActive is false when archived', () {
      final member = validMember(isArchived: true, lifecycle: MemberLifecycle.archived);
      expect(member.isActive, isFalse);
    });

    test('spouse role stored correctly', () {
      final member = validMember(role: MemberRole.spouse);
      expect(member.role, MemberRole.spouse);
    });

    test('child role stored correctly', () {
      final member = validMember(role: MemberRole.child);
      expect(member.role, MemberRole.child);
    });
  });
}
