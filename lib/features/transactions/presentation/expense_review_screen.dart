import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Read-only review screen for an expense transaction.
class ExpenseReviewScreen extends ConsumerWidget {
  const ExpenseReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ctx = ref.watch(stagedExpenseContextProvider);
    final submitting = ref.watch(submittingProvider);

    if (ctx == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pop();
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Row(l10n.fieldPaymentAccount, ctx.paymentAccountId),
          _Row(l10n.fieldAmount, ctx.amountMinorUnits.toString()),
          _Row(l10n.fieldCategory, ctx.category.code),
          _Row(l10n.fieldSpender, ctx.spenderMemberId),
          _Row(l10n.fieldBeneficiary, ctx.beneficiaryMemberId),
          _Row(l10n.fieldScope, ctx.scope.code),
          _Row(
            l10n.fieldRecurring,
            ctx.isRecurring ? l10n.recurringYes : l10n.recurringOneTime,
          ),
          _Row(l10n.fieldEffectiveDate, ctx.effectiveDate),
          if (ctx.note != null) _Row(l10n.fieldNote, ctx.note!),
          if (ctx.childWithdrawalAudit != null)
            _Row(l10n.fieldWithdrawalReason, ctx.childWithdrawalAudit!.reason),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: submitting
                ? null
                : () => _submit(context, ref, l10n, ctx),
            child: submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ExpenseContext ctx,
  ) async {
    ref.read(submittingProvider.notifier).setSubmitting(true);
    try {
      final useCase = ref.read(recordExpenseUseCaseProvider);
      final result = await useCase.execute(ctx);

      if (!context.mounted) return;

      switch (result) {
        case AppOk():
          ref.read(expenseFormKeyProvider.notifier).regenerateKey();
          ref.read(stagedExpenseContextProvider.notifier).set(null);
          ref.invalidate(
            transactionListProvider((_householdId, const TransactionFilter())),
          );
          context.go('/transactions');
        case AppInsufficientFunds():
          _snack(context, l10n.errorInsufficientFunds);
        case AppValidationFailure(:final messageKey):
          _snack(context, _msg(l10n, messageKey));
        case AppDuplicateConflict():
          _snack(context, l10n.errorAccountDuplicate);
        default:
          _snack(context, l10n.errorGeneric);
      }
    } finally {
      if (context.mounted) {
        ref.read(submittingProvider.notifier).setSubmitting(false);
      }
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _msg(AppLocalizations l10n, String key) => switch (key) {
    'errorInsufficientFunds' => l10n.errorInsufficientFunds,
    'errorAccountArchived' => l10n.errorAccountArchived,
    'errorCurrencyMismatch' => l10n.errorCurrencyMismatch,
    'errorWithdrawalReasonRequired' => l10n.errorWithdrawalReasonRequired,
    'errorWithdrawalAcknowledgmentRequired' =>
      l10n.errorWithdrawalAcknowledgmentRequired,
    'errorWithdrawalConfirmationRequired' =>
      l10n.errorWithdrawalConfirmationRequired,
    _ => l10n.errorGeneric,
  };
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
