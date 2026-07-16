/// Typed result for balance queries.
///
/// Distinguishes between three situations that previously all returned 0:
/// - [BalanceFound]: the account exists in the household and has a computed balance.
/// - [BalanceAccountNotFound]: the account ID does not exist in the specified household.
sealed class BalanceQueryResult {
  const BalanceQueryResult();
}

/// The account exists in the household; [minorUnits] is the ledger-derived balance.
///
/// A balance of zero here means the account has no transactions (or credits equal
/// debits), NOT that the account is absent.
final class BalanceFound extends BalanceQueryResult {
  final int minorUnits;
  final String currencyCode;
  const BalanceFound({required this.minorUnits, required this.currencyCode});
}

/// The account ID was not found in the specified household.
///
/// This replaces the previous silent-zero return and allows callers to distinguish
/// between "zero balance" and "account not in this household".
final class BalanceAccountNotFound extends BalanceQueryResult {
  const BalanceAccountNotFound();
}
