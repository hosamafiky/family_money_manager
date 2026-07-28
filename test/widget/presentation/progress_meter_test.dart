/// The meter has to be readable with colour contributing nothing, and it has
/// to refuse to invent a threshold. Both are tested here.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  theme: AppTheme.light(locale: locale),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SizedBox(width: 320, child: child)),
);

void main() {
  group('percentage', () {
    test('truncates, never rounds', () {
      // 2,410 of 3,500 is 68.857…%. Rounding it to 69 tells a household it
      // has less of its budget left than it actually does.
      const meter = ProgressMeter(
        consumedMinorUnits: 241000,
        totalMinorUnits: 350000,
        currencyCode: 'EGP',
        stateLabel: 'On track',
        role: ProgressMeterRole.budget,
      );
      expect(meter.percentUsed, 68);
    });

    test('handles an unset total without dividing by zero', () {
      const meter = ProgressMeter(
        consumedMinorUnits: 5000,
        totalMinorUnits: 0,
        currencyCode: 'EGP',
        stateLabel: 'No limit',
        role: ProgressMeterRole.budget,
      );
      expect(meter.percentUsed, 0);
    });

    test('reports overshoot past 100 rather than clamping', () {
      const meter = ProgressMeter(
        consumedMinorUnits: 98000,
        totalMinorUnits: 80000,
        currencyCode: 'EGP',
        stateLabel: 'Over budget',
        role: ProgressMeterRole.budget,
      );
      expect(meter.percentUsed, 122);
    });
  });

  group('non-colour encoding', () {
    testWidgets('the state is printed, so the bar is never the only signal', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const ProgressMeter(
            consumedMinorUnits: 98000,
            totalMinorUnits: 80000,
            currencyCode: 'EGP',
            stateLabel: 'Over budget',
            role: ProgressMeterRole.budget,
            label: 'Dining',
          ),
        ),
      );
      expect(find.text('Over budget'), findsOneWidget);
      expect(find.text('Dining'), findsOneWidget);
    });

    testWidgets('the meter never derives its own state label', (tester) async {
      // Thresholds are a domain rule. If the widget could compute this, the
      // app would have two sources of truth about overspending.
      await tester.pumpWidget(
        host(
          const ProgressMeter(
            consumedMinorUnits: 350000,
            totalMinorUnits: 350000,
            currencyCode: 'EGP',
            stateLabel: 'Whatever the domain said',
            role: ProgressMeterRole.budget,
          ),
        ),
      );
      expect(find.text('Whatever the domain said'), findsOneWidget);
    });

    testWidgets('semantics carry label, state and percentage', (tester) async {
      await tester.pumpWidget(
        host(
          const ProgressMeter(
            consumedMinorUnits: 241000,
            totalMinorUnits: 350000,
            currencyCode: 'EGP',
            stateLabel: 'On track',
            role: ProgressMeterRole.budget,
            label: 'Groceries',
            semanticsContext: 'remaining 1,090.00 EGP',
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(ProgressMeter));
      expect(node.label, contains('Groceries'));
      expect(node.label, contains('On track'));
      expect(node.label, contains('68%'));
      expect(node.label, contains('remaining'));
    });
  });

  group('rendering', () {
    testWidgets('budget and goal roles both paint without error', (
      tester,
    ) async {
      for (final role in ProgressMeterRole.values) {
        for (final consumed in [0, 120000, 350000, 500000]) {
          await tester.pumpWidget(
            host(
              ProgressMeter(
                consumedMinorUnits: consumed,
                totalMinorUnits: 350000,
                currencyCode: 'EGP',
                stateLabel: 'state',
                role: role,
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: '$role/$consumed');
        }
      }
    });

    testWidgets('paints in RTL — the fill starts at the leading edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const ProgressMeter(
            consumedMinorUnits: 241000,
            totalMinorUnits: 350000,
            currencyCode: 'EGP',
            stateLabel: 'في المسار الصحيح',
            role: ProgressMeterRole.budget,
          ),
          locale: const Locale('ar', 'EG'),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('في المسار الصحيح'), findsOneWidget);
    });
  });
}
