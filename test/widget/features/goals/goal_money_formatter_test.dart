/// Phase 5B.3 – Section 9: GoalMoneyFormatter widget tests.
///
/// Verifies that [GoalMoneyFormatter.format] uses purely integer arithmetic
/// and correctly handles currencies of every minor-unit scale (0, 2, 3).
///
/// Tests:
///  FMT-1.  JPY (scale=0): 10000 → '10000' (no decimal separator)
///  FMT-2.  EGP (scale=2): 0 → '0.00'
///  FMT-3.  EGP (scale=2): 10000 → '100.00'
///  FMT-4.  EGP (scale=2): 10050 → '100.50'
///  FMT-5.  KWD (scale=3): 10000 → '10.000'
///  FMT-6.  KWD (scale=3): 1001 → '1.001'
///  FMT-7.  Large value (EGP): 99999999 → '999999.99'
///  FMT-8.  Negative EGP: -5000 → '-50.00' (fraction takes abs of remainder)
///  FMT-9.  Unknown currency code → falls back to scale=2
///  FMT-10. USD (scale=2): 1 → '0.01'
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

    test('FMT-8. Negative EGP: -5000 → "-50.00" (abs on fraction)', () {
      final result = GoalMoneyFormatter.format(-5000, 'EGP');
      expect(result, '-50.00');
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
  });
}
