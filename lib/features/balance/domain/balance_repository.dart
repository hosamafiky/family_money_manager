import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/ledger_calculator.dart';
import 'package:family_money_manager/features/balance/domain/balance_result.dart';

/// Repository abstraction for balance queries.
///
/// Balance is ALWAYS derived from the ledger — never from a stored value
/// (FINANCIAL_MODEL §3, INV-012).
///
/// No widget may call these methods directly.
abstract interface class BalanceRepository {
  /// Returns the current balance of [accountId] within [householdId].
  ///
  /// Includes all ledger entries regardless of direction or reversal status.
  /// Reversal entries cancel their originals arithmetically.
  ///
  /// Returns 0 for unknown or cross-household accounts (legacy behaviour).
  /// Prefer [balanceForAccount] for typed results that distinguish zero-balance
  /// from account-not-found.
  Future<int> currentBalanceMinorUnits({
    required String accountId,
    required String householdId,
  });

  /// Returns a typed balance result for [accountId] within [householdId].
  ///
  /// - [BalanceFound] — account exists in this household; [minorUnits] may be 0.
  /// - [BalanceAccountNotFound] — account not found in this household.
  Future<BalanceQueryResult> balanceForAccount({
    required String accountId,
    required String householdId,
  });

  /// Returns the balance of [accountId] as of [asOfDate] (inclusive).
  ///
  /// [asOfDate] must be in "YYYY-MM-DD" format (INV-012).
  Future<int> historicalBalanceMinorUnits({
    required String accountId,
    required String householdId,
    required String asOfDate,
  });

  /// Returns the derived balances for all non-archived accounts in
  /// [householdId] that have [includeInNetWorth] set to true.
  ///
  /// Used for net-worth computation (INV-009).
  Future<List<AccountBalance>> netWorthBalances({required String householdId});
}

/// Trivial adapter: compute balance from a list of [LedgerEntryRecord] and
/// a known [Currency], without any database access.
///
/// Useful in tests and pure domain computations.
abstract final class BalanceCalculator {
  BalanceCalculator._();

  /// Wraps [LedgerCalculator.balance] for consistent naming at the feature layer.
  static int currentBalance({
    required String accountId,
    required List<LedgerEntryRecord> entries,
    required Currency currency,
  }) {
    return LedgerCalculator.balance(
      accountId: accountId,
      entries: entries,
      currency: currency,
    ).minorUnits;
  }

  /// Wraps [LedgerCalculator.historicalBalance] for consistent naming.
  static int historicalBalance({
    required String accountId,
    required List<LedgerEntryRecord> entries,
    required Currency currency,
    required String asOfDate,
  }) {
    return LedgerCalculator.historicalBalance(
      accountId: accountId,
      entries: entries,
      currency: currency,
      asOfDate: asOfDate,
    ).minorUnits;
  }
}
