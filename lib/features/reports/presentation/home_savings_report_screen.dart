/// Home savings flow report screen.
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

class HomeSavingsReportScreen extends ConsumerWidget {
  const HomeSavingsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(homeSavingsReportProvider(req));

    void retry() => ref.invalidate(homeSavingsReportProvider(req));

    return AppScreenScaffold(
      title: Text(l10n.reportHomeSavingsTitle),
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
                if (result is! AppOk<List<HomeSavingsFlowSummary>>) {
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
                return _HomeSavingsContent(accounts: accounts, l10n: l10n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSavingsContent extends StatelessWidget {
  const _HomeSavingsContent({required this.accounts, required this.l10n});

  final List<HomeSavingsFlowSummary> accounts;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContentContainer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: Column(
              children: [
                AppInlineNotice(message: l10n.reportCurrencySeparate),
                const SizedBox(height: AppTheme.space8),
                AppInlineNotice(message: l10n.reportTransferNote),
              ],
            ),
          ),
          for (final account in accounts)
            _HomeSavingsFlow(account: account, l10n: l10n),
          const SizedBox(height: AppTheme.space24),
        ],
      ),
    );
  }
}

class _HomeSavingsFlow extends StatelessWidget {
  const _HomeSavingsFlow({required this.account, required this.l10n});

  final HomeSavingsFlowSummary account;
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
        if (account.directIncomeMinorUnits != 0)
          flowRow(
            label: l10n.dashboardPeriodIncome,
            magnitudeMinorUnits: account.directIncomeMinorUnits,
            currencyCode: account.currencyCode,
            direction: FinancialAmountDirection.inflow,
            tone: FinancialAmountTone.income,
          ),
        if (account.directExpenseMinorUnits != 0)
          flowRow(
            label: l10n.dashboardPeriodExpenses,
            magnitudeMinorUnits: account.directExpenseMinorUnits,
            currencyCode: account.currencyCode,
            direction: FinancialAmountDirection.outflow,
            tone: FinancialAmountTone.expense,
          ),
        // Funding a spouse wallet moves money between the household's own
        // accounts, so both legs carry the internal glyph and neither is
        // spending. The label says which leg it is.
        if (account.spouseWalletFundingMinorUnits != 0)
          flowRow(
            label: l10n.reportSpouseWalletFunded,
            magnitudeMinorUnits: account.spouseWalletFundingMinorUnits,
            currencyCode: account.currencyCode,
            direction: FinancialAmountDirection.internal,
            tone: FinancialAmountTone.transfer,
          ),
        if (account.spouseWalletReturnMinorUnits != 0)
          flowRow(
            label: l10n.reportSpouseWalletReturned,
            magnitudeMinorUnits: account.spouseWalletReturnMinorUnits,
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
          label: l10n.reportPeriodClosingBalance,
          minorUnits: account.closingBalanceMinorUnits,
          currencyCode: account.currencyCode,
          isEmphasised: true,
        ),
        balanceRow(
          label: l10n.reportCurrentBalance,
          minorUnits: account.currentBalanceMinorUnits,
          currencyCode: account.currencyCode,
          isEmphasised: true,
          showDivider: false,
        ),
      ],
    );
  }
}
