import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/dashboard/domain/dashboard_summary.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';

/// Read-only repository for dashboard aggregation queries.
///
/// All methods are pure reads; no mutations occur.
/// Balance calculations derive from ledger entries (no cached balance field).
abstract interface class DashboardQueryRepository {
  /// Spendable (non-protected, non-archived) account balances by currency.
  ///
  /// Excludes: archived accounts, protected accounts.
  Future<List<CurrencyAmountSummary>> spendableBalances({required String householdId});

  /// Protected account balances by currency.
  ///
  /// Excludes: archived protected accounts.
  Future<List<CurrencyAmountSummary>> protectedBalances({required String householdId});

  /// Period income and expense totals by currency.
  ///
  /// Excludes: transfers, opening balances, adjustments.
  /// PERIOD-ACTIVITY MODEL: All income/expense operations appear in their
  /// effectiveDate period (no is_reversed exclusion from gross totals).
  /// Reversal operations (type='reversal') appear separately as reversal effects
  /// in the period where the reversal's effectiveDate falls.
  Future<List<PeriodFlowSummary>> periodFlow({
    required String householdId,
    required DashboardPeriod period,
  });

  /// Expense totals grouped by scope and currency for the period.
  ///
  /// Uses expense_scope from operation_contexts (preferred over operations.scope).
  Future<List<ExpenseScopeSummary>> expensesByScope({
    required String householdId,
    required DashboardPeriod period,
  });

  /// Spouse-wallet summaries for the period.
  ///
  /// Returns one entry per spouseCashWallet account in the household.
  Future<List<SpouseWalletDashboardSummary>> spouseWalletSummaries({
    required String householdId,
    required DashboardPeriod period,
  });

  /// Recent activity, ordered deterministically, limited to [limit] items.
  ///
  /// Ordering: effective_date DESC, recorded_at DESC, id DESC.
  Future<List<TransactionSummary>> recentActivity({required String householdId, int limit = 20});
}
