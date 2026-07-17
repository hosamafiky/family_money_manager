/// Transaction history query tests (Phase 3B §14).
///
/// Verifies the DriftTransactionQueryRepository filters and ordering:
/// - Date range filter (fromDate, toDate).
/// - Account filter.
/// - Operation type filter (income / expense / transfer).
/// - Transfers excluded from income / expense totals.
/// - Reversed indicator visible on reversed operations.
/// - Original and reversal both visible in unfiltered list.
/// - Opening balance distinct from income.
/// - Deterministic ordering (DESC by effective_date, recorded_at, id).
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/data/drift_transaction_query_repository.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftTransactionQueryRepository queryRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    queryRepo = DriftTransactionQueryRepository(db);
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('hh-hist', 'History HH', 'user-1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<String> createAccount({required String suffix}) async {
    final id = 'acc-hist-$suffix';
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: 'hh-hist',
        name: 'Account $suffix',
        type: FinancialAccountType.personalCashWallet,
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'user-1',
      ),
    );
    return id;
  }

  group('Transaction history queries', () {
    test('date range filter — fromDate/toDate restricts results', () async {
      final acc = await createAccount(suffix: 'dr1');

      // Three income operations on different dates.
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-jan',
          householdId: 'hh-hist',
          destinationAccountId: acc,
          amountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-10',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-mar',
          householdId: 'hh-hist',
          destinationAccountId: acc,
          amountMinorUnits: 2000,
          currencyCode: 'EGP',
          effectiveDate: '2024-03-15',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-dec',
          householdId: 'hh-hist',
          destinationAccountId: acc,
          amountMinorUnits: 3000,
          currencyCode: 'EGP',
          effectiveDate: '2024-12-01',
          createdBy: 'user-1',
        ),
      );

      // Query for February–April only.
      final results = await queryRepo.recentOperations(
        householdId: 'hh-hist',
        filter: const TransactionFilter(
          fromDate: '2024-02-01',
          toDate: '2024-04-30',
          pageSize: 100,
        ),
      );

      final ids = results.map((t) => t.operation.id).toSet();
      expect(ids, contains('op-hist-mar'));
      expect(ids, isNot(contains('op-hist-jan')));
      expect(ids, isNot(contains('op-hist-dec')));
    });

    test('account filter — operationsForAccount restricts to that account', () async {
      final acc1 = await createAccount(suffix: 'af1');
      final acc2 = await createAccount(suffix: 'af2');

      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-af1-inc',
          householdId: 'hh-hist',
          destinationAccountId: acc1,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-af2-inc',
          householdId: 'hh-hist',
          destinationAccountId: acc2,
          amountMinorUnits: 3000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
      );

      final resultsForAcc1 = await queryRepo.operationsForAccount(
        accountId: acc1,
        householdId: 'hh-hist',
      );
      final ids = resultsForAcc1.map((t) => t.operation.id).toSet();
      expect(ids, contains('op-hist-af1-inc'));
      expect(ids, isNot(contains('op-hist-af2-inc')));
    });

    test('operation type filter — income/expense/transfer are distinct', () async {
      final acc = await createAccount(suffix: 'ot1');
      final acc2 = await createAccount(suffix: 'ot2');

      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-ot-inc',
          householdId: 'hh-hist',
          destinationAccountId: acc,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-hist-ot-exp',
          householdId: 'hh-hist',
          sourceAccountId: acc,
          amountMinorUnits: 2000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: 'op-hist-ot-tf',
          householdId: 'hh-hist',
          sourceAccountId: acc,
          destinationAccountId: acc2,
          amountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-03',
          createdBy: 'user-1',
        ),
      );

      // Filter by income.
      final incomeOps = await queryRepo.recentOperations(
        householdId: 'hh-hist',
        filter: const TransactionFilter(operationType: OperationType.income, pageSize: 100),
      );
      expect(incomeOps.every((t) => t.operation.type == OperationType.income), isTrue);
      expect(incomeOps.any((t) => t.operation.id == 'op-hist-ot-inc'), isTrue);

      // Filter by expense.
      final expenseOps = await queryRepo.recentOperations(
        householdId: 'hh-hist',
        filter: const TransactionFilter(operationType: OperationType.expense, pageSize: 100),
      );
      expect(expenseOps.every((t) => t.operation.type == OperationType.expense), isTrue);

      // Filter by transfer.
      final transferOps = await queryRepo.recentOperations(
        householdId: 'hh-hist',
        filter: const TransactionFilter(operationType: OperationType.transfer, pageSize: 100),
      );
      expect(transferOps.every((t) => t.operation.type == OperationType.transfer), isTrue);
    });

    test('transfers excluded from income/expense totals — type filter is separate', () async {
      final src = await createAccount(suffix: 'te1-src');
      final dst = await createAccount(suffix: 'te1-dst');

      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-te-inc',
          householdId: 'hh-hist',
          destinationAccountId: src,
          amountMinorUnits: 8000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: 'op-hist-te-tf',
          householdId: 'hh-hist',
          sourceAccountId: src,
          destinationAccountId: dst,
          amountMinorUnits: 3000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
      );

      // Income filter should not include transfer.
      final incomeOnly = await queryRepo.recentOperations(
        householdId: 'hh-hist',
        filter: const TransactionFilter(operationType: OperationType.income, pageSize: 100),
      );
      final incomeIds = incomeOnly.map((t) => t.operation.id).toSet();
      expect(incomeIds, isNot(contains('op-hist-te-tf')));

      // Total income amount should be 8000, not 8000+3000.
      final totalIncome = incomeOnly.fold<int>(
        0,
        (sum, t) => sum + t.operation.totalAmountMinorUnits,
      );
      expect(totalIncome, 8000);
    });

    test('reversed indicator visible on reversed operations', () async {
      final acc = await createAccount(suffix: 'rv1');

      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-rv-orig',
          householdId: 'hh-hist',
          destinationAccountId: acc,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-hist-rv-exp',
          householdId: 'hh-hist',
          sourceAccountId: acc,
          amountMinorUnits: 2000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'op-hist-rv-rev',
          originalOperationId: 'op-hist-rv-exp',
          householdId: 'hh-hist',
          effectiveDate: '2024-01-05',
          createdBy: 'user-1',
          reason: 'Test reversal',
        ),
      );

      final all = await queryRepo.recentOperations(
        householdId: 'hh-hist',
        filter: const TransactionFilter(pageSize: 100),
      );

      // The original expense should show isReversed=true.
      final origExp = all.firstWhere((t) => t.operation.id == 'op-hist-rv-exp');
      expect(origExp.operation.isReversed, isTrue);
      expect(origExp.operation.reversedBy, 'op-hist-rv-rev');
    });

    test('original and reversal both visible in unfiltered list', () async {
      final acc = await createAccount(suffix: 'orb1');

      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-orb-inc',
          householdId: 'hh-hist',
          destinationAccountId: acc,
          amountMinorUnits: 3000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-hist-orb-exp',
          householdId: 'hh-hist',
          sourceAccountId: acc,
          amountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'op-hist-orb-rev',
          originalOperationId: 'op-hist-orb-exp',
          householdId: 'hh-hist',
          effectiveDate: '2024-01-03',
          createdBy: 'user-1',
        ),
      );

      final all = await queryRepo.recentOperations(
        householdId: 'hh-hist',
        filter: const TransactionFilter(pageSize: 100),
      );
      final ids = all.map((t) => t.operation.id).toSet();

      // Both original expense and its reversal must be visible.
      expect(ids, contains('op-hist-orb-exp'));
      expect(ids, contains('op-hist-orb-rev'));
    });

    test('opening balance distinct from income (type = openingBalance)', () async {
      final acc = await createAccount(suffix: 'ob1');

      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'op-hist-ob',
          householdId: 'hh-hist',
          accountId: acc,
          amountMinorUnits: 15000,
          currencyCode: 'EGP',
          effectiveDate: '2023-12-01',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-ob-inc',
          householdId: 'hh-hist',
          destinationAccountId: acc,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

      // Filter by income only — opening balance should NOT appear.
      final incomeOnly = await queryRepo.recentOperations(
        householdId: 'hh-hist',
        filter: const TransactionFilter(operationType: OperationType.income, pageSize: 100),
      );
      final ids = incomeOnly.map((t) => t.operation.id).toSet();
      expect(ids, isNot(contains('op-hist-ob')));
      expect(ids, contains('op-hist-ob-inc'));

      // Filter by openingBalance only.
      final obOnly = await queryRepo.recentOperations(
        householdId: 'hh-hist',
        filter: const TransactionFilter(operationType: OperationType.openingBalance, pageSize: 100),
      );
      expect(obOnly.any((t) => t.operation.id == 'op-hist-ob'), isTrue);
    });

    test('deterministic ordering — results are DESC by date, then recorded_at, then id', () async {
      final acc = await createAccount(suffix: 'ord1');

      // Insert operations with different dates.
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-ord-1',
          householdId: 'hh-hist',
          destinationAccountId: acc,
          amountMinorUnits: 100,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-ord-2',
          householdId: 'hh-hist',
          destinationAccountId: acc,
          amountMinorUnits: 200,
          currencyCode: 'EGP',
          effectiveDate: '2024-06-01',
          createdBy: 'user-1',
        ),
      );
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-hist-ord-3',
          householdId: 'hh-hist',
          destinationAccountId: acc,
          amountMinorUnits: 300,
          currencyCode: 'EGP',
          effectiveDate: '2024-03-01',
          createdBy: 'user-1',
        ),
      );

      final results = await queryRepo.recentOperations(
        householdId: 'hh-hist',
        filter: const TransactionFilter(operationType: OperationType.income, pageSize: 100),
      );

      final ids = results.map((t) => t.operation.id).toList();
      // Newest date first (2024-06, 2024-03, 2024-01).
      final juneIdx = ids.indexOf('op-hist-ord-2');
      final marchIdx = ids.indexOf('op-hist-ord-3');
      final janIdx = ids.indexOf('op-hist-ord-1');
      expect(juneIdx < marchIdx, isTrue);
      expect(marchIdx < janIdx, isTrue);

      // Running the same query twice must return the same order.
      final results2 = await queryRepo.recentOperations(
        householdId: 'hh-hist',
        filter: const TransactionFilter(operationType: OperationType.income, pageSize: 100),
      );
      final ids2 = results2.map((t) => t.operation.id).toList();
      expect(ids, equals(ids2));
    });
  });
}
