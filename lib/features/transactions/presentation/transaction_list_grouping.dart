/// Turning a flat list of operations into what the list screen renders.
///
/// Kept out of the widget deliberately: grouping by date and refusing to add
/// two currencies together are decisions about money, and they are far easier
/// to test as functions than as pixels.
library;

import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:meta/meta.dart';

/// One day's transactions, newest day first.
@immutable
final class TransactionDateGroup {
  const TransactionDateGroup({
    required this.effectiveDate,
    required this.transactions,
  });

  /// ISO `YYYY-MM-DD`. Formatting it for a reader is the screen's job.
  final String effectiveDate;

  final List<TransactionSummary> transactions;
}

/// Totals for a single currency.
///
/// There is no combined total and there is no default currency. Adding EGP to
/// USD produces a number that is true of nothing, so the summary is computed
/// per currency and the screen states which one it is showing.
@immutable
final class TransactionPeriodTotals {
  const TransactionPeriodTotals({
    required this.currencyCode,
    required this.incomeMinorUnits,
    required this.expenseMinorUnits,
    required this.transferMinorUnits,
    required this.transactionCount,
  });

  final String currencyCode;
  final int incomeMinorUnits;
  final int expenseMinorUnits;

  /// Money moved between the household's own accounts.
  ///
  /// Reported separately and never folded into the other two: a transfer
  /// changes no household total, so counting it as either would inflate both.
  final int transferMinorUnits;

  final int transactionCount;
}

/// Groups [transactions] by effective date, preserving the incoming order.
///
/// The query already returns newest first; re-sorting here would let the list
/// disagree with the ledger's own deterministic ordering.
List<TransactionDateGroup> groupByEffectiveDate(
  List<TransactionSummary> transactions,
) {
  final groups = <String, List<TransactionSummary>>{};
  for (final transaction in transactions) {
    groups
        .putIfAbsent(transaction.operation.effectiveDate, () => [])
        .add(transaction);
  }
  return [
    for (final entry in groups.entries)
      TransactionDateGroup(effectiveDate: entry.key, transactions: entry.value),
  ];
}

/// Per-currency totals, ordered by how many transactions each currency has.
///
/// Reversed operations and reversing entries are both excluded. Their net
/// effect is zero by construction, so counting either would report money that
/// moved when none did — and counting both would double the error.
List<TransactionPeriodTotals> totalsByCurrency(
  List<TransactionSummary> transactions,
) {
  final income = <String, int>{};
  final expense = <String, int>{};
  final transfer = <String, int>{};
  final counts = <String, int>{};

  for (final transaction in transactions) {
    final op = transaction.operation;
    if (op.isReversed || op.type == OperationType.reversal) continue;

    final code = op.currencyCode;
    counts[code] = (counts[code] ?? 0) + 1;
    final amount = op.totalAmountMinorUnits;

    switch (op.type) {
      case OperationType.income || OperationType.openingBalance:
        income[code] = (income[code] ?? 0) + amount;
      case OperationType.expense:
        expense[code] = (expense[code] ?? 0) + amount;
      case OperationType.transfer:
        transfer[code] = (transfer[code] ?? 0) + amount;
      case _:
        // Adjustments and the asset/liability types carry no agreed sign at
        // this level; they are counted but deliberately not summed into a
        // figure the screen presents as income or expense.
        break;
    }
  }

  final codes = counts.keys.toList()
    ..sort((a, b) {
      final byCount = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
      // Alphabetical tiebreak so the order is stable across rebuilds.
      return byCount != 0 ? byCount : a.compareTo(b);
    });

  return [
    for (final code in codes)
      TransactionPeriodTotals(
        currencyCode: code,
        incomeMinorUnits: income[code] ?? 0,
        expenseMinorUnits: expense[code] ?? 0,
        transferMinorUnits: transfer[code] ?? 0,
        transactionCount: counts[code] ?? 0,
      ),
  ];
}
