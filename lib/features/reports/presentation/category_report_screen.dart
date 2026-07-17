/// Category report screen — expense and income by category.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/reports/application/get_category_report_use_case.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_widgets.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryReportScreen extends ConsumerWidget {
  const CategoryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(categoryReportProvider(req));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportCategoriesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reportRefresh,
            onPressed: () => ref.invalidate(categoryReportProvider(req)),
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
              error: (_, _) =>
                  ReportErrorState(onRetry: () => ref.invalidate(categoryReportProvider(req))),
              data: (result) {
                if (result is! AppOk<CategoryReport>) {
                  return ReportErrorState(
                    onRetry: () => ref.invalidate(categoryReportProvider(req)),
                  );
                }
                final report = result.value;
                if (report.expenseByCategory.isEmpty && report.incomeByCategory.isEmpty) {
                  return const ReportEmptyState();
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ReportInfoNote(text: l10n.reportCurrencySeparate),
        if (report.expenseByCategory.isNotEmpty) ...[
          _SectionHeader(title: l10n.reportGrossExpense),
          for (final item in report.expenseByCategory) _CategoryRow(item: item, l10n: l10n),
        ],
        if (report.incomeByCategory.isNotEmpty) ...[
          _SectionHeader(title: l10n.reportGrossIncome),
          for (final item in report.incomeByCategory) _CategoryRow(item: item, l10n: l10n),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item, required this.l10n});

  final CategoryBreakdown item;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isExpense = item.categoryType == CategoryType.expense;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.label_outline),
      title: Text(item.categoryCode),
      subtitle: Text(l10n.reportTransactionCount(item.transactionCount)),
      trailing: ReportAmountText(
        minorUnits: item.totalMinorUnits,
        currencyCode: item.currencyCode,
        color: isExpense ? Colors.red : Colors.green,
      ),
    );
  }
}
