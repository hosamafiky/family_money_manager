/// Widget tests for IncomeExpenseReportScreen (Phase 4B).
///
/// Tests:
///  1. Shows gross income amount
///  2. Shows gross expense amount
///  3. Shows reversal effect when present
///  4. Transfer note displayed
///  5. Currency note displayed
///  6. No mixed-currency total shown
///  7. Empty state shown when no data
///  8. Error state with retry button
///  9. Period selector visible
/// 10. Refresh button triggers reload
library;

import 'dart:async';

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/income_expense_report_screen.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier(this._locale);
  final Locale _locale;

  @override
  Locale build() => _locale;
}

class _FixedThemeModeNotifier extends ThemeModeNotifier {
  _FixedThemeModeNotifier(this._mode);
  final ThemeMode _mode;

  @override
  ThemeMode build() => _mode;
}

class _FixedRequestNotifier extends ReportRequestNotifier {
  @override
  FinancialReportRequest build() => FinancialReportRequest(
    householdId: 'household-v1',
    period: DashboardPeriod.custom(
      startDate: '2025-01-01',
      endDate: '2025-02-01',
    ),
  );
}

Widget _buildScreen({
  AppResult<List<CurrencyFlowSummary>>? result,
  bool loading = false,
  bool throwError = false,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      appThemeModeProvider.overrideWith(
        () => _FixedThemeModeNotifier(ThemeMode.light),
      ),
      reportRequestProvider.overrideWith(_FixedRequestNotifier.new),
      incomeExpenseReportProvider.overrideWith((ref, req) async {
        if (loading) {
          return Completer<AppResult<List<CurrencyFlowSummary>>>().future;
        }
        if (throwError) throw Exception('Fake error');
        return result ?? const AppOk([]);
      }),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const IncomeExpenseReportScreen(),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('IncomeExpenseReportScreen', () {
    testWidgets('1. Shows gross income amount', (tester) async {
      const result = AppOk([
        CurrencyFlowSummary(
          currencyCode: 'EGP',
          grossIncomeMinorUnits: 10000,
          grossExpenseMinorUnits: 3000,
        ),
      ]);
      await tester.pumpWidget(_buildScreen(result: result));
      await tester.pumpAndSettle();

      // Gross income label and amount
      expect(find.text('Gross Income'), findsOneWidget);
      expect(find.textContaining('100.00'), findsWidgets);
    });

    testWidgets('2. Shows gross expense amount', (tester) async {
      const result = AppOk([
        CurrencyFlowSummary(
          currencyCode: 'EGP',
          grossIncomeMinorUnits: 10000,
          grossExpenseMinorUnits: 5000,
        ),
      ]);
      await tester.pumpWidget(_buildScreen(result: result));
      await tester.pumpAndSettle();

      expect(find.text('Gross Expenses'), findsOneWidget);
    });

    testWidgets('3. Shows reversal effect when present', (tester) async {
      const result = AppOk([
        CurrencyFlowSummary(
          currencyCode: 'EGP',
          grossIncomeMinorUnits: 10000,
          grossExpenseMinorUnits: 5000,
          expenseReversalMinorUnits: 2000,
        ),
      ]);
      await tester.pumpWidget(_buildScreen(result: result));
      await tester.pumpAndSettle();

      expect(find.text('Reversal Effect'), findsWidgets);
      expect(find.text('Net Expenses'), findsOneWidget);
    });

    testWidgets('4. Transfer note displayed', (tester) async {
      const result = AppOk([
        CurrencyFlowSummary(
          currencyCode: 'EGP',
          grossIncomeMinorUnits: 5000,
          grossExpenseMinorUnits: 0,
        ),
      ]);
      await tester.pumpWidget(_buildScreen(result: result));
      await tester.pumpAndSettle();

      expect(find.textContaining('Transfers are not included'), findsOneWidget);
    });

    testWidgets('5. Currency note displayed', (tester) async {
      const result = AppOk([
        CurrencyFlowSummary(
          currencyCode: 'EGP',
          grossIncomeMinorUnits: 5000,
          grossExpenseMinorUnits: 0,
        ),
      ]);
      await tester.pumpWidget(_buildScreen(result: result));
      await tester.pumpAndSettle();

      expect(find.textContaining('Totals shown per currency'), findsOneWidget);
    });

    testWidgets('6. No mixed-currency total shown', (tester) async {
      const result = AppOk([
        CurrencyFlowSummary(
          currencyCode: 'EGP',
          grossIncomeMinorUnits: 5000,
          grossExpenseMinorUnits: 0,
        ),
        CurrencyFlowSummary(
          currencyCode: 'USD',
          grossIncomeMinorUnits: 2000,
          grossExpenseMinorUnits: 0,
        ),
      ]);
      await tester.pumpWidget(_buildScreen(result: result));
      await tester.pumpAndSettle();

      // Should show two separate currency sections, no combined total
      expect(find.text('EGP'), findsWidgets);
      expect(find.text('USD'), findsWidgets);
      // No "Total" label mixing currencies
      expect(find.text('Total'), findsNothing);
    });

    testWidgets('7. Empty state shown when no data', (tester) async {
      await tester.pumpWidget(_buildScreen(result: const AppOk([])));
      await tester.pumpAndSettle();

      expect(find.text('No data for this period.'), findsOneWidget);
    });

    testWidgets('8. Error state with retry button', (tester) async {
      await tester.pumpWidget(_buildScreen(throwError: true));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load report.'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('9. Period selector visible', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('10. Refresh button triggers reload', (tester) async {
      var callCount = 0;
      const result = AppOk([
        CurrencyFlowSummary(
          currencyCode: 'EGP',
          grossIncomeMinorUnits: 5000,
          grossExpenseMinorUnits: 0,
        ),
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('en')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            reportRequestProvider.overrideWith(_FixedRequestNotifier.new),
            incomeExpenseReportProvider.overrideWith((ref, req) async {
              callCount++;
              return result;
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: IncomeExpenseReportScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final countBefore = callCount;
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(callCount, greaterThan(countBefore));
    });
  });
}
