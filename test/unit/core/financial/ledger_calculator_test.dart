import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/ledger_calculator.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

LedgerEntryRecord _credit(
  String id,
  String accountId,
  int amount, {
  String date = '2024-01-01',
  LedgerEntryType type = LedgerEntryType.income,
  bool isReversal = false,
}) => LedgerEntryRecord(
  id: id,
  accountId: accountId,
  direction: LedgerDirection.credit,
  amountMinorUnits: amount,
  currencyCode: 'EGP',
  entryType: type,
  effectiveDate: date,
  isReversal: isReversal,
);

LedgerEntryRecord _debit(
  String id,
  String accountId,
  int amount, {
  String date = '2024-01-01',
  LedgerEntryType type = LedgerEntryType.expense,
  bool isReversal = false,
}) => LedgerEntryRecord(
  id: id,
  accountId: accountId,
  direction: LedgerDirection.debit,
  amountMinorUnits: amount,
  currencyCode: 'EGP',
  entryType: type,
  effectiveDate: date,
  isReversal: isReversal,
);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('LedgerCalculator.balance', () {
    const accountId = 'acc-1';

    test('returns zero for empty entries', () {
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: const [],
        currency: Currency.egp,
      );
      expect(result.isZero, isTrue);
      expect(result.currency, Currency.egp);
    });

    test('single credit increases balance', () {
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: [_credit('e1', accountId, 1000)],
        currency: Currency.egp,
      );
      expect(result.minorUnits, 1000);
    });

    test('single debit decreases balance', () {
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: [_credit('e1', accountId, 1000), _debit('e2', accountId, 300)],
        currency: Currency.egp,
      );
      expect(result.minorUnits, 700);
    });

    test('balance equals credits minus debits', () {
      final entries = [
        _credit('e1', accountId, 5000),
        _credit('e2', accountId, 3000),
        _debit('e3', accountId, 2000),
        _debit('e4', accountId, 1000),
      ];
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: entries,
        currency: Currency.egp,
      );
      // 5000 + 3000 - 2000 - 1000 = 5000
      expect(result.minorUnits, 5000);
    });

    test('ignores entries for other accounts', () {
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: [
          _credit('e1', accountId, 1000),
          _credit('e2', 'acc-other', 99999), // different account
        ],
        currency: Currency.egp,
      );
      expect(result.minorUnits, 1000);
    });

    test('opening balance is included', () {
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: [
          _credit('e1', accountId, 5000, type: LedgerEntryType.openingBalance),
        ],
        currency: Currency.egp,
      );
      expect(result.minorUnits, 5000);
    });

    test('reversal pair nets to zero (INV-004)', () {
      // Original expense debit: -500
      // Reversal credit: +500
      final entries = [
        _credit('e1', accountId, 1000),
        _debit('e2', accountId, 500),
        _credit(
          'e3',
          accountId,
          500,
          isReversal: true,
          type: LedgerEntryType.reversalCredit,
        ),
      ];
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: entries,
        currency: Currency.egp,
      );
      // 1000 - 500 + 500 = 1000 (restored)
      expect(result.minorUnits, 1000);
    });

    test('balance can go negative (deficit)', () {
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: [_debit('e1', accountId, 1000)],
        currency: Currency.egp,
      );
      expect(result.minorUnits, -1000);
    });
  });

  group('LedgerCalculator.historicalBalance', () {
    const accountId = 'acc-1';

    test('excludes entries after asOfDate', () {
      final entries = [
        _credit('e1', accountId, 1000, date: '2024-01-01'),
        _credit('e2', accountId, 500, date: '2024-06-01'),
        _debit('e3', accountId, 200, date: '2024-12-31'),
      ];
      final result = LedgerCalculator.historicalBalance(
        accountId: accountId,
        entries: entries,
        currency: Currency.egp,
        asOfDate: '2024-05-31',
      );
      // Only e1 qualifies (e2 is after)
      expect(result.minorUnits, 1000);
    });

    test('includes entries exactly on asOfDate', () {
      final entries = [
        _credit('e1', accountId, 1000, date: '2024-01-01'),
        _credit('e2', accountId, 500, date: '2024-06-01'),
      ];
      final result = LedgerCalculator.historicalBalance(
        accountId: accountId,
        entries: entries,
        currency: Currency.egp,
        asOfDate: '2024-06-01',
      );
      expect(result.minorUnits, 1500);
    });

    test('returns zero when all entries are after asOfDate', () {
      final result = LedgerCalculator.historicalBalance(
        accountId: accountId,
        entries: [_credit('e1', accountId, 1000, date: '2025-01-01')],
        currency: Currency.egp,
        asOfDate: '2024-12-31',
      );
      expect(result.isZero, isTrue);
    });

    test('backdated operations are included at their effective date', () {
      // A backdated entry for 2023 should be included in 2024 queries
      final entries = [
        _credit('e1', accountId, 200, date: '2023-12-01'), // backdated
        _credit('e2', accountId, 800, date: '2024-03-01'),
      ];
      final resultPre = LedgerCalculator.historicalBalance(
        accountId: accountId,
        entries: entries,
        currency: Currency.egp,
        asOfDate: '2023-12-31',
      );
      expect(resultPre.minorUnits, 200);

      final resultPost = LedgerCalculator.historicalBalance(
        accountId: accountId,
        entries: entries,
        currency: Currency.egp,
        asOfDate: '2024-12-31',
      );
      expect(resultPost.minorUnits, 1000);
    });

    test('reversal within window restores balance', () {
      final entries = [
        _credit('e1', accountId, 1000, date: '2024-01-01'),
        _debit('e2', accountId, 400, date: '2024-02-01'),
        _credit(
          'e3',
          accountId,
          400,
          date: '2024-03-01',
          isReversal: true,
          type: LedgerEntryType.reversalCredit,
        ),
      ];
      final result = LedgerCalculator.historicalBalance(
        accountId: accountId,
        entries: entries,
        currency: Currency.egp,
        asOfDate: '2024-12-31',
      );
      expect(result.minorUnits, 1000);
    });
  });

  group('LedgerCalculator.totalBalance', () {
    test('returns zero for empty list (defaults to EGP)', () {
      final result = LedgerCalculator.totalBalance([]);
      expect(result.isZero, isTrue);
    });

    test('sums same-currency balances', () {
      final balances = [
        const Money(minorUnits: 1000, currency: Currency.egp),
        const Money(minorUnits: 2000, currency: Currency.egp),
        const Money(minorUnits: 500, currency: Currency.egp),
      ];
      final result = LedgerCalculator.totalBalance(balances);
      expect(result.minorUnits, 3500);
    });

    test('single balance returned unchanged', () {
      final balances = [const Money(minorUnits: 999, currency: Currency.egp)];
      final result = LedgerCalculator.totalBalance(balances);
      expect(result.minorUnits, 999);
    });

    test('negative balances are summed correctly', () {
      final balances = [
        const Money(minorUnits: 500, currency: Currency.egp),
        const Money(minorUnits: -200, currency: Currency.egp),
      ];
      final result = LedgerCalculator.totalBalance(balances);
      expect(result.minorUnits, 300);
    });
  });

  group('Transfer neutrality invariant (INV-003)', () {
    test('transfer does not change total balance across two accounts', () {
      const srcId = 'src';
      const dstId = 'dst';
      // Before transfer: src=2000, dst=500
      // Transfer: 800 from src to dst
      final entries = [
        _credit('e1', srcId, 2000, date: '2024-01-01'),
        _credit('e2', dstId, 500, date: '2024-01-01'),
        _debit(
          't1-out',
          srcId,
          800,
          date: '2024-02-01',
          type: LedgerEntryType.transferOut,
        ),
        _credit(
          't1-in',
          dstId,
          800,
          date: '2024-02-01',
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

      // Total before: 2500. Total after: still 2500 (transfer is neutral).
      expect(total.minorUnits, 2500);
      expect(srcBalance.minorUnits, 1200);
      expect(dstBalance.minorUnits, 1300);
    });
  });

  group('Opening balance invariant', () {
    test('opening balance type is distinguishable from income', () {
      const accountId = 'acc-1';
      final openingEntry = _credit(
        'ob1',
        accountId,
        5000,
        type: LedgerEntryType.openingBalance,
      );
      final incomeEntry = _credit(
        'inc1',
        accountId,
        1000,
        type: LedgerEntryType.income,
      );

      expect(openingEntry.entryType, LedgerEntryType.openingBalance);
      expect(incomeEntry.entryType, LedgerEntryType.income);

      // Both contribute to balance
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: [openingEntry, incomeEntry],
        currency: Currency.egp,
      );
      expect(result.minorUnits, 6000);
    });
  });

  group('Adjustment invariant', () {
    test('positive adjustment increases balance', () {
      const accountId = 'acc-1';
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: [
          _credit('e1', accountId, 1000),
          _credit(
            'adj',
            accountId,
            100,
            type: LedgerEntryType.adjustmentCredit,
          ),
        ],
        currency: Currency.egp,
      );
      expect(result.minorUnits, 1100);
    });

    test('negative adjustment decreases balance', () {
      const accountId = 'acc-1';
      final result = LedgerCalculator.balance(
        accountId: accountId,
        entries: [
          _credit('e1', accountId, 1000),
          _debit('adj', accountId, 100, type: LedgerEntryType.adjustmentDebit),
        ],
        currency: Currency.egp,
      );
      expect(result.minorUnits, 900);
    });
  });

  group('Deterministic ordering', () {
    test('balance is the same regardless of entry list order', () {
      const accountId = 'acc-1';
      final e1 = _credit('e1', accountId, 1000, date: '2024-01-01');
      final e2 = _debit('e2', accountId, 300, date: '2024-02-01');
      final e3 = _credit('e3', accountId, 200, date: '2024-03-01');

      final result1 = LedgerCalculator.balance(
        accountId: accountId,
        entries: [e1, e2, e3],
        currency: Currency.egp,
      );
      final result2 = LedgerCalculator.balance(
        accountId: accountId,
        entries: [e3, e1, e2],
        currency: Currency.egp,
      );
      final result3 = LedgerCalculator.balance(
        accountId: accountId,
        entries: [e2, e3, e1],
        currency: Currency.egp,
      );

      expect(result1, equals(result2));
      expect(result2, equals(result3));
    });
  });
}
