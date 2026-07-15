import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:meta/meta.dart';

/// Immutable audit record required for every debit on a protected child fund.
///
/// INVARIANTS (INV-006):
/// - Every [childFundWithdrawal] ledger entry MUST have exactly one linked
///   [ChildWithdrawalAudit] record with the same [operationId].
/// - Once written, this record is NEVER modified or deleted.
/// - [warningShown] must always be true. The database CHECK constraint enforces
///   this; the domain layer also validates it before persistence.
/// - The audit record is written atomically in the same SQLite transaction as
///   the ledger entry (INV-007).
@immutable
final class ChildWithdrawalAudit {
  const ChildWithdrawalAudit({
    required this.id,
    required this.operationId,
    required this.householdId,
    required this.accountId,
    required this.amountMinorUnits,
    required this.reason,
    required this.beneficiary,
    required this.confirmedAt,
    required this.confirmedBy,
    required this.warningShown,
    required this.biometricConfirmed,
    required this.createdAt,
  }) : assert(amountMinorUnits > 0, 'amountMinorUnits must be positive'),
       assert(warningShown, 'warningShown must be true'),
       assert(reason != '', 'reason must not be empty');

  final String id;

  /// Links to the [Operation.id] of the withdrawal operation.
  final String operationId;
  final String householdId;
  final String accountId;
  final int amountMinorUnits;

  /// Mandatory, non-empty reason for the withdrawal.
  final String reason;

  final HouseholdMemberRole beneficiary;

  /// UTC timestamp when the user explicitly confirmed the warning.
  final DateTime confirmedAt;
  final String confirmedBy;

  /// Must be true. The planned CHECK constraint `warning_shown = 1` enforces
  /// this at the database level.
  final bool warningShown;

  final bool biometricConfirmed;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChildWithdrawalAudit && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChildWithdrawalAudit(operationId: $operationId, accountId: $accountId)';
}

/// Parameters required to record a protected-fund withdrawal.
///
/// The caller is responsible for presenting the warning UI and collecting
/// explicit user confirmation before constructing this object.
@immutable
final class ChildWithdrawalAuditParams {
  const ChildWithdrawalAuditParams({
    required this.auditId,
    required this.operationId,
    required this.householdId,
    required this.accountId,
    required this.amountMinorUnits,
    required this.reason,
    required this.beneficiary,
    required this.confirmedAt,
    required this.confirmedBy,
    required this.warningShown,
    this.biometricConfirmed = false,
  }) : assert(amountMinorUnits > 0),
       assert(
         warningShown,
         'Warning must be shown before audit params can be created',
       );

  final String auditId;
  final String operationId;
  final String householdId;
  final String accountId;
  final int amountMinorUnits;
  final String reason;
  final HouseholdMemberRole beneficiary;
  final DateTime confirmedAt;
  final String confirmedBy;

  /// Callers MUST set this to true only after the warning UI has been shown.
  /// Constructing this object with [warningShown: false] is an assertion error.
  final bool warningShown;
  final bool biometricConfirmed;
}

/// Thrown when a debit on a protected account is attempted without providing
/// [ChildWithdrawalAuditParams] (INV-006).
final class MissingProtectedWithdrawalAuditError extends Error {
  MissingProtectedWithdrawalAuditError(this.accountId);
  final String accountId;
  @override
  String toString() =>
      'MissingProtectedWithdrawalAuditError: '
      'Account $accountId is protected. '
      'A ChildWithdrawalAuditParams with warningShown=true is required.';
}

/// Thrown when an operation would cause an account to go negative (INV-005).
final class InsufficientFundsError extends Error {
  InsufficientFundsError({
    required this.accountId,
    required this.availableMinorUnits,
    required this.requestedMinorUnits,
  });
  final String accountId;
  final int availableMinorUnits;
  final int requestedMinorUnits;
  @override
  String toString() =>
      'InsufficientFundsError: account $accountId has $availableMinorUnits '
      'minor units available but $requestedMinorUnits were requested';
}
