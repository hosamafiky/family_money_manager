import 'package:meta/meta.dart';

/// User-confirmed context for a protected-fund withdrawal.
///
/// This object can only be constructed after the UI has presented the
/// warning, collected a reason, and obtained both confirmations.
///
/// INVARIANTS (enforced by the factory constructor):
/// - [reason] must be non-empty after trimming.
/// - [warningAcknowledged] must be `true`.
/// - [confirmed] must be `true`.
@immutable
final class ChildWithdrawalContext {
  const ChildWithdrawalContext._({
    required this.protectedAccountId,
    required this.beneficiaryMemberId,
    required this.reason,
    required this.warningAcknowledged,
    required this.confirmed,
  });

  factory ChildWithdrawalContext({
    required String protectedAccountId,
    required String beneficiaryMemberId,
    required String reason,
    required bool warningAcknowledged,
    required bool confirmed,
  }) {
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'Withdrawal reason must not be empty');
    }
    if (!warningAcknowledged) {
      throw ArgumentError.value(
        warningAcknowledged,
        'warningAcknowledged',
        'The protected-fund warning must be acknowledged before withdrawal',
      );
    }
    if (!confirmed) {
      throw ArgumentError.value(
        confirmed,
        'confirmed',
        'The withdrawal must be explicitly confirmed',
      );
    }
    return ChildWithdrawalContext._(
      protectedAccountId: protectedAccountId,
      beneficiaryMemberId: beneficiaryMemberId,
      reason: reason,
      warningAcknowledged: warningAcknowledged,
      confirmed: confirmed,
    );
  }

  /// The ID of the account being withdrawn from. Must be protected.
  final String protectedAccountId;

  /// Stable UUID of the member who benefits from this withdrawal.
  final String beneficiaryMemberId;

  /// Non-empty reason for the withdrawal (displayed in audit trail).
  final String reason;

  /// The user explicitly acknowledged the protected-fund warning.
  final bool warningAcknowledged;

  /// The user explicitly confirmed the withdrawal action.
  final bool confirmed;
}
