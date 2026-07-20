import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hub for budgets, goals, and certificates (shell Planning tab).
class PlanningHubScreen extends StatelessWidget {
  const PlanningHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScreenScaffold(
      title: Text(l10n.planningTitle),
      body: ResponsiveContentContainer(
        child: ListView(
          children: [
            const SizedBox(height: AppTheme.space16),
            Text(
              l10n.planningSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.space8),
            SectionHeader(title: l10n.budgetsTitle),
            ListTile(
              leading: const Icon(Icons.savings_outlined),
              title: Text(l10n.budgetsTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/budgets'),
            ),
            SectionHeader(title: l10n.goalsTitle),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.goalsTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/goals'),
            ),
            SectionHeader(title: l10n.certificatesTitle),
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: Text(l10n.certificatesTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/certificates'),
            ),
          ],
        ),
      ),
    );
  }
}
