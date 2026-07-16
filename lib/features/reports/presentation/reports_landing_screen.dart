/// Reports landing screen — navigable list of available report types.
library;

import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Entry point for all financial reports.
///
/// Shows a simple list of report types. Tapping one navigates to the
/// corresponding report screen. No charts; no mixed-currency totals.
class ReportsLandingScreen extends StatelessWidget {
  const ReportsLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final entries = <_ReportEntry>[
      _ReportEntry(
        icon: Icons.swap_vert,
        label: l10n.reportIncomeExpenseTitle,
        route: '/reports/income-expense',
        semanticsLabel: l10n.reportIncomeExpenseTitle,
      ),
      _ReportEntry(
        icon: Icons.people_outline,
        label: l10n.reportAttributionTitle,
        route: '/reports/attribution',
        semanticsLabel: l10n.reportAttributionTitle,
      ),
      _ReportEntry(
        icon: Icons.category_outlined,
        label: l10n.reportCategoriesTitle,
        route: '/reports/categories',
        semanticsLabel: l10n.reportCategoriesTitle,
      ),
      _ReportEntry(
        icon: Icons.account_balance_outlined,
        label: l10n.reportAccountsTitle,
        route: '/reports/accounts',
        semanticsLabel: l10n.reportAccountsTitle,
      ),
      _ReportEntry(
        icon: Icons.home_outlined,
        label: l10n.reportHomeSavingsTitle,
        route: '/reports/home-savings',
        semanticsLabel: l10n.reportHomeSavingsTitle,
      ),
      _ReportEntry(
        icon: Icons.wallet_outlined,
        label: l10n.reportSpouseWalletTitle,
        route: '/reports/spouse-wallet',
        semanticsLabel: l10n.reportSpouseWalletTitle,
      ),
      _ReportEntry(
        icon: Icons.lock_outline,
        label: l10n.reportProtectedFundsTitle,
        route: '/reports/protected-funds',
        semanticsLabel: l10n.reportProtectedFundsTitle,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Semantics(
            label: entry.semanticsLabel,
            button: true,
            child: ListTile(
              leading: Icon(entry.icon),
              title: Text(entry.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(entry.route),
            ),
          );
        },
      ),
    );
  }
}

class _ReportEntry {
  const _ReportEntry({
    required this.icon,
    required this.label,
    required this.route,
    required this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final String route;
  final String semanticsLabel;
}
