/// Phase 5B.3 / 5B.4 – GoalMoneyFormatter widget tests.
///
/// Verifies that [GoalMoneyFormatter.format] uses purely integer arithmetic
/// and correctly handles currencies of every minor-unit scale (0, 2, 3).
///
/// FORMATTER POLICY (Phase 5B.4):
///  - Negative values → '—' (em-dash). Goal reserves are always ≥ 0; a
///    negative display would indicate a ledger bug, not a valid balance.
///  - No thousands separators (intentional; grouping is a presentation-layer
///    concern handled by the widget, not the formatter).
///  - No locale-specific digit substitution (always ASCII 0-9).
///  - No currency symbol (consumers append symbol from localisation).
///
/// Tests:
///  FMT-1.  JPY (scale=0): 10000 → '10000' (no decimal separator)
///  FMT-2.  EGP (scale=2): 0 → '0.00'
///  FMT-3.  EGP (scale=2): 10000 → '100.00'
///  FMT-4.  EGP (scale=2): 10050 → '100.50'
///  FMT-5.  KWD (scale=3): 10000 → '10.000'
///  FMT-6.  KWD (scale=3): 1001 → '1.001'
///  FMT-7.  Large value (EGP): 99999999 → '999999.99'
///  FMT-8.  Negative EGP: -5000 → '—' (policy: negative → em-dash)
///  FMT-9.  Unknown currency code → falls back to scale=2
///  FMT-10. USD (scale=2): 1 → '0.01'
///  FMT-11. JPY scale=0: 0 → '0'
///  FMT-12. EGP scale=2: 100 minor units → '1.00'
///  FMT-13. Arabic locale EGP: formatter returns ASCII digits (no Arabic numeral substitution)
///  FMT-14. JPY grouping: 1,000,000 JPY minor units → '1000000' (no grouping separator)
///  FMT-15. KWD 1500 minor → '1.500' (three decimal places)
///  FMT-16. Negative value → '—' (not '-100.00')
///  FMT-17. No currency symbol prepended or appended
///  FMT-18. Very large EGP value: 99999999900 → '999999999.00'
library;

import 'package:family_money_manager/features/goals/presentation/goal_money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalMoneyFormatter', () {
    test('FMT-1. JPY scale=0: 10000 → "10000"', () {
      expect(GoalMoneyFormatter.format(10000, 'JPY'), '10000');
    });

    test('FMT-2. EGP scale=2: 0 → "0.00"', () {
      expect(GoalMoneyFormatter.format(0, 'EGP'), '0.00');
    });

    test('FMT-3. EGP scale=2: 10000 → "100.00"', () {
      expect(GoalMoneyFormatter.format(10000, 'EGP'), '100.00');
    });

    test('FMT-4. EGP scale=2: 10050 → "100.50"', () {
      expect(GoalMoneyFormatter.format(10050, 'EGP'), '100.50');
    });

    test('FMT-5. KWD scale=3: 10000 → "10.000"', () {
      expect(GoalMoneyFormatter.format(10000, 'KWD'), '10.000');
    });

    test('FMT-6. KWD scale=3: 1001 → "1.001"', () {
      expect(GoalMoneyFormatter.format(1001, 'KWD'), '1.001');
    });

    test('FMT-7. Large EGP value: 99999999 → "999999.99"', () {
      expect(GoalMoneyFormatter.format(99999999, 'EGP'), '999999.99');
    });

    test('FMT-8. Negative EGP: -5000 → "—" (policy: negative = em-dash)', () {
      final result = GoalMoneyFormatter.format(-5000, 'EGP');
      expect(result, '—');
    });

    test('FMT-9. Unknown currency code falls back to scale=2', () {
      final result = GoalMoneyFormatter.format(1234, 'XYZ');
      expect(result, '12.34');
    });

    test('FMT-10. USD scale=2: 1 minor unit → "0.01"', () {
      expect(GoalMoneyFormatter.format(1, 'USD'), '0.01');
    });

    test('FMT-11. JPY scale=0: 0 → "0"', () {
      expect(GoalMoneyFormatter.format(0, 'JPY'), '0');
    });

    test('FMT-12. EGP scale=2: 100 minor units → "1.00"', () {
      expect(GoalMoneyFormatter.format(100, 'EGP'), '1.00');
    });

    // ── Phase 5B.4 additions (FMT-13..18) ───────────────────────────────────

    test(
      'FMT-13. Arabic locale EGP: formatter returns ASCII digits (no substitution)',
      () {
        // The formatter is locale-agnostic; it always returns ASCII '0'-'9'.
        // Arabic-digit substitution is a presentation-layer concern.
        final result = GoalMoneyFormatter.format(123456, 'EGP');
        expect(result, '1234.56');
        // Every character must be ASCII digit or decimal point.
        expect(
          result.codeUnits.every((c) => (c >= 48 && c <= 57) || c == 46),
          isTrue,
          reason: 'FMT-13: formatter must return only ASCII digits and "."',
        );
      },
    );

    test(
      'FMT-14. JPY grouping: 1,000,000 JPY minor units → "1000000" (no grouping separator)',
      () {
        // The formatter does NOT insert thousands separators (grouping is
        // a presentation-layer concern handled by the widget).
        final result = GoalMoneyFormatter.format(1000000, 'JPY');
        expect(result, '1000000');
        expect(result.contains(','), isFalse, reason: 'FMT-14: no commas');
      },
    );

    test('FMT-15. KWD 1500 minor → "1.500" (three decimal places)', () {
      expect(GoalMoneyFormatter.format(1500, 'KWD'), '1.500');
    });

    test('FMT-16. Negative value → "—" (not "-100.00")', () {
      expect(GoalMoneyFormatter.format(-10000, 'EGP'), '—');
      expect(GoalMoneyFormatter.format(-1, 'KWD'), '—');
      expect(GoalMoneyFormatter.format(-1, 'JPY'), '—');
    });

    test('FMT-17. No currency symbol prepended or appended', () {
      // The formatter returns only the numeric string; currency symbol is
      // the responsibility of the widget/locale layer.
      for (final code in ['EGP', 'USD', 'KWD', 'JPY']) {
        final result = GoalMoneyFormatter.format(10000, code);
        expect(
          result.contains(code),
          isFalse,
          reason: 'FMT-17: formatter must not include currency code "$code"',
        );
      }
    });

    test(
      'FMT-18. Very large EGP value: 99999999900 minor → "999999999.00"',
      () {
        // 999,999,999 EGP = 99,999,999,900 minor units (piastres).
        expect(GoalMoneyFormatter.format(99999999900, 'EGP'), '999999999.00');
      },
    );
  });
}
