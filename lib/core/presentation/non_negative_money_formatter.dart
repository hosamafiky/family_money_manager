/// Integer-safe display formatting for balances that must remain ≥ 0.
///
/// Used by goal reserves and certificate principal displays. Never uses
/// `double` or `/100` scaling — delegates to [MoneyInputFormatter].
library;

import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';

abstract final class NonNegativeMoneyFormatter {
  const NonNegativeMoneyFormatter._();

  /// Formats [minorUnits] for [currencyCode].
  ///
  /// Negative values → em-dash (`—`) sentinel (invariant breach display).
  /// Unknown currency codes fall back to EGP scale.
  static String format(int minorUnits, String currencyCode) {
    if (minorUnits < 0) return '—';
    late Currency currency;
    try {
      currency = Currency.fromCode(currencyCode);
    } catch (_) {
      currency = Currency.egp;
    }
    return MoneyInputFormatter.format(
      Money(minorUnits: minorUnits, currency: currency),
    );
  }
}
