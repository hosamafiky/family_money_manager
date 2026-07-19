import 'package:family_money_manager/core/financial/currency.dart';
import 'package:meta/meta.dart';

/// Immutable money value type.
///
/// INVARIANTS:
/// - [minorUnits] is always an integer. Never `double`.
/// - Arithmetic between different currencies throws [CurrencyMismatchError].
/// - Overflow is detected and throws [MoneyOverflowError].
/// - The value may be negative (e.g. representing a deficit or a signed leg).
///   For ledger entries, use always-positive [minorUnits] combined with an
///   explicit direction enum (see [LedgerDirection]) instead of signed money.
///
/// Display: Never format [Money] in the domain layer.
/// Use `core/financial/money_formatter.dart` in the presentation layer.
///
/// Production note: [toString] never reveals the numeric value.
@immutable
final class Money implements Comparable<Money> {
  /// The amount expressed as integer minor units.
  ///
  /// For EGP (scale 2): 150 minorUnits = 1.50 EGP.
  /// For JPY (scale 0): 150 minorUnits = 150 JPY.
  /// For KWD (scale 3): 1500 minorUnits = 1.500 KWD.
  final int minorUnits;

  /// The currency this value is expressed in.
  final Currency currency;

  const Money({required this.minorUnits, required this.currency});

  /// Creates a [Money] value of zero for the given [currency].
  const Money.zero(Currency currency) : this(minorUnits: 0, currency: currency);

  /// Creates a [Money] from raw [minorUnits] and an ISO 4217 currency [code].
  ///
  /// Throws [ArgumentError] if [code] is unsupported.
  factory Money.fromMinorUnits(int minorUnits, String currencyCode) {
    return Money(minorUnits: minorUnits, currency: Currency.fromCode(currencyCode));
  }

  // ── Predicates ──────────────────────────────────────────────────────────────

  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;
  bool get isNegative => minorUnits < 0;

  // ── Arithmetic ───────────────────────────────────────────────────────────────

  /// Returns a new [Money] that is the sum of `this` and [other].
  ///
  /// Throws [CurrencyMismatchError] if currencies differ.
  /// Throws [MoneyOverflowError] if the result overflows [int] range.
  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(minorUnits: _checkedAdd(minorUnits, other.minorUnits), currency: currency);
  }

  /// Returns a new [Money] that is `this` minus [other].
  ///
  /// Throws [CurrencyMismatchError] if currencies differ.
  /// Throws [MoneyOverflowError] if the result overflows [int] range.
  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(minorUnits: _checkedSubtract(minorUnits, other.minorUnits), currency: currency);
  }

  /// Returns the arithmetic negation of this value.
  ///
  /// Throws [MoneyOverflowError] for the edge case of negating [int.minValue]
  /// (2's complement overflow).
  Money operator -() {
    if (minorUnits == _minInt64) {
      throw MoneyOverflowError('Cannot negate minimum int value; result would overflow');
    }
    return Money(minorUnits: -minorUnits, currency: currency);
  }

  /// Returns the absolute value of this money.
  Money abs() => isNegative ? Money(minorUnits: -minorUnits, currency: currency) : this;

  // ── Comparison ───────────────────────────────────────────────────────────────

  @override
  int compareTo(Money other) {
    _requireSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  // ── Allocation ───────────────────────────────────────────────────────────────

  /// Splits this value into [parts] equal shares, returning a list where the
  /// first element absorbs the remainder.
  ///
  /// Uses truncate-toward-zero division (`~/` and `remainder()`). The
  /// remainder is added to the first element so that the sum of all parts
  /// always equals [minorUnits], including for negative values.
  ///
  /// Example: 100 EGP split into 3 → [34, 33, 33].
  /// Example: -100 EGP split into 3 → [-34, -33, -33].
  ///
  /// Throws [ArgumentError] if [parts] < 1.
  List<Money> allocate(int parts) {
    if (parts < 1) {
      throw ArgumentError.value(parts, 'parts', 'Must be at least 1');
    }
    // Use truncating division so that the remainder carries the same sign as
    // the dividend (e.g. -100 / 3 → base -33, remainder -1).
    // Dart's `%` is Euclidean (always ≥ 0 when divisor > 0), so we must use
    // `remainder()` which truncates toward zero.
    final base = minorUnits ~/ parts;
    final rem = minorUnits.remainder(parts);
    return List.generate(parts, (i) {
      final extra = i == 0 ? rem : 0;
      return Money(minorUnits: base + extra, currency: currency);
    });
  }

  /// Splits this value according to the given [ratios] (integers).
  ///
  /// The remainder after integer division is distributed one unit at a time
  /// to the first elements. The total of all returned values equals
  /// [minorUnits].
  ///
  /// Throws [ArgumentError] if [ratios] is empty or any ratio is negative.
  List<Money> allocateByRatios(List<int> ratios) {
    if (ratios.isEmpty) throw ArgumentError('ratios must not be empty');
    for (final r in ratios) {
      if (r < 0) throw ArgumentError('All ratios must be non-negative; got $r');
    }
    final totalRatio = ratios.fold(0, (a, b) => a + b);
    if (totalRatio == 0) throw ArgumentError('Sum of ratios must be > 0');

    // Use BigInt to avoid overflow in intermediate multiplication.
    final bigTotal = BigInt.from(minorUnits);
    final bigRatioTotal = BigInt.from(totalRatio);
    final allocated = ratios.map((r) {
      final share = (bigTotal * BigInt.from(r)) ~/ bigRatioTotal;
      return share.toInt();
    }).toList();

    final allocatedSum = allocated.fold(0, (a, b) => a + b);
    final rem = minorUnits - allocatedSum;
    allocated[0] += rem;

    return allocated.map((u) => Money(minorUnits: u, currency: currency)).toList();
  }

  // ── Serialisation ────────────────────────────────────────────────────────────

  /// Serialises to a plain map suitable for storage or transport.
  /// The currency code is the stable ISO 4217 string.
  Map<String, dynamic> toJson() => {'minorUnits': minorUnits, 'currencyCode': currency.code};

  /// Deserialises from a [toJson] map.
  /// Throws [ArgumentError] if the currency code is unsupported.
  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(minorUnits: (json['minorUnits'] as num).toInt(), currency: Currency.fromCode(json['currencyCode'] as String));
  }

  // ── Equality & hashing ───────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) => identical(this, other) || other is Money && other.minorUnits == minorUnits && other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  /// Production-safe string: never reveals the numeric value.
  @override
  String toString() => '[REDACTED_AMOUNT ${currency.code}]';

  /// Debug-only representation — do NOT log this in production.
  String toDebugString() => '${currency.code} $minorUnits';

  // ── Private helpers ───────────────────────────────────────────────────────────

  void _requireSameCurrency(Money other) {
    if (currency != other.currency) {
      throw CurrencyMismatchError(
        'Cannot perform arithmetic between ${currency.code} and ${other.currency.code}. '
        'Cross-currency operations are prohibited in V1.',
      );
    }
  }

  static int _checkedAdd(int a, int b) {
    final result = a + b;
    // Overflow detection: if both operands have the same sign and the result
    // has the opposite sign, an overflow occurred.
    if (((a ^ result) & (b ^ result)) < 0) {
      throw MoneyOverflowError('Integer overflow adding $a + $b');
    }
    return result;
  }

  static int _checkedSubtract(int a, int b) {
    final result = a - b;
    // Overflow if signs of a and b differ and result sign differs from a.
    if (((a ^ b) & (a ^ result)) < 0) {
      throw MoneyOverflowError('Integer overflow subtracting $a - $b');
    }
    return result;
  }

  // Dart `int` on 64-bit platforms. On JS (web) int is 53-bit; but this app
  // targets iOS and Android only, so 64-bit is guaranteed.
  // The minimum 64-bit signed integer: −2^63.
  static const int _minInt64 = -9223372036854775808;
}

// ── Error types ────────────────────────────────────────────────────────────────

/// Thrown when arithmetic is attempted between two [Money] values with
/// different currencies.
///
/// Cross-currency arithmetic is prohibited in V1.
final class CurrencyMismatchError extends Error {
  CurrencyMismatchError(this.message);
  final String message;
  @override
  String toString() => 'CurrencyMismatchError: $message';
}

/// Thrown when a [Money] arithmetic operation would produce a result outside
/// the representable [int] range.
final class MoneyOverflowError extends Error {
  MoneyOverflowError(this.message);
  final String message;
  @override
  String toString() => 'MoneyOverflowError: $message';
}
