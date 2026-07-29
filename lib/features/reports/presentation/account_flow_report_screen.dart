/// Account flow report screen — income/expense/transfer flows per account.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_flow_row.dart';
import 'package:family_money_manager/features/reports/presentation/report_period_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountFlowReportScreen extends ConsumerWidget {
  const AccountFlowReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(accountFlowReportProvider(req));

    void retry() => ref.invalidate(accountFlowReportProvider(req));

    return AppScreenScaffold(
      title: Text(l10n.reportAccountsTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.reportRefresh,
          onPressed: retry,
        ),
      ],
      body: Column(
        children: [
          const ReportPeriodSelector(),
          const Divider(height: 1),
          Expanded(
            child: reportAsync.when(
              loading: () => AppLoadingState(message: l10n.loadingLabel),
              error: (_, _) => AppErrorState(
                message: l10n.reportError,
                onRetry: retry,
                retryLabel: l10n.reportRefresh,
              ),
              data: (result) {
                if (result is! AppOk<List<AccountFlowBreakdown>>) {
                  return AppErrorState(
                    message: l10n.reportError,
                    onRetry: retry,
                    retryLabel: l10n.reportRefresh,
                  );
                }
                final accounts = result.value;
                if (accounts.isEmpty) {
                  return AppEmptyState(title: l10n.reportEmpty);
                }
                return _AccountFlowContent(accounts: accounts, l10n: l10n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountFlowContent extends StatelessWidget {
  const _AccountFlowContent({required this.accounts, required this.l10n});

  final List<AccountFlowBreakdown> accounts;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContentContainer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: AppInlineNotice(message: l10n.reportCurrencySeparate),
          ),
          for (final account in accounts)
            _AccountFlow(account: account, l10n: l10n),
          const SizedBox(height: AppTheme.space24),
        ],
      ),
    );
  }
}

class _AccountFlow extends StatelessWidget {
  const _AccountFlow({required this.account, required this.l10n});

  final AccountFlowBreakdown account;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: account.accountName),
        balanceRow(
          label: l10n.reportOpeningBalance,
          minorUnits: account.openingBalanceMinorUnits,
          currencyCode: account.currencyCode,
        ),
        if (account.incomeMinorUnits != 0)
          flowRow(
            label: l10n.dashboardPeriodIncome,
            magnitudeMinorUnits: account.incomeMinorUnits,
            currencyCode: account.currencyCode,
            direction: FinancialAmountDirection.inflow,
            tone: FinancialAmountTone.income,
          ),
        if (account.expenseMinorUnits != 0)
          flowRow(
            label: l10n.dashboardPeriodExpenses,
            magnitudeMinorUnits: account.expenseMinorUnits,
            currencyCode: account.currencyCode,
            direction: FinancialAmountDirection.outflow,
            tone: FinancialAmountTone.expense,
          ),
        // Transfers keep the internal glyph rather than a plus or a minus: a
        // transfer changes no household total, and the label already says
        // which way it went for this account.
        if (account.transfersInMinorUnits != 0)
          flowRow(
            label: l10n.reportTransferIn,
            magnitudeMinorUnits: account.transfersInMinorUnits,
            currencyCode: account.currencyCode,
            direction: FinancialAmountDirection.internal,
            tone: FinancialAmountTone.transfer,
          ),
        if (account.transfersOutMinorUnits != 0)
          flowRow(
            label: l10n.reportTransferOut,
            magnitudeMinorUnits: account.transfersOutMinorUnits,
            currencyCode: account.currencyCode,
            direction: FinancialAmountDirection.internal,
            tone: FinancialAmountTone.transfer,
          ),
        if (account.adjustmentsMinorUnits != 0)
          signedFlowRow(
            label: l10n.transactionTypeAdjustment,
            signedMinorUnits: account.adjustmentsMinorUnits,
            currencyCode: account.currencyCode,
          ),
        if (account.reversalEffectMinorUnits != 0)
          signedFlowRow(
            label: l10n.reportReversalEffect,
            signedMinorUnits: account.reversalEffectMinorUnits,
            currencyCode: account.currencyCode,
            tone: FinancialAmountTone.muted,
          ),
        balanceRow(
          label: l10n.reportClosingBalance,
          minorUnits: account.closingBalanceMinorUnits,
          currencyCode: account.currencyCode,
          isEmphasised: true,
          showDivider: false,
        ),
        // The model has always been able to check its own accounting
        // identity, and nothing ever asked it. A table whose lines do not sum
        // to its own total is the one thing a ledger must never present in
        // silence — so when the identity fails the screen says so, and says
        // what is still trustworthy.
        if (!account.reconciles) ...[
          const SizedBox(height: AppTheme.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: AppInlineNotice(
              message:
                  '${l10n.reportDoesNotReconcile}\n'
                  '${l10n.reportDoesNotReconcileBody}',
              tone: AppNoticeTone.warning,
            ),
          ),
        ],
      ],
    );
  }
}
