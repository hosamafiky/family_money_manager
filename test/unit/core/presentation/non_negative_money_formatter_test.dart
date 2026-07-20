import 'package:family_money_manager/core/presentation/non_negative_money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats EGP minor units without floating point', () {
    expect(NonNegativeMoneyFormatter.format(0, 'EGP'), '0.00');
    expect(NonNegativeMoneyFormatter.format(10050, 'EGP'), '100.50');
  });

  test('negative → em-dash', () {
    expect(NonNegativeMoneyFormatter.format(-1, 'EGP'), '—');
  });

  test('unknown currency falls back to EGP scale', () {
    expect(NonNegativeMoneyFormatter.format(100, 'ZZZ'), '1.00');
  });
}
