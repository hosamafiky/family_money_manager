import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyInputFormatter.parse', () {
    group('empty input', () {
      test('empty string returns MoneyParseEmpty', () {
        final result = MoneyInputFormatter.parse('', Currency.egp);
        expect(result, isA<MoneyParseEmpty>());
      });

      test('whitespace-only returns MoneyParseEmpty', () {
        final result = MoneyInputFormatter.parse('   ', Currency.egp);
        expect(result, isA<MoneyParseEmpty>());
      });
    });

    group('EGP (scale 2)', () {
      test('parses 12.50 → 1250', () {
        final result = MoneyInputFormatter.parse('12.50', Currency.egp);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 1250);
      });

      test('parses 0 → 0', () {
        final result = MoneyInputFormatter.parse('0', Currency.egp);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 0);
      });

      test('parses 0.00 → 0', () {
        final result = MoneyInputFormatter.parse('0.00', Currency.egp);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 0);
      });

      test('parses 100 → 10000', () {
        final result = MoneyInputFormatter.parse('100', Currency.egp);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 10000);
      });

      test('excess decimals 1.234 → error', () {
        final result = MoneyInputFormatter.parse('1.234', Currency.egp);
        expect(result, isA<MoneyParseValidationError>());
        expect(
          (result as MoneyParseValidationError).messageKey,
          'error_money_excess_decimals',
        );
      });

      test('single decimal digit 5.5 → 550', () {
        final result = MoneyInputFormatter.parse('5.5', Currency.egp);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 550);
      });
    });

    group('JPY (scale 0)', () {
      test('parses 1000 → 1000', () {
        final result = MoneyInputFormatter.parse('1000', Currency.jpy);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 1000);
      });

      test('any decimal → excess decimals error', () {
        final result = MoneyInputFormatter.parse('1000.5', Currency.jpy);
        expect(result, isA<MoneyParseValidationError>());
        expect(
          (result as MoneyParseValidationError).messageKey,
          'error_money_excess_decimals',
        );
      });

      test('0 → 0', () {
        final result = MoneyInputFormatter.parse('0', Currency.jpy);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 0);
      });
    });

    group('KWD (scale 3)', () {
      test('parses 1.500 → 1500', () {
        final result = MoneyInputFormatter.parse('1.500', Currency.kwd);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 1500);
      });

      test('parses 1.5 → 1500', () {
        final result = MoneyInputFormatter.parse('1.5', Currency.kwd);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 1500);
      });

      test('4 decimal places → excess error', () {
        final result = MoneyInputFormatter.parse('1.5001', Currency.kwd);
        expect(result, isA<MoneyParseValidationError>());
      });
    });

    group('Arabic-Indic digits', () {
      test('٠١٢٣ parses as 0123', () {
        final result = MoneyInputFormatter.parse('١٢٫٥٠', Currency.egp);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 1250);
      });

      test('pure Arabic-Indic whole number parses correctly', () {
        final result = MoneyInputFormatter.parse('١٠٠', Currency.egp);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 10000);
      });

      test('Arabic comma separator ، treated as decimal', () {
        final result = MoneyInputFormatter.parse('١٢،٥٠', Currency.egp);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.minorUnits, 1250);
      });
    });

    group('invalid input', () {
      test('letters abc → error', () {
        final result = MoneyInputFormatter.parse('abc', Currency.egp);
        expect(result, isA<MoneyParseValidationError>());
      });

      test('negative sign → error', () {
        final result = MoneyInputFormatter.parse('-5', Currency.egp);
        expect(result, isA<MoneyParseValidationError>());
      });

      test('multiple dots → error', () {
        final result = MoneyInputFormatter.parse('1.2.3', Currency.egp);
        expect(result, isA<MoneyParseValidationError>());
      });
    });

    group('currency attached to result', () {
      test('result currency matches input currency', () {
        final result = MoneyInputFormatter.parse('10.00', Currency.usd);
        expect(result, isA<MoneyParseOk>());
        expect((result as MoneyParseOk).value.currency, Currency.usd);
      });
    });
  });

  group('MoneyInputFormatter.format', () {
    test('EGP 1250 → 12.50', () {
      final formatted = MoneyInputFormatter.format(
        const Money(minorUnits: 1250, currency: Currency.egp),
      );
      expect(formatted, '12.50');
    });

    test('JPY 1000 → 1000', () {
      final formatted = MoneyInputFormatter.format(
        const Money(minorUnits: 1000, currency: Currency.jpy),
      );
      expect(formatted, '1000');
    });

    test('KWD 1500 → 1.500', () {
      final formatted = MoneyInputFormatter.format(
        const Money(minorUnits: 1500, currency: Currency.kwd),
      );
      expect(formatted, '1.500');
    });

    test('zero EGP → 0.00', () {
      final formatted = MoneyInputFormatter.format(
        const Money(minorUnits: 0, currency: Currency.egp),
      );
      expect(formatted, '0.00');
    });

    test('negative EGP -500 → -5.00', () {
      final formatted = MoneyInputFormatter.format(
        const Money(minorUnits: -500, currency: Currency.egp),
      );
      expect(formatted, '-5.00');
    });
  });
}
