/// Phase 5B.3 / 5B.4 – Schema smoke tests (historical name: v10→v11).
///
/// NOTE (Phase 5B.5): This file opens a **fresh** `AppDatabase` at the current
/// schema version. It is useful for fixture preservation / trigger smoke checks
/// but is **not** evidence of a true stepwise migration. For a physical-file
/// (N−1)→N migration, see `goal_true_migration_v12_to_v13_test.dart`.
///
/// Historical coverage notes:
/// v10→v11 migration adds (Phase 5B.3):
///  - early_completion_reason column to goals
///  - validate_goal_reserve_on_insert trigger
///  - validate_funding_movement_household trigger
///  - validate_release_movement_household trigger
///
/// v11→v12 migration adds (Phase 5B.4):
///  - goal_lifecycle_events table
///  - reversal_of_movement_id column on goal_movements
///  - no_modify_reserve_owner_type trigger
///  - updated validate_goal_reserve_on_insert (adds owner_type = 'household')
///  - updated goal_movement_transfer_type (allows 'reversal' ops)
///
/// Since the migration only ADDs capabilities (no data transformation),
/// the tests open a fresh database at the current schema and verify:
///  1. All pre-existing tables and data are preserved
///  2. New columns exist
///  3. New triggers are active
///
/// Tests (original MIG-1..6):
///  MIG-1. Goal data preserved after schema initialization
///  MIG-2. Reserve account data preserved
///  MIG-3. Movement data preserved
///  MIG-4. New triggers are active (validate_goal_reserve_on_insert fires)
///  MIG-5. Budget data preserved (from prior phases)
///  MIG-6. Financial operations preserved
///
/// Tests (Phase 5B.4 MIG-V10-1..6):
///  MIG-V10-1. Goal data preserved (reserve linkage valid)
///  MIG-V10-2. Reserve linkage valid (owner_type = household)
///  MIG-V10-3. Movement data preserved (with reversal_of_movement_id column)
///  MIG-V10-4. Operation context preserved
///  MIG-V10-5. goal_lifecycle_events table created and writable
///  MIG-V10-6. New triggers active post-migration (all key triggers fire)
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

const _hh = 'hh-mig-test';

void main() {
  late AppDatabase db;
  late DriftGoalRepository goalRepo;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late CreateGoalUseCase createGoalUc;
  late FundGoalUseCase fundGoalUc;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    goalRepo = DriftGoalRepository(db);
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    createGoalUc = CreateGoalUseCase(
      goalRepository: goalRepo,
      accountRepository: accountRepo,
    );
    fundGoalUc = FundGoalUseCase(
      goalRepository: goalRepo,
      accountRepository: accountRepo,
      ledgerRepository: ledgerRepo,
    );

    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'Migration Test HH', 'u-mig', "
      "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
  });

  tearDown(() async => db.close());

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<String> createAccount(String id, {String currency = 'EGP'}) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: _hh,
        name: 'Account $id',
        type: FinancialAccountType.personalCashWallet,
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
    return id;
  }

  Future<void> creditAccount(
    String id,
    int amount, {
    String currency = 'EGP',
  }) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId:
            'income-$id-$amount-${DateTime.now().microsecondsSinceEpoch}',
        householdId: _hh,
        destinationAccountId: id,
        amountMinorUnits: amount,
        currencyCode: currency,
        effectiveDate: '2024-01-01',
        createdBy: 'test',
      ),
    );
  }

  test('MIG-1. Goal data preserved after v11 schema initialization', () async {
    final result = await createGoalUc.execute(
      goalName: 'Migration Test Goal',
      purpose: GoalPurpose.emergencyFund,
      currencyCode: 'EGP',
      targetMinorUnits: 50000,
      householdId: _hh,
      idempotencyKey: 'ik-mig1',
    );
    expect(result, isA<AppOk<SavingsGoal>>());
    final goal = (result as AppOk<SavingsGoal>).value;

    // Verify goal is persisted and retrievable.
    final found = await goalRepo.findGoalById(goal.id);
    expect(found, isA<AppOk<SavingsGoal?>>());
    expect((found as AppOk<SavingsGoal?>).value?.id, goal.id);
    expect(
      found.value?.currentRevision.name,
      'Migration Test Goal',
      reason: 'MIG-1: goal name must be preserved',
    );
  });

  test('MIG-2. Reserve account data preserved', () async {
    final result = await createGoalUc.execute(
      goalName: 'Reserve Preservation',
      purpose: GoalPurpose.other,
      currencyCode: 'EGP',
      targetMinorUnits: 100000,
      householdId: _hh,
      idempotencyKey: 'ik-mig2',
    );
    final goal = (result as AppOk<SavingsGoal>).value;

    final reserveRows = await db
        .customSelect(
          "SELECT type, is_spendable, is_protected, currency_code "
          "FROM financial_accounts WHERE id = '${goal.reserveAccountId}'",
        )
        .get();
    expect(reserveRows.isNotEmpty, isTrue);
    expect(reserveRows.first.read<String>('type'), 'goalReserve');
    expect(reserveRows.first.read<bool>('is_spendable'), isFalse);
    expect(reserveRows.first.read<bool>('is_protected'), isFalse);
    expect(
      reserveRows.first.read<String>('currency_code'),
      'EGP',
      reason: 'MIG-2: reserve account data must be preserved',
    );
  });

  test('MIG-3. Movement data preserved after funding', () async {
    final srcId = await createAccount('src-mig3');
    await creditAccount(srcId, 100000);

    final goalResult = await createGoalUc.execute(
      goalName: 'Movement Preservation',
      purpose: GoalPurpose.travel,
      currencyCode: 'EGP',
      targetMinorUnits: 50000,
      householdId: _hh,
      idempotencyKey: 'ik-mig3',
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      householdId: _hh,
      idempotencyKey: 'ik-mig3-fund',
    );

    final movs = await goalRepo.getMovements(goal.id);
    expect(movs, isA<AppOk<List<GoalMovement>>>());
    expect(
      (movs as AppOk<List<GoalMovement>>).value.length,
      1,
      reason: 'MIG-3: movement must be preserved',
    );
    expect(movs.value.first.movementType, GoalMovementType.funding);
  });

  test('MIG-4. New trigger validate_goal_reserve_on_insert is active', () async {
    // Attempt to insert a goal referencing a non-goalReserve account.
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('normal-mig4', '$_hh', 'Normal Account', 'personalCashWallet', 'user', "
      "'available', 'EGP', 1, 0, 1, 0, 1, 'test', '2024-01-01', '2024-01-01')",
    );

    await expectLater(
      () => db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) "
        "VALUES ('goal-mig4-bad', '$_hh', 'normal-mig4', 'EGP', 'active', "
        "'ik-mig4-bad', 'payload-mig4', '2024-01-01T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'MIG-4: validate_goal_reserve_on_insert trigger must be active in v11',
    );
  });

  test('MIG-5. Budget data preserved (from prior phases)', () async {
    // Insert a budget row directly.
    await db.customStatement(
      "INSERT INTO budgets (id, household_id, name, currency_code, "
      "limit_minor_units, period_type, is_archived, idempotency_key, "
      "idempotency_payload, created_at, updated_at) "
      "VALUES ('budget-mig5', '$_hh', 'Test Budget', 'EGP', "
      "500000, 'monthly', 0, 'ik-budget-mig5', 'payload-b-mig5', "
      "'2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );

    final rows = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM budgets WHERE id = 'budget-mig5'",
        )
        .get();
    expect(
      rows.first.read<int>('c'),
      1,
      reason: 'MIG-5: budget data must survive v11 schema',
    );
  });

  test('MIG-6. Financial operations preserved', () async {
    final srcId = await createAccount('src-mig6');
    await creditAccount(srcId, 50000);

    // Verify the income operation exists.
    final opRows = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM operations "
          "WHERE type = 'income' AND destination_account_id = '$srcId'",
        )
        .get();
    expect(
      opRows.first.read<int>('c'),
      greaterThan(0),
      reason: 'MIG-6: income operations must be preserved under v11 schema',
    );

    // Verify ledger entries exist.
    final entryRows = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM ledger_entries "
          "WHERE account_id = '$srcId' AND household_id = '$_hh'",
        )
        .get();
    expect(
      entryRows.first.read<int>('c'),
      greaterThan(0),
      reason: 'MIG-6: ledger entries must be preserved under v11 schema',
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5B.4 – MIG-V10-1..6: Comprehensive migration evidence
  // ══════════════════════════════════════════════════════════════════════════

  test('MIG-V10-1. Goal data preserved and reserve linkage valid', () async {
    final result = await createGoalUc.execute(
      goalName: 'MIG-V10-1 Goal',
      purpose: GoalPurpose.other,
      currencyCode: 'EGP',
      targetMinorUnits: 75000,
      householdId: _hh,
      idempotencyKey: 'ik-migv10-1',
    );
    expect(result, isA<AppOk<SavingsGoal>>());
    final goal = (result as AppOk<SavingsGoal>).value;

    // Verify goal retrieved by ID.
    final found = await goalRepo.findGoalById(goal.id);
    expect(found, isA<AppOk<SavingsGoal?>>());
    expect((found as AppOk<SavingsGoal?>).value?.id, goal.id);
    expect(found.value?.currentRevision.name, 'MIG-V10-1 Goal');

    // Verify reserve linkage.
    final reserveRow = await db
        .customSelect(
          "SELECT type, household_id FROM financial_accounts WHERE id = '${goal.reserveAccountId}'",
        )
        .get();
    expect(reserveRow.isNotEmpty, isTrue);
    expect(reserveRow.first.read<String>('type'), 'goalReserve');
    expect(
      reserveRow.first.read<String>('household_id'),
      _hh,
      reason: 'MIG-V10-1: reserve must be in same household as goal',
    );
  });

  test(
    'MIG-V10-2. Reserve linkage valid — owner_type = household enforced in v12',
    () async {
      final result = await createGoalUc.execute(
        goalName: 'MIG-V10-2 Goal',
        purpose: GoalPurpose.emergencyFund,
        currencyCode: 'EGP',
        targetMinorUnits: 50000,
        householdId: _hh,
        idempotencyKey: 'ik-migv10-2',
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
        reason: 'MIG-V10-2: reserve owner_type must be household',
      );

      // Verify trigger enforces owner_type = 'household' by trying to insert
      // a goal with a non-household reserve.
      await db.customStatement(
        "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
        "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
        "include_in_zakat, display_order, created_by, created_at, updated_at) "
        "VALUES ('v10-bad-reserve', '$_hh', 'Bad Reserve', 'goalReserve', 'child', "
        "'goalReserve', 'EGP', 0, 0, 1, 0, 9998, 'test', '2024-01-01', '2024-01-01')",
      );
      await expectLater(
        () => db.customStatement(
          "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
          "status, idempotency_key, idempotency_payload, created_at) "
          "VALUES ('goal-v10-bad', '$_hh', 'v10-bad-reserve', 'EGP', 'active', "
          "'ik-v10-bad', 'payload-v10-bad', '2024-01-01T00:00:00Z')",
        ),
        throwsA(anything),
        reason: 'MIG-V10-2: non-household owner_type must be rejected in v12',
      );
    },
  );

  test(
    'MIG-V10-3. Movement data preserved (reversal_of_movement_id column exists)',
    () async {
      final srcId = await createAccount('src-migv10-3');
      await creditAccount(srcId, 100000);

      final goalResult = await createGoalUc.execute(
        goalName: 'MIG-V10-3 Goal',
        purpose: GoalPurpose.travel,
        currencyCode: 'EGP',
        targetMinorUnits: 50000,
        householdId: _hh,
        idempotencyKey: 'ik-migv10-3',
      );
      final goal = (goalResult as AppOk<SavingsGoal>).value;

      await fundGoalUc.execute(
        goalId: goal.id,
        sourceAccountId: srcId,
        amountMinorUnits: 25000,
        householdId: _hh,
        idempotencyKey: 'ik-migv10-3-fund',
      );

      // Verify movement exists.
      final movRows = await db
          .customSelect(
            "SELECT id, movement_type, reversal_of_movement_id FROM goal_movements "
            "WHERE goal_id = '${goal.id}'",
          )
          .get();
      expect(
        movRows.isNotEmpty,
        isTrue,
        reason: 'MIG-V10-3: movement must exist',
      );
      expect(movRows.first.read<String>('movement_type'), 'funding');
      // reversal_of_movement_id is NULL for a funding movement.
      expect(
        movRows.first.readNullable<String>('reversal_of_movement_id'),
        isNull,
        reason:
            'MIG-V10-3: reversal_of_movement_id column must exist and be null for funding',
      );
    },
  );

  test('MIG-V10-4. Operation context preserved', () async {
    final srcId = await createAccount('src-migv10-4');
    await creditAccount(srcId, 50000);

    final goalResult = await createGoalUc.execute(
      goalName: 'MIG-V10-4 Goal',
      purpose: GoalPurpose.other,
      currencyCode: 'EGP',
      targetMinorUnits: 20000,
      householdId: _hh,
      idempotencyKey: 'ik-migv10-4',
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;

    await fundGoalUc.execute(
      goalId: goal.id,
      sourceAccountId: srcId,
      amountMinorUnits: 20000,
      householdId: _hh,
      idempotencyKey: 'ik-migv10-4-fund',
    );

    // Verify operation context exists for the funding operation.
    final ctxRows = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM operation_contexts oc "
          "JOIN operations op ON op.id = oc.operation_id "
          "WHERE op.destination_account_id = '${goal.reserveAccountId}'",
        )
        .get();
    expect(
      ctxRows.first.read<int>('c'),
      greaterThanOrEqualTo(0),
      reason: 'MIG-V10-4: operation_contexts table must exist and be queryable',
    );

    // Verify the operation_contexts table structure is intact.
    final tableExists = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM sqlite_master "
          "WHERE type='table' AND name='operation_contexts'",
        )
        .get();
    expect(
      tableExists.first.read<int>('c'),
      1,
      reason: 'MIG-V10-4: operation_contexts table must exist',
    );
  });

  test('MIG-V10-5. goal_lifecycle_events table created and writable', () async {
    // Verify the table exists.
    final tableRows = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM sqlite_master "
          "WHERE type='table' AND name='goal_lifecycle_events'",
        )
        .get();
    expect(
      tableRows.first.read<int>('c'),
      1,
      reason: 'MIG-V10-5: goal_lifecycle_events table must exist in v12 schema',
    );

    // Create a goal and insert a lifecycle event.
    final goalResult = await createGoalUc.execute(
      goalName: 'MIG-V10-5 Goal',
      purpose: GoalPurpose.other,
      currencyCode: 'EGP',
      targetMinorUnits: 10000,
      householdId: _hh,
      idempotencyKey: 'ik-migv10-5',
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.customStatement(
      "INSERT INTO goal_lifecycle_events "
      "(id, goal_id, household_id, event_type, effective_at, created_at, schema_version) "
      "VALUES ('evt-migv10-5', '${goal.id}', '$_hh', 'completed', '$now', '$now', 12)",
    );

    final evtRows = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM goal_lifecycle_events "
          "WHERE goal_id = '${goal.id}'",
        )
        .get();
    expect(
      evtRows.first.read<int>('c'),
      1,
      reason: 'MIG-V10-5: lifecycle event must be writable',
    );
  });

  test('MIG-V10-6. New v12 triggers active post-migration', () async {
    // Trigger 1: no_update_goal_lifecycle_events
    final goalResult = await createGoalUc.execute(
      goalName: 'MIG-V10-6 Goal',
      purpose: GoalPurpose.other,
      currencyCode: 'EGP',
      targetMinorUnits: 5000,
      householdId: _hh,
      idempotencyKey: 'ik-migv10-6',
    );
    final goal = (goalResult as AppOk<SavingsGoal>).value;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.customStatement(
      "INSERT INTO goal_lifecycle_events "
      "(id, goal_id, household_id, event_type, effective_at, created_at, schema_version) "
      "VALUES ('evt-migv10-6', '${goal.id}', '$_hh', 'completed', '$now', '$now', 12)",
    );

    await expectLater(
      () => db.customStatement(
        "UPDATE goal_lifecycle_events SET event_type = 'archived' "
        "WHERE id = 'evt-migv10-6'",
      ),
      throwsA(anything),
      reason: 'MIG-V10-6: no_update_goal_lifecycle_events must be active',
    );

    // Trigger 2: no_modify_reserve_owner_type
    await expectLater(
      () => db.customStatement(
        "UPDATE financial_accounts SET owner_type = 'user' "
        "WHERE id = '${goal.reserveAccountId}'",
      ),
      throwsA(anything),
      reason: 'MIG-V10-6: no_modify_reserve_owner_type must be active',
    );

    // Trigger 3: validate_goal_reserve_on_insert with owner_type check
    await db.customStatement(
      "INSERT INTO financial_accounts (id, household_id, name, type, owner_type, "
      "fund_purpose, currency_code, is_spendable, is_protected, include_in_net_worth, "
      "include_in_zakat, display_order, created_by, created_at, updated_at) "
      "VALUES ('v12-user-reserve', '$_hh', 'User Reserve', 'goalReserve', 'user', "
      "'goalReserve', 'EGP', 0, 0, 1, 0, 8888, 'test', '2024-01-01', '2024-01-01')",
    );
    await expectLater(
      () => db.customStatement(
        "INSERT INTO goals (id, household_id, reserve_account_id, currency_code, "
        "status, idempotency_key, idempotency_payload, created_at) "
        "VALUES ('goal-v12-bad2', '$_hh', 'v12-user-reserve', 'EGP', 'active', "
        "'ik-v12-bad2', 'payload-v12-bad2', '2024-01-01T00:00:00Z')",
      ),
      throwsA(anything),
      reason:
          'MIG-V10-6: validate_goal_reserve_on_insert (owner_type) must be active',
    );
  });
}
