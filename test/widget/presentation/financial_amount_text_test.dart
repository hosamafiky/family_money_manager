/// Behavioural guarantees for the single point where a number becomes pixels.
///
/// Each group corresponds to a defect the previous implementation shipped:
/// a leading currency code, an ASCII hyphen that reordered in RTL, no bidi
/// isolation, a semantics label that repeated the currency, and masking that
/// did not exist at all.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const arabic = Locale('ar', 'EG');
const english = Locale('en');

Widget host(
  Widget child, {
  Locale locale = english,
  bool masked = false,
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  locale: locale,
  theme: brightness == Brightness.light
      ? AppTheme.light(locale: locale)
      : AppTheme.dark(locale: locale),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(textScaler: textScaler),
    child: Scaffold(
      body: Center(
        child: PrivacyScope(masked: masked, child: child),
      ),
    ),
  ),
);

/// The visible text of every [Text] under [widget], in tree order.
List<String> textsUnder(WidgetTester tester, Finder widget) => tester
    .widgetList<Text>(find.descendant(of: widget, matching: find.byType(Text)))
    .map((t) => t.data ?? '')
    .toList();

void main() {
  // Written as escapes: the literal code points are invisible in a diff.
  const fsi = '\u2068'; // FIRST STRONG ISOLATE
  const pdi = '\u2069'; // POP DIRECTIONAL ISOLATE
  const minus = '−';

  group('the number itself', () {
    testWidgets('is grouped and scaled, not raw minor units', (tester) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(minorUnits: 127500, currencyCode: 'EGP'),
        ),
      );
      // The screen this replaced rendered "−127500 EGP".
      expect(find.textContaining('1,275.00'), findsOneWidget);
      expect(find.textContaining('127500'), findsNothing);
    });

    testWidgets('respects per-currency scale', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              FinancialAmountText(minorUnits: 1000000, currencyCode: 'JPY'),
              FinancialAmountText(minorUnits: 10000, currencyCode: 'KWD'),
            ],
          ),
        ),
      );
      expect(find.textContaining('1,000,000'), findsOneWidget);
      expect(find.textContaining('10.000'), findsOneWidget);
    });
  });

  group('sign and glyph — the non-colour channels', () {
    testWidgets('an outflow carries a real minus and the out glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(
            minorUnits: 38250,
            currencyCode: 'EGP',
            direction: FinancialAmountDirection.outflow,
          ),
        ),
      );
      final texts = textsUnder(tester, find.byType(FinancialAmountText));
      // U+2212, not an ASCII hyphen: the hyphen is bidi-neutral.
      expect(texts, contains(minus));
      expect(texts, isNot(contains('-')));
      expect(texts, contains('↑'));
    });

    testWidgets('an inflow carries a plus and the in glyph', (tester) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(
            minorUnits: 1840000,
            currencyCode: 'EGP',
            direction: FinancialAmountDirection.inflow,
          ),
        ),
      );
      final texts = textsUnder(tester, find.byType(FinancialAmountText));
      expect(texts, contains('+'));
      expect(texts, contains('↓'));
    });

    testWidgets('a transfer gets a symmetric glyph and no sign at all', (
      tester,
    ) async {
      // A transfer changes no total, so it is neither positive nor negative.
      await tester.pumpWidget(
        host(
          const FinancialAmountText(
            minorUnits: 4790000,
            currencyCode: 'EGP',
            direction: FinancialAmountDirection.internal,
          ),
        ),
      );
      final texts = textsUnder(tester, find.byType(FinancialAmountText));
      expect(texts, contains('⇄'));
      expect(texts, isNot(contains('+')));
      expect(texts, isNot(contains(minus)));
    });

    testWidgets('held money carries a lock and no sign', (tester) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(
            minorUnits: 4790000,
            currencyCode: 'EGP',
            tone: FinancialAmountTone.certificate,
            direction: FinancialAmountDirection.held,
          ),
        ),
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      final texts = textsUnder(tester, find.byType(FinancialAmountText));
      expect(texts, isNot(contains(minus)));
    });

    testWidgets('a balance is not a movement — no sign, no glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(minorUnits: 2430000, currencyCode: 'EGP'),
        ),
      );
      final texts = textsUnder(tester, find.byType(FinancialAmountText));
      expect(texts, isNot(contains('↑')));
      expect(texts, isNot(contains('↓')));
      expect(texts, isNot(contains('⇄')));
    });

    testWidgets('the sign never comes from a negative input', (tester) async {
      // Callers pass a magnitude; the direction owns the sign. Otherwise an
      // already-negative expense would render a double negative.
      await tester.pumpWidget(
        host(
          const FinancialAmountText(
            minorUnits: -38250,
            currencyCode: 'EGP',
            direction: FinancialAmountDirection.outflow,
          ),
        ),
      );
      final texts = textsUnder(tester, find.byType(FinancialAmountText));
      expect(texts.where((t) => t == minus).length, 1);
      expect(find.textContaining('382.50'), findsOneWidget);
    });
  });

  group('bidi', () {
    testWidgets('the numeric run is isolated', (tester) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(minorUnits: 127500, currencyCode: 'EGP'),
        ),
      );
      final numeric = textsUnder(
        tester,
        find.byType(FinancialAmountText),
      ).firstWhere((t) => t.contains('1,275.00'));
      expect(numeric.startsWith(fsi), isTrue);
      expect(numeric.endsWith(pdi), isTrue);
    });

    testWidgets('sign and number are separate children, so the sign cannot '
        'reorder in RTL', (tester) async {
      // The old formatter emitted one string and rendered "EGP 382.50−" in
      // Arabic. Position is now a layout fact, not a bidi outcome.
      for (final locale in [english, arabic]) {
        await tester.pumpWidget(
          host(
            const FinancialAmountText(
              minorUnits: 38250,
              currencyCode: 'EGP',
              direction: FinancialAmountDirection.outflow,
            ),
            locale: locale,
          ),
        );
        final texts = textsUnder(tester, find.byType(FinancialAmountText));
        final signIndex = texts.indexOf(minus);
        final numberIndex = texts.indexWhere((t) => t.contains('382.50'));
        expect(signIndex, isNonNegative, reason: '$locale');
        // Sign precedes the number in the child order for both scripts; the
        // Row mirrors, so it lands on the correct visual side either way.
        expect(signIndex, lessThan(numberIndex), reason: '$locale');
      }
    });

    testWidgets('the currency code trails the number in both scripts', (
      tester,
    ) async {
      for (final locale in [english, arabic]) {
        await tester.pumpWidget(
          host(
            const FinancialAmountText(minorUnits: 38250, currencyCode: 'EGP'),
            locale: locale,
          ),
        );
        final texts = textsUnder(tester, find.byType(FinancialAmountText));
        final numberIndex = texts.indexWhere((t) => t.contains('382.50'));
        final codeIndex = texts.indexOf('EGP');
        expect(codeIndex, greaterThan(numberIndex), reason: '$locale');
      }
    });
  });

  group('privacy mode', () {
    testWidgets('digits are replaced by one bar per group', (tester) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(minorUnits: 127500, currencyCode: 'EGP'),
          masked: true,
        ),
      );
      // '1', '275', '00' — one bar per group.
      final bars = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(FinancialAmountText),
          matching: find.byType(Container),
        ),
      );
      expect(bars.length, 3);

      // The digits still exist in the tree, because the real text is what
      // sizes the masked run — but at zero opacity, so nothing is rasterised
      // and no pixel of the value reaches the screen.
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(FinancialAmountText),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0);
    });

    testWidgets('sign, glyph and currency code all survive masking', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(
            minorUnits: 38250,
            currencyCode: 'EGP',
            direction: FinancialAmountDirection.outflow,
          ),
          masked: true,
        ),
      );
      final texts = textsUnder(tester, find.byType(FinancialAmountText));
      expect(texts, contains(minus));
      expect(texts, contains('↑'));
      expect(texts, contains('EGP'));
    });

    testWidgets('the lock survives masking on held money', (tester) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(
            minorUnits: 4790000,
            currencyCode: 'EGP',
            direction: FinancialAmountDirection.held,
          ),
          masked: true,
        ),
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('layout width is preserved, so nothing moves on toggle', (
      tester,
    ) async {
      const amount = FinancialAmountText(
        minorUnits: 127500,
        currencyCode: 'EGP',
        direction: FinancialAmountDirection.outflow,
      );

      await tester.pumpWidget(host(amount));
      final visible = tester.getSize(find.byType(FinancialAmountText)).width;

      await tester.pumpWidget(host(amount, masked: true));
      final hidden = tester.getSize(find.byType(FinancialAmountText)).width;

      // A privacy control that reflows the page feels like it is changing the
      // data rather than the display.
      expect(hidden, closeTo(visible, 1.0));
    });

    testWidgets('masking is off unless a scope says otherwise', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: english,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: FinancialAmountText(minorUnits: 100, currencyCode: 'EGP'),
          ),
        ),
      );
      expect(find.textContaining('1.00'), findsOneWidget);
    });
  });

  group('semantics', () {
    testWidgets('an amount is one phrase leading with its class', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(
            minorUnits: 38250,
            currencyCode: 'EGP',
            direction: FinancialAmountDirection.outflow,
            semanticsContext: 'from Bank Misr',
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(FinancialAmountText));
      expect(node.label, 'Expense, 382.50 EGP, from Bank Misr');
    });

    testWidgets('held money announces that it cannot be spent', (tester) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(
            minorUnits: 4790000,
            currencyCode: 'EGP',
            direction: FinancialAmountDirection.held,
            semanticsContext: 'certificate principal',
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(FinancialAmountText));
      expect(node.label, contains('not spendable'));
      expect(node.label, contains('certificate principal'));
    });

    testWidgets('the currency code is not repeated', (tester) async {
      // The old implementation's label was '$text $currencyCode' where text
      // already began with the code, so it said "EGP 382.50 EGP".
      await tester.pumpWidget(
        host(const FinancialAmountText(minorUnits: 38250, currencyCode: 'EGP')),
      );
      final node = tester.getSemantics(find.byType(FinancialAmountText));
      expect('EGP'.allMatches(node.label).length, 1);
    });

    testWidgets('a masked amount never leaks its value', (tester) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(minorUnits: 127500, currencyCode: 'EGP'),
          masked: true,
        ),
      );
      final node = tester.getSemantics(find.byType(FinancialAmountText));
      expect(node.label, contains('Hidden amount'));
      expect(node.label, isNot(contains('1,275')));
      expect(node.label, isNot(contains('127500')));
    });
  });

  group('resilience', () {
    testWidgets('renders at 200% text scale without overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 186,
            child: FinancialAmountText(
              minorUnits: 999999999,
              currencyCode: 'EGP',
              direction: FinancialAmountDirection.outflow,
            ),
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode and in Arabic', (tester) async {
      await tester.pumpWidget(
        host(
          const FinancialAmountText(
            minorUnits: 127500,
            currencyCode: 'EGP',
            tone: FinancialAmountTone.protected,
            direction: FinancialAmountDirection.held,
          ),
          locale: arabic,
          brightness: Brightness.dark,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('each tone resolves to its own theme role', (tester) async {
      for (final (tone, expected) in [
        (FinancialAmountTone.income, AppFinancialColors.light.income),
        (FinancialAmountTone.expense, AppFinancialColors.light.expense),
        (FinancialAmountTone.transfer, AppFinancialColors.light.transfer),
        (
          FinancialAmountTone.protected,
          AppFinancialColors.light.protectedMoney,
        ),
        (FinancialAmountTone.goal, AppFinancialColors.light.goalReserved),
        (
          FinancialAmountTone.certificate,
          AppFinancialColors.light.certificatePrincipal,
        ),
        (FinancialAmountTone.muted, AppFinancialColors.light.secondaryText),
      ]) {
        await tester.pumpWidget(
          host(
            FinancialAmountText(
              minorUnits: 100,
              currencyCode: 'EGP',
              tone: tone,
            ),
          ),
        );
        final numeric = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(FinancialAmountText),
                matching: find.byType(Text),
              ),
            )
            .firstWhere((t) => (t.data ?? '').contains('1.00'));
        expect(numeric.style!.color, expected, reason: '$tone');
      }
    });
  });
}
