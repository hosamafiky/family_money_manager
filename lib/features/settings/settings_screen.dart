import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimal settings screen for Phase 3A.
///
/// Reuses the language and theme toggles from SmokeScreen.
/// Additional settings are deferred to future phases.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.foundationLanguageLabel, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: locale.languageCode == 'ar' ? null : () => ref.read(appLocaleProvider.notifier).setLocale(const Locale('ar')),
                          child: const Text('العربية'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: locale.languageCode == 'en' ? null : () => ref.read(appLocaleProvider.notifier).setLocale(const Locale('en')),
                          child: const Text('English'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Theme toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.foundationThemeLabel, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: themeMode == ThemeMode.light ? null : () => ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.light),
                          child: Text(l10n.foundationThemeLight),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: themeMode == ThemeMode.dark ? null : () => ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                          child: Text(l10n.foundationThemeDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
