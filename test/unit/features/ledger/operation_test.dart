import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2024, 6, 1, 10);

  Operation makeOp({
    String id = 'op-1',
    OperationType type = OperationType.income,
    int amount = 1000,
    String effectiveDate = '2024-06-01',
  }) => Operation(
    id: id,
    householdId: 'hh-1',
    type: type,
    effectiveDate: effectiveDate,
    recordedAt: now,
    totalAmountMinorUnits: amount,
    currencyCode: 'EGP',
    createdBy: 'user-1',
    createdAt: now.toIso8601String(),
    updatedAt: now.toIso8601String(),
    isReversed: false,
  );

  group('Operation – construction', () {
    test('creates with required fields', () {
      final op = makeOp();
      expect(op.id, 'op-1');
      expect(op.type, OperationType.income);
      expect(op.isReversed, isFalse);
      expect(op.reversedBy, isNull);
      expect(op.tags, isEmpty);
    });

    test('equality is based on id', () {
      final a = makeOp(id: 'op-1', amount: 1000);
      final b = makeOp(id: 'op-1', amount: 9999);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different ids are not equal', () {
      final a = makeOp(id: 'op-1');
      final b = makeOp(id: 'op-2');
      expect(a, isNot(equals(b)));
    });
  });

  group('RecordIncomeParams', () {
    test('creates with positive amount', () {
      const params = RecordIncomeParams(
        operationId: 'op-inc-1',
        householdId: 'hh-1',
        destinationAccountId: 'acc-1',
        amountMinorUnits: 5000,
        currencyCode: 'EGP',
        effectiveDate: '2024-06-01',
        createdBy: 'user-1',
      );
      expect(params.amountMinorUnits, 5000);
    });

    test('assert fires for zero amount', () {
      expect(
        () => RecordIncomeParams(
          operationId: 'op-1',
          householdId: 'hh-1',
          destinationAccountId: 'acc-1',
          amountMinorUnits: 0, // must be > 0
          currencyCode: 'EGP',
          effectiveDate: '2024-06-01',
          createdBy: 'user-1',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert fires for negative amount', () {
      expect(
        () => RecordIncomeParams(
          operationId: 'op-1',
          householdId: 'hh-1',
          destinationAccountId: 'acc-1',
          amountMinorUnits: -100,
          currencyCode: 'EGP',
          effectiveDate: '2024-06-01',
          createdBy: 'user-1',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('RecordExpenseParams', () {
    test('creates with positive amount', () {
      const params = RecordExpenseParams(
        operationId: 'op-exp-1',
        householdId: 'hh-1',
        sourceAccountId: 'acc-1',
        amountMinorUnits: 2000,
        currencyCode: 'EGP',
        effectiveDate: '2024-06-01',
        createdBy: 'user-1',
      );
      expect(params.amountMinorUnits, 2000);
    });

    test('assert fires for non-positive amount', () {
      expect(
        () => RecordExpenseParams(
          operationId: 'op-1',
          householdId: 'hh-1',
          sourceAccountId: 'acc-1',
          amountMinorUnits: 0,
          currencyCode: 'EGP',
          effectiveDate: '2024-06-01',
          createdBy: 'user-1',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('ExecuteTransferParams', () {
    test('creates with positive amount', () {
      const params = ExecuteTransferParams(
        operationId: 'op-t-1',
        householdId: 'hh-1',
        sourceAccountId: 'acc-src',
        destinationAccountId: 'acc-dst',
        amountMinorUnits: 3000,
        currencyCode: 'EGP',
        effectiveDate: '2024-06-01',
        createdBy: 'user-1',
      );
      expect(params.sourceAccountId, 'acc-src');
      expect(params.destinationAccountId, 'acc-dst');
      expect(params.amountMinorUnits, 3000);
    });

    test('assert fires for zero amount', () {
      expect(
        () => ExecuteTransferParams(
          operationId: 'op-1',
          householdId: 'hh-1',
          sourceAccountId: 'acc-src',
          destinationAccountId: 'acc-dst',
          amountMinorUnits: 0,
          currencyCode: 'EGP',
          effectiveDate: '2024-06-01',
          createdBy: 'user-1',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('RecordOpeningBalanceParams', () {
    test('accepts zero amount (accounts can start at zero)', () {
      const params = RecordOpeningBalanceParams(
        operationId: 'op-ob-1',
        householdId: 'hh-1',
        accountId: 'acc-1',
        amountMinorUnits: 0,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'user-1',
      );
      expect(params.amountMinorUnits, 0);
    });

    test('assert fires for negative amount', () {
      expect(
        () => RecordOpeningBalanceParams(
          operationId: 'op-ob-2',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: -1,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('RecordAdjustmentParams', () {
    test('creates with positive signed amount', () {
      const params = RecordAdjustmentParams(
        operationId: 'op-adj-1',
        householdId: 'hh-1',
        accountId: 'acc-1',
        adjustmentAmountMinorUnits: 100,
        currencyCode: 'EGP',
        effectiveDate: '2024-06-01',
        createdBy: 'user-1',
        reason: 'Cash recount',
      );
      expect(params.isCredit, isTrue);
    });

    test('isCredit is false for negative amount', () {
      const params = RecordAdjustmentParams(
        operationId: 'op-adj-2',
        householdId: 'hh-1',
        accountId: 'acc-1',
        adjustmentAmountMinorUnits: -50,
        currencyCode: 'EGP',
        effectiveDate: '2024-06-01',
        createdBy: 'user-1',
        reason: 'Discrepancy',
      );
      expect(params.isCredit, isFalse);
    });

    test('assert fires for zero adjustment amount', () {
      expect(
        () => RecordAdjustmentParams(
          operationId: 'op-adj-3',
          householdId: 'hh-1',
          accountId: 'acc-1',
          adjustmentAmountMinorUnits: 0,
          currencyCode: 'EGP',
          effectiveDate: '2024-06-01',
          createdBy: 'user-1',
          reason: 'Should fail',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('ReverseOperationParams', () {
    test('creates with required fields', () {
      const params = ReverseOperationParams(
        reversalOperationId: 'op-rev-1',
        originalOperationId: 'op-1',
        householdId: 'hh-1',
        effectiveDate: '2024-06-01',
        createdBy: 'user-1',
        reason: 'Entry error',
      );
      expect(params.originalOperationId, 'op-1');
      expect(params.reversalOperationId, 'op-rev-1');
    });

    test('reason is optional', () {
      const params = ReverseOperationParams(
        reversalOperationId: 'op-rev-2',
        originalOperationId: 'op-2',
        householdId: 'hh-1',
        effectiveDate: '2024-06-01',
        createdBy: 'user-1',
      );
      expect(params.reason, isNull);
    });
  });

  group('OperationType enum', () {
    test('fromCode round-trips all values', () {
      for (final t in OperationType.values) {
        expect(OperationType.fromCode(t.code), t);
      }
    });

    test('fromCode throws for unknown code', () {
      expect(() => OperationType.fromCode('flyingPig'), throwsArgumentError);
    });

    test('transfer is excluded from income/expense reports (INV-011)', () {
      expect(OperationType.transfer.isExcludedFromIncomeExpenseReports, isTrue);
    });

    test('income is NOT excluded from reports', () {
      expect(OperationType.income.isExcludedFromIncomeExpenseReports, isFalse);
    });

    test('expense is NOT excluded from reports', () {
      expect(OperationType.expense.isExcludedFromIncomeExpenseReports, isFalse);
    });
  });

  group('LedgerDirection enum', () {
    test('opposite of credit is debit and vice-versa', () {
      expect(LedgerDirection.credit.opposite, LedgerDirection.debit);
      expect(LedgerDirection.debit.opposite, LedgerDirection.credit);
    });

    test('fromCode round-trips', () {
      expect(LedgerDirection.fromCode('credit'), LedgerDirection.credit);
      expect(LedgerDirection.fromCode('debit'), LedgerDirection.debit);
    });

    test('fromCode throws for unknown code', () {
      expect(() => LedgerDirection.fromCode('sideways'), throwsArgumentError);
    });
  });

  group('LedgerEntryType enum', () {
    test('fromCode round-trips all values', () {
      for (final t in LedgerEntryType.values) {
        expect(LedgerEntryType.fromCode(t.code), t);
      }
    });

    test('isDebitType is true for debit entry types', () {
      final debitTypes = [
        LedgerEntryType.expense,
        LedgerEntryType.transferOut,
        LedgerEntryType.adjustmentDebit,
        LedgerEntryType.childFundWithdrawal,
        LedgerEntryType.reversalDebit,
      ];
      for (final t in debitTypes) {
        expect(t.isDebitType, isTrue, reason: t.code);
      }
    });

    test('isDebitType is false for credit entry types', () {
      final creditTypes = [
        LedgerEntryType.income,
        LedgerEntryType.transferIn,
        LedgerEntryType.openingBalance,
        LedgerEntryType.reversalCredit,
      ];
      for (final t in creditTypes) {
        expect(t.isDebitType, isFalse, reason: t.code);
      }
    });

    test('isTransferType is true only for transfer types', () {
      expect(LedgerEntryType.transferOut.isTransferType, isTrue);
      expect(LedgerEntryType.transferIn.isTransferType, isTrue);
      expect(LedgerEntryType.transferFee.isTransferType, isTrue);
      expect(LedgerEntryType.income.isTransferType, isFalse);
      expect(LedgerEntryType.expense.isTransferType, isFalse);
    });
  });
}
