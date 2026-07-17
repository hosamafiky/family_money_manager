/// Property-based invariant tests for the ledger domain.
///
/// These tests generate randomized sequences of operations and verify that the
/// financial invariants hold across all combinations.
///
/// Verified invariants:
///   INV-001 – Balance = Σcredits − Σdebits
///   INV-003 – Transfer neutrality (total balance unchanged)
///   INV-004 – Reversal nets to zero with original
///   INV-011 – Transfer entries are distinguishable and not counted as income/expense
///   INV-012 – Balance is deterministic regardless of entry ordering
library;

import 'dart:math';

import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/ledger_calculator.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

LedgerEntryRecord _makeEntry({
  required String id,
  required String accountId,
  required LedgerDirection direction,
  required int amount,
  LedgerEntryType type = LedgerEntryType.income,
  String date = '2024-01-01',
  bool isReversal = false,
}) => LedgerEntryRecord(
  id: id,
  accountId: accountId,
  direction: direction,
  amountMinorUnits: amount,
  currencyCode: 'EGP',
  entryType: type,
  effectiveDate: date,
  isReversal: isReversal,
);

/// Generates a date string YYYY-MM-DD for a day offset [0..364] in 2024.
String _dateForDay(int day) {
  final d = DateTime(2024, 1, 1).add(Duration(days: day % 365));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  const seed = 42;
  final rng = Random(seed);

  group('INV-001 – balance equals sum of credits minus sum of debits', () {
    test('holds for 200 randomized entry sequences', () {
      for (var trial = 0; trial < 200; trial++) {
        const accountId = 'acc-prop';
        final entryCount = rng.nextInt(20) + 1;
        final entries = <LedgerEntryRecord>[];
        var manualBalance = 0;

        for (var i = 0; i < entryCount; i++) {
          final amount = rng.nextInt(10000) + 1;
          final isCredit = rng.nextBool();
          final dir = isCredit ? LedgerDirection.credit : LedgerDirection.debit;
          final type = isCredit ? LedgerEntryType.income : LedgerEntryType.expense;
          entries.add(
            _makeEntry(
              id: 'e-$trial-$i',
              accountId: accountId,
              direction: dir,
              amount: amount,
              type: type,
            ),
          );
          manualBalance += isCredit ? amount : -amount;
        }

        final result = LedgerCalculator.balance(
          accountId: accountId,
          entries: entries,
          currency: Currency.egp,
        );
        expect(result.minorUnits, manualBalance, reason: 'Trial $trial failed');
      }
    });
  });

  group('INV-003 – transfer neutrality', () {
    test('holds for 100 randomized transfers', () {
      for (var trial = 0; trial < 100; trial++) {
        const srcId = 'src-prop';
        const dstId = 'dst-prop';
        final srcStart = rng.nextInt(50000) + 1000;
        final dstStart = rng.nextInt(50000) + 1000;
        final transferAmount = rng.nextInt(srcStart) + 1;

        final entries = [
          _makeEntry(
            id: 'src-open-$trial',
            accountId: srcId,
            direction: LedgerDirection.credit,
            amount: srcStart,
            type: LedgerEntryType.openingBalance,
          ),
          _makeEntry(
            id: 'dst-open-$trial',
            accountId: dstId,
            direction: LedgerDirection.credit,
            amount: dstStart,
            type: LedgerEntryType.openingBalance,
          ),
          _makeEntry(
            id: 'tx-out-$trial',
            accountId: srcId,
            direction: LedgerDirection.debit,
            amount: transferAmount,
            type: LedgerEntryType.transferOut,
          ),
          _makeEntry(
            id: 'tx-in-$trial',
            accountId: dstId,
            direction: LedgerDirection.credit,
            amount: transferAmount,
            type: LedgerEntryType.transferIn,
          ),
        ];

        final srcBalance = LedgerCalculator.balance(
          accountId: srcId,
          entries: entries,
          currency: Currency.egp,
        );
        final dstBalance = LedgerCalculator.balance(
          accountId: dstId,
          entries: entries,
          currency: Currency.egp,
        );
        final total = LedgerCalculator.totalBalance([srcBalance, dstBalance]);

        expect(total.minorUnits, srcStart + dstStart, reason: 'Trial $trial: neutrality violated');
        expect(srcBalance.minorUnits, srcStart - transferAmount);
        expect(dstBalance.minorUnits, dstStart + transferAmount);
      }
    });
  });

  group('INV-004 – reversal pair nets to zero', () {
    test('holds for 100 randomized reversal pairs', () {
      for (var trial = 0; trial < 100; trial++) {
        const accountId = 'rev-prop';
        final original = rng.nextInt(20000) + 1;
        final openingBalance = rng.nextInt(50000) + original;

        final entries = [
          _makeEntry(
            id: 'ob-$trial',
            accountId: accountId,
            direction: LedgerDirection.credit,
            amount: openingBalance,
            type: LedgerEntryType.openingBalance,
          ),
          // Original debit
          _makeEntry(
            id: 'orig-$trial',
            accountId: accountId,
            direction: LedgerDirection.debit,
            amount: original,
            type: LedgerEntryType.expense,
          ),
          // Reversal credit
          _makeEntry(
            id: 'rev-$trial',
            accountId: accountId,
            direction: LedgerDirection.credit,
            amount: original,
            type: LedgerEntryType.reversalCredit,
            isReversal: true,
          ),
        ];

        final result = LedgerCalculator.balance(
          accountId: accountId,
          entries: entries,
          currency: Currency.egp,
        );
        // Opening balance should be fully restored
        expect(
          result.minorUnits,
          openingBalance,
          reason: 'Trial $trial: reversal did not restore balance',
        );
      }
    });
  });

  group('INV-012 – balance is deterministic regardless of entry order', () {
    test('holds for 100 shuffled entry lists', () {
      for (var trial = 0; trial < 100; trial++) {
        const accountId = 'det-prop';
        final entryCount = rng.nextInt(15) + 2;
        final entries = <LedgerEntryRecord>[];
        for (var i = 0; i < entryCount; i++) {
          final amount = rng.nextInt(5000) + 1;
          final isCredit = rng.nextBool();
          entries.add(
            _makeEntry(
              id: 'e-det-$trial-$i',
              accountId: accountId,
              direction: isCredit ? LedgerDirection.credit : LedgerDirection.debit,
              amount: amount,
              date: _dateForDay(rng.nextInt(365)),
            ),
          );
        }

        final canonical = LedgerCalculator.balance(
          accountId: accountId,
          entries: entries,
          currency: Currency.egp,
        );

        // Shuffle and recompute 5 times
        for (var shuffle = 0; shuffle < 5; shuffle++) {
          final shuffled = List<LedgerEntryRecord>.from(entries)..shuffle(rng);
          final shuffledResult = LedgerCalculator.balance(
            accountId: accountId,
            entries: shuffled,
            currency: Currency.egp,
          );
          expect(
            shuffledResult,
            equals(canonical),
            reason: 'Trial $trial shuffle $shuffle: balance differs',
          );
        }
      }
    });
  });

  group('INV-011 – transfer entry types are distinguishable', () {
    test('transfer types are not income or expense types', () {
      expect(LedgerEntryType.transferIn.isTransferType, isTrue);
      expect(LedgerEntryType.transferOut.isTransferType, isTrue);
      expect(LedgerEntryType.income.isTransferType, isFalse);
      expect(LedgerEntryType.expense.isTransferType, isFalse);
    });

    test('OperationType.transfer isExcludedFromIncomeExpenseReports', () {
      expect(OperationType.transfer.isExcludedFromIncomeExpenseReports, isTrue);
      expect(OperationType.income.isExcludedFromIncomeExpenseReports, isFalse);
      expect(OperationType.expense.isExcludedFromIncomeExpenseReports, isFalse);
    });
  });

  group('Duplicate operation idempotency (domain property)', () {
    test('applying same income twice produces double balance (not idempotent at domain layer)', () {
      // The domain-layer LedgerCalculator itself is a pure summation function.
      // Idempotency is enforced by the database UNIQUE constraint on operation IDs.
      // Here we verify that duplicates in the entry list would increase the balance,
      // confirming that the constraint IS needed.
      const accountId = 'dup-test';
      final e = _makeEntry(
        id: 'income-1',
        accountId: accountId,
        direction: LedgerDirection.credit,
        amount: 1000,
      );
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: [e, e], // same entry twice
        currency: Currency.egp,
      );
      // Without idempotency enforcement, the balance would be doubled
      expect(result.minorUnits, 2000);
      // This proves why the UNIQUE constraint in the DB is essential (INV-008)
    });
  });

  group('Money arithmetic properties', () {
    test('addition is commutative', () {
      for (var i = 0; i < 50; i++) {
        final a = Money(minorUnits: rng.nextInt(100000), currency: Currency.egp);
        final b = Money(minorUnits: rng.nextInt(100000), currency: Currency.egp);
        expect((a + b).minorUnits, (b + a).minorUnits);
      }
    });

    test('x + zero = x', () {
      for (var i = 0; i < 50; i++) {
        final a = Money(minorUnits: rng.nextInt(100000), currency: Currency.egp);
        const zero = Money.zero(Currency.egp);
        expect((a + zero).minorUnits, a.minorUnits);
      }
    });

    test('x - x = zero', () {
      for (var i = 0; i < 50; i++) {
        final amount = rng.nextInt(100000);
        final a = Money(minorUnits: amount, currency: Currency.egp);
        expect((a - a).isZero, isTrue);
      }
    });

    test('-(−x) = x (double negation)', () {
      for (var i = 0; i < 50; i++) {
        final amount = rng.nextInt(100000);
        final a = Money(minorUnits: amount, currency: Currency.egp);
        expect((-(-a)).minorUnits, a.minorUnits);
      }
    });

    test('allocation sum equals original amount', () {
      for (var i = 0; i < 50; i++) {
        final amount = rng.nextInt(10000) + 1;
        final parts = rng.nextInt(9) + 2; // 2..10
        final m = Money(minorUnits: amount, currency: Currency.egp);
        final allocated = m.allocate(parts);
        final sum = allocated.fold(0, (acc, p) => acc + p.minorUnits);
        expect(sum, amount, reason: 'Allocation of $amount into $parts parts lost money');
      }
    });
  });
}
