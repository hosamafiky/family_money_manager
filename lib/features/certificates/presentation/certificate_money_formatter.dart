/// Certificate-screen money formatting.
///
/// Thin delegate to [MoneyInputFormatter] — identical policy to
/// [GoalMoneyFormatter] but scoped to certificate principal values.
library;

import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';

/// Formats an integer [minorUnits] amount into a human-readable decimal string.
///
/// Negative values → '—' (certificate principal must be ≥ 0).
/// Unknown currency falls back to EGP scale.
final class CertificateMoneyFormatter {
  const CertificateMoneyFormatter._();

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
