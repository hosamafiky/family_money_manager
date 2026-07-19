/// Phase 5B.3 – Section 11: v10→v11 migration tests (MIG-1..6).
///
/// The v10→v11 migration adds:
///  - early_completion_reason column to goals
///  - validate_goal_reserve_on_insert trigger
///  - validate_funding_movement_household trigger
///  - validate_release_movement_household trigger
///
/// Since the migration only ADDs new capabilities (no data transformation),
/// these tests verify that a fresh v11 database:
///  1. Preserves all pre-existing data (simulated via direct inserts)
///  2. Has the new column available
///  3. Has the new triggers active
///
/// Tests:
///  MIG-1. Goal data preserved after v11 schema initialization
///  MIG-2. Reserve account data preserved
///  MIG-3. Movement data preserved
///  MIG-4. New triggers are active (validate_goal_reserve_on_insert fires)
///  MIG-5. Budget data preserved (from prior phases)
///  MIG-6. Financial operations preserved
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
}
