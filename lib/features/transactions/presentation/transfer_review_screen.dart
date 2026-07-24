import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
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
      data: (r) =>
          r is AppOk<List<FinancialAccount>> ? r.value : <FinancialAccount>[],
      orElse: () => <FinancialAccount>[],
    );

    String accountName(String id) =>
        accounts.where((a) => a.id == id).firstOrNull?.name ?? id;

    String formatAmount(int minor, String code) {
      final currency = Currency.fromCode(code);
      final money = Money(minorUnits: minor, currency: currency);
      return '${MoneyInputFormatter.format(money)} $code';
    }

    return AppScreenScaffold(
      title: Text(l10n.reviewTitle),
      bottomBar: AppBottomActionBar(
        child: PrimaryActionButton(
          label: l10n.confirm,
          isLoading: submitting,
          onPressed: submitting ? null : () => _submit(context, ref, l10n, ctx),
        ),
      ),
      body: ResponsiveContentContainer(
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            top: AppTheme.space16,
            bottom: AppTheme.space32,
          ),
          children: [
            AppInlineNotice(
              message: l10n.transferInternalExplanation,
              tone: AppNoticeTone.info,
            ),
            if (ctx.childWithdrawalAudit != null) ...[
              const SizedBox(height: AppTheme.space12),
              AppInlineNotice(
                message: l10n.protectedWithdrawalReviewNote,
                tone: AppNoticeTone.warning,
              ),
            ],
            const SizedBox(height: AppTheme.space16),
            AppReviewSection(
              title: l10n.reviewTitle,
              rows: [
                AppReviewRowData(
                  label: l10n.fieldOperationType,
                  value: l10n.operationTypeTransfer,
                ),
                AppReviewRowData(
                  label: l10n.fieldAmount,
                  value: formatAmount(ctx.amountMinorUnits, ctx.currencyCode),
                ),
                AppReviewRowData(
                  label: l10n.fieldSourceAccount,
                  value: accountName(ctx.sourceAccountId),
                ),
                AppReviewRowData(
                  label: l10n.fieldDestinationAccount,
                  value: accountName(ctx.destinationAccountId),
                ),
                AppReviewRowData(
                  label: l10n.fieldEffectiveDate,
                  value: ctx.effectiveDate,
                ),
                if (ctx.note != null)
                  AppReviewRowData(label: l10n.fieldNote, value: ctx.note!),
                if (ctx.childWithdrawalAudit != null)
                  AppReviewRowData(
                    label: l10n.fieldWithdrawalReason,
                    value: ctx.childWithdrawalAudit!.reason,
                  ),
              ],
            ),
          ],
        ),
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
          invalidateTransactionMoneyProviders(ref);
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
    'errorWithdrawalAcknowledgmentRequired' =>
      l10n.errorWithdrawalAcknowledgmentRequired,
    'errorWithdrawalConfirmationRequired' =>
      l10n.errorWithdrawalConfirmationRequired,
    _ => l10n.errorGeneric,
  };
}
