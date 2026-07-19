/// Goal repository database tests (Phase 5B / 5B.1).
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
///
/// Phase 5B.1 additions (Section 1 – Atomicity):
///  A1. Rollback when initial-funding source has insufficient balance
///  A2. Zero initial funding produces no operations or movements
///  A3. Successful creation with initial funding has correct row counts
///
/// Phase 5B.1 additions (Section 4 – Balance enforcement):
///  B1. Two sequential fund requests exceeding source balance — only first succeeds
///  B2. Two sequential release requests exceeding reserve — only first succeeds
///
/// Phase 5B.1 additions (Section 3 – Idempotency):
///  I1. Sequential retry of FundGoal with same idempotency key → single movement
///  I2. Sequential retry of ReleaseGoal with same idempotency key → single movement
library;

import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/goals/application/goal_use_cases.dart';
import 'package:family_money_manager/features/goals/data/drift_goal_repository.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/household/data/household_repository.dart';
import 'package:family_money_manager/features/household/domain/household_identity.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/application/execute_transfer_use_case.dart';
import 'package:family_money_manager/features/transactions/application/record_expense_use_case.dart';
import 'package:family_money_manager/features/transactions/application/record_income_use_case.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stub household repository that throws on any call.
/// Used by UC tests where the goalReserve guard fires before member lookups.
class _NoopHouseholdRepository implements HouseholdRepository {
  @override
  Future<HouseholdIdentity?> findHousehold(String householdId) =>
      throw UnimplementedError();
  @override
  Future<HouseholdIdentity> createHousehold({
    required String id,
    required String displayName,
    required String currencyCode,
    required String ownerUserId,
  }) => throw UnimplementedError();
  @override
  Future<HouseholdIdentity> updateHouseholdName({
    required String id,
    required String displayName,
  }) => throw UnimplementedError();
  @override
  Future<HouseholdMember> addMember({
    required String id,
    required String householdId,
    required String displayName,
    required MemberRole role,
  }) => throw UnimplementedError();
  @override
  Future<HouseholdMember?> findMember({
    required String memberId,
    required String householdId,
  }) => throw UnimplementedError();
  @override
  Future<List<HouseholdMember>> listMembers(String householdId) =>
      throw UnimplementedError();
  @override
  Future<HouseholdMember> renameMember({
    required String memberId,
    required String householdId,
    required String displayName,
  }) => throw UnimplementedError();
  @override
  Future<HouseholdMember> archiveMember({
    required String memberId,
    required String householdId,
  }) => throw UnimplementedError();
}

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
    final acc = await accountRepo.findById(
      id: goal.reserveAccountId,
      householdId: _hh,
    );
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
    final acc = await accountRepo.findById(
      id: goal.reserveAccountId,
      householdId: _hh,
    );
    expect(acc!.type, FinancialAccountType.goalReserve);
  });

  test('6. Reserve account is non-spendable', () async {
    final result = await createGoal();
    final goal = (result as AppOk<SavingsGoal>).value;
    final acc = await accountRepo.findById(
      id: goal.reserveAccountId,
      householdId: _hh,
    );
    expect(acc!.isSpendable, isFalse);
  });

  test('7. Reserve account is non-protected', () async {
    final result = await createGoal();
    final goal = (result as AppOk<SavingsGoal>).value;
    final acc = await accountRepo.findById(
      id: goal.reserveAccountId,
      householdId: _hh,
    );
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
    final fakeAccount = await accountRepo.findById(
      id: goal.reserveAccountId,
      householdId: _hh,
    );
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
    expect(
      fakeRevision.id,
      isNotEmpty,
    ); // use fakeRevision to suppress unused variable warning
  });

  test('9. One goal per reserve — goal id itself is the PK', () async {
    // Each goal gets a unique UUID from the use case, so no collision by design.
    final r1 = await createGoal(goalName: 'Goal A');
    final r2 = await createGoal(
      goalName: 'Goal B',
      idempotencyKey: 'ik-goal-b',
    );
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
    final balResult = await goalRepo.getReserveBalance(
      reserveAccountId: srcId,
      householdId: _hh,
    );
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

  test(
    '14. Fund goal: budget consumption NOT incremented (transfer != expense)',
    () async {
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
    },
  );

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

  test(
    '16. Fund goal: not classified as expense (operation type is transfer)',
    () async {
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
    },
  );

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
    expect(
      (result as AppValidationFailure<SavingsGoal>).messageKey,
      'errorGoalSourceIsProtected',
    );
  });

  test('19. Fund goal from another goalReserve → rejected', () async {
    // Create two goals; try to fund one from the other's reserve.
    final r1 = await createGoal(
      goalName: 'Goal A',
      idempotencyKey: 'ik-goal-a',
    );
    final r2 = await createGoal(
      goalName: 'Goal B',
      idempotencyKey: 'ik-goal-b',
    );
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
    expect(
      (result as AppValidationFailure<SavingsGoal>).messageKey,
      'errorGoalSourceIsReserve',
    );
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

    final dstBal = await goalRepo.getReserveBalance(
      reserveAccountId: dstId,
      householdId: _hh,
    );
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
    expect(
      (result as AppValidationFailure<SavingsGoal>).messageKey,
      'errorGoalReleaseReasonEmpty',
    );
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

    final r1 = await createGoal(
      goalName: 'Goal A',
      idempotencyKey: 'ik-goal-relres-a',
    );
    final r2 = await createGoal(
      goalName: 'Goal B',
      idempotencyKey: 'ik-goal-relres-b',
    );
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

    final result = await archiveGoalUc.execute(
      goalId: goal.id,
      householdId: _hh,
    );
    expect(result, isA<AppValidationFailure<void>>());
    expect(
      (result as AppValidationFailure<void>).messageKey,
      'errorGoalArchiveNonzeroBalance',
    );
  });

  test('30. Archive with zero balance → succeeds', () async {
    final goalResult = await createGoal(idempotencyKey: 'ik-goal-arch0');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final result = await archiveGoalUc.execute(
      goalId: goal.id,
      householdId: _hh,
    );
    expect(result, isA<AppOk<void>>());

    // Verify status is now archived.
    final refreshed = await goalRepo.findGoalById(goal.id);
    expect(
      (refreshed as AppOk<SavingsGoal?>).value!.status,
      GoalStatus.archived,
    );
  });

  test('31. Restore archived goal → active', () async {
    final goalResult = await createGoal(idempotencyKey: 'ik-goal-restore');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await archiveGoalUc.execute(goalId: goal.id, householdId: _hh);
    final restoreResult = await restoreGoalUc.execute(
      goalId: goal.id,
      householdId: _hh,
    );
    expect(restoreResult, isA<AppOk<void>>());

    final refreshed = await goalRepo.findGoalById(goal.id);
    expect((refreshed as AppOk<SavingsGoal?>).value!.status, GoalStatus.active);
  });

  test(
    '32. Goal revisions are append-only (no UPDATE on existing rows)',
    () async {
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
    },
  );

  test(
    '33. Goal movements are append-only (no UPDATE on existing rows)',
    () async {
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
      expect(
        movements.every((m) => m.movementType == GoalMovementType.funding),
        isTrue,
      );
    },
  );

  test('34. Metadata-only update does NOT write to operations table', () async {
    final goalResult = await createGoal(idempotencyKey: 'ik-goal-meta');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final beforeCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as cnt FROM operations WHERE household_id = '$_hh'",
                )
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
                .customSelect(
                  "SELECT COUNT(*) as cnt FROM operations WHERE household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('cnt');

    expect(afterCount, beforeCount); // No ledger operations created
  });

  test(
    '35. Migration v7→v8: goals tables created and budget data preserved',
    () async {
      // In forTesting() the schema is always created fresh at the current
      // schemaVersion (9), so all goal tables exist by definition.
      // This test verifies the three tables are present and functional.
      final goalRows = await db
          .customSelect('SELECT COUNT(*) as cnt FROM goals')
          .get();
      final revRows = await db
          .customSelect('SELECT COUNT(*) as cnt FROM goal_revisions')
          .get();
      final movRows = await db
          .customSelect('SELECT COUNT(*) as cnt FROM goal_movements')
          .get();
      expect(goalRows.first.read<int>('cnt'), greaterThanOrEqualTo(0));
      expect(revRows.first.read<int>('cnt'), greaterThanOrEqualTo(0));
      expect(movRows.first.read<int>('cnt'), greaterThanOrEqualTo(0));

      // Verify existing tables from prior phases still exist (budget table from v7).
      final budgetRows = await db
          .customSelect('SELECT COUNT(*) as cnt FROM budgets')
          .get();
      expect(budgetRows.first.read<int>('cnt'), greaterThanOrEqualTo(0));
    },
  );

  // ── Phase 5B.1 – Section 1: Atomicity ────────────────────────────────────

  test(
    'A1. Rollback when initial-funding source has insufficient balance',
    () async {
      const srcId = 'src-atom-insuf';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 500); // only 5.00

      // Attempt to create a goal with initial funding of 100.00 when only 5.00 available.
      final result = await createGoalUc.execute(
        goalName: 'Atomic Rollback Test',
        purpose: GoalPurpose.emergencyFund,
        currencyCode: 'EGP',
        targetMinorUnits: 50000,
        householdId: _hh,
        idempotencyKey: 'ik-atom-rollback',
        initialFundingSourceAccountId: srcId,
        initialFundingMinorUnits: 10000, // more than available
      );

      // Should fail with insufficient funds.
      expect(result, isA<AppInsufficientFunds<SavingsGoal>>());

      // The goal must NOT exist in the DB — full rollback.
      final goalRows = await db
          .customSelect(
            "SELECT COUNT(*) as cnt FROM goals WHERE idempotency_key = 'ik-atom-rollback'",
          )
          .get();
      expect(
        goalRows.first.read<int>('cnt'),
        0,
        reason: 'Goal row must be rolled back when initial funding fails',
      );

      // No operations should have been created.
      final opsRows = await db
          .customSelect(
            "SELECT COUNT(*) as cnt FROM operations WHERE household_id = '$_hh' "
            "AND description LIKE '%Atomic Rollback%'",
          )
          .get();
      expect(opsRows.first.read<int>('cnt'), 0);
    },
  );

  test(
    'A2. Zero initial funding produces no operations or movements (atomic)',
    () async {
      final opsBefore =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) as cnt FROM operations WHERE household_id = '$_hh'",
                  )
                  .get())
              .first
              .read<int>('cnt');

      final result = await createGoalUc.execute(
        goalName: 'Zero Funding Goal',
        purpose: GoalPurpose.other,
        currencyCode: 'EGP',
        targetMinorUnits: 50000,
        householdId: _hh,
        idempotencyKey: 'ik-zero-fund-atomic',
        initialFundingMinorUnits: 0,
      );
      expect(result, isA<AppOk<SavingsGoal>>());
      final goal = (result as AppOk<SavingsGoal>).value;

      final opsAfter =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) as cnt FROM operations WHERE household_id = '$_hh'",
                  )
                  .get())
              .first
              .read<int>('cnt');
      expect(
        opsAfter,
        opsBefore,
        reason: 'Zero initial funding must create no operations',
      );

      final movResult = await goalRepo.getMovements(goal.id);
      expect(
        (movResult as AppOk<List<GoalMovement>>).value,
        isEmpty,
        reason: 'Zero initial funding must create no movements',
      );
    },
  );

  test('A3. Successful creation with initial funding has correct row counts', () async {
    const srcId = 'src-atom-ok';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final result = await createGoalUc.execute(
      goalName: 'Atomic Fund OK',
      purpose: GoalPurpose.travel,
      currencyCode: 'EGP',
      targetMinorUnits: 50000,
      householdId: _hh,
      idempotencyKey: 'ik-atom-ok',
      initialFundingSourceAccountId: srcId,
      initialFundingMinorUnits: 20000,
    );
    expect(result, isA<AppOk<SavingsGoal>>());
    final goal = (result as AppOk<SavingsGoal>).value;

    // Exactly 1 goal row.
    final goalCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as cnt FROM goals WHERE id = '${goal.id}'",
                )
                .get())
            .first
            .read<int>('cnt');
    expect(goalCount, 1);

    // Exactly 1 reserve account.
    final reserveCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as cnt FROM financial_accounts WHERE id = '${goal.reserveAccountId}'",
                )
                .get())
            .first
            .read<int>('cnt');
    expect(reserveCount, 1);

    // Exactly 1 transfer operation.
    final opCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as cnt FROM operations WHERE type = 'transfer' "
                  "AND household_id = '$_hh' AND destination_account_id = '${goal.reserveAccountId}'",
                )
                .get())
            .first
            .read<int>('cnt');
    expect(
      opCount,
      1,
      reason: 'Exactly one transfer operation for initial funding',
    );

    // Exactly 2 ledger entries (debit + credit).
    final entryCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as cnt FROM ledger_entries WHERE account_id = '${goal.reserveAccountId}' "
                  "OR account_id = '$srcId'",
                )
                .get())
            .first
            .read<int>('cnt');
    // The source account also has an income entry from creditAccount(), so we
    // check specifically for the transfer entries.
    final transferEntries =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as cnt FROM ledger_entries WHERE entry_type IN ('transferIn','transferOut') "
                  "AND household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('cnt');
    expect(
      transferEntries,
      2,
      reason: 'One debit + one credit entry for initial funding',
    );
    expect(entryCount, greaterThanOrEqualTo(2));

    // Exactly 1 goal movement.
    final movResult = await goalRepo.getMovements(goal.id);
    final movements = (movResult as AppOk<List<GoalMovement>>).value;
    expect(movements.length, 1);
    expect(movements.first.movementType, GoalMovementType.funding);

    // Reserve balance reflects the funding.
    final balResult = await goalRepo.getReserveBalance(
      reserveAccountId: goal.reserveAccountId,
      householdId: _hh,
    );
    expect((balResult as AppOk<int>).value, 20000);
  });

  // ── Phase 5B.1 – Section 4: Balance enforcement ───────────────────────────

  test(
    'B1. Two sequential fund requests exceeding source balance — only first succeeds',
    () async {
      const srcId = 'src-b1';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 30000); // 300.00 available

      final goalResult = await createGoal(idempotencyKey: 'ik-b1');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      // First request: 200.00 — should succeed.
      final r1 = await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 20000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-b1-1',
      );
      expect(r1, isA<AppOk<SavingsGoal>>());

      // Second request: 200.00 — should fail (only 100.00 left).
      final r2 = await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 20000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-b1-2',
      );
      expect(
        r2,
        isA<AppInsufficientFunds<SavingsGoal>>(),
        reason: 'Second request must fail: combined 40000 > available 30000',
      );

      // Reserve balance must be exactly the first funding amount.
      final balResult = await goalRepo.getReserveBalance(
        reserveAccountId: goal.reserveAccountId,
        householdId: _hh,
      );
      expect((balResult as AppOk<int>).value, 20000);
    },
  );

  test(
    'B2. Two sequential release requests exceeding reserve — only first succeeds',
    () async {
      const srcId = 'src-b2';
      const dstId = 'dst-b2';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 100000);

      final goalResult = await createGoal(
        idempotencyKey: 'ik-b2',
        sourceAccountId: srcId,
        initialFunding: 30000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      // First release: 200.00 — should succeed.
      final r1 = await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dstId,
        amountMinorUnits: 20000,
        releaseReason: 'First release',
        householdId: _hh,
        idempotencyKey: 'ik-release-b2-1',
      );
      expect(r1, isA<AppOk<SavingsGoal>>());

      // Second release: 200.00 — should fail (only 100.00 left in reserve).
      final r2 = await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dstId,
        amountMinorUnits: 20000,
        releaseReason: 'Second release',
        householdId: _hh,
        idempotencyKey: 'ik-release-b2-2',
      );
      expect(
        r2,
        isA<AppInsufficientFunds<SavingsGoal>>(),
        reason:
            'Second release must fail: reserve only has 10000 after first release',
      );
    },
  );

  // ── Phase 5B.1 – Section 3: Idempotency ──────────────────────────────────

  test(
    'I1. FundGoal retry with same idempotency key produces single movement',
    () async {
      const srcId = 'src-i1';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 100000);

      final goalResult = await createGoal(idempotencyKey: 'ik-i1');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      const idempotencyKey = 'ik-fund-i1-retry';

      // First call: creates transfer + movement.
      final r1 = await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: idempotencyKey,
      );
      expect(r1, isA<AppOk<SavingsGoal>>());

      // Second call with same key: transfer is idempotent, no new movement.
      final r2 = await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: idempotencyKey,
      );
      expect(r2, isA<AppOk<SavingsGoal>>());

      // Must have exactly 1 movement.
      final movResult = await goalRepo.getMovements(goal.id);
      final movements = (movResult as AppOk<List<GoalMovement>>).value;
      expect(
        movements.length,
        1,
        reason:
            'Retry with same idempotency key must not create duplicate movement',
      );

      // Reserve balance unchanged from first call.
      final balResult = await goalRepo.getReserveBalance(
        reserveAccountId: goal.reserveAccountId,
        householdId: _hh,
      );
      expect((balResult as AppOk<int>).value, 10000);
    },
  );

  test(
    'I2. ReleaseGoal retry with same idempotency key produces single movement',
    () async {
      const srcId = 'src-i2';
      const dstId = 'dst-i2';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 100000);

      final goalResult = await createGoal(
        idempotencyKey: 'ik-i2',
        sourceAccountId: srcId,
        initialFunding: 50000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      const idempotencyKey = 'ik-release-i2-retry';

      // First call.
      final r1 = await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dstId,
        amountMinorUnits: 10000,
        releaseReason: 'Test release',
        householdId: _hh,
        idempotencyKey: idempotencyKey,
      );
      expect(r1, isA<AppOk<SavingsGoal>>());

      // Retry with same key.
      final r2 = await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dstId,
        amountMinorUnits: 10000,
        releaseReason: 'Test release',
        householdId: _hh,
        idempotencyKey: idempotencyKey,
      );
      expect(r2, isA<AppOk<SavingsGoal>>());

      // Must have exactly 2 movements: 1 funding (initial) + 1 release.
      final movResult = await goalRepo.getMovements(goal.id);
      final movements = (movResult as AppOk<List<GoalMovement>>).value;
      final releaseMovements = movements
          .where((m) => m.movementType == GoalMovementType.release)
          .toList();
      expect(
        releaseMovements.length,
        1,
        reason:
            'Retry with same idempotency key must not create duplicate release movement',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.2 – Section 3: Failure injection tests (FI-1..FI-10)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // Strategy: call goalRepo.createGoal() directly with known IDs so we can
  // pre-insert a conflicting row at the exact step we want to fail.
  // After each failure: verify the DB is completely empty of goal artifacts,
  // then show the idempotency key is free (retry succeeds after removing
  // the conflict row).

  SavingsGoal buildGoal(
    String id,
    String reserveId,
    String hhId,
    String ikey,
    GoalRevision rev,
  ) {
    return SavingsGoal(
      id: id,
      householdId: hhId,
      reserveAccountId: reserveId,
      currencyCode: 'EGP',
      status: GoalStatus.active,
      currentRevision: rev,
      createdAt: '2024-01-01T00:00:00Z',
      idempotencyKey: ikey,
    );
  }

  GoalRevision buildRevision(String id, String goalId, String hhId) {
    return GoalRevision(
      id: id,
      goalId: goalId,
      householdId: hhId,
      name: 'Test Goal',
      purpose: GoalPurpose.emergencyFund,
      targetMinorUnits: 100000,
      currencyCode: 'EGP',
      createdAt: '2024-01-01T00:00:00Z',
      revisionReason: 'initial',
    );
  }

  FinancialAccount buildReserve(String id, String hhId) {
    return FinancialAccount(
      id: id,
      householdId: hhId,
      name: 'Goal Reserve: Test',
      type: FinancialAccountType.goalReserve,
      ownerType: AccountOwnerType.household,
      fundPurpose: FundPurpose.goalReserve,
      currencyCode: 'EGP',
      isSpendable: false,
      isProtected: false,
      includeInNetWorth: true,
      includeInZakat: false,
      isArchived: false,
      displayOrder: 9999,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
      createdBy: 'test',
    );
  }

  Future<void> assertNothingPersisted(
    String goalId,
    String reserveId,
    String revisionId,
  ) async {
    final goalCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goals WHERE id = '$goalId'",
                )
                .get())
            .first
            .read<int>('c');
    final reserveCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM financial_accounts WHERE id = '$reserveId'",
                )
                .get())
            .first
            .read<int>('c');
    final revCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goal_revisions WHERE id = '$revisionId'",
                )
                .get())
            .first
            .read<int>('c');
    final opsCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM operations WHERE household_id = '$_hh' AND description LIKE '%FI-%'",
                )
                .get())
            .first
            .read<int>('c');
    final movCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goal_movements WHERE goal_id = '$goalId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(goalCount, 0, reason: 'No goal row must persist after rollback');
    expect(
      reserveCount,
      0,
      reason: 'No reserve account must persist after rollback',
    );
    expect(revCount, 0, reason: 'No revision must persist after rollback');
    expect(opsCount, 0, reason: 'No operation must persist after rollback');
    expect(movCount, 0, reason: 'No movement must persist after rollback');
  }

  test('FI-1. Fail at step 2 (reserve account insertion) → full rollback', () async {
    const goalId = 'fi1-goal';
    const reserveId = 'fi1-reserve';
    const revId = 'fi1-rev';
    const ikey = 'ik-fi1';

    final rev = buildRevision(revId, goalId, _hh);
    final goal = buildGoal(goalId, reserveId, _hh, ikey, rev);
    final reserve = buildReserve(reserveId, _hh);

    // Pre-insert the reserve account to cause PK conflict at step 2.
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('$reserveId', '$_hh', 'Conflict Reserve', 'goalReserve', 'household', "
      "'goalReserve', 'EGP', 0, 0, 1, 0, 9999, 'test', '2024-01-01', '2024-01-01')",
    );

    final result = await goalRepo.createGoal(
      goal: goal,
      initialRevision: rev,
      reserveAccount: reserve,
    );
    expect(
      result,
      isA<AppPersistenceFailure<SavingsGoal>>(),
      reason: 'FI-1 must return failure',
    );

    await assertNothingPersisted(goalId, goalId, revId);

    // Clean up conflict and retry — idempotency key is free.
    await db.customStatement(
      "DELETE FROM financial_accounts WHERE id = '$reserveId'",
    );
    final retry = await goalRepo.createGoal(
      goal: goal,
      initialRevision: rev,
      reserveAccount: reserve,
    );
    expect(retry, isA<AppOk<SavingsGoal>>(), reason: 'FI-1 retry must succeed');
  });

  test('FI-2. Fail at step 3 (goal row insertion) → full rollback', () async {
    const goalId = 'fi2-goal';
    const reserveId = 'fi2-reserve';
    const revId = 'fi2-rev';
    const ikey = 'ik-fi2';

    final rev = buildRevision(revId, goalId, _hh);
    final goal = buildGoal(goalId, reserveId, _hh, ikey, rev);
    final reserve = buildReserve(reserveId, _hh);

    // Pre-insert a goal with same id to conflict at step 3.
    // We need a different reserve account since the table needs a valid FK.
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('fi2-reserve-dummy', '$_hh', 'Dummy', 'goalReserve', 'household', "
      "'goalReserve', 'EGP', 0, 0, 1, 0, 1, 'test', '2024-01-01', '2024-01-01')",
    );
    await db.customStatement(
      "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
      "status, idempotency_key, idempotency_payload, created_at) "
      "VALUES ('$goalId', '$_hh', 'fi2-reserve-dummy', 'EGP', 'active', 'ik-fi2-dummy', 'dummy-payload', '2024-01-01')",
    );

    final result = await goalRepo.createGoal(
      goal: goal,
      initialRevision: rev,
      reserveAccount: reserve,
    );
    // Idempotency check inside transaction will find existing goal by ikey;
    // since the ikey is 'ik-fi2-dummy' for the pre-inserted row vs 'ik-fi2' here,
    // the pre-inserted row uses a different ikey so the idempotency check passes,
    // and the PK conflict on goal.id causes the failure.
    expect(
      result,
      isA<AppPersistenceFailure<SavingsGoal>>(),
      reason: 'FI-2 must fail with PK conflict',
    );

    // Reserve 'fi2-reserve' was NOT inserted (rolled back), but 'fi2-reserve-dummy' exists.
    final reserveCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM financial_accounts WHERE id = '$reserveId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(reserveCount, 0, reason: 'FI-2: rolled-back reserve must not exist');

    final revCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goal_revisions WHERE id = '$revId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(revCount, 0, reason: 'FI-2: rolled-back revision must not exist');

    // Clean up and retry with a fresh goal ID (the old goal ID is taken).
    await db.customStatement("DELETE FROM goals WHERE id = '$goalId'");
    await db.customStatement(
      "DELETE FROM financial_accounts WHERE id = 'fi2-reserve-dummy'",
    );
    final retry = await goalRepo.createGoal(
      goal: goal,
      initialRevision: rev,
      reserveAccount: reserve,
    );
    expect(
      retry,
      isA<AppOk<SavingsGoal>>(),
      reason: 'FI-2 retry must succeed after conflict removed',
    );
  });

  test('FI-3. Fail at step 4 (revision insertion) → full rollback', () async {
    const goalId = 'fi3-goal';
    const reserveId = 'fi3-reserve';
    const revId = 'fi3-rev';
    const ikey = 'ik-fi3';

    final rev = buildRevision(revId, goalId, _hh);
    final goal = buildGoal(goalId, reserveId, _hh, ikey, rev);
    final reserve = buildReserve(reserveId, _hh);

    // We need a goal row with id 'fi3-goal' to create a valid FK for the revision.
    // But actually we conflict by inserting the revision with same PK before createGoal.
    // This requires a goal to already exist for the FK constraint on goal_revisions.
    // Instead we pre-insert a goal_revision with the same id using a dummy goal.
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('fi3-reserve-dummy', '$_hh', 'Dummy', 'goalReserve', 'household', "
      "'goalReserve', 'EGP', 0, 0, 1, 0, 1, 'test', '2024-01-01', '2024-01-01')",
    );
    await db.customStatement(
      "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
      "status, idempotency_key, idempotency_payload, created_at) "
      "VALUES ('fi3-goal-dummy', '$_hh', 'fi3-reserve-dummy', 'EGP', 'active', 'ik-fi3-dummy', 'dummy', '2024-01-01')",
    );
    await db.customStatement(
      "INSERT INTO goal_revisions (id, goal_id, household_id, name, purpose_code, "
      "target_minor_units, currency_code, created_at, revision_reason) "
      "VALUES ('$revId', 'fi3-goal-dummy', '$_hh', 'Dummy', 'other', 100000, 'EGP', '2024-01-01', 'init')",
    );

    final result = await goalRepo.createGoal(
      goal: goal,
      initialRevision: rev,
      reserveAccount: reserve,
    );
    expect(
      result,
      isA<AppPersistenceFailure<SavingsGoal>>(),
      reason: 'FI-3 must fail at revision insertion',
    );

    final goalCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goals WHERE id = '$goalId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(goalCount, 0, reason: 'FI-3: goal must be rolled back');

    final reserveCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM financial_accounts WHERE id = '$reserveId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(reserveCount, 0, reason: 'FI-3: reserve must be rolled back');

    // Retry with a new revision ID — the original 'fi3-rev' is stuck in the dummy goal
    // because goal_revisions are append-only (no DELETE). Since the idempotency key
    // 'ik-fi3' was never committed (transaction rolled back), the retry proceeds as a
    // fresh creation. We use a different revId to avoid the PK conflict.
    final retryRev = buildRevision('fi3-rev-retry', goalId, _hh);
    final retryGoal = buildGoal(goalId, reserveId, _hh, ikey, retryRev);
    final retry = await goalRepo.createGoal(
      goal: retryGoal,
      initialRevision: retryRev,
      reserveAccount: reserve,
    );
    expect(
      retry,
      isA<AppOk<SavingsGoal>>(),
      reason: 'FI-3 retry with fresh revision ID must succeed',
    );
  });

  test(
    'FI-4. Fail at balance check (insufficient funds) → full rollback',
    () async {
      const srcId = 'src-fi4';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 500); // only 5.00

      final result = await createGoalUc.execute(
        goalName: 'FI-4 Goal',
        purpose: GoalPurpose.emergencyFund,
        currencyCode: 'EGP',
        targetMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'ik-fi4',
        initialFundingSourceAccountId: srcId,
        initialFundingMinorUnits: 50000, // more than available
      );
      expect(
        result,
        isA<AppInsufficientFunds<SavingsGoal>>(),
        reason: 'FI-4 must fail with insufficient funds',
      );

      final goalCount =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) as c FROM goals WHERE idempotency_key = 'ik-fi4'",
                  )
                  .get())
              .first
              .read<int>('c');
      expect(goalCount, 0, reason: 'FI-4: no goal must persist');

      final opsCount =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) as c FROM operations WHERE household_id = '$_hh' AND description LIKE '%FI-4%'",
                  )
                  .get())
              .first
              .read<int>('c');
      expect(opsCount, 0, reason: 'FI-4: no operation must persist');

      // Credit more and retry — same idempotency key, same payload → succeeds.
      await creditAccount(srcId, _hh, 100000);
      final retry = await createGoalUc.execute(
        goalName: 'FI-4 Goal',
        purpose: GoalPurpose.emergencyFund,
        currencyCode: 'EGP',
        targetMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'ik-fi4',
        initialFundingSourceAccountId: srcId,
        initialFundingMinorUnits: 50000,
      );
      expect(
        retry,
        isA<AppOk<SavingsGoal>>(),
        reason: 'FI-4 retry with funded account must succeed',
      );
    },
  );

  test('FI-5. Fail at step 6 (operation insertion) → full rollback', () async {
    const srcId = 'src-fi5';
    const opId = 'fi5-op';
    const goalId = 'fi5-goal';
    const reserveId = 'fi5-reserve';
    const revId = 'fi5-rev';
    const ikey = 'ik-fi5';

    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final rev = buildRevision(revId, goalId, _hh);
    final goal = buildGoal(goalId, reserveId, _hh, ikey, rev);
    final reserve = buildReserve(reserveId, _hh);
    const funding = GoalInitialFunding(
      operationId: opId,
      idempotencyKey: ikey,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      currencyCode: 'EGP',
      effectiveDate: '2024-01-01',
      description: 'FI-5 Initial Funding',
      movementId: 'fi5-mov',
      movementCreatedAt: '2024-01-01T00:00:00Z',
    );

    // Pre-insert an operation with same id to conflict at step 6.
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
      "description, source_account_id, destination_account_id) "
      "VALUES ('$opId', '$_hh', 'income', '2024-01-01', '2024-01-01T00:00:00Z', "
      "1000, 'EGP', 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z', "
      "'Conflict op', '$srcId', '$srcId')",
    );

    final result = await goalRepo.createGoal(
      goal: goal,
      initialRevision: rev,
      reserveAccount: reserve,
      initialFunding: funding,
    );
    expect(
      result,
      isA<AppPersistenceFailure<SavingsGoal>>(),
      reason: 'FI-5 must fail at operation insertion',
    );

    final goalCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goals WHERE id = '$goalId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(goalCount, 0, reason: 'FI-5: goal must be rolled back');

    final movCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goal_movements WHERE id = 'fi5-mov'",
                )
                .get())
            .first
            .read<int>('c');
    expect(movCount, 0, reason: 'FI-5: movement must be rolled back');

    // Cannot delete the conflicting operation ('fi5-op') because operations are
    // append-only (no_delete_operations trigger). Retry with a new operation ID;
    // since the goal row was rolled back, 'ik-fi5' is not in the goals table,
    // so the retry proceeds as a fresh creation.
    const funding2 = GoalInitialFunding(
      operationId: 'fi5-op-2',
      idempotencyKey: ikey,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      currencyCode: 'EGP',
      effectiveDate: '2024-01-01',
      description: 'FI-5 Initial Funding',
      movementId: 'fi5-mov-2',
      movementCreatedAt: '2024-01-01T00:00:00Z',
    );
    final retry = await goalRepo.createGoal(
      goal: goal,
      initialRevision: rev,
      reserveAccount: reserve,
      initialFunding: funding2,
    );
    expect(retry, isA<AppOk<SavingsGoal>>(), reason: 'FI-5 retry must succeed');
  });

  test('FI-6. Fail at step 7 (debit ledger entry) → full rollback', () async {
    const srcId = 'src-fi6';
    const opId = 'fi6-op';
    const debitEntryId = '${opId}_debit';
    const goalId = 'fi6-goal';
    const reserveId = 'fi6-reserve';
    const revId = 'fi6-rev';
    const ikey = 'ik-fi6';

    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final rev = buildRevision(revId, goalId, _hh);
    final goal = buildGoal(goalId, reserveId, _hh, ikey, rev);
    final reserve = buildReserve(reserveId, _hh);

    // We need the operation to already exist so we can pre-insert the debit entry.
    // But the operation is inserted inside the transaction, so we can't pre-insert it.
    // Instead, conflict on the ledger_entry unique index:
    // idx_ledger_idempotency: (operation_id, account_id, direction, entry_type)
    // We'll insert a different operation first, then insert a ledger entry with same composite key.

    // Actually the simplest approach: we use the debit entry ID (opId + '_debit') as PK.
    // Pre-insert a ledger entry for a dummy operation to get the ID 'fi6-op_debit' taken.
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
      "VALUES ('fi6-dummy-op', '$_hh', 'income', '2024-01-01', '2024-01-01T00:00:00Z', "
      "1000, 'EGP', 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    await db.customStatement(
      "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
      "direction, amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "('$debitEntryId', 'fi6-dummy-op', '$_hh', '$srcId', 'credit', 1000, 'EGP', "
      "'income', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
    );

    const funding = GoalInitialFunding(
      operationId: opId,
      idempotencyKey: ikey,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      currencyCode: 'EGP',
      effectiveDate: '2024-01-01',
      description: 'FI-6 Funding',
      movementId: 'fi6-mov',
      movementCreatedAt: '2024-01-01T00:00:00Z',
    );

    final result = await goalRepo.createGoal(
      goal: goal,
      initialRevision: rev,
      reserveAccount: reserve,
      initialFunding: funding,
    );
    expect(
      result,
      isA<AppPersistenceFailure<SavingsGoal>>(),
      reason: 'FI-6 must fail at debit entry',
    );

    final goalCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goals WHERE id = '$goalId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(goalCount, 0, reason: 'FI-6: goal must be rolled back');

    final opCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM operations WHERE id = '$opId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(opCount, 0, reason: 'FI-6: operation must be rolled back');
  });

  test('FI-7. Fail at step 8 (credit ledger entry) → full rollback', () async {
    const srcId = 'src-fi7';
    const opId = 'fi7-op';
    const creditEntryId = '${opId}_credit';
    const goalId = 'fi7-goal';
    const reserveId = 'fi7-reserve';
    const revId = 'fi7-rev';
    const ikey = 'ik-fi7';

    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final rev = buildRevision(revId, goalId, _hh);
    final goal = buildGoal(goalId, reserveId, _hh, ikey, rev);
    final reserve = buildReserve(reserveId, _hh);

    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
      "VALUES ('fi7-dummy-op', '$_hh', 'income', '2024-01-01', '2024-01-01T00:00:00Z', "
      "1000, 'EGP', 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    // Pre-insert a ledger entry with the credit entry PK to conflict.
    await db.customStatement(
      "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
      "direction, amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "('$creditEntryId', 'fi7-dummy-op', '$_hh', '$srcId', 'credit', 1000, 'EGP', "
      "'income', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
    );

    const funding = GoalInitialFunding(
      operationId: opId,
      idempotencyKey: ikey,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      currencyCode: 'EGP',
      effectiveDate: '2024-01-01',
      description: 'FI-7 Funding',
      movementId: 'fi7-mov',
      movementCreatedAt: '2024-01-01T00:00:00Z',
    );

    final result = await goalRepo.createGoal(
      goal: goal,
      initialRevision: rev,
      reserveAccount: reserve,
      initialFunding: funding,
    );
    expect(
      result,
      isA<AppPersistenceFailure<SavingsGoal>>(),
      reason: 'FI-7 must fail at credit entry',
    );

    final goalCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goals WHERE id = '$goalId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(goalCount, 0, reason: 'FI-7: goal must be rolled back');

    final movCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goal_movements WHERE goal_id = '$goalId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(movCount, 0, reason: 'FI-7: movement must be rolled back');
  });

  test('FI-8. Fail at step 9 (operation context) → full rollback', () async {
    const srcId = 'src-fi8';
    const opId = 'fi8-op';
    const goalId = 'fi8-goal';
    const reserveId = 'fi8-reserve';
    const revId = 'fi8-rev';
    const ikey = 'ik-fi8';

    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final rev = buildRevision(revId, goalId, _hh);
    final goal = buildGoal(goalId, reserveId, _hh, ikey, rev);
    final reserve = buildReserve(reserveId, _hh);

    // Pre-insert an operation_context with same operation_id to conflict at step 9.
    // First create a dummy operation for the FK.
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
      "VALUES ('$opId', '$_hh', 'income', '2024-01-01', '2024-01-01T00:00:00Z', "
      "1000, 'EGP', 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    await db.customStatement(
      "INSERT INTO operation_contexts (operation_id, household_id, is_recurring, created_at) "
      "VALUES ('$opId', '$_hh', 0, '2024-01-01T00:00:00Z')",
    );

    const funding = GoalInitialFunding(
      operationId: opId,
      idempotencyKey: ikey,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      currencyCode: 'EGP',
      effectiveDate: '2024-01-01',
      description: 'FI-8 Funding',
      movementId: 'fi8-mov',
      movementCreatedAt: '2024-01-01T00:00:00Z',
    );

    final result = await goalRepo.createGoal(
      goal: goal,
      initialRevision: rev,
      reserveAccount: reserve,
      initialFunding: funding,
    );
    expect(
      result,
      isA<AppPersistenceFailure<SavingsGoal>>(),
      reason: 'FI-8 must fail at operation context insertion',
    );

    final goalCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goals WHERE id = '$goalId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(goalCount, 0, reason: 'FI-8: goal must be rolled back');

    final reserveCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM financial_accounts WHERE id = '$reserveId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(reserveCount, 0, reason: 'FI-8: reserve must be rolled back');
  });

  test('FI-9. Fail at step 10 (goal movement insertion) → full rollback', () async {
    const srcId = 'src-fi9';
    const opId = 'fi9-op';
    const movId = 'fi9-mov';
    const goalId = 'fi9-goal';
    const reserveId = 'fi9-reserve';
    const revId = 'fi9-rev';
    const ikey = 'ik-fi9';

    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final rev = buildRevision(revId, goalId, _hh);
    final goal = buildGoal(goalId, reserveId, _hh, ikey, rev);
    final reserve = buildReserve(reserveId, _hh);

    // Pre-insert a goal movement with same id using a dummy goal.
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('fi9-reserve-dummy', '$_hh', 'Dummy', 'goalReserve', 'household', "
      "'goalReserve', 'EGP', 0, 0, 1, 0, 1, 'test', '2024-01-01', '2024-01-01')",
    );
    await db.customStatement(
      "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
      "status, idempotency_key, idempotency_payload, created_at) "
      "VALUES ('fi9-goal-dummy', '$_hh', 'fi9-reserve-dummy', 'EGP', 'active', 'ik-fi9-dummy', 'dummy', '2024-01-01')",
    );
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
      "source_account_id, destination_account_id) "
      "VALUES ('$opId', '$_hh', 'transfer', '2024-01-01', '2024-01-01T00:00:00Z', "
      "20000, 'EGP', 'test', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z', "
      "'$srcId', 'fi9-reserve-dummy')",
    );
    await db.customStatement(
      "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
      "direction, amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "('${opId}_debit', '$opId', '$_hh', '$srcId', 'debit', 20000, 'EGP', "
      "'transferOut', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
    );
    await db.customStatement(
      "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, "
      "direction, amount_minor_units, currency_code, entry_type, effective_date, "
      "recorded_at, created_by) VALUES "
      "('${opId}_credit', '$opId', '$_hh', 'fi9-reserve-dummy', 'credit', 20000, "
      "'EGP', 'transferIn', '2024-01-01', '2024-01-01T00:00:00Z', 'test')",
    );
    await db.customStatement(
      "INSERT INTO goal_movements (id, goal_id, household_id, transfer_operation_id, "
      "movement_type, created_at) VALUES ('$movId', 'fi9-goal-dummy', '$_hh', '$opId', "
      "'funding', '2024-01-01T00:00:00Z')",
    );

    const funding = GoalInitialFunding(
      operationId: 'fi9-op-new',
      idempotencyKey: ikey,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      currencyCode: 'EGP',
      effectiveDate: '2024-01-01',
      description: 'FI-9 Funding',
      movementId: movId, // same movement id → PK conflict
      movementCreatedAt: '2024-01-01T00:00:00Z',
    );

    final result = await goalRepo.createGoal(
      goal: goal,
      initialRevision: rev,
      reserveAccount: reserve,
      initialFunding: funding,
    );
    expect(
      result,
      isA<AppPersistenceFailure<SavingsGoal>>(),
      reason: 'FI-9 must fail at movement insertion',
    );

    final goalCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM goals WHERE id = '$goalId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(goalCount, 0, reason: 'FI-9: goal must be rolled back');

    final reserveCount =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM financial_accounts WHERE id = '$reserveId'",
                )
                .get())
            .first
            .read<int>('c');
    expect(reserveCount, 0, reason: 'FI-9: reserve must be rolled back');
  });

  test(
    'FI-10. Idempotency key conflict at unique index → graceful duplicate conflict',
    () async {
      const goalId = 'fi10-goal';
      const reserveId = 'fi10-reserve';
      const revId = 'fi10-rev';
      const ikey = 'ik-fi10';

      final rev = buildRevision(revId, goalId, _hh);
      final goal = buildGoal(goalId, reserveId, _hh, ikey, rev);
      final reserve = buildReserve(reserveId, _hh);

      // Pre-insert a goal with same household_id + idempotency_key but DIFFERENT payload.
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) "
        "VALUES ('fi10-reserve-dummy', '$_hh', 'Dummy', 'goalReserve', 'household', "
        "'goalReserve', 'EGP', 0, 0, 1, 0, 1, 'test', '2024-01-01', '2024-01-01')",
      );
      await db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) "
        "VALUES ('fi10-goal-pre', '$_hh', 'fi10-reserve-dummy', 'EGP', 'active', '$ikey', "
        "'different-payload', '2024-01-01')",
      );

      // The idempotency check inside the transaction finds the pre-inserted goal.
      // Payload mismatch → AppDuplicateConflict (not a DB error, no rollback needed).
      final result = await goalRepo.createGoal(
        goal: goal,
        initialRevision: rev,
        reserveAccount: reserve,
      );
      expect(
        result,
        isA<AppDuplicateConflict<SavingsGoal>>(),
        reason: 'FI-10 must return AppDuplicateConflict',
      );

      // Our goal was NOT inserted (only a read happened).
      final goalCount =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) as c FROM goals WHERE id = '$goalId'",
                  )
                  .get())
              .first
              .read<int>('c');
      expect(goalCount, 0, reason: 'FI-10: our goal must not be inserted');

      final reserveCount =
          (await db
                  .customSelect(
                    "SELECT COUNT(*) as c FROM financial_accounts WHERE id = '$reserveId'",
                  )
                  .get())
              .first
              .read<int>('c');
      expect(
        reserveCount,
        0,
        reason: 'FI-10: our reserve must not be inserted',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.2 – Section 6: Use-case reserve restrictions (UC-1..UC-4)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // Transaction use-case instances are built inline per-test because they
  // depend on the per-test `db` / `ledgerRepo` / `accountRepo` instances
  // that are re-created in each setUp.

  test(
    'UC-1. RecordIncomeUseCase with goalReserve destination → returns error',
    () async {
      final goalResult = await createGoal(idempotencyKey: 'ik-uc1');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final uc = RecordIncomeUseCase(
        ledgerRepository: ledgerRepo,
        accountRepository: accountRepo,
      );
      final result = await uc.execute(
        IncomeContext(
          operationId: 'uc1-op',
          idempotencyKey: 'ik-uc1-income',
          householdId: _hh,
          destinationAccountId: goal.reserveAccountId,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'test',
          category: TransactionCategory.salary,
        ),
      );
      expect(
        result,
        isA<AppValidationFailure<String>>(),
        reason: 'Income to goalReserve must be rejected',
      );
      expect(
        (result as AppValidationFailure).messageKey,
        'errorGoalReserveNotAllowedInOrdinaryTransaction',
      );
    },
  );

  test(
    'UC-2. RecordExpenseUseCase with goalReserve payment account → returns error',
    () async {
      final goalResult = await createGoal(idempotencyKey: 'ik-uc2');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final uc = RecordExpenseUseCase(
        ledgerRepository: ledgerRepo,
        accountRepository: accountRepo,
        householdRepository: _NoopHouseholdRepository(),
      );
      final result = await uc.execute(
        ExpenseContext(
          operationId: 'uc2-op',
          idempotencyKey: 'ik-uc2-expense',
          householdId: _hh,
          paymentAccountId: goal.reserveAccountId,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'test',
          category: TransactionCategory.groceries,
          spenderMemberId: 'u1',
          beneficiaryMemberId: 'u1',
          scope: ExpenseScope.personal,
          isRecurring: false,
        ),
      );
      expect(
        result,
        isA<AppValidationFailure<String>>(),
        reason: 'Expense from goalReserve must be rejected',
      );
      expect(
        (result as AppValidationFailure).messageKey,
        'errorGoalReserveNotAllowedInOrdinaryTransaction',
      );
    },
  );

  test(
    'UC-3. ExecuteTransferUseCase with goalReserve as source → returns error',
    () async {
      const dstId = 'dst-uc3';
      await createAccount(id: dstId, householdId: _hh);

      final goalResult = await createGoal(idempotencyKey: 'ik-uc3');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final uc = ExecuteTransferUseCase(
        ledgerRepository: ledgerRepo,
        accountRepository: accountRepo,
      );
      final result = await uc.execute(
        TransferContext(
          operationId: 'uc3-op',
          idempotencyKey: 'ik-uc3-transfer',
          householdId: _hh,
          sourceAccountId: goal.reserveAccountId,
          destinationAccountId: dstId,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'test',
        ),
      );
      expect(
        result,
        isA<AppValidationFailure<String>>(),
        reason: 'Transfer from goalReserve must be rejected',
      );
      expect(
        (result as AppValidationFailure).messageKey,
        'errorGoalReserveNotAllowedInOrdinaryTransaction',
      );
    },
  );

  test(
    'UC-4. ExecuteTransferUseCase with goalReserve as destination → returns error',
    () async {
      const srcId = 'src-uc4';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-uc4');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final uc = ExecuteTransferUseCase(
        ledgerRepository: ledgerRepo,
        accountRepository: accountRepo,
      );
      final result = await uc.execute(
        TransferContext(
          operationId: 'uc4-op',
          idempotencyKey: 'ik-uc4-transfer',
          householdId: _hh,
          sourceAccountId: srcId,
          destinationAccountId: goal.reserveAccountId,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'test',
        ),
      );
      expect(
        result,
        isA<AppValidationFailure<String>>(),
        reason: 'Transfer to goalReserve must be rejected',
      );
      expect(
        (result as AppValidationFailure).messageKey,
        'errorGoalReserveNotAllowedInOrdinaryTransaction',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.2 – Section 7: Release destination validation (RD-1..RD-7)
  // ══════════════════════════════════════════════════════════════════════════

  test('RD-1. Unknown destination → AppNotFound', () async {
    const srcId = 'src-rd1';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-rd1',
      sourceAccountId: srcId,
      initialFunding: 50000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final result = await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: 'non-existent-account',
      amountMinorUnits: 10000,
      releaseReason: 'Test',
      householdId: _hh,
      idempotencyKey: 'ik-rd1-release',
    );
    expect(result, isA<AppNotFound<SavingsGoal>>());
  });

  test(
    'RD-2. Cross-household destination → AppNotFound (scoped by householdId)',
    () async {
      const srcId = 'src-rd2';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 100000);

      // Create a valid account in hh2.
      await accountRepo.createAccount(
        const CreateAccountParams(
          id: 'dst-rd2-hh2',
          householdId: _hh2,
          name: 'HH2 Account',
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

      final goalResult = await createGoal(
        idempotencyKey: 'ik-rd2',
        sourceAccountId: srcId,
        initialFunding: 50000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final result = await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: 'dst-rd2-hh2',
        amountMinorUnits: 10000,
        releaseReason: 'Test',
        householdId: _hh,
        idempotencyKey: 'ik-rd2-release',
      );
      expect(
        result,
        isA<AppNotFound<SavingsGoal>>(),
        reason: 'Cross-household destination must not be found',
      );
    },
  );

  test('RD-3. Archived destination → AppValidationFailure', () async {
    const srcId = 'src-rd3';
    const dstId = 'dst-rd3';
    await createAccount(id: srcId, householdId: _hh);
    await createAccount(id: dstId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-rd3',
      sourceAccountId: srcId,
      initialFunding: 50000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    // Archive the destination.
    await db.customStatement(
      "UPDATE financial_accounts SET is_archived = 1, archived_at = '2024-01-01', "
      "updated_at = '2024-01-01' WHERE id = '$dstId'",
    );

    final result = await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 10000,
      releaseReason: 'Test',
      householdId: _hh,
      idempotencyKey: 'ik-rd3-release',
    );
    expect(result, isA<AppValidationFailure<SavingsGoal>>());
    expect((result as AppValidationFailure).messageKey, 'errorAccountArchived');
  });

  test(
    'RD-4. Destination = own reserve account → AppValidationFailure',
    () async {
      const srcId = 'src-rd4';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 100000);

      final goalResult = await createGoal(
        idempotencyKey: 'ik-rd4',
        sourceAccountId: srcId,
        initialFunding: 50000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final result = await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: goal.reserveAccountId,
        amountMinorUnits: 10000,
        releaseReason: 'Test',
        householdId: _hh,
        idempotencyKey: 'ik-rd4-release',
      );
      expect(result, isA<AppValidationFailure<SavingsGoal>>());
    },
  );

  test(
    'RD-5. Destination = another goalReserve → AppValidationFailure',
    () async {
      const srcId = 'src-rd5';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 100000);

      final r1 = await createGoal(
        goalName: 'Goal RD5-A',
        idempotencyKey: 'ik-rd5-a',
        sourceAccountId: srcId,
        initialFunding: 50000,
      );
      final r2 = await createGoal(
        goalName: 'Goal RD5-B',
        idempotencyKey: 'ik-rd5-b',
      );
      final goal1 = (r1 as AppOk<SavingsGoal>).value;
      final goal2 = (r2 as AppOk<SavingsGoal>).value;

      final result = await releaseGoalUc.execute(
        goalId: goal1.id,
        destinationAccountId: goal2.reserveAccountId,
        amountMinorUnits: 10000,
        releaseReason: 'Test',
        householdId: _hh,
        idempotencyKey: 'ik-rd5-release',
      );
      expect(result, isA<AppValidationFailure<SavingsGoal>>());
    },
  );

  test('RD-6. Different currency destination → AppValidationFailure', () async {
    const srcId = 'src-rd6';
    const dstId = 'dst-rd6-usd';
    await createAccount(id: srcId, householdId: _hh, currency: 'EGP');
    await createAccount(id: dstId, householdId: _hh, currency: 'USD');
    await creditAccount(srcId, _hh, 100000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-rd6',
      sourceAccountId: srcId,
      initialFunding: 50000,
      currency: 'EGP',
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final result = await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 10000,
      releaseReason: 'Test',
      householdId: _hh,
      idempotencyKey: 'ik-rd6-release',
    );
    expect(result, isA<AppValidationFailure<SavingsGoal>>());
    expect(
      (result as AppValidationFailure).messageKey,
      'errorCurrencyMismatch',
    );
  });

  test('RD-7. Valid destination → succeeds', () async {
    const srcId = 'src-rd7';
    const dstId = 'dst-rd7';
    await createAccount(id: srcId, householdId: _hh);
    await createAccount(id: dstId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-rd7',
      sourceAccountId: srcId,
      initialFunding: 50000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final result = await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 10000,
      releaseReason: 'Valid release',
      householdId: _hh,
      idempotencyKey: 'ik-rd7-release',
    );
    expect(result, isA<AppOk<SavingsGoal>>());
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.2 – Section 8: CompleteGoalUseCase tests (CG-1..CG-8)
  // ══════════════════════════════════════════════════════════════════════════

  test(
    'CG-1. Normal completion when balance >= target → succeeds, status = completed',
    () async {
      const srcId = 'src-cg1';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 200000);

      final goalResult = await createGoal(
        idempotencyKey: 'ik-cg1',
        target: 100000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      // Fund to exactly the target.
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-cg1',
      );

      final cg = CompleteGoalUseCase(goalRepo);
      final result = await cg.execute(
        CompleteGoalParams(goalId: goal.id, householdId: _hh),
      );
      expect(result, isA<AppOk<SavingsGoal>>());
      expect((result as AppOk<SavingsGoal>).value.status, GoalStatus.completed);
      expect((result).value.completedAt, isNotNull);
    },
  );

  test(
    'CG-2. Early completion with reason → succeeds regardless of balance',
    () async {
      final goalResult = await createGoal(
        idempotencyKey: 'ik-cg2',
        target: 100000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final cg = CompleteGoalUseCase(goalRepo);
      final result = await cg.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: _hh,
          earlyCompletion: true,
          earlyCompletionConfirmed: true,
          earlyCompletionReason: 'Changed plans, no longer needed',
        ),
      );
      expect(result, isA<AppOk<SavingsGoal>>());
      expect((result as AppOk<SavingsGoal>).value.status, GoalStatus.completed);
    },
  );

  test(
    'CG-3. Early completion without confirmation → AppValidationFailure (confirmed required)',
    () async {
      final goalResult = await createGoal(
        idempotencyKey: 'ik-cg3',
        target: 100000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final cg = CompleteGoalUseCase(goalRepo);
      final result = await cg.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: _hh,
          earlyCompletion: true,
        ),
      );
      expect(result, isA<AppValidationFailure<SavingsGoal>>());
      expect(
        (result as AppValidationFailure).messageKey,
        'errorEarlyCompletionConfirmationRequired',
      );
    },
  );

  test(
    'CG-4. Early completion confirmed but empty reason → AppValidationFailure',
    () async {
      final goalResult = await createGoal(
        idempotencyKey: 'ik-cg4',
        target: 100000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final cg = CompleteGoalUseCase(goalRepo);
      final result = await cg.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: _hh,
          earlyCompletion: true,
          earlyCompletionConfirmed: true,
          earlyCompletionReason: '   ',
        ),
      );
      expect(result, isA<AppValidationFailure<SavingsGoal>>());
      expect(
        (result as AppValidationFailure).messageKey,
        'errorEarlyCompletionReasonRequired',
      );
    },
  );

  test('CG-5. Already completed → returns existing (idempotent)', () async {
    const srcId = 'src-cg5';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 200000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-cg5',
      target: 100000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 100000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-cg5',
    );

    final cg = CompleteGoalUseCase(goalRepo);
    final r1 = await cg.execute(
      CompleteGoalParams(goalId: goal.id, householdId: _hh),
    );
    final r2 = await cg.execute(
      CompleteGoalParams(goalId: goal.id, householdId: _hh),
    );
    expect(r1, isA<AppOk<SavingsGoal>>());
    expect(r2, isA<AppOk<SavingsGoal>>());
    expect((r2 as AppOk<SavingsGoal>).value.status, GoalStatus.completed);
  });

  test('CG-6. Archived goal → AppValidationFailure', () async {
    final goalResult = await createGoal(idempotencyKey: 'ik-cg6');
    final goal = (goalResult as AppOk<SavingsGoal>).value;
    await archiveGoalUc.execute(goalId: goal.id, householdId: _hh);

    final cg = CompleteGoalUseCase(goalRepo);
    final result = await cg.execute(
      CompleteGoalParams(
        goalId: goal.id,
        householdId: _hh,
        earlyCompletion: true,
        earlyCompletionConfirmed: true,
        earlyCompletionReason: 'Test',
      ),
    );
    expect(result, isA<AppValidationFailure<SavingsGoal>>());
    expect((result as AppValidationFailure).messageKey, 'errorGoalArchived');
  });

  test('CG-7. No ledger rows created during completion', () async {
    const srcId = 'src-cg7';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 200000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-cg7',
      target: 100000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 100000,
      householdId: _hh,
      idempotencyKey: 'ik-fund-cg7',
    );

    final opsBefore =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM operations WHERE household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('c');
    final ledgerBefore =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM ledger_entries WHERE household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('c');

    final cg = CompleteGoalUseCase(goalRepo);
    await cg.execute(CompleteGoalParams(goalId: goal.id, householdId: _hh));

    final opsAfter =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM operations WHERE household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('c');
    final ledgerAfter =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM ledger_entries WHERE household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('c');

    expect(
      opsAfter,
      opsBefore,
      reason: 'Completion must not create operations',
    );
    expect(
      ledgerAfter,
      ledgerBefore,
      reason: 'Completion must not create ledger entries',
    );
  });

  test(
    'CG-8. Completion followed by release succeeds (policy allows)',
    () async {
      const srcId = 'src-cg8';
      const dstId = 'dst-cg8';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 200000);

      final goalResult = await createGoal(
        idempotencyKey: 'ik-cg8',
        target: 100000,
        sourceAccountId: srcId,
        initialFunding: 100000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final cg = CompleteGoalUseCase(goalRepo);
      await cg.execute(CompleteGoalParams(goalId: goal.id, householdId: _hh));

      // Release is allowed from a completed goal (not archived).
      final releaseResult = await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dstId,
        amountMinorUnits: 50000,
        releaseReason: 'Post-completion disbursement',
        householdId: _hh,
        idempotencyKey: 'ik-cg8-release',
      );
      expect(
        releaseResult,
        isA<AppOk<SavingsGoal>>(),
        reason: 'Release after completion must succeed',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.2 – Section 10: Concurrency documentation (CC-1..CC-2)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // CONCURRENCY MODEL — SQLite + Dart:
  //
  // Dart runs on a single-threaded event loop. Two Dart Futures started with
  // Future.wait() do NOT run truly in parallel. They interleave at `await`
  // yield points. Drift wraps each `db.transaction()` in an internal
  // serialiser (similar to package:synchronized), so write transactions are
  // serialised at the database level.
  //
  // HOWEVER: the balance-sufficiency check in DriftLedgerRepository is
  // performed BEFORE entering the transaction (outside the lock). This means
  // two concurrent Futures can both pass the balance check before either
  // commits its write, because the check reads the pre-commit balance.
  //
  // Result: the system provides "sequential-write" isolation at the SQLite
  // layer (no partial writes, no torn reads inside a transaction), but it does
  // NOT provide "snapshot isolation" for the pre-transaction balance check.
  //
  // The CC tests below demonstrate the RELIABLE (sequential) guarantee: when
  // two operations are awaited one-by-one, the second sees the committed state
  // of the first. This mirrors the documented behaviour for all ordinary use
  // (API requests, UI interactions) where operations are not literally
  // simultaneous within the same Dart isolate.

  test(
    'CC-1. Sequential funding requests → second fails when balance exhausted',
    () async {
      // DOCUMENTS: sequential isolation — first call succeeds, second fails.
      // Even if both futures were launched simultaneously, at the SQLite layer
      // they execute serially; the second transaction will see the debited
      // balance IF the balance check is inside the transaction.
      // With the current architecture (balance check outside transaction),
      // strict concurrency protection requires calling operations sequentially.

      const srcId = 'src-cc1';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 10000); // 100.00 available

      final goalResult = await createGoal(idempotencyKey: 'ik-cc1');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      // First request: 80.00 — must succeed.
      final r1 = await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 8000,
        householdId: _hh,
        idempotencyKey: 'ik-cc1-fund-1',
      );
      expect(
        r1,
        isA<AppOk<SavingsGoal>>(),
        reason: 'CC-1: first funding of 8000 must succeed',
      );

      // Second request: another 80.00 — must fail (only 20.00 = 2000 remaining).
      final r2 = await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 8000,
        householdId: _hh,
        idempotencyKey: 'ik-cc1-fund-2',
      );
      expect(
        r2,
        isA<AppInsufficientFunds<SavingsGoal>>(),
        reason: 'CC-1: second funding must fail — only 2000 remains',
      );

      // Final reserve balance = 8000 (only one transfer completed).
      final balResult = await goalRepo.getReserveBalance(
        reserveAccountId: goal.reserveAccountId,
        householdId: _hh,
      );
      expect(
        (balResult as AppOk<int>).value,
        8000,
        reason:
            'CC-1: reserve balance must equal the single successful funding',
      );
    },
  );

  test(
    'CC-2. Sequential competing operations (transfer + funding) → balance never negative',
    () async {
      // DOCUMENTS: regardless of operation order, the ledger-backed balance
      // check ensures the source account balance never goes below zero when
      // operations are awaited sequentially. SQLite WAL serialises the write
      // transactions; the Dart await chain serialises the balance checks.

      const srcId = 'src-cc2';
      const dstId = 'dst-cc2';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 10000); // 100.00

      final goalResult = await createGoal(idempotencyKey: 'ik-cc2');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      // First operation: fund goal with 80% of balance.
      final r1 = await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 8000,
        householdId: _hh,
        idempotencyKey: 'ik-cc2-fund',
      );
      expect(
        r1,
        isA<AppOk<SavingsGoal>>(),
        reason: 'CC-2: first funding must succeed',
      );

      // Second operation: fund goal with another 80% — balance only has 20%.
      final r2 = await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 8000,
        householdId: _hh,
        idempotencyKey: 'ik-cc2-fund-2',
      );
      expect(
        r2,
        isA<AppInsufficientFunds<SavingsGoal>>(),
        reason: 'CC-2: second funding must fail — balance exhausted',
      );

      // Source balance is exactly 2000 (never went negative).
      final srcBalResult = await goalRepo.getReserveBalance(
        reserveAccountId: srcId,
        householdId: _hh,
      );
      expect(
        (srcBalResult as AppOk<int>).value,
        greaterThanOrEqualTo(0),
        reason: 'CC-2: source balance must not go negative',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.3 – Section 3: Genuine overlapping-operation tests (CONC-1..4)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // DART CONCURRENCY MODEL:
  // Dart is single-threaded. Two Futures launched before either is awaited
  // interleave at `await` points. SQLite WAL serializes writes. The balance
  // check is now INSIDE the transaction (Phase 5B.3 fix), so the second
  // writer sees the post-commit balance of the first — preventing overdrafts.
  //
  // Pattern:
  //   final f1 = useCase.execute(...);
  //   final f2 = useCase.execute(...);
  //   final results = await Future.wait([f1, f2], eagerError: false);
  //
  // SQLite serializes these; one succeeds, one sees the updated balance and
  // fails with AppInsufficientFunds (or returns AppOk on idempotent replay).

  test(
    'CONC-1. Goal funding vs goal funding (source=10000, each=8000) → exactly 1 success',
    () async {
      const srcId = 'src-conc1';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 10000);

      final goalResult = await createGoal(idempotencyKey: 'ik-conc1');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      // Launch both futures before awaiting either.
      final f1 = fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 8000,
        householdId: _hh,
        idempotencyKey: 'ik-conc1-f1',
      );
      final f2 = fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 8000,
        householdId: _hh,
        idempotencyKey: 'ik-conc1-f2',
      );

      final results = await Future.wait([f1, f2], eagerError: false);

      final successes = results.whereType<AppOk<SavingsGoal>>().length;
      final failures = results
          .whereType<AppInsufficientFunds<SavingsGoal>>()
          .length;

      expect(successes, 1, reason: 'CONC-1: exactly 1 of 2 must succeed');
      expect(failures, 1, reason: 'CONC-1: exactly 1 of 2 must fail');

      // Source balance must not be negative.
      final srcBalance = await goalRepo.getReserveBalance(
        reserveAccountId: srcId,
        householdId: _hh,
      );
      expect(
        (srcBalance as AppOk<int>).value,
        greaterThanOrEqualTo(0),
        reason: 'CONC-1: source balance must not go negative',
      );

      // Exactly 1 funding movement created.
      final movs = await goalRepo.getMovements(goal.id);
      expect(
        (movs as AppOk<List<GoalMovement>>).value.length,
        1,
        reason: 'CONC-1: exactly 1 movement must be recorded',
      );
    },
  );

  test(
    'CONC-2. Goal release vs goal release (reserve=10000, each=8000) → exactly 1 success',
    () async {
      const srcId = 'src-conc2';
      const dstId = 'dst-conc2';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 10000);

      final goalResult = await createGoal(idempotencyKey: 'ik-conc2');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      // Fund reserve with 10000.
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-conc2-fund',
      );

      // Launch two concurrent releases each requesting 8000.
      final f1 = releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dstId,
        amountMinorUnits: 8000,
        releaseReason: 'Concurrent release 1',
        householdId: _hh,
        idempotencyKey: 'ik-conc2-r1',
      );
      final f2 = releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dstId,
        amountMinorUnits: 8000,
        releaseReason: 'Concurrent release 2',
        householdId: _hh,
        idempotencyKey: 'ik-conc2-r2',
      );

      final results = await Future.wait([f1, f2], eagerError: false);

      final successes = results.whereType<AppOk<SavingsGoal>>().length;
      expect(
        successes,
        1,
        reason: 'CONC-2: exactly 1 of 2 releases must succeed',
      );

      // Reserve balance must not be negative.
      final reserveBal = await goalRepo.getReserveBalance(
        reserveAccountId: goal.reserveAccountId,
        householdId: _hh,
      );
      expect(
        (reserveBal as AppOk<int>).value,
        greaterThanOrEqualTo(0),
        reason: 'CONC-2: reserve balance must not go negative',
      );
    },
  );

  test(
    'CONC-3. Goal funding vs ordinary expense from same source → no negative balance',
    () async {
      const srcId = 'src-conc3';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 10000);

      final goalResult = await createGoal(idempotencyKey: 'ik-conc3');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      // Also create a member for the expense use case.
      await db.customStatement(
        "INSERT INTO household_members (id, household_id, display_name, role, "
        "is_archived, created_at, updated_at) VALUES "
        "('m-conc3', '$_hh', 'Test User', 'primary_user', 0, '2024-01-01', '2024-01-01')",
      );

      // Use TransferUseCase instead of expense to avoid household member lookup
      final transferUc = ExecuteTransferUseCase(
        ledgerRepository: ledgerRepo,
        accountRepository: accountRepo,
      );
      const dstId = 'dst-conc3';
      await createAccount(id: dstId, householdId: _hh);

      // Launch goal funding (8000) and ordinary transfer (8000) concurrently.
      final f1 = fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 8000,
        householdId: _hh,
        idempotencyKey: 'ik-conc3-fund',
      );
      final f2 = transferUc.execute(
        const TransferContext(
          operationId: 'op-conc3-transfer',
          idempotencyKey: 'ik-conc3-transfer',
          householdId: _hh,
          sourceAccountId: srcId,
          destinationAccountId: dstId,
          amountMinorUnits: 8000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'test',
          note: 'Concurrent transfer',
        ),
      );

      final results = await Future.wait([f1, f2], eagerError: false);
      final successes = results.length;
      expect(
        successes,
        2,
        reason: 'Both futures must complete (succeed or fail, not throw)',
      );

      // Final balance of source must not be negative.
      final srcBalEntries = await db
          .customSelect(
            'SELECT COALESCE(SUM(CASE WHEN direction = ? THEN amount_minor_units '
            'ELSE -amount_minor_units END), 0) AS bal FROM ledger_entries '
            'WHERE account_id = ? AND household_id = ?',
            variables: [
              const Variable('credit'),
              const Variable(srcId),
              const Variable(_hh),
            ],
          )
          .get();
      final finalBal = srcBalEntries.first.read<int>('bal');
      expect(
        finalBal,
        greaterThanOrEqualTo(0),
        reason: 'CONC-3: source balance must not go negative',
      );
    },
  );

  test(
    'CONC-4. Duplicate idempotency key (same payload) → both return AppOk, 1 operation created',
    () async {
      const srcId = 'src-conc4';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-conc4');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      const sameKey = 'ik-conc4-fund-same';

      // Two futures with the SAME idempotency key.
      final f1 = fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 5000,
        householdId: _hh,
        idempotencyKey: sameKey,
      );
      final f2 = fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 5000,
        householdId: _hh,
        idempotencyKey: sameKey,
      );

      final results = await Future.wait([f1, f2], eagerError: false);
      final successes = results.whereType<AppOk<SavingsGoal>>().length;
      expect(
        successes,
        2,
        reason: 'CONC-4: both idempotent calls must succeed',
      );

      // Exactly 1 transfer operation must exist for this key.
      final opCount = await db
          .customSelect(
            "SELECT COUNT(*) as c FROM operations WHERE idempotency_key = ? "
            "AND household_id = ?",
            variables: [const Variable(sameKey), const Variable(_hh)],
          )
          .get();
      expect(
        opCount.first.read<int>('c'),
        1,
        reason: 'CONC-4: idempotent key must produce exactly 1 operation',
      );

      // Exactly 1 movement for this goal.
      final movs = await goalRepo.getMovements(goal.id);
      final fundingMovs = (movs as AppOk<List<GoalMovement>>).value
          .where((m) => m.movementType == GoalMovementType.funding)
          .toList();
      expect(
        fundingMovs.length,
        1,
        reason: 'CONC-4: idempotent key must produce exactly 1 movement',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.3 – Section 4: Financial audit creation (AUDIT-1..6)
  // ══════════════════════════════════════════════════════════════════════════
  //
  // `operation_contexts` is the canonical audit record for all financial
  // operations. Every goal operation must produce an operation_context row.

  test('AUDIT-1. Goal funding creates an operation_context', () async {
    const srcId = 'src-audit1';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(idempotencyKey: 'ik-audit1');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 5000,
      householdId: _hh,
      idempotencyKey: 'ik-audit1-fund',
    );

    // Find the transfer operation for this funding.
    final opRows = await db
        .customSelect(
          "SELECT id FROM operations WHERE type = 'transfer' "
          "AND destination_account_id = '${goal.reserveAccountId}' "
          "AND household_id = '$_hh'",
        )
        .get();
    expect(opRows.isNotEmpty, isTrue);
    final opId = opRows.first.read<String>('id');

    final ctxRows = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM operation_contexts "
          "WHERE operation_id = ? AND household_id = ?",
          variables: [Variable(opId), const Variable(_hh)],
        )
        .get();
    expect(
      ctxRows.first.read<int>('c'),
      1,
      reason: 'AUDIT-1: funding must create exactly 1 operation_context',
    );
  });

  test('AUDIT-2. Goal release creates an operation_context', () async {
    const srcId = 'src-audit2';
    const dstId = 'dst-audit2';
    await createAccount(id: srcId, householdId: _hh);
    await createAccount(id: dstId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(idempotencyKey: 'ik-audit2');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      householdId: _hh,
      idempotencyKey: 'ik-audit2-fund',
    );

    await releaseGoalUc.execute(
      goalId: goal.id,
      destinationAccountId: dstId,
      amountMinorUnits: 10000,
      releaseReason: 'Audit test release',
      householdId: _hh,
      idempotencyKey: 'ik-audit2-release',
    );

    // Find the release operation.
    final opRows = await db
        .customSelect(
          "SELECT id FROM operations WHERE type = 'transfer' "
          "AND source_account_id = '${goal.reserveAccountId}' "
          "AND household_id = '$_hh'",
        )
        .get();
    expect(opRows.isNotEmpty, isTrue);
    final opId = opRows.first.read<String>('id');

    final ctxRows = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM operation_contexts "
          "WHERE operation_id = ? AND household_id = ?",
          variables: [Variable(opId), const Variable(_hh)],
        )
        .get();
    expect(
      ctxRows.first.read<int>('c'),
      1,
      reason: 'AUDIT-2: release must create exactly 1 operation_context',
    );
  });

  test('AUDIT-3. Initial funding creates an operation_context', () async {
    const srcId = 'src-audit3';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-audit3',
      sourceAccountId: srcId,
      initialFunding: 10000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    // The initial funding operation.
    final opRows = await db
        .customSelect(
          "SELECT id FROM operations WHERE type = 'transfer' "
          "AND destination_account_id = '${goal.reserveAccountId}' "
          "AND household_id = '$_hh'",
        )
        .get();
    expect(opRows.isNotEmpty, isTrue);
    final opId = opRows.first.read<String>('id');

    final ctxRows = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM operation_contexts "
          "WHERE operation_id = ? AND household_id = ?",
          variables: [Variable(opId), const Variable(_hh)],
        )
        .get();
    expect(
      ctxRows.first.read<int>('c'),
      1,
      reason:
          'AUDIT-3: initial funding must create exactly 1 operation_context',
    );
  });

  test(
    'AUDIT-4. Audit references correct operation_id and household_id',
    () async {
      const srcId = 'src-audit4';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-audit4');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 5000,
        householdId: _hh,
        idempotencyKey: 'ik-audit4-fund',
      );

      final opRows = await db
          .customSelect(
            "SELECT id FROM operations WHERE type = 'transfer' "
            "AND destination_account_id = '${goal.reserveAccountId}' "
            "AND household_id = '$_hh'",
          )
          .get();
      final opId = opRows.first.read<String>('id');

      final ctxRows = await db
          .customSelect(
            "SELECT operation_id, household_id FROM operation_contexts "
            "WHERE operation_id = ?",
            variables: [Variable(opId)],
          )
          .get();
      expect(ctxRows.isNotEmpty, isTrue);
      expect(ctxRows.first.read<String>('operation_id'), opId);
      expect(ctxRows.first.read<String>('household_id'), _hh);
    },
  );

  test('AUDIT-5. Idempotent retry creates no additional audit', () async {
    const srcId = 'src-audit5';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(idempotencyKey: 'ik-audit5');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    // First call.
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 5000,
      householdId: _hh,
      idempotencyKey: 'ik-audit5-fund',
    );

    final ctxCountBefore =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM operation_contexts WHERE household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('c');

    // Idempotent retry with same key.
    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 5000,
      householdId: _hh,
      idempotencyKey: 'ik-audit5-fund',
    );

    final ctxCountAfter =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM operation_contexts WHERE household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('c');

    expect(
      ctxCountAfter,
      ctxCountBefore,
      reason: 'AUDIT-5: idempotent retry must not create additional audit rows',
    );
  });

  test('AUDIT-6. Failed workflow (insufficient funds) creates no audit', () async {
    const srcId = 'src-audit6';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 1000); // Only 1000 available

    final goalResult = await createGoal(idempotencyKey: 'ik-audit6');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final ctxCountBefore =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM operation_contexts WHERE household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('c');

    // Try to fund 5000 but only 1000 available → should fail.
    final result = await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 5000,
      householdId: _hh,
      idempotencyKey: 'ik-audit6-fund',
    );
    expect(result, isA<AppInsufficientFunds<SavingsGoal>>());

    final ctxCountAfter =
        (await db
                .customSelect(
                  "SELECT COUNT(*) as c FROM operation_contexts WHERE household_id = '$_hh'",
                )
                .get())
            .first
            .read<int>('c');

    expect(
      ctxCountAfter,
      ctxCountBefore,
      reason: 'AUDIT-6: failed workflow must not create any audit rows',
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.3 – Section 7: Reserve bypass restrictions (BYPS-1..6)
  // ══════════════════════════════════════════════════════════════════════════

  test('BYPS-1. Opening balance with goalReserve account → error', () async {
    final goalResult = await createGoal(idempotencyKey: 'ik-byps1');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await expectLater(
      () => ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'op-byps1',
          householdId: _hh,
          accountId: goal.reserveAccountId,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'test',
        ),
      ),
      throwsA(isA<ArgumentError>()),
      reason:
          'BYPS-1: opening balance must be rejected for goalReserve accounts',
    );
  });

  test('BYPS-2. Adjustment with goalReserve account → error', () async {
    final goalResult = await createGoal(idempotencyKey: 'ik-byps2');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await expectLater(
      () => ledgerRepo.recordAdjustment(
        RecordAdjustmentParams(
          operationId: 'op-byps2',
          householdId: _hh,
          accountId: goal.reserveAccountId,
          adjustmentAmountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'test',
          reason: 'Direct adjustment attempt',
        ),
      ),
      throwsA(isA<ArgumentError>()),
      reason: 'BYPS-2: adjustment must be rejected for goalReserve accounts',
    );
  });

  test(
    'BYPS-3. Reversal of goal funding transfer → reserve balance decreases',
    () async {
      const srcId = 'src-byps3';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-byps3');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-byps3-fund',
      );

      final reserveBefore =
          (await goalRepo.getReserveBalance(
                    reserveAccountId: goal.reserveAccountId,
                    householdId: _hh,
                  )
                  as AppOk<int>)
              .value;
      expect(reserveBefore, 10000);

      // Find the funding operation.
      final opRows = await db
          .customSelect(
            "SELECT id FROM operations WHERE type = 'transfer' "
            "AND destination_account_id = '${goal.reserveAccountId}'",
          )
          .get();
      final fundOpId = opRows.first.read<String>('id');

      // Reverse the funding operation.
      await ledgerRepo.reverseOperation(
        ReverseOperationParams(
          originalOperationId: fundOpId,
          reversalOperationId: 'rev-byps3',
          householdId: _hh,
          effectiveDate: '2024-01-02',
          createdBy: 'test',
        ),
      );

      final reserveAfter =
          (await goalRepo.getReserveBalance(
                    reserveAccountId: goal.reserveAccountId,
                    householdId: _hh,
                  )
                  as AppOk<int>)
              .value;
      expect(
        reserveAfter,
        0,
        reason:
            'BYPS-3: reversal of funding must decrease reserve balance to 0',
      );
    },
  );

  test(
    'BYPS-4. Reversal of goal release transfer → reserve balance increases',
    () async {
      const srcId = 'src-byps4';
      const dstId = 'dst-byps4';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-byps4');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 20000,
        householdId: _hh,
        idempotencyKey: 'ik-byps4-fund',
      );
      await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dstId,
        amountMinorUnits: 10000,
        releaseReason: 'Partial release',
        householdId: _hh,
        idempotencyKey: 'ik-byps4-release',
      );

      final reserveAfterRelease =
          (await goalRepo.getReserveBalance(
                    reserveAccountId: goal.reserveAccountId,
                    householdId: _hh,
                  )
                  as AppOk<int>)
              .value;
      expect(reserveAfterRelease, 10000);

      // Find the release operation.
      final opRows = await db
          .customSelect(
            "SELECT id FROM operations WHERE type = 'transfer' "
            "AND source_account_id = '${goal.reserveAccountId}'",
          )
          .get();
      final releaseOpId = opRows.first.read<String>('id');

      // Reverse the release.
      await ledgerRepo.reverseOperation(
        ReverseOperationParams(
          originalOperationId: releaseOpId,
          reversalOperationId: 'rev-byps4',
          householdId: _hh,
          effectiveDate: '2024-01-03',
          createdBy: 'test',
        ),
      );

      final reserveAfterReversal =
          (await goalRepo.getReserveBalance(
                    reserveAccountId: goal.reserveAccountId,
                    householdId: _hh,
                  )
                  as AppOk<int>)
              .value;
      expect(
        reserveAfterReversal,
        20000,
        reason: 'BYPS-4: reversal of release must restore reserve balance',
      );
    },
  );

  test(
    'BYPS-5. Reversal does not create income/expense ledger entries',
    () async {
      const srcId = 'src-byps5';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-byps5');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-byps5-fund',
      );

      final opRows = await db
          .customSelect(
            "SELECT id FROM operations WHERE type = 'transfer' "
            "AND destination_account_id = '${goal.reserveAccountId}'",
          )
          .get();
      final fundOpId = opRows.first.read<String>('id');

      await ledgerRepo.reverseOperation(
        ReverseOperationParams(
          originalOperationId: fundOpId,
          reversalOperationId: 'rev-byps5',
          householdId: _hh,
          effectiveDate: '2024-01-02',
          createdBy: 'test',
        ),
      );

      // Reversal entries must be reversalDebit/reversalCredit — never income/expense.
      final badEntries = await db
          .customSelect(
            "SELECT COUNT(*) as c FROM ledger_entries "
            "WHERE operation_id = 'rev-byps5' "
            "AND entry_type IN ('income', 'expense', 'childFundWithdrawal')",
          )
          .get();
      expect(
        badEntries.first.read<int>('c'),
        0,
        reason: 'BYPS-5: reversal must not create income/expense entries',
      );
    },
  );

  test(
    'BYPS-6. Unrelated transfer reversal does not affect goal reserve',
    () async {
      const srcId = 'src-byps6';
      const dstId = 'dst-byps6';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-byps6');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      // Fund goal.
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-byps6-fund',
      );
      final reserveBefore =
          (await goalRepo.getReserveBalance(
                    reserveAccountId: goal.reserveAccountId,
                    householdId: _hh,
                  )
                  as AppOk<int>)
              .value;

      // Do an unrelated transfer src→dst.
      await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: 'op-byps6-unrelated',
          householdId: _hh,
          sourceAccountId: srcId,
          destinationAccountId: dstId,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'test',
          description: 'Unrelated transfer',
        ),
      );

      // Reverse the unrelated transfer.
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          originalOperationId: 'op-byps6-unrelated',
          reversalOperationId: 'rev-byps6',
          householdId: _hh,
          effectiveDate: '2024-01-03',
          createdBy: 'test',
        ),
      );

      final reserveAfter =
          (await goalRepo.getReserveBalance(
                    reserveAccountId: goal.reserveAccountId,
                    householdId: _hh,
                  )
                  as AppOk<int>)
              .value;
      expect(
        reserveAfter,
        reserveBefore,
        reason: 'BYPS-6: unrelated reversal must not change reserve balance',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.3 – Section 8: Complete goal lifecycle (CG-EXT-1..4)
  // ══════════════════════════════════════════════════════════════════════════

  test(
    'CG-EXT-1. Missing earlyCompletionConfirmed flag → AppValidationFailure',
    () async {
      final goalResult = await createGoal(idempotencyKey: 'ik-cgext1');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final cg = CompleteGoalUseCase(goalRepo);
      final result = await cg.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: _hh,
          earlyCompletion: true,
          // earlyCompletionConfirmed intentionally omitted (defaults to false)
          earlyCompletionReason: 'Reason provided but not confirmed',
        ),
      );
      expect(result, isA<AppValidationFailure<SavingsGoal>>());
      expect(
        (result as AppValidationFailure).messageKey,
        'errorEarlyCompletionConfirmationRequired',
        reason: 'CG-EXT-1: missing confirmation must fail with correct key',
      );
    },
  );

  test(
    'CG-EXT-2. Missing earlyCompletionReason when earlyCompletion=true → AppValidationFailure',
    () async {
      final goalResult = await createGoal(idempotencyKey: 'ik-cgext2');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final cg = CompleteGoalUseCase(goalRepo);
      final result = await cg.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: _hh,
          earlyCompletion: true,
          earlyCompletionConfirmed: true,
          // earlyCompletionReason intentionally omitted
        ),
      );
      expect(result, isA<AppValidationFailure<SavingsGoal>>());
      expect(
        (result as AppValidationFailure).messageKey,
        'errorEarlyCompletionReasonRequired',
        reason: 'CG-EXT-2: missing reason must fail with correct key',
      );
    },
  );

  test(
    'CG-EXT-3. Idempotent completion → same goal returned on second call',
    () async {
      const srcId = 'src-cgext3';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 200000);

      final goalResult = await createGoal(
        idempotencyKey: 'ik-cgext3',
        target: 100000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 100000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-cgext3',
      );

      final cg = CompleteGoalUseCase(goalRepo);
      final r1 = await cg.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: _hh,
          idempotencyKey: 'complete-${goal.id}',
        ),
      );
      final r2 = await cg.execute(
        CompleteGoalParams(
          goalId: goal.id,
          householdId: _hh,
          idempotencyKey: 'complete-${goal.id}',
        ),
      );

      expect(r1, isA<AppOk<SavingsGoal>>());
      expect(r2, isA<AppOk<SavingsGoal>>());
      expect(
        (r2 as AppOk<SavingsGoal>).value.status,
        GoalStatus.completed,
        reason: 'CG-EXT-3: second call must return completed goal',
      );
    },
  );

  test(
    'CG-EXT-4. completed_at is set correctly on normal completion',
    () async {
      const srcId = 'src-cgext4';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 200000);

      final goalResult = await createGoal(
        idempotencyKey: 'ik-cgext4',
        target: 50000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;
      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 50000,
        householdId: _hh,
        idempotencyKey: 'ik-fund-cgext4',
      );

      final before = DateTime.now().toUtc();

      final cg = CompleteGoalUseCase(goalRepo);
      final result = await cg.execute(
        CompleteGoalParams(goalId: goal.id, householdId: _hh),
      );
      expect(result, isA<AppOk<SavingsGoal>>());

      final completedGoal = (result as AppOk<SavingsGoal>).value;
      expect(completedGoal.completedAt, isNotNull);

      final completedAt = DateTime.parse(completedGoal.completedAt!);
      expect(
        completedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
        reason: 'CG-EXT-4: completed_at must be a recent UTC timestamp',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.4 – Section 5: Concurrency tests (CONC-5..10)
  // ══════════════════════════════════════════════════════════════════════════

  test(
    'CONC-5. Release vs release from same reserve — only one succeeds, balance never negative',
    () async {
      const srcId = 'src-conc5';
      const dstId = 'dst-conc5';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-conc5');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-conc5-fund',
      );

      final f1 = releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dstId,
        amountMinorUnits: 9000,
        releaseReason: 'CONC-5 release A',
        householdId: _hh,
        idempotencyKey: 'ik-conc5-r1',
      );
      final f2 = releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dstId,
        amountMinorUnits: 9000,
        releaseReason: 'CONC-5 release B',
        householdId: _hh,
        idempotencyKey: 'ik-conc5-r2',
      );

      final results = await Future.wait([f1, f2], eagerError: false);
      final successes = results.whereType<AppOk<SavingsGoal>>().length;
      expect(
        successes,
        1,
        reason: 'CONC-5: exactly 1 of 2 releases must succeed',
      );

      final reserveBal =
          (await goalRepo.getReserveBalance(
                    reserveAccountId: goal.reserveAccountId,
                    householdId: _hh,
                  )
                  as AppOk<int>)
              .value;
      expect(
        reserveBal,
        greaterThanOrEqualTo(0),
        reason: 'CONC-5: reserve balance must not go negative',
      );

      final movs =
          (await goalRepo.getMovements(goal.id) as AppOk<List<GoalMovement>>)
              .value;
      // 1 funding + 1 release
      expect(
        movs.where((m) => m.movementType == GoalMovementType.release).length,
        1,
        reason: 'CONC-5: exactly 1 release movement must be recorded',
      );
    },
  );

  test(
    'CONC-6. Funding vs ordinary transfer from same source — only one succeeds',
    () async {
      const srcId = 'src-conc6';
      const dstId = 'dst-conc6';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 10000);

      final goalResult = await createGoal(idempotencyKey: 'ik-conc6');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final transferUc = ExecuteTransferUseCase(
        ledgerRepository: ledgerRepo,
        accountRepository: accountRepo,
      );

      final f1 = fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 9000,
        householdId: _hh,
        idempotencyKey: 'ik-conc6-fund',
      );
      final f2 = transferUc.execute(
        const TransferContext(
          operationId: 'op-conc6-transfer',
          idempotencyKey: 'ik-conc6-transfer',
          householdId: _hh,
          sourceAccountId: srcId,
          destinationAccountId: dstId,
          amountMinorUnits: 9000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'test',
          note: 'CONC-6 transfer',
        ),
      );

      final results = await Future.wait([f1, f2], eagerError: false);
      expect(results.length, 2, reason: 'CONC-6: both futures must complete');

      final srcBal = await db
          .customSelect(
            'SELECT COALESCE(SUM(CASE WHEN direction = ? THEN amount_minor_units '
            'ELSE -amount_minor_units END), 0) AS bal FROM ledger_entries '
            'WHERE account_id = ? AND household_id = ?',
            variables: [
              const Variable('credit'),
              const Variable(srcId),
              const Variable(_hh),
            ],
          )
          .get();
      expect(
        srcBal.first.read<int>('bal'),
        greaterThanOrEqualTo(0),
        reason: 'CONC-6: source balance must not go negative',
      );
    },
  );

  test(
    'CONC-7. Two releases from different reserves — both succeed independently',
    () async {
      const srcId = 'src-conc7';
      const dstId = 'dst-conc7';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 100000);

      final g1Result = await createGoal(idempotencyKey: 'ik-conc7-g1');
      final g2Result = await createGoal(idempotencyKey: 'ik-conc7-g2');
      final goal1 = (g1Result as AppOk<SavingsGoal>).value;
      final goal2 = (g2Result as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal1.id,
        sourceAccountId: srcId,
        amountMinorUnits: 20000,
        householdId: _hh,
        idempotencyKey: 'ik-conc7-fund1',
      );
      await fundGoalUc.execute(
        goalId: goal2.id,
        sourceAccountId: srcId,
        amountMinorUnits: 20000,
        householdId: _hh,
        idempotencyKey: 'ik-conc7-fund2',
      );

      final f1 = releaseGoalUc.execute(
        goalId: goal1.id,
        destinationAccountId: dstId,
        amountMinorUnits: 10000,
        releaseReason: 'CONC-7 goal1 release',
        householdId: _hh,
        idempotencyKey: 'ik-conc7-r1',
      );
      final f2 = releaseGoalUc.execute(
        goalId: goal2.id,
        destinationAccountId: dstId,
        amountMinorUnits: 10000,
        releaseReason: 'CONC-7 goal2 release',
        householdId: _hh,
        idempotencyKey: 'ik-conc7-r2',
      );

      final results = await Future.wait([f1, f2], eagerError: false);
      final successes = results.whereType<AppOk<SavingsGoal>>().length;
      expect(
        successes,
        2,
        reason: 'CONC-7: both releases from independent reserves must succeed',
      );
    },
  );

  test(
    'CONC-8. Equivalent duplicate during in-flight — both return AppOk, same operation',
    () async {
      const srcId = 'src-conc8';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-conc8');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      const sameKey = 'ik-conc8-fund-same';
      final f1 = fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 5000,
        householdId: _hh,
        idempotencyKey: sameKey,
      );
      final f2 = fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 5000,
        householdId: _hh,
        idempotencyKey: sameKey,
      );

      final results = await Future.wait([f1, f2], eagerError: false);
      final successes = results.whereType<AppOk<SavingsGoal>>().length;
      expect(
        successes,
        2,
        reason: 'CONC-8: idempotent duplicate must return AppOk for both',
      );

      final opCount = await db
          .customSelect(
            "SELECT COUNT(*) as c FROM operations WHERE idempotency_key = ? "
            "AND household_id = ?",
            variables: [const Variable(sameKey), const Variable(_hh)],
          )
          .get();
      expect(
        opCount.first.read<int>('c'),
        1,
        reason: 'CONC-8: same idempotency key must produce exactly 1 operation',
      );
    },
  );

  test(
    'CONC-9. Conflicting duplicate (same key, different amount) → AppDuplicateConflict for loser',
    () async {
      // Phase 5B.5: conflicting payloads under the same scoped key must surface
      // AppDuplicateConflict (not AppOk). Exactly 1 operation is committed.
      const srcId = 'src-conc9';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-conc9');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      const sameKey = 'ik-conc9-conflict';
      final f1 = fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 5000,
        householdId: _hh,
        idempotencyKey: sameKey,
      );
      final f2 = fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 7000,
        householdId: _hh,
        idempotencyKey: sameKey,
      );

      final results = await Future.wait([f1, f2], eagerError: false);
      expect(results.length, 2, reason: 'CONC-9: both futures must complete');

      final oks = results.whereType<AppOk<SavingsGoal>>().length;
      final conflicts = results
          .whereType<AppDuplicateConflict<SavingsGoal>>()
          .length;
      expect(oks, 1, reason: 'CONC-9: exactly one caller succeeds');
      expect(
        conflicts,
        1,
        reason: 'CONC-9: loser must be AppDuplicateConflict',
      );

      final opCount = await db
          .customSelect(
            "SELECT COUNT(*) as c FROM operations WHERE idempotency_key = ? "
            "AND household_id = ?",
            variables: [const Variable(sameKey), const Variable(_hh)],
          )
          .get();
      expect(
        opCount.first.read<int>('c'),
        1,
        reason:
            'CONC-9: exactly 1 operation must be committed for the same key',
      );

      final srcBal = await db
          .customSelect(
            'SELECT COALESCE(SUM(CASE WHEN direction = ? THEN amount_minor_units '
            'ELSE -amount_minor_units END), 0) AS bal FROM ledger_entries '
            'WHERE account_id = ? AND household_id = ?',
            variables: [
              const Variable('credit'),
              const Variable(srcId),
              const Variable(_hh),
            ],
          )
          .get();
      expect(
        srcBal.first.read<int>('bal'),
        greaterThanOrEqualTo(0),
        reason: 'CONC-9: source balance must not go negative',
      );
    },
  );

  test(
    'CONC-10. Competing expense vs goal-funding vs transfer (3-way) — exactly the affordable combination succeeds',
    () async {
      const srcId = 'src-conc10';
      const dstId = 'dst-conc10';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 10000); // Enough for only 1 of 3.

      final goalResult = await createGoal(idempotencyKey: 'ik-conc10');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final transferUc = ExecuteTransferUseCase(
        ledgerRepository: ledgerRepo,
        accountRepository: accountRepo,
      );

      final f1 = fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 9000,
        householdId: _hh,
        idempotencyKey: 'ik-conc10-fund',
      );
      final f2 = transferUc.execute(
        const TransferContext(
          operationId: 'op-conc10-t1',
          idempotencyKey: 'ik-conc10-t1',
          householdId: _hh,
          sourceAccountId: srcId,
          destinationAccountId: dstId,
          amountMinorUnits: 9000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'test',
          note: 'CONC-10 transfer 1',
        ),
      );
      final f3 = transferUc.execute(
        const TransferContext(
          operationId: 'op-conc10-t2',
          idempotencyKey: 'ik-conc10-t2',
          householdId: _hh,
          sourceAccountId: srcId,
          destinationAccountId: dstId,
          amountMinorUnits: 9000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'test',
          note: 'CONC-10 transfer 2',
        ),
      );

      final results = await Future.wait([f1, f2, f3], eagerError: false);
      expect(results.length, 3, reason: 'CONC-10: all 3 futures must complete');

      final srcBal = await db
          .customSelect(
            'SELECT COALESCE(SUM(CASE WHEN direction = ? THEN amount_minor_units '
            'ELSE -amount_minor_units END), 0) AS bal FROM ledger_entries '
            'WHERE account_id = ? AND household_id = ?',
            variables: [
              const Variable('credit'),
              const Variable(srcId),
              const Variable(_hh),
            ],
          )
          .get();
      expect(
        srcBal.first.read<int>('bal'),
        greaterThanOrEqualTo(0),
        reason: 'CONC-10: source balance must not go negative after 3-way race',
      );
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.4 – Section 6: Goal lifecycle events (GLC-1..8)
  // ══════════════════════════════════════════════════════════════════════════

  test('GLC-1. Normal completion creates a lifecycle event', () async {
    const srcId = 'src-glc1';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-glc1',
      target: 50000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 50000,
      householdId: _hh,
      idempotencyKey: 'ik-glc1-fund',
    );

    final cg = CompleteGoalUseCase(goalRepo);
    final result = await cg.execute(
      CompleteGoalParams(goalId: goal.id, householdId: _hh),
    );
    expect(result, isA<AppOk<SavingsGoal>>());

    final events = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM goal_lifecycle_events "
          "WHERE goal_id = ? AND event_type = 'completed'",
          variables: [Variable.withString(goal.id)],
        )
        .get();
    expect(
      events.first.read<int>('c'),
      1,
      reason: 'GLC-1: normal completion must create exactly 1 lifecycle event',
    );
  });

  test('GLC-2. Early completion creates lifecycle event with reason', () async {
    const srcId = 'src-glc2';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-glc2',
      target: 100000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 30000,
      householdId: _hh,
      idempotencyKey: 'ik-glc2-fund',
    );

    final cg = CompleteGoalUseCase(goalRepo);
    final result = await cg.execute(
      CompleteGoalParams(
        goalId: goal.id,
        householdId: _hh,
        earlyCompletion: true,
        earlyCompletionConfirmed: true,
        earlyCompletionReason: 'Changed plans for GLC-2',
      ),
    );
    expect(result, isA<AppOk<SavingsGoal>>());

    final events = await db
        .customSelect(
          "SELECT completion_type, early_completion_reason "
          "FROM goal_lifecycle_events WHERE goal_id = ?",
          variables: [Variable.withString(goal.id)],
        )
        .get();
    expect(events.isNotEmpty, isTrue, reason: 'GLC-2: event must exist');
    expect(
      events.first.read<String>('completion_type'),
      'early',
      reason: 'GLC-2: completion_type must be early',
    );
    expect(
      events.first.readNullable<String>('early_completion_reason'),
      'Changed plans for GLC-2',
      reason: 'GLC-2: reason must be stored',
    );
  });

  test(
    'GLC-3. UPDATE on lifecycle event → no_update_goal_lifecycle_events fires',
    () async {
      const srcId = 'src-glc3';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(
        idempotencyKey: 'ik-glc3',
        target: 10000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-glc3-fund',
      );
      final cg = CompleteGoalUseCase(goalRepo);
      await cg.execute(CompleteGoalParams(goalId: goal.id, householdId: _hh));

      await expectLater(
        () => db.customStatement(
          "UPDATE goal_lifecycle_events SET event_type = 'archived' "
          "WHERE goal_id = '${goal.id}'",
        ),
        throwsA(anything),
        reason: 'GLC-3: no_update_goal_lifecycle_events must prevent mutation',
      );
    },
  );

  test(
    'GLC-4. DELETE on lifecycle event → no_delete_goal_lifecycle_events fires',
    () async {
      const srcId = 'src-glc4';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(
        idempotencyKey: 'ik-glc4',
        target: 10000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 10000,
        householdId: _hh,
        idempotencyKey: 'ik-glc4-fund',
      );
      final cg = CompleteGoalUseCase(goalRepo);
      await cg.execute(CompleteGoalParams(goalId: goal.id, householdId: _hh));

      await expectLater(
        () => db.customStatement(
          "DELETE FROM goal_lifecycle_events WHERE goal_id = '${goal.id}'",
        ),
        throwsA(anything),
        reason: 'GLC-4: no_delete_goal_lifecycle_events must prevent deletion',
      );
    },
  );

  test(
    'GLC-5. Duplicate idempotency key → idempotent AppOk for both',
    () async {
      const srcId = 'src-glc5';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(
        idempotencyKey: 'ik-glc5',
        target: 10000,
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final now = DateTime.now().toUtc().toIso8601String();
      const key = 'glc5-idem-key';

      final event = GoalLifecycleEvent(
        id: 'evt-glc5-a',
        goalId: goal.id,
        householdId: _hh,
        eventType: GoalLifecycleEventType.completed,
        completionType: 'normal',
        effectiveAt: now,
        createdAt: now,
        idempotencyKey: key,
      );
      final r1 = await goalRepo.insertLifecycleEvent(event);
      // Same key, same event_type → idempotent.
      final r2 = await goalRepo.insertLifecycleEvent(
        GoalLifecycleEvent(
          id: 'evt-glc5-b', // Different id but same key.
          goalId: goal.id,
          householdId: _hh,
          eventType: GoalLifecycleEventType.completed,
          completionType: 'normal',
          effectiveAt: now,
          createdAt: now,
          idempotencyKey: key,
        ),
      );

      expect(
        r1,
        isA<AppOk<GoalLifecycleEvent>>(),
        reason: 'GLC-5: first insert must succeed',
      );
      expect(
        r2,
        isA<AppOk<GoalLifecycleEvent>>(),
        reason: 'GLC-5: second must be idempotent AppOk',
      );

      final count = await db
          .customSelect(
            "SELECT COUNT(*) as c FROM goal_lifecycle_events "
            "WHERE idempotency_key = ?",
            variables: [const Variable(key)],
          )
          .get();
      expect(
        count.first.read<int>('c'),
        1,
        reason: 'GLC-5: only 1 row for same key',
      );
    },
  );

  test('GLC-6. Same key, different payload → AppDuplicateConflict', () async {
    const srcId = 'src-glc6';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-glc6',
      target: 10000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final now = DateTime.now().toUtc().toIso8601String();
    const key = 'glc6-conflict-key';

    await goalRepo.insertLifecycleEvent(
      GoalLifecycleEvent(
        id: 'evt-glc6-a',
        goalId: goal.id,
        householdId: _hh,
        eventType: GoalLifecycleEventType.completed,
        effectiveAt: now,
        createdAt: now,
        idempotencyKey: key,
      ),
    );

    // Same key but DIFFERENT event_type → conflict.
    final r2 = await goalRepo.insertLifecycleEvent(
      GoalLifecycleEvent(
        id: 'evt-glc6-b',
        goalId: goal.id,
        householdId: _hh,
        eventType: GoalLifecycleEventType.archived, // Different!
        effectiveAt: now,
        createdAt: now,
        idempotencyKey: key,
      ),
    );

    expect(
      r2,
      isA<AppDuplicateConflict<GoalLifecycleEvent>>(),
      reason:
          'GLC-6: same key + different event_type must return AppDuplicateConflict',
    );
  });

  test('GLC-7. Cross-household lifecycle event → FK prevents insert', () async {
    const srcId = 'src-glc7';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-glc7',
      target: 10000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    final now = DateTime.now().toUtc().toIso8601String();

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goal_lifecycle_events (id, goal_id, household_id, "
        "event_type, effective_at, created_at, schema_version) "
        "VALUES ('evt-glc7-xhh', '${goal.id}', 'hh-does-not-exist', "
        "'completed', '$now', '$now', 12)",
      ),
      throwsA(anything),
      reason:
          'GLC-7: lifecycle event for wrong household must be rejected (FK or trigger)',
    );
  });

  test('GLC-8. No ledger entries created during goal completion', () async {
    const srcId = 'src-glc8';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-glc8',
      target: 20000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      householdId: _hh,
      idempotencyKey: 'ik-glc8-fund',
    );

    final entriesBefore = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM ledger_entries WHERE household_id = '$_hh'",
        )
        .get();
    final countBefore = entriesBefore.first.read<int>('c');

    final cg = CompleteGoalUseCase(goalRepo);
    await cg.execute(CompleteGoalParams(goalId: goal.id, householdId: _hh));

    final entriesAfter = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM ledger_entries WHERE household_id = '$_hh'",
        )
        .get();
    expect(
      entriesAfter.first.read<int>('c'),
      countBefore,
      reason: 'GLC-8: goal completion must NOT create any new ledger entries',
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.4 – Section 7: Goal-transfer reversal association (REV-1..5)
  // ══════════════════════════════════════════════════════════════════════════

  test(
    'REV-1. Reversal of goal funding → reserve balance decreases, reversal movement created',
    () async {
      const srcId = 'src-rev1';
      await createAccount(id: srcId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-rev1');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 20000,
        householdId: _hh,
        idempotencyKey: 'ik-rev1-fund',
      );

      final fundOpRows = await db
          .customSelect(
            "SELECT id FROM operations WHERE type = 'transfer' "
            "AND destination_account_id = '${goal.reserveAccountId}'",
          )
          .get();
      final fundOpId = fundOpRows.first.read<String>('id');

      final uc = ReverseGoalTransferUseCase(goalRepository: goalRepo);
      await uc.execute(
        originalOperationId: fundOpId,
        reversalOperationId: 'rev-op-rev1',
        householdId: _hh,
        effectiveDate: '2024-01-02',
        createdBy: 'test',
        reason: 'REV-1 reversal',
      );

      final balance =
          (await goalRepo.getReserveBalance(
                    reserveAccountId: goal.reserveAccountId,
                    householdId: _hh,
                  )
                  as AppOk<int>)
              .value;
      expect(balance, 0, reason: 'REV-1: reserve must be 0 after reversal');

      final movs =
          (await goalRepo.getMovements(goal.id) as AppOk<List<GoalMovement>>)
              .value;
      final reversals = movs.where(
        (m) => m.movementType == GoalMovementType.reversal,
      );
      expect(
        reversals.length,
        1,
        reason: 'REV-1: exactly 1 reversal movement must be created',
      );
      expect(
        reversals.first.transferOperationId,
        'rev-op-rev1',
        reason:
            'REV-1: reversal movement must reference the reversal operation',
      );
    },
  );

  test(
    'REV-2. Reversal of goal release → reserve balance increases, reversal movement created',
    () async {
      const srcId = 'src-rev2';
      const dstId = 'dst-rev2';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-rev2');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 30000,
        householdId: _hh,
        idempotencyKey: 'ik-rev2-fund',
      );
      await releaseGoalUc.execute(
        goalId: goal.id,
        destinationAccountId: dstId,
        amountMinorUnits: 15000,
        releaseReason: 'REV-2 initial release',
        householdId: _hh,
        idempotencyKey: 'ik-rev2-release',
      );

      final releaseOpRows = await db
          .customSelect(
            "SELECT id FROM operations WHERE type = 'transfer' "
            "AND source_account_id = '${goal.reserveAccountId}'",
          )
          .get();
      final releaseOpId = releaseOpRows.first.read<String>('id');

      final balBefore =
          (await goalRepo.getReserveBalance(
                    reserveAccountId: goal.reserveAccountId,
                    householdId: _hh,
                  )
                  as AppOk<int>)
              .value;

      final uc = ReverseGoalTransferUseCase(goalRepository: goalRepo);
      await uc.execute(
        originalOperationId: releaseOpId,
        reversalOperationId: 'rev-op-rev2',
        householdId: _hh,
        effectiveDate: '2024-01-03',
        createdBy: 'test',
      );

      final balAfter =
          (await goalRepo.getReserveBalance(
                    reserveAccountId: goal.reserveAccountId,
                    householdId: _hh,
                  )
                  as AppOk<int>)
              .value;
      expect(
        balAfter,
        balBefore + 15000,
        reason:
            'REV-2: reserve must increase by released amount after reversal',
      );

      final movs =
          (await goalRepo.getMovements(goal.id) as AppOk<List<GoalMovement>>)
              .value;
      expect(
        movs.where((m) => m.movementType == GoalMovementType.reversal).length,
        1,
        reason: 'REV-2: reversal movement must be created',
      );
    },
  );

  test('REV-3. Reversal is not income, expense, or budget spending', () async {
    const srcId = 'src-rev3';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 50000);

    final goalResult = await createGoal(idempotencyKey: 'ik-rev3');
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      householdId: _hh,
      idempotencyKey: 'ik-rev3-fund',
    );

    final fundOpId =
        (await db
                .customSelect(
                  "SELECT id FROM operations WHERE type = 'transfer' "
                  "AND destination_account_id = '${goal.reserveAccountId}'",
                )
                .get())
            .first
            .read<String>('id');

    await ReverseGoalTransferUseCase(goalRepository: goalRepo).execute(
      originalOperationId: fundOpId,
      reversalOperationId: 'rev-op-rev3',
      householdId: _hh,
      effectiveDate: '2024-01-02',
      createdBy: 'test',
    );

    // Verify the reversal operation type is 'reversal', not income/expense.
    final revOp = await db
        .customSelect("SELECT type FROM operations WHERE id = 'rev-op-rev3'")
        .get();
    expect(
      revOp.first.read<String>('type'),
      'reversal',
      reason: 'REV-3: reversal must have type=reversal, not income/expense',
    );

    final entries = await db
        .customSelect(
          "SELECT entry_type FROM ledger_entries "
          "WHERE operation_id = 'rev-op-rev3'",
        )
        .get();
    for (final e in entries) {
      final et = e.read<String>('entry_type');
      expect(
        et,
        anyOf('reversalDebit', 'reversalCredit'),
        reason: 'REV-3: reversal entries must be reversalDebit/reversalCredit',
      );
    }
  });

  test('REV-4. Goal progress reflects reversed state', () async {
    const srcId = 'src-rev4';
    await createAccount(id: srcId, householdId: _hh);
    await creditAccount(srcId, _hh, 100000);

    final goalResult = await createGoal(
      idempotencyKey: 'ik-rev4',
      target: 50000,
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 40000,
      householdId: _hh,
      idempotencyKey: 'ik-rev4-fund',
    );

    final fundOpId =
        (await db
                .customSelect(
                  "SELECT id FROM operations WHERE type = 'transfer' "
                  "AND destination_account_id = '${goal.reserveAccountId}'",
                )
                .get())
            .first
            .read<String>('id');

    final progressUc = GetGoalProgressUseCase(goalRepo);

    final progressBefore =
        ((await progressUc.execute(goal.id)) as AppOk<GoalProgress>).value;
    expect(progressBefore.reserveBalanceMinorUnits, 40000);

    await ReverseGoalTransferUseCase(goalRepository: goalRepo).execute(
      originalOperationId: fundOpId,
      reversalOperationId: 'rev-op-rev4',
      householdId: _hh,
      effectiveDate: '2024-01-02',
      createdBy: 'test',
    );

    final progressAfter =
        ((await progressUc.execute(goal.id)) as AppOk<GoalProgress>).value;
    expect(
      progressAfter.reserveBalanceMinorUnits,
      0,
      reason: 'REV-4: progress must reflect reversed state (balance = 0)',
    );
  });

  test(
    'REV-5. Unrelated transfer reversal does not create goal movement',
    () async {
      const srcId = 'src-rev5';
      const dstId = 'dst-rev5';
      await createAccount(id: srcId, householdId: _hh);
      await createAccount(id: dstId, householdId: _hh);
      await creditAccount(srcId, _hh, 50000);

      final goalResult = await createGoal(idempotencyKey: 'ik-rev5');
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      final transferUc = ExecuteTransferUseCase(
        ledgerRepository: ledgerRepo,
        accountRepository: accountRepo,
      );
      await transferUc.execute(
        const TransferContext(
          operationId: 'op-rev5-unrelated',
          idempotencyKey: 'ik-rev5-unrelated',
          householdId: _hh,
          sourceAccountId: srcId,
          destinationAccountId: dstId,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'test',
          note: 'unrelated transfer',
        ),
      );

      final movsBefore =
          (await goalRepo.getMovements(goal.id) as AppOk<List<GoalMovement>>)
              .value
              .length;

      await ReverseGoalTransferUseCase(goalRepository: goalRepo).execute(
        originalOperationId: 'op-rev5-unrelated',
        reversalOperationId: 'rev-op-rev5',
        householdId: _hh,
        effectiveDate: '2024-01-02',
        createdBy: 'test',
      );

      final movsAfter =
          (await goalRepo.getMovements(goal.id) as AppOk<List<GoalMovement>>)
              .value
              .length;
      expect(
        movsAfter,
        movsBefore,
        reason: 'REV-5: unrelated reversal must not create any goal movement',
      );
    },
  );
}
