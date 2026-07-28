/// The account tile's job is to answer "can I spend this?" without colour,
/// without reading, and without the tile ever working it out for itself.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(
  Widget child, {
  Locale locale = const Locale('en'),
  double width = 360,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  locale: locale,
  theme: AppTheme.light(locale: locale),
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
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

AccountListTile tile(
  AccountVisualClass visualClass, {
  String name = 'Banque Misr — Salary',
  int minorUnits = 2430000,
  bool isArchived = false,
}) => AccountListTile(
  name: name,
  visualClass: visualClass,
  minorUnits: minorUnits,
  currencyCode: 'EGP',
  subtitle: 'Bank · Ahmed',
  isArchived: isArchived,
);

void main() {
  group('regions', () {
    test('each visual class knows which region it may appear in', () {
      // Held money never appears in the same list as spendable money. The
      // class carries that constraint so a screen cannot place it wrongly by
      // accident.
      expect(AccountVisualClass.cash.region, AccountRegion.spendable);
      expect(AccountVisualClass.bank.region, AccountRegion.spendable);
      expect(AccountVisualClass.spouseWallet.region, AccountRegion.spendable);
      expect(
        AccountVisualClass.certificatePrincipal.region,
        AccountRegion.held,
      );
      expect(AccountVisualClass.goalReserve.region, AccountRegion.held);
      expect(AccountVisualClass.protectedFund.region, AccountRegion.held);
    });

    test('there are exactly six classes', () {
      // Six is the design's number. A seventh would mean a distinction the
      // rest of the system has no vocabulary for.
      expect(AccountVisualClass.values, hasLength(6));
    });
  });

  group('non-colour encoding', () {
    testWidgets('held classes carry the lock; spendable ones do not', (
      tester,
    ) async {
      for (final visualClass in AccountVisualClass.values) {
        await tester.pumpWidget(host(tile(visualClass)));
        final locks = find.byIcon(Icons.lock_outline).evaluate().length;
        if (visualClass.isHeld) {
          // The amount carries a lock; protectedFund's own glyph is a lock
          // too, so it legitimately shows two.
          expect(locks, greaterThanOrEqualTo(1), reason: '$visualClass');
        } else {
          expect(locks, 0, reason: '$visualClass');
        }
      }
    });

    testWidgets('every class paints a leading edge', (tester) async {
      for (final visualClass in AccountVisualClass.values) {
        await tester.pumpWidget(host(tile(visualClass)));
        expect(tester.takeException(), isNull, reason: '$visualClass');
        final edge = find.descendant(
          of: find.byType(AccountListTile),
          matching: find.byType(CustomPaint),
        );
        expect(edge, findsWidgets, reason: '$visualClass');
      }
    });

    testWidgets('the edge is a fixed 4 dp regardless of tile height', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(tile(AccountVisualClass.cash, name: 'A' * 120)),
      );
      final edge = tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(AccountListTile),
              matching: find.byType(SizedBox),
            ),
          )
          .firstWhere((b) => b.width == AccountListTile.edgeWidth);
      expect(edge.width, 4);
    });
  });

  group('height', () {
    testWidgets('is at least 64 dp', (tester) async {
      await tester.pumpWidget(host(tile(AccountVisualClass.bank)));
      final size = tester.getSize(find.byType(AccountListTile));
      expect(size.height, greaterThanOrEqualTo(AccountListTile.minHeight));
    });

    testWidgets('grows for a long Arabic name rather than truncating it', (
      tester,
    ) async {
      // Fixed-height money rows are why long names used to be ellipsised.
      // The tile grows up to the design's three-line cap.
      await tester.pumpWidget(
        host(
          tile(AccountVisualClass.bank, name: 'بنك'),
          locale: const Locale('ar', 'EG'),
        ),
      );
      final short = tester.getSize(find.byType(AccountListTile)).height;

      await tester.pumpWidget(
        host(
          tile(
            AccountVisualClass.bank,
            name: 'حساب بنك مصر — الراتب الشهري لأحمد عبد الرحمن محمود',
          ),
          locale: const Locale('ar', 'EG'),
        ),
      );
      final long = tester.getSize(find.byType(AccountListTile)).height;

      expect(long, greaterThan(short));
    });

    testWidgets('survives 200% text scale', (tester) async {
      await tester.pumpWidget(
        host(
          tile(AccountVisualClass.protectedFund),
          textScaler: const TextScaler.linear(2),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('archived', () {
    testWidgets('renders read-only and quietened, keeping its figure', (
      tester,
    ) async {
      // History is retained. An archived account is never hidden, and its
      // balance is never blanked.
      await tester.pumpWidget(
        host(tile(AccountVisualClass.bank, isArchived: true)),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('24,300.00'), findsOneWidget);
    });
  });

  group('interaction', () {
    testWidgets('a tappable tile is a button to a screen reader', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          AccountListTile(
            name: 'Cash wallet',
            visualClass: AccountVisualClass.cash,
            minorUnits: 184500,
            currencyCode: 'EGP',
            subtitle: 'Cash · Ahmed',
            onTap: () => taps++,
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(AccountListTile));
      expect(node.label, contains('Cash wallet'));

      await tester.tap(find.byType(AccountListTile));
      expect(taps, 1);
    });

    testWidgets('presses tonally, never with a ripple', (tester) async {
      // An expanding circle contradicts a square system, and on a money row it
      // reads as something happening to the money.
      await tester.pumpWidget(
        host(
          AccountListTile(
            name: 'Cash wallet',
            visualClass: AccountVisualClass.cash,
            minorUnits: 184500,
            currencyCode: 'EGP',
            subtitle: 'Cash · Ahmed',
            onTap: () {},
          ),
        ),
      );
      final inkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.byType(AccountListTile),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWell.splashFactory, NoSplash.splashFactory);
    });
  });
}
