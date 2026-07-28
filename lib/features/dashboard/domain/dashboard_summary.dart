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
    required this.availableToSpend,
    required this.excludedFromAvailable,
    required this.heldByReason,
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

  /// The headline figure: money the household can spend right now.
  ///
  /// [spendableBalances] minus everything in [excludedFromAvailable]. Computed
  /// in the query rather than by subtracting in a widget, because that
  /// subtraction is balance arithmetic and belongs where the ledger is.
  final List<CurrencyAmountSummary> availableToSpend;

  /// Spendable money deliberately left out of [availableToSpend], with the
  /// reason it was excluded.
  ///
  /// The exclusion is stated rather than silent: a household reading a total
  /// needs to know what is not in it.
  final List<ExcludedAmountSummary> excludedFromAvailable;

  /// Money that exists, is not archived, and cannot be spent — grouped by why.
  ///
  /// This is the third state of money. Certificate principal and goal reserves
  /// are neither spendable nor protected, so before this existed they appeared
  /// in no dashboard figure at all. A widget cannot derive it: deciding what is
  /// held, and why, is ledger classification.
  final List<HeldAmountSummary> heldByReason;

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

  bool get hasHeldBalance => heldByReason.any((h) => h.totalMinorUnits != 0);

  bool get hasExcludedBalance =>
      excludedFromAvailable.any((e) => e.totalMinorUnits != 0);

  bool get hasPeriodActivity => periodFlow.any(
    (f) => f.grossIncomeMinorUnits != 0 || f.grossExpenseMinorUnits != 0,
  );
}

/// Why money is held and cannot be spent.
///
/// Ordered from most to least restricted, which is also the order the held
/// region prints them in.
enum HeldReason {
  /// A child's protected fund. Withdrawal requires a named acknowledgement.
  childProtected,

  /// Reserved against a savings goal.
  goalReserve,

  /// Certificate principal, locked for the term.
  certificatePrincipal,

  /// Non-spendable for a reason the dashboard has no specific vocabulary for.
  /// Rendered with a generic label rather than being silently dropped.
  other;

  String get code => name;

  static HeldReason fromCode(String code) {
    for (final r in HeldReason.values) {
      if (r.name == code) return r;
    }
    return HeldReason.other;
  }
}

/// Why spendable money is nonetheless left out of the headline figure.
enum ExclusionReason {
  /// A spouse's wallet. Spendable by them, but telling one member's money from
  /// another's is the point of the row — so it is not in "available to spend".
  spouseWallet;

  String get code => name;

  static ExclusionReason fromCode(String code) {
    for (final r in ExclusionReason.values) {
      if (r.name == code) return r;
    }
    return ExclusionReason.spouseWallet;
  }
}

/// Held money for one reason, in one currency. Never summed across either.
@immutable
final class HeldAmountSummary {
  const HeldAmountSummary({
    required this.reason,
    required this.currencyCode,
    required this.totalMinorUnits,
  });

  final HeldReason reason;
  final String currencyCode;
  final int totalMinorUnits;
}

/// Excluded money for one reason, in one currency.
@immutable
final class ExcludedAmountSummary {
  const ExcludedAmountSummary({
    required this.reason,
    required this.currencyCode,
    required this.totalMinorUnits,
  });

  final ExclusionReason reason;
  final String currencyCode;
  final int totalMinorUnits;
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
