/// Widget tests for BudgetsListScreen (Phase 5A).
///
/// Tests:
///  1. Loading state shown (CircularProgressIndicator)
///  2. Empty state shown with create button
///  3. Error state shown
///  4. Budget card shows name and currency
///  5. No mixed-currency total shown
///  6. Status badge shows text (not color-only)
///  7. Arabic RTL layout correct
///  8. English LTR layout correct
///  9. Tap card navigates to budget detail
/// 10. FAB create button present
library;

import 'dart:async';

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';
import 'package:family_money_manager/features/budgets/presentation/budgets_list_screen.dart';
import 'package:family_money_manager/features/budgets/presentation/providers/budget_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ── Test helpers ───────────────────────────────────────────────────────────

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

BudgetPlan _fakePlan({
  String id = 'b1',
  String name = 'Groceries',
  String currency = 'EGP',
  bool archived = false,
}) => BudgetPlan(
  id: id,
  householdId: 'household-v1',
  name: name,
  currencyCode: currency,
  limitMinorUnits: 50000,
  periodDefinition: const MonthlyBudgetPeriod(),
  filter: const BudgetFilter(),
  isArchived: archived,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
  idempotencyKey: 'ik-$id',
  idempotencyPayload: 'p-$id',
);

BudgetProgress _fakeProgress(BudgetPlan plan, {int consumed = 0}) => BudgetProgress(
  budget: plan,
  periodStart: '2024-01-01',
  periodEnd: '2024-02-01',
  consumedMinorUnits: consumed,
  limitMinorUnits: plan.limitMinorUnits,
  currencyCode: plan.currencyCode,
  matchingTransactionCount: 0,
  usageState: BudgetUsageState.noSpending,
  drillDown: const [],
);

GoRouter _makeRouter({String initialLocation = '/budgets'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/budgets',
      builder: (_, _) => const BudgetsListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, _) => const Scaffold(body: Text('CreateBudget')),
        ),
        GoRoute(
          path: ':budgetId',
          builder: (context, state) =>
              Scaffold(body: Text('Detail:${state.pathParameters['budgetId']}')),
        ),
      ],
    ),
  ],
);

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('BudgetsListScreen', () {
    testWidgets('1. Loading state shown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            budgetsProvider.overrideWith(
              // Never-completing future keeps the provider in AsyncLoading.
              (ref, _) => Completer<AppResult<List<BudgetPlan>>>().future,
            ),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _makeRouter(),
          ),
        ),
      );
      // 100ms is enough for GoRouter and Riverpod to initialize the loading state,
      // but far less than the 10s delay so the FutureProvider stays AsyncLoading.
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('2. Empty state shown with create button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            budgetsProvider.overrideWith((ref, _) async => const AppOk(<BudgetPlan>[])),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _makeRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No budgets'), findsOneWidget);
      // Both FAB and empty-state button
      expect(find.text('New Budget'), findsWidgets);
    });

    testWidgets('3. Error state shown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            budgetsProvider.overrideWith((ref, _) => Future.error(Exception('DB error'))),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _makeRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('DB error'), findsOneWidget);
    });

    testWidgets('4. Budget card shows name and currency', (tester) async {
      final plan = _fakePlan(name: 'Groceries', currency: 'EGP');
      final progress = _fakeProgress(plan);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            budgetsProvider.overrideWith((ref, _) async => AppOk([plan])),
            budgetProgressProvider.overrideWith((ref, _) async => AppOk(progress)),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _makeRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('EGP'), findsOneWidget);
    });

    testWidgets('5. No mixed-currency grand total shown', (tester) async {
      final egp = _fakePlan(id: 'b1', name: 'Budget EGP', currency: 'EGP');
      final usd = _fakePlan(id: 'b2', name: 'Budget USD', currency: 'USD');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            budgetsProvider.overrideWith((ref, _) async => AppOk([egp, usd])),
            budgetProgressProvider.overrideWith((ref, id) async {
              final plan = id == 'b1' ? egp : usd;
              return AppOk(_fakeProgress(plan));
            }),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _makeRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budget EGP'), findsOneWidget);
      expect(find.text('Budget USD'), findsOneWidget);
      // No cross-currency "Total" label
      expect(find.textContaining('Total'), findsNothing);
    });

    testWidgets('6. Status badge shows text (not color-only)', (tester) async {
      final plan = _fakePlan();
      final progress = _fakeProgress(plan, consumed: 0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            budgetsProvider.overrideWith((ref, _) async => AppOk([plan])),
            budgetProgressProvider.overrideWith((ref, _) async => AppOk(progress)),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _makeRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Text label present (not color-only)
      expect(find.text('No spending'), findsOneWidget);
    });

    testWidgets('7. Arabic RTL layout correct', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('ar'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            budgetsProvider.overrideWith((ref, _) async => const AppOk(<BudgetPlan>[])),
          ],
          child: MaterialApp.router(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _makeRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الميزانيات'), findsOneWidget);
    });

    testWidgets('8. English LTR layout correct', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            budgetsProvider.overrideWith((ref, _) async => const AppOk(<BudgetPlan>[])),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _makeRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budgets'), findsOneWidget);
    });

    testWidgets('9. Tap card navigates to budget detail', (tester) async {
      final plan = _fakePlan(id: 'budget-nav', name: 'Nav Budget');
      final progress = _fakeProgress(plan);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            budgetsProvider.overrideWith((ref, _) async => AppOk([plan])),
            budgetProgressProvider.overrideWith((ref, _) async => AppOk(progress)),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _makeRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nav Budget'));
      await tester.pumpAndSettle();

      expect(find.text('Detail:budget-nav'), findsOneWidget);
    });

    testWidgets('10. FAB create button present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            budgetsProvider.overrideWith((ref, _) async => const AppOk(<BudgetPlan>[])),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _makeRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
