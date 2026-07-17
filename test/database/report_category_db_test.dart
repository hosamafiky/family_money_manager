/// Category report DB tests (Phase 4B).
///
/// Tests:
/// 1. Expense by category
/// 2. Income by category
/// 3. Income and expense not combined
/// 4. Stable category code used (not localized label)
/// 5. Transaction count accurate
/// 6. Multiple currencies reported separately
/// 7. Period boundary
/// 8. Filter by category code returns only that category
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/reports/data/drift_report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_filter.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-cat';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftReportQueryRepository reportRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    reportRepo = DriftReportQueryRepository(db);

    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'Cat HH', 'u1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<String> createAccount(String id, {String currency = 'EGP'}) async {
    await accountRepo.createAccount(
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
    return id;
  }

  Future<void> seedIncome(String accId, String opId, int amount, {String currency = 'EGP'}) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: opId,
        householdId: _hh,
        destinationAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: currency,
        effectiveDate: '2025-01-01',
        createdBy: 'test',
      ),
    );
  }

  Future<void> expenseWithCategory(
    String accId,
    String opId,
    int amount,
    String date,
    String categoryCode, {
    String currency = 'EGP',
  }) async {
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: opId,
        householdId: _hh,
        sourceAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: currency,
        effectiveDate: date,
        createdBy: 'test',
        categoryCode: categoryCode,
      ),
    );
  }

  Future<void> incomeWithCategory(
    String accId,
    String opId,
    int amount,
    String date,
    String categoryCode,
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
        categoryCode: categoryCode,
      ),
    );
  }

  FinancialReportRequest req({
    String start = '2025-01-01',
    String end = '2025-02-01',
    ReportFilter filter = const ReportFilter(),
  }) {
    return FinancialReportRequest(
      householdId: _hh,
      period: DashboardPeriod.custom(startDate: start, endDate: end),
      filter: filter,
    );
  }

  group('report_category_db', () {
    test('1. Expense by category', () async {
      final acc = await createAccount('acc-cat-1');
      await seedIncome(acc, 'op-seed-cat-1', 20000);
      await expenseWithCategory(acc, 'op-exp-cat-1', 3000, '2025-01-10', 'food');

      final result = await reportRepo.expenseByCategory(req());
      expect(result.isNotEmpty, isTrue);
      final food = result.firstWhere(
        (r) => r.categoryCode == 'food',
        orElse: () => throw Exception('food not found'),
      );
      expect(food.totalMinorUnits, 3000);
      expect(food.categoryType, CategoryType.expense);
    });

    test('2. Income by category', () async {
      final acc = await createAccount('acc-cat-2');
      await incomeWithCategory(acc, 'op-inc-cat-2', 8000, '2025-01-05', 'salary');

      final result = await reportRepo.incomeByCategory(req());
      expect(result.isNotEmpty, isTrue);
      final salary = result.firstWhere(
        (r) => r.categoryCode == 'salary',
        orElse: () => throw Exception('salary not found'),
      );
      expect(salary.totalMinorUnits, 8000);
      expect(salary.categoryType, CategoryType.income);
    });

    test('3. Income and expense not combined', () async {
      final acc = await createAccount('acc-cat-3');
      await incomeWithCategory(acc, 'op-inc-cat-3', 5000, '2025-01-05', 'salary');
      await seedIncome(acc, 'op-seed-cat-3', 20000);
      await expenseWithCategory(acc, 'op-exp-cat-3', 2000, '2025-01-10', 'food');

      final expenseResult = await reportRepo.expenseByCategory(req());
      final incomeResult = await reportRepo.incomeByCategory(req());

      expect(expenseResult.every((r) => r.categoryType == CategoryType.expense), isTrue);
      expect(incomeResult.every((r) => r.categoryType == CategoryType.income), isTrue);
      expect(
        expenseResult.any((r) => r.categoryCode == 'salary'),
        isFalse,
        reason: 'Salary not in expense result',
      );
    });

    test('4. Stable category code used (not localized label)', () async {
      final acc = await createAccount('acc-cat-4');
      await seedIncome(acc, 'op-seed-cat-4', 20000);
      await expenseWithCategory(acc, 'op-exp-cat-4', 1500, '2025-01-10', 'transport');

      final result = await reportRepo.expenseByCategory(req());
      final transport = result.firstWhere((r) => r.categoryCode == 'transport');
      expect(transport.categoryCode, 'transport', reason: 'Raw code returned, not localized label');
    });

    test('5. Transaction count accurate', () async {
      final acc = await createAccount('acc-cat-5');
      await seedIncome(acc, 'op-seed-cat-5', 30000);
      await expenseWithCategory(acc, 'op-exp-cat-5a', 1000, '2025-01-05', 'food');
      await expenseWithCategory(acc, 'op-exp-cat-5b', 2000, '2025-01-10', 'food');
      await expenseWithCategory(acc, 'op-exp-cat-5c', 3000, '2025-01-15', 'food');

      final result = await reportRepo.expenseByCategory(req());
      final food = result.firstWhere((r) => r.categoryCode == 'food');
      expect(food.transactionCount, 3);
      expect(food.totalMinorUnits, 6000);
    });

    test('6. Multiple currencies reported separately', () async {
      final accEgp = await createAccount('acc-cat-6a', currency: 'EGP');
      final accUsd = await createAccount('acc-cat-6b', currency: 'USD');
      await seedIncome(accEgp, 'op-seed-cat-6a', 20000);
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-seed-cat-6b',
          householdId: _hh,
          destinationAccountId: accUsd,
          amountMinorUnits: 10000,
          currencyCode: 'USD',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      await expenseWithCategory(
        accEgp,
        'op-exp-cat-6a',
        3000,
        '2025-01-10',
        'food',
        currency: 'EGP',
      );
      await expenseWithCategory(
        accUsd,
        'op-exp-cat-6b',
        1500,
        '2025-01-10',
        'food',
        currency: 'USD',
      );

      final result = await reportRepo.expenseByCategory(req());
      final egp = result.where((r) => r.currencyCode == 'EGP').toList();
      final usd = result.where((r) => r.currencyCode == 'USD').toList();
      expect(egp.isNotEmpty, isTrue);
      expect(usd.isNotEmpty, isTrue);
    });

    test('7. Period boundary for categories', () async {
      final acc = await createAccount('acc-cat-7');
      await seedIncome(acc, 'op-seed-cat-7', 30000);
      await expenseWithCategory(acc, 'op-exp-cat-7a', 2000, '2024-12-31', 'food'); // before
      await expenseWithCategory(acc, 'op-exp-cat-7b', 3000, '2025-01-15', 'food'); // in
      await expenseWithCategory(acc, 'op-exp-cat-7c', 4000, '2025-02-01', 'food'); // exclusive end

      final result = await reportRepo.expenseByCategory(req());
      final food = result.firstWhere((r) => r.categoryCode == 'food');
      expect(food.totalMinorUnits, 3000, reason: 'Only in-period expense counted');
    });

    test('8. No category code = not in breakdown', () async {
      final acc = await createAccount('acc-cat-8');
      await seedIncome(acc, 'op-seed-cat-8', 20000);
      // Expense without category
      await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-exp-cat-8',
          householdId: _hh,
          sourceAccountId: acc,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-10',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.expenseByCategory(req());
      expect(result.isEmpty, isTrue, reason: 'Expense without category excluded from breakdown');
    });
  });
}
