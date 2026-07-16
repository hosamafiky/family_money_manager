/// Reversal-reporting gate: period-activity model DB tests.
///
/// Tests:
/// 1. Expense Jan + reversal Jan → gross Jan expense = original; net = 0
/// 2. Expense Jan + reversal Feb → gross Jan = amount, Jan net = gross; Feb shows reversal
/// 3. Income Jan + reversal Feb → same pattern for income
/// 4. Both original and reversal visible in history query
/// 5. Backdated reversal appears in its effective period
/// 6. Same-timestamp ordering is deterministic
/// 7. Cumulative totals net correctly across two periods
/// 8. Adding operations in Feb doesn't change Jan totals
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/dashboard/data/drift_dashboard_query_repository.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-rev';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftDashboardQueryRepository dashRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    dashRepo = DriftDashboardQueryRepository(db);

    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'Rev HH', 'u1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<String> createAccount({
    String id = 'acc-rev-1',
    String type = 'personalCashWallet',
  }) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: _hh,
        name: 'Rev Account',
        type: FinancialAccountType.fromCode(type),
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
    return id;
  }

  Future<void> recordExpense(
    String accId,
    String opId,
    int amount,
    String date,
  ) async {
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: opId,
        householdId: _hh,
        sourceAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  Future<void> recordIncome(
    String accId,
    String opId,
    int amount,
    String date,
  ) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: opId,
        householdId: _hh,
        destinationAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  Future<void> reverseOp(
    String originalOpId,
    String reversalOpId,
    String date,
  ) async {
    await ledgerRepo.reverseOperation(
      ReverseOperationParams(
        reversalOperationId: reversalOpId,
        originalOperationId: originalOpId,
        householdId: _hh,
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  // Helper: build a period for a month
  DashboardPeriod jan = DashboardPeriod.custom(
    startDate: '2025-01-01',
    endDate: '2025-02-01',
  );
  DashboardPeriod feb = DashboardPeriod.custom(
    startDate: '2025-02-01',
    endDate: '2025-03-01',
  );

  group('Reversal reporting — period-activity model', () {
    test(
      '1. Expense Jan + reversal Jan → gross Jan expense = original; net = 0',
      () async {
        final acc = await createAccount();
        // Seed opening balance so account isn't overdrawn
        await recordIncome(acc, 'op-income-1', 10000, '2025-01-01');
        await recordExpense(acc, 'op-exp-jan', 5000, '2025-01-15');
        await reverseOp('op-exp-jan', 'op-rev-jan', '2025-01-20');

        final flows = await dashRepo.periodFlow(householdId: _hh, period: jan);
        expect(flows.length, 1);
        final flow = flows.first;
        expect(
          flow.grossExpenseMinorUnits,
          5000,
          reason: 'Gross expense includes reversed op',
        );
        expect(
          flow.expenseReversalMinorUnits,
          5000,
          reason: 'Reversal in same period cancels gross',
        );
        expect(
          flow.netExpenseMinorUnits,
          0,
          reason: 'Net = gross - reversal = 0',
        );
      },
    );

    test(
      '2. Expense Jan + reversal Feb → gross Jan = amount; Jan net = gross; Feb shows reversal',
      () async {
        final acc = await createAccount(id: 'acc-rev-2');
        await recordIncome(acc, 'op-income-2', 10000, '2025-01-01');
        await recordExpense(acc, 'op-exp-jan-2', 5000, '2025-01-10');
        await reverseOp('op-exp-jan-2', 'op-rev-feb-2', '2025-02-05');

        final janFlows = await dashRepo.periodFlow(
          householdId: _hh,
          period: jan,
        );
        expect(
          janFlows.first.grossExpenseMinorUnits,
          5000,
          reason: 'Jan gross expense includes the original op',
        );
        expect(
          janFlows.first.expenseReversalMinorUnits,
          0,
          reason: 'Reversal is in Feb, not Jan',
        );
        expect(
          janFlows.first.netExpenseMinorUnits,
          5000,
          reason: 'Net Jan = gross (no reversal in Jan)',
        );

        final febFlows = await dashRepo.periodFlow(
          householdId: _hh,
          period: feb,
        );
        // Feb has a reversal operation; net expense should reflect that
        expect(
          febFlows.first.expenseReversalMinorUnits,
          5000,
          reason: 'Feb has the reversal-of-expense effect',
        );
      },
    );

    test('3. Income Jan + reversal Feb → same pattern for income', () async {
      final acc = await createAccount(id: 'acc-rev-3');
      await recordIncome(acc, 'op-income-3', 8000, '2025-01-05');
      await reverseOp('op-income-3', 'op-rev-inc-feb', '2025-02-10');

      final janFlows = await dashRepo.periodFlow(householdId: _hh, period: jan);
      expect(
        janFlows.first.grossIncomeMinorUnits,
        8000,
        reason: 'Jan gross income includes original op',
      );
      expect(
        janFlows.first.incomeReversalMinorUnits,
        0,
        reason: 'Reversal is in Feb',
      );
      expect(janFlows.first.netIncomeMinorUnits, 8000);

      final febFlows = await dashRepo.periodFlow(householdId: _hh, period: feb);
      expect(
        febFlows.first.incomeReversalMinorUnits,
        8000,
        reason: 'Feb has the reversal-of-income effect',
      );
    });

    test('4. Both original and reversal visible in history query', () async {
      final acc = await createAccount(id: 'acc-rev-4');
      await recordIncome(acc, 'op-income-4', 10000, '2025-01-01');
      await recordExpense(acc, 'op-exp-4', 3000, '2025-01-12');
      await reverseOp('op-exp-4', 'op-rev-4', '2025-02-02');

      // Verify both exist in operations table
      final ops = await db
          .customSelect(
            "SELECT id, type FROM operations WHERE household_id = '$_hh' ORDER BY id",
          )
          .get();
      final ids = ops.map((r) => r.read<String>('id')).toList();
      expect(ids, contains('op-exp-4'));
      expect(ids, contains('op-rev-4'));

      // is_reversed should be true on original
      final original = await db
          .customSelect(
            "SELECT is_reversed FROM operations WHERE id = 'op-exp-4'",
          )
          .getSingle();
      expect(original.read<bool>('is_reversed'), isTrue);
    });

    test('5. Backdated reversal appears in its effective period', () async {
      final acc = await createAccount(id: 'acc-rev-5');
      await recordIncome(acc, 'op-income-5', 10000, '2025-01-01');
      await recordExpense(acc, 'op-exp-5', 4000, '2025-01-20');
      // Backdated reversal to Jan even though "recorded" later
      await reverseOp('op-exp-5', 'op-rev-back-5', '2025-01-25');

      final janFlows = await dashRepo.periodFlow(householdId: _hh, period: jan);
      expect(
        janFlows.first.expenseReversalMinorUnits,
        4000,
        reason: 'Backdated reversal to Jan appears in Jan',
      );

      final febFlows = await dashRepo.periodFlow(householdId: _hh, period: feb);
      // Feb should have no reversal from this op
      final febRev = febFlows.isEmpty
          ? 0
          : febFlows.first.expenseReversalMinorUnits;
      expect(febRev, 0, reason: 'Reversal effective Jan, not Feb');
    });

    test('6. Same-timestamp ordering is deterministic', () async {
      final acc = await createAccount(id: 'acc-rev-6');
      await recordIncome(acc, 'op-inc-6a', 10000, '2025-01-01');
      await recordIncome(acc, 'op-inc-6b', 5000, '2025-01-01');
      await recordExpense(acc, 'op-exp-6a', 2000, '2025-01-15');
      await recordExpense(acc, 'op-exp-6b', 3000, '2025-01-15');

      final flows1 = await dashRepo.periodFlow(householdId: _hh, period: jan);
      final flows2 = await dashRepo.periodFlow(householdId: _hh, period: jan);

      expect(
        flows1.first.grossIncomeMinorUnits,
        flows2.first.grossIncomeMinorUnits,
        reason: 'Identical queries return identical totals',
      );
      expect(
        flows1.first.grossExpenseMinorUnits,
        flows2.first.grossExpenseMinorUnits,
      );
      expect(flows1.first.grossIncomeMinorUnits, 15000);
      expect(flows1.first.grossExpenseMinorUnits, 5000);
    });

    test('7. Cumulative totals net correctly across two periods', () async {
      final acc = await createAccount(id: 'acc-rev-7');
      // Jan: income 10000, expense 4000 (reversed in Feb)
      await recordIncome(acc, 'op-inc-7', 10000, '2025-01-10');
      await recordExpense(acc, 'op-exp-7', 4000, '2025-01-20');
      await reverseOp('op-exp-7', 'op-rev-7', '2025-02-15');
      // Feb: income 6000
      await recordIncome(acc, 'op-inc-7b', 6000, '2025-02-05');

      final janFlows = await dashRepo.periodFlow(householdId: _hh, period: jan);
      final febFlows = await dashRepo.periodFlow(householdId: _hh, period: feb);

      // Jan: gross income 10000, gross expense 4000, no reversal in Jan
      expect(janFlows.first.grossIncomeMinorUnits, 10000);
      expect(janFlows.first.grossExpenseMinorUnits, 4000);
      expect(janFlows.first.expenseReversalMinorUnits, 0);

      // Feb: income 6000, reversal of 4000 expense
      expect(febFlows.first.grossIncomeMinorUnits, 6000);
      expect(febFlows.first.expenseReversalMinorUnits, 4000);

      // Combined net cash flow: (10000 - 4000) + (6000 + 4000) = 16000
      final janNet = janFlows.first.netCashFlowMinorUnits;
      final febNet = febFlows.first.netCashFlowMinorUnits;
      expect(janNet + febNet, 16000);
    });

    test('8. Adding operations in Feb does not change Jan totals', () async {
      final acc = await createAccount(id: 'acc-rev-8');
      await recordIncome(acc, 'op-inc-8', 5000, '2025-01-01');
      await recordExpense(acc, 'op-exp-8', 2000, '2025-01-15');

      final janBefore = await dashRepo.periodFlow(
        householdId: _hh,
        period: jan,
      );

      // Add Feb operations
      await recordIncome(acc, 'op-inc-8b', 3000, '2025-02-01');
      await recordExpense(acc, 'op-exp-8b', 1000, '2025-02-10');

      final janAfter = await dashRepo.periodFlow(householdId: _hh, period: jan);

      expect(
        janAfter.first.grossIncomeMinorUnits,
        janBefore.first.grossIncomeMinorUnits,
        reason: 'Feb additions do not change Jan income',
      );
      expect(
        janAfter.first.grossExpenseMinorUnits,
        janBefore.first.grossExpenseMinorUnits,
        reason: 'Feb additions do not change Jan expense',
      );
    });
  });
}
