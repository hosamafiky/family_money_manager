import 'package:meta/meta.dart';

@immutable
final class HouseholdIdentity {
  const HouseholdIdentity._({
    required this.id,
    required this.displayName,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HouseholdIdentity({
    required String id,
    required String displayName,
    required String currencyCode,
    required String createdAt,
    required String updatedAt,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    if (displayName.trim().isEmpty) {
      throw ArgumentError.value(displayName, 'displayName', 'must not be empty');
    }
    return HouseholdIdentity._(
      id: id,
      displayName: displayName.trim(),
      currencyCode: currencyCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String displayName;
  final String currencyCode;
  final String createdAt;
  final String updatedAt;
}
