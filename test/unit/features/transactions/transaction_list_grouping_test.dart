/// Grouping and totalling the transaction list.
///
/// The rule these exist to protect: a total never crosses a currency, and a
/// reversed pair never contributes to one. Both are easy to break by adding a
/// convenient `sum` somewhere, and neither is visible in a screenshot.
library;

import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:family_money_manager/features/transactions/presentation/transaction_list_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionSummary _tx({
  required String id,
  required OperationType type,
  required int amount,
  String date = '2026-07-25',
  String currency = 'EGP',
  bool isReversed = false,
}) => TransactionSummary(
  operation: Operation(
    id: id,
    householdId: 'household-v1',
    type: type,
    effectiveDate: date,
    recordedAt: DateTime.utc(2026, 7, 25),
    totalAmountMinorUnits: amount,
    currencyCode: currency,
    createdBy: 'member-1',
    createdAt: '2026-07-25T00:00:00Z',
    updatedAt: '2026-07-25T00:00:00Z',
    isReversed: isReversed,
  ),
  isRecurring: false,
);

void main() {
  group('grouping by date', () {
    test('one group per day, in the order the query returned them', () {
      final groups = groupByEffectiveDate([
        _tx(
          id: 'a',
          type: OperationType.expense,
          amount: 100,
          date: '2026-07-25',
        ),
        _tx(
          id: 'b',
          type: OperationType.expense,
          amount: 200,
          date: '2026-07-25',
        ),
        _tx(
          id: 'c',
          type: OperationType.expense,
          amount: 300,
          date: '2026-07-24',
        ),
      ]);

      expect(groups.map((g) => g.effectiveDate), ['2026-07-25', '2026-07-24']);
      expect(groups.first.transactions.map((t) => t.operation.id), ['a', 'b']);
      expect(groups.last.transactions.single.operation.id, 'c');
    });

    test(
      'a day that reappears later does not start a second group — the ledger '
      'orders by date, so this can only mean one day',
      () {
        final groups = groupByEffectiveDate([
          _tx(
            id: 'a',
            type: OperationType.expense,
            amount: 100,
            date: '2026-07-25',
          ),
          _tx(
            id: 'b',
            type: OperationType.expense,
            amount: 200,
            date: '2026-07-24',
          ),
          _tx(
            id: 'c',
            type: OperationType.expense,
            amount: 300,
            date: '2026-07-25',
          ),
        ]);

        expect(groups, hasLength(2));
        expect(groups.first.transactions, hasLength(2));
      },
    );

    test('an empty list has no groups', () {
      expect(groupByEffectiveDate(const []), isEmpty);
    });
  });

  group('totals never cross a currency', () {
    test('each currency gets its own block', () {
      final totals = totalsByCurrency([
        _tx(id: 'a', type: OperationType.income, amount: 1840000),
        _tx(id: 'b', type: OperationType.expense, amount: 38250),
        _tx(
          id: 'c',
          type: OperationType.income,
          amount: 32000,
          currency: 'USD',
        ),
      ]);

      expect(totals, hasLength(2));

      final egp = totals.firstWhere((t) => t.currencyCode == 'EGP');
      expect(egp.incomeMinorUnits, 1840000);
      expect(egp.expenseMinorUnits, 38250);

      final usd = totals.firstWhere((t) => t.currencyCode == 'USD');
      expect(usd.incomeMinorUnits, 32000);
      // The USD income is nowhere in the EGP block. A combined figure would
      // be true of nothing.
      expect(usd.expenseMinorUnits, 0);
    });

    test('the currency with the most transactions comes first', () {
      final totals = totalsByCurrency([
        _tx(id: 'a', type: OperationType.income, amount: 1, currency: 'USD'),
        _tx(id: 'b', type: OperationType.income, amount: 1),
        _tx(id: 'c', type: OperationType.income, amount: 1),
      ]);

      expect(totals.first.currencyCode, 'EGP');
      expect(totals.first.transactionCount, 2);
    });
  });

  group('transfers and reversals', () {
    test('a transfer is reported apart, never as income or expense', () {
      final totals = totalsByCurrency([
        _tx(id: 'a', type: OperationType.transfer, amount: 150000),
      ]).single;

      expect(totals.transferMinorUnits, 150000);
      expect(totals.incomeMinorUnits, 0);
      expect(totals.expenseMinorUnits, 0);
    });

    test('a reversed original contributes nothing', () {
      final totals = totalsByCurrency([
        _tx(
          id: 'a',
          type: OperationType.expense,
          amount: 127500,
          isReversed: true,
        ),
      ]);

      // Not merely zeroed — the currency has no block at all, because no
      // money moved in it.
      expect(totals, isEmpty);
    });

    test('the reversing entry contributes nothing either — counting both would '
        'double the error', () {
      final totals = totalsByCurrency([
        _tx(
          id: 'original',
          type: OperationType.expense,
          amount: 127500,
          isReversed: true,
        ),
        _tx(id: 'reversal', type: OperationType.reversal, amount: 127500),
        _tx(id: 'live', type: OperationType.expense, amount: 6800),
      ]).single;

      expect(totals.expenseMinorUnits, 6800);
      expect(totals.transactionCount, 1);
    });

    test('an adjustment is counted but not summed into either figure', () {
      final totals = totalsByCurrency([
        _tx(id: 'a', type: OperationType.adjustment, amount: 5000),
      ]).single;

      expect(totals.transactionCount, 1);
      expect(totals.incomeMinorUnits, 0);
      expect(totals.expenseMinorUnits, 0);
      expect(totals.transferMinorUnits, 0);
    });
  });
}
