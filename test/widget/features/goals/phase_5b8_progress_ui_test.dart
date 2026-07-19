/// Phase 5B.8 – UI progress / lifecycle presentation (UI-PROG-1..6).
library;

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/goals/presentation/goal_detail_screen.dart';
import 'package:family_money_manager/features/goals/presentation/goals_list_screen.dart';
import 'package:family_money_manager/features/goals/presentation/providers/goal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
  GoalStatus status = GoalStatus.active,
  int target = 100000,
}) {
  final rev = GoalRevision(
    id: 'rev-$id',
    goalId: id,
    householdId: 'household-v1',
    name: name,
    purpose: GoalPurpose.emergencyFund,
    targetMinorUnits: target,
    currencyCode: 'EGP',
    createdAt: '2024-01-01T00:00:00Z',
    revisionReason: 'initial',
  );
  return SavingsGoal(
    id: id,
    householdId: 'household-v1',
    reserveAccountId: 'reserve-$id',
    currencyCode: 'EGP',
    status: status,
    currentRevision: rev,
    createdAt: '2024-01-01T00:00:00Z',
    idempotencyKey: 'ik-$id',
  );
}

GoalProgress _fakeProgress(
  SavingsGoal goal, {
  required int balance,
  GoalProgressState? state,
}) {
  final progressState =
      state ?? GoalProgressState.fromBalance(balance, goal.targetMinorUnits);
  return GoalProgress(
    goal: goal,
    reserveBalanceMinorUnits: balance,
    currencyCode: goal.currencyCode,
    progressState: progressState,
    movements: const [],
    revisions: [goal.currentRevision],
  );
}

GoRouter _listRouter() => GoRouter(
  initialLocation: '/goals',
  routes: [
    GoRoute(
      path: '/goals',
      builder: (_, _) => const GoalsListScreen(),
      routes: [
        GoRoute(
          path: ':goalId',
          builder: (_, state) =>
              Scaffold(body: Text('Detail:${state.pathParameters['goalId']}')),
        ),
      ],
    ),
  ],
);

GoRouter _detailRouter({String goalId = 'g-1'}) => GoRouter(
  initialLocation: '/goals/$goalId',
  routes: [
    GoRoute(
      path: '/goals',
      builder: (_, _) => const Scaffold(body: Text('List')),
      routes: [
        GoRoute(
          path: ':goalId',
          builder: (_, state) =>
              GoalDetailScreen(goalId: state.pathParameters['goalId']!),
        ),
      ],
    ),
  ],
);

Widget _wrap({
  required Locale locale,
  required GoRouter router,
  required SavingsGoal goal,
  required GoalProgress progress,
}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(AppConfig.development),
    appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
    appThemeModeProvider.overrideWith(
      () => _FixedThemeModeNotifier(ThemeMode.light),
    ),
    goalsProvider.overrideWith((ref, _) async => AppOk([goal])),
    goalProgressProvider.overrideWith((ref, _) async => AppOk(progress)),
    goalDetailProvider.overrideWith((ref, _) async => AppOk(goal)),
  ],
  child: MaterialApp.router(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ),
);

void main() {
  testWidgets(
    'UI-PROG-1. EN list shows lifecycle Active + progress Not started',
    (tester) async {
      final goal = _fakeGoal();
      final progress = _fakeProgress(goal, balance: 0);
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          router: _listRouter(),
          goal: goal,
          progress: progress,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Not started'), findsOneWidget);
      expect(find.text('Target reached'), findsNothing);
    },
  );

  testWidgets(
    'UI-PROG-2. EN detail shows Target reached as progress not lifecycle',
    (tester) async {
      final goal = _fakeGoal();
      final progress = _fakeProgress(goal, balance: 100000);
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          router: _detailRouter(),
          goal: goal,
          progress: progress,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Target reached'), findsWidgets);
      expect(find.text('Completed'), findsNothing);
      expect(find.text('Archived'), findsNothing);
    },
  );

  testWidgets('UI-PROG-3. EN list shows Overfunded progress badge', (
    tester,
  ) async {
    final goal = _fakeGoal();
    final progress = _fakeProgress(goal, balance: 150000);
    await tester.pumpWidget(
      _wrap(
        locale: const Locale('en'),
        router: _listRouter(),
        goal: goal,
        progress: progress,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Overfunded'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('UI-PROG-4. AR list shows نشط lifecycle + لم يبدأ progress', (
    tester,
  ) async {
    final goal = _fakeGoal();
    final progress = _fakeProgress(goal, balance: 0);
    await tester.pumpWidget(
      _wrap(
        locale: const Locale('ar'),
        router: _listRouter(),
        goal: goal,
        progress: progress,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('نشط'), findsOneWidget);
    expect(find.text('لم يبدأ'), findsOneWidget);
  });

  testWidgets(
    'UI-PROG-5. AR detail shows تم بلوغ الهدف as progress with نشط lifecycle',
    (tester) async {
      final goal = _fakeGoal();
      final progress = _fakeProgress(goal, balance: 100000);
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ar'),
          router: _detailRouter(),
          goal: goal,
          progress: progress,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('نشط'), findsOneWidget);
      expect(find.text('تم بلوغ الهدف'), findsWidgets);
    },
  );

  testWidgets(
    'UI-PROG-6. Completed lifecycle can still show derived Overfunded',
    (tester) async {
      final goal = _fakeGoal(status: GoalStatus.completed);
      final progress = _fakeProgress(goal, balance: 150000);
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          router: _detailRouter(),
          goal: goal,
          progress: progress,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Overfunded'), findsWidgets);
      expect(find.text('Active'), findsNothing);
    },
  );
}
