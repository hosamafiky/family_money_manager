/// Home savings flow report screen.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeSavingsReportScreen extends ConsumerWidget {
  const HomeSavingsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(homeSavingsReportProvider(req));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportHomeSavingsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reportRefresh,
            onPressed: () => ref.invalidate(homeSavingsReportProvider(req)),
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
                onRetry: () => ref.invalidate(homeSavingsReportProvider(req)),
              ),
              data: (result) {
                if (result is! AppOk<List<HomeSavingsFlowSummary>>) {
                  return ReportErrorState(
                    onRetry: () =>
                        ref.invalidate(homeSavingsReportProvider(req)),
                  );
                }
                final accounts = result.value;
                if (accounts.isEmpty) return const ReportEmptyState();
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ReportInfoNote(text: l10n.reportCurrencySeparate),
        ReportInfoNote(text: l10n.reportTransferNote),
        for (final account in accounts) ...[
          _HomeSavingsCard(account: account, l10n: l10n),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _HomeSavingsCard extends StatelessWidget {
  const _HomeSavingsCard({required this.account, required this.l10n});

  final HomeSavingsFlowSummary account;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.accountName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ReportAmountRow(
              label: l10n.reportOpeningBalance,
              minorUnits: account.openingBalanceMinorUnits,
              currencyCode: account.currencyCode,
            ),
            if (account.directIncomeMinorUnits != 0)
              ReportAmountRow(
                label: l10n.dashboardPeriodIncome,
                minorUnits: account.directIncomeMinorUnits,
                currencyCode: account.currencyCode,
                color: colors.income,
                icon: Icons.arrow_downward,
              ),
            if (account.directExpenseMinorUnits != 0)
              ReportAmountRow(
                label: l10n.dashboardPeriodExpenses,
                minorUnits: -account.directExpenseMinorUnits,
                currencyCode: account.currencyCode,
                color: colors.expense,
                icon: Icons.arrow_upward,
              ),
            if (account.spouseWalletFundingMinorUnits != 0)
              ReportAmountRow(
                label: '${l10n.reportSpouseWalletTitle} (${l10n.reportFunded})',
                minorUnits: -account.spouseWalletFundingMinorUnits,
                currencyCode: account.currencyCode,
                color: colors.transfer,
                icon: Icons.north_east,
              ),
            if (account.spouseWalletReturnMinorUnits != 0)
              ReportAmountRow(
                label:
                    '${l10n.reportSpouseWalletTitle} (${l10n.reportReturned})',
                minorUnits: account.spouseWalletReturnMinorUnits,
                currencyCode: account.currencyCode,
                color: colors.transfer,
                icon: Icons.south_west,
              ),
            if (account.adjustmentsMinorUnits != 0)
              ReportAmountRow(
                label: l10n.transactionTypeAdjustment,
                minorUnits: account.adjustmentsMinorUnits,
                currencyCode: account.currencyCode,
                icon: Icons.tune,
              ),
            if (account.reversalEffectMinorUnits != 0)
              ReportAmountRow(
                label: l10n.reportReversalEffect,
                minorUnits: account.reversalEffectMinorUnits,
                currencyCode: account.currencyCode,
                color: colors.secondaryText,
                icon: Icons.undo,
              ),
            const Divider(height: 12),
            ReportAmountRow(
              label: l10n.reportPeriodClosingBalance,
              minorUnits: account.closingBalanceMinorUnits,
              currencyCode: account.currencyCode,
              bold: true,
            ),
            ReportAmountRow(
              label: l10n.reportCurrentBalance,
              minorUnits: account.currentBalanceMinorUnits,
              currencyCode: account.currencyCode,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}
