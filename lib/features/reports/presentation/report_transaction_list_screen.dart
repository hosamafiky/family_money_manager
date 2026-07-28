/// Generic drill-down transaction list screen.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_widgets.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shows a list of [ReportTransactionRow] items for drill-down.
///
/// Each row is tappable and navigates to `/transactions/:operationId`.
class ReportTransactionListScreen extends ConsumerWidget {
  const ReportTransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(reportTransactionsProvider(req));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportDrillDown),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reportRefresh,
            onPressed: () => ref.invalidate(reportTransactionsProvider(req)),
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
                onRetry: () => ref.invalidate(reportTransactionsProvider(req)),
              ),
              data: (result) {
                if (result is! AppOk<List<ReportTransactionRow>>) {
                  return ReportErrorState(
                    onRetry: () =>
                        ref.invalidate(reportTransactionsProvider(req)),
                  );
                }
                final rows = result.value;
                if (rows.isEmpty) return const ReportEmptyState();
                return _TransactionList(rows: rows, l10n: l10n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.rows, required this.l10n});

  final List<ReportTransactionRow> rows;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _TransactionRow(row: rows[index], l10n: l10n);
      },
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.row, required this.l10n});

  final ReportTransactionRow row;
  final AppLocalizations l10n;

  IconData _icon() => switch (row.operationType) {
    OperationType.income => Icons.arrow_downward,
    OperationType.expense ||
    OperationType.childFundWithdrawal => Icons.arrow_upward,
    OperationType.transfer => Icons.swap_horiz,
    OperationType.reversal => Icons.undo,
    OperationType.openingBalance => Icons.flag_outlined,
    _ => Icons.receipt_outlined,
  };

  Color _color(AppFinancialColors colors) => switch (row.operationType) {
    OperationType.income => colors.income,
    OperationType.expense ||
    OperationType.childFundWithdrawal => colors.expense,
    OperationType.transfer => colors.transfer,
    // A reversal is a correction, not a threshold — grey ink plus the undo
    // glyph, never the warning role, which belongs on notices.
    OperationType.reversal => colors.secondaryText,
    _ => colors.secondaryText,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(context.financialColors);
    return Semantics(
      label:
          '${operationTypeLabel(l10n, row.operationType)} ${ReportAmountText.formatMinorUnits(row.amountMinorUnits, row.currencyCode)} ${row.effectiveDate}',
      button: true,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(_icon(), color: color, size: 18),
        ),
        title: Text(row.accountName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.effectiveDate),
            if (row.categoryCode != null)
              Text(
                categoryLabelFromCode(l10n, row.categoryCode!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (row.isReversed)
              Text(
                l10n.reportReversalEffect,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: color),
              ),
          ],
        ),
        trailing: ReportAmountText(
          minorUnits: row.amountMinorUnits,
          currencyCode: row.currencyCode,
          color: color,
        ),
        onTap: () => context.push('/transactions/${row.operationId}'),
      ),
    );
  }
}
