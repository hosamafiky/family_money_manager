/// Spending attribution report screen — by spender, beneficiary, and scope.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/reports/application/get_spending_attribution_report_use_case.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Expense attribution: by spender, by beneficiary, by scope.
class SpendingAttributionReportScreen extends ConsumerWidget {
  const SpendingAttributionReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final reportAsync = ref.watch(spendingAttributionReportProvider(req));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportAttributionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reportRefresh,
            onPressed: () =>
                ref.invalidate(spendingAttributionReportProvider(req)),
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
              error: (_, __) => ReportErrorState(
                onRetry: () =>
                    ref.invalidate(spendingAttributionReportProvider(req)),
              ),
              data: (result) {
                if (result is! AppOk<SpendingAttributionReport>) {
                  return ReportErrorState(
                    onRetry: () =>
                        ref.invalidate(spendingAttributionReportProvider(req)),
                  );
                }
                final report = result.value;
                final hasData =
                    report.bySpender.isNotEmpty ||
                    report.byBeneficiary.isNotEmpty ||
                    report.byScope.isNotEmpty;
                if (!hasData) return const ReportEmptyState();
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ReportInfoNote(text: l10n.reportCurrencySeparate),
        // By Spender
        if (report.bySpender.isNotEmpty) ...[
          _SectionHeader(title: l10n.reportSpenderSection),
          for (final item in report.bySpender)
            _MemberRow(
              memberName: item.memberDisplayName,
              totalMinorUnits: item.totalMinorUnits,
              currencyCode: item.currencyCode,
              transactionCount: item.transactionCount,
              l10n: l10n,
            ),
        ],
        // By Beneficiary
        if (report.byBeneficiary.isNotEmpty) ...[
          _SectionHeader(title: l10n.reportBeneficiarySection),
          for (final item in report.byBeneficiary)
            _MemberRow(
              memberName: item.memberDisplayName,
              totalMinorUnits: item.totalMinorUnits,
              currencyCode: item.currencyCode,
              transactionCount: item.transactionCount,
              l10n: l10n,
            ),
        ],
        // By Scope
        if (report.byScope.isNotEmpty) ...[
          _SectionHeader(title: l10n.reportScopeSection),
          for (final item in report.byScope)
            _ScopeRow(
              scope: item.scope,
              totalMinorUnits: item.totalMinorUnits,
              currencyCode: item.currencyCode,
              transactionCount: item.transactionCount,
              l10n: l10n,
            ),
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
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.memberName,
    required this.totalMinorUnits,
    required this.currencyCode,
    required this.transactionCount,
    required this.l10n,
  });

  final String memberName;
  final int totalMinorUnits;
  final String currencyCode;
  final int transactionCount;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(memberName),
      subtitle: Text(l10n.reportTransactionCount(transactionCount)),
      trailing: ReportAmountText(
        minorUnits: totalMinorUnits,
        currencyCode: currencyCode,
        color: Colors.red,
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({
    required this.scope,
    required this.totalMinorUnits,
    required this.currencyCode,
    required this.transactionCount,
    required this.l10n,
  });

  final ExpenseScope scope;
  final int totalMinorUnits;
  final String currencyCode;
  final int transactionCount;
  final AppLocalizations l10n;

  String _scopeLabel(AppLocalizations l10n) => switch (scope) {
    ExpenseScope.personal => l10n.dashboardScopePersonal,
    ExpenseScope.spouse => l10n.dashboardScopeSpouse,
    ExpenseScope.household => l10n.dashboardScopeHousehold,
    ExpenseScope.child => l10n.dashboardScopeChild,
    ExpenseScope.shared => l10n.dashboardScopeHousehold,
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(_scopeLabel(l10n)),
      subtitle: Text(l10n.reportTransactionCount(transactionCount)),
      trailing: ReportAmountText(
        minorUnits: totalMinorUnits,
        currencyCode: currencyCode,
        color: Colors.red,
      ),
    );
  }
}
