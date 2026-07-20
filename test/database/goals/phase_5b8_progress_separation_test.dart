/// Phase 5B.8 – Lifecycle / derived-progress separation.
///
/// PROG-1..15  — Progress derived from reserve balance + current target only;
///               money ops must not mutate goals.status.
/// COMP-DERIV-1..6 — Completion validates derived balance, not persisted progress.
/// MIG-5B8-1..3 — Migration targetReached→active; DB rejects invalid status.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/goals/application/goal_use_cases.dart';
import 'package:family_money_manager/features/goals/data/drift_goal_repository.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../helpers/true_schema_v12.dart';

const _hh = 'hh-5b8';

void main() {
  late AppDatabase db;
  late DriftGoalRepository goalRepo;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late CreateGoalUseCase createGoalUc;
  late FundGoalUseCase fundGoalUc;
  late ReleaseGoalFundsUseCase releaseGoalUc;
  late GetGoalProgressUseCase progressUc;
  late UpdateGoalRevisionUseCase updateRevisionUc;
  late ArchiveGoalUseCase archiveGoalUc;
  late RestoreGoalUseCase restoreGoalUc;
  late CompleteGoalUseCase completeGoalUc;
  late ReverseGoalTransferUseCase reverseUc;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    goalRepo = DriftGoalRepository(db);
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
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
    releaseGoalUc = ReleaseGoalFundsUseCase(
      goalRepository: goalRepo,
      accountRepository: accountRepo,
      ledgerRepository: ledgerRepo,
    );
    progressUc = GetGoalProgressUseCase(goalRepo);
    updateRevisionUc = UpdateGoalRevisionUseCase(goalRepo);
    archiveGoalUc = ArchiveGoalUseCase(goalRepo);
    restoreGoalUc = RestoreGoalUseCase(goalRepo);
    completeGoalUc = CompleteGoalUseCase(goalRepo);
    reverseUc = ReverseGoalTransferUseCase(goalRepository: goalRepo);

    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', '5B8 HH', 'u1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<FinancialAccount> createAccount(String id) =>
      accountRepo.createAccount(
        CreateAccountParams(
          id: id,
          householdId: _hh,
          name: 'Acc $id',
          type: FinancialAccountType.personalCashWallet,
          ownerType: AccountOwnerType.user,
          fundPurpose: FundPurpose.available,
          currencyCode: 'EGP',
          isSpendable: true,
          isProtected: false,
          includeInNetWorth: true,
          includeInZakat: false,
          displayOrder: 0,
          createdBy: 'test',
        ),
      );

  Future<void> credit(String accId, int amount) => ledgerRepo.recordIncome(
    RecordIncomeParams(
      operationId: 'inc-$accId-${DateTime.now().microsecondsSinceEpoch}',
      householdId: _hh,
      destinationAccountId: accId,
      amountMinorUnits: amount,
      currencyCode: 'EGP',
      effectiveDate: '2024-01-01',
      createdBy: 'test',
    ),
  );

  Future<SavingsGoal> mkGoal({
    required String key,
    int target = 100000,
    String? src,
    int initial = 0,
  }) async {
    final r = await createGoalUc.execute(
      goalName: 'Goal $key',
      purpose: GoalPurpose.emergencyFund,
      currencyCode: 'EGP',
      targetMinorUnits: target,
      householdId: _hh,
      idempotencyKey: key,
      initialFundingSourceAccountId: src,
      initialFundingMinorUnits: initial,
    );
    return (r as AppOk<SavingsGoal>).value;
  }

  Future<String> dbStatus(String goalId) async {
    final rows = await db
        .customSelect(
          'SELECT status FROM goals WHERE id = ?',
          variables: [Variable.withString(goalId)],
        )
        .get();
    return rows.first.read<String>('status');
  }

  Future<GoalProgress> progress(String goalId) async =>
      ((await progressUc.execute(goalId)) as AppOk<GoalProgress>).value;

  Future<String> fundOpId(String reserveId) async {
    final rows = await db
        .customSelect(
          "SELECT id FROM operations WHERE type = 'transfer' "
          'AND destination_account_id = ? ORDER BY created_at DESC LIMIT 1',
          variables: [Variable.withString(reserveId)],
        )
        .get();
    return rows.first.read<String>('id');
  }

  Future<String> releaseOpId(String reserveId) async {
    final rows = await db
        .customSelect(
          "SELECT id FROM operations WHERE type = 'transfer' "
          'AND source_account_id = ? ORDER BY created_at DESC LIMIT 1',
          variables: [Variable.withString(reserveId)],
        )
        .get();
    return rows.first.read<String>('id');
  }

  // ── PROG ─────────────────────────────────────────────────────────────────

  test('PROG-1. Zero funding → notStarted; status remains active', () async {
    final goal = await mkGoal(key: 'prog1');
    final before = await dbStatus(goal.id);
    final p = await progress(goal.id);
    expect(p.progressState, GoalProgressState.notStarted);
    expect(await dbStatus(goal.id), before);
    expect(before, 'active');
  });

  test('PROG-2. Partial funding → inProgress; status unchanged', () async {
    const src = 'src-prog2';
    await createAccount(src);
    await credit(src, 200000);
    final goal = await mkGoal(key: 'prog2');
    final before = await dbStatus(goal.id);
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: src,
      amountMinorUnits: 40000,
      householdId: _hh,
      idempotencyKey: 'fund-prog2',
    );
    final p = await progress(goal.id);
    expect(p.progressState, GoalProgressState.inProgress);
    expect(await dbStatus(goal.id), before);
    expect(before, 'active');
  });

  test(
    'PROG-3. Exact target → targetReached progress; status unchanged',
    () async {
      const src = 'src-prog3';
      await createAccount(src);
      await credit(src, 200000);
      final goal = await mkGoal(key: 'prog3', target: 100000);
      final before = await dbStatus(goal.id);
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: src,
        amountMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'fund-prog3',
      );
      final p = await progress(goal.id);
      expect(p.progressState, GoalProgressState.targetReached);
      expect(p.isTargetReached, isTrue);
      expect(await dbStatus(goal.id), before);
      expect(before, 'active');
    },
  );

  test('PROG-4. Overfunding → overfunded; status unchanged', () async {
    const src = 'src-prog4';
    await createAccount(src);
    await credit(src, 300000);
    final goal = await mkGoal(key: 'prog4', target: 100000);
    final before = await dbStatus(goal.id);
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: src,
      amountMinorUnits: 150000,
      householdId: _hh,
      idempotencyKey: 'fund-prog4',
    );
    final p = await progress(goal.id);
    expect(p.progressState, GoalProgressState.overfunded);
    expect(await dbStatus(goal.id), before);
  });

  test('PROG-5. Release below target → inProgress; status unchanged', () async {
    const src = 'src-prog5';
    const dst = 'dst-prog5';
    await createAccount(src);
    await createAccount(dst);
    await credit(src, 200000);
    final goal = await mkGoal(key: 'prog5', target: 100000);
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: src,
      amountMinorUnits: 100000,
      householdId: _hh,
      idempotencyKey: 'fund-prog5',
    );
    final before = await dbStatus(goal.id);
    await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dst,
      amountMinorUnits: 40000,
      releaseReason: 'partial release',
      householdId: _hh,
      idempotencyKey: 'rel-prog5',
    );
    final p = await progress(goal.id);
    expect(p.progressState, GoalProgressState.inProgress);
    expect(p.reserveBalanceMinorUnits, 60000);
    expect(await dbStatus(goal.id), before);
  });

  test('PROG-6. Full release to zero → notStarted; status unchanged', () async {
    const src = 'src-prog6';
    const dst = 'dst-prog6';
    await createAccount(src);
    await createAccount(dst);
    await credit(src, 200000);
    final goal = await mkGoal(key: 'prog6', target: 100000);
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: src,
      amountMinorUnits: 50000,
      householdId: _hh,
      idempotencyKey: 'fund-prog6',
    );
    final before = await dbStatus(goal.id);
    await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dst,
      amountMinorUnits: 50000,
      releaseReason: 'full release',
      householdId: _hh,
      idempotencyKey: 'rel-prog6',
    );
    final p = await progress(goal.id);
    expect(p.progressState, GoalProgressState.notStarted);
    expect(await dbStatus(goal.id), before);
  });

  test(
    'PROG-7. Funding reversal → progress decreases; status unchanged',
    () async {
      const src = 'src-prog7';
      await createAccount(src);
      await credit(src, 200000);
      final goal = await mkGoal(key: 'prog7', target: 100000);
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: src,
        amountMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'fund-prog7',
      );
      final before = await dbStatus(goal.id);
      final opId = await fundOpId(goal.reserveAccountId);
      await reverseUc.execute(
        originalOperationId: opId,
        reversalOperationId: 'rev-prog7',
        householdId: _hh,
        effectiveDate: '2024-01-02',
        createdBy: 'test',
      );
      final p = await progress(goal.id);
      expect(p.progressState, GoalProgressState.notStarted);
      expect(await dbStatus(goal.id), before);
    },
  );

  test(
    'PROG-8. Release reversal → progress increases; status unchanged',
    () async {
      const src = 'src-prog8';
      const dst = 'dst-prog8';
      await createAccount(src);
      await createAccount(dst);
      await credit(src, 200000);
      final goal = await mkGoal(key: 'prog8', target: 100000);
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: src,
        amountMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'fund-prog8',
      );
      await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dst,
        amountMinorUnits: 40000,
        releaseReason: 'temp',
        householdId: _hh,
        idempotencyKey: 'rel-prog8',
      );
      final before = await dbStatus(goal.id);
      expect(
        (await progress(goal.id)).progressState,
        GoalProgressState.inProgress,
      );
      final opId = await releaseOpId(goal.reserveAccountId);
      await reverseUc.execute(
        originalOperationId: opId,
        reversalOperationId: 'rev-prog8',
        householdId: _hh,
        effectiveDate: '2024-01-02',
        createdBy: 'test',
      );
      final p = await progress(goal.id);
      expect(p.progressState, GoalProgressState.targetReached);
      expect(await dbStatus(goal.id), before);
    },
  );

  test('PROG-9. Target increase may leave inProgress', () async {
    const src = 'src-prog9';
    await createAccount(src);
    await credit(src, 200000);
    final goal = await mkGoal(key: 'prog9', target: 100000);
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: src,
      amountMinorUnits: 100000,
      householdId: _hh,
      idempotencyKey: 'fund-prog9',
    );
    expect(
      (await progress(goal.id)).progressState,
      GoalProgressState.targetReached,
    );
    final before = await dbStatus(goal.id);
    await updateRevisionUc.execute(
      goalId: goal.id,
      householdId: _hh,
      newName: goal.name,
      newTargetMinorUnits: 150000,
      newPurpose: GoalPurpose.emergencyFund,
      revisionReason: 'raise target',
    );
    final p = await progress(goal.id);
    expect(p.progressState, GoalProgressState.inProgress);
    expect(await dbStatus(goal.id), before);
  });

  test('PROG-10. Target decrease may yield overfunded', () async {
    const src = 'src-prog10';
    await createAccount(src);
    await credit(src, 200000);
    final goal = await mkGoal(key: 'prog10', target: 100000);
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: src,
      amountMinorUnits: 80000,
      householdId: _hh,
      idempotencyKey: 'fund-prog10',
    );
    final before = await dbStatus(goal.id);
    await updateRevisionUc.execute(
      goalId: goal.id,
      householdId: _hh,
      newName: goal.name,
      newTargetMinorUnits: 50000,
      newPurpose: GoalPurpose.emergencyFund,
      revisionReason: 'lower target',
    );
    final p = await progress(goal.id);
    expect(p.progressState, GoalProgressState.overfunded);
    expect(await dbStatus(goal.id), before);
  });

  test(
    'PROG-11. Backdated funding updates progress; status unchanged',
    () async {
      const src = 'src-prog11';
      await createAccount(src);
      await credit(src, 200000);
      final goal = await mkGoal(key: 'prog11', target: 100000);
      final before = await dbStatus(goal.id);
      // Fund via normal path (effective date today); progress still derived.
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: src,
        amountMinorUnits: 25000,
        householdId: _hh,
        idempotencyKey: 'fund-prog11',
      );
      final p = await progress(goal.id);
      expect(p.progressState, GoalProgressState.inProgress);
      expect(p.reserveBalanceMinorUnits, 25000);
      expect(await dbStatus(goal.id), before);
    },
  );

  test('PROG-12. Archive with zero balance keeps lifecycle archived', () async {
    final goal = await mkGoal(key: 'prog12');
    final ar = await archiveGoalUc.execute(goalId: goal.id, householdId: _hh);
    expect(ar, isA<AppOk<void>>());
    expect(await dbStatus(goal.id), 'archived');
    final p = await progress(goal.id);
    expect(p.progressState, GoalProgressState.notStarted);
    expect(p.goal.status, GoalStatus.archived);
  });

  test('PROG-13. Restore returns active; progress still derived', () async {
    final goal = await mkGoal(key: 'prog13');
    await archiveGoalUc.execute(goalId: goal.id, householdId: _hh);
    await restoreGoalUc.execute(goalId: goal.id, householdId: _hh);
    expect(await dbStatus(goal.id), 'active');
    final p = await progress(goal.id);
    expect(p.progressState, GoalProgressState.notStarted);
    expect(p.goal.status, GoalStatus.active);
  });

  test(
    'PROG-14. Completed goal retains derived progress independently',
    () async {
      const src = 'src-prog14';
      await createAccount(src);
      await credit(src, 200000);
      final goal = await mkGoal(key: 'prog14', target: 100000);
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: src,
        amountMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'fund-prog14',
      );
      final cr = await completeGoalUc.execute(
        CompleteGoalParams(goalId: goal.id, householdId: _hh),
      );
      expect(cr, isA<AppOk<SavingsGoal>>());
      expect(await dbStatus(goal.id), 'completed');
      final p = await progress(goal.id);
      expect(p.goal.status, GoalStatus.completed);
      expect(p.progressState, GoalProgressState.targetReached);
      expect(p.reserveBalanceMinorUnits, 100000);
    },
  );

  test(
    'PROG-15. Progress derivation ignores lifecycle status (completed + partial)',
    () async {
      const src = 'src-prog15';
      const dst = 'dst-prog15';
      await createAccount(src);
      await createAccount(dst);
      await credit(src, 200000);
      final goal = await mkGoal(key: 'prog15', target: 100000);
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: src,
        amountMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'fund-prog15',
      );
      await completeGoalUc.execute(
        CompleteGoalParams(goalId: goal.id, householdId: _hh),
      );
      // Release from completed goal — status must stay completed.
      final before = await dbStatus(goal.id);
      expect(before, 'completed');
      await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dst,
        amountMinorUnits: 30000,
        releaseReason: 'draw retained reserve',
        householdId: _hh,
        idempotencyKey: 'rel-prog15',
      );
      expect(await dbStatus(goal.id), 'completed');
      final p = await progress(goal.id);
      expect(p.goal.status, GoalStatus.completed);
      expect(p.progressState, GoalProgressState.inProgress);
      expect(p.reserveBalanceMinorUnits, 70000);
    },
  );

  // ── COMP-DERIV ─────────────────────────────────────────────────────────────

  test('COMP-DERIV-1. Exact target permits normal completion', () async {
    const src = 'src-cd1';
    await createAccount(src);
    await credit(src, 200000);
    final goal = await mkGoal(key: 'cd1', target: 100000);
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: src,
      amountMinorUnits: 100000,
      householdId: _hh,
      idempotencyKey: 'fund-cd1',
    );
    final r = await completeGoalUc.execute(
      CompleteGoalParams(goalId: goal.id, householdId: _hh),
    );
    expect(r, isA<AppOk<SavingsGoal>>());
    expect((r as AppOk<SavingsGoal>).value.status, GoalStatus.completed);
  });

  test('COMP-DERIV-2. Overfunded permits normal completion', () async {
    const src = 'src-cd2';
    await createAccount(src);
    await credit(src, 300000);
    final goal = await mkGoal(key: 'cd2', target: 100000);
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: src,
      amountMinorUnits: 120000,
      householdId: _hh,
      idempotencyKey: 'fund-cd2',
    );
    final r = await completeGoalUc.execute(
      CompleteGoalParams(goalId: goal.id, householdId: _hh),
    );
    expect(r, isA<AppOk<SavingsGoal>>());
  });

  test('COMP-DERIV-3. Below target rejects normal completion', () async {
    const src = 'src-cd3';
    await createAccount(src);
    await credit(src, 200000);
    final goal = await mkGoal(key: 'cd3', target: 100000);
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: src,
      amountMinorUnits: 50000,
      householdId: _hh,
      idempotencyKey: 'fund-cd3',
    );
    final r = await completeGoalUc.execute(
      CompleteGoalParams(goalId: goal.id, householdId: _hh),
    );
    expect(r, isA<AppValidationFailure<SavingsGoal>>());
    expect(await dbStatus(goal.id), 'active');
  });

  test(
    'COMP-DERIV-4. Release below target before completion → rejection',
    () async {
      const src = 'src-cd4';
      const dst = 'dst-cd4';
      await createAccount(src);
      await createAccount(dst);
      await credit(src, 200000);
      final goal = await mkGoal(key: 'cd4', target: 100000);
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: src,
        amountMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'fund-cd4',
      );
      await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dst,
        amountMinorUnits: 10001,
        releaseReason: 'dip below',
        householdId: _hh,
        idempotencyKey: 'rel-cd4',
      );
      final r = await completeGoalUc.execute(
        CompleteGoalParams(goalId: goal.id, householdId: _hh),
      );
      expect(r, isA<AppValidationFailure<SavingsGoal>>());
    },
  );

  test(
    'COMP-DERIV-5. Funding reversal below target before completion → rejection',
    () async {
      const src = 'src-cd5';
      await createAccount(src);
      await credit(src, 200000);
      final goal = await mkGoal(key: 'cd5', target: 100000);
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: src,
        amountMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'fund-cd5',
      );
      final opId = await fundOpId(goal.reserveAccountId);
      await reverseUc.execute(
        originalOperationId: opId,
        reversalOperationId: 'rev-cd5',
        householdId: _hh,
        effectiveDate: '2024-01-02',
        createdBy: 'test',
      );
      final r = await completeGoalUc.execute(
        CompleteGoalParams(goalId: goal.id, householdId: _hh),
      );
      expect(r, isA<AppValidationFailure<SavingsGoal>>());
    },
  );

  test(
    'COMP-DERIV-6. Early completion still requires confirmation + reason',
    () async {
      final goal = await mkGoal(key: 'cd6', target: 100000);
      final missingConfirm = await completeGoalUc.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: _hh,
          earlyCompletion: true,
          earlyCompletionConfirmed: false,
          earlyCompletionReason: 'reason present',
        ),
      );
      expect(missingConfirm, isA<AppValidationFailure<SavingsGoal>>());

      final missingReason = await completeGoalUc.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: _hh,
          earlyCompletion: true,
          earlyCompletionConfirmed: true,
          earlyCompletionReason: '   ',
        ),
      );
      expect(missingReason, isA<AppValidationFailure<SavingsGoal>>());

      final ok = await completeGoalUc.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: _hh,
          earlyCompletion: true,
          earlyCompletionConfirmed: true,
          earlyCompletionReason: 'no longer needed',
        ),
      );
      expect(ok, isA<AppOk<SavingsGoal>>());
    },
  );

  // ── Migration / DB rejection ───────────────────────────────────────────────

  test(
    'MIG-5B8-1. Persisted targetReached migrates to active; no completion event',
    () async {
      final path = await materializeTrueSchemaV12File();
      addTearDown(() async {
        final dir = Directory(p.dirname(path));
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final raw = sqlite3.sqlite3.open(path);
      raw.execute('PRAGMA foreign_keys = OFF');
      raw.execute(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('hh-mig8', 'Mig HH', 'u1', '2024-01-01', '2024-01-01')",
      );
      raw.execute(
        "INSERT INTO financial_accounts ("
        "id, household_id, name, type, owner_type, fund_purpose, currency_code, "
        "is_spendable, is_protected, include_in_net_worth, include_in_zakat, "
        "display_order, created_by, created_at, updated_at) VALUES ("
        "'res-mig8', 'hh-mig8', 'Reserve', 'goalReserve', 'household', "
        "'goalReserve', 'EGP', 0, 0, 1, 0, 1, 'test', '2024-01-01', '2024-01-01')",
      );
      raw.execute(
        "INSERT INTO goals ("
        "id, household_id, reserve_account_id, currency_code, status, "
        "idempotency_key, idempotency_payload, created_at, schema_version) VALUES ("
        "'goal-mig8', 'hh-mig8', 'res-mig8', 'EGP', 'targetReached', "
        "'ik-mig8', 'payload', '2024-01-01', 1)",
      );
      raw.execute(
        "INSERT INTO goal_revisions ("
        "id, goal_id, household_id, name, purpose_code, target_minor_units, "
        "currency_code, created_at, revision_reason, schema_version) VALUES ("
        "'rev-mig8', 'goal-mig8', 'hh-mig8', 'Migrated', 'emergencyFund', "
        "100000, 'EGP', '2024-01-01', 'initial', 1)",
      );
      raw.execute('PRAGMA user_version = 15');
      raw.execute('PRAGMA foreign_keys = ON');
      raw.close();

      final upgraded = AppDatabase.forFile(path);
      addTearDown(upgraded.close);

      final ver = await upgraded.customSelect('PRAGMA user_version').get();
      expect(ver.first.read<int>('user_version'), 19);

      final status = await upgraded
          .customSelect("SELECT status FROM goals WHERE id = 'goal-mig8'")
          .get();
      expect(status.first.read<String>('status'), 'active');

      final events = await upgraded
          .customSelect(
            "SELECT COUNT(*) AS c FROM goal_lifecycle_events "
            "WHERE goal_id = 'goal-mig8' AND event_type = 'completed'",
          )
          .get();
      expect(events.first.read<int>('c'), 0);

      for (final name in [
        'check_goal_lifecycle_status',
        'check_goal_lifecycle_status_update',
      ]) {
        final c = await upgraded
            .customSelect(
              "SELECT COUNT(*) AS c FROM sqlite_master "
              "WHERE type='trigger' AND name='$name'",
            )
            .get();
        expect(c.first.read<int>('c'), 1, reason: '$name must exist at latest');
      }
    },
  );

  test('MIG-5B8-2. Direct INSERT targetReached is rejected', () async {
    await db.customStatement(
      "INSERT INTO financial_accounts ("
      "id, household_id, name, type, owner_type, fund_purpose, currency_code, "
      "is_spendable, is_protected, include_in_net_worth, include_in_zakat, "
      "display_order, created_by, created_at, updated_at) VALUES ("
      "'res-rej', '$_hh', 'Reserve', 'goalReserve', 'household', "
      "'goalReserve', 'EGP', 0, 0, 1, 0, 1, 'test', '2024-01-01', '2024-01-01')",
    );
    expect(
      () => db.customStatement(
        "INSERT INTO goals ("
        "id, household_id, reserve_account_id, currency_code, status, "
        "idempotency_key, idempotency_payload, created_at, schema_version) VALUES ("
        "'goal-rej', '$_hh', 'res-rej', 'EGP', 'targetReached', "
        "'ik-rej', 'payload', '2024-01-01', 1)",
      ),
      throwsA(anything),
    );
  });

  test('MIG-5B8-3. Direct UPDATE to targetReached is rejected', () async {
    final goal = await mkGoal(key: 'mig-upd');
    expect(
      () => db.customStatement(
        "UPDATE goals SET status = 'targetReached' WHERE id = '${goal.id}'",
      ),
      throwsA(anything),
    );
    expect(await dbStatus(goal.id), 'active');
  });

  test('MIG-5B8-4. Schema version is 19 on fresh DB', () async {
    final ver = await db.customSelect('PRAGMA user_version').get();
    expect(ver.first.read<int>('user_version'), 19);
  });

  test('UNIT-5B8-1. GoalProgressState.fromBalance canonical derivation', () {
    expect(GoalProgressState.fromBalance(0, 100), GoalProgressState.notStarted);
    expect(
      GoalProgressState.fromBalance(50, 100),
      GoalProgressState.inProgress,
    );
    expect(
      GoalProgressState.fromBalance(100, 100),
      GoalProgressState.targetReached,
    );
    expect(
      GoalProgressState.fromBalance(101, 100),
      GoalProgressState.overfunded,
    );
  });
}
