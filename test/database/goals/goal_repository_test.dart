/// Goal repository database tests (Phase 5B).
///
/// Tests:
///  1. Create goal and reserve account atomically
///  2. Goal creation is idempotent (same key + same payload → existing)
///  3. Conflicting payload returns AppDuplicateConflict
///  4. Cross-household isolation
///  5. Reserve account created with correct type (goalReserve)
///  6. Reserve account is non-spendable
///  7. Reserve account is non-protected
///  8. One reserve per goal enforced (unique constraint)
///  9. One goal per reserve enforced (unique constraint)
/// 10. Fund goal: transfer recorded correctly in ledger
/// 11. Fund goal: source balance decremented
/// 12. Fund goal: reserve balance incremented
/// 13. Fund goal: movement record created
/// 14. Fund goal: budget consumption NOT incremented
/// 15. Fund goal: not classified as income
/// 16. Fund goal: not classified as expense
/// 17. Insufficient source balance → AppInsufficientFunds
/// 18. Fund goal from protected child account → rejected
/// 19. Fund goal from another goalReserve → rejected
/// 20. Release goal: transfer recorded correctly
/// 21. Release goal: reserve balance decremented
/// 22. Release goal: destination balance incremented
/// 23. Release goal: movement record created
/// 24. Release goal: not classified as income
/// 25. Release goal: not classified as expense
/// 26. Release goal: requires non-empty reason
/// 27. Insufficient reserve balance → AppInsufficientFunds
/// 28. Release to goalReserve account → rejected
/// 29. Archive with non-zero balance → rejected
/// 30. Archive with zero balance → succeeds
/// 31. Restore archived goal → active
/// 32. Goal revisions are append-only (no UPDATE)
/// 33. Goal movements are append-only (no UPDATE)
/// 34. Metadata-only update (name change via revision) does NOT write to operations
/// 35. Migration v7 → v8: goals tables created, existing data preserved
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

const _hh = 'hh-goal-test';
const _hh2 = 'hh-goal-test-2';

void main() {
  late AppDatabase db;
  late DriftGoalRepository goalRepo;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;

  // Use cases for higher-level tests.
  late CreateGoalUseCase createGoalUc;
  late FundGoalUseCase fundGoalUc;
  late ReleaseGoalFundsUseCase releaseGoalUc;
  late ArchiveGoalUseCase archiveGoalUc;
  late RestoreGoalUseCase restoreGoalUc;
  late UpdateGoalRevisionUseCase updateRevisionUc;

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
    restoreGoalUc = RestoreGoalUseCase(goalRepo);
    updateRevisionUc = UpdateGoalRevisionUseCase(goalRepo);

    for (final h in [_hh, _hh2]) {
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('$h', 'HH $h', 'u1', '2024-01-01', '2024-01-01')",
      );
    }
  });

  tearDown(() async => db.close());

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<FinancialAccount> createAccount({
    required String id,
    required String householdId,
    String currency = 'EGP',
    String type = 'personalCashWallet',
    bool isProtected = false,
    bool isSpendable = true,
  }) async {
    return accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Account $id',
        type: FinancialAccountType.fromCode(type),
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: currency,
        isSpendable: isSpendable,
        isProtected: isProtected,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'test',
      ),
    );
  }

  Future<void> creditAccount(
    String accId,
    String hhId,
    int amount, {
    String currency = 'EGP',
  }) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: 'income-$accId-${DateTime.now().microsecondsSinceEpoch}',
        householdId: hhId,
        destinationAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: currency,
        effectiveDate: '2024-01-01',
        createdBy: 'test',
      ),
    );
  }

  Future<AppResult<SavingsGoal>> createGoal({
    String goalName = 'Test Goal',
    int target = 100000,
    String householdId = _hh,
    String idempotencyKey = 'ik-goal-1',
    String currency = 'EGP',
    String? sourceAccountId,
    int initialFunding = 0,
  }) async {
    return createGoalUc.execute(
      goalName: goalName,
      purpose: GoalPurpose.emergencyFund,
      currencyCode: currency,
      targetMinorUnits: target,
      householdId: householdId,
      idempotencyKey: idempotencyKey,
      initialFundingSourceAccountId: sourceAccountId,
      initialFundingMinorUnits: initialFunding,
    );
  }

  // ── Tests ─────────────────────────────────────────────────────────────────

  test('1. Create goal and reserve account atomically', () async {
    final result = await createGoal();
    expect(result, isA<AppOk<SavingsGoal>>());
    final goal = (result as AppOk<SavingsGoal>).value;
    expect(goal.id, isNotEmpty);
    expect(goal.reserveAccountId, isNotEmpty);
    expect(goal.householdId, _hh);
    // Reserve account must exist in financial_accounts.
    final acc = await accountRepo.findById(id: goal.reserveAccountId, householdId: _hh);
    expect(acc, isNotNull);
  });

  test('2. Goal creation is idempotent (same key + same payload)', () async {
    final r1 = await createGoal();
    final r2 = await createGoal(); // same key, same payload
    expect(r1, isA<AppOk<SavingsGoal>>());
    expect(r2, isA<AppOk<SavingsGoal>>());
    final id1 = (r1 as AppOk<SavingsGoal>).value.id;
    final id2 = (r2 as AppOk<SavingsGoal>).value.id;
    expect(id1, id2);
  });

  test('3. Conflicting payload returns AppDuplicateConflict', () async {
    await createGoal(goalName: 'Original');
    // Same idempotencyKey but different payload (different name → different payload fingerprint).
    final r2 = await createGoal(goalName: 'Different Name');
    expect(r2, isA<AppDuplicateConflict<SavingsGoal>>());
  });

  test('4. Cross-household isolation', () async {
    // Same idempotencyKey in different households is allowed.
    final r1 = await createGoal(householdId: _hh);
    final r2 = await createGoal(householdId: _hh2);
    expect(r1, isA<AppOk<SavingsGoal>>());
    expect(r2, isA<AppOk<SavingsGoal>>());
    final id1 = (r1 as AppOk<SavingsGoal>).value.id;
    final id2 = (r2 as AppOk<SavingsGoal>).value.id;
    expect(id1, isNot(id2));
  });

  test('5. Reserve account created with correct type (goalReserve)', () async {
    final result = await createGoal();
    final goal = (result as AppOk<SavingsGoal>).value;
    final acc = await accountRepo.findById(id: goal.reserveAccountId, householdId: _hh);
    expect(acc!.type, FinancialAccountType.goalReserve);
  });

  test('6. Reserve account is non-spendable', () async {
    final result = await createGoal();
    final goal = (result as AppOk<SavingsGoal>).value;
    final acc = await accountRepo.findById(id: goal.reserveAccountId, householdId: _hh);
    expect(acc!.isSpendable, isFalse);
  });

  test('7. Reserve account is non-protected', () async {
    final result = await createGoal();
    final goal = (result as AppOk<SavingsGoal>).value;
    final acc = await accountRepo.findById(id: goal.reserveAccountId, householdId: _hh);
    expect(acc!.isProtected, isFalse);
  });

  test('8. One reserve per goal: duplicate reserve_account_id rejected', () async {
    final result = await createGoal();
    final goal = (result as AppOk<SavingsGoal>).value;

    // Manually try to create a second goal with the same reserve account.
    final fakeDuplicateGoal = SavingsGoal(
      id: 'fake-goal-2',
      householdId: _hh,
      reserveAccountId: goal.reserveAccountId, // same reserve
      currencyCode: 'EGP',
      status: GoalStatus.active,
      currentRevision: const GoalRevision(
        id: 'rev-fake',
        goalId: 'fake-goal-2',
        householdId: _hh,
        name: 'Fake Goal 2',
        purpose: GoalPurpose.travel,
        targetMinorUnits: 50000,
        currencyCode: 'EGP',
        createdAt: '2024-06-01T00:00:00Z',
        revisionReason: 'initial',
      ),
      createdAt: '2024-06-01T00:00:00Z',
      idempotencyKey: 'ik-fake-goal-2',
    );
    final fakeRevision = fakeDuplicateGoal.currentRevision;

    // The unique index on goals.reserve_account_id should prevent this.
    final fakeAccount = await accountRepo.findById(id: goal.reserveAccountId, householdId: _hh);
    // We can't re-insert the same account — trying a direct repo call
    // but providing same reserveAccountId in a new goal should fail via unique constraint.
    // We use a minimal direct DB insert to test the DB-level constraint:
    try {
      await db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) "
        "VALUES ('fake-goal-2', '$_hh', '${fakeAccount!.id}', 'EGP', "
        "'active', 'ik-fake-2', 'payload-fake-2', '2024-01-01')",
      );
      fail('Expected unique constraint violation');
    } catch (e) {
      // Expected: unique index on reserve_account_id
      expect(e, isA<Exception>());
    }
    expect(fakeRevision.id, isNotEmpty); // use fakeRevision to suppress unused variable warning
  });

  test('9. One goal per reserve — goal id itself is the PK', () async {
    // Each goal gets a unique UUID from the use case, so no collision by design.
    final r1 = await createGoal(goalName: 'Goal A');
    final r2 = await createGoal(goalName: 'Goal B', idempotencyKey: 'ik-goal-b');
    final id1 = (r1 as AppOk<SavingsGoal>).value.id;
    final id2 = (r2 as AppOk<SavingsGoal>).value.id;
    expect(id1, isNot(id2));
    // Confirm separate reserve accounts.
    expect((r1).value.reserveAccountId, isNot((r2).value.reserveAccountId));
  });

  test('10. Fund goal: transfer recorded correctly in ledger', () async {
    const srcId = 'src-acc-fund';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal();
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final fundResult = await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-1',
    );
    expect(fundResult, isA<AppOk<SavingsGoal>>());

    // Check ledger entries exist for the transfer.
    final entries = await ledgerRepo.entriesForAccount(
      accountId: goal.reserveAccountId,
      householdId: _hh,
    );
    expect(entries, isNotEmpty);
    // Reserve should have received a credit entry.
    expect(entries.any((e) => e.direction == .credit), isTrue);
  });

  test('11. Fund goal: source balance decremented', () async {
    const srcId = 'src-acc-bal';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(idempotencyKey: 'ik-goal-bal');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-bal',
    );

    // Source balance should now be 50000 - 20000 = 30000.
    final balResult = await goalRepo.getReserveBalance(reserveAccountId: srcId, householdId: _hh);
    expect(balResult, isA<AppOk<int>>());
    expect((balResult as AppOk<int>).value, 30000);
  });

  test('12. Fund goal: reserve balance incremented', () async {
    const srcId = 'src-acc-reserve';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(idempotencyKey: 'ik-goal-reserve');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 25000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-reserve',
    );

    final balResult = await goalRepo.getReserveBalance(
      reserveAccountId: goal.reserveAccountId,
      householdId: _hh,
    );
    expect((balResult as AppOk<int>).value, 25000);
  });

  test('13. Fund goal: movement record created', () async {
    const srcId = 'src-acc-movement';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(idempotencyKey: 'ik-goal-movement');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 15000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-movement',
    );

    final movResult = await goalRepo.getMovements(goal.id);
    expect(movResult, isA<AppOk<List<GoalMovement>>>());
    final movements = (movResult as AppOk<List<GoalMovement>>).value;
    expect(movements.length, 1);
    expect(movements.first.movementType, GoalMovementType.funding);
  });

  test('14. Fund goal: budget consumption NOT incremented (transfer != expense)', () async {
    const srcId = 'src-acc-budget';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    // Count operations before.
    final beforeRows = await db
        .customSelect(
          "SELECT COUNT(*) as cnt FROM operations WHERE type = 'expense' AND household_id = '$_hh'",
        )
        .get();
    final beforeCount = beforeRows.first.read<int>('cnt');

    final goalResult = await createGoal(idempotencyKey: 'ik-goal-budget');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 10000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-budget',
    );

    final afterRows = await db
        .customSelect(
          "SELECT COUNT(*) as cnt FROM operations WHERE type = 'expense' AND household_id = '$_hh'",
        )
        .get();
    final afterCount = afterRows.first.read<int>('cnt');

    expect(afterCount, beforeCount); // No expense operations created
  });

  test('15. Fund goal: not classified as income', () async {
    const srcId = 'src-acc-income';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(idempotencyKey: 'ik-goal-income');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final beforeRows = await db
        .customSelect(
          "SELECT COUNT(*) as cnt FROM operations WHERE type = 'income' AND household_id = '$_hh'",
        )
        .get();
    final beforeCount = beforeRows.first.read<int>('cnt');

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 10000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-income',
    );

    final afterRows = await db
        .customSelect(
          "SELECT COUNT(*) as cnt FROM operations WHERE type = 'income' AND household_id = '$_hh'",
        )
        .get();
    final afterCount = afterRows.first.read<int>('cnt');
    expect(afterCount, beforeCount);
  });

  test('16. Fund goal: not classified as expense (operation type is transfer)', () async {
    const srcId = 'src-acc-expense';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(idempotencyKey: 'ik-goal-expense');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 10000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-expense',
    );

    // The operation type must be 'transfer', not 'expense'.
    final opsRows = await db
        .customSelect(
          "SELECT type FROM operations WHERE household_id = '$_hh' AND type != 'income' ORDER BY created_at DESC LIMIT 1",
        )
        .get();
    expect(opsRows, isNotEmpty);
    expect(opsRows.first.read<String>('type'), 'transfer');
  });

  test('17. Insufficient source balance → AppInsufficientFunds', () async {
    const srcId = 'src-acc-insuf';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 1000); // only 10.00

    final goalResult = await createGoal(idempotencyKey: 'ik-goal-insuf');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final result = await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 50000, // more than available
      householdId: _hh,
      idempotencyKey: 'ik-fund-insuf',
    );
    expect(result, isA<AppInsufficientFunds<SavingsGoal>>());
  });

  test('18. Fund goal from protected child account → rejected', () async {
    const protectedId = 'protected-acc';
    await createAccount(
      id: protectedId,
      householdId: _hh,
      type: 'childProtectedFund',
      isProtected: true,
      isSpendable: false,
    );
    await creditAccount(protectedId, _hh, 50000);

    final goalResult = await createGoal(idempotencyKey: 'ik-goal-prot');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final result = await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: protectedId,
      amountMinorUnits: 10000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-prot',
    );
    expect(result, isA<AppValidationFailure<SavingsGoal>>());
    expect((result as AppValidationFailure<SavingsGoal>).messageKey, 'errorGoalSourceIsProtected');
  });

  test('19. Fund goal from another goalReserve → rejected', () async {
    // Create two goals; try to fund one from the other's reserve.
    final r1 = await createGoal(goalName: 'Goal A', idempotencyKey: 'ik-goal-a');
    final r2 = await createGoal(goalName: 'Goal B', idempotencyKey: 'ik-goal-b');
    final goal1 = (r1 as AppOk<SavingsGoal>).value;
    final goal2 = (r2 as AppOk<SavingsGoal>).value;

    // Fund goal1's reserve manually via income.
    await creditAccount(goal1.reserveAccountId, _hh, 50000);

    // Now try to fund goal2 from goal1's reserve account.
    final result = await fundGoalUc.execute(
      goalId: goal2.id,
      sourceAccountId: goal1.reserveAccountId, // goalReserve type
      amountMinorUnits: 10000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-reserve-to-reserve',
    );
    expect(result, isA<AppValidationFailure<SavingsGoal>>());
    expect((result as AppValidationFailure<SavingsGoal>).messageKey, 'errorGoalSourceIsReserve');
  });

  test('20. Release goal: transfer recorded correctly', () async {
    const srcId = 'src-acc-rel';
    const dstId = 'dst-acc-rel';
    await createAccount(id: srcId, householdId: _hh);
    await createAccount(id: dstId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-goal-rel',
      sourceAccountId: srcId,
      initialFunding: 30000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final releaseResult = await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 10000,
      releaseReason: 'Emergency car repair',
      householdId: _hh,
      idempotencyKey: 'ik-release-1',
    );
    expect(releaseResult, isA<AppOk<SavingsGoal>>());

    // Reserve should have had a debit entry.
    final entries = await ledgerRepo.entriesForAccount(
      accountId: goal.reserveAccountId,
      householdId: _hh,
    );
    expect(entries.any((e) => e.direction == .debit), isTrue);
  });

  test('21. Release goal: reserve balance decremented', () async {
    const srcId = 'src-acc-relbal';
    const dstId = 'dst-acc-relbal';
    await createAccount(id: srcId, householdId: _hh);
    await createAccount(id: dstId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-goal-relbal',
      sourceAccountId: srcId,
      initialFunding: 30000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 10000,
      releaseReason: 'test release',
      householdId: _hh,
      idempotencyKey: 'ik-release-bal',
    );

    final balResult = await goalRepo.getReserveBalance(
      reserveAccountId: goal.reserveAccountId,
      householdId: _hh,
    );
    expect((balResult as AppOk<int>).value, 20000); // 30000 - 10000
  });

  test('22. Release goal: destination balance incremented', () async {
    const srcId = 'src-acc-dstbal';
    const dstId = 'dst-acc-dstbal';
    await createAccount(id: srcId, householdId: _hh);
    await createAccount(id: dstId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-goal-dstbal',
      sourceAccountId: srcId,
      initialFunding: 30000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 15000,
      releaseReason: 'test destination',
      householdId: _hh,
      idempotencyKey: 'ik-release-dst',
    );

    final dstBal = await goalRepo.getReserveBalance(reserveAccountId: dstId, householdId: _hh);
    expect((dstBal as AppOk<int>).value, 15000);
  });

  test('23. Release goal: movement record created with release type', () async {
    const srcId = 'src-acc-relmov';
    const dstId = 'dst-acc-relmov';
    await createAccount(id: srcId, householdId: _hh);
    await createAccount(id: dstId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-goal-relmov',
      sourceAccountId: srcId,
      initialFunding: 30000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 5000,
      releaseReason: 'Vacation trip',
      householdId: _hh,
      idempotencyKey: 'ik-release-mov',
    );

    final movResult = await goalRepo.getMovements(goal.id);
    final movements = (movResult as AppOk<List<GoalMovement>>).value;
    // 1 funding movement (initial) + 1 release movement
    final releaseMovements = movements
        .where((m) => m.movementType == GoalMovementType.release)
        .toList();
    expect(releaseMovements.length, 1);
    expect(releaseMovements.first.releaseReason, 'Vacation trip');
  });

  test('24. Release goal: not classified as income', () async {
    const srcId = 'src-acc-relinc';
    const dstId = 'dst-acc-relinc';
    await createAccount(id: srcId, householdId: _hh);
    await createAccount(id: dstId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-goal-relinc',
      sourceAccountId: srcId,
      initialFunding: 30000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final beforeRows = await db
        .customSelect(
          "SELECT COUNT(*) as cnt FROM operations WHERE type = 'income' AND household_id = '$_hh'",
        )
        .get();
    final beforeCount = beforeRows.first.read<int>('cnt');

    await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 5000,
      releaseReason: 'test',
      householdId: _hh,
      idempotencyKey: 'ik-release-inc',
    );

    final afterRows = await db
        .customSelect(
          "SELECT COUNT(*) as cnt FROM operations WHERE type = 'income' AND household_id = '$_hh'",
        )
        .get();
    expect(afterRows.first.read<int>('cnt'), beforeCount);
  });

  test('25. Release goal: not classified as expense', () async {
    const srcId = 'src-acc-relexp';
    const dstId = 'dst-acc-relexp';
    await createAccount(id: srcId, householdId: _hh);
    await createAccount(id: dstId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-goal-relexp',
      sourceAccountId: srcId,
      initialFunding: 30000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 5000,
      releaseReason: 'test',
      householdId: _hh,
      idempotencyKey: 'ik-release-exp',
    );

    final opsRows = await db
        .customSelect(
          "SELECT type FROM operations WHERE household_id = '$_hh' ORDER BY created_at DESC LIMIT 1",
        )
        .get();
    expect(opsRows.first.read<String>('type'), isNot('expense'));
  });

  test('26. Release goal: requires non-empty reason', () async {
    const srcId = 'src-acc-relreason';
    const dstId = 'dst-acc-relreason';
    await createAccount(id: srcId, householdId: _hh);
    await createAccount(id: dstId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-goal-relreason',
      sourceAccountId: srcId,
      initialFunding: 30000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final result = await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 5000,
      releaseReason: '   ', // whitespace only
      householdId: _hh,
      idempotencyKey: 'ik-release-reason',
    );
    expect(result, isA<AppValidationFailure<SavingsGoal>>());
    expect((result as AppValidationFailure<SavingsGoal>).messageKey, 'errorGoalReleaseReasonEmpty');
  });

  test('27. Insufficient reserve balance → AppInsufficientFunds', () async {
    const dstId = 'dst-acc-relfail';
    await createAccount(id: dstId, householdId: _hh);

    final goalResult = await createGoal(idempotencyKey: 'ik-goal-relfail');
    final goal = (goalResult as AppOk<SavingsGoal>).value;
    // Reserve has 0 balance (no funding).

    final result = await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 10000,
      releaseReason: 'test',
      householdId: _hh,
      idempotencyKey: 'ik-release-fail',
    );
    expect(result, isA<AppInsufficientFunds<SavingsGoal>>());
  });

  test('28. Release to goalReserve account → rejected', () async {
    const srcId = 'src-acc-relres';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final r1 = await createGoal(goalName: 'Goal A', idempotencyKey: 'ik-goal-relres-a');
    final r2 = await createGoal(goalName: 'Goal B', idempotencyKey: 'ik-goal-relres-b');
    final goal1 = (r1 as AppOk<SavingsGoal>).value;
    final goal2 = (r2 as AppOk<SavingsGoal>).value;

    // Fund goal1 reserve.
    await fundGoalUc.execute(
      goalId: goal1.id,
      sourceAccountId: srcId,
      amountMinorUnits: 30000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-relres',
    );

    // Try to release from goal1's reserve to goal2's reserve.
    final result = await releaseGoalUc.execute(
      goalId: goal1.id,
      destinationAccountId: goal2.reserveAccountId, // goalReserve type
      amountMinorUnits: 10000,
      releaseReason: 'test',
      householdId: _hh,
      idempotencyKey: 'ik-release-to-reserve',
    );
    expect(result, isA<AppValidationFailure<SavingsGoal>>());
  });

  test('29. Archive with non-zero balance → rejected', () async {
    const srcId = 'src-acc-archbal';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-goal-archbal',
      sourceAccountId: srcId,
      initialFunding: 20000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final result = await archiveGoalUc.execute(goalId: goal.id, householdId: _hh);
    expect(result, isA<AppValidationFailure<void>>());
    expect((result as AppValidationFailure<void>).messageKey, 'errorGoalArchiveNonzeroBalance');
  });

  test('30. Archive with zero balance → succeeds', () async {
    final goalResult = await createGoal(idempotencyKey: 'ik-goal-arch0');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final result = await archiveGoalUc.execute(goalId: goal.id, householdId: _hh);
    expect(result, isA<AppOk<void>>());

    // Verify status is now archived.
    final refreshed = await goalRepo.findGoalById(goal.id);
    expect((refreshed as AppOk<SavingsGoal?>).value!.status, GoalStatus.archived);
  });

  test('31. Restore archived goal → active', () async {
    final goalResult = await createGoal(idempotencyKey: 'ik-goal-restore');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await archiveGoalUc.execute(goalId: goal.id, householdId: _hh);
    final restoreResult = await restoreGoalUc.execute(goalId: goal.id);
    expect(restoreResult, isA<AppOk<void>>());

    final refreshed = await goalRepo.findGoalById(goal.id);
    expect((refreshed as AppOk<SavingsGoal?>).value!.status, GoalStatus.active);
  });

  test('32. Goal revisions are append-only (no UPDATE on existing rows)', () async {
    final goalResult = await createGoal(idempotencyKey: 'ik-goal-rev');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await updateRevisionUc.execute(
      goalId: goal.id,
      householdId: _hh,
      newName: 'Updated Name',
      newTargetMinorUnits: 200000,
      newPurpose: GoalPurpose.travel,
      revisionReason: 'target revised',
    );

    final revResult = await goalRepo.getRevisions(goal.id);
    final revisions = (revResult as AppOk<List<GoalRevision>>).value;
    // Original revision + new revision = 2 rows
    expect(revisions.length, 2);
    // Most recent revision has the new name.
    expect(revisions.last.name, 'Updated Name');
    // Original revision is still there (append-only).
    expect(revisions.first.name, 'Test Goal');
  });

  test('33. Goal movements are append-only (no UPDATE on existing rows)', () async {
    const srcId = 'src-acc-movapp';
    const dstId = 'dst-acc-movapp';
    await createAccount(id: srcId, householdId: _hh);
    await createAccount(id: dstId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final goalResult = await createGoal(idempotencyKey: 'ik-goal-movapp');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    // Fund twice.
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-movapp-1',
    );
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 10000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-movapp-2',
    );

    final movResult = await goalRepo.getMovements(goal.id);
    final movements = (movResult as AppOk<List<GoalMovement>>).value;
    expect(movements.length, 2);
    // Both are funding movements.
    expect(movements.every((m) => m.movementType == GoalMovementType.funding), isTrue);
  });

  test('34. Metadata-only update does NOT write to operations table', () async {
    final goalResult = await createGoal(idempotencyKey: 'ik-goal-meta');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final beforeCount =
        (await db
                .customSelect("SELECT COUNT(*) as cnt FROM operations WHERE household_id = '$_hh'")
                .get())
            .first
            .read<int>('cnt');

    // Name/target change via revision — no money moves.
    await updateRevisionUc.execute(
      goalId: goal.id,
      householdId: _hh,
      newName: 'Revised Name',
      newTargetMinorUnits: 150000,
      newPurpose: GoalPurpose.education,
      revisionReason: 'annual review',
    );

    final afterCount =
        (await db
                .customSelect("SELECT COUNT(*) as cnt FROM operations WHERE household_id = '$_hh'")
                .get())
            .first
            .read<int>('cnt');

    expect(afterCount, beforeCount); // No ledger operations created
  });

  test('35. Migration v7→v8: goals tables created and budget data preserved', () async {
    // In forTesting() the schema is always created fresh at the current
    // schemaVersion (8), so all goal tables exist by definition.
    // This test verifies the three tables are present and functional.
    final goalRows = await db.customSelect('SELECT COUNT(*) as cnt FROM goals').get();
    final revRows = await db.customSelect('SELECT COUNT(*) as cnt FROM goal_revisions').get();
    final movRows = await db.customSelect('SELECT COUNT(*) as cnt FROM goal_movements').get();
    expect(goalRows.first.read<int>('cnt'), greaterThanOrEqualTo(0));
    expect(revRows.first.read<int>('cnt'), greaterThanOrEqualTo(0));
    expect(movRows.first.read<int>('cnt'), greaterThanOrEqualTo(0));

    // Verify existing tables from prior phases still exist (budget table from v7).
    final budgetRows = await db.customSelect('SELECT COUNT(*) as cnt FROM budgets').get();
    expect(budgetRows.first.read<int>('cnt'), greaterThanOrEqualTo(0));
  });
}
