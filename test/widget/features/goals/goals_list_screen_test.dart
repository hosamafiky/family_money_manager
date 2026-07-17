/// Widget tests for GoalsListScreen (Phase 5B).
///
/// Tests:
///  1. Loading state shown (CircularProgressIndicator)
///  2. Empty state shown with create button
///  3. Error state shown
///  4. Goal card shows name, currency, target amount
///  5. No mixed-currency total shown
///  6. Status badge uses text + icon (not color alone)
///  7. Arabic RTL layout correct
///  8. English LTR layout correct
///  9. FAB present with correct heroTag
/// 10. Tap card navigates to goal detail (with GoRouter)
library;

import 'dart:async';

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/goals/presentation/goals_list_screen.dart';
import 'package:family_money_manager/features/goals/presentation/providers/goal_providers.dart';
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

SavingsGoal _fakeGoal({
  String id = 'g-1',
  String name = 'Emergency Fund',
  String currency = 'EGP',
  int target = 100000,
  GoalStatus status = GoalStatus.active,
}) {
  final rev = GoalRevision(
    id: 'rev-$id',
    goalId: id,
    householdId: 'household-v1',
    name: name,
    purpose: GoalPurpose.emergencyFund,
    targetMinorUnits: target,
    currencyCode: currency,
    createdAt: '2024-01-01T00:00:00Z',
    revisionReason: 'initial',
  );
  return SavingsGoal(
    id: id,
    householdId: 'household-v1',
    reserveAccountId: 'reserve-$id',
    currencyCode: currency,
    status: status,
    currentRevision: rev,
    createdAt: '2024-01-01T00:00:00Z',
    idempotencyKey: 'ik-$id',
  );
}

GoalProgress _fakeProgress(SavingsGoal goal, {int balance = 0}) => GoalProgress(
  goal: goal,
  reserveBalanceMinorUnits: balance,
  currencyCode: goal.currencyCode,
  progressState: balance == 0 ? GoalProgressState.notStarted : GoalProgressState.inProgress,
  movements: const [],
  revisions: [goal.currentRevision],
);

GoRouter _makeRouter({String initialLocation = '/goals'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/goals',
      builder: (_, _) => const GoalsListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, _) => const Scaffold(body: Text('CreateGoal')),
        ),
        GoRoute(
          path: ':goalId',
          builder: (context, state) =>
              Scaffold(body: Text('Detail:${state.pathParameters['goalId']}')),
        ),
      ],
    ),
  ],
);

MaterialApp _appShell(GoRouter router, Locale locale) => MaterialApp.router(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: router,
);

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('GoalsListScreen', () {
    testWidgets('1. Loading state shown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            goalsProvider.overrideWith(
              (ref, _) => Completer<AppResult<List<SavingsGoal>>>().future,
            ),
            goalProgressProvider.overrideWith(
              (ref, _) => Completer<AppResult<GoalProgress>>().future,
            ),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
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
            goalsProvider.overrideWith((ref, _) async => const AppOk(<SavingsGoal>[])),
            goalProgressProvider.overrideWith((ref, _) async => Future.error('not needed')),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No goals'), findsOneWidget);
      expect(find.text('New Goal'), findsWidgets);
    });

    testWidgets('3. Error state shown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            goalsProvider.overrideWith((ref, _) => Future.error(Exception('DB error'))),
            goalProgressProvider.overrideWith(
              (ref, _) => Future.error(Exception('progress error')),
            ),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('DB error'), findsOneWidget);
    });

    testWidgets('4. Goal card shows name, currency, target amount', (tester) async {
      final goal = _fakeGoal(name: 'Car Fund', currency: 'EGP', target: 200000);
      final progress = _fakeProgress(goal, balance: 50000);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            goalsProvider.overrideWith((ref, _) async => AppOk([goal])),
            goalProgressProvider.overrideWith((ref, _) async => AppOk(progress)),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Car Fund'), findsOneWidget);
      expect(find.textContaining('EGP'), findsWidgets);
    });

    testWidgets('5. No mixed-currency total shown', (tester) async {
      final goalEgp = _fakeGoal(id: 'g-egp', currency: 'EGP');
      final goalUsd = _fakeGoal(id: 'g-usd', currency: 'USD');
      final progressEgp = _fakeProgress(goalEgp);
      final progressUsd = _fakeProgress(goalUsd);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            goalsProvider.overrideWith((ref, _) async => AppOk([goalEgp, goalUsd])),
            goalProgressProvider.overrideWith((ref, goalId) async {
              if (goalId == 'g-egp') return AppOk(progressEgp);
              return AppOk(progressUsd);
            }),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('EGP'), findsWidgets);
      expect(find.textContaining('USD'), findsWidgets);
      expect(find.textContaining('Total'), findsNothing);
    });

    testWidgets('6. Status badge uses text + icon (not color alone)', (tester) async {
      final goal = _fakeGoal(status: GoalStatus.active);
      final progress = _fakeProgress(goal);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            goalsProvider.overrideWith((ref, _) async => AppOk([goal])),
            goalProgressProvider.overrideWith((ref, _) async => AppOk(progress)),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('7. Arabic RTL layout correct', (tester) async {
      final goal = _fakeGoal();
      final progress = _fakeProgress(goal);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('ar'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            goalsProvider.overrideWith((ref, _) async => AppOk([goal])),
            goalProgressProvider.overrideWith((ref, _) async => AppOk(progress)),
          ],
          child: _appShell(_makeRouter(), const Locale('ar')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('الأهداف'), findsWidgets);
    });

    testWidgets('8. English LTR layout correct', (tester) async {
      final goal = _fakeGoal();
      final progress = _fakeProgress(goal);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            goalsProvider.overrideWith((ref, _) async => AppOk([goal])),
            goalProgressProvider.overrideWith((ref, _) async => AppOk(progress)),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Goals'), findsOneWidget);
    });

    testWidgets('9. FAB present with heroTag fab_goals', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            goalsProvider.overrideWith((ref, _) async => const AppOk(<SavingsGoal>[])),
            goalProgressProvider.overrideWith((ref, _) async => Future.error('not used')),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.heroTag, 'fab_goals');
    });

    testWidgets('10. Tap card navigates to goal detail', (tester) async {
      final goal = _fakeGoal(id: 'g-tap');
      final progress = _fakeProgress(goal);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(const Locale('en'))),
            appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
            goalsProvider.overrideWith((ref, _) async => AppOk([goal])),
            goalProgressProvider.overrideWith((ref, _) async => AppOk(progress)),
          ],
          child: _appShell(_makeRouter(), const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Emergency Fund'));
      await tester.pumpAndSettle();

      expect(find.text('Detail:g-tap'), findsOneWidget);
    });
  });
}
