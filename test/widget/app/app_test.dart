import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/app/app_router.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('App widget — startup smoke test', () {
    testWidgets('renders without error with development config', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays Arabic app title when locale is Arabic', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('ar', 'EG')));
      await tester.pumpAndSettle();
      expect(find.text('مدير مالية الأسرة'), findsWidgets);
    });

    testWidgets('displays English app title when locale is English', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('en', 'US')));
      await tester.pumpAndSettle();
      expect(find.text('Family Money Manager'), findsWidgets);
    });
  });

  group('App widget — locale and directionality', () {
    testWidgets('Arabic locale produces RTL directionality', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('ar', 'EG')));
      await tester.pumpAndSettle();

      final direction = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(direction.textDirection, TextDirection.rtl);
    });

    testWidgets('English locale produces LTR directionality', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('en', 'US')));
      await tester.pumpAndSettle();

      final direction = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(direction.textDirection, TextDirection.ltr);
    });
  });

  group('App widget — localization availability', () {
    testWidgets('Arabic localization is available', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('ar', 'EG')));
      await tester.pumpAndSettle();

      // AppLocalizations is resolved in elements below MaterialApp.
      // Scaffold is a safe child element that has the delegates applied.
      final context = tester.element(find.byType(Scaffold).first);
      final l10n = AppLocalizations.of(context);
      expect(l10n.appTitle, isNotEmpty);
    });

    testWidgets('English localization is available', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('en', 'US')));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final l10n = AppLocalizations.of(context);
      expect(l10n.appTitle, 'Family Money Manager');
    });
  });

  group('App widget — theme', () {
    testWidgets('light theme is applied when ThemeMode.light', (tester) async {
      await tester.pumpWidget(buildTestApp(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
    });

    testWidgets('dark theme is applied when ThemeMode.dark', (tester) async {
      await tester.pumpWidget(buildTestApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });
  });

  group('App widget — unknown route (AppErrorScreen)', () {
    testWidgets('renders error icon and back button when error is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
          ],
          child: const MaterialApp(home: AppErrorScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Go home'), findsOneWidget);
    });

    testWidgets('displays error message when exception provided', (
      tester,
    ) async {
      final error = Exception('not-found');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
          ],
          child: MaterialApp(home: AppErrorScreen(error: error)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('not-found'), findsOneWidget);
    });

    testWidgets('AppRouter.create() initialises without error', (tester) async {
      // Verifies that the router can be constructed and wired up.
      // The errorBuilder is exercised by the AppErrorScreen tests above.
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('App widget — Riverpod overrides', () {
    testWidgets('appConfigProvider override is respected', (tester) async {
      await tester.pumpWidget(buildTestApp(config: AppConfig.development));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('locale override drives displayed language', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('en', 'US')));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      expect(AppLocalizations.of(context).appTitle, 'Family Money Manager');
    });
  });
}
