/// Category report screen — expense and income by category.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/amount_display_formatter.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/reports/application/get_category_report_use_case.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_period_selector.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CategoryReportScreen extends ConsumerWidget {
  const CategoryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(categoryReportProvider(req));

    void retry() => ref.invalidate(categoryReportProvider(req));

    return AppScreenScaffold(
      title: Text(l10n.reportCategoriesTitle),
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
                if (result is! AppOk<CategoryReport>) {
                  return AppErrorState(
                    message: l10n.reportError,
                    onRetry: retry,
                    retryLabel: l10n.reportRefresh,
                  );
                }
                final report = result.value;
                if (report.expenseByCategory.isEmpty &&
                    report.incomeByCategory.isEmpty) {
                  return AppEmptyState(title: l10n.reportEmpty);
                }
                return _CategoryContent(report: report, l10n: l10n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryContent extends StatelessWidget {
  const _CategoryContent({required this.report, required this.l10n});

  final CategoryReport report;
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
          if (report.expenseByCategory.isNotEmpty) ...[
            SectionHeader(title: l10n.reportGrossExpense),
            // The table first, then the picture of it. The chart shows no
            // figure the rows above do not already carry, and if the rows go
            // it goes with them.
            for (final item in report.expenseByCategory)
              _CategoryRow(item: item, l10n: l10n),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space16,
                AppTheme.space16,
                AppTheme.space16,
                0,
              ),
              child: BarSeries(
                bars: [
                  for (final item in report.expenseByCategory)
                    ChartBar(
                      label: categoryLabelFromCode(l10n, item.categoryCode),
                      value: item.totalMinorUnits.toDouble(),
                      valueLabel: AmountDisplayFormatter.format(
                        item.totalMinorUnits,
                        item.currencyCode,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (report.incomeByCategory.isNotEmpty) ...[
            SectionHeader(title: l10n.reportGrossIncome),
            for (final item in report.incomeByCategory)
              _CategoryRow(item: item, l10n: l10n),
          ],
          const SizedBox(height: AppTheme.space24),
        ],
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.item, required this.l10n});

  final CategoryBreakdown item;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = item.categoryType == CategoryType.expense;
    return CurrencyAmountRow(
      label: categoryLabelFromCode(l10n, item.categoryCode),
      caption: l10n.reportTransactionCount(item.transactionCount),
      minorUnits: item.totalMinorUnits,
      currencyCode: item.currencyCode,
      tone: isExpense
          ? FinancialAmountTone.expense
          : FinancialAmountTone.income,
      direction: isExpense
          ? FinancialAmountDirection.outflow
          : FinancialAmountDirection.inflow,
      // The figure is a claim about a set of transactions; tapping it shows
      // the set. Until this existed the drill-down screen was unreachable.
      onTap: () {
        ref
            .read(reportRequestProvider.notifier)
            .drillDown(categoryCode: item.categoryCode);
        context.push('/reports/transactions');
      },
    );
  }
}
