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
///
/// VALIDATION: The factory constructor performs release-safe validation.
/// [ArgumentError] is thrown (not `assert`) so validation also runs in release.
@immutable
final class ChildWithdrawalAudit {
  // Private constructor — only reachable through the validated factory.
  const ChildWithdrawalAudit._({
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
  });

  /// Creates a validated [ChildWithdrawalAudit].
  ///
  /// Throws [ArgumentError] when:
  /// - [amountMinorUnits] is not positive
  /// - [warningShown] is false
  /// - [reason] is empty
  factory ChildWithdrawalAudit({
    required String id,
    required String operationId,
    required String householdId,
    required String accountId,
    required int amountMinorUnits,
    required String reason,
    required HouseholdMemberRole beneficiary,
    required DateTime confirmedAt,
    required String confirmedBy,
    required bool warningShown,
    required bool biometricConfirmed,
    required DateTime createdAt,
  }) {
    if (amountMinorUnits <= 0) {
      throw ArgumentError.value(
        amountMinorUnits,
        'amountMinorUnits',
        'ChildWithdrawalAudit amountMinorUnits must be positive (> 0)',
      );
    }
    if (!warningShown) {
      throw ArgumentError.value(
        warningShown,
        'warningShown',
        'ChildWithdrawalAudit warningShown must be true. '
            'The user must acknowledge the warning before the audit is recorded.',
      );
    }
    if (reason.isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'ChildWithdrawalAudit reason must not be empty',
      );
    }
    if (id.isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'ChildWithdrawalAudit id must not be empty',
      );
    }
    if (operationId.isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'ChildWithdrawalAudit operationId must not be empty',
      );
    }
    return ChildWithdrawalAudit._(
      id: id,
      operationId: operationId,
      householdId: householdId,
      accountId: accountId,
      amountMinorUnits: amountMinorUnits,
      reason: reason,
      beneficiary: beneficiary,
      confirmedAt: confirmedAt,
      confirmedBy: confirmedBy,
      warningShown: warningShown,
      biometricConfirmed: biometricConfirmed,
      createdAt: createdAt,
    );
  }

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
///
/// VALIDATION: All invariants are checked in the factory constructor and throw
/// [ArgumentError] in both debug and release modes.
@immutable
final class ChildWithdrawalAuditParams {
  const ChildWithdrawalAuditParams._({
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
    required this.biometricConfirmed,
  });

  factory ChildWithdrawalAuditParams({
    required String auditId,
    required String operationId,
    required String householdId,
    required String accountId,
    required int amountMinorUnits,
    required String reason,
    required HouseholdMemberRole beneficiary,
    required DateTime confirmedAt,
    required String confirmedBy,
    required bool warningShown,
    bool biometricConfirmed = false,
  }) {
    if (amountMinorUnits <= 0) {
      throw ArgumentError.value(
        amountMinorUnits,
        'amountMinorUnits',
        'ChildWithdrawalAuditParams amountMinorUnits must be positive (> 0)',
      );
    }
    if (!warningShown) {
      throw ArgumentError.value(
        warningShown,
        'warningShown',
        'Warning must be shown before ChildWithdrawalAuditParams can be created. '
            'Set warningShown=true only after the warning UI has been presented.',
      );
    }
    if (reason.isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'ChildWithdrawalAuditParams reason must not be empty',
      );
    }
    if (operationId.isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'operationId must not be empty',
      );
    }
    if (accountId.isEmpty) {
      throw ArgumentError.value(
        accountId,
        'accountId',
        'accountId must not be empty',
      );
    }
    return ChildWithdrawalAuditParams._(
      auditId: auditId,
      operationId: operationId,
      householdId: householdId,
      accountId: accountId,
      amountMinorUnits: amountMinorUnits,
      reason: reason,
      beneficiary: beneficiary,
      confirmedAt: confirmedAt,
      confirmedBy: confirmedBy,
      warningShown: warningShown,
      biometricConfirmed: biometricConfirmed,
    );
  }

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
  /// Constructing this object with [warningShown: false] throws [ArgumentError].
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

/// Thrown when an audit record references a different operation than expected.
final class AuditOperationMismatchError extends Error {
  AuditOperationMismatchError({
    required this.auditOperationId,
    required this.expectedOperationId,
  });
  final String auditOperationId;
  final String expectedOperationId;
  @override
  String toString() =>
      'AuditOperationMismatchError: '
      'ChildWithdrawalAuditParams.operationId ($auditOperationId) '
      'does not match the operation being written ($expectedOperationId). '
      'An audit record must reference its own operation.';
}

/// Thrown when an audit record references a different account than the
/// protected account being debited.
final class AuditAccountMismatchError extends Error {
  AuditAccountMismatchError({
    required this.auditAccountId,
    required this.expectedAccountId,
  });
  final String auditAccountId;
  final String expectedAccountId;
  @override
  String toString() =>
      'AuditAccountMismatchError: '
      'ChildWithdrawalAuditParams.accountId ($auditAccountId) '
      'does not match the protected account being debited ($expectedAccountId).';
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
