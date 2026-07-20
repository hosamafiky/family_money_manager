import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const Text('home-body'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (_, _) => const Text('tx-body'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/planning',
                builder: (_, _) => const Text('planning-body'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (_, _) => const Text('reports-body'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, _) => const Text('more-body'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget _app(
  GoRouter router, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp.router(
      locale: locale,
      theme: AppTheme.light(),
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('shell shows five English destinations', (tester) async {
    final router = _testRouter();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.navHome), findsOneWidget);
    expect(find.text(l10n.navTransactions), findsOneWidget);
    expect(find.text(l10n.navPlanning), findsOneWidget);
    expect(find.text(l10n.navReports), findsOneWidget);
    expect(find.text(l10n.navMore), findsOneWidget);
    expect(find.text('home-body'), findsOneWidget);
  });

  testWidgets('shell shows five Arabic destinations', (tester) async {
    final router = _testRouter();
    await tester.pumpWidget(_app(router, locale: const Locale('ar')));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l10n.navHome), findsOneWidget);
    expect(find.text(l10n.navPlanning), findsOneWidget);
    expect(find.text(l10n.navMore), findsOneWidget);
  });

  testWidgets('tapping planning branch shows planning body', (tester) async {
    final router = _testRouter();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l10n.navPlanning));
    await tester.pumpAndSettle();
    expect(find.text('planning-body'), findsOneWidget);
  });

  testWidgets('wide shell uses navigation rail', (tester) async {
    final router = _testRouter();
    await tester.pumpWidget(_app(router, size: const Size(1200, 800)));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
