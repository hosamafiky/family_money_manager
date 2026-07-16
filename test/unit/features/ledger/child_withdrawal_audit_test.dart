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

    // Phase 2A: release-safe validation (ArgumentError, not AssertionError)
    test('warningShown=false throws ArgumentError in all modes', () {
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
          warningShown: false,
          biometricConfirmed: false,
          createdAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('empty reason throws ArgumentError in all modes', () {
      expect(
        () => ChildWithdrawalAudit(
          id: 'audit-3',
          operationId: 'op-3',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 100,
          reason: '',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: now,
          confirmedBy: 'user-1',
          warningShown: true,
          biometricConfirmed: false,
          createdAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('amountMinorUnits=0 throws ArgumentError in all modes', () {
      expect(
        () => ChildWithdrawalAudit(
          id: 'audit-4',
          operationId: 'op-4',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 0,
          reason: 'reason',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: now,
          confirmedBy: 'user-1',
          warningShown: true,
          biometricConfirmed: false,
          createdAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('negative amountMinorUnits throws ArgumentError', () {
      expect(
        () => ChildWithdrawalAudit(
          id: 'audit-5',
          operationId: 'op-5',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: -1,
          reason: 'reason',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: now,
          confirmedBy: 'user-1',
          warningShown: true,
          biometricConfirmed: false,
          createdAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('empty id throws ArgumentError', () {
      expect(
        () => ChildWithdrawalAudit(
          id: '',
          operationId: 'op-6',
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
        ),
        throwsArgumentError,
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
    test('warningShown=false throws ArgumentError in all modes', () {
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
        throwsArgumentError,
      );
    });

    test('empty reason throws ArgumentError', () {
      expect(
        () => ChildWithdrawalAuditParams(
          auditId: 'a1',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 100,
          reason: '',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: now,
          confirmedBy: 'user-1',
          warningShown: true,
        ),
        throwsArgumentError,
      );
    });

    test('zero amount throws ArgumentError', () {
      expect(
        () => ChildWithdrawalAuditParams(
          auditId: 'a1',
          operationId: 'op-1',
          householdId: 'hh-1',
          accountId: 'acc-1',
          amountMinorUnits: 0,
          reason: 'reason',
          beneficiary: HouseholdMemberRole.child,
          confirmedAt: now,
          confirmedBy: 'user-1',
          warningShown: true,
        ),
        throwsArgumentError,
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

  // ── Error types ─────────────────────────────────────────────────────────

  group('MissingProtectedWithdrawalAuditError', () {
    test('has accountId in message', () {
      final err = MissingProtectedWithdrawalAuditError('acc-protected');
      expect(err.toString(), contains('acc-protected'));
    });
  });

  group('AuditOperationMismatchError', () {
    test('has both operation IDs in message', () {
      final err = AuditOperationMismatchError(
        auditOperationId: 'op-audit',
        expectedOperationId: 'op-expected',
      );
      expect(err.toString(), contains('op-audit'));
      expect(err.toString(), contains('op-expected'));
    });
  });

  group('AuditAccountMismatchError', () {
    test('has both account IDs in message', () {
      final err = AuditAccountMismatchError(
        auditAccountId: 'acc-audit',
        expectedAccountId: 'acc-protected',
      );
      expect(err.toString(), contains('acc-audit'));
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
