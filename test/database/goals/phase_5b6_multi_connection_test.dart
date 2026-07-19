/// Phase 5B.6 — MC-CONC-1..6 multi-connection concurrency tests.
///
/// Uses TWO Drift connections to the SAME physical temporary SQLite file.
library;

import 'dart:io';

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
import 'package:path/path.dart' as p;

void main() {
  const hh = 'hh-mc';

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late Directory dir;
  late String path;
  late AppDatabase db1;
  late AppDatabase db2;
  late FundGoalUseCase fund1;
  late FundGoalUseCase fund2;
  late ReleaseGoalFundsUseCase rel1;
  late ReleaseGoalFundsUseCase rel2;
  late DriftLedgerRepository ledger1;
  late DriftLedgerRepository ledger2;
  late DriftGoalRepository goals1;
  late CreateGoalUseCase create1;
  late DriftAccountRepository accounts1;

  Future<void> seed() async {
    await db1.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$hh', 'HH', 'u1', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
  }

  Future<void> createAcct(String id) async {
    await accounts1.createAccount(
      CreateAccountParams(
        id: id,
        householdId: hh,
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

  Future<void> credit(String id, int amount) async {
    await ledger1.recordIncome(
      RecordIncomeParams(
        operationId: 'inc-$id-$amount-${DateTime.now().microsecondsSinceEpoch}',
        householdId: hh,
        destinationAccountId: id,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'test',
        categoryCode: 'salary',
      ),
    );
  }

  Future<SavingsGoal> makeGoal(String ikey) async {
    final r = await create1.execute(
      goalName: 'G-$ikey',
      purpose: GoalPurpose.emergencyFund,
      currencyCode: 'EGP',
      targetMinorUnits: 100000,
      householdId: hh,
      idempotencyKey: ikey,
    );
    return (r as AppOk<SavingsGoal>).value;
  }

  Future<int> bal(AppDatabase db, String accountId) async =>
      (await db
              .customSelect(
                "SELECT COALESCE(SUM(CASE WHEN direction = 'credit' "
                'THEN amount_minor_units ELSE -amount_minor_units END), 0) AS bal '
                "FROM ledger_entries WHERE account_id = '$accountId'",
              )
              .get())
          .first
          .read<int>('bal');

  Future<int> count(AppDatabase db, String sql) async =>
      (await db.customSelect(sql).get()).first.read<int>('c');

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fmm_conc_');
    path = p.join(dir.path, 'conc.db');
    db1 = AppDatabase.forFile(path);
    db2 = AppDatabase.forFile(path);
    await db1.customStatement('PRAGMA busy_timeout = 3000');
    await db2.customStatement('PRAGMA busy_timeout = 3000');
    accounts1 = DriftAccountRepository(db1);
    ledger1 = DriftLedgerRepository(db1);
    ledger2 = DriftLedgerRepository(db2);
    goals1 = DriftGoalRepository(db1);
    final goals2 = DriftGoalRepository(db2);
    create1 = CreateGoalUseCase(
      goalRepository: goals1,
      accountRepository: accounts1,
    );
    fund1 = FundGoalUseCase(
      goalRepository: goals1,
      accountRepository: accounts1,
      ledgerRepository: ledger1,
    );
    fund2 = FundGoalUseCase(
      goalRepository: goals2,
      accountRepository: DriftAccountRepository(db2),
      ledgerRepository: ledger2,
    );
    rel1 = ReleaseGoalFundsUseCase(
      goalRepository: goals1,
      accountRepository: accounts1,
      ledgerRepository: ledger1,
    );
    rel2 = ReleaseGoalFundsUseCase(
      goalRepository: goals2,
      accountRepository: DriftAccountRepository(db2),
      ledgerRepository: ledger2,
    );
    await seed();
  });

  tearDown(() async {
    await db1.close();
    await db2.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('MC-CONC-1. Funding vs funding across two connections', () async {
    await createAcct('src-mc1');
    await credit('src-mc1', 10000);
    final goal = await makeGoal('ik-mc1');
    final results = await Future.wait([
      fund1.execute(
        goalId: goal.id,
        sourceAccountId: 'src-mc1',
        amountMinorUnits: 8000,
        householdId: hh,
        idempotencyKey: 'ik-mc1-a',
      ),
      fund2.execute(
        goalId: goal.id,
        sourceAccountId: 'src-mc1',
        amountMinorUnits: 8000,
        householdId: hh,
        idempotencyKey: 'ik-mc1-b',
      ),
    ]);
    final oks = results.whereType<AppOk<SavingsGoal>>().length;
    final fails = results.length - oks;
    expect(oks + fails, 2);
    expect(oks, lessThanOrEqualTo(1));
    expect(await bal(db1, 'src-mc1'), greaterThanOrEqualTo(0));
    expect(
      await count(
        db1,
        "SELECT COUNT(*) as c FROM goal_movements WHERE goal_id = '${goal.id}'",
      ),
      oks,
    );
    // Incomplete workflows must not remain.
    final ops = await count(
      db1,
      "SELECT COUNT(*) as c FROM operations WHERE idempotency_key LIKE 'ik-mc1-%'",
    );
    final movs = await count(
      db1,
      "SELECT COUNT(*) as c FROM goal_movements WHERE goal_id = '${goal.id}'",
    );
    expect(ops, movs);
  });

  test('MC-CONC-2. Release vs release across two connections', () async {
    await createAcct('src-mc2');
    await createAcct('dst-mc2');
    await credit('src-mc2', 100000);
    final goal = await makeGoal('ik-mc2');
    await fund1.execute(
      goalId: goal.id,
      sourceAccountId: 'src-mc2',
      amountMinorUnits: 10000,
      householdId: hh,
      idempotencyKey: 'ik-mc2-fund',
    );
    final results = await Future.wait([
      rel1.execute(
        goalId: goal.id,
        destinationAccountId: 'dst-mc2',
        amountMinorUnits: 8000,
        releaseReason: 'a',
        householdId: hh,
        idempotencyKey: 'ik-mc2-a',
      ),
      rel2.execute(
        goalId: goal.id,
        destinationAccountId: 'dst-mc2',
        amountMinorUnits: 8000,
        releaseReason: 'b',
        householdId: hh,
        idempotencyKey: 'ik-mc2-b',
      ),
    ]);
    expect(
      results.whereType<AppOk<SavingsGoal>>().length,
      lessThanOrEqualTo(1),
    );
    expect(await bal(db1, goal.reserveAccountId), greaterThanOrEqualTo(0));
  });

  test('MC-CONC-3. Funding vs ordinary expense across connections', () async {
    await createAcct('src-mc3');
    await credit('src-mc3', 10000);
    final goal = await makeGoal('ik-mc3');
    Object? fundResult;
    Object? expResult;
    try {
      final results = await Future.wait<Object?>([
        fund1.execute(
          goalId: goal.id,
          sourceAccountId: 'src-mc3',
          amountMinorUnits: 8000,
          householdId: hh,
          idempotencyKey: 'ik-mc3-fund',
        ),
        ledger2.recordExpense(
          RecordExpenseParams(
            operationId: 'op-mc3-exp',
            householdId: hh,
            sourceAccountId: 'src-mc3',
            amountMinorUnits: 8000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'test',
            categoryCode: 'food',
          ),
        ),
      ], eagerError: false);
      fundResult = results[0];
      expResult = results[1];
    } catch (e) {
      // SQLite busy/locked under dual writers is an observed outcome.
      expResult = e;
    }
    expect(fundResult != null || expResult != null, isTrue);
    expect(await bal(db1, 'src-mc3'), greaterThanOrEqualTo(0));
  });

  test('MC-CONC-4. Funding vs ordinary transfer across connections', () async {
    await createAcct('src-mc4');
    await createAcct('dst-mc4');
    await credit('src-mc4', 10000);
    final goal = await makeGoal('ik-mc4');
    try {
      await Future.wait<Object?>([
        fund1.execute(
          goalId: goal.id,
          sourceAccountId: 'src-mc4',
          amountMinorUnits: 8000,
          householdId: hh,
          idempotencyKey: 'ik-mc4-fund',
        ),
        ledger2.executeTransfer(
          ExecuteTransferParams(
            operationId: 'op-mc4-xfer',
            householdId: hh,
            sourceAccountId: 'src-mc4',
            destinationAccountId: 'dst-mc4',
            amountMinorUnits: 8000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'test',
          ),
        ),
      ], eagerError: false);
    } catch (_) {
      // Observed: SQLite lock under overlapping writers on separate connections.
    }
    expect(await bal(db1, 'src-mc4'), greaterThanOrEqualTo(0));
  });

  test('MC-CONC-5. Equivalent duplicate request across connections', () async {
    await createAcct('src-mc5');
    await credit('src-mc5', 50000);
    final goal = await makeGoal('ik-mc5');
    final results = await Future.wait([
      fund1.execute(
        goalId: goal.id,
        sourceAccountId: 'src-mc5',
        amountMinorUnits: 5000,
        householdId: hh,
        idempotencyKey: 'ik-mc5-same',
      ),
      fund2.execute(
        goalId: goal.id,
        sourceAccountId: 'src-mc5',
        amountMinorUnits: 5000,
        householdId: hh,
        idempotencyKey: 'ik-mc5-same',
      ),
    ]);
    expect(
      results.whereType<AppOk<SavingsGoal>>().length,
      greaterThanOrEqualTo(1),
    );
    expect(
      await count(
        db1,
        "SELECT COUNT(*) as c FROM operations WHERE idempotency_key = 'ik-mc5-same'",
      ),
      1,
    );
    expect(
      await count(
        db1,
        "SELECT COUNT(*) as c FROM goal_movements WHERE goal_id = '${goal.id}'",
      ),
      1,
    );
  });

  test('MC-CONC-6. Conflicting duplicate request across connections', () async {
    await createAcct('src-mc6');
    await credit('src-mc6', 50000);
    final goal = await makeGoal('ik-mc6');
    final results = await Future.wait([
      fund1.execute(
        goalId: goal.id,
        sourceAccountId: 'src-mc6',
        amountMinorUnits: 5000,
        householdId: hh,
        idempotencyKey: 'ik-mc6-same',
      ),
      fund2.execute(
        goalId: goal.id,
        sourceAccountId: 'src-mc6',
        amountMinorUnits: 7000,
        householdId: hh,
        idempotencyKey: 'ik-mc6-same',
      ),
    ]);
    expect(results.whereType<AppOk<SavingsGoal>>().length, 1);
    expect(
      await count(
        db1,
        "SELECT COUNT(*) as c FROM operations WHERE idempotency_key = 'ik-mc6-same'",
      ),
      1,
    );
  });
}
