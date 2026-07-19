import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:meta/meta.dart';

/// A minimal projection of a ledger entry used for balance calculations.
///
/// This is a pure domain type — it has no dependency on Drift, Flutter, or
/// any infrastructure library. Repository implementations must map their
/// database rows to [LedgerEntryRecord] before passing them to
/// [LedgerCalculator].
@immutable
final class LedgerEntryRecord {
  const LedgerEntryRecord({
    required this.id,
    required this.accountId,
    required this.direction,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.entryType,
    required this.effectiveDate,
    required this.isReversal,
    this.reversalOfEntryId,
  });

  final String id;
  final String accountId;
  final LedgerDirection direction;

  /// Always a positive integer. The [direction] field determines whether this
  /// is a credit (inflow) or debit (outflow).
  final int amountMinorUnits;

  final String currencyCode;
  final LedgerEntryType entryType;

  /// Date in "YYYY-MM-DD" format (user-chosen effective date).
  final String effectiveDate;

  final bool isReversal;
  final String? reversalOfEntryId;
}

/// Pure, testable balance computation from ledger entries.
///
/// NO widget may call these methods directly (INV-012).
/// NO Drift, Firebase, or Flutter dependency is permitted in this class.
///
/// Balance formula (FINANCIAL_MODEL.md §6):
///   balance = Σ(credit.amountMinorUnits) - Σ(debit.amountMinorUnits)
///
/// Reversal entries are included in the sum. The reversal credit + reversal
/// debit pair nets to zero together with the original entries, producing the
/// correct post-reversal balance without any special filter.
abstract final class LedgerCalculator {
  LedgerCalculator._();

  /// Computes the current balance for [accountId] from [entries].
  ///
  /// Returns [Money.zero] when [entries] is empty.
  ///
  /// [currency] is used to construct the result; it must match the currency
  /// of the entries (all entries for a single account share one currency in V1).
  static Money balance({required String accountId, required List<LedgerEntryRecord> entries, required Currency currency}) {
    return _sum(accountId: accountId, entries: entries, currency: currency);
  }

  /// Computes the historical balance for [accountId] as of [asOfDate].
  ///
  /// Only entries whose [LedgerEntryRecord.effectiveDate] is less than or
  /// equal to [asOfDate] are included (INV-012).
  ///
  /// [asOfDate] must be in "YYYY-MM-DD" format. Lexicographic comparison is
  /// valid for ISO 8601 date strings.
  static Money historicalBalance({required String accountId, required List<LedgerEntryRecord> entries, required Currency currency, required String asOfDate}) {
    final filtered = entries.where((e) => e.effectiveDate.compareTo(asOfDate) <= 0).toList();
    return _sum(accountId: accountId, entries: filtered, currency: currency);
  }

  /// Computes the total balance across multiple accounts by summing the
  /// provided individual balances.
  ///
  /// All [balances] must share the same [Currency] (INV-009 scope).
  static Money totalBalance(List<Money> balances) {
    if (balances.isEmpty) return const Money.zero(Currency.egp);
    var total = Money.zero(balances.first.currency);
    for (final b in balances) {
      total = total + b;
    }
    return total;
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  static Money _sum({required String accountId, required List<LedgerEntryRecord> entries, required Currency currency}) {
    var credits = 0;
    var debits = 0;
    for (final e in entries) {
      if (e.accountId != accountId) continue;
      switch (e.direction) {
        case LedgerDirection.credit:
          credits = _checkedAdd(credits, e.amountMinorUnits);
        case LedgerDirection.debit:
          debits = _checkedAdd(debits, e.amountMinorUnits);
      }
    }
    final result = _checkedSubtract(credits, debits);
    return Money(minorUnits: result, currency: currency);
  }

  static int _checkedAdd(int a, int b) {
    final result = a + b;
    if (((a ^ result) & (b ^ result)) < 0) {
      throw StateError('Balance overflow computing ledger sum');
    }
    return result;
  }

  static int _checkedSubtract(int a, int b) {
    final result = a - b;
    if (((a ^ b) & (a ^ result)) < 0) {
      throw StateError('Balance overflow computing ledger difference');
    }
    return result;
  }
}

/// Pairs an account ID with its computed balance.
@immutable
final class AccountBalance {
  const AccountBalance({required this.accountId, required this.balance});
  final String accountId;
  final Money balance;
}
