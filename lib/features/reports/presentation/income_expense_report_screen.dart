/// Income & Expense report screen.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows gross/net income and expense flows per currency for the selected period.
class IncomeExpenseReportScreen extends ConsumerWidget {
  const IncomeExpenseReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(incomeExpenseReportProvider(req));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportIncomeExpenseTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reportRefresh,
            onPressed: () => ref.invalidate(incomeExpenseReportProvider(req)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportPeriodSelector(),
          const Divider(height: 1),
          Expanded(
            child: reportAsync.when(
              loading: () => const ReportLoading(),
              error: (_, _) => ReportErrorState(
                onRetry: () => ref.invalidate(incomeExpenseReportProvider(req)),
              ),
              data: (result) {
                if (result is! AppOk<List<CurrencyFlowSummary>>) {
                  return ReportErrorState(
                    onRetry: () =>
                        ref.invalidate(incomeExpenseReportProvider(req)),
                  );
                }
                final flows = result.value;
                if (flows.isEmpty) return const ReportEmptyState();
                return _IncomeExpenseContent(flows: flows, l10n: l10n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseContent extends StatelessWidget {
  const _IncomeExpenseContent({required this.flows, required this.l10n});

  final List<CurrencyFlowSummary> flows;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ReportInfoNote(text: l10n.reportTransferNote),
        ReportInfoNote(text: l10n.reportCurrencySeparate),
        for (final flow in flows) ...[
          CurrencyHeader(currencyCode: flow.currencyCode),
          _FlowCard(flow: flow, l10n: l10n),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({required this.flow, required this.l10n});

  final CurrencyFlowSummary flow;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hasReversals = flow.hasReversalEffect;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income section
            ReportAmountRow(
              label: l10n.reportGrossIncome,
              minorUnits: flow.grossIncomeMinorUnits,
              currencyCode: flow.currencyCode,
              color: Colors.green,
              icon: Icons.arrow_downward,
            ),
            if (flow.incomeReversalMinorUnits != 0)
              ReportAmountRow(
                label: l10n.reportReversalEffect,
                minorUnits: -flow.incomeReversalMinorUnits,
                currencyCode: flow.currencyCode,
                color: Colors.orange,
                icon: Icons.undo,
              ),
            if (hasReversals)
              ReportAmountRow(
                label: l10n.reportNetIncome,
                minorUnits: flow.netIncomeMinorUnits,
                currencyCode: flow.currencyCode,
                color: Colors.green,
                icon: Icons.arrow_downward,
                bold: true,
              ),
            const Divider(height: 12),
            // Expense section
            ReportAmountRow(
              label: l10n.reportGrossExpense,
              minorUnits: flow.grossExpenseMinorUnits,
              currencyCode: flow.currencyCode,
              color: Colors.red,
              icon: Icons.arrow_upward,
            ),
            if (flow.expenseReversalMinorUnits != 0)
              ReportAmountRow(
                label: l10n.reportReversalEffect,
                minorUnits: -flow.expenseReversalMinorUnits,
                currencyCode: flow.currencyCode,
                color: Colors.orange,
                icon: Icons.undo,
              ),
            if (hasReversals)
              ReportAmountRow(
                label: l10n.reportNetExpense,
                minorUnits: flow.netExpenseMinorUnits,
                currencyCode: flow.currencyCode,
                color: Colors.red,
                icon: Icons.arrow_upward,
                bold: true,
              ),
            const Divider(height: 12),
            // Net cash flow
            ReportAmountRow(
              label: l10n.reportNetCashFlow,
              minorUnits: flow.netCashFlowMinorUnits,
              currencyCode: flow.currencyCode,
              color: flow.netCashFlowMinorUnits >= 0
                  ? Colors.green
                  : Colors.red,
              bold: true,
            ),
            if (hasReversals) ...[
              const SizedBox(height: 4),
              ReportInfoNote(text: l10n.reportReversalNote),
            ],
          ],
        ),
      ),
    );
  }
}
