import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Read-only review screen for a transfer transaction.
class TransferReviewScreen extends ConsumerWidget {
  const TransferReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ctx = ref.watch(stagedTransferContextProvider);
    final submitting = ref.watch(submittingProvider);
    final accountsAsync = ref.watch(accountsProvider(_householdId));

    if (ctx == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && context.canPop()) context.pop();
      });
      return const SizedBox.shrink();
    }

    final accounts = accountsAsync.maybeWhen(
      data: (r) => r is AppOk<List<FinancialAccount>> ? r.value : <FinancialAccount>[],
      orElse: () => <FinancialAccount>[],
    );

    String accountName(String id) => accounts.where((a) => a.id == id).firstOrNull?.name ?? id;

    String formatAmount(int minor, String code) {
      final currency = Currency.fromCode(code);
      final money = Money(minorUnits: minor, currency: currency);
      return '${MoneyInputFormatter.format(money)} $code';
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Row(l10n.fieldSourceAccount, accountName(ctx.sourceAccountId)),
          _Row(l10n.fieldDestinationAccount, accountName(ctx.destinationAccountId)),
          _Row(l10n.fieldAmount, formatAmount(ctx.amountMinorUnits, ctx.currencyCode)),
          _Row(l10n.fieldEffectiveDate, ctx.effectiveDate),
          if (ctx.note != null) _Row(l10n.fieldNote, ctx.note!),
          if (ctx.childWithdrawalAudit != null)
            _Row(l10n.fieldWithdrawalReason, ctx.childWithdrawalAudit!.reason),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: submitting ? null : () => _submit(context, ref, l10n, ctx),
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
    TransferContext ctx,
  ) async {
    ref.read(submittingProvider.notifier).setSubmitting(true);
    try {
      final useCase = ref.read(executeTransferUseCaseProvider);
      final result = await useCase.execute(ctx);

      if (!context.mounted) return;

      switch (result) {
        case AppOk():
          ref.read(transferFormKeyProvider.notifier).regenerateKey();
          ref.read(stagedTransferContextProvider.notifier).set(null);
          ref.invalidate(transactionListProvider((_householdId, const TransactionFilter())));
          ref.invalidate(accountsProvider(_householdId));
          ref.invalidate(accountBalanceProvider);
          ref.invalidate(dashboardSummaryProvider(_householdId));
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
    'errorSameAccount' => l10n.errorSameAccount,
    'errorWithdrawalReasonRequired' => l10n.errorWithdrawalReasonRequired,
    'errorWithdrawalAcknowledgmentRequired' => l10n.errorWithdrawalAcknowledgmentRequired,
    'errorWithdrawalConfirmationRequired' => l10n.errorWithdrawalConfirmationRequired,
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
