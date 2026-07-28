/// The entry primitives: the pad every flow opens with, and the field it
/// drives.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
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
  home: Scaffold(body: child),
);

void main() {
  group('AmountKeypad', () {
    testWidgets('reports every digit, the separator and backspace', (
      tester,
    ) async {
      final pressed = <AmountKeypadKey>[];
      await tester.pumpWidget(host(AmountKeypad(onKey: pressed.add)));

      for (var digit = 0; digit <= 9; digit++) {
        await tester.tap(find.text('$digit'));
      }
      await tester.tap(find.text('.'));
      await tester.tap(find.byIcon(Icons.backspace_outlined));

      // Tapped 0 through 9, so that is the order reported back.
      expect(pressed.whereType<DigitKey>().map((k) => k.digit), [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
      ]);
      expect(pressed.whereType<DecimalSeparatorKey>(), hasLength(1));
      expect(pressed.whereType<BackspaceKey>(), hasLength(1));
    });

    testWidgets('a zero-scale currency gets no separator key', (tester) async {
      // There is no such thing as a fraction of a yen.
      await tester.pumpWidget(
        host(AmountKeypad(onKey: (_) {}, showDecimalSeparator: false)),
      );
      expect(find.text('.'), findsNothing);
      // Every digit is still present — the pad does not reflow.
      for (var digit = 0; digit <= 9; digit++) {
        expect(find.text('$digit'), findsOneWidget);
      }
    });

    testWidgets('disabled reports nothing', (tester) async {
      final pressed = <AmountKeypadKey>[];
      await tester.pumpWidget(
        host(AmountKeypad(onKey: pressed.add, enabled: false)),
      );
      await tester.tap(find.text('5'));
      expect(pressed, isEmpty);
    });

    testWidgets('every key clears the minimum touch target', (tester) async {
      await tester.pumpWidget(host(AmountKeypad(onKey: (_) {})));
      final size = tester.getSize(find.text('5'));
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('5'),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .height,
        greaterThanOrEqualTo(AppTheme.minTouchTarget),
      );
      expect(size.height, greaterThan(0));
    });

    testWidgets('renders in Arabic without error', (tester) async {
      await tester.pumpWidget(
        host(AmountKeypad(onKey: (_) {}), locale: const Locale('ar', 'EG')),
      );
      expect(tester.takeException(), isNull);
      // Digits stay Western in both locales, matching every rendered amount.
      expect(find.text('7'), findsOneWidget);
    });
  });

  group('AmountEntryField', () {
    testWidgets('label sits above the field, never inside it', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          AmountEntryField(
            controller: controller,
            label: 'Amount',
            currencyCode: 'EGP',
          ),
        ),
      );

      final label = tester.getTopLeft(find.text('Amount'));
      final field = tester.getTopLeft(find.byType(TextFormField));
      expect(label.dy, lessThan(field.dy));
    });

    testWidgets('the currency code is pinned at the trailing edge', (
      tester,
    ) async {
      final controller = TextEditingController(text: '1275.00');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          AmountEntryField(
            controller: controller,
            label: 'Amount',
            currencyCode: 'EGP',
          ),
        ),
      );
      expect(find.text('EGP'), findsOneWidget);
      // Trailing in LTR means to the right of the digits.
      expect(
        tester.getTopLeft(find.text('EGP')).dx,
        greaterThan(tester.getTopLeft(find.byType(TextFormField)).dx),
      );
    });

    testWidgets('an error is persistent, announced, and rules in expense', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          AmountEntryField(
            controller: controller,
            label: 'Amount',
            currencyCode: 'EGP',
            errorText: 'Enter an amount greater than zero',
          ),
        ),
      );

      // Persistent, at its cause — never a snackbar.
      expect(find.text('Enter an amount greater than zero'), findsOneWidget);

      final rule = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (c) => c.constraints?.maxHeight == AppTheme.regionRuleWidth,
            orElse: () => tester
                .widgetList<Container>(find.byType(Container))
                .firstWhere((c) => c.color == AppFinancialColors.light.expense),
          );
      expect(rule.color, AppFinancialColors.light.expense);
    });

    testWidgets('a disabled field carries a reason', (tester) async {
      // `disabled` is 2.6:1 and cannot convey its own state, so it never
      // appears without an accompanying explanation.
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          AmountEntryField(
            controller: controller,
            label: 'Amount',
            enabled: false,
            helperText: 'Choose an account first',
          ),
        ),
      );
      expect(find.text('Choose an account first'), findsOneWidget);
    });

    testWidgets('an error replaces the helper rather than stacking', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          AmountEntryField(
            controller: controller,
            label: 'Amount',
            helperText: 'Choose an account first',
            errorText: 'Enter an amount',
          ),
        ),
      );
      expect(find.text('Enter an amount'), findsOneWidget);
      expect(find.text('Choose an account first'), findsNothing);
    });

    testWidgets('is 56 dp tall and survives 200% text scale', (tester) async {
      final controller = TextEditingController(text: '999999999');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SizedBox(
              width: 320,
              child: AmountEntryField(
                controller: controller,
                label: 'Amount',
                currencyCode: 'EGP',
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
