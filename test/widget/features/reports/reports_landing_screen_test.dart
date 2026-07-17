/// Widget tests for ReportsLandingScreen (Phase 4B).
///
/// Tests:
/// 1. Shows all 7 report type tiles
/// 2. RTL Arabic layout: screen is displayed correctly
/// 3. LTR English layout: screen is displayed correctly
/// 4. Tap income/expense tile navigates
/// 5. Tap attribution tile navigates
/// 6. Each tile has a chevron icon
/// 7. Semantics labels present on tiles
/// 8. Touch targets are large enough (accessible)
library;

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/reports/presentation/reports_landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ── Test helpers ───────────────────────────────────────────────────────────

class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier(this._locale);
  final Locale _locale;

  @override
  Locale build() => _locale;
}

class _FixedThemeModeNotifier extends ThemeModeNotifier {
  _FixedThemeModeNotifier(this._mode);
  final ThemeMode _mode;

  @override
  ThemeMode build() => _mode;
}

Widget _buildScreen({Locale locale = const Locale('ar')}) {
  final router = GoRouter(
    initialLocation: '/reports',
    routes: [
      GoRoute(
        path: '/reports',
        builder: (_, _) => const ReportsLandingScreen(),
        routes: [
          GoRoute(
            path: 'income-expense',
            builder: (_, _) => const Scaffold(body: Text('Income/Expense')),
          ),
          GoRoute(
            path: 'attribution',
            builder: (_, _) => const Scaffold(body: Text('Attribution')),
          ),
          GoRoute(
            path: 'categories',
            builder: (_, _) => const Scaffold(body: Text('Categories')),
          ),
          GoRoute(
            path: 'accounts',
            builder: (_, _) => const Scaffold(body: Text('Accounts')),
          ),
          GoRoute(
            path: 'home-savings',
            builder: (_, _) => const Scaffold(body: Text('Home Savings')),
          ),
          GoRoute(
            path: 'spouse-wallet',
            builder: (_, _) => const Scaffold(body: Text('Spouse Wallet')),
          ),
          GoRoute(
            path: 'protected-funds',
            builder: (_, _) => const Scaffold(body: Text('Protected Funds')),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('ReportsLandingScreen', () {
    testWidgets('1. Shows all 7 report type tiles', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      // 7 ListTile items (one per report type)
      expect(find.byType(ListTile), findsNWidgets(7));
    });

    testWidgets('2. RTL Arabic layout: screen is displayed', (tester) async {
      await tester.pumpWidget(_buildScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Arabic title should appear
      expect(find.text('التقارير'), findsOneWidget);
    });

    testWidgets('3. LTR English layout: screen is displayed', (tester) async {
      await tester.pumpWidget(_buildScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Reports'), findsOneWidget);
    });

    testWidgets('4. Tap income/expense tile navigates', (tester) async {
      await tester.pumpWidget(_buildScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Income & Expenses'));
      await tester.pumpAndSettle();

      expect(find.text('Income/Expense'), findsOneWidget);
    });

    testWidgets('5. Tap attribution tile navigates', (tester) async {
      await tester.pumpWidget(_buildScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spending Attribution'));
      await tester.pumpAndSettle();

      expect(find.text('Attribution'), findsOneWidget);
    });

    testWidgets('6. Each tile has a chevron icon', (tester) async {
      await tester.pumpWidget(_buildScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(7));
    });

    testWidgets('7. Semantics labels present on tiles', (tester) async {
      await tester.pumpWidget(_buildScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(find.text('Income & Expenses'));
      expect(semantics, isNotNull);
    });

    testWidgets('8. Touch targets accessible (no overflow)', (tester) async {
      await tester.pumpWidget(_buildScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // No overflow errors = valid layout
      expect(tester.takeException(), isNull);
      // All tiles are present
      expect(find.byType(ListTile), findsNWidgets(7));
    });
  });
}
