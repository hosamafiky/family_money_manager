import 'package:family_money_manager/app/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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

/// The currently active [Locale].
///
/// Initialised from [AppConfig.defaultLocale] and updated when the user
/// changes the language.
final appLocaleProvider = StateProvider<Locale>((ref) {
  return ref.watch(appConfigProvider).defaultLocale;
});

/// The current [ThemeMode] preference.
final appThemeModeProvider = StateProvider<ThemeMode>(
  (ref) => ThemeMode.system,
);
