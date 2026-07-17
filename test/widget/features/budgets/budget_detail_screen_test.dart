/// Widget tests for BudgetDetailScreen (Phase 5A).
///
/// Tests:
///  1. Budget name shown in AppBar
///  2. Consumed and limit shown (formatted amounts)
///  3. Remaining label shown
///  4. Status text shown (not color-only)
///  5. Progress bar present
///  6. Reversal note shown
///  7. Drill-down transactions listed
///  8. Archive button present
///  9. Monthly budget shows previous periods section
/// 10. Arabic RTL layout
library;

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';
import 'package:family_money_manager/features/budgets/presentation/budget_detail_screen.dart';
import 'package:family_money_manager/features/budgets/presentation/providers/budget_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

BudgetPlan _fakePlan({String id = 'b1', String name = 'Test Budget', bool monthly = true, bool archived = false}) => BudgetPlan(
  id: id,
  householdId: 'household-v1',
  name: name,
  currencyCode: 'EGP',
  limitMinorUnits: 100000,
  periodDefinition: monthly ? const MonthlyBudgetPeriod() : const FixedBudgetPeriod(startDateInclusive: '2024-01-01', endDateExclusive: '2024-06-01'),
  filter: const BudgetFilter(),
  isArchived: archived,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
  idempotencyKey: 'ik-$id',
  idempotencyPayload: 'p-$id',
);

BudgetProgress _fakeProgress(BudgetPlan plan, {int consumed = 40000, List<BudgetTransactionRow> drillDown = const []}) => BudgetProgress(
  budget: plan,
  periodStart: '2024-01-01',
  periodEnd: '2024-02-01',
  consumedMinorUnits: consumed,
  limitMinorUnits: plan.limitMinorUnits,
  currencyCode: plan.currencyCode,
  matchingTransactionCount: drillDown.length,
  usageState: consumed == 0 ? BudgetUsageState.noSpending : BudgetUsageState.onTrack,
  drillDown: drillDown,
);

Widget _buildDetailScreen({
  required String budgetId,
  required AppResult<BudgetProgress> progressResult,
  AppResult<List<BudgetProgress>> historyResult = const AppOk(<BudgetProgress>[]),
  Locale locale = const Locale('en'),
}) {
  final router = GoRouter(
    initialLocation: '/budgets/$budgetId',
    routes: [
      GoRoute(
        path: '/budgets',
        builder: (_, _) => const Scaffold(body: Text('Budgets')),
        routes: [
          GoRoute(
            path: ':budgetId',
            builder: (context, state) => BudgetDetailScreen(budgetId: state.pathParameters['budgetId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/transactions/:opId',
        builder: (context, state) => Scaffold(body: Text('Tx:${state.pathParameters['opId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
      budgetProgressProvider.overrideWith((ref, _) async => progressResult),
      budgetHistoryProvider.overrideWith((ref, _) async => historyResult),
      budgetDetailProvider.overrideWith((ref, _) async {
        if (progressResult is AppOk<BudgetProgress>) {
          return AppOk(progressResult.value.budget);
        }
        return const AppNotFound<BudgetPlan?>();
      }),
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('BudgetDetailScreen', () {
    testWidgets('1. Budget name shown in AppBar', (tester) async {
      final plan = _fakePlan(name: 'House Budget');
      final progress = _fakeProgress(plan);

      await tester.pumpWidget(_buildDetailScreen(budgetId: 'b1', progressResult: AppOk(progress)));
      await tester.pumpAndSettle();

      // Name appears in AppBar title and in the body summary card
      expect(find.text('House Budget'), findsWidgets);
    });

    testWidgets('2. Consumed and limit shown (formatted amounts)', (tester) async {
      final plan = _fakePlan();
      final progress = _fakeProgress(plan, consumed: 40000);

      await tester.pumpWidget(_buildDetailScreen(budgetId: 'b1', progressResult: AppOk(progress)));
      await tester.pumpAndSettle();

      // formatMinorUnits(40000, 'EGP') → 'EGP 400.00'
      // formatMinorUnits(100000, 'EGP') → 'EGP 1000.00'
      expect(find.textContaining('EGP 400.00'), findsWidgets);
      expect(find.textContaining('EGP 1000.00'), findsWidgets);
    });

    testWidgets('3. Remaining label shown', (tester) async {
      final plan = _fakePlan();
      final progress = _fakeProgress(plan, consumed: 40000);

      await tester.pumpWidget(_buildDetailScreen(budgetId: 'b1', progressResult: AppOk(progress)));
      await tester.pumpAndSettle();

      expect(find.text('Remaining'), findsOneWidget);
    });

    testWidgets('4. Status text shown (not color-only)', (tester) async {
      final plan = _fakePlan();
      final progress = _fakeProgress(plan, consumed: 40000);

      await tester.pumpWidget(_buildDetailScreen(budgetId: 'b1', progressResult: AppOk(progress)));
      await tester.pumpAndSettle();

      // "On track" text visible alongside the icon
      expect(find.text('On track'), findsWidgets);
    });

    testWidgets('5. Progress bar present', (tester) async {
      final plan = _fakePlan();
      final progress = _fakeProgress(plan, consumed: 40000);

      await tester.pumpWidget(_buildDetailScreen(budgetId: 'b1', progressResult: AppOk(progress)));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('6. Reversal note shown', (tester) async {
      final plan = _fakePlan();
      final progress = _fakeProgress(plan);

      await tester.pumpWidget(_buildDetailScreen(budgetId: 'b1', progressResult: AppOk(progress)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Fully reversed expenses'), findsOneWidget);
    });

    testWidgets('7. Drill-down transactions listed', (tester) async {
      final plan = _fakePlan();
      const tx = BudgetTransactionRow(
        operationId: 'op-1',
        effectiveDate: '2024-01-15',
        amountMinorUnits: 5000,
        currencyCode: 'EGP',
        categoryCode: 'food',
        note: null,
        isReversed: false,
      );
      final progress = _fakeProgress(plan, consumed: 5000, drillDown: [tx]);

      await tester.pumpWidget(_buildDetailScreen(budgetId: 'b1', progressResult: AppOk(progress)));
      await tester.pumpAndSettle();

      expect(find.textContaining('2024-01-15'), findsOneWidget);
    });

    testWidgets('8. Archive button present', (tester) async {
      final plan = _fakePlan();
      final progress = _fakeProgress(plan);

      await tester.pumpWidget(_buildDetailScreen(budgetId: 'b1', progressResult: AppOk(progress)));
      await tester.pumpAndSettle();

      expect(find.text('Archive budget'), findsOneWidget);
    });

    testWidgets('9. Monthly budget shows previous periods section', (tester) async {
      final plan = _fakePlan(monthly: true);
      final progress = _fakeProgress(plan);
      final historyEntry = BudgetProgress(
        budget: plan,
        periodStart: '2023-12-01',
        periodEnd: '2024-01-01',
        consumedMinorUnits: 20000,
        limitMinorUnits: 100000,
        currencyCode: 'EGP',
        matchingTransactionCount: 1,
        usageState: BudgetUsageState.onTrack,
        drillDown: const [],
      );

      await tester.pumpWidget(_buildDetailScreen(budgetId: 'b1', progressResult: AppOk(progress), historyResult: AppOk([progress, historyEntry])));
      await tester.pumpAndSettle();

      expect(find.text('Previous periods'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('2023-12-01'), 500, scrollable: find.byType(Scrollable).first);
      expect(find.text('2023-12-01'), findsOneWidget);
    });

    testWidgets('10. Arabic RTL layout', (tester) async {
      final plan = _fakePlan(name: 'ميزانية الطعام');
      final progress = _fakeProgress(plan);

      await tester.pumpWidget(_buildDetailScreen(budgetId: 'b1', progressResult: AppOk(progress), locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Name appears in AppBar and in body summary card
      expect(find.text('ميزانية الطعام'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
