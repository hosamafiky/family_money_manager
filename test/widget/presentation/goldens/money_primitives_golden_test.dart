/// Golden coverage for the shared money primitives, and nothing else.
///
/// Scope is deliberately narrow. Screen-level goldens would be worthless while
/// screens are still being rebuilt phase by phase, and a large brittle suite
/// trains people to regenerate without looking. These cover the properties
/// that are genuinely visual and that unit assertions can only describe
/// indirectly: where the sign sits in RTL, that a masked run occupies the same
/// space as a visible one, and that the progress meter is legible with colour
/// contributing nothing.
///
/// Regenerate with `flutter test --update-goldens`, and only after confirming
/// the change against the handoff artboards.
///
/// Text renders in the test stub font, not Archivo or Plex Arabic — these
/// goldens pin layout and composition, not typeface.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _arabic = Locale('ar', 'EG');
const _english = Locale('en');

Widget _frame(
  Widget child, {
  required Locale locale,
  required Brightness brightness,
  bool masked = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
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
  home: Scaffold(
    body: Center(
      child: PrivacyScope(
        masked: masked,
        // Captured on its own boundary so the golden is the component, not
        // 800x600 of empty scaffold around it — a reviewer has to be able to
        // see the difference between two of these at a glance.
        child: RepaintBoundary(
          key: captureKey,
          child: ColoredBox(
            color: brightness == Brightness.light
                ? AppFinancialColors.light.ground
                : AppFinancialColors.dark.ground,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: SizedBox(width: 360, child: child),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// Identifies the region each golden captures.
const captureKey = ValueKey('golden-capture');

/// The direction grammar, all five states in one column.
Widget get _directionGrammar => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    FinancialAmountText(
      minorUnits: 1840000,
      currencyCode: 'EGP',
      tone: FinancialAmountTone.income,
      direction: FinancialAmountDirection.inflow,
    ),
    SizedBox(height: AppTheme.space12),
    FinancialAmountText(
      minorUnits: 38250,
      currencyCode: 'EGP',
      tone: FinancialAmountTone.expense,
      direction: FinancialAmountDirection.outflow,
    ),
    SizedBox(height: AppTheme.space12),
    FinancialAmountText(
      minorUnits: 4790000,
      currencyCode: 'EGP',
      tone: FinancialAmountTone.transfer,
      direction: FinancialAmountDirection.internal,
    ),
    SizedBox(height: AppTheme.space12),
    FinancialAmountText(
      minorUnits: 4790000,
      currencyCode: 'EGP',
      tone: FinancialAmountTone.certificate,
      direction: FinancialAmountDirection.held,
    ),
    SizedBox(height: AppTheme.space12),
    FinancialAmountText(minorUnits: 2430000, currencyCode: 'EGP'),
  ],
);

Widget get _meters => const Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    ProgressMeter(
      consumedMinorUnits: 241000,
      totalMinorUnits: 350000,
      currencyCode: 'EGP',
      stateLabel: 'On track',
      role: ProgressMeterRole.budget,
      label: 'Groceries',
    ),
    SizedBox(height: AppTheme.space24),
    ProgressMeter(
      consumedMinorUnits: 98000,
      totalMinorUnits: 80000,
      currencyCode: 'EGP',
      stateLabel: 'Over budget',
      role: ProgressMeterRole.budget,
      label: 'Dining',
    ),
    SizedBox(height: AppTheme.space24),
    ProgressMeter(
      consumedMinorUnits: 1360000,
      totalMinorUnits: 1300000,
      currencyCode: 'EGP',
      stateLabel: 'Overfunded',
      role: ProgressMeterRole.goal,
      label: 'School fees',
    ),
  ],
);

Widget get _summary => const FinancialSummary(
  metrics: [
    FinancialMetric(label: 'Given', minorUnits: 600000, currencyCode: 'EGP'),
    FinancialMetric(label: 'Spent', minorUnits: 161750, currencyCode: 'EGP'),
    FinancialMetric(label: 'Returned', minorUnits: 0, currencyCode: 'EGP'),
    FinancialMetric(
      label: 'Remaining',
      minorUnits: 438250,
      currencyCode: 'EGP',
      isEmphasised: true,
    ),
  ],
);

/// The six visual classes in their two regions, plus an archived row.
Widget get _accountClasses => const Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    AccountListTile(
      name: 'Cash wallet',
      visualClass: AccountVisualClass.cash,
      minorUnits: 184500,
      currencyCode: 'EGP',
      subtitle: 'Cash · Ahmed',
    ),
    AccountListTile(
      name: 'Banque Misr — Salary',
      visualClass: AccountVisualClass.bank,
      minorUnits: 2625925,
      currencyCode: 'EGP',
      subtitle: 'Bank · Ahmed',
    ),
    AccountListTile(
      name: "Spouse wallet — Hana",
      visualClass: AccountVisualClass.spouseWallet,
      minorUnits: 438250,
      currencyCode: 'EGP',
      subtitle: 'Cash · Spouse · excluded from available',
    ),
    AccountListTile(
      name: '12-month investment certificate',
      visualClass: AccountVisualClass.certificatePrincipal,
      minorUnits: 4790000,
      currencyCode: 'EGP',
      subtitle: 'Principal · matures 2027/03/14',
    ),
    AccountListTile(
      name: 'School fees reserve',
      visualClass: AccountVisualClass.goalReserve,
      minorUnits: 1360000,
      currencyCode: 'EGP',
      subtitle: 'Reserved for goal · 104% of target',
    ),
    AccountListTile(
      name: "Yousuf's protected funds",
      visualClass: AccountVisualClass.protectedFund,
      minorUnits: 695000,
      currencyCode: 'EGP',
      subtitle: 'Protected · beneficiary Yousuf',
    ),
    AccountListTile(
      name: 'Old savings account',
      visualClass: AccountVisualClass.bank,
      minorUnits: 0,
      currencyCode: 'EGP',
      subtitle: 'Archived · history retained, read only',
      isArchived: true,
    ),
  ],
);

void main() {
  group('direction grammar', () {
    for (final (name, locale) in [('ltr', _english), ('rtl', _arabic)]) {
      for (final (theme, brightness) in [
        ('light', Brightness.light),
        ('dark', Brightness.dark),
      ]) {
        testWidgets('$name · $theme', (tester) async {
          await tester.pumpWidget(
            _frame(_directionGrammar, locale: locale, brightness: brightness),
          );
          await expectLater(
            find.byKey(captureKey),
            matchesGoldenFile('direction_grammar_${name}_$theme.png'),
          );
        });
      }
    }
  });

  group('privacy mode', () {
    // Paired on purpose: the two images must have identical geometry, and a
    // reviewer can see that at a glance by flipping between them.
    for (final (name, masked) in [('visible', false), ('masked', true)]) {
      testWidgets('rtl · $name', (tester) async {
        await tester.pumpWidget(
          _frame(
            _directionGrammar,
            locale: _arabic,
            brightness: Brightness.light,
            masked: masked,
          ),
        );
        await expectLater(
          find.byKey(captureKey),
          matchesGoldenFile('privacy_rtl_$name.png'),
        );
      });
    }
  });

  group('account classes', () {
    // The whole point of this board: seven rows that must stay distinguishable
    // with colour contributing nothing.
    for (final (name, locale) in [('ltr', _english), ('rtl', _arabic)]) {
      for (final (theme, brightness) in [
        ('light', Brightness.light),
        ('dark', Brightness.dark),
      ]) {
        testWidgets('$name · $theme', (tester) async {
          // Seven tiles do not fit the default 600 dp test surface, and a
          // scroll view would clip the board rather than show it.
          await tester.binding.setSurfaceSize(const Size(420, 1000));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            _frame(_accountClasses, locale: locale, brightness: brightness),
          );
          await expectLater(
            find.byKey(captureKey),
            matchesGoldenFile('account_classes_${name}_$theme.png'),
          );
        });
      }
    }
  });

  group('progress meter', () {
    for (final (name, locale) in [('ltr', _english), ('rtl', _arabic)]) {
      testWidgets('$name · light', (tester) async {
        await tester.pumpWidget(
          _frame(_meters, locale: locale, brightness: Brightness.light),
        );
        await expectLater(
          find.byKey(captureKey),
          matchesGoldenFile('progress_meter_$name.png'),
        );
      });
    }
  });

  group('financial summary', () {
    for (final (name, locale) in [('ltr', _english), ('rtl', _arabic)]) {
      testWidgets('$name · light', (tester) async {
        await tester.pumpWidget(
          _frame(_summary, locale: locale, brightness: Brightness.light),
        );
        await expectLater(
          find.byKey(captureKey),
          matchesGoldenFile('financial_summary_$name.png'),
        );
      });
    }
  });
}
