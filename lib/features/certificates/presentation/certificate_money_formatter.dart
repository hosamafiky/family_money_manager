/// Certificate-screen money formatting.
///
/// Thin delegate to [NonNegativeMoneyFormatter] — identical non-negative
/// display policy to [GoalMoneyFormatter], scoped to certificate screens.
library;

import 'package:family_money_manager/core/presentation/non_negative_money_formatter.dart';

/// Formats an integer [minorUnits] amount into a human-readable decimal string.
///
/// Negative values → '—' (certificate principal must be ≥ 0).
/// Unknown currency falls back to EGP scale.
final class CertificateMoneyFormatter {
  const CertificateMoneyFormatter._();

  static String format(int minorUnits, String currencyCode) =>
      NonNegativeMoneyFormatter.format(minorUnits, currencyCode);
}
