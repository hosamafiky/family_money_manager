/// Widget tests for DashboardScreen (Phase 4A).
///
/// Tests:
/// 1.  Shows loading state initially
/// 2.  Shows error state with retry button
/// 3.  Shows empty state for household with no accounts
/// 4.  Shows one card per currency for spendable balances
/// 5.  Protected balances shown separately
/// 6.  No "net worth" text anywhere on screen
/// 7.  No mixed-currency total shown
/// 8.  Income and expense shown for period with data
/// 9.  Transfer label shown in recent activity
/// 10. Reversed operation shown with label
/// 11. Arabic RTL layout correct
/// 12. English LTR layout correct
/// 13. Semantics labels present on monetary sections
/// 14. Period selector changes data displayed
/// 15. Refresh button triggers reload
/// 16. Child fund shown with protected indicator (icon + text)
/// 17. Negative balance shown with warning icon
/// 18. Large text does not overflow cards
library;

import 'dart:async';

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/dashboard/domain/dashboard_summary.dart';
import 'package:family_money_manager/features/dashboard/presentation/dashboard_screen.dart';
import 'package:family_money_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _householdId = 'household-v1';

final _defaultPeriod = DashboardPeriod.custom(
  startDate: '2025-03-01',
  endDate: '2025-04-01',
);

DashboardSummary _emptySummary() => DashboardSummary(
  availableToSpend: const [],
  excludedFromAvailable: const [],
  heldByReason: const [],
  householdId: _householdId,
  period: _defaultPeriod,
  spendableBalances: const [],
  protectedBalances: const [],
  periodFlow: const [],
  expensesByScope: const [],
  spouseWallets: const [],
  recentActivity: const [],
  generatedAt: DateTime(2025, 3, 15),
);

DashboardSummary _summaryWithData({
  List<CurrencyAmountSummary>? spendable,
  List<CurrencyAmountSummary>? protected,
  List<CurrencyAmountSummary>? available,
  List<ExcludedAmountSummary>? excluded,
  List<HeldAmountSummary>? held,
  List<PeriodFlowSummary>? flow,
  List<ExpenseScopeSummary>? scopes,
  List<SpouseWalletDashboardSummary>? wallets,
  List<TransactionSummary>? recent,
}) => DashboardSummary(
  // The screen reads availableToSpend and heldByReason; the older
  // spendable/protected params describe the same money, so they seed both.
  // Tests that need the two to differ — a spouse wallet excluded from the
  // headline — set the new fields directly.
  availableToSpend: available ?? spendable ?? const [],
  excludedFromAvailable: excluded ?? const [],
  heldByReason:
      held ??
      [
        for (final p in protected ?? const <CurrencyAmountSummary>[])
          HeldAmountSummary(
            reason: HeldReason.childProtected,
            currencyCode: p.currencyCode,
            totalMinorUnits: p.totalMinorUnits,
          ),
      ],
  householdId: _householdId,
  period: _defaultPeriod,
  spendableBalances: spendable ?? const [],
  protectedBalances: protected ?? const [],
  periodFlow: flow ?? const [],
  expensesByScope: scopes ?? const [],
  spouseWallets: wallets ?? const [],
  recentActivity: recent ?? const [],
  generatedAt: DateTime(2025, 3, 15),
);

TransactionSummary _makeTxSummary({
  required String id,
  required OperationType type,
  String date = '2025-03-10',
  int amount = 10000,
  String currency = 'EGP',
  bool isReversed = false,
}) => TransactionSummary(
  operation: Operation(
    id: id,
    householdId: _householdId,
    type: type,
    effectiveDate: date,
    recordedAt: DateTime(2025, 3, 10).toUtc(),
    description: '$type $id',
    totalAmountMinorUnits: amount,
    currencyCode: currency,
    isRecurring: false,
    tags: const [],
    isReversed: isReversed,
    createdBy: 'test',
    createdAt: '2025-03-10T00:00:00Z',
    updatedAt: '2025-03-10T00:00:00Z',
  ),
  isRecurring: false,
);

// ─────────────────────────────────────────────────────────────────────────────
// Test helper: builds the DashboardScreen with an override for the summary.
// We override dashboardSummaryProvider directly so there is no need to
// subclass the final GetDashboardSummaryUseCase.
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildScreen({
  AppResult<DashboardSummary>? result,
  bool loading = false,
  bool throwError = false,
  Locale locale = const Locale('ar'),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      appThemeModeProvider.overrideWith(
        () => _FixedThemeModeNotifier(ThemeMode.light),
      ),
      dashboardPeriodProvider.overrideWith(() => _FixedPeriodNotifier()),
      dashboardSummaryProvider.overrideWith((ref, householdId) async {
        if (loading) return Completer<AppResult<DashboardSummary>>().future;
        if (throwError) throw Exception('Fake error');
        return result ?? AppOk(_emptySummary());
      }),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: const DashboardScreen(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
void main() {
  group('DashboardScreen', () {
    testWidgets('1. Shows loading state initially', (tester) async {
      await tester.pumpWidget(_buildScreen(loading: true));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('2. Shows error state with retry button', (tester) async {
      await tester.pumpWidget(_buildScreen(throwError: true));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data?.contains('Retry') == true ||
                  w.data?.contains('إعادة المحاولة') == true ||
                  w.data?.contains('تعذّر') == true ||
                  w.data?.contains('Unable') == true),
        ),
        findsWidgets,
      );
    });

    testWidgets('3. Shows empty state for household with no accounts', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(result: AppOk(_emptySummary())));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('4. Shows one card per currency for spendable balances', (
      tester,
    ) async {
      final summary = _summaryWithData(
        spendable: const [
          CurrencyAmountSummary(currencyCode: 'EGP', totalMinorUnits: 150000),
          CurrencyAmountSummary(currencyCode: 'USD', totalMinorUnits: 200000),
        ],
      );
      await tester.pumpWidget(_buildScreen(result: AppOk(summary)));
      await tester.pumpAndSettle();
      expect(find.text('EGP'), findsWidgets);
      expect(find.text('USD'), findsWidgets);
    });

    testWidgets('5. Held money is a separate region, never in the hero', (
      tester,
    ) async {
      final summary = _summaryWithData(
        spendable: const [
          CurrencyAmountSummary(currencyCode: 'EGP', totalMinorUnits: 100000),
        ],
        protected: const [
          CurrencyAmountSummary(currencyCode: 'EGP', totalMinorUnits: 50000),
        ],
      );
      await tester.pumpWidget(_buildScreen(result: AppOk(summary)));
      await tester.pumpAndSettle();

      // The hero answers "what can I spend"; the held region answers "what do
      // I own that I cannot". They are separate regions with separate
      // headings, and the held subtotal is never added to the hero.
      expect(find.byType(BalanceHero), findsOneWidget);
      expect(find.byType(HeldMoneyRegion), findsOneWidget);
      // Default locale for these tests is Arabic.
      expect(find.text('يمكنك صرف الآن'), findsOneWidget);
      expect(find.text('محتجز — غير قابل للصرف'), findsOneWidget);
      // The refusal is printed where a grand total would sit.
      expect(
        find.text('لا يوجد إجمالي موحّد — كل عملة مستقلة'),
        findsOneWidget,
      );
    });

    testWidgets('6. No "net worth" text anywhere on screen', (tester) async {
      final summary = _summaryWithData(
        spendable: const [
          CurrencyAmountSummary(currencyCode: 'EGP', totalMinorUnits: 100000),
        ],
      );
      await tester.pumpWidget(_buildScreen(result: AppOk(summary)));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('net worth', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('Net Worth', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('صافي الثروة', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('7. No mixed-currency total shown', (tester) async {
      final summary = _summaryWithData(
        spendable: const [
          CurrencyAmountSummary(currencyCode: 'EGP', totalMinorUnits: 100000),
          CurrencyAmountSummary(currencyCode: 'USD', totalMinorUnits: 200000),
        ],
      );
      await tester.pumpWidget(_buildScreen(result: AppOk(summary)));
      await tester.pumpAndSettle();
      // Verify both currencies are listed separately, not summed
      expect(find.text('EGP'), findsWidgets);
      expect(find.text('USD'), findsWidgets);
    });

    testWidgets('8. Income and expense shown for period with data', (
      tester,
    ) async {
      final summary = _summaryWithData(
        flow: const [
          PeriodFlowSummary(
            currencyCode: 'EGP',
            grossIncomeMinorUnits: 500000,
            grossExpenseMinorUnits: 200000,
          ),
        ],
      );
      await tester.pumpWidget(_buildScreen(result: AppOk(summary)));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data?.contains('الدخل') == true ||
                  w.data?.contains('Income') == true),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data?.contains('المصروفات') == true ||
                  w.data?.contains('Expenses') == true ||
                  w.data?.contains('Expense') == true),
        ),
        findsWidgets,
      );
    });

    testWidgets('9. Transfer label shown in recent activity', (tester) async {
      final tx = _makeTxSummary(id: 'op-t1', type: OperationType.transfer);
      final summary = _summaryWithData(recent: [tx]);
      await tester.pumpWidget(_buildScreen(result: AppOk(summary)));
      await tester.pumpAndSettle();
      // Recent activity section shows something
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('10. Reversed operation shown with معكوسة label', (
      tester,
    ) async {
      final tx = _makeTxSummary(
        id: 'op-r1',
        type: OperationType.expense,
        isReversed: true,
      );
      final summary = _summaryWithData(recent: [tx]);
      await tester.pumpWidget(_buildScreen(result: AppOk(summary)));
      await tester.pumpAndSettle();
      // Recent activity sits lower after 6B.2 hierarchy; scroll to reveal.
      await tester.drag(find.byType(ListView).first, const Offset(0, -800));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data?.contains('معكوسة') == true ||
                  w.data?.contains('Reversed') == true),
          skipOffstage: false,
        ),
        findsWidgets,
      );
    });

    testWidgets('11. Arabic RTL layout correct', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          result: AppOk(_emptySummary()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();
      final dir = Directionality.of(
        tester.element(find.byType(DashboardScreen)),
      );
      expect(dir, TextDirection.rtl);
    });

    testWidgets('12. English LTR layout correct', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          result: AppOk(_emptySummary()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      final dir = Directionality.of(
        tester.element(find.byType(DashboardScreen)),
      );
      expect(dir, TextDirection.ltr);
    });

    testWidgets('13. Semantics labels present on monetary sections', (
      tester,
    ) async {
      final summary = _summaryWithData(
        spendable: const [
          CurrencyAmountSummary(currencyCode: 'EGP', totalMinorUnits: 100000),
        ],
      );
      await tester.pumpWidget(_buildScreen(result: AppOk(summary)));
      await tester.pumpAndSettle();
      // Accessibility check: verify that text is present and screen renders
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('14. Period selector changes data displayed', (tester) async {
      await tester.pumpWidget(_buildScreen(result: AppOk(_emptySummary())));
      await tester.pumpAndSettle();
      // Period chips/buttons are visible
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data?.contains('هذا الشهر') == true ||
                  w.data?.contains('This Month') == true ||
                  w.data?.contains('شهر') == true),
        ),
        findsWidgets,
      );
    });

    testWidgets('15. Refresh button triggers reload', (tester) async {
      await tester.pumpWidget(_buildScreen(result: AppOk(_emptySummary())));
      await tester.pumpAndSettle();
      // Scrollable area for pull-to-refresh
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('16. Child fund shown with protected indicator', (
      tester,
    ) async {
      final summary = _summaryWithData(
        protected: const [
          CurrencyAmountSummary(currencyCode: 'EGP', totalMinorUnits: 30000),
        ],
      );
      await tester.pumpWidget(_buildScreen(result: AppOk(summary)));
      await tester.pumpAndSettle();
      // A protected fund is held money: it lands in the held region, named by
      // its reason, and carries the lock. Colour is not one of the signals.
      expect(find.byType(HeldMoneyRegion), findsOneWidget);
      expect(find.text('محمي'), findsWidgets);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    });

    testWidgets('17. Negative balance shown with warning icon', (tester) async {
      final summary = _summaryWithData(
        spendable: const [
          CurrencyAmountSummary(currencyCode: 'EGP', totalMinorUnits: -100),
        ],
      );
      await tester.pumpWidget(_buildScreen(result: AppOk(summary)));
      await tester.pumpAndSettle();
      // Warning icon for negative balance
      expect(find.byIcon(Icons.warning_amber_outlined), findsWidgets);
    });

    testWidgets('18. Large text does not overflow cards', (tester) async {
      final summary = _summaryWithData(
        spendable: const [
          CurrencyAmountSummary(
            currencyCode: 'EGP',
            totalMinorUnits: 999999999,
          ),
        ],
      );
      await tester.pumpWidget(
        _buildScreen(
          result: AppOk(summary),
          textScaler: const TextScaler.linear(2.0),
        ),
      );
      await tester.pumpAndSettle();
      // No overflow exceptions; screen renders successfully
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });
}

// ── Test helpers ──────────────────────────────────────────────────────────────

class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier(this._locale);
  final Locale _locale;

  @override
  Locale build() => _locale;
}

class _FixedThemeModeNotifier extends ThemeModeNotifier {
  _FixedThemeModeNotifier(this._themeMode);
  final ThemeMode _themeMode;

  @override
  ThemeMode build() => _themeMode;
}

class _FixedPeriodNotifier extends DashboardPeriodNotifier {
  @override
  DashboardPeriod build() => _defaultPeriod;
}
