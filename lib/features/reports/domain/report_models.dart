/// Domain models for the financial reports feature.
///
/// All models are immutable value objects. No mutation occurs in this layer.
/// Currency amounts are always per-currency (no mixed-currency aggregation).
library;

import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/reports/domain/report_filter.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:meta/meta.dart';

// ── Request ───────────────────────────────────────────────────────────────────

/// Input to any report use case.
@immutable
final class FinancialReportRequest {
  const FinancialReportRequest({
    required this.householdId,
    required this.period,
    this.filter = const ReportFilter(),
  });

  final String householdId;
  final DashboardPeriod period;
  final ReportFilter filter;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialReportRequest &&
          other.householdId == householdId &&
          other.period == period &&
          other.filter == filter;

  @override
  int get hashCode => Object.hash(householdId, period, filter);

  @override
  String toString() =>
      'FinancialReportRequest($householdId, ${period.startDate}–${period.endDate})';
}

// ── Flow summary ──────────────────────────────────────────────────────────────

/// Gross + net income and expense flows per currency for a period.
@immutable
final class CurrencyFlowSummary {
  const CurrencyFlowSummary({
    required this.currencyCode,
    required this.grossIncomeMinorUnits,
    required this.grossExpenseMinorUnits,
    this.incomeReversalMinorUnits = 0,
    this.expenseReversalMinorUnits = 0,
  });

  final String currencyCode;

  /// All income operations in the period (no is_reversed exclusion).
  final int grossIncomeMinorUnits;

  /// All expense operations in the period (no is_reversed exclusion).
  final int grossExpenseMinorUnits;

  /// Reversal operations in the period that cancel income.
  final int incomeReversalMinorUnits;

  /// Reversal operations in the period that cancel expense.
  final int expenseReversalMinorUnits;

  int get netIncomeMinorUnits => grossIncomeMinorUnits - incomeReversalMinorUnits;

  int get netExpenseMinorUnits => grossExpenseMinorUnits - expenseReversalMinorUnits;

  int get netCashFlowMinorUnits => netIncomeMinorUnits - netExpenseMinorUnits;

  bool get hasReversalEffect => incomeReversalMinorUnits != 0 || expenseReversalMinorUnits != 0;
}

// ── Expense breakdowns ────────────────────────────────────────────────────────

/// Expense total for one scope and currency.
@immutable
final class ExpenseScopeBreakdown {
  const ExpenseScopeBreakdown({
    required this.scope,
    required this.currencyCode,
    required this.totalMinorUnits,
    required this.transactionCount,
  });

  final ExpenseScope scope;
  final String currencyCode;
  final int totalMinorUnits;
  final int transactionCount;
}

/// Expense or income total for one category and currency.
@immutable
final class CategoryBreakdown {
  const CategoryBreakdown({
    required this.categoryCode,
    required this.categoryType,
    required this.currencyCode,
    required this.totalMinorUnits,
    required this.transactionCount,
  });

  final String categoryCode;

  /// Whether this is an expense or income category.
  final CategoryType categoryType;

  final String currencyCode;
  final int totalMinorUnits;
  final int transactionCount;
}

// ── Member breakdown ──────────────────────────────────────────────────────────

/// Member spending breakdown (by spender or beneficiary).
@immutable
final class MemberSpendingBreakdown {
  const MemberSpendingBreakdown({
    required this.memberId,
    required this.memberDisplayName,
    required this.currencyCode,
    required this.totalMinorUnits,
    required this.transactionCount,
  });

  final String memberId;
  final String memberDisplayName;
  final String currencyCode;
  final int totalMinorUnits;
  final int transactionCount;
}

// ── Account flow ──────────────────────────────────────────────────────────────

/// Income/expense/transfer/adjustment flows for one account and currency.
///
/// RECONCILIATION INVARIANT:
///   openingBalance + income - expense + transfersIn - transfersOut
///     + adjustments + reversalEffect = closingBalance
@immutable
final class AccountFlowBreakdown {
  const AccountFlowBreakdown({
    required this.accountId,
    required this.accountName,
    required this.currencyCode,
    required this.openingBalanceMinorUnits,
    required this.incomeMinorUnits,
    required this.expenseMinorUnits,
    required this.transfersInMinorUnits,
    required this.transfersOutMinorUnits,
    required this.adjustmentsMinorUnits,
    required this.reversalEffectMinorUnits,
    required this.closingBalanceMinorUnits,
  });

  final String accountId;
  final String accountName;
  final String currencyCode;

  /// Sum of credits minus debits before the period start.
  final int openingBalanceMinorUnits;

  /// Income credits in the period.
  final int incomeMinorUnits;

  /// Expense debits in the period.
  final int expenseMinorUnits;

  /// Transfer-in credits in the period.
  final int transfersInMinorUnits;

  /// Transfer-out debits in the period.
  final int transfersOutMinorUnits;

  /// Net adjustment effect in the period (positive = credit, negative = debit).
  final int adjustmentsMinorUnits;

  /// Net reversal effect in the period (positive = reversal credit restored funds).
  final int reversalEffectMinorUnits;

  /// Sum of credits minus debits through period end (all-time up to end).
  final int closingBalanceMinorUnits;

  /// Verifies the accounting identity holds for this account.
  bool get reconciles {
    final computed =
        openingBalanceMinorUnits +
        incomeMinorUnits -
        expenseMinorUnits +
        transfersInMinorUnits -
        transfersOutMinorUnits +
        adjustmentsMinorUnits +
        reversalEffectMinorUnits;
    return computed == closingBalanceMinorUnits;
  }
}

// ── Home savings ──────────────────────────────────────────────────────────────

/// Home savings flow report for one homeSavingsCash account.
@immutable
final class HomeSavingsFlowSummary {
  const HomeSavingsFlowSummary({
    required this.accountId,
    required this.accountName,
    required this.currencyCode,
    required this.openingBalanceMinorUnits,
    required this.directIncomeMinorUnits,
    required this.directExpenseMinorUnits,
    required this.transfersInMinorUnits,
    required this.transfersOutMinorUnits,
    required this.spouseWalletFundingMinorUnits,
    required this.spouseWalletReturnMinorUnits,
    required this.adjustmentsMinorUnits,
    required this.reversalEffectMinorUnits,
    required this.closingBalanceMinorUnits,
    required this.currentBalanceMinorUnits,
  });

  final String accountId;
  final String accountName;
  final String currencyCode;
  final int openingBalanceMinorUnits;
  final int directIncomeMinorUnits;
  final int directExpenseMinorUnits;
  final int transfersInMinorUnits;
  final int transfersOutMinorUnits;

  /// Subset of transfersOut to spouse wallets.
  final int spouseWalletFundingMinorUnits;

  /// Subset of transfersIn from spouse wallet returns.
  final int spouseWalletReturnMinorUnits;

  final int adjustmentsMinorUnits;
  final int reversalEffectMinorUnits;

  /// All-time balance as of period end.
  final int closingBalanceMinorUnits;

  /// All-time balance (live, outside period boundaries).
  final int currentBalanceMinorUnits;
}

// ── Spouse wallet report ──────────────────────────────────────────────────────

/// Spouse wallet report for one spouseCashWallet account.
@immutable
final class SpouseWalletReport {
  const SpouseWalletReport({
    required this.accountId,
    required this.accountName,
    required this.currencyCode,
    required this.openingBalanceMinorUnits,
    required this.periodFundedMinorUnits,
    required this.periodSpentMinorUnits,
    required this.periodReturnedMinorUnits,
    required this.periodReversalEffectMinorUnits,
    required this.periodClosingBalanceMinorUnits,
    required this.currentBalanceMinorUnits,
  });

  final String accountId;
  final String accountName;
  final String currencyCode;

  /// Balance at start of period (before any period activity).
  final int openingBalanceMinorUnits;

  /// Transfers into the wallet during the period (funding from home savings).
  final int periodFundedMinorUnits;

  /// Expenses paid from the wallet during the period.
  final int periodSpentMinorUnits;

  /// Transfers out of the wallet during the period (returns to home savings).
  final int periodReturnedMinorUnits;

  /// Net reversal effects in the period.
  final int periodReversalEffectMinorUnits;

  /// Balance at end of period = opening + funded - spent - returned + reversal.
  final int periodClosingBalanceMinorUnits;

  /// All-time ledger-derived balance (not bounded by period).
  final int currentBalanceMinorUnits;
}

// ── Protected funds ───────────────────────────────────────────────────────────

/// Protected fund report per protected account.
@immutable
final class ProtectedFundsSummary {
  const ProtectedFundsSummary({
    required this.accountId,
    required this.accountName,
    required this.accountType,
    required this.currencyCode,
    required this.openingBalanceMinorUnits,
    required this.fundingMinorUnits,
    required this.withdrawalMinorUnits,
    required this.reversalEffectMinorUnits,
    required this.closingBalanceMinorUnits,
    required this.currentBalanceMinorUnits,
    required this.withdrawalAudits,
  });

  final String accountId;
  final String accountName;
  final FinancialAccountType accountType;
  final String currencyCode;
  final int openingBalanceMinorUnits;
  final int fundingMinorUnits;
  final int withdrawalMinorUnits;
  final int reversalEffectMinorUnits;
  final int closingBalanceMinorUnits;
  final int currentBalanceMinorUnits;

  /// Audit records for withdrawals from this fund (all-time).
  final List<WithdrawalAuditSummary> withdrawalAudits;
}

/// A single withdrawal audit record for a protected fund.
@immutable
final class WithdrawalAuditSummary {
  const WithdrawalAuditSummary({
    required this.operationId,
    required this.effectiveDate,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.reason,
    required this.beneficiaryMemberId,
    required this.isReversed,
  });

  final String operationId;
  final String effectiveDate;
  final int amountMinorUnits;
  final String currencyCode;
  final String reason;
  final String beneficiaryMemberId;
  final bool isReversed;
}

// ── Drill-down transaction row ─────────────────────────────────────────────────

/// A single row in a drill-down transaction list.
@immutable
final class ReportTransactionRow {
  const ReportTransactionRow({
    required this.operationId,
    required this.operationType,
    required this.effectiveDate,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.accountId,
    required this.accountName,
    this.categoryCode,
    this.spenderMemberId,
    this.beneficiaryMemberId,
    this.scope,
    required this.isReversed,
    required this.isProtectedWithdrawal,
    this.note,
  });

  final String operationId;
  final OperationType operationType;
  final String effectiveDate;
  final int amountMinorUnits;
  final String currencyCode;
  final String accountId;
  final String accountName;
  final String? categoryCode;
  final String? spenderMemberId;
  final String? beneficiaryMemberId;
  final ExpenseScope? scope;
  final bool isReversed;
  final bool isProtectedWithdrawal;
  final String? note;
}
