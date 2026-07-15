import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/smoke_screen/smoke_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [SmokeScreen] with the minimum Material + localizations scaffolding
/// needed for isolated widget tests.
Widget buildSmokeScreen({Locale locale = const Locale('en', 'US')}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith((ref) => locale),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      home: const SmokeScreen(),
    ),
  );
}

void main() {
  group('SmokeScreen — English', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildSmokeScreen());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows English app title', (tester) async {
      await tester.pumpWidget(buildSmokeScreen());
      await tester.pumpAndSettle();
      expect(find.text('Family Money Manager'), findsOneWidget);
    });

    testWidgets('shows foundation title', (tester) async {
      await tester.pumpWidget(buildSmokeScreen());
      await tester.pumpAndSettle();
      expect(find.text('Foundation Phase'), findsOneWidget);
    });

    testWidgets('shows language toggle buttons', (tester) async {
      await tester.pumpWidget(buildSmokeScreen());
      await tester.pumpAndSettle();
      expect(find.text('العربية'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('shows theme toggle buttons', (tester) async {
      await tester.pumpWidget(buildSmokeScreen());
      await tester.pumpAndSettle();
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('shows LTR direction label for English', (tester) async {
      await tester.pumpWidget(
        buildSmokeScreen(locale: const Locale('en', 'US')),
      );
      await tester.pumpAndSettle();
      expect(find.text('LTR'), findsOneWidget);
    });

    testWidgets('does not contain financial amounts or balances', (
      tester,
    ) async {
      await tester.pumpWidget(buildSmokeScreen());
      await tester.pumpAndSettle();

      final allText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');

      expect(allText, isNot(contains('EGP')));
      expect(allText, isNot(matches(RegExp(r'\d{3,}'))));
    });

    testWidgets('does not overflow at default text scale', (tester) async {
      await tester.pumpWidget(buildSmokeScreen());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('SmokeScreen — Arabic RTL', () {
    testWidgets('renders without error in Arabic', (tester) async {
      await tester.pumpWidget(
        buildSmokeScreen(locale: const Locale('ar', 'EG')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows Arabic app title', (tester) async {
      await tester.pumpWidget(
        buildSmokeScreen(locale: const Locale('ar', 'EG')),
      );
      await tester.pumpAndSettle();
      expect(find.text('مدير مالية الأسرة'), findsOneWidget);
    });

    testWidgets('shows RTL direction label for Arabic', (tester) async {
      await tester.pumpWidget(
        buildSmokeScreen(locale: const Locale('ar', 'EG')),
      );
      await tester.pumpAndSettle();
      expect(find.text('يمين إلى يسار'), findsOneWidget);
    });
  });
}
