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
    (f) => f.incomeMinorUnits != 0 || f.expenseMinorUnits != 0,
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
@immutable
final class PeriodFlowSummary {
  const PeriodFlowSummary({
    required this.currencyCode,
    required this.incomeMinorUnits,
    required this.expenseMinorUnits,
    required this.netExpenseMinorUnits,
  });

  final String currencyCode;

  /// Sum of income operation amounts in the period.
  final int incomeMinorUnits;

  /// Gross sum of expense operation amounts (including reversed operations).
  final int expenseMinorUnits;

  /// Net expense: sum of non-reversed expense operations only.
  ///
  /// REVERSAL POLICY: An operation with is_reversed=true is included in
  /// [expenseMinorUnits] (gross) but excluded from [netExpenseMinorUnits].
  /// The reversal operation itself (type='reversal') is excluded from both.
  final int netExpenseMinorUnits;
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
