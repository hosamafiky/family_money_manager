/// Detail screens sit above the shell, not inside a tab.
///
/// The behaviour this buys, and the reason it was worth a router change:
/// opening an account from Home no longer switches the visible tab to More
/// and discards Home's scroll position. A destination should not decide which
/// tab you are on. The observable consequence is that a detail screen has no
/// bottom navigation, and popping returns you to where you actually were.
library;

import 'dart:async';

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/app/app_router.dart';
import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/household/data/drift_household_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Every route that must be pushed above the shell.
///
/// Detail screens and the actions reached from them. The list is the point:
/// a route added here without `parentNavigatorKey` slides the bottom bar back
/// in, and go_router does not inherit the key from a parent route.
const _rootPushedRoutes = <String>[
  '/transactions/op-1',
  '/transactions/op-1/reverse',
  '/accounts/acc-1',
  '/budgets/b-1',
  '/goals/g-1',
  '/goals/g-1/fund',
  '/goals/g-1/release',
  '/certificates/c-1',
  '/certificates/c-1/profit',
  '/certificates/c-1/redeem',
];

/// Shell destinations, which must keep their bottom navigation.
const _shellRoutes = <String>[
  '/dashboard',
  '/transactions',
  '/planning',
  '/budgets',
  '/goals',
  '/certificates',
  '/reports',
  '/more',
  '/accounts',
];

Future<GoRouter> _pumpApp(WidgetTester tester) async {
  late AppDatabase db;
  late GoRouter router;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.development),
        appDatabaseProvider.overrideWith((ref) {
          db = AppDatabase.forTesting();
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          router = AppRouter.create(ref);
          return MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  // The router redirects to onboarding until a household exists.
  await DriftHouseholdRepository(db).createHousehold(
    id: 'household-v1',
    displayName: 'Test Household',
    currencyCode: 'EGP',
    ownerUserId: 'owner-1',
  );
  return router;
}

void main() {
  testWidgets('a detail route shows no bottom navigation', (tester) async {
    final router = await _pumpApp(tester);

    for (final route in _rootPushedRoutes) {
      router.go('/dashboard');
      await tester.pumpAndSettle();

      // `push` returns a future that completes when the route is *popped*,
      // so awaiting it here would hang forever. The navigation is synchronous;
      // pumpAndSettle is what makes the pushed page observable.
      unawaited(router.push(route));
      await tester.pumpAndSettle();

      expect(
        find.byType(NavigationBar),
        findsNothing,
        reason: '$route is a detail route and must sit above the shell',
      );
    }
  });

  testWidgets('shell destinations keep their bottom navigation', (
    tester,
  ) async {
    final router = await _pumpApp(tester);

    for (final route in _shellRoutes) {
      router.go(route);
      await tester.pumpAndSettle();

      expect(
        find.byType(NavigationBar),
        findsOneWidget,
        reason: '$route is a tab destination and must keep the shell',
      );
    }
  });

  testWidgets(
    'popping a detail returns to the tab it was opened from, not to More',
    (tester) async {
      final router = await _pumpApp(tester);

      // Home, then an account — which lives on the More branch. Before the
      // router change this switched the visible tab.
      router.go('/dashboard');
      await tester.pumpAndSettle();

      unawaited(router.push('/accounts/acc-1'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);

      router.pop();
      await tester.pumpAndSettle();

      // Back on Home with its shell intact — not stranded on the More tab.
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/dashboard');
    },
  );
}
