import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2024, 6, 1, 12);

  group('ChildWithdrawalAudit – construction', () {
    test('creates with all valid fields', () {
      final audit = ChildWithdrawalAudit(
        id: 'audit-1',
        operationId: 'op-1',
        householdId: 'hh-1',
        accountId: 'acc-1',
        amountMinorUnits: 5000,
        reason: 'School supplies',
        beneficiary: HouseholdMemberRole.child,
        confirmedAt: now,
        confirmedBy: 'user-1',
        warningShown: true,
        biometricConfirmed: false,
        createdAt: now,
      );
      expect(audit.amountMinorUnits, 5000);
      expect(audit.warningShown, isTrue);
      expect(audit.reason, 'School supplies');
    });

    test('warningShown=false is an assertion error', () {
      expect(
        () => ChildWithdrawalAudit(
          id: 'audit-2',
          operationId: 'op-2',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 100,
          reason: 'reason',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: now,
          confirmedBy: 'user-1',
          warningShown: false, // must be true
          biometricConfirmed: false,
          createdAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('empty reason is an assertion error', () {
      expect(
        () => ChildWithdrawalAudit(
          id: 'audit-3',
          operationId: 'op-3',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 100,
          reason: '', // must not be empty
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: now,
          confirmedBy: 'user-1',
          warningShown: true,
          biometricConfirmed: false,
          createdAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('amountMinorUnits=0 is an assertion error', () {
      expect(
        () => ChildWithdrawalAudit(
          id: 'audit-4',
          operationId: 'op-4',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 0, // must be positive
          reason: 'reason',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: now,
          confirmedBy: 'user-1',
          warningShown: true,
          biometricConfirmed: false,
          createdAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality is based on id', () {
      final a = ChildWithdrawalAudit(
        id: 'audit-1',
        operationId: 'op-1',
        householdId: 'hh-1',
        accountId: 'acc-1',
        amountMinorUnits: 100,
        reason: 'reason',
        beneficiary: HouseholdMemberRole.child,
        confirmedAt: now,
        confirmedBy: 'user-1',
        warningShown: true,
        biometricConfirmed: false,
        createdAt: now,
      );
      final b = ChildWithdrawalAudit(
        id: 'audit-1',
        operationId: 'op-DIFFERENT',
        householdId: 'hh-1',
        accountId: 'acc-1',
        amountMinorUnits: 999,
        reason: 'different reason',
        beneficiary: HouseholdMemberRole.user,
        confirmedAt: now,
        confirmedBy: 'user-2',
        warningShown: true,
        biometricConfirmed: true,
        createdAt: now,
      );
      expect(a, equals(b));
    });
  });

  group('ChildWithdrawalAuditParams – construction', () {
    test('warningShown=false throws AssertionError', () {
      expect(
        () => ChildWithdrawalAuditParams(
          auditId: 'a1',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 100,
          reason: 'reason',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: now,
          confirmedBy: 'user-1',
          warningShown: false,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('creates successfully with warningShown=true', () {
      final params = ChildWithdrawalAuditParams(
        auditId: 'a1',
        operationId: 'op-1',
        householdId: 'hh-1',
        accountId: 'acc-1',
        amountMinorUnits: 500,
        reason: 'Books',
        beneficiary: HouseholdMemberRole.child,
        confirmedAt: now,
        confirmedBy: 'user-1',
        warningShown: true,
      );
      expect(params.warningShown, isTrue);
      expect(params.biometricConfirmed, isFalse);
    });
  });

  group('MissingProtectedWithdrawalAuditError', () {
    test('has accountId in message', () {
      final err = MissingProtectedWithdrawalAuditError('acc-protected');
      expect(err.toString(), contains('acc-protected'));
    });
  });

  group('InsufficientFundsError', () {
    test('has available and requested in message', () {
      final err = InsufficientFundsError(
        accountId: 'acc-1',
        availableMinorUnits: 100,
        requestedMinorUnits: 500,
      );
      expect(err.toString(), contains('100'));
      expect(err.toString(), contains('500'));
    });
  });
}
