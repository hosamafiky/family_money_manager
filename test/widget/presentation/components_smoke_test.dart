/// Smoke coverage that the shared kit renders in a real MaterialApp.
///
/// Behavioural guarantees live in the dedicated money-primitive tests; this
/// file only proves the components mount and compose.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  theme: AppTheme.light(locale: locale),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('the money primitives mount and compose', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            FinancialAmountText(
              minorUnits: 127500,
              currencyCode: 'EGP',
              tone: FinancialAmountTone.expense,
              direction: FinancialAmountDirection.outflow,
            ),
            CurrencyAmountRow(
              label: 'Transfer fee',
              minorUnits: 1500,
              currencyCode: 'EGP',
              tone: FinancialAmountTone.expense,
              direction: FinancialAmountDirection.outflow,
            ),
            FinancialSummary(
              metrics: [
                FinancialMetric(
                  label: 'Given',
                  minorUnits: 600000,
                  currencyCode: 'EGP',
                ),
                FinancialMetric(
                  label: 'Remaining',
                  minorUnits: 438250,
                  currencyCode: 'EGP',
                  isEmphasised: true,
                ),
              ],
            ),
            ProgressMeter(
              consumedMinorUnits: 241000,
              totalMinorUnits: 350000,
              currencyCode: 'EGP',
              stateLabel: 'On track',
              role: ProgressMeterRole.budget,
              label: 'Groceries',
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('1,275.00'), findsNothing); // wrapped in a bidi isolate
    expect(find.textContaining('1,275.00'), findsOneWidget);
    expect(find.text('Transfer fee'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('the state components still mount', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            AppLoadingState(message: 'Loading'),
            AppEmptyState(title: 'Nothing here'),
            AppInlineNotice(message: 'This is a transfer'),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
