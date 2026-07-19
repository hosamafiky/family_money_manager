import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:uuid/uuid.dart';

/// Executes a money transfer between two accounts.
///
/// Validates: accounts exist, same currency, source ≠ destination,
/// neither archived, amount > 0. Protected source triggers audit.
final class ExecuteTransferUseCase {
  const ExecuteTransferUseCase({
    required LedgerRepository ledgerRepository,
    required AccountRepository accountRepository,
  }) : _ledger = ledgerRepository,
       _accounts = accountRepository;

  final LedgerRepository _ledger;
  final AccountRepository _accounts;

  static const _uuid = Uuid();

  Future<AppResult<String>> execute(TransferContext ctx) async {
    // ── Basic validation ──────────────────────────────────────────────────
    if (ctx.amountMinorUnits <= 0) {
      return const AppValidationFailure(
        field: 'amount',
        messageKey: 'error_amount_must_be_positive',
      );
    }
    if (ctx.sourceAccountId.isEmpty || ctx.destinationAccountId.isEmpty) {
      return const AppValidationFailure(
        field: 'account',
        messageKey: 'error_account_required',
      );
    }
    if (ctx.sourceAccountId == ctx.destinationAccountId) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorSameAccount',
      );
    }
    if (!_isValidDate(ctx.effectiveDate)) {
      return const AppValidationFailure(
        field: 'effectiveDate',
        messageKey: 'error_date_invalid',
      );
    }

    // ── Account validation ────────────────────────────────────────────────
    final source = await _accounts.findById(
      id: ctx.sourceAccountId,
      householdId: ctx.householdId,
    );
    if (source == null) return const AppNotFound();
    // Goal reserve accounts are managed exclusively by goal use cases.
    if (source.type == FinancialAccountType.goalReserve) {
      return const AppValidationFailure(
        field: 'sourceAccountId',
        messageKey: 'errorGoalReserveNotAllowedInOrdinaryTransaction',
      );
    }
    if (source.isArchived) {
      return const AppValidationFailure(
        field: 'sourceAccountId',
        messageKey: 'errorAccountArchived',
      );
    }

    final destination = await _accounts.findById(
      id: ctx.destinationAccountId,
      householdId: ctx.householdId,
    );
    if (destination == null) return const AppNotFound();
    // Goal reserve accounts are managed exclusively by goal use cases.
    if (destination.type == FinancialAccountType.goalReserve) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorGoalReserveNotAllowedInOrdinaryTransaction',
      );
    }
    if (destination.isArchived) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorAccountArchived',
      );
    }
    if (source.currencyCode != destination.currencyCode) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    }
    if (source.currencyCode != ctx.currencyCode) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    }

    // ── Protected-fund audit validation ───────────────────────────────────
    ChildWithdrawalAuditParams? auditParams;
    if (source.requiresWithdrawalAudit) {
      final audit = ctx.childWithdrawalAudit;
      if (audit == null) {
        return const AppValidationFailure(
          field: 'childWithdrawalAudit',
          messageKey: 'errorWithdrawalReasonRequired',
        );
      }
      if (audit.reason.trim().isEmpty) {
        return const AppValidationFailure(
          field: 'reason',
          messageKey: 'errorWithdrawalReasonRequired',
        );
      }
      if (!audit.warningAcknowledged) {
        return const AppValidationFailure(
          field: 'warningAcknowledged',
          messageKey: 'errorWithdrawalAcknowledgmentRequired',
        );
      }
      if (!audit.confirmed) {
        return const AppValidationFailure(
          field: 'confirmed',
          messageKey: 'errorWithdrawalConfirmationRequired',
        );
      }

      auditParams = ChildWithdrawalAuditParams(
        auditId: _uuid.v4(),
        operationId: ctx.operationId,
        householdId: ctx.householdId,
        accountId: ctx.sourceAccountId,
        amountMinorUnits: ctx.amountMinorUnits,
        reason: audit.reason,
        beneficiary: HouseholdMemberRole.child,
        confirmedAt: DateTime.now().toUtc(),
        confirmedBy: ctx.createdBy,
        warningShown: audit.warningAcknowledged,
      );
    }

    // ── Map to ledger params ──────────────────────────────────────────────
    try {
      final params = ExecuteTransferParams(
        operationId: ctx.operationId,
        idempotencyKey: ctx.resolvedIdempotencyKey,
        householdId: ctx.householdId,
        sourceAccountId: ctx.sourceAccountId,
        destinationAccountId: ctx.destinationAccountId,
        amountMinorUnits: ctx.amountMinorUnits,
        currencyCode: ctx.currencyCode,
        effectiveDate: ctx.effectiveDate,
        createdBy: ctx.createdBy,
        description: ctx.note,
      );

      final ledgerResult = await _ledger.executeTransfer(
        params,
        auditParams: auditParams,
      );

      return switch (ledgerResult) {
        IdempotentOperationResult.created => AppOk(ctx.operationId),
        IdempotentOperationResult.alreadyExists => AppOk(ctx.operationId),
        IdempotentOperationResult.conflict => const AppDuplicateConflict(
          messageKey: 'error_account_duplicate',
        ),
      };
    } on InsufficientFundsError {
      return const AppInsufficientFunds();
    } on SameAccountTransferError {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorSameAccount',
      );
    } on CurrencyMismatchTransferError {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    } on ArchivedAccountError {
      return const AppValidationFailure(
        field: 'sourceAccountId',
        messageKey: 'errorAccountArchived',
      );
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
