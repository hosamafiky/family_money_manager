/// Widget tests for SpendingAttributionReportScreen (Phase 4B).
///
/// Tests:
/// 1. Shows spender section
/// 2. Shows scope section
/// 3. RTL Arabic layout
/// 4. Empty state shown
/// 5. Error + retry button shown
/// 6. Currency separation note present
library;

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/reports/application/get_spending_attribution_report_use_case.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/spending_attribution_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  AppResult<SpendingAttributionReport>? result,
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
      spendingAttributionReportProvider.overrideWith((ref, req) async {
        if (throwError) throw Exception('Fake error');
        return result ??
            const AppOk(
              SpendingAttributionReport(
                bySpender: [],
                byBeneficiary: [],
                byScope: [],
              ),
            );
      }),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SpendingAttributionReportScreen(),
    ),
  );
}

SpendingAttributionReport _sampleReport() => const SpendingAttributionReport(
  bySpender: [
    MemberSpendingBreakdown(
      memberId: 'member-1',
      memberDisplayName: 'Alice',
      currencyCode: 'EGP',
      totalMinorUnits: 5000,
      transactionCount: 3,
    ),
  ],
  byBeneficiary: [],
  byScope: [
    ExpenseScopeBreakdown(
      scope: ExpenseScope.personal,
      currencyCode: 'EGP',
      totalMinorUnits: 3000,
      transactionCount: 2,
    ),
  ],
);

void main() {
  group('SpendingAttributionReportScreen', () {
    testWidgets('1. Shows spender section with member name', (tester) async {
      await tester.pumpWidget(_buildScreen(result: AppOk(_sampleReport())));
      await tester.pumpAndSettle();

      expect(find.text('By Spender'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('2. Shows scope section', (tester) async {
      await tester.pumpWidget(_buildScreen(result: AppOk(_sampleReport())));
      await tester.pumpAndSettle();

      expect(find.text('By Scope'), findsOneWidget);
    });

    testWidgets('3. RTL Arabic layout shown correctly', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          result: AppOk(_sampleReport()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // Arabic attribution title
      expect(find.text('نسب الإنفاق'), findsOneWidget);
    });

    testWidgets('4. Empty state shown when no data', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          result: const AppOk(
            SpendingAttributionReport(
              bySpender: [],
              byBeneficiary: [],
              byScope: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No data for this period.'), findsOneWidget);
    });

    testWidgets('5. Error state with retry button', (tester) async {
      await tester.pumpWidget(_buildScreen(throwError: true));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load report.'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('6. Currency separation note present', (tester) async {
      await tester.pumpWidget(_buildScreen(result: AppOk(_sampleReport())));
      await tester.pumpAndSettle();

      expect(find.textContaining('Totals shown per currency'), findsOneWidget);
    });
  });
}
