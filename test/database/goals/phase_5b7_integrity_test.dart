/// Phase 5B.7 — atomic goal lifecycle, completion idempotency / rollback,
/// lifecycle workflow restrictions, and reversal balanced-ledger validation.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/goals/application/goal_use_cases.dart';
import 'package:family_money_manager/features/goals/data/drift_goal_repository.dart';
import 'package:family_money_manager/features/goals/data/goal_transfer_write_boundary.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftGoalRepository goalRepo;
  late CreateGoalUseCase createGoalUc;
  late FundGoalUseCase fundGoalUc;
  late CompleteGoalUseCase completeUc;
  late ArchiveGoalUseCase archiveUc;
  late RestoreGoalUseCase restoreUc;
  late ReverseGoalTransferUseCase reverseUc;

  const hh = 'hh-5b7';
  const hh2 = 'hh-5b7-b';

  Future<void> seedHh(String id) async {
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$id', 'HH', 'u1', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    await db.customStatement(
      "INSERT INTO household_members "
      "(id, household_id, display_name, role, is_archived, created_at, updated_at) "
      "VALUES ('mem-$id', '$id', 'Owner', 'primary_user', 0, "
      "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
  }

  Future<void> createAcct(String id, {String household = hh}) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: household,
        name: id,
        type: FinancialAccountType.personalCashWallet,
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 1,
        createdBy: 'test',
      ),
    );
  }

  Future<void> credit(
    String accountId,
    int amount, {
    String household = hh,
  }) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId:
            'inc-$accountId-$amount-${DateTime.now().microsecondsSinceEpoch}',
        householdId: household,
        destinationAccountId: accountId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'test',
        categoryCode: 'salary',
      ),
    );
  }

  Future<SavingsGoal> makeGoal({
    required String ikey,
    int target = 100000,
    String household = hh,
  }) async {
    final r = await createGoalUc.execute(
      goalName: 'G-$ikey',
      purpose: GoalPurpose.emergencyFund,
      currencyCode: 'EGP',
      targetMinorUnits: target,
      householdId: household,
      idempotencyKey: ikey,
    );
    expect(r, isA<AppOk<SavingsGoal>>());
    return (r as AppOk<SavingsGoal>).value;
  }

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).get()).first.read<int>('c');

  void wire({GoalLifecycleFailAfter failAfter = GoalLifecycleFailAfter.none}) {
    goalRepo = DriftGoalRepository(db, debugLifecycleFailAfter: failAfter);
    createGoalUc = CreateGoalUseCase(
      goalRepository: goalRepo,
      accountRepository: accountRepo,
      ledgerRepository: ledgerRepo,
    );
    fundGoalUc = FundGoalUseCase(
      goalRepository: goalRepo,
      accountRepository: accountRepo,
      ledgerRepository: ledgerRepo,
    );
    completeUc = CompleteGoalUseCase(goalRepo);
    archiveUc = ArchiveGoalUseCase(goalRepo);
    restoreUc = RestoreGoalUseCase(goalRepo);
    reverseUc = ReverseGoalTransferUseCase(goalRepository: goalRepo);
  }

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    wire();
    await seedHh(hh);
    await seedHh(hh2);
  });

  tearDown(() async => db.close());

  Future<void> assertUncompleted(String goalId) async {
    final row =
        (await db
                .customSelect(
                  "SELECT status, completed_at FROM goals WHERE id = '$goalId'",
                )
                .get())
            .first;
    expect(
      row.read<String>('status'),
      isIn(['active', 'targetReached']),
      reason: 'goal must remain non-completed after rollback',
    );
    expect(row.readNullable<String>('completed_at'), isNull);
    expect(
      await count(
        "SELECT COUNT(*) as c FROM goal_lifecycle_events "
        "WHERE goal_id = '$goalId' AND event_type = 'completed'",
      ),
      0,
    );
  }

  // ── COMP-IDMP-1..6 ────────────────────────────────────────────────────────

  test(
    'COMP-IDMP-1. Same key + equivalent payload → original result',
    () async {
      await createAcct('src-idmp1');
      await credit('src-idmp1', 200000);
      final goal = await makeGoal(ikey: 'ik-idmp1', target: 50000);
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: 'src-idmp1',
        amountMinorUnits: 50000,
        householdId: hh,
        idempotencyKey: 'ik-fund-idmp1',
      );

      final p = CompleteGoalParams(
        goalId: goal.id,
        householdId: hh,
        idempotencyKey: 'same-key-idmp1',
        actorMetadata: '{"actor":"a"}',
      );
      final r1 = await completeUc.execute(p);
      final r2 = await completeUc.execute(p);
      expect(r1, isA<AppOk<SavingsGoal>>());
      expect(r2, isA<AppOk<SavingsGoal>>());
      expect(
        (r1 as AppOk<SavingsGoal>).value.id,
        (r2 as AppOk<SavingsGoal>).value.id,
      );
      expect(
        await count(
          "SELECT COUNT(*) as c FROM goal_lifecycle_events "
          "WHERE goal_id = '${goal.id}' AND event_type = 'completed'",
        ),
        1,
      );
    },
  );

  test(
    'COMP-IDMP-2. Same key + conflicting payload → AppDuplicateConflict',
    () async {
      final goal = await makeGoal(ikey: 'ik-idmp2', target: 50000);
      final r1 = await completeUc.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: hh,
          idempotencyKey: 'conflict-key',
          earlyCompletion: true,
          earlyCompletionConfirmed: true,
          earlyCompletionReason: 'reason-a',
        ),
      );
      expect(r1, isA<AppOk<SavingsGoal>>());
      final r2 = await completeUc.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: hh,
          idempotencyKey: 'conflict-key',
          earlyCompletion: true,
          earlyCompletionConfirmed: true,
          earlyCompletionReason: 'reason-b',
        ),
      );
      expect(r2, isA<AppDuplicateConflict<SavingsGoal>>());
    },
  );

  test('COMP-IDMP-3. Same key in another household → isolated', () async {
    final g1 = await makeGoal(ikey: 'ik-idmp3a', target: 1000);
    final g2 = await createGoalUc.execute(
      goalName: 'G-idmp3b',
      purpose: GoalPurpose.other,
      currencyCode: 'EGP',
      targetMinorUnits: 1000,
      householdId: hh2,
      idempotencyKey: 'ik-idmp3b',
    );
    final goal2 = (g2 as AppOk<SavingsGoal>).value;

    const sharedKey = 'shared-complete-key';
    final r1 = await completeUc.execute(
      CompleteGoalParams(
        goalId: g1.id,
        householdId: hh,
        idempotencyKey: sharedKey,
        earlyCompletion: true,
        earlyCompletionConfirmed: true,
        earlyCompletionReason: 'hh1',
      ),
    );
    final r2 = await completeUc.execute(
      CompleteGoalParams(
        goalId: goal2.id,
        householdId: hh2,
        idempotencyKey: sharedKey,
        earlyCompletion: true,
        earlyCompletionConfirmed: true,
        earlyCompletionReason: 'hh2',
      ),
    );
    expect(r1, isA<AppOk<SavingsGoal>>());
    expect(r2, isA<AppOk<SavingsGoal>>());
    expect(
      await count(
        "SELECT COUNT(*) as c FROM goal_lifecycle_events "
        "WHERE idempotency_key = 'complete-$sharedKey'",
      ),
      2,
    );
  });

  test(
    'COMP-IDMP-4. Already-completed + exact original → idempotent success',
    () async {
      final goal = await makeGoal(ikey: 'ik-idmp4');
      final params = CompleteGoalParams(
        goalId: goal.id,
        householdId: hh,
        idempotencyKey: 'exact-again',
        earlyCompletion: true,
        earlyCompletionConfirmed: true,
        earlyCompletionReason: 'done early',
        actorMetadata: 'actor-x',
      );
      expect(await completeUc.execute(params), isA<AppOk<SavingsGoal>>());
      expect(await completeUc.execute(params), isA<AppOk<SavingsGoal>>());
      expect(
        await count(
          "SELECT COUNT(*) as c FROM goal_lifecycle_events WHERE goal_id = '${goal.id}'",
        ),
        1,
      );
    },
  );

  test(
    'COMP-IDMP-5. Already-completed + different completion type → conflict',
    () async {
      await createAcct('src-idmp5');
      await credit('src-idmp5', 200000);
      final goal = await makeGoal(ikey: 'ik-idmp5', target: 10000);
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: 'src-idmp5',
        amountMinorUnits: 10000,
        householdId: hh,
        idempotencyKey: 'ik-fund-idmp5',
      );
      expect(
        await completeUc.execute(
          CompleteGoalParams(
            goalId: goal.id,
            householdId: hh,
            idempotencyKey: 'type-a',
          ),
        ),
        isA<AppOk<SavingsGoal>>(),
      );
      final r2 = await completeUc.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: hh,
          idempotencyKey: 'type-b',
          earlyCompletion: true,
          earlyCompletionConfirmed: true,
          earlyCompletionReason: 'now early',
        ),
      );
      expect(r2, isA<AppDuplicateConflict<SavingsGoal>>());
    },
  );

  test(
    'COMP-IDMP-6. Already-completed + different reason → conflict',
    () async {
      final goal = await makeGoal(ikey: 'ik-idmp6');
      expect(
        await completeUc.execute(
          CompleteGoalParams(
            goalId: goal.id,
            householdId: hh,
            idempotencyKey: 'reason-a',
            earlyCompletion: true,
            earlyCompletionConfirmed: true,
            earlyCompletionReason: 'first-reason',
          ),
        ),
        isA<AppOk<SavingsGoal>>(),
      );
      final r2 = await completeUc.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: hh,
          idempotencyKey: 'reason-b',
          earlyCompletion: true,
          earlyCompletionConfirmed: true,
          earlyCompletionReason: 'second-reason',
        ),
      );
      expect(r2, isA<AppDuplicateConflict<SavingsGoal>>());
    },
  );

  // ── COMP-ROLL-1..6 ────────────────────────────────────────────────────────

  for (final entry in <(String, GoalLifecycleFailAfter)>[
    ('COMP-ROLL-1', GoalLifecycleFailAfter.afterGoalValidation),
    ('COMP-ROLL-2', GoalLifecycleFailAfter.afterBalanceCalculation),
    ('COMP-ROLL-3', GoalLifecycleFailAfter.afterGoalStatusUpdate),
    ('COMP-ROLL-4', GoalLifecycleFailAfter.afterCompletionTimestampUpdate),
    ('COMP-ROLL-5', GoalLifecycleFailAfter.afterLifecycleEventInsertion),
    ('COMP-ROLL-6', GoalLifecycleFailAfter.preCommit),
  ]) {
    test(
      '${entry.$1}. Fail after ${entry.$2.name} → full rollback; retry ok',
      () async {
        await createAcct('src-${entry.$1}');
        await credit('src-${entry.$1}', 200000);
        final goal = await makeGoal(ikey: 'ik-${entry.$1}', target: 20000);
        await fundGoalUc.execute(
          goalId: goal.id,
          sourceAccountId: 'src-${entry.$1}',
          amountMinorUnits: 20000,
          householdId: hh,
          idempotencyKey: 'ik-fund-${entry.$1}',
        );

        final opCountBefore = await count(
          'SELECT COUNT(*) as c FROM operations',
        );
        final entryCountBefore = await count(
          'SELECT COUNT(*) as c FROM ledger_entries',
        );
        final movCountBefore = await count(
          "SELECT COUNT(*) as c FROM goal_movements WHERE goal_id = '${goal.id}'",
        );

        wire(failAfter: entry.$2);
        final failing = await completeUc.execute(
          CompleteGoalParams(
            goalId: goal.id,
            householdId: hh,
            idempotencyKey: 'roll-${entry.$1}',
          ),
        );
        expect(failing, isA<AppPersistenceFailure<SavingsGoal>>());
        await assertUncompleted(goal.id);
        expect(
          await count('SELECT COUNT(*) as c FROM operations'),
          opCountBefore,
        );
        expect(
          await count('SELECT COUNT(*) as c FROM ledger_entries'),
          entryCountBefore,
        );
        expect(
          await count(
            "SELECT COUNT(*) as c FROM goal_movements WHERE goal_id = '${goal.id}'",
          ),
          movCountBefore,
        );

        wire();
        final retry = await completeUc.execute(
          CompleteGoalParams(
            goalId: goal.id,
            householdId: hh,
            idempotencyKey: 'roll-${entry.$1}',
          ),
        );
        expect(retry, isA<AppOk<SavingsGoal>>());
        expect(
          (retry as AppOk<SavingsGoal>).value.status,
          GoalStatus.completed,
        );
        expect(
          await count(
            "SELECT COUNT(*) as c FROM goal_lifecycle_events "
            "WHERE goal_id = '${goal.id}' AND event_type = 'completed'",
          ),
          1,
        );
      },
    );
  }

  // ── LIFE-1..8 ─────────────────────────────────────────────────────────────

  test('LIFE-1. updateGoalStatus active→completed rejected', () async {
    final goal = await makeGoal(ikey: 'ik-life1');
    final r = await goalRepo.updateGoalStatus(
      goalId: goal.id,
      status: GoalStatus.completed,
      completedAt: '2024-01-01T00:00:00Z',
    );
    expect(r, isA<AppValidationFailure<void>>());
    expect(
      (await goalRepo.findGoalById(goal.id) as AppOk<SavingsGoal?>)
          .value!
          .status,
      GoalStatus.active,
    );
  });

  test('LIFE-2. updateGoalStatus completed→active rejected', () async {
    final goal = await makeGoal(ikey: 'ik-life2');
    await completeUc.execute(
      CompleteGoalParams(
        goalId: goal.id,
        householdId: hh,
        earlyCompletion: true,
        earlyCompletionConfirmed: true,
        earlyCompletionReason: 'done',
      ),
    );
    final r = await goalRepo.updateGoalStatus(
      goalId: goal.id,
      status: GoalStatus.active,
    );
    expect(r, isA<AppValidationFailure<void>>());
    expect(
      (await goalRepo.findGoalById(goal.id) as AppOk<SavingsGoal?>)
          .value!
          .status,
      GoalStatus.completed,
    );
  });

  test('LIFE-3. updateGoalStatus active→archived rejected', () async {
    final goal = await makeGoal(ikey: 'ik-life3');
    final r = await goalRepo.updateGoalStatus(
      goalId: goal.id,
      status: GoalStatus.archived,
      archivedAt: '2024-01-01T00:00:00Z',
    );
    expect(r, isA<AppValidationFailure<void>>());
  });

  test('LIFE-4. updateGoalStatus archived→active rejected', () async {
    final goal = await makeGoal(ikey: 'ik-life4');
    await archiveUc.execute(goalId: goal.id, householdId: hh);
    final r = await goalRepo.updateGoalStatus(
      goalId: goal.id,
      status: GoalStatus.active,
    );
    expect(r, isA<AppValidationFailure<void>>());
    expect(
      (await goalRepo.findGoalById(goal.id) as AppOk<SavingsGoal?>)
          .value!
          .status,
      GoalStatus.archived,
    );
  });

  test('LIFE-5. raw SQL completed→active rejected by trigger', () async {
    final goal = await makeGoal(ikey: 'ik-life5');
    await completeUc.execute(
      CompleteGoalParams(
        goalId: goal.id,
        householdId: hh,
        earlyCompletion: true,
        earlyCompletionConfirmed: true,
        earlyCompletionReason: 'x',
      ),
    );
    await expectLater(
      db.customStatement(
        "UPDATE goals SET status = 'active' WHERE id = '${goal.id}'",
      ),
      throwsA(anything),
    );
  });

  test('LIFE-6. raw SQL archived→completed rejected by trigger', () async {
    final goal = await makeGoal(ikey: 'ik-life6');
    await archiveUc.execute(goalId: goal.id, householdId: hh);
    await expectLater(
      db.customStatement(
        "UPDATE goals SET status = 'completed' WHERE id = '${goal.id}'",
      ),
      throwsA(anything),
    );
  });

  test(
    'LIFE-7. ArchiveGoal atomic — fail after status rolls back event',
    () async {
      final goal = await makeGoal(ikey: 'ik-life7');
      wire(failAfter: GoalLifecycleFailAfter.afterGoalStatusUpdate);
      final failing = await archiveUc.execute(
        goalId: goal.id,
        householdId: hh,
        idempotencyKey: 'arch-life7',
      );
      expect(failing, isA<AppPersistenceFailure<void>>());
      expect(
        (await goalRepo.findGoalById(goal.id) as AppOk<SavingsGoal?>)
            .value!
            .status,
        GoalStatus.active,
      );
      expect(
        await count(
          "SELECT COUNT(*) as c FROM goal_lifecycle_events WHERE goal_id = '${goal.id}'",
        ),
        0,
      );

      wire();
      expect(
        await archiveUc.execute(
          goalId: goal.id,
          householdId: hh,
          idempotencyKey: 'arch-life7',
        ),
        isA<AppOk<void>>(),
      );
      expect(
        await count(
          "SELECT COUNT(*) as c FROM goal_lifecycle_events "
          "WHERE goal_id = '${goal.id}' AND event_type = 'archived'",
        ),
        1,
      );
    },
  );

  test(
    'LIFE-8. RestoreGoal atomic — fail after event rolls back status',
    () async {
      final goal = await makeGoal(ikey: 'ik-life8');
      await archiveUc.execute(goalId: goal.id, householdId: hh);

      wire(failAfter: GoalLifecycleFailAfter.afterLifecycleEventInsertion);
      final failing = await restoreUc.execute(
        goalId: goal.id,
        householdId: hh,
        idempotencyKey: 'rest-life8',
      );
      expect(failing, isA<AppPersistenceFailure<void>>());
      expect(
        (await goalRepo.findGoalById(goal.id) as AppOk<SavingsGoal?>)
            .value!
            .status,
        GoalStatus.archived,
      );
      expect(
        await count(
          "SELECT COUNT(*) as c FROM goal_lifecycle_events "
          "WHERE goal_id = '${goal.id}' AND event_type = 'restored'",
        ),
        0,
      );

      wire();
      expect(
        await restoreUc.execute(
          goalId: goal.id,
          householdId: hh,
          idempotencyKey: 'rest-life8',
        ),
        isA<AppOk<void>>(),
      );
      expect(
        (await goalRepo.findGoalById(goal.id) as AppOk<SavingsGoal?>)
            .value!
            .status,
        GoalStatus.active,
      );
      expect(
        await count(
          "SELECT COUNT(*) as c FROM goal_lifecycle_events "
          "WHERE goal_id = '${goal.id}' AND event_type = 'restored'",
        ),
        1,
      );
    },
  );

  // ── REV-BAL-1..10 + positive control ──────────────────────────────────────

  Future<
    (
      String goalId,
      String reserve,
      String src,
      String origMovId,
      String origOpId,
    )
  >
  seedFundedGoal(String tag) async {
    await createAcct('src-$tag');
    await credit('src-$tag', 50000);
    final goal = await makeGoal(ikey: 'ik-$tag', target: 100000);
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: 'src-$tag',
      amountMinorUnits: 5000,
      householdId: hh,
      idempotencyKey: 'ik-fund-$tag',
    );
    final mov =
        (await db
                .customSelect(
                  "SELECT id, transfer_operation_id FROM goal_movements "
                  "WHERE goal_id = '${goal.id}' AND movement_type = 'funding' LIMIT 1",
                )
                .get())
            .first;
    return (
      goal.id,
      goal.reserveAccountId,
      'src-$tag',
      mov.read<String>('id'),
      mov.read<String>('transfer_operation_id'),
    );
  }

  Future<void> insertRevOp({
    required String opId,
    required String origOpId,
    required String src,
    required String dst,
    int amount = 5000,
    String type = 'reversal',
  }) async {
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
      "description, source_account_id, destination_account_id, is_reversed) VALUES "
      "('$opId', '$hh', '$type', '2024-01-02', '2024-01-02T00:00:00Z', $amount, "
      "'EGP', 'test', '2024-01-02T00:00:00Z', '2024-01-02T00:00:00Z', "
      "'rev', '$src', '$dst', 0)",
    );
    await db.customStatement(
      "UPDATE operations SET is_reversed = 1, reversed_by = '$opId' WHERE id = '$origOpId'",
    );
  }

  Future<void> insertLeg({
    required String id,
    required String opId,
    required String accountId,
    required String direction,
    int amount = 5000,
    String currency = 'EGP',
    String? household,
  }) async {
    await db.customStatement(
      "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
      "direction, amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "('$id', '$opId', '${household ?? hh}', '$accountId', '$direction', $amount, "
      "'$currency', 'reversalDebit', '2024-01-02', '2024-01-02T00:00:00Z', 'test')",
    );
  }

  Future<void> expectRevRejected({
    required String movId,
    required String goalId,
    required String revOpId,
    required String origMovId,
  }) async {
    await expectLater(
      db.customStatement(
        "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
        "movement_type, created_at, reversal_of_movement_id) VALUES "
        "('$movId', '$goalId', '$hh', '$revOpId', 'reversal', "
        "'2024-01-02T00:00:00Z', '$origMovId')",
      ),
      throwsA(anything),
    );
  }

  test('REV-BAL-1. Missing debit leg rejected', () async {
    final (goalId, reserve, src, origMovId, origOpId) = await seedFundedGoal(
      'rb1',
    );
    await insertRevOp(
      opId: 'rev-rb1',
      origOpId: origOpId,
      src: reserve,
      dst: src,
    );
    await insertLeg(
      id: 'rev-rb1_c',
      opId: 'rev-rb1',
      accountId: src,
      direction: 'credit',
    );
    await expectRevRejected(
      movId: 'mov-rb1',
      goalId: goalId,
      revOpId: 'rev-rb1',
      origMovId: origMovId,
    );
  });

  test('REV-BAL-2. Missing credit leg rejected', () async {
    final (goalId, reserve, src, origMovId, origOpId) = await seedFundedGoal(
      'rb2',
    );
    await insertRevOp(
      opId: 'rev-rb2',
      origOpId: origOpId,
      src: reserve,
      dst: src,
    );
    await insertLeg(
      id: 'rev-rb2_d',
      opId: 'rev-rb2',
      accountId: reserve,
      direction: 'debit',
    );
    await expectRevRejected(
      movId: 'mov-rb2',
      goalId: goalId,
      revOpId: 'rev-rb2',
      origMovId: origMovId,
    );
  });

  test('REV-BAL-3. Operation type != reversal rejected', () async {
    final (goalId, reserve, src, origMovId, origOpId) = await seedFundedGoal(
      'rb3',
    );
    await insertRevOp(
      opId: 'rev-rb3',
      origOpId: origOpId,
      src: reserve,
      dst: src,
      type: 'transfer',
    );
    await insertLeg(
      id: 'd',
      opId: 'rev-rb3',
      accountId: reserve,
      direction: 'debit',
    );
    await insertLeg(
      id: 'c',
      opId: 'rev-rb3',
      accountId: src,
      direction: 'credit',
    );
    await expectRevRejected(
      movId: 'mov-rb3',
      goalId: goalId,
      revOpId: 'rev-rb3',
      origMovId: origMovId,
    );
  });

  test('REV-BAL-4. Unequal amounts rejected', () async {
    final (goalId, reserve, src, origMovId, origOpId) = await seedFundedGoal(
      'rb4',
    );
    await insertRevOp(
      opId: 'rev-rb4',
      origOpId: origOpId,
      src: reserve,
      dst: src,
    );
    await insertLeg(
      id: 'd',
      opId: 'rev-rb4',
      accountId: reserve,
      direction: 'debit',
      amount: 5000,
    );
    await insertLeg(
      id: 'c',
      opId: 'rev-rb4',
      accountId: src,
      direction: 'credit',
      amount: 4000,
    );
    await expectRevRejected(
      movId: 'mov-rb4',
      goalId: goalId,
      revOpId: 'rev-rb4',
      origMovId: origMovId,
    );
  });

  test('REV-BAL-5. Entry accounts not inverse of original rejected', () async {
    final (goalId, reserve, src, origMovId, origOpId) = await seedFundedGoal(
      'rb5',
    );
    await createAcct('other-rb5');
    await insertRevOp(
      opId: 'rev-rb5',
      origOpId: origOpId,
      src: reserve,
      dst: src,
    );
    // Same direction as original (not inverse).
    await insertLeg(
      id: 'd',
      opId: 'rev-rb5',
      accountId: src,
      direction: 'debit',
    );
    await insertLeg(
      id: 'c',
      opId: 'rev-rb5',
      accountId: reserve,
      direction: 'credit',
    );
    await expectRevRejected(
      movId: 'mov-rb5',
      goalId: goalId,
      revOpId: 'rev-rb5',
      origMovId: origMovId,
    );
  });

  test('REV-BAL-6. Currency mismatch rejected', () async {
    final (goalId, reserve, src, origMovId, origOpId) = await seedFundedGoal(
      'rb6',
    );
    await insertRevOp(
      opId: 'rev-rb6',
      origOpId: origOpId,
      src: reserve,
      dst: src,
    );
    await insertLeg(
      id: 'd',
      opId: 'rev-rb6',
      accountId: reserve,
      direction: 'debit',
      currency: 'USD',
    );
    await insertLeg(
      id: 'c',
      opId: 'rev-rb6',
      accountId: src,
      direction: 'credit',
      currency: 'USD',
    );
    await expectRevRejected(
      movId: 'mov-rb6',
      goalId: goalId,
      revOpId: 'rev-rb6',
      origMovId: origMovId,
    );
  });

  test('REV-BAL-7. Missing reversal_of_movement_id rejected', () async {
    final (goalId, reserve, src, origMovId, origOpId) = await seedFundedGoal(
      'rb7',
    );
    await insertRevOp(
      opId: 'rev-rb7',
      origOpId: origOpId,
      src: reserve,
      dst: src,
    );
    await insertLeg(
      id: 'd',
      opId: 'rev-rb7',
      accountId: reserve,
      direction: 'debit',
    );
    await insertLeg(
      id: 'c',
      opId: 'rev-rb7',
      accountId: src,
      direction: 'credit',
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
        "movement_type, created_at, reversal_of_movement_id) VALUES "
        "('mov-rb7', '$goalId', '$hh', 'rev-rb7', 'reversal', "
        "'2024-01-02T00:00:00Z', NULL)",
      ),
      throwsA(anything),
    );
    // silence unused
    expect(origMovId, isNotEmpty);
  });

  test('REV-BAL-8. Reversal op not linked via reversed_by rejected', () async {
    final (goalId, reserve, src, origMovId, origOpId) = await seedFundedGoal(
      'rb8',
    );
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
      "description, source_account_id, destination_account_id, is_reversed) VALUES "
      "('rev-rb8', '$hh', 'reversal', '2024-01-02', '2024-01-02T00:00:00Z', 5000, "
      "'EGP', 'test', '2024-01-02T00:00:00Z', '2024-01-02T00:00:00Z', "
      "'rev', '$reserve', '$src', 0)",
    );
    // Mark original reversed by a DIFFERENT id.
    await db.customStatement(
      "UPDATE operations SET is_reversed = 1, reversed_by = 'other-rev' "
      "WHERE id = '$origOpId'",
    );
    await insertLeg(
      id: 'd',
      opId: 'rev-rb8',
      accountId: reserve,
      direction: 'debit',
    );
    await insertLeg(
      id: 'c',
      opId: 'rev-rb8',
      accountId: src,
      direction: 'credit',
    );
    await expectRevRejected(
      movId: 'mov-rb8',
      goalId: goalId,
      revOpId: 'rev-rb8',
      origMovId: origMovId,
    );
  });

  test('REV-BAL-9. Household mismatch rejected', () async {
    final (goalId, reserve, src, origMovId, origOpId) = await seedFundedGoal(
      'rb9',
    );
    await insertRevOp(
      opId: 'rev-rb9',
      origOpId: origOpId,
      src: reserve,
      dst: src,
    );
    await db.customStatement(
      'DROP TRIGGER IF EXISTS fk_ledger_entry_operation_id',
    );
    await insertLeg(
      id: 'd',
      opId: 'rev-rb9',
      accountId: reserve,
      direction: 'debit',
      household: hh2,
    );
    await insertLeg(
      id: 'c',
      opId: 'rev-rb9',
      accountId: src,
      direction: 'credit',
      household: hh2,
    );
    await expectRevRejected(
      movId: 'mov-rb9',
      goalId: goalId,
      revOpId: 'rev-rb9',
      origMovId: origMovId,
    );
  });

  test('REV-BAL-10. Second reversal movement for same original rejected', () async {
    final (goalId, reserve, src, origMovId, origOpId) = await seedFundedGoal(
      'rb10',
    );
    // First reversal via use case (positive path).
    final rev1 = await reverseUc.execute(
      originalOperationId: origOpId,
      reversalOperationId: 'rev-rb10-1',
      householdId: hh,
      effectiveDate: '2024-01-02',
      createdBy: 'test',
      idempotencyKey: 'ik-rev-rb10-1',
    );
    expect(rev1, isA<AppOk<void>>());

    // Attempt a second raw reversal movement referencing same original.
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
      "description, source_account_id, destination_account_id, is_reversed) VALUES "
      "('rev-rb10-2', '$hh', 'reversal', '2024-01-03', '2024-01-03T00:00:00Z', 5000, "
      "'EGP', 'test', '2024-01-03T00:00:00Z', '2024-01-03T00:00:00Z', "
      "'rev2', '$reserve', '$src', 0)",
    );
    await insertLeg(
      id: 'd2',
      opId: 'rev-rb10-2',
      accountId: reserve,
      direction: 'debit',
    );
    await insertLeg(
      id: 'c2',
      opId: 'rev-rb10-2',
      accountId: src,
      direction: 'credit',
    );
    await expectRevRejected(
      movId: 'mov-rb10-2',
      goalId: goalId,
      revOpId: 'rev-rb10-2',
      origMovId: origMovId,
    );
  });

  test('REV-BAL-11. Positive balanced reversal control accepted', () async {
    final seeded = await seedFundedGoal('rb11');
    final origOpId = seeded.$5;
    final rev = await reverseUc.execute(
      originalOperationId: origOpId,
      reversalOperationId: 'rev-rb11',
      householdId: hh,
      effectiveDate: '2024-01-02',
      createdBy: 'test',
      idempotencyKey: 'ik-rev-rb11',
    );
    expect(rev, isA<AppOk<void>>());
    expect(
      await count(
        "SELECT COUNT(*) as c FROM goal_movements "
        "WHERE transfer_operation_id = 'rev-rb11' AND movement_type = 'reversal'",
      ),
      1,
    );
  });
}
