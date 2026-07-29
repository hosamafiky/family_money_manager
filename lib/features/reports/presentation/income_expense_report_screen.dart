/// Income & Expense report screen.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_period_selector.dart';
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

    void retry() => ref.invalidate(incomeExpenseReportProvider(req));

    return AppScreenScaffold(
      title: Text(l10n.reportIncomeExpenseTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.reportRefresh,
          onPressed: retry,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                if (result is! AppOk<List<CurrencyFlowSummary>>) {
                  return AppErrorState(
                    message: l10n.reportError,
                    onRetry: retry,
                    retryLabel: l10n.reportRefresh,
                  );
                }
                final flows = result.value;
                if (flows.isEmpty) {
                  return AppEmptyState(title: l10n.reportEmpty);
                }
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
          for (final flow in flows) ...[
            // One section per currency, never a combined total: adding two
            // currencies produces a figure that is true of nothing.
            SectionHeader(title: flow.currencyCode),
            _FlowRows(flow: flow, l10n: l10n),
          ],
          const SizedBox(height: AppTheme.space24),
        ],
      ),
    );
  }
}

class _FlowRows extends StatelessWidget {
  const _FlowRows({required this.flow, required this.l10n});

  final CurrencyFlowSummary flow;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hasReversals = flow.hasReversalEffect;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CurrencyAmountRow(
          label: l10n.reportGrossIncome,
          minorUnits: flow.grossIncomeMinorUnits,
          currencyCode: flow.currencyCode,
          tone: FinancialAmountTone.income,
          direction: FinancialAmountDirection.inflow,
        ),
        if (flow.incomeReversalMinorUnits != 0)
          CurrencyAmountRow(
            label: l10n.reportReversalEffect,
            minorUnits: flow.incomeReversalMinorUnits,
            currencyCode: flow.currencyCode,
            // Reversing an income removes money that had been counted as
            // arriving, so it reads as an outflow — quietly, because a
            // correction is not a threshold.
            tone: FinancialAmountTone.muted,
            direction: FinancialAmountDirection.outflow,
          ),
        if (hasReversals)
          CurrencyAmountRow(
            label: l10n.reportNetIncome,
            minorUnits: flow.netIncomeMinorUnits,
            currencyCode: flow.currencyCode,
            tone: FinancialAmountTone.income,
            direction: FinancialAmountDirection.inflow,
            isEmphasised: true,
          ),
        CurrencyAmountRow(
          label: l10n.reportGrossExpense,
          minorUnits: flow.grossExpenseMinorUnits,
          currencyCode: flow.currencyCode,
          tone: FinancialAmountTone.expense,
          direction: FinancialAmountDirection.outflow,
        ),
        if (flow.expenseReversalMinorUnits != 0)
          CurrencyAmountRow(
            label: l10n.reportReversalEffect,
            minorUnits: flow.expenseReversalMinorUnits,
            currencyCode: flow.currencyCode,
            // The mirror of the line above: reversing an expense returns
            // money that had been counted as spent.
            tone: FinancialAmountTone.muted,
            direction: FinancialAmountDirection.inflow,
          ),
        if (hasReversals)
          CurrencyAmountRow(
            label: l10n.reportNetExpense,
            minorUnits: flow.netExpenseMinorUnits,
            currencyCode: flow.currencyCode,
            tone: FinancialAmountTone.expense,
            direction: FinancialAmountDirection.outflow,
            isEmphasised: true,
          ),
        // Weight, not colour. This figure was previously tinted green or red
        // by its own sign, which puts a verdict on a derived number; the sign
        // and the glyph already say which way it went.
        CurrencyAmountRow(
          label: l10n.reportNetCashFlow,
          minorUnits: flow.netCashFlowMinorUnits.abs(),
          currencyCode: flow.currencyCode,
          direction: flow.netCashFlowMinorUnits >= 0
              ? FinancialAmountDirection.inflow
              : FinancialAmountDirection.outflow,
          isEmphasised: true,
          showDivider: false,
        ),
        if (hasReversals) ...[
          const SizedBox(height: AppTheme.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: AppInlineNotice(message: l10n.reportReversalNote),
          ),
        ],
      ],
    );
  }
}
