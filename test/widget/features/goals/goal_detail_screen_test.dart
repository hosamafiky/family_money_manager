/// Widget tests for GoalDetailScreen (Phase 5B).
///
/// Tests:
///  1. Goal name shown
///  2. Reserve balance shown (formatted, not raw minor units)
///  3. Progress bar present
///  4. Status badge uses text + icon
///  5. Child-fund separation note shown
///  6. Fund button present
///  7. Movements list shown when non-empty
///  8. Arabic RTL layout correct
library;

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/goals/presentation/goal_detail_screen.dart';
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

GoalRevision _fakeRevision({String name = 'Emergency Fund', int target = 100000}) => GoalRevision(
  id: 'rev-1',
  goalId: 'g-1',
  householdId: 'household-v1',
  name: name,
  purpose: GoalPurpose.emergencyFund,
  targetMinorUnits: target,
  currencyCode: 'EGP',
  createdAt: '2024-01-01T00:00:00Z',
  revisionReason: 'initial',
);

SavingsGoal _fakeGoal({
  String name = 'Emergency Fund',
  int target = 100000,
  GoalStatus status = GoalStatus.active,
}) {
  final rev = _fakeRevision(name: name, target: target);
  return SavingsGoal(
    id: 'g-1',
    householdId: 'household-v1',
    reserveAccountId: 'reserve-1',
    currencyCode: 'EGP',
    status: status,
    currentRevision: rev,
    createdAt: '2024-01-01T00:00:00Z',
    idempotencyKey: 'ik-1',
  );
}

GoalProgress _fakeProgress({
  int balance = 25000,
  List<GoalMovement> movements = const [],
  List<GoalRevision> revisions = const [],
}) {
  final goal = _fakeGoal();
  return GoalProgress(
    goal: goal,
    reserveBalanceMinorUnits: balance,
    currencyCode: 'EGP',
    progressState: balance == 0 ? GoalProgressState.notStarted : GoalProgressState.inProgress,
    movements: movements,
    revisions: revisions.isEmpty ? [goal.currentRevision] : revisions,
  );
}

GoRouter _makeRouter({String goalId = 'g-1'}) => GoRouter(
  initialLocation: '/goals/$goalId',
  routes: [
    GoRoute(
      path: '/goals',
      builder: (_, _) => const Scaffold(body: Text('Goals List')),
      routes: [
        GoRoute(
          path: ':goalId',
          builder: (context, state) => GoalDetailScreen(goalId: state.pathParameters['goalId']!),
          routes: [
            GoRoute(
              path: 'fund',
              builder: (_, _) => const Scaffold(body: Text('Fund Goal')),
            ),
            GoRoute(
              path: 'release',
              builder: (_, _) => const Scaffold(body: Text('Release Goal')),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/transactions/:operationId',
      builder: (context, state) =>
          Scaffold(body: Text('Tx:${state.pathParameters['operationId']}')),
    ),
  ],
);

Widget _buildApp({required GoalProgress progress, Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
      goalProgressProvider.overrideWith((ref, goalId) async => AppOk(progress)),
      goalDetailProvider.overrideWith((ref, goalId) async => AppOk(progress.goal)),
      completeGoalUseCaseProvider.overrideWith((ref) => throw UnimplementedError()),
      archiveGoalUseCaseProvider.overrideWith((ref) => throw UnimplementedError()),
      restoreGoalUseCaseProvider.overrideWith((ref) => throw UnimplementedError()),
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _makeRouter(),
    ),
  );
}

void main() {
  group('GoalDetailScreen', () {
    testWidgets('1. Goal name shown', (tester) async {
      await tester.pumpWidget(_buildApp(progress: _fakeProgress()));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Fund'), findsAtLeastNWidgets(1));
    });

    testWidgets('2. Reserve balance shown formatted (not raw minor units)', (tester) async {
      // Balance is 25000 minor units = 250.00 EGP
      await tester.pumpWidget(_buildApp(progress: _fakeProgress(balance: 25000)));
      await tester.pumpAndSettle();

      // Should show formatted amount like "250.00" not raw "25000"
      expect(find.textContaining('250.00'), findsWidgets);
      expect(find.text('25000'), findsNothing);
    });

    testWidgets('3. Progress bar present', (tester) async {
      await tester.pumpWidget(_buildApp(progress: _fakeProgress(balance: 50000)));
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('4. Status badge uses text + icon (not color alone)', (tester) async {
      await tester.pumpWidget(_buildApp(progress: _fakeProgress()));
      await tester.pumpAndSettle();
      // Status badge text must be present.
      expect(find.text('Active'), findsOneWidget);
      // And an icon must also exist.
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('5. Child-fund separation note shown', (tester) async {
      await tester.pumpWidget(_buildApp(progress: _fakeProgress()));
      await tester.pumpAndSettle();
      expect(find.text('Goal funds are NOT child-protected money'), findsOneWidget);
    });

    testWidgets('6. Fund button present for active goal', (tester) async {
      await tester.pumpWidget(_buildApp(progress: _fakeProgress()));
      await tester.pumpAndSettle();
      expect(find.text('Add funds'), findsOneWidget);
    });

    testWidgets('7. Movements list shown when non-empty', (tester) async {
      const movement = GoalMovement(
        id: 'mov-1',
        goalId: 'g-1',
        householdId: 'household-v1',
        transferOperationId: 'op-1',
        movementType: GoalMovementType.funding,
        createdAt: '2024-01-01T00:00:00Z',
      );
      await tester.pumpWidget(_buildApp(progress: _fakeProgress(movements: [movement])));
      await tester.pumpAndSettle();
      expect(find.text('Funding'), findsAtLeastNWidgets(1));
    });

    testWidgets('8. Arabic RTL layout correct', (tester) async {
      await tester.pumpWidget(_buildApp(progress: _fakeProgress(), locale: const Locale('ar')));
      await tester.pumpAndSettle();
      expect(find.text('أموال الأهداف ليست أموالاً محمية للأطفال'), findsOneWidget);
    });
  });
}
