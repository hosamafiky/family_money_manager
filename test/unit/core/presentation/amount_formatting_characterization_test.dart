/// Characterization tests for money rendering, pinned at phase 0.
///
/// Three formatters produce user-visible amounts today, and they disagree with
/// each other and with the redesign. This file records exactly what each one
/// emits *before* phase 4 consolidates them into a single
/// `FinancialAmountText`, so that consolidation is a reviewable diff rather
/// than a rewrite nobody can check.
///
/// Several expectations below assert output the design explicitly rejects.
/// They are labelled DEFECT and each names the rule it breaks. Do not "fix"
/// them here — they are the before-picture, and phase 4 is where they change.
library;

import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/core/presentation/non_negative_money_formatter.dart';
import 'package:family_money_manager/features/reports/presentation/report_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportAmountText.formatMinorUnits — every report amount', () {
    // This is the single formatter behind all report, budget and drill-down
    // amounts, and it breaks four rules at once.

    test('DEFECT: currency code leads the number', () {
      // The design requires the code to *trail* the amount in both scripts.
      expect(ReportAmountText.formatMinorUnits(38250, 'EGP'), 'EGP 382.50');
    });

    test('DEFECT: ASCII hyphen, and it lands inside the run', () {
      // In RTL this renders as "EGP 382.50-": the bidi algorithm moves an
      // unisolated ASCII hyphen to the wrong side of the numeric run. The fix
      // is a first-strong isolate plus a real minus glyph, in phase 4.
      expect(ReportAmountText.formatMinorUnits(-38250, 'EGP'), 'EGP -382.50');
    });

    test('DEFECT: no thousands grouping', () {
      // A ledger is a column of numbers; ungrouped digits cannot be scanned.
      expect(
        ReportAmountText.formatMinorUnits(999999999, 'EGP'),
        'EGP 9999999.99',
      );
    });

    test('zero and sub-unit values', () {
      expect(ReportAmountText.formatMinorUnits(0, 'EGP'), 'EGP 0.00');
      expect(ReportAmountText.formatMinorUnits(5, 'EGP'), 'EGP 0.05');
      expect(ReportAmountText.formatMinorUnits(-5, 'EGP'), 'EGP -0.05');
    });

    test('respects per-currency minor-unit scale', () {
      expect(ReportAmountText.formatMinorUnits(10000, 'JPY'), 'JPY 10000');
      expect(ReportAmountText.formatMinorUnits(10000, 'KWD'), 'KWD 10.000');
      expect(ReportAmountText.formatMinorUnits(320000, 'USD'), 'USD 3200.00');
    });

    test('DEFECT: a zero-scale currency loses its sign handling path', () {
      // The scale-0 branch interpolates minorUnits directly, so the sign comes
      // from Dart's int formatting rather than the deliberate sign logic used
      // for every other currency. Same visible result today, different code
      // path — and phase 4 unifies them.
      expect(ReportAmountText.formatMinorUnits(-10000, 'JPY'), 'JPY -10000');
    });

    test('unknown currency codes silently fall back to scale 2', () {
      // No throw, no marker. A typo'd code renders as a plausible amount.
      expect(ReportAmountText.formatMinorUnits(38250, 'XXX'), 'XXX 382.50');
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

    test('DEFECT: also ungrouped, and disagrees with nothing else', () {
      // Same number, three formatters, three strings: '1275.00' here,
      // 'EGP 1275.00' from ReportAmountText. Phase 4 leaves one.
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

  group('the three formatters disagree — the reason phase 4 exists', () {
    test('one amount, three different strings', () {
      const minor = 127500;
      final report = ReportAmountText.formatMinorUnits(minor, 'EGP');
      final entry = MoneyInputFormatter.format(
        const Money(minorUnits: minor, currency: Currency.egp),
      );
      final nonNegative = NonNegativeMoneyFormatter.format(minor, 'EGP');

      expect(report, 'EGP 1275.00');
      expect(entry, '1275.00');
      expect(nonNegative, '1275.00');
      expect(report, isNot(entry));
    });

    test('and they disagree on negatives more sharply still', () {
      const minor = -127500;
      expect(ReportAmountText.formatMinorUnits(minor, 'EGP'), 'EGP -1275.00');
      expect(
        MoneyInputFormatter.format(
          const Money(minorUnits: minor, currency: Currency.egp),
        ),
        '-1275.00',
      );
      // The third refuses to render it at all.
      expect(NonNegativeMoneyFormatter.format(minor, 'EGP'), '—');
    });
  });
}
