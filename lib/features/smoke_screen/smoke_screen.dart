import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Phase 1 foundation smoke screen.
///
/// Demonstrates that the application shell is functional:
/// - Localized title in the active language
/// - Locale toggle (Arabic ↔ English)
/// - Theme toggle (Light ↔ Dark)
/// - Text-direction indicator
///
/// This screen must not show any financial data, account names, balances,
/// or product feature UI. It is replaced in Phase 4 by the real dashboard.
class SmokeScreen extends ConsumerWidget {
  const SmokeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final isArabic = locale.languageCode == 'ar';
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: l10n.foundationTitle,
                child: Text(l10n.foundationSubtitle, style: Theme.of(context).textTheme.bodyLarge),
              ),
              const SizedBox(height: AppTheme.space16),
              _SectionCard(
                title: l10n.foundationLanguageLabel,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isArabic
                            ? null
                            : () => ref
                                  .read(appLocaleProvider.notifier)
                                  .setLocale(const Locale('ar', 'EG')),
                        child: Text(l10n.foundationSwitchToArabic),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isArabic
                            ? () => ref
                                  .read(appLocaleProvider.notifier)
                                  .setLocale(const Locale('en', 'US'))
                            : null,
                        child: Text(l10n.foundationSwitchToEnglish),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              _SectionCard(
                title: l10n.foundationThemeLabel,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: themeMode == ThemeMode.light
                            ? null
                            : () => ref
                                  .read(appThemeModeProvider.notifier)
                                  .setThemeMode(ThemeMode.light),
                        child: Text(l10n.foundationThemeLight),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: themeMode == ThemeMode.dark
                            ? null
                            : () => ref
                                  .read(appThemeModeProvider.notifier)
                                  .setThemeMode(ThemeMode.dark),
                        child: Text(l10n.foundationThemeDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              _SectionCard(
                title: l10n.foundationDirectionLabel,
                child: Text(
                  isRtl ? l10n.foundationDirectionRtl : l10n.foundationDirectionLtr,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              _NoteCard(message: l10n.foundationNote),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: AppTheme.space8),
            child,
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSecondaryContainer),
      ),
    );
  }
}
