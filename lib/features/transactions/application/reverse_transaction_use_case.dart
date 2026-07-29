import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';

/// The longest a reversal reason may be.
///
/// Long enough for a sentence explaining what went wrong, short enough that it
/// renders on one detail row without truncation becoming the normal case.
const int maxReversalReasonLength = 280;

/// Records a reversal of a prior operation, with a reason, on behalf of a user.
///
/// This is the only path the UI may take to reverse anything. The ledger
/// repository will reverse without a reason because internal flows need that;
/// a person correcting their own ledger must say why, because the reason is
/// the entire audit value of an append-only correction. Six months later
/// "reversed" tells you nothing and "entered twice by mistake" tells you
/// everything.
///
/// There is deliberately no edit and no delete anywhere above this use case.
final class ReverseTransactionUseCase {
  const ReverseTransactionUseCase({required LedgerRepository ledgerRepository})
    : _ledger = ledgerRepository;

  final LedgerRepository _ledger;

  /// Reverses [originalOperationId], returning the new reversal operation's id.
  ///
  /// [reversalOperationId] is client-generated and doubles as the idempotency
  /// key, so a retried confirm cannot produce two counter-entries.
  Future<AppResult<String>> execute({
    required String reversalOperationId,
    required String originalOperationId,
    required String householdId,
    required String effectiveDate,
    required String createdBy,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      return const AppValidationFailure(
        field: 'reason',
        messageKey: 'errorReversalReasonRequired',
      );
    }
    if (trimmedReason.length > maxReversalReasonLength) {
      return const AppValidationFailure(
        field: 'reason',
        messageKey: 'errorReversalReasonTooLong',
      );
    }
    if (originalOperationId.isEmpty || reversalOperationId.isEmpty) {
      return const AppValidationFailure(
        field: 'operationId',
        messageKey: 'errorGeneric',
      );
    }
    if (householdId.isEmpty) {
      return const AppValidationFailure(
        field: 'householdId',
        messageKey: 'error_household_id_empty',
      );
    }
    if (!_isValidDate(effectiveDate)) {
      return const AppValidationFailure(
        field: 'effectiveDate',
        messageKey: 'error_date_invalid',
      );
    }

    try {
      final ledgerResult = await _ledger.reverseOperation(
        ReverseOperationParams(
          reversalOperationId: reversalOperationId,
          originalOperationId: originalOperationId,
          householdId: householdId,
          effectiveDate: effectiveDate,
          createdBy: createdBy,
          reason: trimmedReason,
        ),
      );

      return switch (ledgerResult) {
        // `alreadyExists` is success, not a conflict: the same reversal id
        // arriving twice is a retried confirm, and the counter-entry it names
        // is already in the ledger.
        IdempotentOperationResult.created ||
        IdempotentOperationResult.alreadyExists => AppOk(reversalOperationId),
        IdempotentOperationResult.conflict => const AppDuplicateConflict(
          messageKey: 'errorReversalConflict',
        ),
      };
    } on OperationNotFoundError {
      return const AppNotFound();
    } on DuplicateReversalError {
      // The original already carries a reversal. Distinct from the id conflict
      // above, and the screen says so — an operation is reversed once.
      return const AppDuplicateConflict(
        messageKey: 'errorOperationAlreadyReversed',
      );
    } on MissingProtectedWithdrawalAuditError {
      // Reversing an operation whose reversal would debit a protected account
      // needs the protected-withdrawal flow, which this use case does not
      // carry. Surfaced rather than silently dropped.
      return const AppValidationFailure(
        field: 'protectedAccount',
        messageKey: 'errorReversalRequiresProtectedAudit',
      );
    } on InsufficientFundsError {
      // The counter-entry would overdraft: money that arrived has since been
      // spent. Real and user-actionable.
      return const AppInsufficientFunds();
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }

  bool _isValidDate(String date) {
    if (date.length != 10) return false;
    try {
      DateTime.parse(date);
      return true;
    } catch (_) {
      return false;
    }
  }
}
