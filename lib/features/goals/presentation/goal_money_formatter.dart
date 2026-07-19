/// Goal-screen money formatting — thin delegate to [MoneyInputFormatter].
///
/// All goal-related screens use [GoalMoneyFormatter.format] to convert integer
/// minor units into a human-readable decimal string. Formatting arithmetic is
/// owned exclusively by [MoneyInputFormatter] (shared with income / expense /
/// account screens). This class adds only the goal-reserve display policy for
/// negative balances (em-dash) — reserves must remain ≥ 0.
library;

import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';

/// Formats an integer [minorUnits] amount into a human-readable decimal string
/// using the shared [MoneyInputFormatter] (integer-only arithmetic; no
/// `.toDouble()`, no `/ 100.0`).
///
/// Examples (EGP, scale=2):
///   format(0, 'EGP')      → '0.00'
///   format(10000, 'EGP')  → '100.00'
///   format(10050, 'EGP')  → '100.50'
///
/// Examples (JPY, scale=0):
///   format(10000, 'JPY')  → '10000'
///
/// Examples (KWD, scale=3):
///   format(10000, 'KWD')  → '10.000'
///
/// Negative values → '—' (goal-reserve display policy).
/// If [currencyCode] is unknown, scale defaults to EGP (2).
final class GoalMoneyFormatter {
  const GoalMoneyFormatter._();

  /// Formats [minorUnits] for the given [currencyCode] via [MoneyInputFormatter].
  static String format(int minorUnits, String currencyCode) {
    // Goal reserves are an invariant ≥ 0. Surface a sentinel rather than a
    // signed amount if a ledger bug produces a negative derived balance.
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
