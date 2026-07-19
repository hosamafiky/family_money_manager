import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';

/// A balance total for one currency.
///
/// Spendable and protected totals are kept separate so that the UI can
/// display them in distinct rows without ever summing across protection levels.
final class CurrencyTotal {
  const CurrencyTotal({
    required this.currency,
    required this.spendableMinorUnits,
    required this.protectedMinorUnits,
  });

  final Currency currency;
  final int spendableMinorUnits;
  final int protectedMinorUnits;
}

/// Computes per-currency spendable and protected totals from a list of
/// accounts and their balances.
///
/// **Cross-currency prohibition**: balances of different currencies are never
/// aggregated. Returns one [CurrencyTotal] per distinct currency code present
/// in the non-archived account list.
///
/// Archived accounts are excluded from all totals (INV-015).
/// Non-spendable, non-protected accounts contribute to neither total.
abstract final class AccountTotalsService {
  AccountTotalsService._();

  /// Computes per-currency totals.
  ///
  /// [accounts] — non-archived or archived accounts (archived are filtered).
  /// [balancesByAccountId] — map of accountId → current balance in minor units.
  static List<CurrencyTotal> compute({
    required List<FinancialAccount> accounts,
    required Map<String, int> balancesByAccountId,
  }) {
    final Map<String, ({int spendable, int protected_})> byCurrency = {};

    for (final account in accounts) {
      if (account.isArchived) continue;
      final balance = balancesByAccountId[account.id] ?? 0;
      final entry = byCurrency.putIfAbsent(
        account.currencyCode,
        () => (spendable: 0, protected_: 0),
      );
      if (account.isProtected) {
        byCurrency[account.currencyCode] = (
          spendable: entry.spendable,
          protected_: entry.protected_ + balance,
        );
      } else if (account.isSpendable) {
        byCurrency[account.currencyCode] = (
          spendable: entry.spendable + balance,
          protected_: entry.protected_,
        );
      } else {
        // Non-spendable, non-protected: ensure currency key exists but no total.
        byCurrency.putIfAbsent(
          account.currencyCode,
          () => (spendable: 0, protected_: 0),
        );
      }
    }

    return byCurrency.entries.map((e) {
      return CurrencyTotal(
        currency: Currency.fromCode(e.key),
        spendableMinorUnits: e.value.spendable,
        protectedMinorUnits: e.value.protected_,
      );
    }).toList();
  }
}
