/// Riverpod providers for the reports feature.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:family_money_manager/features/reports/application/get_account_flow_report_use_case.dart';
import 'package:family_money_manager/features/reports/application/get_category_report_use_case.dart';
import 'package:family_money_manager/features/reports/application/get_home_savings_report_use_case.dart';
import 'package:family_money_manager/features/reports/application/get_income_expense_report_use_case.dart';
import 'package:family_money_manager/features/reports/application/get_protected_funds_report_use_case.dart';
import 'package:family_money_manager/features/reports/application/get_report_transactions_use_case.dart';
import 'package:family_money_manager/features/reports/application/get_spending_attribution_report_use_case.dart';
import 'package:family_money_manager/features/reports/application/get_spouse_wallet_report_use_case.dart';
import 'package:family_money_manager/features/reports/data/drift_report_query_repository.dart';
import 'package:family_money_manager/features/reports/data/report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final reportQueryRepositoryProvider = Provider<ReportQueryRepository>((ref) {
  return DriftReportQueryRepository(ref.watch(appDatabaseProvider));
});

// ── Use cases ─────────────────────────────────────────────────────────────────

final getIncomeExpenseReportUseCaseProvider =
    Provider<GetIncomeExpenseReportUseCase>((ref) {
      return GetIncomeExpenseReportUseCase(
        ref.watch(reportQueryRepositoryProvider),
      );
    });

final getSpendingAttributionReportUseCaseProvider =
    Provider<GetSpendingAttributionReportUseCase>((ref) {
      return GetSpendingAttributionReportUseCase(
        ref.watch(reportQueryRepositoryProvider),
      );
    });

final getCategoryReportUseCaseProvider = Provider<GetCategoryReportUseCase>((
  ref,
) {
  return GetCategoryReportUseCase(ref.watch(reportQueryRepositoryProvider));
});

final getAccountFlowReportUseCaseProvider =
    Provider<GetAccountFlowReportUseCase>((ref) {
      return GetAccountFlowReportUseCase(
        ref.watch(reportQueryRepositoryProvider),
      );
    });

final getHomeSavingsReportUseCaseProvider =
    Provider<GetHomeSavingsReportUseCase>((ref) {
      return GetHomeSavingsReportUseCase(
        ref.watch(reportQueryRepositoryProvider),
      );
    });

final getSpouseWalletReportUseCaseProvider =
    Provider<GetSpouseWalletReportUseCase>((ref) {
      return GetSpouseWalletReportUseCase(
        ref.watch(reportQueryRepositoryProvider),
      );
    });

final getProtectedFundsReportUseCaseProvider =
    Provider<GetProtectedFundsReportUseCase>((ref) {
      return GetProtectedFundsReportUseCase(
        ref.watch(reportQueryRepositoryProvider),
      );
    });

final getReportTransactionsUseCaseProvider =
    Provider<GetReportTransactionsUseCase>((ref) {
      return GetReportTransactionsUseCase(
        ref.watch(reportQueryRepositoryProvider),
      );
    });

// ── Selected report request ───────────────────────────────────────────────────

/// Notifier that manages the currently selected report request.
class ReportRequestNotifier extends Notifier<FinancialReportRequest> {
  @override
  FinancialReportRequest build() {
    final clock = ref.watch(clockProvider);
    return FinancialReportRequest(
      householdId: 'household-v1',
      period: DashboardPeriod.currentMonth(clock),
    );
  }

  /// Replace the active request (period + filters).
  void update(FinancialReportRequest request) => state = request;
}

/// The currently selected report request (period + filters).
///
/// Defaults to the current month with no filters.
final reportRequestProvider =
    NotifierProvider<ReportRequestNotifier, FinancialReportRequest>(
      ReportRequestNotifier.new,
    );

// ── Report data providers ─────────────────────────────────────────────────────

final incomeExpenseReportProvider = FutureProvider.autoDispose
    .family<AppResult<List<CurrencyFlowSummary>>, FinancialReportRequest>((
      ref,
      req,
    ) async {
      final useCase = ref.watch(getIncomeExpenseReportUseCaseProvider);
      return useCase.execute(req);
    });

final spendingAttributionReportProvider = FutureProvider.autoDispose
    .family<AppResult<SpendingAttributionReport>, FinancialReportRequest>((
      ref,
      req,
    ) async {
      final useCase = ref.watch(getSpendingAttributionReportUseCaseProvider);
      return useCase.execute(req);
    });

final categoryReportProvider = FutureProvider.autoDispose
    .family<AppResult<CategoryReport>, FinancialReportRequest>((
      ref,
      req,
    ) async {
      final useCase = ref.watch(getCategoryReportUseCaseProvider);
      return useCase.execute(req);
    });

final accountFlowReportProvider = FutureProvider.autoDispose
    .family<AppResult<List<AccountFlowBreakdown>>, FinancialReportRequest>((
      ref,
      req,
    ) async {
      final useCase = ref.watch(getAccountFlowReportUseCaseProvider);
      return useCase.execute(req);
    });

final homeSavingsReportProvider = FutureProvider.autoDispose
    .family<AppResult<List<HomeSavingsFlowSummary>>, FinancialReportRequest>((
      ref,
      req,
    ) async {
      final useCase = ref.watch(getHomeSavingsReportUseCaseProvider);
      return useCase.execute(req);
    });

final spouseWalletReportProvider = FutureProvider.autoDispose
    .family<AppResult<List<SpouseWalletReport>>, FinancialReportRequest>((
      ref,
      req,
    ) async {
      final useCase = ref.watch(getSpouseWalletReportUseCaseProvider);
      return useCase.execute(req);
    });

final protectedFundsReportProvider = FutureProvider.autoDispose
    .family<AppResult<List<ProtectedFundsSummary>>, FinancialReportRequest>((
      ref,
      req,
    ) async {
      final useCase = ref.watch(getProtectedFundsReportUseCaseProvider);
      return useCase.execute(req);
    });

final reportTransactionsProvider = FutureProvider.autoDispose
    .family<AppResult<List<ReportTransactionRow>>, FinancialReportRequest>((
      ref,
      req,
    ) async {
      final useCase = ref.watch(getReportTransactionsUseCaseProvider);
      return useCase.execute(req);
    });
