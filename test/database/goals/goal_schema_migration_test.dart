/// Phase 5B schema integrity and immutability tests.
///
/// Complements goal_repository_test.dart with raw-SQL-level verifications that
/// cannot be satisfied at the repository API boundary alone.
///
/// Tests (Section 4 – Schema and migration):
///  SM-1.  Fresh schema v8 creates all goal tables
///  SM-2.  Unique index idx_goals_reserve_account is enforced
///  SM-3.  Unique index idx_goals_idempotency is enforced
///  SM-4.  Budget table from v7 is present (migration baseline)
///  SM-5.  All prior-phase tables present in schema v8
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

  test('SM-1. Fresh schema v8 creates all goal tables', () async {
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

  test('SM-5. All prior-phase tables present in schema v8', () async {
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
}
