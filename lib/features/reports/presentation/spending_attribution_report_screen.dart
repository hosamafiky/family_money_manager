/// Spending attribution report screen — by spender, beneficiary, and scope.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/reports/application/get_spending_attribution_report_use_case.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_period_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Expense attribution: by spender, by beneficiary, by scope.
class SpendingAttributionReportScreen extends ConsumerWidget {
  const SpendingAttributionReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(spendingAttributionReportProvider(req));

    void retry() => ref.invalidate(spendingAttributionReportProvider(req));

    return AppScreenScaffold(
      title: Text(l10n.reportAttributionTitle),
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
                if (result is! AppOk<SpendingAttributionReport>) {
                  return AppErrorState(
                    message: l10n.reportError,
                    onRetry: retry,
                    retryLabel: l10n.reportRefresh,
                  );
                }
                final report = result.value;
                final hasData =
                    report.bySpender.isNotEmpty ||
                    report.byBeneficiary.isNotEmpty ||
                    report.byScope.isNotEmpty;
                if (!hasData) {
                  return AppEmptyState(title: l10n.reportEmpty);
                }
                return _AttributionContent(report: report, l10n: l10n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributionContent extends StatelessWidget {
  const _AttributionContent({required this.report, required this.l10n});

  final SpendingAttributionReport report;
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
          if (report.bySpender.isNotEmpty) ...[
            SectionHeader(title: l10n.reportSpenderSection),
            for (final item in report.bySpender)
              _AttributionRow(
                label: item.memberDisplayName,
                totalMinorUnits: item.totalMinorUnits,
                currencyCode: item.currencyCode,
                transactionCount: item.transactionCount,
                l10n: l10n,
                spenderMemberId: item.memberId,
              ),
          ],
          if (report.byBeneficiary.isNotEmpty) ...[
            SectionHeader(title: l10n.reportBeneficiarySection),
            for (final item in report.byBeneficiary)
              _AttributionRow(
                label: item.memberDisplayName,
                totalMinorUnits: item.totalMinorUnits,
                currencyCode: item.currencyCode,
                transactionCount: item.transactionCount,
                l10n: l10n,
                beneficiaryMemberId: item.memberId,
              ),
          ],
          if (report.byScope.isNotEmpty) ...[
            SectionHeader(title: l10n.reportScopeSection),
            for (final item in report.byScope)
              _AttributionRow(
                label: expenseScopeDashboardLabel(l10n, item.scope),
                totalMinorUnits: item.totalMinorUnits,
                currencyCode: item.currencyCode,
                transactionCount: item.transactionCount,
                l10n: l10n,
                scope: item.scope,
              ),
          ],
          const SizedBox(height: AppTheme.space24),
        ],
      ),
    );
  }
}

/// One attributed total. The three sections differ only in what the label is,
/// so they share a row rather than duplicating one per dimension.
class _AttributionRow extends ConsumerWidget {
  const _AttributionRow({
    required this.label,
    required this.totalMinorUnits,
    required this.currencyCode,
    required this.transactionCount,
    required this.l10n,
    this.spenderMemberId,
    this.beneficiaryMemberId,
    this.scope,
  });

  final String label;
  final int totalMinorUnits;
  final String currencyCode;
  final int transactionCount;
  final AppLocalizations l10n;

  /// Exactly one of these is set — the dimension this total was grouped by,
  /// and therefore the one the drill-down filters on.
  final String? spenderMemberId;
  final String? beneficiaryMemberId;
  final ExpenseScope? scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CurrencyAmountRow(
      label: label,
      caption: l10n.reportTransactionCount(transactionCount),
      minorUnits: totalMinorUnits,
      currencyCode: currencyCode,
      tone: FinancialAmountTone.expense,
      direction: FinancialAmountDirection.outflow,
      onTap: () {
        ref
            .read(reportRequestProvider.notifier)
            .drillDown(
              spenderMemberId: spenderMemberId,
              beneficiaryMemberId: beneficiaryMemberId,
              scope: scope,
            );
        context.push('/reports/transactions');
      },
    );
  }
}
