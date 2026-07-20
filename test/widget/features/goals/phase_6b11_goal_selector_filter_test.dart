/// Phase 6B.1.1 – Widget selector filters for goal fund/release.
///
/// Classification: **presentation convenience only** — not authoritative DB
/// enforcement. See `phase_6b11_certificate_goal_eligibility_test.dart` for
/// trigger-level guarantees.
library;

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/goals/presentation/fund_goal_screen.dart';
import 'package:family_money_manager/features/goals/presentation/providers/goal_providers.dart';
import 'package:family_money_manager/features/goals/presentation/release_goal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

FinancialAccount _acct({
  required String id,
  required String name,
  required FinancialAccountType type,
  FundPurpose purpose = FundPurpose.available,
  bool spendable = true,
  bool protected = false,
  String currency = 'EGP',
}) {
  return FinancialAccount(
    id: id,
    householdId: 'household-v1',
    name: name,
    type: type,
    ownerType: AccountOwnerType.user,
    fundPurpose: purpose,
    currencyCode: currency,
    isSpendable: spendable,
    isProtected: protected,
    includeInNetWorth: true,
    includeInZakat: false,
    isArchived: false,
    displayOrder: 0,
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
    createdBy: 'u1',
  );
}

SavingsGoal _goal() {
  const rev = GoalRevision(
    id: 'rev1',
    goalId: 'goal1',
    householdId: 'household-v1',
    name: 'Vacation',
    purpose: GoalPurpose.travel,
    targetMinorUnits: 100000,
    currencyCode: 'EGP',
    createdAt: '2026-01-01T00:00:00.000Z',
    revisionReason: 'initial',
  );
  return const SavingsGoal(
    id: 'goal1',
    householdId: 'household-v1',
    reserveAccountId: 'reserve1',
    currencyCode: 'EGP',
    status: GoalStatus.active,
    currentRevision: rev,
    createdAt: '2026-01-01T00:00:00.000Z',
    idempotencyKey: 'ik',
  );
}

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

final _accounts = [
  _acct(id: 'bank1', name: 'Main Bank', type: FinancialAccountType.bankAccount),
  _acct(
    id: 'cert1',
    name: 'Certificate Ledger',
    type: FinancialAccountType.certificate,
    purpose: FundPurpose.certificate,
    spendable: false,
  ),
  _acct(
    id: 'reserve1',
    name: 'Goal Reserve',
    type: FinancialAccountType.goalReserve,
    purpose: FundPurpose.goalReserve,
    spendable: false,
  ),
  _acct(
    id: 'locked1',
    name: 'Locked Savings',
    type: FinancialAccountType.homeSavingsCash,
    spendable: false,
  ),
];

Widget _buildFund({Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      appThemeModeProvider.overrideWith(
        () => _FixedThemeModeNotifier(ThemeMode.light),
      ),
      accountsProvider.overrideWith((ref, _) async => AppOk(_accounts)),
      goalDetailProvider.overrideWith(
        (ref, _) async => AppOk<SavingsGoal?>(_goal()),
      ),
      fundGoalUseCaseProvider.overrideWith(
        (ref) => throw UnimplementedError('not needed'),
      ),
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: '/goals/goal1/fund',
        routes: [
          GoRoute(
            path: '/goals/:id/fund',
            builder: (_, state) =>
                FundGoalScreen(goalId: state.pathParameters['id']!),
          ),
        ],
      ),
    ),
  );
}

Widget _buildRelease({Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      appThemeModeProvider.overrideWith(
        () => _FixedThemeModeNotifier(ThemeMode.light),
      ),
      accountsProvider.overrideWith((ref, _) async => AppOk(_accounts)),
      goalDetailProvider.overrideWith(
        (ref, _) async => AppOk<SavingsGoal?>(_goal()),
      ),
      releaseGoalFundsUseCaseProvider.overrideWith(
        (ref) => throw UnimplementedError('not needed'),
      ),
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: '/goals/goal1/release',
        routes: [
          GoRoute(
            path: '/goals/:id/release',
            builder: (_, state) =>
                ReleaseGoalScreen(goalId: state.pathParameters['id']!),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('FundGoalScreen selector (presentation filter)', () {
    testWidgets('SEL-F1. Excludes certificate accounts; keeps eligible bank', (
      tester,
    ) async {
      await tester.pumpWidget(_buildFund());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Main Bank').hitTestable(), findsWidgets);
      expect(find.text('Certificate Ledger'), findsNothing);
      expect(find.text('Goal Reserve'), findsNothing);
      expect(find.text('Locked Savings'), findsNothing);
    });

    testWidgets('SEL-F2. AR locale still excludes certificate accounts', (
      tester,
    ) async {
      await tester.pumpWidget(_buildFund(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Certificate Ledger'), findsNothing);
      expect(find.text('Main Bank').hitTestable(), findsWidgets);
    });
  });

  group('ReleaseGoalScreen selector (presentation filter)', () {
    testWidgets('SEL-R1. Excludes certificate accounts; keeps eligible bank', (
      tester,
    ) async {
      await tester.pumpWidget(_buildRelease());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Main Bank').hitTestable(), findsWidgets);
      expect(find.text('Certificate Ledger'), findsNothing);
      expect(find.text('Goal Reserve'), findsNothing);
      expect(find.text('Locked Savings'), findsNothing);
    });

    testWidgets('SEL-R2. AR locale still excludes certificate accounts', (
      tester,
    ) async {
      await tester.pumpWidget(_buildRelease(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Certificate Ledger'), findsNothing);
      expect(find.text('Main Bank').hitTestable(), findsWidgets);
    });
  });
}
