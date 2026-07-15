import 'package:family_money_manager/app/app.dart';
import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/logging/log_level.dart';
import 'package:family_money_manager/core/logging/log_sink.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns a [ProviderScope]-wrapped [App] suitable for widget tests.
///
/// All providers are overridden so tests never hit the unimplemented
/// [appConfigProvider] guard.
Widget buildTestApp({
  AppConfig config = AppConfig.development,
  Locale? locale,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      if (locale != null) appLocaleProvider.overrideWith((ref) => locale),
      appThemeModeProvider.overrideWith((ref) => themeMode),
    ],
    child: const App(),
  );
}

/// A [LogSink] that captures all writes for assertion in unit tests.
final class TestLogSink implements LogSink {
  final List<({LogLevel level, String tag, String message})> records = [];

  String? get lastMessage => records.isEmpty ? null : records.last.message;

  bool containsLevel(LogLevel level) => records.any((r) => r.level == level);

  void clear() => records.clear();

  @override
  void write(LogLevel level, String tag, String message) {
    records.add((level: level, tag: tag, message: message));
  }
}
