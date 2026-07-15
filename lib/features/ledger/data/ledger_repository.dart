import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';

/// Repository abstraction for all ledger write and read operations.
///
/// ARCHITECTURE RULES:
/// - No widget or provider may call these methods directly.
/// - No Drift types appear in any method signature.
/// - There is NO `update` or `delete` method on ledger entries (INV-002).
/// - Financial writes must occur inside explicit database transactions (INV-007).
/// - The [isReversed] flag on an operation is the ONLY field ever mutated
///   after initial creation; this update is done atomically with the reversal.
/// - All write methods are idempotent: submitting the same [operationId] twice
///   returns [IdempotentOperationResult.alreadyExists] (INV-008).
///
/// Protected-fund rule (INV-006):
/// - Any method that creates a debit on a protected account MUST require
///   [ChildWithdrawalAuditParams].
/// - The repository checks [FinancialAccount.requiresWithdrawalAudit] before
///   writing any debit entry.
/// - The audit record is written in the same SQLite transaction.
abstract interface class LedgerRepository {
  // ── Write operations ─────────────────────────────────────────────────────────

  /// Records an income operation (credit on destination account).
  ///
  /// Returns [IdempotentOperationResult.created] on success.
  /// Returns [IdempotentOperationResult.alreadyExists] if [params.operationId]
  /// was already used.
  Future<IdempotentOperationResult> recordIncome(RecordIncomeParams params);

  /// Records an expense operation (debit on source account).
  ///
  /// Throws [MissingProtectedWithdrawalAuditError] if the source account is
  /// protected and [auditParams] is null.
  /// Throws [InsufficientFundsError] if the account would go negative.
  Future<IdempotentOperationResult> recordExpense(
    RecordExpenseParams params, {
    ChildWithdrawalAuditParams? auditParams,
  });

  /// Executes a transfer between two accounts.
  ///
  /// Requirements (INV-003, INV-007):
  /// - Source and destination must differ.
  /// - Both accounts must share the same currency (V1 cross-currency prohibition).
  /// - Neither account may be archived.
  /// - Both debit and credit entries are written atomically.
  /// - If either account is protected, [auditParams] is required.
  /// - Balance check for source account is performed inside the transaction.
  ///
  /// Throws [SameAccountTransferError], [CurrencyMismatchTransferError],
  /// [ArchivedAccountTransferError], [InsufficientFundsError],
  /// [MissingProtectedWithdrawalAuditError].
  Future<IdempotentOperationResult> executeTransfer(
    ExecuteTransferParams params, {
    ChildWithdrawalAuditParams? auditParams,
  });

  /// Records an opening balance for an account.
  ///
  /// Throws [DuplicateOpeningBalanceError] if the account already has an
  /// opening balance entry (FINANCIAL_MODEL §5.1).
  Future<IdempotentOperationResult> recordOpeningBalance(
    RecordOpeningBalanceParams params,
  );

  /// Records a balance adjustment (credit or debit).
  ///
  /// If the target account is protected, [auditParams] is required for debit
  /// adjustments. Credit adjustments (positive amount) do not require audit.
  Future<IdempotentOperationResult> recordAdjustment(
    RecordAdjustmentParams params, {
    ChildWithdrawalAuditParams? auditParams,
  });

  /// Reverses a prior operation by appending opposite ledger entries.
  ///
  /// Requirements (FINANCIAL_MODEL §22):
  /// - The original operation must exist.
  /// - The original operation must NOT already be reversed.
  /// - Both the new reversal entries and the flag update are atomic.
  /// - If any reversed leg debits a protected account, [auditParams] is required.
  ///
  /// Throws [OperationNotFoundError], [DuplicateReversalError],
  /// [MissingProtectedWithdrawalAuditError].
  Future<IdempotentOperationResult> reverseOperation(
    ReverseOperationParams params, {
    ChildWithdrawalAuditParams? auditParams,
  });

  // ── Read operations ──────────────────────────────────────────────────────────

  /// Returns all ledger entries for [accountId] within [householdId].
  ///
  /// Includes reversal entries (they are part of the permanent record).
  /// Ordered by [effectiveDate] ascending, then [recordedAt] ascending for
  /// deterministic ordering within the same date (INV-012).
  Future<List<LedgerEntry>> entriesForAccount({
    required String accountId,
    required String householdId,
  });

  /// Returns the [Operation] with [operationId], or null when not found.
  Future<Operation?> findOperation({
    required String operationId,
    required String householdId,
  });

  /// Returns all operations for [householdId] between [fromDate] and [toDate]
  /// inclusive ("YYYY-MM-DD" format), ordered by effective date ascending.
  Future<List<Operation>> operationsInRange({
    required String householdId,
    required String fromDate,
    required String toDate,
  });
}

// ── Result type ───────────────────────────────────────────────────────────────

/// The outcome of a ledger write that supports idempotency (INV-008).
enum IdempotentOperationResult {
  /// The operation was newly created and persisted.
  created,

  /// The operation already existed; no change was made.
  alreadyExists,
}

// ── Domain errors ────────────────────────────────────────────────────────────

final class SameAccountTransferError extends Error {
  SameAccountTransferError(this.accountId);
  final String accountId;
  @override
  String toString() =>
      'SameAccountTransferError: source and destination are the same account ($accountId)';
}

final class CurrencyMismatchTransferError extends Error {
  CurrencyMismatchTransferError({
    required this.sourceCode,
    required this.destinationCode,
  });
  final String sourceCode;
  final String destinationCode;
  @override
  String toString() =>
      'CurrencyMismatchTransferError: '
      'source currency $sourceCode ≠ destination currency $destinationCode. '
      'Cross-currency transfers are prohibited in V1.';
}

final class ArchivedAccountTransferError extends Error {
  ArchivedAccountTransferError(this.accountId, this.role);
  final String accountId;
  final String role;
  @override
  String toString() =>
      'ArchivedAccountTransferError: $role account $accountId is archived';
}

final class DuplicateOpeningBalanceError extends Error {
  DuplicateOpeningBalanceError(this.accountId);
  final String accountId;
  @override
  String toString() =>
      'DuplicateOpeningBalanceError: '
      'account $accountId already has an opening balance. '
      'Use an adjustment operation to correct the balance.';
}

final class OperationNotFoundError extends Error {
  OperationNotFoundError(this.operationId);
  final String operationId;
  @override
  String toString() =>
      'OperationNotFoundError: operation $operationId not found';
}

final class DuplicateReversalError extends Error {
  DuplicateReversalError(this.operationId);
  final String operationId;
  @override
  String toString() =>
      'DuplicateReversalError: operation $operationId has already been reversed. '
      'An operation may only be fully reversed once (FINANCIAL_MODEL §22).';
}
