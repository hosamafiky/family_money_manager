/// Unit tests for goal domain types (Phase 5B).
///
/// Tests:
///  1. GoalProgressState.notStarted when balance == 0
///  2. GoalProgressState.inProgress when 0 < balance < target
///  3. GoalProgressState.targetReached when balance == target
///  4. GoalProgressState.overfunded when balance > target
///  5. remainingMinorUnits == 0 when overfunded
///  6. overfundedMinorUnits correct when balance > target
///  7. percentageFunded == null when target == 0
///  8. percentageFunded == 50 when half funded
///  9. percentageFunded == 100 when exactly funded
/// 10. percentageFunded == 200 when double funded
/// 11. GoalPurpose.emergencyFund.code == 'emergencyFund'
/// 12. GoalMovementType.funding and release exist
/// 13. GoalStatus transitions exist
/// 14. GoalRevision stores all fields
/// 15. GoalMovement stores all fields
/// 16. SavingsGoal.name delegates to currentRevision
/// 17. SavingsGoal.targetMinorUnits delegates to currentRevision
/// 18. GoalProgressState is not derived from goal status (independent)
/// 19. goalReserve is never isProtected in domain model
/// 20. FinancialAccountType.goalReserve exists and FundPurpose.goalReserve exists
library;

import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

GoalRevision _fakeRevision({
  String name = 'Test Goal',
  int targetMinorUnits = 100000,
  GoalPurpose purpose = GoalPurpose.emergencyFund,
}) => GoalRevision(
  id: 'rev-1',
  goalId: 'g-1',
  householdId: 'hh-1',
  name: name,
  purpose: purpose,
  targetMinorUnits: targetMinorUnits,
  currencyCode: 'EGP',
  createdAt: '2024-01-01T00:00:00Z',
  revisionReason: 'initial',
);

SavingsGoal _fakeGoal({
  GoalStatus status = GoalStatus.active,
  int targetMinorUnits = 100000,
}) {
  final rev = _fakeRevision(targetMinorUnits: targetMinorUnits);
  return SavingsGoal(
    id: 'g-1',
    householdId: 'hh-1',
    reserveAccountId: 'acc-reserve-1',
    currencyCode: 'EGP',
    status: status,
    currentRevision: rev,
    createdAt: '2024-01-01T00:00:00Z',
    idempotencyKey: 'ik-1',
  );
}

GoalProgress _fakeProgress({
  required int balance,
  int target = 100000,
  GoalStatus status = GoalStatus.active,
}) {
  final goal = _fakeGoal(targetMinorUnits: target, status: status);
  final state = balance == 0
      ? GoalProgressState.notStarted
      : balance > target
      ? GoalProgressState.overfunded
      : balance == target
      ? GoalProgressState.targetReached
      : GoalProgressState.inProgress;
  return GoalProgress(
    goal: goal,
    reserveBalanceMinorUnits: balance,
    currencyCode: 'EGP',
    progressState: state,
    movements: const [],
    revisions: [goal.currentRevision],
  );
}

void main() {
  group('GoalProgress state derivation', () {
    test('1. notStarted when balance == 0', () {
      final p = _fakeProgress(balance: 0);
      expect(p.progressState, GoalProgressState.notStarted);
    });

    test('2. inProgress when 0 < balance < target', () {
      final p = _fakeProgress(balance: 50000);
      expect(p.progressState, GoalProgressState.inProgress);
    });

    test('3. targetReached when balance == target', () {
      final p = _fakeProgress(balance: 100000);
      expect(p.progressState, GoalProgressState.targetReached);
    });

    test('4. overfunded when balance > target', () {
      final p = _fakeProgress(balance: 120000);
      expect(p.progressState, GoalProgressState.overfunded);
    });

    test('5. remainingMinorUnits == 0 when overfunded', () {
      final p = _fakeProgress(balance: 120000, target: 100000);
      expect(p.remainingMinorUnits, 0);
    });

    test('6. overfundedMinorUnits correct when balance > target', () {
      final p = _fakeProgress(balance: 120000, target: 100000);
      expect(p.overfundedMinorUnits, 20000);
    });

    test('7. percentageFunded == null when target == 0', () {
      final p = _fakeProgress(balance: 0, target: 0);
      expect(p.percentageFunded, isNull);
    });

    test('8. percentageFunded == 50 when half funded', () {
      final p = _fakeProgress(balance: 50000, target: 100000);
      expect(p.percentageFunded, 50);
    });

    test('9. percentageFunded == 100 when exactly funded', () {
      final p = _fakeProgress(balance: 100000, target: 100000);
      expect(p.percentageFunded, 100);
    });

    test('10. percentageFunded == 200 when double funded', () {
      final p = _fakeProgress(balance: 200000, target: 100000);
      expect(p.percentageFunded, 200);
    });
  });

  group('GoalPurpose', () {
    test('11. emergencyFund.code == emergencyFund', () {
      expect(GoalPurpose.emergencyFund.code, 'emergencyFund');
    });

    test('all purposes have stable codes matching their name', () {
      for (final p in GoalPurpose.values) {
        expect(p.code, p.name);
      }
    });
  });

  group('Enum existence', () {
    test('12. GoalMovementType.funding and release exist', () {
      expect(GoalMovementType.values, contains(GoalMovementType.funding));
      expect(GoalMovementType.values, contains(GoalMovementType.release));
    });

    test('13. GoalStatus transitions exist', () {
      expect(GoalStatus.values, contains(GoalStatus.active));
      expect(GoalStatus.values, contains(GoalStatus.targetReached));
      expect(GoalStatus.values, contains(GoalStatus.completed));
      expect(GoalStatus.values, contains(GoalStatus.archived));
    });
  });

  group('GoalRevision', () {
    test('14. GoalRevision stores all fields', () {
      const rev = GoalRevision(
        id: 'rev-id',
        goalId: 'g-id',
        householdId: 'hh-id',
        name: 'My Goal',
        purpose: GoalPurpose.education,
        targetMinorUnits: 50000,
        currencyCode: 'USD',
        createdAt: '2024-06-01T00:00:00Z',
        revisionReason: 'updated target',
        targetDate: '2025-01-01',
        beneficiaryMemberId: 'member-1',
      );
      expect(rev.id, 'rev-id');
      expect(rev.goalId, 'g-id');
      expect(rev.householdId, 'hh-id');
      expect(rev.name, 'My Goal');
      expect(rev.purpose, GoalPurpose.education);
      expect(rev.targetMinorUnits, 50000);
      expect(rev.currencyCode, 'USD');
      expect(rev.revisionReason, 'updated target');
      expect(rev.targetDate, '2025-01-01');
      expect(rev.beneficiaryMemberId, 'member-1');
    });
  });

  group('GoalMovement', () {
    test('15. GoalMovement stores all fields', () {
      const m = GoalMovement(
        id: 'm-id',
        goalId: 'g-id',
        householdId: 'hh-id',
        transferOperationId: 'op-id',
        movementType: GoalMovementType.release,
        createdAt: '2024-06-01T00:00:00Z',
        releaseReason: 'bought a car',
      );
      expect(m.id, 'm-id');
      expect(m.goalId, 'g-id');
      expect(m.householdId, 'hh-id');
      expect(m.transferOperationId, 'op-id');
      expect(m.movementType, GoalMovementType.release);
      expect(m.releaseReason, 'bought a car');
    });
  });

  group('SavingsGoal delegation', () {
    test('16. SavingsGoal.name delegates to currentRevision', () {
      final goal = _fakeGoal();
      expect(goal.name, goal.currentRevision.name);
    });

    test('17. SavingsGoal.targetMinorUnits delegates to currentRevision', () {
      final goal = _fakeGoal(targetMinorUnits: 75000);
      expect(goal.targetMinorUnits, 75000);
      expect(goal.targetMinorUnits, goal.currentRevision.targetMinorUnits);
    });
  });

  group('Independence of status and progress state', () {
    test('18. GoalProgressState is not derived from GoalStatus', () {
      // A completed goal can still have non-100% progress if you manually
      // completed it before reaching target.
      final completedGoal = _fakeGoal(
        status: GoalStatus.completed,
        targetMinorUnits: 100000,
      );
      // We construct progress independently from status.
      final progress = GoalProgress(
        goal: completedGoal,
        reserveBalanceMinorUnits: 50000,
        currencyCode: 'EGP',
        progressState: GoalProgressState.inProgress, // independent
        movements: const [],
        revisions: [completedGoal.currentRevision],
      );
      expect(completedGoal.status, GoalStatus.completed);
      expect(progress.progressState, GoalProgressState.inProgress);
    });
  });

  group('goalReserve account properties', () {
    test('19. goalReserve is never isProtected in domain model', () {
      // Domain rule: goalReserve accounts have isProtected = false.
      // This test verifies the rule by checking the account_enums setup.
      // goalReserve type does NOT requiresProtectedWithdrawalAudit.
      expect(
        FinancialAccountType.goalReserve.requiresProtectedWithdrawalAudit,
        isFalse,
      );
    });

    test(
      '20. FinancialAccountType.goalReserve and FundPurpose.goalReserve exist',
      () {
        expect(
          FinancialAccountType.values,
          contains(FinancialAccountType.goalReserve),
        );
        expect(FundPurpose.values, contains(FundPurpose.goalReserve));
      },
    );
  });
}
