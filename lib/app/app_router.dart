import 'package:family_money_manager/core/database/database_providers.dart';
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
import 'package:family_money_manager/features/onboarding/onboarding_screen.dart';
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
import 'package:family_money_manager/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/transactions_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/transfer_form_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/transfer_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Creates and owns the single [GoRouter] instance for the application.
///
/// Phase 4A/4B routes:
///   /dashboard             — DashboardScreen (tab 0)
///   /accounts              — AccountsScreen (tab 1)
///   /accounts/new          — AccountCreationScreen (push)
///   /accounts/:accountId   — AccountDetailScreen (push)
///   /transactions          — TransactionsScreen (tab 2)
///   /transactions/new      — CreateTransactionScreen (push)
///   /transactions/new/income          — IncomeFormScreen
///   /transactions/new/income/review   — IncomeReviewScreen
///   /transactions/new/expense         — ExpenseFormScreen
///   /transactions/new/expense/review  — ExpenseReviewScreen
///   /transactions/new/transfer        — TransferFormScreen
///   /transactions/new/transfer/review — TransferReviewScreen
///   /transactions/:operationId        — TransactionDetailScreen
///   /members               — HouseholdMembersScreen (tab 3)
///   /settings              — SettingsScreen (tab 4)
///   /reports               — ReportsLandingScreen (push from dashboard)
///   /reports/income-expense   — IncomeExpenseReportScreen
///   /reports/attribution      — SpendingAttributionReportScreen
///   /reports/categories       — CategoryReportScreen
///   /reports/accounts         — AccountFlowReportScreen
///   /reports/home-savings     — HomeSavingsReportScreen
///   /reports/spouse-wallet    — SpouseWalletReportScreen
///   /reports/protected-funds  — ProtectedFundsReportScreen
///   /reports/transactions     — ReportTransactionListScreen (drill-down)
///   /budgets               — BudgetsListScreen (Phase 5A)
///   /budgets/new           — BudgetCreationScreen
///   /budgets/:budgetId     — BudgetDetailScreen
abstract final class AppRouter {
  static GoRouter create(WidgetRef ref) {
    return GoRouter(
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
        // ── Phase 4A shell with bottom navigation ─────────────────────────
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            // Tab 0: Dashboard
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard',
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            // Tab 1: Accounts
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
            // Tab 2: Transactions
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
                    GoRoute(
                      path: ':operationId',
                      builder: (context, state) => TransactionDetailScreen(
                        operationId: state.pathParameters['operationId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Tab 3: Family members
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/members',
                  builder: (context, state) => const HouseholdMembersScreen(),
                ),
              ],
            ),
            // Tab 4: Settings
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

        // ── Phase 4B report routes (pushed from dashboard, not in shell tab) ─
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsLandingScreen(),
          routes: [
            GoRoute(
              path: 'income-expense',
              builder: (context, state) => const IncomeExpenseReportScreen(),
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
              builder: (context, state) => const AccountFlowReportScreen(),
            ),
            GoRoute(
              path: 'home-savings',
              builder: (context, state) => const HomeSavingsReportScreen(),
            ),
            GoRoute(
              path: 'spouse-wallet',
              builder: (context, state) => const SpouseWalletReportScreen(),
            ),
            GoRoute(
              path: 'protected-funds',
              builder: (context, state) => const ProtectedFundsReportScreen(),
            ),
            GoRoute(
              path: 'transactions',
              builder: (context, state) => const ReportTransactionListScreen(),
            ),
          ],
        ),

        // ── Phase 5A budget routes ─────────────────────────────────────────
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
              builder: (context, state) => BudgetDetailScreen(
                budgetId: state.pathParameters['budgetId']!,
              ),
            ),
          ],
        ),

        // ── Phase 5B goal routes ────────────────────────────────────────────
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
              builder: (context, state) =>
                  GoalDetailScreen(goalId: state.pathParameters['goalId']!),
              routes: [
                GoRoute(
                  path: 'fund',
                  builder: (context, state) =>
                      FundGoalScreen(goalId: state.pathParameters['goalId']!),
                ),
                GoRoute(
                  path: 'release',
                  builder: (context, state) => ReleaseGoalScreen(
                    goalId: state.pathParameters['goalId']!,
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Phase 6A certificate routes ─────────────────────────────────────
        GoRoute(
          path: '/certificates',
          builder: (context, state) => const CertificatesListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const CertificateCreationScreen(),
            ),
            GoRoute(
              path: ':certificateId',
              builder: (context, state) => CertificateDetailScreen(
                certificateId: state.pathParameters['certificateId']!,
              ),
              routes: [
                GoRoute(
                  path: 'profit',
                  builder: (context, state) => RecordCertificateProfitScreen(
                    certificateId: state.pathParameters['certificateId']!,
                  ),
                ),
                GoRoute(
                  path: 'redeem',
                  builder: (context, state) => RedeemCertificateScreen(
                    certificateId: state.pathParameters['certificateId']!,
                  ),
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
