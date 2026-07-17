/// Read-only repository for financial report queries.
library;

import 'package:family_money_manager/features/reports/domain/report_models.dart';

/// Read-only repository for aggregating financial report data.
///
/// All methods are pure reads. No mutations occur.
/// All amounts are per-currency; no mixed-currency aggregation is performed.
abstract interface class ReportQueryRepository {
  /// Income and expense gross/net flow for the period.
  ///
  /// Follows the period-activity model: all income/expense operations in the
  /// period are included regardless of is_reversed. Reversal operations in the
  /// period are reported as separate reversal effects.
  Future<List<CurrencyFlowSummary>> incomeExpenseFlow(FinancialReportRequest req);

  /// Expense totals grouped by expense scope and currency.
  Future<List<ExpenseScopeBreakdown>> expenseByScope(FinancialReportRequest req);

  /// Expense totals grouped by spender member and currency.
  Future<List<MemberSpendingBreakdown>> expenseBySpender(FinancialReportRequest req);

  /// Expense totals grouped by beneficiary member and currency.
  Future<List<MemberSpendingBreakdown>> expenseByBeneficiary(FinancialReportRequest req);

  /// Expense totals grouped by category code and currency.
  Future<List<CategoryBreakdown>> expenseByCategory(FinancialReportRequest req);

  /// Income totals grouped by category code and currency.
  Future<List<CategoryBreakdown>> incomeByCategory(FinancialReportRequest req);

  /// Per-account flow breakdown: opening balance, income, expense, transfers,
  /// adjustments, reversal effects, closing balance.
  Future<List<AccountFlowBreakdown>> accountFlows(FinancialReportRequest req);

  /// Home savings account flow reports (homeSavingsCash account type).
  Future<List<HomeSavingsFlowSummary>> homeSavingsFlows(FinancialReportRequest req);

  /// Spouse wallet reports (spouseCashWallet account type).
  Future<List<SpouseWalletReport>> spouseWalletReports(FinancialReportRequest req);

  /// Protected fund reports (is_protected = 1 accounts) with withdrawal audits.
  Future<List<ProtectedFundsSummary>> protectedFundsReports(FinancialReportRequest req);

  /// Drill-down: individual transaction rows matching the request filter.
  ///
  /// Returns at most [limit] rows, ordered by effective_date DESC, id DESC.
  Future<List<ReportTransactionRow>> drillDown(FinancialReportRequest req, {int limit = 100});
}
