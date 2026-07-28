import 'package:family_money_manager/app/app.dart';
import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/logging/log_level.dart';
import 'package:family_money_manager/core/logging/log_sink.dart';
import 'package:family_money_manager/features/dashboard/domain/dashboard_summary.dart';
import 'package:family_money_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns a [ProviderScope]-wrapped [App] suitable for widget tests.
///
/// All providers are overridden so tests never hit the unimplemented
/// [appConfigProvider] guard.
///
/// [appDatabaseProvider] is overridden with an in-memory database so that
/// the dashboard FutureProvider resolves synchronously, preventing
/// [CircularProgressIndicator] from causing [pumpAndSettle] to time out.
///
/// When [locale] is provided, a fixed-locale notifier is used so that
/// [App] renders in the requested language from the first frame.
Widget buildTestApp({
  AppConfig config = AppConfig.development,
  Locale? locale,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      if (locale != null)
        appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      appThemeModeProvider.overrideWith(
        () => _FixedThemeModeNotifier(themeMode),
      ),
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase.forTesting();
        ref.onDispose(db.close);
        return db;
      }),
      // Override dashboard summary to return immediately with empty data so
      // that _DashboardLoading is never shown (avoids CircularProgressIndicator
      // preventing pumpAndSettle from settling).
      dashboardSummaryProvider.overrideWith(
        (ref, householdId) async => AppOk(
          DashboardSummary(
            availableToSpend: const [],
            excludedFromAvailable: const [],
            heldByReason: const [],
            householdId: householdId,
            period: DashboardPeriod.custom(
              startDate: '2025-01-01',
              endDate: '2025-02-01',
            ),
            spendableBalances: const [],
            protectedBalances: const [],
            periodFlow: const [],
            expensesByScope: const [],
            spouseWallets: const [],
            recentActivity: const [],
            generatedAt: DateTime(2025, 1, 1),
          ),
        ),
      ),
    ],
    child: const App(),
  );
}

/// A [LocaleNotifier] that always returns a fixed locale, ignoring
/// [AppConfig.defaultLocale]. Used in widget tests.
class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier(this._locale);
  final Locale _locale;

  @override
  Locale build() => _locale;
}

/// A [ThemeModeNotifier] that always returns a fixed theme mode.
/// Used in widget tests.
class _FixedThemeModeNotifier extends ThemeModeNotifier {
  _FixedThemeModeNotifier(this._themeMode);
  final ThemeMode _themeMode;

  @override
  ThemeMode build() => _themeMode;
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
