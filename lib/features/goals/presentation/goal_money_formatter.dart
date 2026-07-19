/// Centralized money-formatting utilities for goal screens.
///
/// All goal-related screens use [GoalMoneyFormatter.format] to convert integer
/// minor units into a human-readable decimal string that respects each
/// currency's minor-unit scale (e.g. 0 for JPY, 2 for EGP/USD, 3 for KWD).
///
/// This file is the single source of truth for minor-unit formatting within
/// the goals feature. Do NOT add inline `minorUnits ~/ 100` or
/// `.toStringAsFixed(2)` arithmetic in goal screens.
library;

import 'package:family_money_manager/core/financial/currency.dart';

/// Formats an integer [minorUnits] amount into a human-readable decimal string
/// using the scale declared by [currencyCode].
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
/// If [currencyCode] is unknown, scale defaults to 2.
final class GoalMoneyFormatter {
  const GoalMoneyFormatter._();

  /// Formats [minorUnits] for the given [currencyCode].
  static String format(int minorUnits, String currencyCode) {
    final int scale;
    try {
      scale = Currency.fromCode(currencyCode).minorUnitScale;
    } catch (_) {
      return _formatWithScale(minorUnits, 2);
    }
    return _formatWithScale(minorUnits, scale);
  }

  static String _formatWithScale(int minorUnits, int scale) {
    // Negative balances are a financial invariant violation in the goal
    // reserve context (balance must always be ≥ 0). Display '—' instead
    // of a raw negative number to prevent confusing users.
    if (minorUnits < 0) return '—';
    if (scale == 0) return '$minorUnits';
    final divisor = _pow10(scale);
    final whole = minorUnits ~/ divisor;
    final fraction = (minorUnits % divisor).toString().padLeft(scale, '0');
    return '$whole.$fraction';
  }

  static int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}
