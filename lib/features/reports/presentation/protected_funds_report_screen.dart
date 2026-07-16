/// Protected funds report screen.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProtectedFundsReportScreen extends ConsumerWidget {
  const ProtectedFundsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(protectedFundsReportProvider(req));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportProtectedFundsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reportRefresh,
            onPressed: () => ref.invalidate(protectedFundsReportProvider(req)),
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
                onRetry: () =>
                    ref.invalidate(protectedFundsReportProvider(req)),
              ),
              data: (result) {
                if (result is! AppOk<List<ProtectedFundsSummary>>) {
                  return ReportErrorState(
                    onRetry: () =>
                        ref.invalidate(protectedFundsReportProvider(req)),
                  );
                }
                final funds = result.value;
                if (funds.isEmpty) return const ReportEmptyState();
                return _ProtectedFundsContent(funds: funds, l10n: l10n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtectedFundsContent extends StatelessWidget {
  const _ProtectedFundsContent({required this.funds, required this.l10n});

  final List<ProtectedFundsSummary> funds;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ReportInfoNote(text: l10n.reportCurrencySeparate),
        for (final fund in funds) ...[
          _FundCard(fund: fund, l10n: l10n),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FundCard extends StatelessWidget {
  const _FundCard({required this.fund, required this.l10n});

  final ProtectedFundsSummary fund;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fund.accountName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ReportAmountRow(
              label: l10n.reportOpeningBalance,
              minorUnits: fund.openingBalanceMinorUnits,
              currencyCode: fund.currencyCode,
            ),
            if (fund.fundingMinorUnits != 0)
              ReportAmountRow(
                label: l10n.reportFunded,
                minorUnits: fund.fundingMinorUnits,
                currencyCode: fund.currencyCode,
                color: Colors.green,
                icon: Icons.arrow_downward,
              ),
            if (fund.withdrawalMinorUnits != 0)
              ReportAmountRow(
                label: l10n.reportWithdrawals,
                minorUnits: -fund.withdrawalMinorUnits,
                currencyCode: fund.currencyCode,
                color: Colors.red,
                icon: Icons.arrow_upward,
              ),
            if (fund.reversalEffectMinorUnits != 0)
              ReportAmountRow(
                label: l10n.reportReversalEffect,
                minorUnits: fund.reversalEffectMinorUnits,
                currencyCode: fund.currencyCode,
                color: Colors.orange,
                icon: Icons.undo,
              ),
            const Divider(height: 12),
            ReportAmountRow(
              label: l10n.reportPeriodClosingBalance,
              minorUnits: fund.closingBalanceMinorUnits,
              currencyCode: fund.currencyCode,
              bold: true,
            ),
            ReportAmountRow(
              label: l10n.reportCurrentBalance,
              minorUnits: fund.currentBalanceMinorUnits,
              currencyCode: fund.currencyCode,
              bold: true,
            ),
            if (fund.withdrawalAudits.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.reportWithdrawals,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              ...fund.withdrawalAudits.map(
                (audit) => _AuditRow(audit: audit, l10n: l10n),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.audit, required this.l10n});

  final WithdrawalAuditSummary audit;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        audit.isReversed ? Icons.undo : Icons.arrow_upward,
        color: audit.isReversed ? Colors.orange : Colors.red,
        size: 18,
      ),
      title: Text(audit.reason, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${l10n.reportBeneficiary}: ${audit.beneficiaryMemberId}  •  ${audit.effectiveDate}',
      ),
      trailing: ReportAmountText(
        minorUnits: audit.amountMinorUnits,
        currencyCode: audit.currencyCode,
        color: audit.isReversed ? Colors.orange : Colors.red,
      ),
    );
  }
}
