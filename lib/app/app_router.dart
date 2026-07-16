import 'package:family_money_manager/core/navigation/routes.dart';
import 'package:family_money_manager/features/accounts/presentation/account_creation_screen.dart';
import 'package:family_money_manager/features/accounts/presentation/account_detail_screen.dart';
import 'package:family_money_manager/features/accounts/presentation/accounts_screen.dart';
import 'package:family_money_manager/features/household/presentation/household_members_screen.dart';
import 'package:family_money_manager/features/settings/settings_screen.dart';
import 'package:family_money_manager/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Creates and owns the single [GoRouter] instance for the application.
///
/// Phase 3A routes:
///   /accounts              — AccountsScreen (tab 0)
///   /accounts/new          — AccountCreationScreen (push)
///   /accounts/:accountId   — AccountDetailScreen (push)
///   /members               — HouseholdMembersScreen (tab 1)
///   /settings              — SettingsScreen (tab 2)
///
/// The old smoke/foundation routes remain accessible via typed route objects
/// for backwards compatibility with existing widget tests.
abstract final class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/accounts',
      debugLogDiagnostics: false,
      errorBuilder: (context, state) => AppErrorScreen(error: state.error),
      routes: [
        // ── Phase 3A shell with bottom navigation ─────────────────────────
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            // Tab 0: Accounts
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/accounts',
                  builder: (context, state) => const AccountsScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) =>
                          const AccountCreationScreen(),
                    ),
                    GoRoute(
                      path: ':accountId',
                      builder: (context, state) => AccountDetailScreen(
                        accountId: state.pathParameters['accountId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Tab 1: Family members
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/members',
                  builder: (context, state) => const HouseholdMembersScreen(),
                ),
              ],
            ),
            // Tab 2: Settings
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Phase 1 legacy routes (kept for smoke/foundation widget tests) ─
        ...$appRoutes,
      ],
    );
  }
}

/// Minimal error screen shown when no route matches.
///
/// Exposed as a public class so it can be widget-tested directly without
/// requiring a live router instance.
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({this.error, super.key});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(error?.toString() ?? 'Page not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => const SmokeRouteData().go(context),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}
