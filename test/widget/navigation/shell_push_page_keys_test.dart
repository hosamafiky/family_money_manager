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

/// Regression for Navigator `!keyReservation.contains(key)` when shell
/// destinations were previously registered as root siblings and stacked via
/// `push` (duplicate StatefulShellRoute page keys).
///
/// Note on `unawaited`: `GoRouter.push` returns a future that completes when
/// the pushed route is *popped*, not when it is displayed. Awaiting it here
/// would block until something pops the page, which nothing in these tests
/// ever does — so the await never returns and the test dies on the framework
/// timeout. The navigation itself is synchronous; `pumpAndSettle` is what
/// makes the pushed page observable.
void main() {
  testWidgets(
    'planning → budgets → transaction detail does not duplicate page keys',
    (tester) async {
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

      await DriftHouseholdRepository(db).createHousehold(
        id: 'household-v1',
        displayName: 'Test Household',
        currencyCode: 'EGP',
        ownerUserId: 'owner-1',
      );

      router.go('/planning');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Historical crash path used push for hub destinations.
      unawaited(router.push('/budgets'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      unawaited(router.push('/transactions/op-repro-1'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'more → accounts → transaction form does not duplicate page keys',
    (tester) async {
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

      await DriftHouseholdRepository(db).createHousehold(
        id: 'household-v1',
        displayName: 'Test Household',
        currencyCode: 'EGP',
        ownerUserId: 'owner-1',
      );

      router.go('/more');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      unawaited(router.push('/accounts'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      unawaited(router.push('/transactions/new/income'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
