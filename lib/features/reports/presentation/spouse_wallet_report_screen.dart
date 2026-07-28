/// Spouse wallet report screen.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpouseWalletReportScreen extends ConsumerWidget {
  const SpouseWalletReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(spouseWalletReportProvider(req));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportSpouseWalletTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reportRefresh,
            onPressed: () => ref.invalidate(spouseWalletReportProvider(req)),
          ),
        ],
      ),
      body: Column(
        children: [
          const ReportPeriodSelector(),
          const Divider(height: 1),
          Expanded(
            child: reportAsync.when(
              loading: () => const ReportLoading(),
              error: (_, _) => ReportErrorState(
                onRetry: () => ref.invalidate(spouseWalletReportProvider(req)),
              ),
              data: (result) {
                if (result is! AppOk<List<SpouseWalletReport>>) {
                  return ReportErrorState(
                    onRetry: () =>
                        ref.invalidate(spouseWalletReportProvider(req)),
                  );
                }
                final wallets = result.value;
                if (wallets.isEmpty) return const ReportEmptyState();
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ReportInfoNote(text: l10n.reportTransferNote),
        ReportInfoNote(text: l10n.reportCurrencySeparate),
        for (final wallet in wallets) ...[
          _WalletCard(wallet: wallet, l10n: l10n),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.wallet, required this.l10n});

  final SpouseWalletReport wallet;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    return Semantics(
      label: wallet.accountName,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.accountName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ReportAmountRow(
                label: l10n.reportOpeningBalance,
                minorUnits: wallet.openingBalanceMinorUnits,
                currencyCode: wallet.currencyCode,
              ),
              if (wallet.periodFundedMinorUnits != 0)
                ReportAmountRow(
                  label: l10n.reportFunded,
                  minorUnits: wallet.periodFundedMinorUnits,
                  currencyCode: wallet.currencyCode,
                  color: colors.income,
                  icon: Icons.south_west,
                ),
              if (wallet.periodSpentMinorUnits != 0)
                ReportAmountRow(
                  label: l10n.reportSpent,
                  minorUnits: -wallet.periodSpentMinorUnits,
                  currencyCode: wallet.currencyCode,
                  color: colors.expense,
                  icon: Icons.arrow_upward,
                ),
              if (wallet.periodReturnedMinorUnits != 0)
                ReportAmountRow(
                  label: l10n.reportReturned,
                  minorUnits: -wallet.periodReturnedMinorUnits,
                  currencyCode: wallet.currencyCode,
                  color: colors.transfer,
                  icon: Icons.north_east,
                ),
              if (wallet.periodReversalEffectMinorUnits != 0)
                ReportAmountRow(
                  label: l10n.reportReversalEffect,
                  minorUnits: wallet.periodReversalEffectMinorUnits,
                  currencyCode: wallet.currencyCode,
                  color: colors.secondaryText,
                  icon: Icons.undo,
                ),
              const Divider(height: 12),
              ReportAmountRow(
                label: l10n.reportPeriodClosingBalance,
                minorUnits: wallet.periodClosingBalanceMinorUnits,
                currencyCode: wallet.currencyCode,
                bold: true,
              ),
              ReportAmountRow(
                label: l10n.reportCurrentBalance,
                minorUnits: wallet.currentBalanceMinorUnits,
                currencyCode: wallet.currencyCode,
                bold: true,
              ),
              if (wallet.periodClosingBalanceMinorUnits !=
                  wallet.currentBalanceMinorUnits)
                ReportInfoNote(text: l10n.reportReversalNote),
            ],
          ),
        ),
      ),
    );
  }
}
