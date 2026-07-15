import 'package:family_money_manager/app/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [AppConfig] for the current environment.
///
/// Must be overridden in [ProviderScope] at the application entry point.
/// Tests may override it with [AppConfig.development] via
/// [ProviderScope.overrides].
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider must be overridden before use. '
    'Override it in the root ProviderScope in main.dart.',
  ),
);

// ─── Locale ────────────────────────────────────────────────────────────────

/// Manages the currently active [Locale].
///
/// Initialised from [AppConfig.defaultLocale].
/// Call `ref.read(appLocaleProvider.notifier).setLocale(locale)` to change.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => ref.watch(appConfigProvider).defaultLocale;

  void setLocale(Locale locale) => state = locale;
}

final appLocaleProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

// ─── Theme mode ────────────────────────────────────────────────────────────

/// Manages the current [ThemeMode] preference.
///
/// Defaults to [ThemeMode.system].
/// Call `ref.read(appThemeModeProvider.notifier).setThemeMode(mode)` to change.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) => state = mode;
}

final appThemeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
