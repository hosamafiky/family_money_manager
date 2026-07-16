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
///
/// VALIDATION: The factory constructor validates all required invariants and
/// throws [ArgumentError] in all compilation modes (debug and release).
@immutable
final class RecordIncomeParams {
  // Private constructor — only reachable through the validated factory.
  const RecordIncomeParams._({
    required this.operationId,
    required this.householdId,
    required this.destinationAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    required this.tags,
    required this.isRecurring,
    this.idempotencyKey,
    this.categoryCode,
    this.description,
    this.scope,
    this.beneficiaryRole,
    this.spenderMemberId,
    this.beneficiaryMemberId,
  });

  factory RecordIncomeParams({
    required String operationId,
    required String householdId,
    required String destinationAccountId,
    required int amountMinorUnits,
    required String currencyCode,
    required String effectiveDate,
    required String createdBy,
    String? idempotencyKey,
    String? categoryCode,
    String? description,
    ExpenseScope? scope,
    HouseholdMemberRole? beneficiaryRole,
    List<String> tags = const [],
    bool isRecurring = false,
    String? spenderMemberId,
    String? beneficiaryMemberId,
  }) {
    if (amountMinorUnits <= 0) {
      throw ArgumentError.value(
        amountMinorUnits,
        'amountMinorUnits',
        'Income amount must be a positive integer (> 0)',
      );
    }
    if (operationId.isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'operationId must not be empty',
      );
    }
    if (destinationAccountId.isEmpty) {
      throw ArgumentError.value(
        destinationAccountId,
        'destinationAccountId',
        'must not be empty',
      );
    }
    return RecordIncomeParams._(
      operationId: operationId,
      householdId: householdId,
      destinationAccountId: destinationAccountId,
      amountMinorUnits: amountMinorUnits,
      currencyCode: currencyCode,
      effectiveDate: effectiveDate,
      createdBy: createdBy,
      idempotencyKey: idempotencyKey,
      categoryCode: categoryCode,
      description: description,
      scope: scope,
      beneficiaryRole: beneficiaryRole,
      tags: tags,
      isRecurring: isRecurring,
      spenderMemberId: spenderMemberId,
      beneficiaryMemberId: beneficiaryMemberId,
    );
  }

  final String operationId;
  final String householdId;
  final String destinationAccountId;
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String createdBy;

  /// Optional explicit idempotency key. Defaults to [operationId] when null.
  /// Scoped by [householdId] at the database level.
  final String? idempotencyKey;

  final String? categoryCode;
  final String? description;
  final ExpenseScope? scope;
  final HouseholdMemberRole? beneficiaryRole;
  final List<String> tags;

  /// True when flagged as a recurring transaction (scheduling deferred).
  final bool isRecurring;

  /// Stable member UUID for the spender (not a role code).
  final String? spenderMemberId;

  /// Stable member UUID for the beneficiary (not a role code).
  final String? beneficiaryMemberId;

  /// The resolved idempotency key. Falls back to [operationId].
  String get resolvedIdempotencyKey => idempotencyKey ?? operationId;
}

/// Parameters for recording an expense operation.
@immutable
final class RecordExpenseParams {
  const RecordExpenseParams._({
    required this.operationId,
    required this.householdId,
    required this.sourceAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    required this.tags,
    required this.isRecurring,
    this.idempotencyKey,
    this.categoryCode,
    this.description,
    this.scope,
    this.spenderRole,
    this.beneficiaryRole,
    this.spenderMemberId,
    this.beneficiaryMemberId,
  });

  factory RecordExpenseParams({
    required String operationId,
    required String householdId,
    required String sourceAccountId,
    required int amountMinorUnits,
    required String currencyCode,
    required String effectiveDate,
    required String createdBy,
    String? idempotencyKey,
    String? categoryCode,
    String? description,
    ExpenseScope? scope,
    HouseholdMemberRole? spenderRole,
    HouseholdMemberRole? beneficiaryRole,
    List<String> tags = const [],
    bool isRecurring = false,
    String? spenderMemberId,
    String? beneficiaryMemberId,
  }) {
    if (amountMinorUnits <= 0) {
      throw ArgumentError.value(
        amountMinorUnits,
        'amountMinorUnits',
        'Expense amount must be a positive integer (> 0)',
      );
    }
    if (operationId.isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'operationId must not be empty',
      );
    }
    if (sourceAccountId.isEmpty) {
      throw ArgumentError.value(
        sourceAccountId,
        'sourceAccountId',
        'must not be empty',
      );
    }
    return RecordExpenseParams._(
      operationId: operationId,
      householdId: householdId,
      sourceAccountId: sourceAccountId,
      amountMinorUnits: amountMinorUnits,
      currencyCode: currencyCode,
      effectiveDate: effectiveDate,
      createdBy: createdBy,
      idempotencyKey: idempotencyKey,
      categoryCode: categoryCode,
      description: description,
      scope: scope,
      spenderRole: spenderRole,
      beneficiaryRole: beneficiaryRole,
      tags: tags,
      isRecurring: isRecurring,
      spenderMemberId: spenderMemberId,
      beneficiaryMemberId: beneficiaryMemberId,
    );
  }

  final String operationId;
  final String householdId;
  final String sourceAccountId;
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String createdBy;
  final String? idempotencyKey;
  final String? categoryCode;
  final String? description;
  final ExpenseScope? scope;
  final HouseholdMemberRole? spenderRole;
  final HouseholdMemberRole? beneficiaryRole;
  final List<String> tags;

  /// True when flagged as a recurring transaction (scheduling deferred).
  final bool isRecurring;

  /// Stable member UUID for the spender.
  final String? spenderMemberId;

  /// Stable member UUID for the beneficiary.
  final String? beneficiaryMemberId;

  String get resolvedIdempotencyKey => idempotencyKey ?? operationId;
}

/// Parameters for executing a transfer between two accounts.
@immutable
final class ExecuteTransferParams {
  const ExecuteTransferParams._({
    required this.operationId,
    required this.householdId,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    required this.tags,
    this.idempotencyKey,
    this.description,
    this.spenderMemberId,
    this.beneficiaryMemberId,
  });

  factory ExecuteTransferParams({
    required String operationId,
    required String householdId,
    required String sourceAccountId,
    required String destinationAccountId,
    required int amountMinorUnits,
    required String currencyCode,
    required String effectiveDate,
    required String createdBy,
    String? idempotencyKey,
    String? description,
    List<String> tags = const [],
    String? spenderMemberId,
    String? beneficiaryMemberId,
  }) {
    if (amountMinorUnits <= 0) {
      throw ArgumentError.value(
        amountMinorUnits,
        'amountMinorUnits',
        'Transfer amount must be a positive integer (> 0)',
      );
    }
    if (operationId.isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'operationId must not be empty',
      );
    }
    if (sourceAccountId.isEmpty) {
      throw ArgumentError.value(
        sourceAccountId,
        'sourceAccountId',
        'must not be empty',
      );
    }
    if (destinationAccountId.isEmpty) {
      throw ArgumentError.value(
        destinationAccountId,
        'destinationAccountId',
        'must not be empty',
      );
    }
    return ExecuteTransferParams._(
      operationId: operationId,
      householdId: householdId,
      sourceAccountId: sourceAccountId,
      destinationAccountId: destinationAccountId,
      amountMinorUnits: amountMinorUnits,
      currencyCode: currencyCode,
      effectiveDate: effectiveDate,
      createdBy: createdBy,
      idempotencyKey: idempotencyKey,
      description: description,
      tags: tags,
      spenderMemberId: spenderMemberId,
      beneficiaryMemberId: beneficiaryMemberId,
    );
  }

  final String operationId;
  final String householdId;
  final String sourceAccountId;
  final String destinationAccountId;
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String createdBy;
  final String? idempotencyKey;
  final String? description;
  final List<String> tags;

  /// Stable member UUID for the initiator of the transfer.
  final String? spenderMemberId;

  /// Stable member UUID for the beneficiary of the transfer.
  final String? beneficiaryMemberId;

  String get resolvedIdempotencyKey => idempotencyKey ?? operationId;
}

/// Parameters for recording an opening balance.
@immutable
final class RecordOpeningBalanceParams {
  const RecordOpeningBalanceParams._({
    required this.operationId,
    required this.householdId,
    required this.accountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    this.idempotencyKey,
    this.description,
  });

  factory RecordOpeningBalanceParams({
    required String operationId,
    required String householdId,
    required String accountId,
    required int amountMinorUnits,
    required String currencyCode,
    required String effectiveDate,
    required String createdBy,
    String? idempotencyKey,
    String? description,
  }) {
    if (amountMinorUnits < 0) {
      throw ArgumentError.value(
        amountMinorUnits,
        'amountMinorUnits',
        'Opening balance must be non-negative (>= 0). '
            'Use a liability record for negative starting positions.',
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
    return RecordOpeningBalanceParams._(
      operationId: operationId,
      householdId: householdId,
      accountId: accountId,
      amountMinorUnits: amountMinorUnits,
      currencyCode: currencyCode,
      effectiveDate: effectiveDate,
      createdBy: createdBy,
      idempotencyKey: idempotencyKey,
      description: description,
    );
  }

  final String operationId;
  final String householdId;
  final String accountId;

  /// Opening balances must be non-negative (an account cannot start in debt
  /// in V1 — use a liability record for that).
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String createdBy;
  final String? idempotencyKey;
  final String? description;

  String get resolvedIdempotencyKey => idempotencyKey ?? operationId;
}

/// Parameters for recording an adjustment.
@immutable
final class RecordAdjustmentParams {
  const RecordAdjustmentParams._({
    required this.operationId,
    required this.householdId,
    required this.accountId,
    required this.adjustmentAmountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    required this.reason,
    this.idempotencyKey,
  });

  factory RecordAdjustmentParams({
    required String operationId,
    required String householdId,
    required String accountId,
    required int adjustmentAmountMinorUnits,
    required String currencyCode,
    required String effectiveDate,
    required String createdBy,
    required String reason,
    String? idempotencyKey,
  }) {
    if (adjustmentAmountMinorUnits == 0) {
      throw ArgumentError.value(
        adjustmentAmountMinorUnits,
        'adjustmentAmountMinorUnits',
        'Adjustment amount must be non-zero. '
            'Positive = credit (balance increases), negative = debit (balance decreases).',
      );
    }
    if (operationId.isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'operationId must not be empty',
      );
    }
    if (reason.isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Adjustment reason must not be empty',
      );
    }
    return RecordAdjustmentParams._(
      operationId: operationId,
      householdId: householdId,
      accountId: accountId,
      adjustmentAmountMinorUnits: adjustmentAmountMinorUnits,
      currencyCode: currencyCode,
      effectiveDate: effectiveDate,
      createdBy: createdBy,
      reason: reason,
      idempotencyKey: idempotencyKey,
    );
  }

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
  final String? idempotencyKey;

  bool get isCredit => adjustmentAmountMinorUnits > 0;

  String get resolvedIdempotencyKey => idempotencyKey ?? operationId;
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
