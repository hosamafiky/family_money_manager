import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/dashboard/data/dashboard_query_repository.dart';
import 'package:family_money_manager/features/dashboard/domain/dashboard_summary.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';

/// Fetches and assembles the complete dashboard snapshot for one period.
///
/// Executes all sub-queries in parallel via [Future.wait].
/// Any persistence failure collapses to [AppPersistenceFailure].
final class GetDashboardSummaryUseCase {
  const GetDashboardSummaryUseCase({
    required DashboardQueryRepository queryRepository,
    required Clock clock,
  }) : _repo = queryRepository,
       _clock = clock;

  final DashboardQueryRepository _repo;
  final Clock _clock;

  Future<AppResult<DashboardSummary>> execute({
    required String householdId,
    required DashboardPeriod period,
  }) async {
    try {
      final now = _clock.now;
      final todayLocal =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        _repo.spendableBalances(householdId: householdId),
        _repo.protectedBalances(
          householdId: householdId,
          todayLocal: todayLocal,
        ),
        _repo.periodFlow(householdId: householdId, period: period),
        _repo.expensesByScope(householdId: householdId, period: period),
        _repo.spouseWalletSummaries(householdId: householdId, period: period),
        _repo.recentActivity(householdId: householdId),
        _repo.availableToSpend(householdId: householdId),
        _repo.excludedFromAvailable(householdId: householdId),
        _repo.heldByReason(householdId: householdId),
      ]);

      return AppOk(
        DashboardSummary(
          householdId: householdId,
          period: period,
          spendableBalances: (results[0] as List).cast<CurrencyAmountSummary>(),
          protectedBalances: (results[1] as List).cast<CurrencyAmountSummary>(),
          periodFlow: (results[2] as List).cast<PeriodFlowSummary>(),
          expensesByScope: (results[3] as List).cast<ExpenseScopeSummary>(),
          spouseWallets: (results[4] as List)
              .cast<SpouseWalletDashboardSummary>(),
          recentActivity: (results[5] as List).cast<TransactionSummary>(),
          availableToSpend: (results[6] as List).cast<CurrencyAmountSummary>(),
          excludedFromAvailable: (results[7] as List)
              .cast<ExcludedAmountSummary>(),
          heldByReason: (results[8] as List).cast<HeldAmountSummary>(),
          generatedAt: now,
        ),
      );
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}
