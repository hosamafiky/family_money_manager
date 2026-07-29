/// Spouse wallet report screen.
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

class SpouseWalletReportScreen extends ConsumerWidget {
  const SpouseWalletReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(spouseWalletReportProvider(req));

    void retry() => ref.invalidate(spouseWalletReportProvider(req));

    return AppScreenScaffold(
      title: Text(l10n.reportSpouseWalletTitle),
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
                if (result is! AppOk<List<SpouseWalletReport>>) {
                  return AppErrorState(
                    message: l10n.reportError,
                    onRetry: retry,
                    retryLabel: l10n.reportRefresh,
                  );
                }
                final wallets = result.value;
                if (wallets.isEmpty) {
                  return AppEmptyState(title: l10n.reportEmpty);
                }
                return _SpouseWalletContent(wallets: wallets, l10n: l10n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpouseWalletContent extends StatelessWidget {
  const _SpouseWalletContent({required this.wallets, required this.l10n});

  final List<SpouseWalletReport> wallets;
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
                AppInlineNotice(message: l10n.reportTransferNote),
                const SizedBox(height: AppTheme.space8),
                AppInlineNotice(message: l10n.reportCurrencySeparate),
              ],
            ),
          ),
          for (final wallet in wallets) _WalletFlow(wallet: wallet, l10n: l10n),
          const SizedBox(height: AppTheme.space24),
        ],
      ),
    );
  }
}

class _WalletFlow extends StatelessWidget {
  const _WalletFlow({required this.wallet, required this.l10n});

  final SpouseWalletReport wallet;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: wallet.accountName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: wallet.accountName),
          balanceRow(
            label: l10n.reportOpeningBalance,
            minorUnits: wallet.openingBalanceMinorUnits,
            currencyCode: wallet.currencyCode,
          ),
          // Funding and returning are both moves between the household's own
          // accounts. Only the middle line is real spending — which is the
          // whole point of this report, and was previously obscured by
          // funding being tinted as income.
          if (wallet.periodFundedMinorUnits != 0)
            flowRow(
              label: l10n.reportFunded,
              magnitudeMinorUnits: wallet.periodFundedMinorUnits,
              currencyCode: wallet.currencyCode,
              direction: FinancialAmountDirection.internal,
              tone: FinancialAmountTone.transfer,
            ),
          if (wallet.periodSpentMinorUnits != 0)
            flowRow(
              label: l10n.reportSpent,
              magnitudeMinorUnits: wallet.periodSpentMinorUnits,
              currencyCode: wallet.currencyCode,
              direction: FinancialAmountDirection.outflow,
              tone: FinancialAmountTone.expense,
            ),
          if (wallet.periodReturnedMinorUnits != 0)
            flowRow(
              label: l10n.reportReturned,
              magnitudeMinorUnits: wallet.periodReturnedMinorUnits,
              currencyCode: wallet.currencyCode,
              direction: FinancialAmountDirection.internal,
              tone: FinancialAmountTone.transfer,
            ),
          if (wallet.periodReversalEffectMinorUnits != 0)
            signedFlowRow(
              label: l10n.reportReversalEffect,
              signedMinorUnits: wallet.periodReversalEffectMinorUnits,
              currencyCode: wallet.currencyCode,
              tone: FinancialAmountTone.muted,
            ),
          balanceRow(
            label: l10n.reportPeriodClosingBalance,
            minorUnits: wallet.periodClosingBalanceMinorUnits,
            currencyCode: wallet.currencyCode,
            isEmphasised: true,
          ),
          balanceRow(
            label: l10n.reportCurrentBalance,
            minorUnits: wallet.currentBalanceMinorUnits,
            currencyCode: wallet.currencyCode,
            isEmphasised: true,
            showDivider: false,
          ),
          if (wallet.periodClosingBalanceMinorUnits !=
              wallet.currentBalanceMinorUnits) ...[
            const SizedBox(height: AppTheme.space8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: AppInlineNotice(message: l10n.reportReversalNote),
            ),
          ],
        ],
      ),
    );
  }
}
