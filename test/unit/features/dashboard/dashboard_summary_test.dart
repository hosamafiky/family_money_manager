/// Unit tests for DashboardSummary domain model (Phase 4A).
///
/// Tests:
/// 1. hasSpendableBalance returns false when all zeros
/// 2. hasSpendableBalance returns true when any non-zero
/// 3. hasProtectedBalance correct
/// 4. hasPeriodActivity correct
/// 5. CurrencyAmountSummary.isNegative correct
library;

import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/dashboard/domain/dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final period = DashboardPeriod.custom(
    startDate: '2025-03-01',
    endDate: '2025-04-01',
  );

  DashboardSummary buildSummary({
    List<CurrencyAmountSummary> spendable = const [],
    List<CurrencyAmountSummary> protected = const [],
    List<PeriodFlowSummary> flow = const [],
  }) {
    return DashboardSummary(
      availableToSpend: const [],
      excludedFromAvailable: const [],
      heldByReason: const [],
      householdId: 'hh-test',
      period: period,
      spendableBalances: spendable,
      protectedBalances: protected,
      periodFlow: flow,
      expensesByScope: const [],
      spouseWallets: const [],
      recentActivity: const [],
      generatedAt: DateTime(2025, 3, 15),
    );
  }

  group('DashboardSummary computed properties', () {
    test('1. hasSpendableBalance returns false when all zeros', () {
      final summary = buildSummary(
        spendable: [
          const CurrencyAmountSummary(currencyCode: 'EGP', totalMinorUnits: 0),
        ],
      );
      expect(summary.hasSpendableBalance, isFalse);
    });

    test('2. hasSpendableBalance returns true when any non-zero', () {
      final summary = buildSummary(
        spendable: [
          const CurrencyAmountSummary(
            currencyCode: 'EGP',
            totalMinorUnits: 5000,
          ),
        ],
      );
      expect(summary.hasSpendableBalance, isTrue);
    });

    test('3. hasProtectedBalance correct', () {
      final zeroSummary = buildSummary(
        protected: [
          const CurrencyAmountSummary(currencyCode: 'EGP', totalMinorUnits: 0),
        ],
      );
      final nonZeroSummary = buildSummary(
        protected: [
          const CurrencyAmountSummary(
            currencyCode: 'EGP',
            totalMinorUnits: 100,
          ),
        ],
      );
      expect(zeroSummary.hasProtectedBalance, isFalse);
      expect(nonZeroSummary.hasProtectedBalance, isTrue);
    });

    test('4. hasPeriodActivity correct', () {
      final noActivitySummary = buildSummary(
        flow: [
          const PeriodFlowSummary(
            currencyCode: 'EGP',
            grossIncomeMinorUnits: 0,
            grossExpenseMinorUnits: 0,
          ),
        ],
      );
      final withActivitySummary = buildSummary(
        flow: [
          const PeriodFlowSummary(
            currencyCode: 'EGP',
            grossIncomeMinorUnits: 1000,
            grossExpenseMinorUnits: 0,
          ),
        ],
      );
      expect(noActivitySummary.hasPeriodActivity, isFalse);
      expect(withActivitySummary.hasPeriodActivity, isTrue);
    });

    test('5. CurrencyAmountSummary.isNegative correct', () {
      const positive = CurrencyAmountSummary(
        currencyCode: 'EGP',
        totalMinorUnits: 1000,
      );
      const zero = CurrencyAmountSummary(
        currencyCode: 'EGP',
        totalMinorUnits: 0,
      );
      const negative = CurrencyAmountSummary(
        currencyCode: 'EGP',
        totalMinorUnits: -500,
      );
      expect(positive.isNegative, isFalse);
      expect(zero.isNegative, isFalse);
      expect(negative.isNegative, isTrue);
    });
  });

  group('ExpenseScopeSummary', () {
    test('values are immutable and accessible', () {
      const s = ExpenseScopeSummary(
        scope: ExpenseScope.personal,
        currencyCode: 'EGP',
        totalMinorUnits: 2000,
      );
      expect(s.scope, ExpenseScope.personal);
      expect(s.currencyCode, 'EGP');
      expect(s.totalMinorUnits, 2000);
    });
  });
}
