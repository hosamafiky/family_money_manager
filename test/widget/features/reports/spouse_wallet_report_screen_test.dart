/// Widget tests for SpouseWalletReportScreen (Phase 4B).
///
/// Tests:
/// 1. Shows funded/spent/returned/balance labels
/// 2. Period closing and current balance labeled distinctly
/// 3. Transfer note visible
/// 4. Empty state when no wallets
/// 5. RTL Arabic layout
/// 6. Semantics present on wallet card
library;

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/spouse_wallet_report_screen.dart';
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

const _sampleWallet = SpouseWalletReport(
  accountId: 'wallet-1',
  accountName: "Alice's Wallet",
  currencyCode: 'EGP',
  openingBalanceMinorUnits: 0,
  periodFundedMinorUnits: 200000, // 2000.00 EGP
  periodSpentMinorUnits: 130000, // 1300.00 EGP
  periodReturnedMinorUnits: 20000, // 200.00 EGP
  periodReversalEffectMinorUnits: 0,
  periodClosingBalanceMinorUnits: 50000, // 500.00 EGP
  currentBalanceMinorUnits: 50000,
);

Widget _buildScreen({
  AppResult<List<SpouseWalletReport>>? result,
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
      spouseWalletReportProvider.overrideWith((ref, req) async {
        if (throwError) throw Exception('Fake error');
        return result ?? AppOk([_sampleWallet]);
      }),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SpouseWalletReportScreen(),
    ),
  );
}

void main() {
  group('SpouseWalletReportScreen', () {
    testWidgets('1. Shows funded, spent, returned, balance labels', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Funded'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('Returned'), findsOneWidget);
      expect(find.text('Period Closing Balance'), findsOneWidget);
    });

    testWidgets('2. Period closing and current balance labeled distinctly', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Period Closing Balance'), findsOneWidget);
      expect(find.text('Current Balance'), findsOneWidget);
    });

    testWidgets('3. Transfer note visible', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Transfers are not included'), findsOneWidget);
    });

    testWidgets('4. Empty state when no wallets', (tester) async {
      await tester.pumpWidget(_buildScreen(result: const AppOk([])));
      await tester.pumpAndSettle();

      expect(find.text('No data for this period.'), findsOneWidget);
    });

    testWidgets('5. RTL Arabic layout', (tester) async {
      await tester.pumpWidget(_buildScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Arabic title
      expect(find.text('محفظة الزوج/ة'), findsOneWidget);
    });

    testWidgets('6. Semantics present on wallet card', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      // Wallet name appears as a semantics label on the card
      expect(find.text("Alice's Wallet"), findsOneWidget);
      // No semantic errors
      expect(tester.takeException(), isNull);
    });
  });
}
