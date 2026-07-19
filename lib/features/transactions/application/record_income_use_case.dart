import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';

/// Records an income credit on the destination account.
///
/// Validates the context, maps to ledger params, and maps the result
/// to [AppResult]. No raw exceptions escape to the caller.
final class RecordIncomeUseCase {
  const RecordIncomeUseCase({
    required LedgerRepository ledgerRepository,
    required AccountRepository accountRepository,
  }) : _ledger = ledgerRepository,
       _accounts = accountRepository;

  final LedgerRepository _ledger;
  final AccountRepository _accounts;

  Future<AppResult<String>> execute(IncomeContext ctx) async {
    // ── Validate ──────────────────────────────────────────────────────────
    if (ctx.amountMinorUnits <= 0) {
      return const AppValidationFailure(
        field: 'amount',
        messageKey: 'error_amount_must_be_positive',
      );
    }
    if (!ctx.category.isIncome) {
      return const AppValidationFailure(
        field: 'category',
        messageKey: 'errorCategoryRequired',
      );
    }
    if (ctx.householdId.isEmpty) {
      return const AppValidationFailure(
        field: 'householdId',
        messageKey: 'error_household_id_empty',
      );
    }
    if (ctx.destinationAccountId.isEmpty) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'error_account_required',
      );
    }
    if (!_isValidDate(ctx.effectiveDate)) {
      return const AppValidationFailure(
        field: 'effectiveDate',
        messageKey: 'error_date_invalid',
      );
    }

    // ── Account existence + household scoping ─────────────────────────────
    final account = await _accounts.findById(
      id: ctx.destinationAccountId,
      householdId: ctx.householdId,
    );
    if (account == null) {
      return const AppNotFound();
    }
    // Goal reserve accounts are managed exclusively by goal use cases.
    if (account.type == FinancialAccountType.goalReserve) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorGoalReserveNotAllowedInOrdinaryTransaction',
      );
    }
    if (account.isArchived) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorAccountArchived',
      );
    }
    if (account.currencyCode != ctx.currencyCode) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    }

    // ── Map and call ledger ───────────────────────────────────────────────
    try {
      final params = RecordIncomeParams(
        operationId: ctx.operationId,
        idempotencyKey: ctx.resolvedIdempotencyKey,
        householdId: ctx.householdId,
        destinationAccountId: ctx.destinationAccountId,
        amountMinorUnits: ctx.amountMinorUnits,
        currencyCode: ctx.currencyCode,
        effectiveDate: ctx.effectiveDate,
        createdBy: ctx.createdBy,
        categoryCode: ctx.category.code,
        description: ctx.note,
        beneficiaryMemberId: null,
        spenderMemberId: null,
      );

      final ledgerResult = await _ledger.recordIncome(params);

      return switch (ledgerResult) {
        IdempotentOperationResult.created => AppOk(ctx.operationId),
        IdempotentOperationResult.alreadyExists => AppOk(ctx.operationId),
        IdempotentOperationResult.conflict => const AppDuplicateConflict(
          messageKey: 'error_account_duplicate',
        ),
      };
    } on ArchivedAccountError {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorAccountArchived',
      );
    } on InsufficientFundsError {
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
