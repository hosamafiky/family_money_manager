/// Generic drill-down transaction list screen.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_period_selector.dart';
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

    void retry() => ref.invalidate(reportTransactionsProvider(req));

    return AppScreenScaffold(
      title: Text(l10n.reportDrillDown),
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
          // Arriving here by tapping a report figure means this list is a
          // subset. Saying so — with the way out — is the difference between
          // "these are my transactions" and "these are some of them".
          if (!req.filter.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space16,
                0,
                AppTheme.space16,
                AppTheme.space8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppInlineNotice(
                      message: l10n.reportDrillDownFiltered,
                      icon: Icons.filter_list,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  TextButton(
                    onPressed: () =>
                        ref.read(reportRequestProvider.notifier).clearFilter(),
                    child: Text(l10n.reportDrillDownClear),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: reportAsync.when(
              loading: () => const AppSkeletonList(),
              error: (_, _) => AppErrorState(
                message: l10n.reportError,
                onRetry: retry,
                retryLabel: l10n.reportRefresh,
              ),
              data: (result) {
                if (result is! AppOk<List<ReportTransactionRow>>) {
                  return AppErrorState(
                    message: l10n.reportError,
                    onRetry: retry,
                    retryLabel: l10n.reportRefresh,
                  );
                }
                final rows = result.value;
                if (rows.isEmpty) {
                  return AppEmptyState(title: l10n.reportEmpty);
                }
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
    return ResponsiveContentContainer(
      child: ListView.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) =>
            _TransactionRow(row: rows[index], l10n: l10n),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.row, required this.l10n});

  final ReportTransactionRow row;
  final AppLocalizations l10n;

  /// The same tile the transaction list uses.
  ///
  /// Arriving at a transaction from a report used to show a different row
  /// than arriving at it from the list — different geometry, different
  /// grammar, a raw amount string. One row model means the drill-down reads
  /// like what it drills into.
  @override
  Widget build(BuildContext context) {
    final typeKind = switch (row.operationType) {
      OperationType.income => FinancialTypeKind.income,
      OperationType.expense ||
      OperationType.childFundWithdrawal => FinancialTypeKind.expense,
      OperationType.transfer => FinancialTypeKind.transfer,
      OperationType.reversal => FinancialTypeKind.reversal,
      OperationType.adjustment => FinancialTypeKind.adjustment,
      _ => FinancialTypeKind.other,
    };

    return TransactionListTile(
      typeLabel: operationTypeLabel(l10n, row.operationType),
      typeKind: typeKind,
      primaryDescription: row.categoryCode == null
          ? operationTypeLabel(l10n, row.operationType)
          : categoryLabelFromCode(l10n, row.categoryCode!),
      accountOrDirection: row.accountName,
      effectiveDate: row.effectiveDate,
      minorUnits: row.amountMinorUnits,
      currencyCode: row.currencyCode,
      isReversed: row.isReversed,
      reversedLabel: row.isReversed ? l10n.transactionReversed : null,
      onTap: () => context.push('/transactions/${row.operationId}'),
    );
  }
}
