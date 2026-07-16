import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';

/// Result of parsing a user-entered money string.
sealed class MoneyParseResult {
  const MoneyParseResult();
}

final class MoneyParseOk extends MoneyParseResult {
  final Money value;
  const MoneyParseOk(this.value);
}

final class MoneyParseEmpty extends MoneyParseResult {
  const MoneyParseEmpty();
}

final class MoneyParseValidationError extends MoneyParseResult {
  final String messageKey;
  const MoneyParseValidationError(this.messageKey);
}

/// Parses user-entered amount strings into [Money] values.
///
/// Requirements:
/// - Never uses [double] internally; computes minor units via integer arithmetic.
/// - Accepts Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩) and Western digits.
/// - Normalises Arabic/Persian decimal separators (٫, ،) to '.'.
/// - Validates minor-unit precision against the currency's [scale].
/// - Detects integer overflow before construction.
/// - Returns typed [MoneyParseResult] rather than throwing.
abstract final class MoneyInputFormatter {
  MoneyInputFormatter._();

  /// Parses [input] as an amount in [currency].
  ///
  /// Returns [MoneyParseEmpty] for blank input.
  /// Returns [MoneyParseOk] on success.
  /// Returns [MoneyParseValidationError] for any invalid input.
  static MoneyParseResult parse(String input, Currency currency) {
    final normalised = _normalise(input.trim());
    if (normalised.isEmpty) return const MoneyParseEmpty();

    // Validate character set: digits and at most one decimal point.
    final validPattern = RegExp(r'^\d+(\.\d*)?$');
    if (!validPattern.hasMatch(normalised)) {
      return const MoneyParseValidationError('error_money_invalid_format');
    }

    final parts = normalised.split('.');
    final integerPart = parts[0];
    final fractionalPart = parts.length > 1 ? parts[1] : '';

    // Check scale precision.
    if (fractionalPart.length > currency.minorUnitScale) {
      return const MoneyParseValidationError('error_money_excess_decimals');
    }

    // Build minor units without double arithmetic.
    final scale = currency.minorUnitScale;
    final paddedFraction = fractionalPart.padRight(scale, '0');
    final integerStr = integerPart.isEmpty ? '0' : integerPart;
    final combined = '$integerStr$paddedFraction';

    int minorUnits;
    try {
      minorUnits = int.parse(combined);
    } on FormatException {
      return const MoneyParseValidationError('error_money_invalid_format');
    }

    // Check for overflow (int.parse on an extremely long string returns a
    // valid int in Dart but may wrap; guard with string length check).
    if (minorUnits < 0) {
      return const MoneyParseValidationError('error_money_overflow');
    }

    return MoneyParseOk(Money(minorUnits: minorUnits, currency: currency));
  }

  /// Formats [money] as a human-readable decimal string for display.
  ///
  /// Does NOT include currency symbol (caller adds that).
  /// Uses standard Western digits (locale-aware formatting belongs in the
  /// presentation layer with intl package).
  static String format(Money money) {
    final scale = money.currency.minorUnitScale;
    if (scale == 0) return money.minorUnits.abs().toString();
    final factor = _pow10(scale);
    final abs = money.minorUnits.abs();
    final integer = abs ~/ factor;
    final fraction = (abs % factor).toString().padLeft(scale, '0');
    final sign = money.minorUnits < 0 ? '-' : '';
    return '$sign$integer.$fraction';
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _normalise(String input) {
    // Map Arabic-Indic digits to Western digits.
    const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var s = input;
    for (var i = 0; i < arabicIndic.length; i++) {
      s = s.replaceAll(arabicIndic[i], '$i');
    }
    // Normalise Arabic/Persian decimal separators.
    s = s.replaceAll('٫', '.').replaceAll('،', '.');
    // Remove grouping separators (commas in Western format).
    s = s.replaceAll(',', '');
    return s;
  }

  static int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}
