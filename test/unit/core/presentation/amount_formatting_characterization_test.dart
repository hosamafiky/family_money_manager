/// How money becomes a string, and which formatter owns which job.
///
/// This began as the phase-0 before-picture: three formatters disagreeing on
/// the same amount, with the report one breaking four rules at once. That one
/// is gone. What remains pins the division of labour — display groups and
/// drops the sign, entry echoes what was typed, and the non-negative
/// formatter refuses a value it should never receive — so a future
/// "simplification" that collapses them has to argue with a test first.
library;

import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/presentation/amount_display_formatter.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/core/presentation/non_negative_money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmountDisplayFormatter — the one formatter reports now use', () {
    // `ReportAmountText.formatMinorUnits` used to sit behind every report,
    // budget and drill-down amount, and broke four rules at once: it led with
    // the currency code, used an ASCII hyphen inside the numeric run, emitted
    // no thousands grouping, and silently fell back to scale 2 for an unknown
    // code. It is deleted. These tests are the after-picture — each one
    // inverts an assertion that used to pin a defect.

    test('the currency code is not part of the string at all', () {
      // Placement is a layout decision, so it belongs to the widget, not to
      // the formatter. Trailing in both scripts, and never baked into the
      // number.
      expect(AmountDisplayFormatter.format(38250, 'EGP'), '382.50');
      expect(
        AmountDisplayFormatter.format(38250, 'EGP'),
        isNot(contains('EGP')),
      );
    });

    test('the sign is not part of the string either', () {
      // The old formatter emitted "EGP -382.50", which the bidi algorithm
      // rendered as "EGP 382.50-" in RTL. The magnitude is formatted here and
      // the sign is positioned by FinancialAmountText, inside an isolate.
      expect(AmountDisplayFormatter.format(-38250, 'EGP'), '382.50');
      expect(
        AmountDisplayFormatter.format(-38250, 'EGP'),
        isNot(contains('-')),
      );
    });

    test('thousands are grouped, so a column can be scanned', () {
      expect(AmountDisplayFormatter.format(999999999, 'EGP'), '9,999,999.99');
    });

    test('zero and sub-unit values', () {
      expect(AmountDisplayFormatter.format(0, 'EGP'), '0.00');
      expect(AmountDisplayFormatter.format(5, 'EGP'), '0.05');
      expect(AmountDisplayFormatter.format(-5, 'EGP'), '0.05');
    });

    test('per-currency minor-unit scale, including scale 0 and scale 3', () {
      expect(AmountDisplayFormatter.format(10000, 'JPY'), '10,000');
      expect(AmountDisplayFormatter.format(10000, 'KWD'), '10.000');
      expect(AmountDisplayFormatter.format(320000, 'USD'), '3,200.00');
    });

    test('a zero-scale currency takes the same path as every other', () {
      // The old formatter had a separate scale-0 branch that interpolated the
      // signed int directly, so JPY got its sign from Dart rather than from
      // the deliberate sign logic. There is one path now.
      expect(AmountDisplayFormatter.format(-10000, 'JPY'), '10,000');
    });
  });

  group('MoneyInputFormatter.format — entry and review screens', () {
    test('emits a bare decimal with no currency code', () {
      expect(
        MoneyInputFormatter.format(
          const Money(minorUnits: 127500, currency: Currency.egp),
        ),
        '1275.00',
      );
    });

    test('stays ungrouped, because a text field echoes what was typed', () {
      // MoneyInputFormatter is the *entry* formatter: it round-trips what a
      // user typed, so it stays ungrouped on purpose. Display grouping is
      // AmountDisplayFormatter's job, and the two are no longer confusable.
      expect(
        MoneyInputFormatter.format(
          const Money(minorUnits: 127500, currency: Currency.egp),
        ),
        isNot(contains(',')),
      );
    });

    test('negative values take an ASCII hyphen', () {
      expect(
        MoneyInputFormatter.format(
          const Money(minorUnits: -127500, currency: Currency.egp),
        ),
        '-1275.00',
      );
    });

    test('scale 0 and scale 3 currencies', () {
      expect(
        MoneyInputFormatter.format(
          const Money(minorUnits: 10000, currency: Currency.jpy),
        ),
        '10000',
      );
      expect(
        MoneyInputFormatter.format(
          const Money(minorUnits: 10000, currency: Currency.kwd),
        ),
        '10.000',
      );
    });
  });

  group('NonNegativeMoneyFormatter — goal and certificate displays', () {
    test('formats like MoneyInputFormatter for non-negative values', () {
      expect(NonNegativeMoneyFormatter.format(10050, 'EGP'), '100.50');
      expect(NonNegativeMoneyFormatter.format(0, 'EGP'), '0.00');
    });

    test('negative values become an em-dash sentinel', () {
      // A goal reserve or certificate principal below zero is an invariant
      // breach, and the display refuses to render a number for it. This
      // behaviour is correct and must survive phase 4.
      expect(NonNegativeMoneyFormatter.format(-1, 'EGP'), '—');
      expect(NonNegativeMoneyFormatter.format(-100000, 'EGP'), '—');
    });

    test('unknown currency falls back to the EGP scale', () {
      expect(NonNegativeMoneyFormatter.format(10050, 'XXX'), '100.50');
    });
  });

  group('the formatters that remain, and what each is for', () {
    test('display and entry differ only in grouping, and deliberately so', () {
      const minor = 127500;

      // What a reader sees.
      expect(AmountDisplayFormatter.format(minor, 'EGP'), '1,275.00');
      // What a typist round-trips. Grouping separators in a text field
      // fight the cursor, so entry stays ungrouped on purpose.
      expect(
        MoneyInputFormatter.format(
          const Money(minorUnits: minor, currency: Currency.egp),
        ),
        '1275.00',
      );
    });

    test('none of them bakes a currency code into the string any more', () {
      const minor = 127500;
      expect(AmountDisplayFormatter.format(minor, 'EGP'), isNot(contains('E')));
      expect(
        MoneyInputFormatter.format(
          const Money(minorUnits: minor, currency: Currency.egp),
        ),
        isNot(contains('E')),
      );
      expect(
        NonNegativeMoneyFormatter.format(minor, 'EGP'),
        isNot(contains('E')),
      );
    });

    test('on a negative, each does the one thing it exists to do', () {
      const minor = -127500;

      // Display drops the sign: FinancialAmountText positions it, inside an
      // isolate, from the direction rather than from the value.
      expect(AmountDisplayFormatter.format(minor, 'EGP'), '1,275.00');
      // Entry keeps it, because it is echoing input.
      expect(
        MoneyInputFormatter.format(
          const Money(minorUnits: minor, currency: Currency.egp),
        ),
        '-1275.00',
      );
      // And the non-negative formatter still refuses, which is its whole
      // point: a balance that cannot be negative renders an em dash rather
      // than a number nobody should trust.
      expect(NonNegativeMoneyFormatter.format(minor, 'EGP'), '—');
    });
  });
}
