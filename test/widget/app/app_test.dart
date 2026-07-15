import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
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
}
