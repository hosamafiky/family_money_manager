import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:meta/meta.dart';

/// Top-level dashboard snapshot for one household and one period.
@immutable
final class DashboardSummary {
  const DashboardSummary({
    required this.householdId,
    required this.period,
    required this.spendableBalances,
    required this.protectedBalances,
    required this.periodFlow,
    required this.expensesByScope,
    required this.spouseWallets,
    required this.recentActivity,
    required this.generatedAt,
  });

  final String householdId;
  final DashboardPeriod period;

  /// Spendable (non-protected, non-archived) account balances, grouped by currency.
  final List<CurrencyAmountSummary> spendableBalances;

  /// Protected account balances, grouped by currency.
  final List<CurrencyAmountSummary> protectedBalances;

  /// Income and expense flow for the period, grouped by currency.
  final List<PeriodFlowSummary> periodFlow;

  /// Expense totals grouped by scope and currency for the period.
  final List<ExpenseScopeSummary> expensesByScope;

  /// One entry per spouse-cash-wallet account.
  final List<SpouseWalletDashboardSummary> spouseWallets;

  /// Recent activity, limited and ordered deterministically.
  final List<TransactionSummary> recentActivity;

  /// Timestamp when this snapshot was generated (clock.now at query time).
  final DateTime generatedAt;

  bool get hasSpendableBalance =>
      spendableBalances.any((b) => b.totalMinorUnits != 0);

  bool get hasProtectedBalance =>
      protectedBalances.any((b) => b.totalMinorUnits != 0);

  bool get hasPeriodActivity => periodFlow.any(
    (f) => f.grossIncomeMinorUnits != 0 || f.grossExpenseMinorUnits != 0,
  );
}

/// Total ledger-derived balance for one currency.
@immutable
final class CurrencyAmountSummary {
  const CurrencyAmountSummary({
    required this.currencyCode,
    required this.totalMinorUnits,
  });

  final String currencyCode;

  /// Sum of credits minus debits in minor units.
  /// Negative value = data integrity anomaly (balance below zero).
  final int totalMinorUnits;

  bool get isNegative => totalMinorUnits < 0;
}

/// Income and expense totals for one currency in a period.
///
/// PERIOD-ACTIVITY MODEL (Phase 4B correction):
/// Every operation (including subsequently reversed ones) appears in the period
/// where its effectiveDate falls. Reversal operations (type='reversal') appear
/// in their own effectiveDate period and are reported as reversal effects.
/// No operation is silently excluded from gross period totals.
@immutable
final class PeriodFlowSummary {
  const PeriodFlowSummary({
    required this.currencyCode,
    required this.grossIncomeMinorUnits,
    required this.grossExpenseMinorUnits,
    this.incomeReversalMinorUnits = 0,
    this.expenseReversalMinorUnits = 0,
  });

  final String currencyCode;

  /// Gross sum of all income operation amounts in the period (no exclusions).
  final int grossIncomeMinorUnits;

  /// Gross sum of all expense operation amounts in the period (no exclusions).
  final int grossExpenseMinorUnits;

  /// Sum of reversal operation amounts that cancel income in this period.
  /// These are type='reversal' operations whose effectiveDate is in this period
  /// and whose original operation was an income operation.
  final int incomeReversalMinorUnits;

  /// Sum of reversal operation amounts that cancel expense in this period.
  /// These are type='reversal' operations whose effectiveDate is in this period
  /// and whose original operation was an expense operation.
  final int expenseReversalMinorUnits;

  // ── Backward-compat aliases ─────────────────────────────────────────────

  /// Alias for [grossIncomeMinorUnits]. Kept for backward compatibility.
  int get incomeMinorUnits => grossIncomeMinorUnits;

  /// Alias for [grossExpenseMinorUnits]. Kept for backward compatibility.
  int get expenseMinorUnits => grossExpenseMinorUnits;

  // ── Derived ─────────────────────────────────────────────────────────────

  /// Net income: gross income minus income reversals in this period.
  int get netIncomeMinorUnits =>
      grossIncomeMinorUnits - incomeReversalMinorUnits;

  /// Net expense: gross expense minus expense reversals in this period.
  ///
  /// For a same-period reversal: netExpense = gross - reversal = 0.
  /// For a cross-period reversal (original in T, reversal in T+1):
  ///   Period T: netExpense = gross (reversal not in this period)
  ///   Period T+1: reversal shows as expenseReversalMinorUnits
  int get netExpenseMinorUnits =>
      grossExpenseMinorUnits - expenseReversalMinorUnits;

  /// Net cash flow: net income minus net expense.
  int get netCashFlowMinorUnits => netIncomeMinorUnits - netExpenseMinorUnits;
}

/// Expense totals for one scope and one currency in a period.
@immutable
final class ExpenseScopeSummary {
  const ExpenseScopeSummary({
    required this.scope,
    required this.currencyCode,
    required this.totalMinorUnits,
  });

  final ExpenseScope scope;
  final String currencyCode;
  final int totalMinorUnits;
}

/// Spouse-wallet activity and balance for one wallet account.
@immutable
final class SpouseWalletDashboardSummary {
  const SpouseWalletDashboardSummary({
    required this.accountId,
    required this.accountName,
    required this.currencyCode,
    required this.periodFundedMinorUnits,
    required this.periodSpentMinorUnits,
    required this.periodReturnedMinorUnits,
    required this.currentBalanceMinorUnits,
  });

  final String accountId;
  final String accountName;
  final String currencyCode;

  /// Transfers into the wallet during the period (transferIn entries).
  final int periodFundedMinorUnits;

  /// Expenses paid from the wallet during the period (expense entries).
  final int periodSpentMinorUnits;

  /// Transfers out of the wallet during the period (transferOut entries).
  final int periodReturnedMinorUnits;

  /// All-time ledger-derived balance (outside period boundaries).
  final int currentBalanceMinorUnits;
}
