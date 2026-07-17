import 'package:meta/meta.dart';

enum MemberRole {
  primaryUser,
  spouse,
  child;

  String get code => switch (this) {
    MemberRole.primaryUser => 'primary_user',
    MemberRole.spouse => 'spouse',
    MemberRole.child => 'child',
  };

  static MemberRole fromCode(String code) => switch (code) {
    'primary_user' => MemberRole.primaryUser,
    'spouse' => MemberRole.spouse,
    'child' => MemberRole.child,
    _ => throw ArgumentError.value(code, 'code', 'Unknown MemberRole code'),
  };
}

enum MemberLifecycle {
  active,
  archived;

  String get code => name;

  static MemberLifecycle fromCode(String code) =>
      MemberLifecycle.values.firstWhere(
        (v) => v.code == code,
        orElse: () =>
            throw ArgumentError.value(code, 'code', 'Unknown MemberLifecycle'),
      );
}

@immutable
final class HouseholdMember {
  const HouseholdMember._({
    required this.id,
    required this.householdId,
    required this.displayName,
    required this.role,
    required this.lifecycle,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HouseholdMember({
    required String id,
    required String householdId,
    required String displayName,
    required MemberRole role,
    required MemberLifecycle lifecycle,
    required bool isArchived,
    required String createdAt,
    required String updatedAt,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    if (householdId.isEmpty) {
      throw ArgumentError.value(
        householdId,
        'householdId',
        'must not be empty',
      );
    }
    if (displayName.trim().isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'must not be empty',
      );
    }
    return HouseholdMember._(
      id: id,
      householdId: householdId,
      displayName: displayName.trim(),
      role: role,
      lifecycle: lifecycle,
      isArchived: isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String householdId;
  final String displayName;
  final MemberRole role;
  final MemberLifecycle lifecycle;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;

  bool get isActive => !isArchived;
}
