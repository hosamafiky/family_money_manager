import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hub for accounts, household members, and settings (shell More tab).
class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScreenScaffold(
      title: Text(l10n.moreTitle),
      body: ResponsiveContentContainer(
        child: ListView(
          children: [
            const SizedBox(height: AppTheme.space16),
            Text(
              l10n.moreSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.space8),
            SectionHeader(title: l10n.navAccounts),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(l10n.navAccounts),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/accounts'),
            ),
            SectionHeader(title: l10n.navMembers),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: Text(l10n.navMembers),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/members'),
            ),
            SectionHeader(title: l10n.navSettings),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.navSettings),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}
