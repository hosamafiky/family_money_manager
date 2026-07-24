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
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Read-only review screen for an income transaction.
class IncomeReviewScreen extends ConsumerWidget {
  const IncomeReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ctx = ref.watch(stagedIncomeContextProvider);
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
      resizeToAvoidBottomInset: true,
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
              message: l10n.incomeIncreasesBalance,
              tone: AppNoticeTone.info,
            ),
            const SizedBox(height: AppTheme.space16),
            AppReviewSection(
              title: l10n.reviewTitle,
              rows: [
                AppReviewRowData(
                  label: l10n.fieldOperationType,
                  value: l10n.operationTypeIncome,
                ),
                AppReviewRowData(
                  label: l10n.fieldAmount,
                  value: formatAmount(ctx.amountMinorUnits, ctx.currencyCode),
                ),
                AppReviewRowData(
                  label: l10n.fieldDestinationAccount,
                  value: accountName(ctx.destinationAccountId),
                ),
                AppReviewRowData(
                  label: l10n.fieldCategory,
                  value: categoryLabel(l10n, ctx.category),
                ),
                AppReviewRowData(
                  label: l10n.fieldEffectiveDate,
                  value: ctx.effectiveDate,
                ),
                if (ctx.note != null)
                  AppReviewRowData(label: l10n.fieldNote, value: ctx.note!),
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
    IncomeContext ctx,
  ) async {
    ref.read(submittingProvider.notifier).setSubmitting(true);
    try {
      final useCase = ref.read(recordIncomeUseCaseProvider);
      final result = await useCase.execute(ctx);

      if (!context.mounted) return;

      switch (result) {
        case AppOk():
          ref.read(incomeFormProvider.notifier).regenerateKey();
          ref.read(stagedIncomeContextProvider.notifier).set(null);
          invalidateTransactionMoneyProviders(ref);
          if (context.canPop()) {
            context.go('/transactions');
          } else {
            context.go('/transactions');
          }
        case AppInsufficientFunds():
          _showSnackBar(context, l10n.errorInsufficientFunds);
        case AppValidationFailure(:final messageKey):
          _showSnackBar(context, _resolveMessage(l10n, messageKey));
        case AppDuplicateConflict():
          _showSnackBar(context, l10n.errorAccountDuplicate);
        default:
          _showSnackBar(context, l10n.errorGeneric);
      }
    } finally {
      if (context.mounted) {
        ref.read(submittingProvider.notifier).setSubmitting(false);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _resolveMessage(AppLocalizations l10n, String key) {
    return switch (key) {
      'errorAccountArchived' => l10n.errorAccountArchived,
      'errorCurrencyMismatch' => l10n.errorCurrencyMismatch,
      _ => l10n.errorGeneric,
    };
  }
}
