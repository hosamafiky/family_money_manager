import 'package:family_money_manager/core/navigation/routes.dart';
import 'package:family_money_manager/features/accounts/presentation/account_creation_screen.dart';
import 'package:family_money_manager/features/accounts/presentation/account_detail_screen.dart';
import 'package:family_money_manager/features/accounts/presentation/accounts_screen.dart';
import 'package:family_money_manager/features/household/presentation/household_members_screen.dart';
import 'package:family_money_manager/features/settings/settings_screen.dart';
import 'package:family_money_manager/features/shell/app_shell.dart';
import 'package:family_money_manager/features/transactions/presentation/create_transaction_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/expense_form_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/expense_review_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/income_form_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/income_review_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/transactions_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/transfer_form_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/transfer_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Creates and owns the single [GoRouter] instance for the application.
///
/// Phase 3B routes:
///   /accounts              — AccountsScreen (tab 0)
///   /accounts/new          — AccountCreationScreen (push)
///   /accounts/:accountId   — AccountDetailScreen (push)
///   /transactions          — TransactionsScreen (tab 1)
///   /transactions/new      — CreateTransactionScreen (push)
///   /transactions/new/income          — IncomeFormScreen
///   /transactions/new/income/review   — IncomeReviewScreen
///   /transactions/new/expense         — ExpenseFormScreen
///   /transactions/new/expense/review  — ExpenseReviewScreen
///   /transactions/new/transfer        — TransferFormScreen
///   /transactions/new/transfer/review — TransferReviewScreen
///   /transactions/:operationId        — TransactionDetailScreen
///   /members               — HouseholdMembersScreen (tab 2)
///   /settings              — SettingsScreen (tab 3)
abstract final class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/accounts',
      debugLogDiagnostics: false,
      errorBuilder: (context, state) => AppErrorScreen(error: state.error),
      routes: [
        // ── Phase 3B shell with bottom navigation ─────────────────────────
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
            // Tab 1: Transactions
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/transactions',
                  builder: (context, state) => const TransactionsScreen(),
                  routes: [
                    GoRoute(
                      path: ':operationId',
                      builder: (context, state) => TransactionDetailScreen(
                        operationId: state.pathParameters['operationId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => CreateTransactionScreen(
                        preselectedAccountId: state.extra as String?,
                      ),
                      routes: [
                        GoRoute(
                          path: 'income',
                          builder: (context, state) => IncomeFormScreen(
                            preselectedAccountId: state.extra as String?,
                          ),
                          routes: [
                            GoRoute(
                              path: 'review',
                              builder: (context, state) =>
                                  const IncomeReviewScreen(),
                            ),
                          ],
                        ),
                        GoRoute(
                          path: 'expense',
                          builder: (context, state) => ExpenseFormScreen(
                            preselectedAccountId: state.extra as String?,
                          ),
                          routes: [
                            GoRoute(
                              path: 'review',
                              builder: (context, state) =>
                                  const ExpenseReviewScreen(),
                            ),
                          ],
                        ),
                        GoRoute(
                          path: 'transfer',
                          builder: (context, state) => TransferFormScreen(
                            preselectedAccountId: state.extra as String?,
                          ),
                          routes: [
                            GoRoute(
                              path: 'review',
                              builder: (context, state) =>
                                  const TransferReviewScreen(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Tab 2: Family members
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/members',
                  builder: (context, state) => const HouseholdMembersScreen(),
                ),
              ],
            ),
            // Tab 3: Settings
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
