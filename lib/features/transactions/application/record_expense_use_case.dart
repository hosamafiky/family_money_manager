import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/household/data/household_repository.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/domain/child_withdrawal_context.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:uuid/uuid.dart';

/// Records an expense debit on the payment account.
///
/// Enforces scope/beneficiary consistency, protected-account audit
/// requirements, and all amount/category validations.
final class RecordExpenseUseCase {
  const RecordExpenseUseCase({
    required LedgerRepository ledgerRepository,
    required AccountRepository accountRepository,
    required HouseholdRepository householdRepository,
  }) : _ledger = ledgerRepository,
       _accounts = accountRepository,
       _household = householdRepository;

  final LedgerRepository _ledger;
  final AccountRepository _accounts;
  final HouseholdRepository _household;

  static const _uuid = Uuid();

  Future<AppResult<String>> execute(ExpenseContext ctx) async {
    // ── Basic validation ──────────────────────────────────────────────────
    if (ctx.amountMinorUnits <= 0) {
      return const AppValidationFailure(
        field: 'amount',
        messageKey: 'error_amount_must_be_positive',
      );
    }
    if (!ctx.category.isExpense) {
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
    if (ctx.paymentAccountId.isEmpty) {
      return const AppValidationFailure(
        field: 'paymentAccountId',
        messageKey: 'error_account_required',
      );
    }
    if (ctx.spenderMemberId.isEmpty) {
      return const AppValidationFailure(
        field: 'spender',
        messageKey: 'errorSpenderRequired',
      );
    }
    if (ctx.beneficiaryMemberId.isEmpty) {
      return const AppValidationFailure(
        field: 'beneficiary',
        messageKey: 'errorBeneficiaryRequired',
      );
    }
    if (!_isValidDate(ctx.effectiveDate)) {
      return const AppValidationFailure(
        field: 'effectiveDate',
        messageKey: 'error_date_invalid',
      );
    }

    // ── Account validation ────────────────────────────────────────────────
    final account = await _accounts.findById(
      id: ctx.paymentAccountId,
      householdId: ctx.householdId,
    );
    if (account == null) return const AppNotFound();
    if (account.isArchived) {
      return const AppValidationFailure(
        field: 'paymentAccountId',
        messageKey: 'errorAccountArchived',
      );
    }
    if (account.currencyCode != ctx.currencyCode) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    }

    // ── Scope/beneficiary consistency ─────────────────────────────────────
    final members = await _household.listMembers(ctx.householdId);
    final beneficiary = members
        .where((m) => m.id == ctx.beneficiaryMemberId)
        .firstOrNull;
    if (beneficiary == null) return const AppNotFound();

    final scopeValidation = _validateScope(ctx.scope, beneficiary.role);
    if (scopeValidation != null) return scopeValidation;

    // ── Protected-fund audit validation ───────────────────────────────────
    ChildWithdrawalAuditParams? auditParams;
    if (account.requiresWithdrawalAudit) {
      final audit = ctx.childWithdrawalAudit;
      if (audit == null) {
        return const AppValidationFailure(
          field: 'childWithdrawalAudit',
          messageKey: 'errorWithdrawalReasonRequired',
        );
      }
      final auditValidation = _validateAudit(audit);
      if (auditValidation != null) return auditValidation;

      auditParams = ChildWithdrawalAuditParams(
        auditId: _uuid.v4(),
        operationId: ctx.operationId,
        householdId: ctx.householdId,
        accountId: ctx.paymentAccountId,
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
      final params = RecordExpenseParams(
        operationId: ctx.operationId,
        idempotencyKey: ctx.resolvedIdempotencyKey,
        householdId: ctx.householdId,
        sourceAccountId: ctx.paymentAccountId,
        amountMinorUnits: ctx.amountMinorUnits,
        currencyCode: ctx.currencyCode,
        effectiveDate: ctx.effectiveDate,
        createdBy: ctx.createdBy,
        categoryCode: ctx.category.code,
        description: ctx.note,
        scope: ctx.scope,
        spenderMemberId: ctx.spenderMemberId,
        beneficiaryMemberId: ctx.beneficiaryMemberId,
        isRecurring: ctx.isRecurring,
      );

      final ledgerResult = await _ledger.recordExpense(
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
    } on ArchivedAccountError {
      return const AppValidationFailure(
        field: 'paymentAccountId',
        messageKey: 'errorAccountArchived',
      );
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }

  AppResult<String>? _validateScope(
    ExpenseScope scope,
    MemberRole beneficiaryRole,
  ) {
    switch (scope) {
      case ExpenseScope.child:
        if (beneficiaryRole != MemberRole.child) {
          return const AppValidationFailure(
            field: 'beneficiary',
            messageKey: 'errorBeneficiaryRequired',
          );
        }
      case ExpenseScope.spouse:
        if (beneficiaryRole != MemberRole.spouse) {
          return const AppValidationFailure(
            field: 'beneficiary',
            messageKey: 'errorBeneficiaryRequired',
          );
        }
      case ExpenseScope.personal:
      case ExpenseScope.household:
      case ExpenseScope.shared:
        break;
    }
    return null;
  }

  AppResult<String>? _validateAudit(ChildWithdrawalContext audit) {
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
    return null;
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
