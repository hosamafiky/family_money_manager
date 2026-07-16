/// Release-safe validation tests (Phase 2A §2).
///
/// Verifies that all financial domain validation runs in all Dart compilation
/// modes. Tests do NOT depend on `assert()` — they explicitly test
/// [ArgumentError] thrown by factory constructors.
///
/// If Dart were to disable assertions (as it does in `dart compile exe` with
/// `--define dart.vm.product=true`), these tests would still pass because the
/// validation uses `throw ArgumentError(...)`, not `assert()`.
library;

import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ts = DateTime.utc(2024, 1, 1, 12);

  // ── LedgerEntry ───────────────────────────────────────────────────────────

  group('LedgerEntry – release-safe validation', () {
    test('valid entry constructs successfully', () {
      final e = LedgerEntry(
        id: 'e-1',
        operationId: 'op-1',
        householdId: 'hh-1',
        accountId: 'acc-1',
        direction: LedgerDirection.credit,
        amountMinorUnits: 1,
        currencyCode: 'EGP',
        entryType: LedgerEntryType.income,
        effectiveDate: '2024-01-01',
        recordedAt: ts,
        createdBy: 'user-1',
        isReversal: false,
      );
      expect(e.amountMinorUnits, 1);
    });

    test('amountMinorUnits = 0 throws ArgumentError (not AssertionError)', () {
      expect(
        () => LedgerEntry(
          id: 'e-bad',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          direction: LedgerDirection.credit,
          amountMinorUnits: 0,
          currencyCode: 'EGP',
          entryType: LedgerEntryType.income,
          effectiveDate: '2024-01-01',
          recordedAt: ts,
          createdBy: 'user-1',
          isReversal: false,
        ),
        throwsArgumentError,
      );
    });

    test('amountMinorUnits = -1 throws ArgumentError', () {
      expect(
        () => LedgerEntry(
          id: 'e-neg',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          direction: LedgerDirection.credit,
          amountMinorUnits: -1,
          currencyCode: 'EGP',
          entryType: LedgerEntryType.income,
          effectiveDate: '2024-01-01',
          recordedAt: ts,
          createdBy: 'user-1',
          isReversal: false,
        ),
        throwsArgumentError,
      );
    });

    test('empty id throws ArgumentError', () {
      expect(
        () => LedgerEntry(
          id: '',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          direction: LedgerDirection.credit,
          amountMinorUnits: 100,
          currencyCode: 'EGP',
          entryType: LedgerEntryType.income,
          effectiveDate: '2024-01-01',
          recordedAt: ts,
          createdBy: 'user-1',
          isReversal: false,
        ),
        throwsArgumentError,
      );
    });

    test('empty operationId throws ArgumentError', () {
      expect(
        () => LedgerEntry(
          id: 'e-1',
          operationId: '',
          householdId: 'hh-1',
          accountId: 'acc-1',
          direction: LedgerDirection.credit,
          amountMinorUnits: 100,
          currencyCode: 'EGP',
          entryType: LedgerEntryType.income,
          effectiveDate: '2024-01-01',
          recordedAt: ts,
          createdBy: 'user-1',
          isReversal: false,
        ),
        throwsArgumentError,
      );
    });

    test('empty accountId throws ArgumentError', () {
      expect(
        () => LedgerEntry(
          id: 'e-1',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: '',
          direction: LedgerDirection.credit,
          amountMinorUnits: 100,
          currencyCode: 'EGP',
          entryType: LedgerEntryType.income,
          effectiveDate: '2024-01-01',
          recordedAt: ts,
          createdBy: 'user-1',
          isReversal: false,
        ),
        throwsArgumentError,
      );
    });

    test('maximum int is accepted as amountMinorUnits', () {
      expect(
        () => LedgerEntry(
          id: 'e-max',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          direction: LedgerDirection.credit,
          amountMinorUnits: 9223372036854775807, // Dart int64 max
          currencyCode: 'EGP',
          entryType: LedgerEntryType.income,
          effectiveDate: '2024-01-01',
          recordedAt: ts,
          createdBy: 'user-1',
          isReversal: false,
        ),
        returnsNormally,
      );
    });
  });

  // ── RecordIncomeParams ────────────────────────────────────────────────────

  group('RecordIncomeParams – release-safe validation', () {
    test('valid params construct', () {
      expect(
        () => RecordIncomeParams(
          operationId: 'op-1',
          householdId: 'hh-1',
          destinationAccountId: 'acc-1',
          amountMinorUnits: 1,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        returnsNormally,
      );
    });

    test('amount=0 throws ArgumentError', () {
      expect(
        () => RecordIncomeParams(
          operationId: 'op-1',
          householdId: 'hh-1',
          destinationAccountId: 'acc-1',
          amountMinorUnits: 0,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsArgumentError,
      );
    });

    test('amount=-1 throws ArgumentError', () {
      expect(
        () => RecordIncomeParams(
          operationId: 'op-1',
          householdId: 'hh-1',
          destinationAccountId: 'acc-1',
          amountMinorUnits: -1,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsArgumentError,
      );
    });

    test('empty operationId throws ArgumentError', () {
      expect(
        () => RecordIncomeParams(
          operationId: '',
          householdId: 'hh-1',
          destinationAccountId: 'acc-1',
          amountMinorUnits: 100,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsArgumentError,
      );
    });

    test('resolvedIdempotencyKey defaults to operationId', () {
      final p = RecordIncomeParams(
        operationId: 'op-x',
        householdId: 'hh-1',
        destinationAccountId: 'acc-1',
        amountMinorUnits: 100,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'user-1',
      );
      expect(p.resolvedIdempotencyKey, 'op-x');
    });

    test('explicit idempotencyKey overrides default', () {
      final p = RecordIncomeParams(
        operationId: 'op-x',
        householdId: 'hh-1',
        destinationAccountId: 'acc-1',
        amountMinorUnits: 100,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'user-1',
        idempotencyKey: 'my-custom-key',
      );
      expect(p.resolvedIdempotencyKey, 'my-custom-key');
    });
  });

  // ── RecordExpenseParams ───────────────────────────────────────────────────

  group('RecordExpenseParams – release-safe validation', () {
    test('amount=0 throws ArgumentError', () {
      expect(
        () => RecordExpenseParams(
          operationId: 'op-1',
          householdId: 'hh-1',
          sourceAccountId: 'acc-1',
          amountMinorUnits: 0,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsArgumentError,
      );
    });

    test('empty sourceAccountId throws ArgumentError', () {
      expect(
        () => RecordExpenseParams(
          operationId: 'op-1',
          householdId: 'hh-1',
          sourceAccountId: '',
          amountMinorUnits: 100,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsArgumentError,
      );
    });
  });

  // ── ExecuteTransferParams ─────────────────────────────────────────────────

  group('ExecuteTransferParams – release-safe validation', () {
    test('amount=0 throws ArgumentError', () {
      expect(
        () => ExecuteTransferParams(
          operationId: 'op-1',
          householdId: 'hh-1',
          sourceAccountId: 'src',
          destinationAccountId: 'dst',
          amountMinorUnits: 0,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsArgumentError,
      );
    });

    test('empty destinationAccountId throws ArgumentError', () {
      expect(
        () => ExecuteTransferParams(
          operationId: 'op-1',
          householdId: 'hh-1',
          sourceAccountId: 'src',
          destinationAccountId: '',
          amountMinorUnits: 100,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsArgumentError,
      );
    });
  });

  // ── RecordOpeningBalanceParams ────────────────────────────────────────────

  group('RecordOpeningBalanceParams – release-safe validation', () {
    test('zero amount is valid (account can start empty)', () {
      expect(
        () => RecordOpeningBalanceParams(
          operationId: 'op-ob',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 0,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        returnsNormally,
      );
    });

    test('negative amount throws ArgumentError', () {
      expect(
        () => RecordOpeningBalanceParams(
          operationId: 'op-ob',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: -1,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsArgumentError,
      );
    });

    test('empty accountId throws ArgumentError', () {
      expect(
        () => RecordOpeningBalanceParams(
          operationId: 'op-ob',
          householdId: 'hh-1',
          accountId: '',
          amountMinorUnits: 100,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsArgumentError,
      );
    });
  });

  // ── RecordAdjustmentParams ────────────────────────────────────────────────

  group('RecordAdjustmentParams – release-safe validation', () {
    test('zero adjustment throws ArgumentError', () {
      expect(
        () => RecordAdjustmentParams(
          operationId: 'op-adj',
          householdId: 'hh-1',
          accountId: 'acc-1',
          adjustmentAmountMinorUnits: 0,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
          reason: 'test',
        ),
        throwsArgumentError,
      );
    });

    test('empty reason throws ArgumentError', () {
      expect(
        () => RecordAdjustmentParams(
          operationId: 'op-adj',
          householdId: 'hh-1',
          accountId: 'acc-1',
          adjustmentAmountMinorUnits: 100,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
          reason: '',
        ),
        throwsArgumentError,
      );
    });

    test('positive amount → isCredit=true', () {
      final p = RecordAdjustmentParams(
        operationId: 'op-adj',
        householdId: 'hh-1',
        accountId: 'acc-1',
        adjustmentAmountMinorUnits: 100,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'user-1',
        reason: 'recount',
      );
      expect(p.isCredit, isTrue);
    });

    test('negative amount → isCredit=false', () {
      final p = RecordAdjustmentParams(
        operationId: 'op-adj',
        householdId: 'hh-1',
        accountId: 'acc-1',
        adjustmentAmountMinorUnits: -50,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'user-1',
        reason: 'recount',
      );
      expect(p.isCredit, isFalse);
    });
  });

  // ── ChildWithdrawalAudit ──────────────────────────────────────────────────

  group('ChildWithdrawalAudit – release-safe validation', () {
    test('warningShown=false throws ArgumentError', () {
      expect(
        () => ChildWithdrawalAudit(
          id: 'a-1',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 100,
          reason: 'reason',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: ts,
          confirmedBy: 'user-1',
          warningShown: false,
          biometricConfirmed: false,
          createdAt: ts,
        ),
        throwsArgumentError,
      );
    });

    test('empty reason throws ArgumentError', () {
      expect(
        () => ChildWithdrawalAudit(
          id: 'a-1',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 100,
          reason: '',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: ts,
          confirmedBy: 'user-1',
          warningShown: true,
          biometricConfirmed: false,
          createdAt: ts,
        ),
        throwsArgumentError,
      );
    });

    test('zero amountMinorUnits throws ArgumentError', () {
      expect(
        () => ChildWithdrawalAudit(
          id: 'a-1',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 0,
          reason: 'reason',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: ts,
          confirmedBy: 'user-1',
          warningShown: true,
          biometricConfirmed: false,
          createdAt: ts,
        ),
        throwsArgumentError,
      );
    });
  });

  // ── ChildWithdrawalAuditParams ────────────────────────────────────────────

  group('ChildWithdrawalAuditParams – release-safe validation', () {
    test('warningShown=false throws ArgumentError', () {
      expect(
        () => ChildWithdrawalAuditParams(
          auditId: 'a-1',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 100,
          reason: 'reason',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: ts,
          confirmedBy: 'user-1',
          warningShown: false,
        ),
        throwsArgumentError,
      );
    });

    test('empty reason throws ArgumentError', () {
      expect(
        () => ChildWithdrawalAuditParams(
          auditId: 'a-1',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 100,
          reason: '',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: ts,
          confirmedBy: 'user-1',
          warningShown: true,
        ),
        throwsArgumentError,
      );
    });
  });
}
