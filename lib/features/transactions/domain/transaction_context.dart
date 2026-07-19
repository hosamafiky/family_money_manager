import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/transactions/domain/child_withdrawal_context.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:meta/meta.dart';

// ── IncomeContext ─────────────────────────────────────────────────────────────

/// All data needed to record a single income transaction.
@immutable
final class IncomeContext {
  const IncomeContext({
    required this.operationId,
    required this.idempotencyKey,
    required this.householdId,
    required this.destinationAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.category,
    required this.effectiveDate,
    required this.createdBy,
    this.note,
  });

  /// Client-generated UUID for the operation.
  final String operationId;

  /// Explicit idempotency key. Empty string means "use operationId".
  final String idempotencyKey;

  final String householdId;

  /// The account that receives the income credit.
  final String destinationAccountId;

  /// Amount in currency minor units (must be > 0).
  final int amountMinorUnits;

  /// ISO 4217 currency code.
  final String currencyCode;

  /// Must be an income category ([TransactionCategory.isIncome]).
  final TransactionCategory category;

  /// User-chosen effective date, format "YYYY-MM-DD".
  final String effectiveDate;

  /// ID of the user who recorded this (typically the primary-user ID).
  final String createdBy;

  /// Optional free-text note.
  final String? note;

  /// The resolved idempotency key: falls back to [operationId] when [idempotencyKey] is empty.
  String get resolvedIdempotencyKey => idempotencyKey.isEmpty ? operationId : idempotencyKey;
}

// ── ExpenseContext ────────────────────────────────────────────────────────────

/// All data needed to record a single expense transaction.
@immutable
final class ExpenseContext {
  const ExpenseContext({
    required this.operationId,
    required this.idempotencyKey,
    required this.householdId,
    required this.paymentAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.category,
    required this.spenderMemberId,
    required this.beneficiaryMemberId,
    required this.scope,
    required this.isRecurring,
    required this.effectiveDate,
    required this.createdBy,
    this.note,
    this.childWithdrawalAudit,
  });

  final String operationId;
  final String idempotencyKey;
  final String householdId;

  /// The account that is debited.
  final String paymentAccountId;

  final int amountMinorUnits;
  final String currencyCode;

  /// Must be an expense category ([TransactionCategory.isExpense]).
  final TransactionCategory category;

  /// Stable UUID of the member who spent the money.
  final String spenderMemberId;

  /// Stable UUID of the member who benefits.
  final String beneficiaryMemberId;

  /// The scope of the expense (personal, household, spouse, child, shared).
  final ExpenseScope scope;

  /// True when the user flagged this as a recurring expense.
  /// Scheduling is deferred to a future phase.
  final bool isRecurring;

  final String effectiveDate;
  final String createdBy;

  final String? note;

  /// Required when [paymentAccountId] is a protected fund account.
  final ChildWithdrawalContext? childWithdrawalAudit;

  String get resolvedIdempotencyKey => idempotencyKey.isEmpty ? operationId : idempotencyKey;
}

// ── TransferContext ───────────────────────────────────────────────────────────

/// All data needed to execute a money transfer between two accounts.
@immutable
final class TransferContext {
  const TransferContext({
    required this.operationId,
    required this.idempotencyKey,
    required this.householdId,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.createdBy,
    this.note,
    this.childWithdrawalAudit,
  });

  final String operationId;
  final String idempotencyKey;
  final String householdId;
  final String sourceAccountId;
  final String destinationAccountId;
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String createdBy;
  final String? note;

  /// Required when [sourceAccountId] is a protected fund account.
  final ChildWithdrawalContext? childWithdrawalAudit;

  String get resolvedIdempotencyKey => idempotencyKey.isEmpty ? operationId : idempotencyKey;
}
