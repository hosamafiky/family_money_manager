import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency', () {
    test('fromCode resolves known codes case-insensitively', () {
      expect(Currency.fromCode('EGP'), Currency.egp);
      expect(Currency.fromCode('egp'), Currency.egp);
      expect(Currency.fromCode('USD'), Currency.usd);
      expect(Currency.fromCode(' KWD '), Currency.kwd);
    });

    test('fromCode throws ArgumentError for unknown code', () {
      expect(() => Currency.fromCode('XXX'), throwsArgumentError);
      expect(() => Currency.fromCode(''), throwsArgumentError);
      expect(() => Currency.fromCode('EGYPT'), throwsArgumentError);
    });

    test('isSupported returns true only for known codes', () {
      expect(Currency.isSupported('EGP'), isTrue);
      expect(Currency.isSupported('JPY'), isTrue);
      expect(Currency.isSupported('ZZZ'), isFalse);
    });

    test('minorUnitScale is correct per currency', () {
      expect(Currency.egp.minorUnitScale, 2);
      expect(Currency.usd.minorUnitScale, 2);
      expect(Currency.jpy.minorUnitScale, 0);
      expect(Currency.kwd.minorUnitScale, 3);
    });
  });

  group('Money – construction', () {
    test('creates with positive minorUnits', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      expect(m.minorUnits, 100);
      expect(m.currency, Currency.egp);
    });

    test('zero factory returns 0 minor units', () {
      const z = Money.zero(Currency.egp);
      expect(z.isZero, isTrue);
      expect(z.minorUnits, 0);
    });

    test('negative minorUnits is valid', () {
      const m = Money(minorUnits: -50, currency: Currency.egp);
      expect(m.isNegative, isTrue);
      expect(m.isPositive, isFalse);
    });

    test('fromMinorUnits resolves currency code', () {
      final m = Money.fromMinorUnits(500, 'EGP');
      expect(m.currency, Currency.egp);
    });

    test('fromMinorUnits throws for unsupported currency', () {
      expect(() => Money.fromMinorUnits(100, 'ZZZ'), throwsArgumentError);
    });
  });

  group('Money – predicates', () {
    test('isZero', () {
      expect(const Money(minorUnits: 0, currency: Currency.egp).isZero, isTrue);
      expect(
        const Money(minorUnits: 1, currency: Currency.egp).isZero,
        isFalse,
      );
    });

    test('isPositive', () {
      expect(
        const Money(minorUnits: 1, currency: Currency.egp).isPositive,
        isTrue,
      );
      expect(
        const Money(minorUnits: 0, currency: Currency.egp).isPositive,
        isFalse,
      );
      expect(
        const Money(minorUnits: -1, currency: Currency.egp).isPositive,
        isFalse,
      );
    });

    test('isNegative', () {
      expect(
        const Money(minorUnits: -1, currency: Currency.egp).isNegative,
        isTrue,
      );
      expect(
        const Money(minorUnits: 0, currency: Currency.egp).isNegative,
        isFalse,
      );
      expect(
        const Money(minorUnits: 1, currency: Currency.egp).isNegative,
        isFalse,
      );
    });
  });

  group('Money – equality', () {
    test('equal when same amount and currency', () {
      const a = Money(minorUnits: 100, currency: Currency.egp);
      const b = Money(minorUnits: 100, currency: Currency.egp);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when different amount', () {
      const a = Money(minorUnits: 100, currency: Currency.egp);
      const b = Money(minorUnits: 200, currency: Currency.egp);
      expect(a, isNot(equals(b)));
    });

    test('not equal when different currency', () {
      const a = Money(minorUnits: 100, currency: Currency.egp);
      const b = Money(minorUnits: 100, currency: Currency.usd);
      expect(a, isNot(equals(b)));
    });
  });

  group('Money – arithmetic (same currency)', () {
    const a = Money(minorUnits: 300, currency: Currency.egp);
    const b = Money(minorUnits: 100, currency: Currency.egp);

    test('addition', () => expect((a + b).minorUnits, 400));
    test('subtraction', () => expect((a - b).minorUnits, 200));
    test('negation', () => expect((-a).minorUnits, -300));
    test('abs of negative', () {
      const neg = Money(minorUnits: -300, currency: Currency.egp);
      expect(neg.abs().minorUnits, 300);
    });
    test('abs of positive returns same', () => expect(a.abs(), equals(a)));
  });

  group('Money – currency mismatch throws CurrencyMismatchError', () {
    const egp = Money(minorUnits: 100, currency: Currency.egp);
    const usd = Money(minorUnits: 100, currency: Currency.usd);

    test(
      'addition',
      () => expect(() => egp + usd, throwsA(isA<CurrencyMismatchError>())),
    );
    test(
      'subtraction',
      () => expect(() => egp - usd, throwsA(isA<CurrencyMismatchError>())),
    );
    test(
      'compareTo',
      () => expect(
        () => egp.compareTo(usd),
        throwsA(isA<CurrencyMismatchError>()),
      ),
    );
  });

  group('Money – overflow detection', () {
    test('addition overflow throws MoneyOverflowError', () {
      const maxMoney = Money(
        minorUnits: 9223372036854775807,
        currency: Currency.egp,
      ); // int.maxFinite-ish
      const one = Money(minorUnits: 1, currency: Currency.egp);
      expect(() => maxMoney + one, throwsA(isA<MoneyOverflowError>()));
    });

    test('subtraction overflow throws MoneyOverflowError', () {
      const minMoney = Money(
        minorUnits: -9223372036854775808,
        currency: Currency.egp,
      );
      const one = Money(minorUnits: 1, currency: Currency.egp);
      expect(() => minMoney - one, throwsA(isA<MoneyOverflowError>()));
    });

    test('negation of minInt throws MoneyOverflowError', () {
      const minMoney = Money(
        minorUnits: -9223372036854775808,
        currency: Currency.egp,
      );
      expect(() => -minMoney, throwsA(isA<MoneyOverflowError>()));
    });

    test('normal values do not overflow', () {
      const a = Money(minorUnits: 1000000000, currency: Currency.egp);
      const b = Money(minorUnits: 2000000000, currency: Currency.egp);
      expect((a + b).minorUnits, 3000000000);
    });
  });

  group('Money – comparison', () {
    const small = Money(minorUnits: 50, currency: Currency.egp);
    const large = Money(minorUnits: 200, currency: Currency.egp);

    test('compareTo ordering', () {
      expect(small.compareTo(large), isNegative);
      expect(large.compareTo(small), isPositive);
      expect(small.compareTo(small), 0);
    });
    test('< operator', () => expect(small < large, isTrue));
    test('<= operator equal', () => expect(small <= small, isTrue));
    test('> operator', () => expect(large > small, isTrue));
    test('>= operator equal', () => expect(large >= large, isTrue));
  });

  group('Money – allocation', () {
    test('allocate splits evenly', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      final parts = m.allocate(4);
      expect(parts.length, 4);
      expect(parts.map((p) => p.minorUnits).toList(), [25, 25, 25, 25]);
    });

    test('allocate distributes remainder to first part', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      final parts = m.allocate(3);
      expect(parts[0].minorUnits, 34);
      expect(parts[1].minorUnits, 33);
      expect(parts[2].minorUnits, 33);
      final total = parts.fold(0, (acc, p) => acc + p.minorUnits);
      expect(total, 100);
    });

    test('allocate with 1 part returns the original amount', () {
      const m = Money(minorUnits: 999, currency: Currency.egp);
      final parts = m.allocate(1);
      expect(parts[0].minorUnits, 999);
    });

    test('allocate throws for zero or negative parts', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      expect(() => m.allocate(0), throwsArgumentError);
      expect(() => m.allocate(-1), throwsArgumentError);
    });

    test('allocateByRatios distributes proportionally with correct total', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      final parts = m.allocateByRatios([1, 2, 2]);
      final total = parts.fold(0, (acc, p) => acc + p.minorUnits);
      expect(total, 100);
      expect(parts.length, 3);
    });

    test('allocateByRatios throws for empty list', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      expect(() => m.allocateByRatios([]), throwsArgumentError);
    });

    test('allocateByRatios throws for negative ratio', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      expect(() => m.allocateByRatios([1, -1]), throwsArgumentError);
    });

    test('allocateByRatios throws when all ratios are zero', () {
      const m = Money(minorUnits: 100, currency: Currency.egp);
      expect(() => m.allocateByRatios([0, 0]), throwsArgumentError);
    });
  });

  group('Money – serialisation', () {
    test('toJson / fromJson round-trip', () {
      const m = Money(minorUnits: 12345, currency: Currency.egp);
      final json = m.toJson();
      final restored = Money.fromJson(json);
      expect(restored, equals(m));
    });

    test('fromJson with different currency', () {
      const usd = Money(minorUnits: 500, currency: Currency.usd);
      final restored = Money.fromJson(usd.toJson());
      expect(restored.currency, Currency.usd);
      expect(restored.minorUnits, 500);
    });

    test('fromJson throws for unsupported currency', () {
      expect(
        () => Money.fromJson({'minorUnits': 100, 'currencyCode': 'XXX'}),
        throwsArgumentError,
      );
    });
  });

  group('Money – toString redacts amount', () {
    test('toString never reveals minorUnits', () {
      const m = Money(minorUnits: 999999, currency: Currency.egp);
      expect(m.toString(), isNot(contains('999999')));
      expect(m.toString(), contains('[REDACTED_AMOUNT'));
    });

    test('toDebugString reveals value (never call in production)', () {
      const m = Money(minorUnits: 42, currency: Currency.egp);
      expect(m.toDebugString(), contains('42'));
    });
  });

  group('Money – currencies with different minor-unit scales', () {
    test('JPY has scale 0 (no fractional units)', () {
      expect(Currency.jpy.minorUnitScale, 0);
      const jpy = Money(minorUnits: 1000, currency: Currency.jpy);
      const jpy2 = Money(minorUnits: 500, currency: Currency.jpy);
      expect((jpy - jpy2).minorUnits, 500);
    });

    test('KWD has scale 3 (fils)', () {
      expect(Currency.kwd.minorUnitScale, 3);
      const kwd = Money(minorUnits: 5500, currency: Currency.kwd);
      expect(kwd.isPositive, isTrue);
    });

    test('EGP has scale 2 (piasters)', () {
      expect(Currency.egp.minorUnitScale, 2);
    });
  });
}
