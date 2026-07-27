/// Dashboard balance and query DB tests (Phase 4A).
///
/// Uses real AppDatabase.forTesting() + DriftDashboardQueryRepository.
///
/// Tests:
/// Group "spendable balances" (1–8)
/// Group "protected balances" (9–11)
/// Group "period income/expense" (12–19)
/// Group "expense scopes" (20–24)
/// Group "spouse wallet" (25–30)
/// Group "recent activity" (31–34)
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

const _hh = 'hh-dash';
const _hh2 = 'hh-dash-2';

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
      "VALUES ('$_hh', 'Test HH', 'u1', '2024-01-01', '2024-01-01')",
    );
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh2', 'Other HH', 'u2', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<String> createAccount({
    required String id,
    bool isSpendable = true,
    bool isProtected = false,
    bool isArchived = false,
    String type = 'personalCashWallet',
    String currency = 'EGP',
    String householdId = _hh,
  }) async {
    await accountRepo.createAccount(
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
    if (isArchived) {
      await accountRepo.archiveAccount(
        id: id,
        householdId: householdId,
        archivedAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
    }
    return id;
  }

  Future<void> recordIncome({
    required String accountId,
    required int amount,
    required String date,
    String opId = '',
    String currency = 'EGP',
    String householdId = _hh,
  }) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: opId.isEmpty ? 'op-inc-$date-$accountId' : opId,
        householdId: householdId,
        destinationAccountId: accountId,
        amountMinorUnits: amount,
        currencyCode: currency,
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  Future<void> recordExpense({
    required String accountId,
    required int amount,
    required String date,
    String opId = '',
    String currency = 'EGP',
    ExpenseScope? scope,
    String householdId = _hh,
  }) async {
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: opId.isEmpty ? 'op-exp-$date-$accountId' : opId,
        householdId: householdId,
        sourceAccountId: accountId,
        amountMinorUnits: amount,
        currencyCode: currency,
        effectiveDate: date,
        createdBy: 'test',
        scope: scope,
      ),
    );
  }

  Future<void> executeTransfer({
    required String sourceId,
    required String destId,
    required int amount,
    required String date,
    String opId = '',
    String householdId = _hh,
  }) async {
    await ledgerRepo.executeTransfer(
      ExecuteTransferParams(
        operationId: opId.isEmpty ? 'op-tr-$date-$sourceId' : opId,
        householdId: householdId,
        sourceAccountId: sourceId,
        destinationAccountId: destId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: date,
        createdBy: 'test',
      ),
    );
  }

  // ── Spendable balances ───────────────────────────────────────────────────────

  group('spendable balances', () {
    test('1. Active spendable account is included', () async {
      final acc = await createAccount(id: 'acc-sp-1');
      await recordIncome(accountId: acc, amount: 10000, date: '2025-03-01');

      final balances = await dashRepo.spendableBalances(householdId: _hh);
      expect(balances.length, 1);
      expect(balances.first.currencyCode, 'EGP');
      expect(balances.first.totalMinorUnits, 10000);
    });

    test('2. Archived account is excluded', () async {
      final acc = await createAccount(id: 'acc-sp-2');
      await recordIncome(accountId: acc, amount: 10000, date: '2025-03-01');
      await accountRepo.archiveAccount(
        id: acc,
        householdId: _hh,
        archivedAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      final balances = await dashRepo.spendableBalances(householdId: _hh);
      expect(balances.isEmpty, isTrue);
    });

    test('3. Protected account is excluded from spendable', () async {
      await createAccount(
        id: 'acc-sp-3',
        isSpendable: false,
        isProtected: true,
        type: 'childProtectedFund',
      );
      await recordIncome(
        accountId: 'acc-sp-3',
        amount: 5000,
        date: '2025-03-01',
      );

      final balances = await dashRepo.spendableBalances(householdId: _hh);
      expect(balances.isEmpty, isTrue);
    });

    test('4. Non-spendable account is excluded from spendable', () async {
      await createAccount(id: 'acc-sp-4', isSpendable: false);

      final balances = await dashRepo.spendableBalances(householdId: _hh);
      expect(balances.isEmpty, isTrue);
    });

    test('5. Multiple currencies remain separate', () async {
      await createAccount(id: 'acc-egp', currency: 'EGP');
      await createAccount(id: 'acc-usd', currency: 'USD');
      await recordIncome(
        accountId: 'acc-egp',
        amount: 10000,
        date: '2025-03-01',
        currency: 'EGP',
      );
      await recordIncome(
        accountId: 'acc-usd',
        amount: 500,
        date: '2025-03-01',
        currency: 'USD',
      );

      final balances = await dashRepo.spendableBalances(householdId: _hh);
      expect(balances.length, 2);
      final egp = balances.firstWhere((b) => b.currencyCode == 'EGP');
      final usd = balances.firstWhere((b) => b.currencyCode == 'USD');
      expect(egp.totalMinorUnits, 10000);
      expect(usd.totalMinorUnits, 500);
    });

    test(
      '6. Account with no ledger entries contributes 0 (no row returned)',
      () async {
        await createAccount(id: 'acc-sp-6');
        // No transactions — no ledger entries — no row in aggregation
        final balances = await dashRepo.spendableBalances(householdId: _hh);
        // An account with no entries returns no row (SUM over empty set = NULL)
        expect(balances.isEmpty, isTrue);
      },
    );

    test(
      '7. Profile isolation — other household accounts not included',
      () async {
        await createAccount(id: 'acc-sp-7-hh2', householdId: _hh2);
        await recordIncome(
          accountId: 'acc-sp-7-hh2',
          amount: 99999,
          date: '2025-03-01',
          householdId: _hh2,
        );

        final balances = await dashRepo.spendableBalances(householdId: _hh);
        expect(balances.isEmpty, isTrue);
      },
    );

    test('8. Overdraft debit rejected by prevent_negative_account_balance', () async {
      // Phase 6A.2: account balances cannot go negative at the DB boundary.
      await createAccount(id: 'acc-sp-8');
      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'ob-sp-8',
          householdId: _hh,
          accountId: 'acc-sp-8',
          amountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      await recordExpense(
        accountId: 'acc-sp-8',
        amount: 1000,
        date: '2025-02-01',
      );
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
        "VALUES ('op-extra-debit', '$_hh', 'adjustment', '2025-03-01', '2025-03-01T00:00:00Z', "
        "500, 'EGP', 'test', '2025-03-01T00:00:00Z', '2025-03-01T00:00:00Z')",
      );
      await expectLater(
        () => db.customStatement(
          "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
          "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
          "VALUES ('le-extra-debit', 'op-extra-debit', '$_hh', 'acc-sp-8', 'debit', "
          "500, 'EGP', 'adjustmentDebit', '2025-03-01', '2025-03-01T00:00:00Z', 'test')",
        ),
        throwsA(anything),
      );
      final balances = await dashRepo.spendableBalances(householdId: _hh);
      final egp = balances.firstWhere((b) => b.currencyCode == 'EGP');
      expect(egp.isNegative, isFalse);
      expect(egp.totalMinorUnits, 0);
    });
  });

  // ── Protected balances ───────────────────────────────────────────────────────

  group('protected balances', () {
    test('9. Protected account balance included', () async {
      await createAccount(
        id: 'acc-prot-9',
        isSpendable: false,
        isProtected: true,
        type: 'childProtectedFund',
      );
      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'ob-prot-9',
          householdId: _hh,
          accountId: 'acc-prot-9',
          amountMinorUnits: 50000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );

      final balances = await dashRepo.protectedBalances(
        householdId: _hh,
        todayLocal: '2025-06-01',
      );
      expect(balances.length, 1);
      expect(balances.first.totalMinorUnits, 50000);
    });

    test('10. Archived protected account excluded from totals', () async {
      await createAccount(
        id: 'acc-prot-10',
        isSpendable: false,
        isProtected: true,
        type: 'childProtectedFund',
      );
      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'ob-prot-10',
          householdId: _hh,
          accountId: 'acc-prot-10',
          amountMinorUnits: 50000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      await accountRepo.archiveAccount(
        id: 'acc-prot-10',
        householdId: _hh,
        archivedAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      final balances = await dashRepo.protectedBalances(
        householdId: _hh,
        todayLocal: '2025-06-01',
      );
      expect(balances.isEmpty, isTrue);
    });

    test('11. Child fund shown with protected flag', () async {
      await createAccount(
        id: 'acc-child-11',
        isSpendable: false,
        isProtected: true,
        type: 'childProtectedFund',
      );
      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'ob-child-11',
          householdId: _hh,
          accountId: 'acc-child-11',
          amountMinorUnits: 30000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );

      final balances = await dashRepo.protectedBalances(
        householdId: _hh,
        todayLocal: '2025-06-01',
      );
      expect(balances.any((b) => b.totalMinorUnits == 30000), isTrue);
    });
  });

  // ── Period income/expense ─────────────────────────────────────────────────────

  group('period income/expense', () {
    setUp(() async {
      await createAccount(id: 'acc-flow');
    });

    final period = DashboardPeriod.custom(
      startDate: '2025-03-01',
      endDate: '2025-04-01',
    );

    test('12. Ordinary income included', () async {
      await recordIncome(
        accountId: 'acc-flow',
        amount: 50000,
        date: '2025-03-15',
      );

      final flows = await dashRepo.periodFlow(householdId: _hh, period: period);
      expect(flows.length, 1);
      expect(flows.first.incomeMinorUnits, 50000);
    });

    test('13. Transfer excluded from income totals', () async {
      await createAccount(id: 'acc-flow-dest');
      await recordIncome(
        accountId: 'acc-flow',
        amount: 100000,
        date: '2025-02-01',
      );
      await executeTransfer(
        sourceId: 'acc-flow',
        destId: 'acc-flow-dest',
        amount: 10000,
        date: '2025-03-15',
      );

      final flows = await dashRepo.periodFlow(householdId: _hh, period: period);
      // Transfer should NOT appear in income or expense totals
      final incomeTotal = flows.fold<int>(0, (s, f) => s + f.incomeMinorUnits);
      expect(incomeTotal, 0);
    });

    test('14. Opening balance excluded', () async {
      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'ob-flow-14',
          householdId: _hh,
          accountId: 'acc-flow',
          amountMinorUnits: 100000,
          currencyCode: 'EGP',
          effectiveDate: '2025-03-10',
          createdBy: 'test',
        ),
      );

      final flows = await dashRepo.periodFlow(householdId: _hh, period: period);
      final incomeTotal = flows.fold<int>(0, (s, f) => s + f.incomeMinorUnits);
      expect(incomeTotal, 0);
    });

    test('15. Adjustment excluded', () async {
      await recordIncome(
        accountId: 'acc-flow',
        amount: 100000,
        date: '2025-01-01',
      );
      await ledgerRepo.recordAdjustment(
        RecordAdjustmentParams(
          operationId: 'adj-15',
          householdId: _hh,
          accountId: 'acc-flow',
          adjustmentAmountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2025-03-15',
          createdBy: 'test',
          reason: 'test adj',
        ),
      );

      final flows = await dashRepo.periodFlow(householdId: _hh, period: period);
      final incomeTotal = flows.fold<int>(0, (s, f) => s + f.incomeMinorUnits);
      expect(incomeTotal, 0);
    });

    test(
      '16. Fully reversed expense: gross includes it, net excludes it',
      () async {
        await recordIncome(
          accountId: 'acc-flow',
          amount: 50000,
          date: '2025-01-01',
        );
        await recordExpense(
          accountId: 'acc-flow',
          amount: 20000,
          date: '2025-03-10',
          opId: 'exp-16',
        );
        await ledgerRepo.reverseOperation(
          const ReverseOperationParams(
            reversalOperationId: 'rev-16',
            originalOperationId: 'exp-16',
            householdId: _hh,
            effectiveDate: '2025-03-11',
            createdBy: 'test',
          ),
        );

        final flows = await dashRepo.periodFlow(
          householdId: _hh,
          period: period,
        );
        final egp = flows.firstWhere((f) => f.currencyCode == 'EGP');
        // Gross expense includes the reversed operation
        expect(egp.expenseMinorUnits, 20000);
        // Net expense excludes the reversed operation
        expect(egp.netExpenseMinorUnits, 0);
      },
    );

    test('17. Reversal operation itself not counted as income', () async {
      await recordIncome(
        accountId: 'acc-flow',
        amount: 50000,
        date: '2025-01-01',
      );
      await recordExpense(
        accountId: 'acc-flow',
        amount: 5000,
        date: '2025-02-10',
        opId: 'exp-17',
      );
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'rev-17',
          originalOperationId: 'exp-17',
          householdId: _hh,
          effectiveDate: '2025-03-15',
          createdBy: 'test',
        ),
      );

      final flows = await dashRepo.periodFlow(householdId: _hh, period: period);
      final incomeTotal = flows.fold<int>(0, (s, f) => s + f.incomeMinorUnits);
      expect(incomeTotal, 0);
    });

    test('18. Backdated income appears in correct period', () async {
      await recordIncome(
        accountId: 'acc-flow',
        amount: 20000,
        date: '2025-02-28',
      );
      await recordIncome(
        accountId: 'acc-flow',
        amount: 30000,
        date: '2025-03-01',
        opId: 'inc-march',
      );

      final marchPeriod = DashboardPeriod.custom(
        startDate: '2025-03-01',
        endDate: '2025-04-01',
      );
      final febPeriod = DashboardPeriod.custom(
        startDate: '2025-02-01',
        endDate: '2025-03-01',
      );

      final marchFlows = await dashRepo.periodFlow(
        householdId: _hh,
        period: marchPeriod,
      );
      final febFlows = await dashRepo.periodFlow(
        householdId: _hh,
        period: febPeriod,
      );

      expect(marchFlows.first.incomeMinorUnits, 30000);
      expect(febFlows.first.incomeMinorUnits, 20000);
    });

    test('19. Currency grouping correct', () async {
      await createAccount(id: 'acc-usd-flow', currency: 'USD');
      await recordIncome(
        accountId: 'acc-flow',
        amount: 10000,
        date: '2025-03-10',
        currency: 'EGP',
      );
      await recordIncome(
        accountId: 'acc-usd-flow',
        amount: 200,
        date: '2025-03-10',
        currency: 'USD',
      );

      final flows = await dashRepo.periodFlow(householdId: _hh, period: period);
      expect(flows.length, 2);
      final egp = flows.firstWhere((f) => f.currencyCode == 'EGP');
      final usd = flows.firstWhere((f) => f.currencyCode == 'USD');
      expect(egp.incomeMinorUnits, 10000);
      expect(usd.incomeMinorUnits, 200);
    });
  });

  // ── Expense scopes ────────────────────────────────────────────────────────────

  group('expense scopes', () {
    final period = DashboardPeriod.custom(
      startDate: '2025-03-01',
      endDate: '2025-04-01',
    );

    setUp(() async {
      await createAccount(id: 'acc-scope');
      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'ob-scope',
          householdId: _hh,
          accountId: 'acc-scope',
          amountMinorUnits: 200000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
    });

    test('20. Personal scope expense counted in personal total', () async {
      await recordExpense(
        accountId: 'acc-scope',
        amount: 1000,
        date: '2025-03-10',
        scope: ExpenseScope.personal,
        opId: 'exp-scope-20',
      );

      final scopes = await dashRepo.expensesByScope(
        householdId: _hh,
        period: period,
      );
      final personal = scopes.where((s) => s.scope == ExpenseScope.personal);
      expect(personal.isNotEmpty, isTrue);
      expect(personal.first.totalMinorUnits, 1000);
    });

    test('21. Child scope expense counted in child total', () async {
      await recordExpense(
        accountId: 'acc-scope',
        amount: 2000,
        date: '2025-03-10',
        scope: ExpenseScope.child,
        opId: 'exp-scope-21',
      );

      final scopes = await dashRepo.expensesByScope(
        householdId: _hh,
        period: period,
      );
      final child = scopes.where((s) => s.scope == ExpenseScope.child);
      expect(child.isNotEmpty, isTrue);
      expect(child.first.totalMinorUnits, 2000);
    });

    test('22. Spouse scope expense counted in spouse total', () async {
      await recordExpense(
        accountId: 'acc-scope',
        amount: 3000,
        date: '2025-03-10',
        scope: ExpenseScope.spouse,
        opId: 'exp-scope-22',
      );

      final scopes = await dashRepo.expensesByScope(
        householdId: _hh,
        period: period,
      );
      final spouse = scopes.where((s) => s.scope == ExpenseScope.spouse);
      expect(spouse.isNotEmpty, isTrue);
      expect(spouse.first.totalMinorUnits, 3000);
    });

    test('23. Household scope expense counted in household total', () async {
      await recordExpense(
        accountId: 'acc-scope',
        amount: 4000,
        date: '2025-03-10',
        scope: ExpenseScope.household,
        opId: 'exp-scope-23',
      );

      final scopes = await dashRepo.expensesByScope(
        householdId: _hh,
        period: period,
      );
      final household = scopes.where((s) => s.scope == ExpenseScope.household);
      expect(household.isNotEmpty, isTrue);
      expect(household.first.totalMinorUnits, 4000);
    });

    test('24. Reversed expense excluded from scope totals', () async {
      await recordExpense(
        accountId: 'acc-scope',
        amount: 5000,
        date: '2025-03-10',
        scope: ExpenseScope.personal,
        opId: 'exp-scope-24',
      );
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'rev-scope-24',
          originalOperationId: 'exp-scope-24',
          householdId: _hh,
          effectiveDate: '2025-03-11',
          createdBy: 'test',
        ),
      );

      final scopes = await dashRepo.expensesByScope(
        householdId: _hh,
        period: period,
      );
      // is_reversed = 1 → excluded from scope totals
      final personal = scopes.where((s) => s.scope == ExpenseScope.personal);
      expect(personal.isEmpty, isTrue);
    });
  });

  // ── Spouse wallet ─────────────────────────────────────────────────────────────

  group('spouse wallet', () {
    final period = DashboardPeriod.custom(
      startDate: '2025-03-01',
      endDate: '2025-04-01',
    );

    Future<String> createSourceAndWallet() async {
      await createAccount(id: 'acc-src');
      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'ob-src',
          householdId: _hh,
          accountId: 'acc-src',
          amountMinorUnits: 500000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      await createAccount(id: 'acc-wallet', type: 'spouseCashWallet');
      return 'acc-wallet';
    }

    test('25. Transfer in (funding) counted correctly', () async {
      final walletId = await createSourceAndWallet();
      await executeTransfer(
        sourceId: 'acc-src',
        destId: walletId,
        amount: 10000,
        date: '2025-03-10',
      );

      final summaries = await dashRepo.spouseWalletSummaries(
        householdId: _hh,
        period: period,
      );
      expect(summaries.length, 1);
      expect(summaries.first.periodFundedMinorUnits, 10000);
    });

    test('26. Expense from wallet counted in spent', () async {
      final walletId = await createSourceAndWallet();
      await executeTransfer(
        sourceId: 'acc-src',
        destId: walletId,
        amount: 50000,
        date: '2025-01-01',
      );
      await recordExpense(
        accountId: walletId,
        amount: 15000,
        date: '2025-03-10',
        opId: 'exp-wallet-26',
      );

      final summaries = await dashRepo.spouseWalletSummaries(
        householdId: _hh,
        period: period,
      );
      expect(summaries.first.periodSpentMinorUnits, 15000);
    });

    test('27. Transfer out (return) counted correctly', () async {
      final walletId = await createSourceAndWallet();
      await executeTransfer(
        sourceId: 'acc-src',
        destId: walletId,
        amount: 50000,
        date: '2025-01-01',
      );
      await executeTransfer(
        sourceId: walletId,
        destId: 'acc-src',
        amount: 5000,
        date: '2025-03-15',
      );

      final summaries = await dashRepo.spouseWalletSummaries(
        householdId: _hh,
        period: period,
      );
      expect(summaries.first.periodReturnedMinorUnits, 5000);
    });

    test('28. Current balance reflects all-time activity', () async {
      final walletId = await createSourceAndWallet();
      await executeTransfer(
        sourceId: 'acc-src',
        destId: walletId,
        amount: 30000,
        date: '2025-01-01',
        opId: 'tr-28a',
      );
      await recordExpense(
        accountId: walletId,
        amount: 5000,
        date: '2025-02-01',
        opId: 'exp-28',
      );

      final summaries = await dashRepo.spouseWalletSummaries(
        householdId: _hh,
        period: period,
      );
      expect(summaries.first.currentBalanceMinorUnits, 25000);
    });

    test('29. Period filter applies to funding/spending/returning', () async {
      final walletId = await createSourceAndWallet();
      // Transfer outside period (February)
      await executeTransfer(
        sourceId: 'acc-src',
        destId: walletId,
        amount: 20000,
        date: '2025-02-15',
        opId: 'tr-29-feb',
      );
      // Transfer inside period (March)
      await executeTransfer(
        sourceId: 'acc-src',
        destId: walletId,
        amount: 10000,
        date: '2025-03-05',
        opId: 'tr-29-mar',
      );

      final summaries = await dashRepo.spouseWalletSummaries(
        householdId: _hh,
        period: period,
      );
      // Only March funding counted in period
      expect(summaries.first.periodFundedMinorUnits, 10000);
    });

    test('30. Multiple spouse wallets returned separately', () async {
      await createAccount(id: 'acc-src-30');
      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'ob-src-30',
          householdId: _hh,
          accountId: 'acc-src-30',
          amountMinorUnits: 500000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      await createAccount(id: 'wallet-30a', type: 'spouseCashWallet');
      await createAccount(id: 'wallet-30b', type: 'spouseCashWallet');

      final summaries = await dashRepo.spouseWalletSummaries(
        householdId: _hh,
        period: period,
      );
      expect(summaries.length, 2);
      final ids = summaries.map((s) => s.accountId).toSet();
      expect(ids.contains('wallet-30a'), isTrue);
      expect(ids.contains('wallet-30b'), isTrue);
    });
  });

  // ── Recent activity ────────────────────────────────────────────────────────────

  group('recent activity', () {
    setUp(() async {
      await createAccount(id: 'acc-recent');
      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'ob-recent',
          householdId: _hh,
          accountId: 'acc-recent',
          amountMinorUnits: 500000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
    });

    test('31. Returns last N items ordered by date DESC', () async {
      await recordIncome(
        accountId: 'acc-recent',
        amount: 1000,
        date: '2025-01-10',
        opId: 'inc-old',
      );
      await recordIncome(
        accountId: 'acc-recent',
        amount: 2000,
        date: '2025-03-20',
        opId: 'inc-new',
      );

      final activities = await dashRepo.recentActivity(
        householdId: _hh,
        limit: 5,
      );
      // Most recent first
      expect(activities.first.operation.id, 'inc-new');
    });

    test('32. Reversal item visible (not hidden)', () async {
      await recordExpense(
        accountId: 'acc-recent',
        amount: 5000,
        date: '2025-02-01',
        opId: 'exp-rev-32',
      );
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'rev-32',
          originalOperationId: 'exp-rev-32',
          householdId: _hh,
          effectiveDate: '2025-02-02',
          createdBy: 'test',
        ),
      );

      final activities = await dashRepo.recentActivity(
        householdId: _hh,
        limit: 20,
      );
      final ids = activities.map((a) => a.operation.id).toList();
      expect(ids.contains('rev-32'), isTrue);
    });

    test('33. Income, expense, and transfer all returned', () async {
      await createAccount(id: 'acc-recent-dest');
      await recordIncome(
        accountId: 'acc-recent',
        amount: 10000,
        date: '2025-03-01',
        opId: 'inc-33',
      );
      await recordExpense(
        accountId: 'acc-recent',
        amount: 1000,
        date: '2025-03-02',
        opId: 'exp-33',
      );
      await executeTransfer(
        sourceId: 'acc-recent',
        destId: 'acc-recent-dest',
        amount: 500,
        date: '2025-03-03',
        opId: 'tr-33',
      );

      final activities = await dashRepo.recentActivity(
        householdId: _hh,
        limit: 20,
      );
      final types = activities.map((a) => a.operation.type.code).toSet();
      expect(types.contains('income'), isTrue);
      expect(types.contains('expense'), isTrue);
      expect(types.contains('transfer'), isTrue);
    });

    test('34. Household isolation — other household not included', () async {
      await createAccount(id: 'acc-recent-hh2', householdId: _hh2);
      await recordIncome(
        accountId: 'acc-recent-hh2',
        amount: 99999,
        date: '2025-03-15',
        householdId: _hh2,
        opId: 'inc-hh2-34',
      );

      final activities = await dashRepo.recentActivity(householdId: _hh);
      final ids = activities.map((a) => a.operation.id).toSet();
      expect(ids.contains('inc-hh2-34'), isFalse);
    });
  });
}
