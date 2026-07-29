import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/navigation/routes.dart';
import 'package:family_money_manager/features/accounts/presentation/account_creation_screen.dart';
import 'package:family_money_manager/features/accounts/presentation/account_detail_screen.dart';
import 'package:family_money_manager/features/accounts/presentation/accounts_screen.dart';
import 'package:family_money_manager/features/budgets/presentation/budget_creation_screen.dart';
import 'package:family_money_manager/features/budgets/presentation/budget_detail_screen.dart';
import 'package:family_money_manager/features/budgets/presentation/budgets_list_screen.dart';
import 'package:family_money_manager/features/certificates/presentation/certificate_creation_screen.dart';
import 'package:family_money_manager/features/certificates/presentation/certificate_detail_screen.dart';
import 'package:family_money_manager/features/certificates/presentation/certificates_list_screen.dart';
import 'package:family_money_manager/features/certificates/presentation/record_certificate_profit_screen.dart';
import 'package:family_money_manager/features/certificates/presentation/redeem_certificate_screen.dart';
import 'package:family_money_manager/features/dashboard/presentation/dashboard_screen.dart';
import 'package:family_money_manager/features/goals/presentation/fund_goal_screen.dart';
import 'package:family_money_manager/features/goals/presentation/goal_creation_screen.dart';
import 'package:family_money_manager/features/goals/presentation/goal_detail_screen.dart';
import 'package:family_money_manager/features/goals/presentation/goals_list_screen.dart';
import 'package:family_money_manager/features/goals/presentation/release_goal_screen.dart';
import 'package:family_money_manager/features/household/data/drift_household_repository.dart';
import 'package:family_money_manager/features/household/presentation/household_members_screen.dart';
import 'package:family_money_manager/features/more/presentation/more_hub_screen.dart';
import 'package:family_money_manager/features/onboarding/onboarding_screen.dart';
import 'package:family_money_manager/features/planning/presentation/planning_hub_screen.dart';
import 'package:family_money_manager/features/reports/presentation/account_flow_report_screen.dart';
import 'package:family_money_manager/features/reports/presentation/category_report_screen.dart';
import 'package:family_money_manager/features/reports/presentation/home_savings_report_screen.dart';
import 'package:family_money_manager/features/reports/presentation/income_expense_report_screen.dart';
import 'package:family_money_manager/features/reports/presentation/protected_funds_report_screen.dart';
import 'package:family_money_manager/features/reports/presentation/report_transaction_list_screen.dart';
import 'package:family_money_manager/features/reports/presentation/reports_landing_screen.dart';
import 'package:family_money_manager/features/reports/presentation/spending_attribution_report_screen.dart';
import 'package:family_money_manager/features/reports/presentation/spouse_wallet_report_screen.dart';
import 'package:family_money_manager/features/settings/settings_screen.dart';
import 'package:family_money_manager/features/shell/app_shell.dart';
import 'package:family_money_manager/features/transactions/presentation/create_transaction_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/expense_form_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/expense_review_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/income_form_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/income_review_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/reverse_transaction_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/transactions_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/transfer_form_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/transfer_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Creates and owns the single [GoRouter] instance for the application.
///
/// Phase 6B.2 shell tabs: Home · Transactions · Planning · Reports · More.
///
/// Budgets/goals/certificates live as sibling absolute routes on the Planning
/// branch; accounts/members/settings on the More branch. That keeps public
/// paths (`/budgets`, `/accounts`, …) while ensuring those destinations share
/// the same [StatefulShellRoute] page identity — avoiding duplicate Navigator
/// page keys when stacking shell destinations via `push`.
///
/// Every *detail* route, and every action reached from one, is pushed above
/// the shell instead. See [AppRouter.rootNavigatorKey] for why.
abstract final class AppRouter {
  /// Navigator that owns full-screen detail and correction routes.
  ///
  /// Detail screens are pushed above the shell rather than inside a branch.
  /// Without this, opening an account from Home switches the visible tab to
  /// More and discards Home's scroll position — the destination decides which
  /// tab you are on, which is backwards. Above the shell there is no bottom
  /// navigation on a detail screen, and popping returns to wherever you came
  /// from with its state intact.
  ///
  /// It has to be set on each route individually, including children of an
  /// already-root-pushed route: go_router resolves the navigator per route,
  /// so a child does not inherit its parent's. A goal's "fund" screen without
  /// it would slide the bottom bar back in halfway through the flow.
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter create(WidgetRef ref) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/dashboard',
      debugLogDiagnostics: false,
      errorBuilder: (context, state) => AppErrorScreen(error: state.error),
      redirect: (context, state) async {
        // On every navigation attempt, check whether the household is
        // initialized. If not, redirect to /onboarding (unless already there).
        if (state.matchedLocation == '/onboarding') return null;
        final db = ref.read(appDatabaseProvider);
        final repo = DriftHouseholdRepository(db);
        final household = await repo.findHousehold('household-v1');
        if (household == null) return '/onboarding';
        return null;
      },
      routes: [
        // ── Onboarding ────────────────────────────────────────────────────
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        // ── Phase 6B.2 shell: Home · Transactions · Planning · Reports · More ─
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            // Tab 0: Home (dashboard path preserved)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard',
                  builder: (context, state) => const DashboardScreen(),
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
                    // Declared after 'new' deliberately: go_router matches
                    // siblings in order, and ':operationId' would otherwise
                    // swallow '/transactions/new' as an operation id.
                    GoRoute(
                      path: ':operationId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => TransactionDetailScreen(
                        operationId: state.pathParameters['operationId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'reverse',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) => ReverseTransactionScreen(
                            operationId: state.pathParameters['operationId']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Tab 2: Planning hub + budgets / goals / certificates
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/planning',
                  builder: (context, state) => const PlanningHubScreen(),
                ),
                GoRoute(
                  path: '/budgets',
                  builder: (context, state) => const BudgetsListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const BudgetCreationScreen(),
                    ),
                    GoRoute(
                      path: ':budgetId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => BudgetDetailScreen(
                        budgetId: state.pathParameters['budgetId']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: '/goals',
                  builder: (context, state) => const GoalsListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const GoalCreationScreen(),
                    ),
                    GoRoute(
                      path: ':goalId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => GoalDetailScreen(
                        goalId: state.pathParameters['goalId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'fund',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) => FundGoalScreen(
                            goalId: state.pathParameters['goalId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'release',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) => ReleaseGoalScreen(
                            goalId: state.pathParameters['goalId']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GoRoute(
                  path: '/certificates',
                  builder: (context, state) => const CertificatesListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) =>
                          const CertificateCreationScreen(),
                    ),
                    GoRoute(
                      path: ':certificateId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => CertificateDetailScreen(
                        certificateId: state.pathParameters['certificateId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'profit',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) =>
                              RecordCertificateProfitScreen(
                                certificateId:
                                    state.pathParameters['certificateId']!,
                              ),
                        ),
                        GoRoute(
                          path: 'redeem',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) => RedeemCertificateScreen(
                            certificateId:
                                state.pathParameters['certificateId']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Tab 3: Reports (paths preserved under /reports)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/reports',
                  builder: (context, state) => const ReportsLandingScreen(),
                  routes: [
                    GoRoute(
                      path: 'income-expense',
                      builder: (context, state) =>
                          const IncomeExpenseReportScreen(),
                    ),
                    GoRoute(
                      path: 'attribution',
                      builder: (context, state) =>
                          const SpendingAttributionReportScreen(),
                    ),
                    GoRoute(
                      path: 'categories',
                      builder: (context, state) => const CategoryReportScreen(),
                    ),
                    GoRoute(
                      path: 'accounts',
                      builder: (context, state) =>
                          const AccountFlowReportScreen(),
                    ),
                    GoRoute(
                      path: 'home-savings',
                      builder: (context, state) =>
                          const HomeSavingsReportScreen(),
                    ),
                    GoRoute(
                      path: 'spouse-wallet',
                      builder: (context, state) =>
                          const SpouseWalletReportScreen(),
                    ),
                    GoRoute(
                      path: 'protected-funds',
                      builder: (context, state) =>
                          const ProtectedFundsReportScreen(),
                    ),
                    GoRoute(
                      path: 'transactions',
                      builder: (context, state) =>
                          const ReportTransactionListScreen(),
                    ),
                  ],
                ),
              ],
            ),
            // Tab 4: More hub + accounts / members / settings
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/more',
                  builder: (context, state) => const MoreHubScreen(),
                ),
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
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => AccountDetailScreen(
                        accountId: state.pathParameters['accountId']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: '/members',
                  builder: (context, state) => const HouseholdMembersScreen(),
                ),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(error?.toString() ?? l10n.errorPageNotFound),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: Text(l10n.goHome),
            ),
          ],
        ),
      ),
    );
  }
}
