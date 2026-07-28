/// The one place integer minor units become a displayable number string.
///
/// It produces the *number only* — no sign, no currency code, no direction
/// glyph. Those are composed by `FinancialAmountText`, which is the only
/// widget allowed to turn an amount into pixels. Splitting it this way is
/// deliberate: a formatter that emitted `'EGP -1275.00'` as one string is
/// exactly how the previous implementation ended up with a leading currency
/// code and an ASCII hyphen that reordered in RTL.
library;

import 'package:family_money_manager/core/financial/currency.dart';
import 'package:intl/intl.dart';

abstract final class AmountDisplayFormatter {
  const AmountDisplayFormatter._();

  /// Digits are Western (0–9) in both locales, with Western group and decimal
  /// separators.
  ///
  /// Egyptian banking, ATM slips, receipts and wallet SMS all print Western
  /// digits; Arabic-Indic reads as formal or archaic in a money context and
  /// mixes badly with the Latin currency codes and dates users see elsewhere.
  /// Arabic-Indic is a settings preference, not the default.
  static const String _numberLocale = 'en_US';

  /// Formats the magnitude of [minorUnits] for [currencyCode].
  ///
  /// Always unsigned — the sign is a layout position, not part of the string.
  /// Returns `1,275.00` for `127500` EGP, `10,000` for JPY (scale 0) and
  /// `10.000` for KWD (scale 3).
  ///
  /// Arithmetic stays integral throughout; no value is ever converted to
  /// `double`, so no amount can be perturbed by binary floating point.
  static String format(int minorUnits, String currencyCode) {
    final scale = _scaleOf(currencyCode);
    final magnitude = minorUnits.abs();
    final grouping = NumberFormat.decimalPattern(_numberLocale);

    if (scale == 0) return grouping.format(magnitude);

    final divisor = _pow10(scale);
    final whole = magnitude ~/ divisor;
    final fraction = (magnitude % divisor).toString().padLeft(scale, '0');
    final decimalSeparator =
        grouping.symbols.DECIMAL_SEP; // ignore: non_constant_identifier_names
    return '${grouping.format(whole)}$decimalSeparator$fraction';
  }

  /// The runs of digits in a formatted amount, in visual order.
  ///
  /// Privacy masking draws one ink bar per group, so it needs the groups
  /// rather than the assembled string. `1,275.00` yields `['1', '275', '00']`.
  static List<String> digitGroups(String formatted) {
    final groups = <String>[];
    final buffer = StringBuffer();
    for (final rune in formatted.runes) {
      final char = String.fromCharCode(rune);
      if (_isDigit(char)) {
        buffer.write(char);
      } else if (buffer.isNotEmpty) {
        groups.add(buffer.toString());
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) groups.add(buffer.toString());
    return groups;
  }

  /// Formats a gold-style quantity, which is not money and never a currency.
  ///
  /// Kept here so quantity rows share the grouping and digit conventions of
  /// money rows without being mistaken for them by the type system.
  static String formatQuantity(int milliUnits, {int fractionDigits = 3}) {
    final divisor = _pow10(fractionDigits);
    final magnitude = milliUnits.abs();
    final whole = magnitude ~/ divisor;
    final fraction = (magnitude % divisor).toString().padLeft(
      fractionDigits,
      '0',
    );
    final grouping = NumberFormat.decimalPattern(_numberLocale);
    return '${grouping.format(whole)}${grouping.symbols.DECIMAL_SEP}$fraction';
  }

  static bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  /// Unknown codes fall back to two decimal places rather than throwing: a
  /// display path must never be the thing that takes the screen down.
  static int _scaleOf(String currencyCode) {
    try {
      return Currency.fromCode(currencyCode).minorUnitScale;
    } catch (_) {
      return 2;
    }
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
