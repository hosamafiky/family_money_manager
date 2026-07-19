/// Phase 5B / 5B.1 / 5B.2 schema integrity and immutability tests.
///
/// Complements goal_repository_test.dart with raw-SQL-level verifications that
/// cannot be satisfied at the repository API boundary alone.
///
/// Tests (Section 4 – Schema and migration):
///  SM-1.  Fresh schema v10 creates all goal tables
///  SM-2.  Unique index idx_goals_reserve_account is enforced
///  SM-3.  Unique index idx_goals_idempotency is enforced
///  SM-4.  Budget table from v7 is present (migration baseline)
///  SM-5.  All prior-phase tables present in schema v10
///
/// Phase 5B.2 – Section 4 (Reserve classification DB enforcement):
///  RC-1.  UPDATE is_spendable on goalReserve → rejected by trigger
///  RC-2.  UPDATE is_protected on goalReserve → rejected by trigger
///  RC-3.  UPDATE is_spendable on non-reserve account → allowed
///  RC-4.  UPDATE is_protected on non-reserve account → allowed
///  RC-5.  UPDATE type from goalReserve to other → rejected (SR-1 re-verify)
///  RC-6.  INSERT second goal with same reserve_account_id → rejected
///  RC-7.  Reserve account created with is_spendable=false enforced
///  RC-8.  Reserve account created with is_protected=false enforced
///  RC-9.  Trigger no-op when is_spendable unchanged on goalReserve → allowed
///
/// Phase 5B.2 – Section 5 (Goal movement validation):
///  MV-1.  Valid funding movement → succeeds
///  MV-2.  Funding movement with wrong destination account → rejected
///  MV-3.  Funding movement referencing non-transfer operation → rejected
///  MV-4.  Release movement with wrong source account → rejected
///  MV-5.  Release movement without reason → rejected
///  MV-6.  Duplicate movement for same operation → rejected
///  MV-7.  UPDATE on goal_movements → rejected by trigger
///  MV-8.  DELETE on goal_movements → rejected by trigger
///
/// Tests (Section 5 – One-to-one goal reserve integrity):
///  SR-1.  Reserve account type cannot be changed (trigger)
///  SR-2.  Reserve currency immutable once ledger history exists (trigger)
///  SR-3.  Two goals cannot share a reserve account (unique index)
///  SR-4.  Reserve account cannot be deleted while referenced by a goal (FK)
///
/// Tests (Section 11 – Goal movement integrity):
///  GM-1.  UPDATE on goal_movements is blocked by no_update_goal_movements trigger
///  GM-2.  DELETE on goal_movements is blocked by no_delete_goal_movements trigger
///
/// Tests (Section 13 – Goal revisions immutability):
///  GR-1.  UPDATE on goal_revisions is blocked by no_update_goal_revisions trigger
///  GR-2.  DELETE on goal_revisions is blocked by no_delete_goal_revisions trigger
///
/// Tests (Section 12 – Goal progress for non-2-decimal currencies):
///  GP-1.  JPY goal: balance uses scale=0 (minor units are the major units)
///  GP-2.  KWD goal: balance uses scale=3 (1 KWD = 1000 minor units)
///  GP-3.  GoalProgress.remainingMinorUnits is zero when overfunded (never negative)
///
/// Tests (Section 14 – Archived goal workflow):
///  AG-1.  Archived goal cannot be funded
///  AG-2.  Archived goal cannot have funds released
///
/// Tests (Section 7 – Zero initial funding):
///  ZF-1.  Zero initial funding creates no transfer, no movement
///
/// Phase 5B.1 additions (Section 5 – Goals table hardening):
///  GT-1.  no_update_goal_immutable: household_id cannot change
///  GT-2.  no_delete_goal_with_history: cannot delete goal with revisions
///  GT-3.  goal_status_valid_transition: invalid transition (active→active) rejected
///
/// Phase 5B.1 additions (Section 6 – Reserve account hardening):
///  RA-1.  no_retype_reserve_account: goalReserve type cannot change (semantic trigger)
///  RA-2.  no_archive_active_reserve: reserve cannot be archived when goal is active
///  RA-3.  Can archive reserve account when goal is archived
///
/// Phase 5B.1 additions (Section 7 – Movements hardening):
///  MH-1.  goal_movement_release_reason: release movement requires non-empty reason
///  MH-2.  goal_movement_transfer_type: movement must reference a transfer operation
///  MH-3.  idx_goal_movements_unique_operation: duplicate operation rejected
///
/// Phase 5B.1 additions (Section 8 – Beneficiary household integrity):
///  BH-1.  goal_revision_beneficiary_same_household: cross-household beneficiary rejected
///
/// Phase 5B.1 additions (Section 9 – Lifecycle vs. progress):
///  LP-1.  GoalProgressState.targetReached is derived from balance (not from status write)
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
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

const _hh = 'hh-schema-test';

void main() {
  late AppDatabase db;
  late DriftGoalRepository goalRepo;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late CreateGoalUseCase createGoalUc;
  late FundGoalUseCase fundGoalUc;
  late ReleaseGoalFundsUseCase releaseGoalUc;
  late ArchiveGoalUseCase archiveGoalUc;

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
    archiveGoalUc = ArchiveGoalUseCase(goalRepo);

    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'Schema Test HH', 'u-sm', "
      "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
  });

  tearDown(() async => db.close());

  // ── Local helpers ──────────────────────────────────────────────────────────

  Future<FinancialAccount> createAccount({
    required String id,
    String currency = 'EGP',
  }) => accountRepo.createAccount(
    CreateAccountParams(
      id: id,
      householdId: _hh,
      name: 'Acc $id',
      type: FinancialAccountType.fromCode('personalCashWallet'),
      ownerType: AccountOwnerType.user,
      fundPurpose: FundPurpose.available,
      currencyCode: currency,
      isSpendable: true,
      isProtected: false,
      includeInNetWorth: true,
      includeInZakat: false,
      displayOrder: 0,
      createdBy: 'test',
    ),
  );

  Future<void> creditAccount(
    String accId,
    int amount, {
    String currency = 'EGP',
  }) => ledgerRepo.recordIncome(
    RecordIncomeParams(
      operationId: 'income-$accId-$amount',
      householdId: _hh,
      destinationAccountId: accId,
      amountMinorUnits: amount,
      currencyCode: currency,
      effectiveDate: '2024-01-01',
      createdBy: 'test',
    ),
  );

  Future<AppResult<SavingsGoal>> createGoal({
    String goalName = 'Test Goal',
    String currencyCode = 'EGP',
    int target = 100000,
    required String idempotencyKey,
  }) => createGoalUc.execute(
    goalName: goalName,
    purpose: GoalPurpose.emergencyFund,
    currencyCode: currencyCode,
    targetMinorUnits: target,
    householdId: _hh,
    idempotencyKey: idempotencyKey,
  );

  // ── Section 4: Schema and migration ───────────────────────────────────────

  test('SM-1. Fresh schema v9 creates all goal tables', () async {
    for (final t in ['goals', 'goal_revisions', 'goal_movements']) {
      final rows = await db.customSelect('SELECT COUNT(*) as c FROM $t').get();
      expect(
        rows.first.read<int>('c'),
        greaterThanOrEqualTo(0),
        reason: 'Table $t must exist in fresh schema v8',
      );
    }
  });

  test('SM-2. Unique index idx_goals_reserve_account is enforced', () async {
    final goal =
        ((await createGoal(idempotencyKey: 'ik-sm2')) as AppOk<SavingsGoal>)
            .value;

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) VALUES "
        "('goal-sm2-dup', '$_hh', '${goal.reserveAccountId}', 'EGP', 'active', "
        "'ik-sm2-dup', 'payload-dup', '2024-01-02T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'idx_goals_reserve_account must reject duplicate reserve_account_id',
    );
  });

  test('SM-3. Unique index idx_goals_idempotency is enforced', () async {
    await createGoal(idempotencyKey: 'ik-sm3');

    // Insert a distinct account so the unique-reserve-index does not fire first.
    await createAccount(id: 'reserve-sm3-dup');

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) VALUES "
        "('goal-sm3-dup', '$_hh', 'reserve-sm3-dup', 'EGP', 'active', "
        "'ik-sm3', 'diff-payload', '2024-01-02T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'idx_goals_idempotency must reject duplicate (household_id, idempotency_key)',
    );
  });

  test('SM-4. Budget table from v7 is present (migration baseline)', () async {
    final rows = await db
        .customSelect('SELECT COUNT(*) as c FROM budgets')
        .get();
    expect(rows.first.read<int>('c'), greaterThanOrEqualTo(0));
  });

  test('SM-5. All prior-phase tables present in schema v9', () async {
    for (final t in [
      'households',
      'household_members',
      'financial_accounts',
      'ledger_entries',
      'operations',
      'child_withdrawal_audits',
      'operation_contexts',
      'budgets',
      'goals',
      'goal_revisions',
      'goal_movements',
    ]) {
      final rows = await db.customSelect('SELECT COUNT(*) as c FROM $t').get();
      expect(
        rows.first.read<int>('c'),
        greaterThanOrEqualTo(0),
        reason: 'Table $t must be present in schema v8',
      );
    }
  });

  // ── Section 5: One-to-one goal reserve integrity ───────────────────────────

  test(
    'SR-1. Reserve account type cannot be changed (immutable_account_type_currency trigger)',
    () async {
      final goal =
          ((await createGoal(idempotencyKey: 'ik-sr1')) as AppOk<SavingsGoal>)
              .value;

      await expectLater(
        () => db.customStatement(
          "UPDATE financial_accounts SET type = 'checking' "
          "WHERE id = '${goal.reserveAccountId}'",
        ),
        throwsA(anything),
        reason:
            'immutable_account_type_currency trigger must block type change on goalReserve',
      );
    },
  );

  test(
    'SR-2. Reserve currency immutable once ledger history exists (trigger)',
    () async {
      const srcId = 'src-sr2';
      await createAccount(id: srcId);
      await creditAccount(srcId, 50000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-sr2')) as AppOk<SavingsGoal>)
              .value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-sr2',
      );

      await expectLater(
        () => db.customStatement(
          "UPDATE financial_accounts SET currency_code = 'USD' "
          "WHERE id = '${goal.reserveAccountId}'",
        ),
        throwsA(anything),
        reason:
            'restrict_account_classification_update must block currency change on reserve '
            'after financial history exists',
      );
    },
  );

  test('SR-3. Two goals cannot share a reserve account (unique index)', () async {
    final goal =
        ((await createGoal(idempotencyKey: 'ik-sr3')) as AppOk<SavingsGoal>)
            .value;

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) VALUES "
        "('goal-sr3-b', '$_hh', '${goal.reserveAccountId}', 'EGP', 'active', "
        "'ik-sr3-b', 'payload-b', '2024-01-02T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'idx_goals_reserve_account must prevent two goals pointing at the same '
          'reserve account',
    );
  });

  test(
    'SR-4. Reserve account cannot be deleted while referenced by a goal (FK)',
    () async {
      final goal =
          ((await createGoal(idempotencyKey: 'ik-sr4')) as AppOk<SavingsGoal>)
              .value;

      await expectLater(
        () => db.customStatement(
          "DELETE FROM financial_accounts WHERE id = '${goal.reserveAccountId}'",
        ),
        throwsA(anything),
        reason:
            'FK from goals.reserve_account_id must prevent independent deletion of the '
            'reserve account',
      );
    },
  );

  // ── Section 11: Goal movement integrity ───────────────────────────────────

  test('GM-1. UPDATE on goal_movements is blocked by trigger', () async {
    const srcId = 'src-gm1';
    await createAccount(id: srcId);
    await creditAccount(srcId, 50000);

    final goal =
        ((await createGoal(idempotencyKey: 'ik-gm1')) as AppOk<SavingsGoal>)
            .value;
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 10000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-gm1',
    );

    final movRows = await db
        .customSelect(
          "SELECT id FROM goal_movements WHERE goal_id = '${goal.id}'",
        )
        .get();
    final movId = movRows.first.read<String>('id');

    await expectLater(
      () => db.customStatement(
        "UPDATE goal_movements SET movement_type = 'release' WHERE id = '$movId'",
      ),
      throwsA(anything),
      reason:
          'no_update_goal_movements trigger must block any UPDATE on goal_movements',
    );
  });

  test('GM-2. DELETE on goal_movements is blocked by trigger', () async {
    const srcId = 'src-gm2';
    await createAccount(id: srcId);
    await creditAccount(srcId, 50000);

    final goal =
        ((await createGoal(idempotencyKey: 'ik-gm2')) as AppOk<SavingsGoal>)
            .value;
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 10000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-gm2',
    );

    final movRows = await db
        .customSelect(
          "SELECT id FROM goal_movements WHERE goal_id = '${goal.id}'",
        )
        .get();
    final movId = movRows.first.read<String>('id');

    await expectLater(
      () =>
          db.customStatement("DELETE FROM goal_movements WHERE id = '$movId'"),
      throwsA(anything),
      reason:
          'no_delete_goal_movements trigger must block DELETE on goal_movements',
    );
  });

  // ── Section 13: Goal revisions immutability ────────────────────────────────

  test('GR-1. UPDATE on goal_revisions is blocked by trigger', () async {
    final goal =
        ((await createGoal(idempotencyKey: 'ik-gr1')) as AppOk<SavingsGoal>)
            .value;

    final revRows = await db
        .customSelect(
          "SELECT id FROM goal_revisions WHERE goal_id = '${goal.id}'",
        )
        .get();
    final revId = revRows.first.read<String>('id');

    await expectLater(
      () => db.customStatement(
        "UPDATE goal_revisions SET name = 'Hacked' WHERE id = '$revId'",
      ),
      throwsA(anything),
      reason:
          'no_update_goal_revisions trigger must block any UPDATE on goal_revisions',
    );
  });

  test('GR-2. DELETE on goal_revisions is blocked by trigger', () async {
    final goal =
        ((await createGoal(idempotencyKey: 'ik-gr2')) as AppOk<SavingsGoal>)
            .value;

    final revRows = await db
        .customSelect(
          "SELECT id FROM goal_revisions WHERE goal_id = '${goal.id}'",
        )
        .get();
    final revId = revRows.first.read<String>('id');

    await expectLater(
      () =>
          db.customStatement("DELETE FROM goal_revisions WHERE id = '$revId'"),
      throwsA(anything),
      reason:
          'no_delete_goal_revisions trigger must block DELETE on goal_revisions',
    );
  });

  // ── Section 12: Goal progress for non-2-decimal currencies ────────────────

  test(
    'GP-1. JPY goal: balance uses scale=0 (minor units are the major units)',
    () async {
      const srcId = 'src-jpy';
      await createAccount(id: srcId, currency: 'JPY');
      await creditAccount(srcId, 50000, currency: 'JPY');

      final result = await createGoalUc.execute(
        goalName: 'Japan Trip',
        purpose: GoalPurpose.travel,
        currencyCode: 'JPY',
        targetMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'ik-jpy-goal',
      );
      final goal = (result as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-jpy-fund',
      );

      final balResult = await goalRepo.getReserveBalance(
        reserveAccountId: goal.reserveAccountId,
        householdId: _hh,
      );
      expect(
        (balResult as AppOk<int>).value,
        10000,
        reason: 'JPY balance must match funded minor-unit amount exactly',
      );
    },
  );

  test(
    'GP-2. KWD goal: balance uses scale=3 (1 KWD = 1000 minor units)',
    () async {
      const srcId = 'src-kwd';
      await createAccount(id: srcId, currency: 'KWD');
      await creditAccount(srcId, 500000, currency: 'KWD');

      final result = await createGoalUc.execute(
        goalName: 'KWD Savings',
        purpose: GoalPurpose.majorPurchase,
        currencyCode: 'KWD',
        targetMinorUnits: 100000, // 100.000 KWD
        householdId: _hh,
        idempotencyKey: 'ik-kwd-goal',
      );
      final goal = (result as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 50000, // 50.000 KWD
        householdId: _hh,
        idempotencyKey: 'ik-kwd-fund',
      );

      final balResult = await goalRepo.getReserveBalance(
        reserveAccountId: goal.reserveAccountId,
        householdId: _hh,
      );
      expect(
        (balResult as AppOk<int>).value,
        50000,
        reason:
            '50.000 KWD = 50000 minor units must be stored and retrieved correctly',
      );
    },
  );

  test(
    'GP-3. GoalProgress.remainingMinorUnits is zero (never negative) when overfunded',
    () async {
      const srcId = 'src-ovf';
      await createAccount(id: srcId);
      await creditAccount(srcId, 200000);

      final goal =
          ((await createGoal(target: 50000, idempotencyKey: 'ik-ovf'))
                  as AppOk<SavingsGoal>)
              .value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 75000, // > target of 50000
        householdId: _hh,
        idempotencyKey: 'ik-fund-ovf',
      );

      final progressUc = GetGoalProgressUseCase(goalRepo);
      final progress =
          ((await progressUc.execute(goal.id)) as AppOk<GoalProgress>).value;

      expect(
        progress.remainingMinorUnits,
        0,
        reason: 'Remaining must be 0 when overfunded (clamp prevents negative)',
      );
      expect(
        progress.overfundedMinorUnits,
        25000,
        reason: 'Overfunded = 75000 - 50000 = 25000',
      );
      expect(progress.progressState, GoalProgressState.overfunded);
    },
  );

  // ── Section 14: Archived goal workflow ────────────────────────────────────

  test('AG-1. Archived goal cannot be funded', () async {
    const srcId = 'src-ag1';
    await createAccount(id: srcId);
    await creditAccount(srcId, 50000);

    final goal =
        ((await createGoal(idempotencyKey: 'ik-ag1')) as AppOk<SavingsGoal>)
            .value;
    await archiveGoalUc.execute(goalId: goal.id, householdId: _hh);

    final result = await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 10000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-ag1',
    );
    expect(
      result,
      isA<AppValidationFailure<SavingsGoal>>(),
      reason: 'Archived goal must not be fundable',
    );
  });

  test('AG-2. Archived goal cannot have funds released', () async {
    const srcId = 'src-ag2';
    const dstId = 'dst-ag2';
    await createAccount(id: srcId);
    await createAccount(id: dstId);
    await creditAccount(srcId, 50000);

    final goal =
        ((await createGoal(idempotencyKey: 'ik-ag2')) as AppOk<SavingsGoal>)
            .value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-ag2',
    );
    await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 20000,
      releaseReason: 'Clear to archive',
      householdId: _hh,
      idempotencyKey: 'ik-release-ag2-clear',
    );
    await archiveGoalUc.execute(goalId: goal.id, householdId: _hh);

    final result = await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 5000,
      releaseReason: 'Should fail',
      householdId: _hh,
      idempotencyKey: 'ik-release-ag2-fail',
    );
    expect(
      result,
      isA<AppValidationFailure<SavingsGoal>>(),
      reason: 'Archived goal must not allow fund release',
    );
  });

  // ── Section 7: Zero initial funding ───────────────────────────────────────

  test('ZF-1. Zero initial funding creates no transfer, no movement', () async {
    final opsBefore =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM operations WHERE household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('c');

    final result = await createGoalUc.execute(
      goalName: 'No Funding Goal',
      purpose: GoalPurpose.other,
      currencyCode: 'EGP',
      targetMinorUnits: 50000,
      householdId: _hh,
      idempotencyKey: 'ik-zero-fund',
      initialFundingMinorUnits: 0,
    );
    expect(result, isA<AppOk<SavingsGoal>>());
    final goal = (result as AppOk<SavingsGoal>).value;

    final opsAfter =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM operations WHERE household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('c');

    expect(
      opsAfter,
      opsBefore,
      reason: 'Zero initial funding must not create any operations',
    );

    final movResult = await goalRepo.getMovements(goal.id);
    expect(
      (movResult as AppOk<List<GoalMovement>>).value,
      isEmpty,
      reason: 'Zero initial funding must not create any goal movements',
    );

    final balResult = await goalRepo.getReserveBalance(
      reserveAccountId: goal.reserveAccountId,
      householdId: _hh,
    );
    expect((balResult as AppOk<int>).value, 0);
  });

  // ── Phase 5B.1 – Section 5: Goals table hardening triggers ────────────────

  test('GT-1. no_update_goal_immutable: household_id cannot change', () async {
    final goal =
        ((await createGoal(idempotencyKey: 'ik-gt1')) as AppOk<SavingsGoal>)
            .value;

    await expectLater(
      () => db.customStatement(
        "UPDATE goals SET household_id = 'other-hh' WHERE id = '${goal.id}'",
      ),
      throwsA(anything),
      reason: 'no_update_goal_immutable must reject household_id change',
    );
  });

  test(
    'GT-2. no_delete_goal_with_history: cannot delete goal with revisions',
    () async {
      final goal =
          ((await createGoal(idempotencyKey: 'ik-gt2')) as AppOk<SavingsGoal>)
              .value;

      // Verify revision exists.
      final revCount =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) as c FROM goal_revisions WHERE goal_id = '${goal.id}'",
                  )
                  .get())
              .first
              .read<int>('c');
      expect(revCount, greaterThan(0));

      await expectLater(
        () => db.customStatement("DELETE FROM goals WHERE id = '${goal.id}'"),
        throwsA(anything),
        reason:
            'no_delete_goal_with_history must block DELETE when revisions exist',
      );
    },
  );

  test(
    'GT-3. goal_status_valid_transition: invalid transition (archived→completed) rejected',
    () async {
      final goal =
          ((await createGoal(idempotencyKey: 'ik-gt3')) as AppOk<SavingsGoal>)
              .value;

      // Archive the goal (active→archived is valid).
      await archiveGoalUc.execute(goalId: goal.id, householdId: _hh);

      // Now try archived→completed which is NOT in the allowed set.
      await expectLater(
        () => db.customStatement(
          "UPDATE goals SET status = 'completed' WHERE id = '${goal.id}'",
        ),
        throwsA(anything),
        reason:
            'goal_status_valid_transition must reject archived→completed transition',
      );
    },
  );

  // ── Phase 5B.1 – Section 6: Reserve account hardening ─────────────────────

  test(
    'RA-1. no_retype_reserve_account: goalReserve type cannot be changed',
    () async {
      final goal =
          ((await createGoal(idempotencyKey: 'ik-ra1')) as AppOk<SavingsGoal>)
              .value;

      await expectLater(
        () => db.customStatement(
          "UPDATE financial_accounts SET type = 'personalCashWallet' "
          "WHERE id = '${goal.reserveAccountId}'",
        ),
        throwsA(anything),
        reason:
            'no_retype_reserve_account or immutable_account_type_currency must block type change',
      );
    },
  );

  test(
    'RA-2. no_archive_active_reserve: cannot archive reserve while goal is active',
    () async {
      final goal =
          ((await createGoal(idempotencyKey: 'ik-ra2')) as AppOk<SavingsGoal>)
              .value;
      expect(goal.status, GoalStatus.active);

      await expectLater(
        () => db.customStatement(
          "UPDATE financial_accounts SET is_archived = 1 "
          "WHERE id = '${goal.reserveAccountId}'",
        ),
        throwsA(anything),
        reason:
            'no_archive_active_reserve must block archiving reserve of an active goal',
      );
    },
  );

  test('RA-3. Can archive reserve account when goal is archived', () async {
    final goal =
        ((await createGoal(idempotencyKey: 'ik-ra3')) as AppOk<SavingsGoal>)
            .value;

    // Archive the goal first.
    await archiveGoalUc.execute(goalId: goal.id, householdId: _hh);

    // Now archiving the reserve account must NOT throw.
    await expectLater(
      () => db.customStatement(
        "UPDATE financial_accounts SET is_archived = 1, archived_at = '2024-01-01', "
        "updated_at = '2024-01-01' WHERE id = '${goal.reserveAccountId}'",
      ),
      returnsNormally,
      reason: 'Archiving reserve of an archived goal must be allowed',
    );
  });

  // ── Phase 5B.1 – Section 7: Movements hardening ───────────────────────────

  test(
    'MH-1. goal_movement_release_reason: release movement requires non-empty reason',
    () async {
      const srcId = 'src-mh1';
      await createAccount(id: srcId);
      await creditAccount(srcId, 50000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-mh1')) as AppOk<SavingsGoal>)
              .value;
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-mh1',
      );

      // Get the transfer operation id.
      final opRows = await db
          .customSelect(
            "SELECT id FROM operations WHERE type = 'transfer' "
            "AND destination_account_id = '${goal.reserveAccountId}' LIMIT 1",
          )
          .get();
      final opId = opRows.first.read<String>('id');

      // Try to insert a release movement without release_reason.
      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
          "movement_type, created_at) "
          "VALUES ('mov-mh1-direct', '${goal.id}', '$_hh', '$opId', 'release', '2024-01-02')",
        ),
        throwsA(anything),
        reason:
            'goal_movement_release_reason must block release movement without release_reason',
      );
    },
  );

  test(
    'MH-2. goal_movement_transfer_type: movement must reference a transfer operation',
    () async {
      final goal =
          ((await createGoal(idempotencyKey: 'ik-mh2')) as AppOk<SavingsGoal>)
              .value;

      // Insert an income operation (not a transfer).
      const srcId = 'src-mh2';
      await createAccount(id: srcId);
      await creditAccount(srcId, 50000);

      // Get the income operation id.
      final opRows = await db
          .customSelect(
            "SELECT id FROM operations WHERE type = 'income' "
            "AND household_id = '$_hh' LIMIT 1",
          )
          .get();
      final incomeOpId = opRows.first.read<String>('id');

      // Try to create a movement referencing an income operation.
      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
          "movement_type, created_at) "
          "VALUES ('mov-mh2-direct', '${goal.id}', '$_hh', '$incomeOpId', 'funding', '2024-01-02')",
        ),
        throwsA(anything),
        reason:
            'goal_movement_transfer_type must block movement referencing a non-transfer operation',
      );
    },
  );

  test(
    'MH-3. idx_goal_movements_unique_operation: duplicate operation rejected',
    () async {
      const srcId = 'src-mh3';
      await createAccount(id: srcId);
      await creditAccount(srcId, 100000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-mh3')) as AppOk<SavingsGoal>)
              .value;
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-mh3',
      );

      // Get the existing movement's transfer_operation_id.
      final movRows = await db
          .customSelect(
            "SELECT transfer_operation_id FROM goal_movements "
            "WHERE goal_id = '${goal.id}' LIMIT 1",
          )
          .get();
      final transferOpId = movRows.first.read<String>('transfer_operation_id');

      // Try to insert another movement with the same transfer_operation_id.
      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
          "movement_type, created_at) "
          "VALUES ('mov-mh3-dup', '${goal.id}', '$_hh', '$transferOpId', 'funding', '2024-01-03')",
        ),
        throwsA(anything),
        reason:
            'idx_goal_movements_unique_operation must reject duplicate transfer_operation_id',
      );
    },
  );

  // ── Phase 5B.1 – Section 8: Beneficiary household integrity ──────────────

  test(
    'BH-1. goal_revision_beneficiary_same_household: cross-household beneficiary rejected',
    () async {
      // Create a second household.
      const hh2 = 'hh-bh1-other';
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('$hh2', 'Other HH', 'u-bh1', '2024-01-01', '2024-01-01')",
      );

      // Create a member in hh2.
      await db.customStatement(
        "INSERT INTO household_members (id, household_id, display_name, role, "
        "is_archived, created_at, updated_at) "
        "VALUES ('member-hh2', '$hh2', 'Other Member', 'primary_user', 0, "
        "'2024-01-01', '2024-01-01')",
      );

      // Create a goal in hh1 (_hh).
      final goal =
          ((await createGoal(idempotencyKey: 'ik-bh1')) as AppOk<SavingsGoal>)
              .value;

      // Try to insert a revision referencing the hh2 member as beneficiary.
      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_revisions (id, goal_id, household_id, name, purpose_code, "
          "target_minor_units, currency_code, created_at, revision_reason, beneficiary_member_id) "
          "VALUES ('rev-bh1-cross', '${goal.id}', '$_hh', 'BH Test', 'other', "
          "50000, 'EGP', '2024-01-02', 'cross-household test', 'member-hh2')",
        ),
        throwsA(anything),
        reason:
            'goal_revision_beneficiary_same_household must reject cross-household beneficiary',
      );
    },
  );

  // ── Phase 5B.1 – Section 9: Lifecycle vs. derived progress ───────────────

  test(
    'LP-1. GoalProgressState.targetReached derived from balance (not from status write)',
    () async {
      const srcId = 'src-lp1';
      await createAccount(id: srcId);
      await creditAccount(srcId, 200000);

      // Create a goal with target = 100.00
      final goal =
          ((await createGoal(target: 100000, idempotencyKey: 'ik-lp1'))
                  as AppOk<SavingsGoal>)
              .value;

      // Fund exactly to the target.
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-lp1',
      );

      // GoalProgressState must be targetReached, derived from balance.
      final progressUc = GetGoalProgressUseCase(goalRepo);
      final progress =
          ((await progressUc.execute(goal.id)) as AppOk<GoalProgress>).value;

      expect(
        progress.progressState,
        GoalProgressState.targetReached,
        reason:
            'progressState must be targetReached when balance equals target, '
            'derived from ledger — no explicit status write needed',
      );
      expect(
        progress.reserveBalanceMinorUnits,
        100000,
        reason: 'Reserve balance must equal the funded amount',
      );
      expect(progress.isTargetReached, isTrue);
      // Phase 5B.8: funding must not persist targetReached as lifecycle status.
      final refreshed =
          ((await goalRepo.findGoalById(goal.id)) as AppOk<SavingsGoal?>)
              .value!;
      expect(refreshed.status, GoalStatus.active);
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.2 – Section 4: Reserve classification DB enforcement (RC-1..RC-9)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // These tests bypass the repository layer and issue raw SQL to verify that
  // the no_modify_reserve_spendable / no_modify_reserve_protected triggers
  // and unique constraints reject forbidden modifications.

  /// Insert a goalReserve account directly via SQL and return its ID.
  Future<String> insertReserveAccount(String id) async {
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('$id', '$_hh', 'Reserve $id', 'goalReserve', 'household', "
      "'goalReserve', 'EGP', 0, 0, 1, 0, 9999, 'test', "
      "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    return id;
  }

  /// Insert a normal spendable account directly via SQL and return its ID.
  Future<String> insertNormalAccount(String id) async {
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('$id', '$_hh', 'Normal $id', 'personalCashWallet', 'user', "
      "'available', 'EGP', 1, 0, 1, 0, 1, 'test', "
      "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    return id;
  }

  test('RC-1. UPDATE is_spendable on goalReserve → rejected by trigger', () async {
    await insertReserveAccount('rc1-reserve');

    await expectLater(
      () => db.customStatement(
        "UPDATE financial_accounts SET is_spendable = 1 WHERE id = 'rc1-reserve'",
      ),
      throwsA(anything),
      reason:
          'no_modify_reserve_spendable trigger must reject is_spendable change',
    );

    // Verify the value was NOT changed.
    final rows = await db
        .customSelect(
          "SELECT is_spendable FROM financial_accounts WHERE id = 'rc1-reserve'",
        )
        .get();
    expect(rows.first.read<bool>('is_spendable'), isFalse);
  });

  test('RC-2. UPDATE is_protected on goalReserve → rejected by trigger', () async {
    await insertReserveAccount('rc2-reserve');

    await expectLater(
      () => db.customStatement(
        "UPDATE financial_accounts SET is_protected = 1 WHERE id = 'rc2-reserve'",
      ),
      throwsA(anything),
      reason:
          'no_modify_reserve_protected trigger must reject is_protected change',
    );

    final rows = await db
        .customSelect(
          "SELECT is_protected FROM financial_accounts WHERE id = 'rc2-reserve'",
        )
        .get();
    expect(rows.first.read<bool>('is_protected'), isFalse);
  });

  test('RC-3. UPDATE is_spendable on non-reserve account → allowed', () async {
    await insertNormalAccount('rc3-normal');

    // Should NOT throw — trigger only fires on goalReserve rows.
    await db.customStatement(
      "UPDATE financial_accounts SET is_spendable = 0 WHERE id = 'rc3-normal'",
    );

    final rows = await db
        .customSelect(
          "SELECT is_spendable FROM financial_accounts WHERE id = 'rc3-normal'",
        )
        .get();
    expect(rows.first.read<bool>('is_spendable'), isFalse);
  });

  test('RC-4. UPDATE is_protected on non-reserve account → allowed', () async {
    await insertNormalAccount('rc4-normal');

    await db.customStatement(
      "UPDATE financial_accounts SET is_protected = 1 WHERE id = 'rc4-normal'",
    );

    final rows = await db
        .customSelect(
          "SELECT is_protected FROM financial_accounts WHERE id = 'rc4-normal'",
        )
        .get();
    expect(rows.first.read<bool>('is_protected'), isTrue);
  });

  test(
    'RC-5. UPDATE type from goalReserve to other type → rejected by trigger (SR-1 re-verify)',
    () async {
      await insertReserveAccount('rc5-reserve');

      await expectLater(
        () => db.customStatement(
          "UPDATE financial_accounts SET type = 'personalCashWallet' WHERE id = 'rc5-reserve'",
        ),
        throwsA(anything),
        reason: 'no_retype_reserve_account trigger must prevent type change',
      );

      final rows = await db
          .customSelect(
            "SELECT type FROM financial_accounts WHERE id = 'rc5-reserve'",
          )
          .get();
      expect(rows.first.read<String>('type'), 'goalReserve');
    },
  );

  test(
    'RC-6. INSERT second goal with same reserve_account_id → rejected by unique constraint',
    () async {
      final goal1 =
          ((await createGoal(idempotencyKey: 'ik-rc6-g1'))
                  as AppOk<SavingsGoal>)
              .value;

      // Attempt to create a second goal row that reuses the same reserve_account_id.
      await expectLater(
        () => db.customStatement(
          "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
          "status, created_at, updated_at, idempotency_key, idempotency_payload) "
          "VALUES ('rc6-goal-dup', '$_hh', '${goal1.reserveAccountId}', 'EGP', "
          "'active', '2024-01-01', '2024-01-01', 'ik-rc6-dup', 'payload-dup')",
        ),
        throwsA(anything),
        reason:
            'idx_goals_reserve_account unique constraint must prevent sharing a reserve account',
      );
    },
  );

  test(
    'RC-7. Reserve account created with is_spendable=false (verified)',
    () async {
      final goal =
          ((await createGoal(idempotencyKey: 'ik-rc7')) as AppOk<SavingsGoal>)
              .value;

      final rows = await db
          .customSelect(
            "SELECT is_spendable FROM financial_accounts WHERE id = '${goal.reserveAccountId}'",
          )
          .get();
      expect(rows.first.read<bool>('is_spendable'), isFalse);
    },
  );

  test(
    'RC-8. Reserve account created with is_protected=false (verified)',
    () async {
      final goal =
          ((await createGoal(idempotencyKey: 'ik-rc8')) as AppOk<SavingsGoal>)
              .value;

      final rows = await db
          .customSelect(
            "SELECT is_protected FROM financial_accounts WHERE id = '${goal.reserveAccountId}'",
          )
          .get();
      expect(rows.first.read<bool>('is_protected'), isFalse);
    },
  );

  test(
    'RC-9. UPDATE is_spendable to same value on goalReserve → allowed (trigger no-op)',
    () async {
      await insertReserveAccount('rc9-reserve');

      // UPDATE where the new value equals the old value — WHEN clause is false, trigger doesn't fire.
      await db.customStatement(
        "UPDATE financial_accounts SET is_spendable = 0 WHERE id = 'rc9-reserve'",
      );

      final rows = await db
          .customSelect(
            "SELECT is_spendable FROM financial_accounts WHERE id = 'rc9-reserve'",
          )
          .get();
      expect(rows.first.read<bool>('is_spendable'), isFalse);
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.2 – Section 5: Goal movement validation (MV-1..MV-8)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // These tests bypass the repository layer and issue raw SQL to verify that
  // the validate_funding_movement / validate_release_movement triggers and
  // the unique index on (goal_id, transfer_operation_id) enforce direction
  // and reason constraints.

  /// Insert a minimal transfer operation and return its ID.
  Future<String> insertTransferOp({
    required String id,
    required String sourceAccountId,
    required String destinationAccountId,
  }) async {
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, source_account_id, "
      "destination_account_id, total_amount_minor_units, currency_code, effective_date, "
      "recorded_at, created_by, created_at, updated_at) "
      "VALUES ('$id', '$_hh', 'transfer', '$sourceAccountId', "
      "'$destinationAccountId', 10000, 'EGP', '2024-01-01', '2024-01-01T00:00:00Z', "
      "'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    await db.customStatement(
      "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
      "direction, amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "('${id}_debit', '$id', '$_hh', '$sourceAccountId', 'debit', 10000, "
      "'EGP', 'transferOut', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
    );
    await db.customStatement(
      "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
      "direction, amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "('${id}_credit', '$id', '$_hh', '$destinationAccountId', 'credit', 10000, "
      "'EGP', 'transferIn', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
    );
    return id;
  }

  test(
    'MV-1. Valid funding movement (transfer to reserve) → succeeds',
    () async {
      const srcId = 'src-mv1';
      await createAccount(id: srcId);
      await creditAccount(srcId, 100000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-mv1')) as AppOk<SavingsGoal>)
              .value;

      // Insert a valid transfer operation into the reserve.
      final opId = await insertTransferOp(
        id: 'op-mv1',
        sourceAccountId: srcId,
        destinationAccountId: goal.reserveAccountId,
      );

      // Insert the goal movement — must succeed.
      await db.customStatement(
        "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
        "transfer_operation_id, created_at, release_reason) "
        "VALUES ('mov-mv1', '${goal.id}', '$_hh', 'funding', '$opId', "
        "'2024-01-01T00:00:00Z', NULL)",
      );

      final rows = await db
          .customSelect(
            "SELECT COUNT(*) as c FROM goal_movements WHERE id = 'mov-mv1'",
          )
          .get();
      expect(rows.first.read<int>('c'), 1);
    },
  );

  test(
    'MV-2. Funding movement with wrong destination (not reserve) → rejected',
    () async {
      const srcId = 'src-mv2';
      const wrongDstId = 'dst-mv2-wrong';
      await createAccount(id: srcId);
      await createAccount(id: wrongDstId);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-mv2')) as AppOk<SavingsGoal>)
              .value;

      // Transfer goes to wrong account (not the reserve).
      final opId = await insertTransferOp(
        id: 'op-mv2',
        sourceAccountId: srcId,
        destinationAccountId: wrongDstId,
      );

      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
          "transfer_operation_id, created_at, release_reason) "
          "VALUES ('mov-mv2', '${goal.id}', '$_hh', 'funding', '$opId', "
          "'2024-01-01T00:00:00Z', NULL)",
        ),
        throwsA(anything),
        reason:
            'validate_funding_movement must reject transfer not directed to the reserve',
      );
    },
  );

  test(
    'MV-3. Funding movement referencing non-transfer operation type → rejected',
    () async {
      const dstId = 'dst-mv3';
      await createAccount(id: dstId);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-mv3')) as AppOk<SavingsGoal>)
              .value;

      // Insert an income operation (not a transfer) pointing to the reserve.
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, destination_account_id, "
        "total_amount_minor_units, currency_code, effective_date, recorded_at, "
        "created_by, created_at, updated_at) "
        "VALUES ('op-mv3-income', '$_hh', 'income', '${goal.reserveAccountId}', "
        "10000, 'EGP', '2024-01-01', '2024-01-01T00:00:00Z', "
        "'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
      );

      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
          "transfer_operation_id, created_at, release_reason) "
          "VALUES ('mov-mv3', '${goal.id}', '$_hh', 'funding', 'op-mv3-income', "
          "'2024-01-01T00:00:00Z', NULL)",
        ),
        throwsA(anything),
        reason: 'validate_funding_movement must reject non-transfer operation',
      );
    },
  );

  test(
    'MV-4. Release movement with wrong source account (not reserve) → rejected',
    () async {
      const srcId = 'src-mv4';
      const wrongSrcId = 'wrong-src-mv4';
      await createAccount(id: srcId);
      await createAccount(id: wrongSrcId);
      await creditAccount(srcId, 100000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-mv4')) as AppOk<SavingsGoal>)
              .value;

      // Transfer FROM wrong source (not the reserve).
      final opId = await insertTransferOp(
        id: 'op-mv4',
        sourceAccountId: wrongSrcId,
        destinationAccountId: srcId,
      );

      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
          "transfer_operation_id, created_at, release_reason) "
          "VALUES ('mov-mv4', '${goal.id}', '$_hh', 'release', '$opId', "
          "'2024-01-01T00:00:00Z', 'test reason')",
        ),
        throwsA(anything),
        reason:
            'validate_release_movement must reject transfer not sourced from the reserve',
      );
    },
  );

  test('MV-5. Release movement without reason → rejected', () async {
    const dstId = 'dst-mv5';
    await createAccount(id: dstId);

    final goal =
        ((await createGoal(idempotencyKey: 'ik-mv5')) as AppOk<SavingsGoal>)
            .value;

    // Transfer FROM the reserve (correct source).
    final opId = await insertTransferOp(
      id: 'op-mv5',
      sourceAccountId: goal.reserveAccountId,
      destinationAccountId: dstId,
    );

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
        "transfer_operation_id, created_at, release_reason) "
        "VALUES ('mov-mv5', '${goal.id}', '$_hh', 'release', '$opId', "
        "'2024-01-01T00:00:00Z', NULL)",
      ),
      throwsA(anything),
      reason:
          'validate_release_movement must require a non-null, non-empty release_reason',
    );
  });

  test(
    'MV-6. Duplicate movement for same operation → rejected by unique index',
    () async {
      const srcId = 'src-mv6';
      await createAccount(id: srcId);
      await creditAccount(srcId, 100000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-mv6')) as AppOk<SavingsGoal>)
              .value;

      final opId = await insertTransferOp(
        id: 'op-mv6',
        sourceAccountId: srcId,
        destinationAccountId: goal.reserveAccountId,
      );

      // First insert succeeds.
      await db.customStatement(
        "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
        "transfer_operation_id, created_at, release_reason) "
        "VALUES ('mov-mv6-1', '${goal.id}', '$_hh', 'funding', '$opId', "
        "'2024-01-01T00:00:00Z', NULL)",
      );

      // Second insert for the same operation must fail.
      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
          "transfer_operation_id, created_at, release_reason) "
          "VALUES ('mov-mv6-2', '${goal.id}', '$_hh', 'funding', '$opId', "
          "'2024-01-01T00:00:00Z', NULL)",
        ),
        throwsA(anything),
        reason:
            'idx_goal_movements_unique_operation must prevent duplicate operation reference',
      );
    },
  );

  test(
    'MV-7. UPDATE on goal_movements → rejected by no_update_goal_movements trigger',
    () async {
      const srcId = 'src-mv7';
      await createAccount(id: srcId);
      await creditAccount(srcId, 100000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-mv7')) as AppOk<SavingsGoal>)
              .value;

      final opId = await insertTransferOp(
        id: 'op-mv7',
        sourceAccountId: srcId,
        destinationAccountId: goal.reserveAccountId,
      );

      await db.customStatement(
        "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
        "transfer_operation_id, created_at, release_reason) "
        "VALUES ('mov-mv7', '${goal.id}', '$_hh', 'funding', '$opId', "
        "'2024-01-01T00:00:00Z', NULL)",
      );

      await expectLater(
        () => db.customStatement(
          "UPDATE goal_movements SET movement_type = 'release' WHERE id = 'mov-mv7'",
        ),
        throwsA(anything),
        reason:
            'no_update_goal_movements trigger must block all UPDATEs on movements',
      );
    },
  );

  test(
    'MV-8. DELETE on goal_movements → rejected by no_delete_goal_movements trigger',
    () async {
      const srcId = 'src-mv8';
      await createAccount(id: srcId);
      await creditAccount(srcId, 100000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-mv8')) as AppOk<SavingsGoal>)
              .value;

      final opId = await insertTransferOp(
        id: 'op-mv8',
        sourceAccountId: srcId,
        destinationAccountId: goal.reserveAccountId,
      );

      await db.customStatement(
        "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
        "transfer_operation_id, created_at, release_reason) "
        "VALUES ('mov-mv8', '${goal.id}', '$_hh', 'funding', '$opId', "
        "'2024-01-01T00:00:00Z', NULL)",
      );

      await expectLater(
        () => db.customStatement(
          "DELETE FROM goal_movements WHERE id = 'mov-mv8'",
        ),
        throwsA(anything),
        reason:
            'no_delete_goal_movements trigger must block all DELETEs on movements',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.3 – Section 5: Goal-to-reserve insertion validator (GR-4..GR-9)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // The validate_goal_reserve_on_insert trigger (v11) ensures that every
  // new goal row references a valid goalReserve account.

  test('GR-4. Insert goal with non-goalReserve account → rejected', () async {
    final normalId = await insertNormalAccount('gr4-normal');

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) "
        "VALUES ('goal-gr4', '$_hh', '$normalId', 'EGP', 'active', "
        "'ik-gr4', 'payload-gr4', '2024-01-01T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'GR-4: validate_goal_reserve_on_insert must reject non-goalReserve account',
    );
  });

  test('GR-5. Insert goal with cross-household reserve → rejected', () async {
    // Create a second household.
    const hh2 = 'hh-gr5-other';
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$hh2', 'Other HH', 'u-gr5', '2024-01-01', '2024-01-01')",
    );

    // Create a goalReserve in hh2 but try to assign it to a goal in _hh.
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('reserve-gr5-hh2', '$hh2', 'Reserve HH2', 'goalReserve', 'household', "
      "'goalReserve', 'EGP', 0, 0, 1, 0, 9999, 'test', "
      "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) "
        "VALUES ('goal-gr5', '$_hh', 'reserve-gr5-hh2', 'EGP', 'active', "
        "'ik-gr5', 'payload-gr5', '2024-01-01T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'GR-5: validate_goal_reserve_on_insert must reject cross-household reserve',
    );
  });

  test('GR-6. Insert goal with wrong-currency reserve → rejected', () async {
    // Create a goalReserve in _hh with USD currency but goal uses EGP.
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('reserve-gr6-usd', '$_hh', 'USD Reserve', 'goalReserve', 'household', "
      "'goalReserve', 'USD', 0, 0, 1, 0, 9999, 'test', "
      "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) "
        "VALUES ('goal-gr6', '$_hh', 'reserve-gr6-usd', 'EGP', 'active', "
        "'ik-gr6', 'payload-gr6', '2024-01-01T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'GR-6: validate_goal_reserve_on_insert must reject wrong-currency reserve',
    );
  });

  test('GR-7. Insert goal with spendable reserve → rejected', () async {
    // Insert a goalReserve with is_spendable=1 (violates constraint).
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('reserve-gr7-spend', '$_hh', 'Spendable Reserve', 'goalReserve', 'household', "
      "'goalReserve', 'EGP', 1, 0, 1, 0, 9999, 'test', "
      "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) "
        "VALUES ('goal-gr7', '$_hh', 'reserve-gr7-spend', 'EGP', 'active', "
        "'ik-gr7', 'payload-gr7', '2024-01-01T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'GR-7: validate_goal_reserve_on_insert must reject spendable reserve',
    );
  });

  test('GR-8. Insert goal with protected reserve → rejected', () async {
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('reserve-gr8-prot', '$_hh', 'Protected Reserve', 'goalReserve', 'household', "
      "'goalReserve', 'EGP', 0, 1, 1, 0, 9999, 'test', "
      "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) "
        "VALUES ('goal-gr8', '$_hh', 'reserve-gr8-prot', 'EGP', 'active', "
        "'ik-gr8', 'payload-gr8', '2024-01-01T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'GR-8: validate_goal_reserve_on_insert must reject protected reserve',
    );
  });

  test(
    'GR-9. Insert second goal with same reserve → rejected by unique index',
    () async {
      final goal =
          ((await createGoal(idempotencyKey: 'ik-gr9')) as AppOk<SavingsGoal>)
              .value;

      await expectLater(
        () => db.customStatement(
          "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
          "status, idempotency_key, idempotency_payload, created_at) "
          "VALUES ('goal-gr9-dup', '$_hh', '${goal.reserveAccountId}', 'EGP', 'active', "
          "'ik-gr9-dup', 'payload-dup', '2024-01-02T00:00:00Z')",
        ),
        throwsA(anything),
        reason:
            'GR-9: unique constraint must prevent two goals sharing a reserve',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.3 – Section 6: Movement household validation (MVEXT-1..4)
  // ══════════════════════════════════════════════════════════════════════════

  test('MVEXT-1. Funding movement with cross-household operation → rejected', () async {
    const srcId = 'src-mvext1';
    await createAccount(id: srcId);
    await creditAccount(srcId, 100000);

    final goal =
        ((await createGoal(idempotencyKey: 'ik-mvext1')) as AppOk<SavingsGoal>)
            .value;

    // Create a second household.
    const hh2 = 'hh-mvext1-other';
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$hh2', 'Other HH', 'u-mvext1', '2024-01-01', '2024-01-01')",
    );

    // Create the same accounts in hh2 (cross-household transfer).
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('src-mvext1-hh2', '$hh2', 'Src HH2', 'personalCashWallet', 'user', "
      "'available', 'EGP', 1, 0, 1, 0, 1, 'test', '2024-01-01', '2024-01-01')",
    );
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('reserve-mvext1-hh2', '$hh2', 'Reserve HH2', 'goalReserve', 'household', "
      "'goalReserve', 'EGP', 0, 0, 1, 0, 9999, 'test', '2024-01-01', '2024-01-01')",
    );

    // Insert a transfer in hh2.
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, source_account_id, "
      "destination_account_id, total_amount_minor_units, currency_code, effective_date, "
      "recorded_at, created_by, created_at, updated_at) "
      "VALUES ('op-mvext1-xhh', '$hh2', 'transfer', 'src-mvext1-hh2', "
      "'reserve-mvext1-hh2', 10000, 'EGP', '2024-01-01', '2024-01-01T00:00:00Z', "
      "'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );

    // Try to insert a movement in _hh referencing hh2's operation.
    await expectLater(
      () => db.customStatement(
        "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
        "transfer_operation_id, created_at) "
        "VALUES ('mov-mvext1', '${goal.id}', '$_hh', 'funding', "
        "'op-mvext1-xhh', '2024-01-01T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'MVEXT-1: validate_funding_movement must reject cross-household operation',
    );
  });

  test('MVEXT-2. Funding movement with cross-household source account → rejected', () async {
    const srcId = 'src-mvext2';
    await createAccount(id: srcId);
    await creditAccount(srcId, 100000);

    final goal =
        ((await createGoal(idempotencyKey: 'ik-mvext2')) as AppOk<SavingsGoal>)
            .value;

    // Create a second household with a cross-household source.
    const hh2 = 'hh-mvext2-other';
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$hh2', 'Other HH', 'u-mvext2', '2024-01-01', '2024-01-01')",
    );
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('cross-src-mvext2', '$hh2', 'Cross Src', 'personalCashWallet', 'user', "
      "'available', 'EGP', 1, 0, 1, 0, 1, 'test', '2024-01-01', '2024-01-01')",
    );

    // Insert a transfer where source is from hh2 but destination is in _hh.
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, source_account_id, "
      "destination_account_id, total_amount_minor_units, currency_code, effective_date, "
      "recorded_at, created_by, created_at, updated_at) "
      "VALUES ('op-mvext2-xsrc', '$_hh', 'transfer', 'cross-src-mvext2', "
      "'${goal.reserveAccountId}', 10000, 'EGP', '2024-01-01', '2024-01-01T00:00:00Z', "
      "'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
        "transfer_operation_id, created_at) "
        "VALUES ('mov-mvext2', '${goal.id}', '$_hh', 'funding', "
        "'op-mvext2-xsrc', '2024-01-01T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'MVEXT-2: validate_funding_movement_household must reject cross-household source account',
    );
  });

  test(
    'MVEXT-3. Release movement with cross-household destination account → rejected',
    () async {
      const srcId = 'src-mvext3';
      await createAccount(id: srcId);
      await creditAccount(srcId, 100000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-mvext3'))
                  as AppOk<SavingsGoal>)
              .value;

      // Fund the reserve.
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 50000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-mvext3',
      );

      // Create a second household with a cross-household destination.
      const hh2 = 'hh-mvext3-other';
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('$hh2', 'Other HH', 'u-mvext3', '2024-01-01', '2024-01-01')",
      );
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) "
        "VALUES ('cross-dst-mvext3', '$hh2', 'Cross Dst', 'personalCashWallet', 'user', "
        "'available', 'EGP', 1, 0, 1, 0, 1, 'test', '2024-01-01', '2024-01-01')",
      );

      // Insert a release transfer where destination is cross-household.
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, source_account_id, "
        "destination_account_id, total_amount_minor_units, currency_code, effective_date, "
        "recorded_at, created_by, created_at, updated_at) "
        "VALUES ('op-mvext3-xdst', '$_hh', 'transfer', '${goal.reserveAccountId}', "
        "'cross-dst-mvext3', 10000, 'EGP', '2024-01-01', '2024-01-01T00:00:00Z', "
        "'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
      );

      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
          "transfer_operation_id, created_at, release_reason) "
          "VALUES ('mov-mvext3', '${goal.id}', '$_hh', 'release', "
          "'op-mvext3-xdst', '2024-01-01T00:00:00Z', 'reason')",
        ),
        throwsA(anything),
        reason:
            'MVEXT-3: validate_release_movement_household must reject cross-household destination',
      );
    },
  );

  test('MVEXT-4. Valid same-household movement → succeeds (control)', () async {
    const srcId = 'src-mvext4';
    await createAccount(id: srcId);
    await creditAccount(srcId, 100000);

    final goal =
        ((await createGoal(idempotencyKey: 'ik-mvext4')) as AppOk<SavingsGoal>)
            .value;

    // Insert a valid same-household transfer.
    final opId = await insertTransferOp(
      id: 'op-mvext4',
      sourceAccountId: srcId,
      destinationAccountId: goal.reserveAccountId,
    );

    // Must succeed.
    await db.customStatement(
      "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
      "transfer_operation_id, created_at) "
      "VALUES ('mov-mvext4', '${goal.id}', '$_hh', 'funding', '$opId', "
      "'2024-01-01T00:00:00Z')",
    );

    final rows = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM goal_movements WHERE id = 'mov-mvext4'",
        )
        .get();
    expect(
      rows.first.read<int>('c'),
      1,
      reason: 'MVEXT-4: valid same-household movement must be accepted',
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.4 – Section 3: Movement-to-ledger guarantees (LEDG-1..6)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // These tests prove the enforcement boundary for each ledger invariant:
  //  - DB-level: trigger name cited.
  //  - Use-case-level: enforced by FundGoalUseCase atomicity (no partial writes).
  //
  //  LEDG-1. Missing debit → use case prevents partial write (atomicity).
  //          Mechanism: DriftGoalRepository.createGoal / fundGoal always inserts
  //          both legs inside a single DB transaction; no trigger needed.
  //  LEDG-2. Missing credit → same atomicity guarantee.
  //  LEDG-3. Unequal amounts → enforced by ledger repository code, not a trigger.
  //  LEDG-4. Wrong destination in funding → validate_funding_movement trigger.
  //  LEDG-5. Cross-household → validate_funding_movement_household trigger.
  //  LEDG-6. Non-transfer operation → goal_movement_transfer_type trigger.

  test(
    'LEDG-1. Funding with zero balance → use case fails, no partial entries',
    () async {
      const srcId = 'src-ledg1';
      await createAccount(id: srcId);
      // Deliberately do NOT credit srcId — balance = 0.

      final goal =
          ((await createGoal(idempotencyKey: 'ik-ledg1')) as AppOk<SavingsGoal>)
              .value;

      final entriesBefore = await db
          .customSelect(
            "SELECT COUNT(*) as c FROM ledger_entries "
            "WHERE household_id = '$_hh'",
          )
          .get();
      final countBefore = entriesBefore.first.read<int>('c');

      final result = await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-ledg1-fund',
      );
      expect(
        result,
        isA<AppInsufficientFunds<SavingsGoal>>(),
        reason: 'LEDG-1: use case must reject funding with no balance',
      );

      final entriesAfter = await db
          .customSelect(
            "SELECT COUNT(*) as c FROM ledger_entries "
            "WHERE household_id = '$_hh'",
          )
          .get();
      expect(
        entriesAfter.first.read<int>('c'),
        countBefore,
        reason: 'LEDG-1: no partial entries must be written on failure',
      );
    },
  );

  test('LEDG-2. Funding insufficient balance → no partial movements', () async {
    const srcId = 'src-ledg2';
    await createAccount(id: srcId);
    await creditAccount(srcId, 1000); // Only 1000, but request 5000.

    final goal =
        ((await createGoal(idempotencyKey: 'ik-ledg2')) as AppOk<SavingsGoal>)
            .value;

    final movsBefore = await db
        .customSelect("SELECT COUNT(*) as c FROM goal_movements")
        .get();
    final movCountBefore = movsBefore.first.read<int>('c');

    final result = await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 5000,
      householdId: _hh,
      idempotencyKey: 'ik-ledg2-fund',
    );
    expect(
      result,
      isA<AppInsufficientFunds<SavingsGoal>>(),
      reason: 'LEDG-2: insufficient balance must be rejected',
    );

    final movsAfter = await db
        .customSelect("SELECT COUNT(*) as c FROM goal_movements")
        .get();
    expect(
      movsAfter.first.read<int>('c'),
      movCountBefore,
      reason: 'LEDG-2: no partial movements on failure',
    );
  });

  test(
    'LEDG-3. Funding amount = 0 → use case rejects before DB (amount > 0 enforced)',
    () async {
      const srcId = 'src-ledg3';
      await createAccount(id: srcId);
      await creditAccount(srcId, 50000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-ledg3')) as AppOk<SavingsGoal>)
              .value;

      // Amount = 0 is blocked at the use-case validation level or DB
      // check_ledger_entry_amount trigger (amount_minor_units > 0).
      final result = await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 0,
        householdId: _hh,
        idempotencyKey: 'ik-ledg3-fund',
      );
      expect(
        result,
        isNot(isA<AppOk<SavingsGoal>>()),
        reason:
            'LEDG-3: zero-amount funding must be rejected (use-case or DB trigger)',
      );
    },
  );

  test(
    'LEDG-4. Goal movement with wrong destination → validate_funding_movement fires',
    () async {
      const srcId = 'src-ledg4';
      const wrongDstId = 'dst-ledg4-wrong';
      await createAccount(id: srcId);
      await createAccount(id: wrongDstId);
      await creditAccount(srcId, 100000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-ledg4')) as AppOk<SavingsGoal>)
              .value;

      // Insert a transfer to the WRONG destination (not the reserve).
      final opId = await insertTransferOp(
        id: 'op-ledg4-wrong',
        sourceAccountId: srcId,
        destinationAccountId: wrongDstId,
      );

      // Attempt to create a funding movement referencing this misrouted transfer.
      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
          "transfer_operation_id, created_at) "
          "VALUES ('mov-ledg4', '${goal.id}', '$_hh', 'funding', "
          "'$opId', '2024-01-01T00:00:00Z')",
        ),
        throwsA(anything),
        reason:
            'LEDG-4: validate_funding_movement must reject wrong destination',
      );
    },
  );

  test(
    'LEDG-5. Cross-household account in movement → validate_funding_movement_household fires',
    () async {
      // Create an account in a DIFFERENT household.
      const otherHh = 'hh-ledg5-other';
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('$otherHh', 'Other HH', 'u-ledg5', '2024-01-01', '2024-01-01')",
      );
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) "
        "VALUES ('xhh-src-ledg5', '$otherHh', 'Cross-HH Src', 'personalCashWallet', "
        "'user', 'available', 'EGP', 1, 0, 1, 0, 1, 'test', '2024-01-01', '2024-01-01')",
      );

      final goal =
          ((await createGoal(idempotencyKey: 'ik-ledg5')) as AppOk<SavingsGoal>)
              .value;

      // Insert a transfer where source is in the other household.
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, "
        "recorded_at, total_amount_minor_units, currency_code, created_by, "
        "created_at, updated_at, source_account_id, destination_account_id) "
        "VALUES ('op-ledg5-xhh', '$_hh', 'transfer', '2024-01-01', '2024-01-01', "
        "1000, 'EGP', 'test', '2024-01-01', '2024-01-01', 'xhh-src-ledg5', "
        "'${goal.reserveAccountId}')",
      );

      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
          "transfer_operation_id, created_at) "
          "VALUES ('mov-ledg5', '${goal.id}', '$_hh', 'funding', "
          "'op-ledg5-xhh', '2024-01-01T00:00:00Z')",
        ),
        throwsA(anything),
        reason:
            'LEDG-5: validate_funding_movement_household must reject cross-household source',
      );
    },
  );

  test(
    'LEDG-6. Unrelated transfer attached to goal movement → goal_movement_transfer_type or validate_funding_movement fires',
    () async {
      const srcId = 'src-ledg6';
      await createAccount(id: srcId);
      await creditAccount(srcId, 50000);

      final goal =
          ((await createGoal(idempotencyKey: 'ik-ledg6')) as AppOk<SavingsGoal>)
              .value;

      // Get the income operation id (type = 'income', not 'transfer').
      final opRows = await db
          .customSelect(
            "SELECT id FROM operations WHERE type = 'income' "
            "AND household_id = '$_hh' LIMIT 1",
          )
          .get();
      final incomeOpId = opRows.first.read<String>('id');

      // Attempt to attach an income operation to a goal movement.
      await expectLater(
        () => db.customStatement(
          "INSERT INTO goal_movements (id, goal_id, household_id, movement_type, "
          "transfer_operation_id, created_at) "
          "VALUES ('mov-ledg6', '${goal.id}', '$_hh', 'funding', "
          "'$incomeOpId', '2024-01-01T00:00:00Z')",
        ),
        throwsA(anything),
        reason:
            'LEDG-6: goal_movement_transfer_type trigger must block non-transfer ops',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.4 – Section 4: Reserve ownership classification (OWN-1..5)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // The v12 trigger validate_goal_reserve_on_insert enforces
  //   fa.owner_type = 'household'
  // rejecting child, spouse, user (personal), and shared owner types.

  test(
    'OWN-1. Goal with child-owner reserve → validate_goal_reserve_on_insert fires',
    () async {
      const reserveId = 'reserve-own1-child';
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) "
        "VALUES ('$reserveId', '$_hh', 'Child Reserve', 'goalReserve', 'child', "
        "'goalReserve', 'EGP', 0, 0, 1, 0, 9999, 'test', '2024-01-01', '2024-01-01')",
      );

      await expectLater(
        () => db.customStatement(
          "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
          "status, idempotency_key, idempotency_payload, created_at) "
          "VALUES ('goal-own1', '$_hh', '$reserveId', 'EGP', 'active', "
          "'ik-own1', 'payload-own1', '2024-01-01T00:00:00Z')",
        ),
        throwsA(anything),
        reason: 'OWN-1: child-owner reserve must be rejected by trigger',
      );
    },
  );

  test(
    'OWN-2. Goal with spouse-owner reserve → validate_goal_reserve_on_insert fires',
    () async {
      const reserveId = 'reserve-own2-spouse';
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) "
        "VALUES ('$reserveId', '$_hh', 'Spouse Reserve', 'goalReserve', 'spouse', "
        "'goalReserve', 'EGP', 0, 0, 1, 0, 9999, 'test', '2024-01-01', '2024-01-01')",
      );

      await expectLater(
        () => db.customStatement(
          "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
          "status, idempotency_key, idempotency_payload, created_at) "
          "VALUES ('goal-own2', '$_hh', '$reserveId', 'EGP', 'active', "
          "'ik-own2', 'payload-own2', '2024-01-01T00:00:00Z')",
        ),
        throwsA(anything),
        reason: 'OWN-2: spouse-owner reserve must be rejected',
      );
    },
  );

  test(
    'OWN-3. Goal with user (personal) owner reserve → validate_goal_reserve_on_insert fires',
    () async {
      const reserveId = 'reserve-own3-user';
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) "
        "VALUES ('$reserveId', '$_hh', 'User Reserve', 'goalReserve', 'user', "
        "'goalReserve', 'EGP', 0, 0, 1, 0, 9999, 'test', '2024-01-01', '2024-01-01')",
      );

      await expectLater(
        () => db.customStatement(
          "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
          "status, idempotency_key, idempotency_payload, created_at) "
          "VALUES ('goal-own3', '$_hh', '$reserveId', 'EGP', 'active', "
          "'ik-own3', 'payload-own3', '2024-01-01T00:00:00Z')",
        ),
        throwsA(anything),
        reason: 'OWN-3: user (personal) owner reserve must be rejected',
      );
    },
  );

  test(
    'OWN-4. Change owner_type of existing goalReserve → no_modify_reserve_owner_type fires',
    () async {
      const reserveId = 'reserve-own4';
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) "
        "VALUES ('$reserveId', '$_hh', 'Reserve Own4', 'goalReserve', 'household', "
        "'goalReserve', 'EGP', 0, 0, 1, 0, 9999, 'test', '2024-01-01', '2024-01-01')",
      );

      await expectLater(
        () => db.customStatement(
          "UPDATE financial_accounts SET owner_type = 'user' WHERE id = '$reserveId'",
        ),
        throwsA(anything),
        reason:
            'OWN-4: no_modify_reserve_owner_type must prevent owner_type change on goalReserve',
      );

      // Verify value unchanged.
      final row = await db
          .customSelect(
            "SELECT owner_type FROM financial_accounts WHERE id = '$reserveId'",
          )
          .get();
      expect(
        row.first.read<String>('owner_type'),
        'household',
        reason: 'OWN-4: owner_type must remain household',
      );
    },
  );

  test('OWN-5. Goal with household-owner reserve → succeeds', () async {
    // createGoal via use case sets ownerType = household; must succeed.
    final result = await createGoal(idempotencyKey: 'ik-own5');
    expect(
      result,
      isA<AppOk<SavingsGoal>>(),
      reason: 'OWN-5: household-owner reserve must be accepted',
    );

    final goal = (result as AppOk<SavingsGoal>).value;
    final row = await db
        .customSelect(
          "SELECT owner_type FROM financial_accounts WHERE id = '${goal.reserveAccountId}'",
        )
        .get();
    expect(
      row.first.read<String>('owner_type'),
      'household',
      reason: 'OWN-5: reserve owner_type must be household',
    );
  });
}
