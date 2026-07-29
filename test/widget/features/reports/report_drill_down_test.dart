/// The report drill-down.
///
/// `ReportFilter` supported every dimension from the start and no screen ever
/// set one, so the drill-down list existed but nothing could reach it. These
/// tests pin the wiring: a breakdown figure is a claim about a set of
/// transactions, tapping it filters to that set, and the period it was
/// computed in is carried over unchanged.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/reports/application/get_category_report_use_case.dart';
import 'package:family_money_manager/features/reports/application/get_spending_attribution_report_use_case.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/category_report_screen.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:family_money_manager/features/reports/presentation/spending_attribution_report_screen.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _period = DashboardPeriod.custom(
  startDate: '2026-07-01',
  endDate: '2026-08-01',
);

const _categoryReport = CategoryReport(
  expenseByCategory: [
    CategoryBreakdown(
      categoryCode: 'groceries',
      categoryType: CategoryType.expense,
      currencyCode: 'EGP',
      totalMinorUnits: 324000,
      transactionCount: 12,
    ),
  ],
  incomeByCategory: [],
);

const _attributionReport = SpendingAttributionReport(
  bySpender: [
    MemberSpendingBreakdown(
      memberId: 'member-hana',
      memberDisplayName: 'هناء',
      currencyCode: 'EGP',
      totalMinorUnits: 210000,
      transactionCount: 8,
    ),
  ],
  byBeneficiary: [],
  byScope: [
    ExpenseScopeBreakdown(
      scope: ExpenseScope.household,
      currencyCode: 'EGP',
      totalMinorUnits: 450000,
      transactionCount: 20,
    ),
  ],
);

/// Captures the request the drill-down screen would be built with.
FinancialReportRequest? capturedRequest;

Widget _buildApp(Widget screen) {
  final router = GoRouter(
    initialLocation: '/reports',
    routes: [
      GoRoute(
        path: '/reports',
        builder: (_, _) => screen,
        routes: [
          GoRoute(
            path: 'transactions',
            builder: (_, _) => const _CapturingDrillDown(),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase.forTesting();
        ref.onDispose(db.close);
        return db;
      }),
      reportRequestProvider.overrideWith(_TestRequestNotifier.new),
      categoryReportProvider.overrideWith(
        (ref, _) async => const AppOk(_categoryReport),
      ),
      spendingAttributionReportProvider.overrideWith(
        (ref, _) async => const AppOk(_attributionReport),
      ),
    ],
    child: MaterialApp.router(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
}

/// A request notifier with a fixed period, so the test can assert the period
/// survives a drill-down rather than asserting on today's date.
class _TestRequestNotifier extends ReportRequestNotifier {
  @override
  FinancialReportRequest build() =>
      FinancialReportRequest(householdId: 'household-v1', period: _period);
}

class _CapturingDrillDown extends ConsumerWidget {
  const _CapturingDrillDown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    capturedRequest = ref.watch(reportRequestProvider);
    return const Scaffold(body: Text('Drill-down'));
  }
}

void main() {
  setUp(() {
    capturedRequest = null;
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 3200);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  testWidgets('a category figure drills down to its own category', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const CategoryReportScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CurrencyAmountRow).first);
    await tester.pumpAndSettle();

    expect(find.text('Drill-down'), findsOneWidget);
    expect(capturedRequest!.filter.categoryCodes, ['groceries']);
    // Nothing else is filtered: two chained dimensions would produce a list
    // matching neither figure.
    expect(capturedRequest!.filter.spenderMemberIds, isEmpty);
    expect(capturedRequest!.filter.scopes, isEmpty);
  });

  testWidgets('the period the figure was computed in is carried over', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const CategoryReportScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CurrencyAmountRow).first);
    await tester.pumpAndSettle();

    expect(capturedRequest!.period.startDate, '2026-07-01');
    expect(capturedRequest!.period.endDate, '2026-08-01');
  });

  testWidgets('a spender figure drills down by spender', (tester) async {
    await tester.pumpWidget(_buildApp(const SpendingAttributionReportScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('هناء'));
    await tester.pumpAndSettle();

    expect(capturedRequest!.filter.spenderMemberIds, ['member-hana']);
    expect(capturedRequest!.filter.scopes, isEmpty);
  });

  testWidgets('a scope figure drills down by scope', (tester) async {
    await tester.pumpWidget(_buildApp(const SpendingAttributionReportScreen()));
    await tester.pumpAndSettle();

    // The scope row is the second breakdown row on this screen.
    await tester.tap(find.byType(CurrencyAmountRow).last);
    await tester.pumpAndSettle();

    expect(capturedRequest!.filter.scopes, [ExpenseScope.household]);
    expect(capturedRequest!.filter.spenderMemberIds, isEmpty);
  });

  testWidgets('a tappable row says so — chevron and button semantics', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const CategoryReportScreen()));
    await tester.pumpAndSettle();

    // RTL, so the chevron points left.
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);

    expect(
      tester.getSemantics(find.byType(CurrencyAmountRow).first),
      isSemantics(isButton: true),
    );
  });

  testWidgets(
    'the category chart draws only figures the table above it already shows',
    (tester) async {
      await tester.pumpWidget(_buildApp(const CategoryReportScreen()));
      await tester.pumpAndSettle();

      final chart = tester.widget<BarSeries>(find.byType(BarSeries));
      final rows = tester.widgetList<CurrencyAmountRow>(
        find.byType(CurrencyAmountRow),
      );

      // One bar per row, and each bar's figure is a figure on screen. A chart
      // that could show a number absent from its table would be unauditable.
      expect(chart.bars, hasLength(rows.length));
      for (final bar in chart.bars) {
        expect(find.text(bar.valueLabel), findsWidgets);
      }
    },
  );
}
