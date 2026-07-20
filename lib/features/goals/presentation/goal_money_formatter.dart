/// Goal-screen money formatting — thin delegate to [NonNegativeMoneyFormatter].
///
/// All goal-related screens use [GoalMoneyFormatter.format] to convert integer
/// minor units into a human-readable decimal string. Formatting arithmetic is
/// owned exclusively by [MoneyInputFormatter] (shared with income / expense /
/// account screens). This class adds only the goal-reserve display policy for
/// negative balances (em-dash) — reserves must remain ≥ 0.
library;

import 'package:family_money_manager/core/presentation/non_negative_money_formatter.dart';

/// Formats an integer [minorUnits] amount into a human-readable decimal string
/// using the shared [NonNegativeMoneyFormatter] (integer-only arithmetic; no
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

  /// Formats [minorUnits] for the given [currencyCode].
  static String format(int minorUnits, String currencyCode) =>
      NonNegativeMoneyFormatter.format(minorUnits, currencyCode);
}
