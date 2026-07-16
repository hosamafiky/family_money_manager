/// Money integer boundary and overflow tests (Phase 2A §10).
///
/// Verifies:
/// - Accepted integer range (Dart int64 native, SQLite INTEGER signed 64-bit)
/// - Overflow detection before persistence
/// - Allocation of positive and negative values
/// - Remainder distribution correctness
/// - Zero-part allocation rejection
/// - No double/REAL usage in monetary calculations
library;

import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Dart int on native targets is 64-bit signed.
  // SQLite INTEGER is also signed 64-bit.
  const int maxInt = 9223372036854775807;
  const int minInt = -9223372036854775808;

  // ── Valid range ───────────────────────────────────────────────────────────

  group('Money – valid integer range', () {
    test('zero is valid', () {
      expect(const Money.zero(Currency.egp).minorUnits, 0);
    });

    test('positive maximum int64 is accepted', () {
      const m = Money(minorUnits: maxInt, currency: Currency.egp);
      expect(m.minorUnits, maxInt);
    });

    test('negative maximum int64 is accepted (debt representation)', () {
      const m = Money(minorUnits: minInt, currency: Currency.egp);
      expect(m.minorUnits, minInt);
    });
  });

  // ── Overflow detection ────────────────────────────────────────────────────

  group('Money – overflow detection on arithmetic', () {
    test('adding two max-int values throws MoneyOverflowError', () {
      const a = Money(minorUnits: maxInt, currency: Currency.egp);
      const b = Money(minorUnits: 1, currency: Currency.egp);
      expect(() => a + b, throwsA(isA<MoneyOverflowError>()));
    });

    test('subtracting min-int and 1 throws MoneyOverflowError', () {
      const a = Money(minorUnits: minInt, currency: Currency.egp);
      const b = Money(minorUnits: 1, currency: Currency.egp);
      // min - 1 would overflow
      expect(() => a - b, throwsA(isA<MoneyOverflowError>()));
    });

    test('adding two large values near overflow throws MoneyOverflowError', () {
      const half = maxInt ~/ 2;
      const a = Money(minorUnits: half + 1, currency: Currency.egp);
      const b = Money(minorUnits: half + 1, currency: Currency.egp);
      expect(() => a + b, throwsA(isA<MoneyOverflowError>()));
    });

    test('adding two safe values does not overflow', () {
      const half = maxInt ~/ 2;
      const a = Money(minorUnits: half, currency: Currency.egp);
      const b = Money(minorUnits: 1, currency: Currency.egp);
      expect((a + b).minorUnits, half + 1);
    });
  });

  // ── No floating point ─────────────────────────────────────────────────────

  group('Money – no double arithmetic', () {
    test('minor units are always int (no fractional EGP)', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      expect(m.minorUnits, isA<int>());
    });

    test('allocate returns only int minor units with no rounding loss', () {
      // 100 EGP / 3 parts → [34, 33, 33] (remainder goes to first)
      const m = Money(minorUnits: 100, currency: Currency.egp);
      final parts = m.allocate(3);
      expect(parts.map((p) => p.minorUnits).toList(), [34, 33, 33]);
      // Sum must equal original.
      expect(parts.fold<int>(0, (s, p) => s + p.minorUnits), 100);
    });

    test('allocate for 0 remainder distributes evenly', () {
      const m = Money(minorUnits: 99, currency: Currency.egp);
      final parts = m.allocate(3);
      expect(parts.map((p) => p.minorUnits).toList(), [33, 33, 33]);
      expect(parts.fold<int>(0, (s, p) => s + p.minorUnits), 99);
    });

    test('allocateByRatios distributes proportionally with exact sum', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      final parts = m.allocateByRatios([1, 2, 1]); // 25/50/25
      expect(parts.fold<int>(0, (s, p) => s + p.minorUnits), 100);
    });
  });

  // ── Zero-part allocation ──────────────────────────────────────────────────

  group('Money – zero-part allocation rejection', () {
    test('allocate(0) throws ArgumentError', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      expect(() => m.allocate(0), throwsArgumentError);
    });

    test('allocate(-1) throws ArgumentError', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      expect(() => m.allocate(-1), throwsArgumentError);
    });

    test('allocateByRatios([]) throws ArgumentError', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      expect(() => m.allocateByRatios([]), throwsArgumentError);
    });
  });

  // ── fromJson / toJson range ───────────────────────────────────────────────

  group('Money – JSON serialization with boundary values', () {
    test('max int64 round-trips via JSON', () {
      const m = Money(minorUnits: maxInt, currency: Currency.egp);
      final json = m.toJson();
      final restored = Money.fromJson(json);
      expect(restored.minorUnits, maxInt);
    });

    test('min int64 round-trips via JSON', () {
      const m = Money(minorUnits: minInt, currency: Currency.egp);
      final json = m.toJson();
      final restored = Money.fromJson(json);
      expect(restored.minorUnits, minInt);
    });

    test('fromJson with invalid currency code throws ArgumentError', () {
      expect(
        () => Money.fromJson({'minorUnits': 100, 'currencyCode': 'XYZ_FAKE'}),
        throwsArgumentError,
      );
    });
  });

  // ── Negative allocation (liability values) ────────────────────────────────

  group('Money – negative value allocation', () {
    test('negative money allocates correctly with sign preserved', () {
      const m = Money(minorUnits: -100, currency: Currency.egp);
      final parts = m.allocate(3);
      // -100 / 3 = -33 each; remainder -1 goes to first
      expect(parts.fold<int>(0, (s, p) => s + p.minorUnits), -100);
    });
  });

  // ── Currency minor-unit scales ────────────────────────────────────────────

  group('Money – currency minor-unit scale accuracy', () {
    test('EGP has 2 decimal places (100 piastres)', () {
      expect(Currency.egp.minorUnitScale, 2);
    });

    test('JPY has 0 decimal places', () {
      expect(Currency.jpy.minorUnitScale, 0);
    });

    test('KWD has 3 decimal places (1000 fils)', () {
      expect(Currency.kwd.minorUnitScale, 3);
    });
  });
}
