import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/smoke_screen/smoke_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed-locale notifier for isolated SmokeScreen tests.
class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier(this._locale);
  final Locale _locale;
  @override
  Locale build() => _locale;
}

/// Wraps [SmokeScreen] with the minimum Material + localizations scaffolding
/// needed for isolated widget tests.
Widget buildSmokeScreen({Locale locale = const Locale('en', 'US')}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
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

    testWidgets('does not overflow at 1.5x text scale', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: buildSmokeScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('language toggle buttons have non-empty semantics labels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildSmokeScreen());
      await tester.pumpAndSettle();

      // OutlinedButton derives its semantics label from its Text child.
      final arabicSemantics = tester.getSemantics(find.text('العربية'));
      expect(arabicSemantics.label, isNotEmpty);

      final englishSemantics = tester.getSemantics(find.text('English'));
      expect(englishSemantics.label, isNotEmpty);

      handle.dispose();
    });

    testWidgets('theme toggle buttons have non-empty semantics labels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildSmokeScreen());
      await tester.pumpAndSettle();

      final lightSemantics = tester.getSemantics(find.text('Light'));
      expect(lightSemantics.label, isNotEmpty);

      final darkSemantics = tester.getSemantics(find.text('Dark'));
      expect(darkSemantics.label, isNotEmpty);

      handle.dispose();
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

  group('SmokeScreen — touch targets', () {
    testWidgets('language toggle buttons meet 48-pt minimum touch target', (
      tester,
    ) async {
      await tester.pumpWidget(buildSmokeScreen());
      await tester.pumpAndSettle();

      // Find all OutlinedButtons (language + theme toggles).
      final buttons = tester.widgetList<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(buttons, isNotEmpty);

      for (final button in buttons) {
        final renderBox = tester.renderObject<RenderBox>(find.byWidget(button));
        // WCAG 2.5.5 and Material Design require >= 48 logical pixels.
        expect(
          renderBox.size.height,
          greaterThanOrEqualTo(48.0),
          reason:
              'Button height ${renderBox.size.height} is below 48pt minimum',
        );
      }
    });
  });
}
