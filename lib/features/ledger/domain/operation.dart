import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:meta/meta.dart';

/// A logical wrapper grouping related ledger entries into a single financial event.
///
/// An operation is the unit of idempotency. Its [id] must be unique across the
/// household (INV-008). Duplicate [id]s are rejected by a UNIQUE constraint.
///
/// The only mutable fields after creation are [isReversed] and [reversedBy],
/// which are set atomically when a reversal operation is recorded.
/// All ledger entries themselves remain immutable (INV-002).
@immutable
final class Operation {
  const Operation({
    required this.id,
    required this.householdId,
    required this.type,
    required this.effectiveDate,
    required this.recordedAt,
    required this.totalAmountMinorUnits,
    required this.currencyCode,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isReversed,
    this.description,
    this.categoryCode,
    this.scope,
    this.spenderRole,
    this.beneficiaryRole,
    this.sourceAccountId,
    this.destinationAccountId,
    this.isRecurring = false,
    this.recurringRuleId,
    this.tags = const [],
    this.receiptPath,
    this.reversedBy,
  });

  /// Stable client-generated UUID. Used as the idempotency key.
  final String id;

  final String householdId;
  final OperationType type;

  /// User-chosen effective date in "YYYY-MM-DD" format.
  final String effectiveDate;

  /// System UTC timestamp when the operation was recorded.
  final DateTime recordedAt;

  /// User-visible description / notes.
  final String? description;

  /// Income or expense category code. Null for transfers, opening balances, etc.
  final String? categoryCode;

  /// Spending scope: personal, household, spouse, child, or shared.
  final ExpenseScope? scope;

  final HouseholdMemberRole? spenderRole;
  final HouseholdMemberRole? beneficiaryRole;

  /// Source account ID (for expense, transfer, adjustment debits).
  final String? sourceAccountId;

  /// Destination account ID (for income, transfer, opening balance).
  final String? destinationAccountId;

  /// The operation's face amount in minor units. For transfers this is the
  /// amount moved; for income/expense it is the income/expense amount.
  final int totalAmountMinorUnits;

  final String currencyCode;

  final bool isRecurring;
  final String? recurringRuleId;

  /// User-defined tags for filtering.
  final List<String> tags;

  /// Path to a locally stored receipt image (encrypted). Display-layer only.
  final String? receiptPath;

  /// True once a reversal operation has been applied to this operation.
  /// The ONLY permitted mutation of an operation record after creation (INV-002).
  final bool isReversed;

  /// The [id] of the reversal [Operation] that cancelled this one.
  final String? reversedBy;

  final String createdBy;

  /// System UTC timestamp of creation. Matches [recordedAt] on first write.
  final String createdAt;

  /// System UTC timestamp of last update. Only changes when [isReversed] is set.
  final String updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Operation && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Operation(id: $id, type: ${type.code}, date: $effectiveDate)';
}

// ── Params types ─────────────────────────────────────────────────────────────

/// Parameters for recording an income operation.
@immutable
final class RecordIncomeParams {
  const RecordIncomeParams({
    required this.operationId,
    required this.householdId,
    required this.destinationAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    this.categoryCode,
    this.description,
    this.scope,
    this.beneficiaryRole,
    this.tags = const [],
  }) : assert(amountMinorUnits > 0, 'Income amount must be positive');

  final String operationId;
  final String householdId;
  final String destinationAccountId;
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String createdBy;
  final String? categoryCode;
  final String? description;
  final ExpenseScope? scope;
  final HouseholdMemberRole? beneficiaryRole;
  final List<String> tags;
}

/// Parameters for recording an expense operation.
@immutable
final class RecordExpenseParams {
  const RecordExpenseParams({
    required this.operationId,
    required this.householdId,
    required this.sourceAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    this.categoryCode,
    this.description,
    this.scope,
    this.spenderRole,
    this.beneficiaryRole,
    this.tags = const [],
  }) : assert(amountMinorUnits > 0, 'Expense amount must be positive');

  final String operationId;
  final String householdId;
  final String sourceAccountId;
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String createdBy;
  final String? categoryCode;
  final String? description;
  final ExpenseScope? scope;
  final HouseholdMemberRole? spenderRole;
  final HouseholdMemberRole? beneficiaryRole;
  final List<String> tags;
}

/// Parameters for executing a transfer between two accounts.
@immutable
final class ExecuteTransferParams {
  const ExecuteTransferParams({
    required this.operationId,
    required this.householdId,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    this.description,
    this.tags = const [],
  }) : assert(amountMinorUnits > 0, 'Transfer amount must be positive');

  final String operationId;
  final String householdId;
  final String sourceAccountId;
  final String destinationAccountId;
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String createdBy;
  final String? description;
  final List<String> tags;
}

/// Parameters for recording an opening balance.
@immutable
final class RecordOpeningBalanceParams {
  const RecordOpeningBalanceParams({
    required this.operationId,
    required this.householdId,
    required this.accountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    this.description,
  }) : assert(amountMinorUnits >= 0, 'Opening balance must be non-negative');

  final String operationId;
  final String householdId;
  final String accountId;

  /// Opening balances must be non-negative (an account cannot start in debt
  /// in V1 — use a liability record for that).
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String createdBy;
  final String? description;
}

/// Parameters for recording an adjustment.
@immutable
final class RecordAdjustmentParams {
  const RecordAdjustmentParams({
    required this.operationId,
    required this.householdId,
    required this.accountId,
    required this.adjustmentAmountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    required this.reason,
  }) : assert(
         adjustmentAmountMinorUnits != 0,
         'Adjustment amount must be non-zero',
       );

  final String operationId;
  final String householdId;
  final String accountId;

  /// Signed amount: positive → credit adjustment (balance increases),
  /// negative → debit adjustment (balance decreases).
  final int adjustmentAmountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String createdBy;

  /// Mandatory reason for the adjustment (auditable).
  final String reason;

  bool get isCredit => adjustmentAmountMinorUnits > 0;
}

/// Parameters for reversing a prior operation.
@immutable
final class ReverseOperationParams {
  const ReverseOperationParams({
    required this.reversalOperationId,
    required this.originalOperationId,
    required this.householdId,
    required this.effectiveDate,
    required this.createdBy,
    this.reason,
  });

  final String reversalOperationId;
  final String originalOperationId;
  final String householdId;
  final String effectiveDate;
  final String createdBy;
  final String? reason;
}
