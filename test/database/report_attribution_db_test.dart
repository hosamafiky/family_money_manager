/// Spending attribution report DB tests (Phase 4B).
///
/// Tests:
///  1. Expense by spender
///  2. Expense by beneficiary
///  3. Expense by scope
///  4. Multiple spenders grouped correctly
///  5. Scope: personal vs household
///  6. No context = not in spender breakdown
///  7. Cross-household isolation
///  8. Multiple currencies separate in scope breakdown
///  9. Period boundary for attribution
/// 10. Beneficiary with display name from household_members
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
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-attr';
const _hh2 = 'hh-attr-2';

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

    for (final h in [_hh, _hh2]) {
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('$h', 'HH $h', 'u1', '2024-01-01', '2024-01-01')",
      );
    }
    // Household members for display name tests
    await db.customStatement(
      "INSERT INTO household_members (id, household_id, display_name, role, is_archived, created_at, updated_at) "
      "VALUES ('member-1', '$_hh', 'Alice', 'primaryUser', 0, '2024-01-01', '2024-01-01')",
    );
    await db.customStatement(
      "INSERT INTO household_members (id, household_id, display_name, role, is_archived, created_at, updated_at) "
      "VALUES ('member-2', '$_hh', 'Bob', 'spouseUser', 0, '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<String> createAccount(
    String id, {
    String householdId = _hh,
    String currency = 'EGP',
  }) async {
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
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

  Future<void> seedIncome(String accId, String opId, int amount) async {
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: opId,
        householdId: _hh,
        destinationAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: '2025-01-01',
        createdBy: 'test',
      ),
    );
  }

  Future<void> expenseWithContext(
    String accId,
    String opId,
    int amount,
    String date, {
    String? spenderId,
    String? beneficiaryId,
    ExpenseScope? scope,
    String householdId = _hh,
  }) async {
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: opId,
        householdId: householdId,
        sourceAccountId: accId,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: date,
        createdBy: 'test',
        scope: scope,
        spenderMemberId: spenderId,
        beneficiaryMemberId: beneficiaryId,
      ),
    );
  }

  FinancialReportRequest janReq({String householdId = _hh}) => FinancialReportRequest(
    householdId: householdId,
    period: DashboardPeriod.custom(startDate: '2025-01-01', endDate: '2025-02-01'),
  );

  group('report_attribution_db', () {
    test('1. Expense by spender', () async {
      final acc = await createAccount('acc-attr-1');
      await seedIncome(acc, 'op-inc-attr-1', 20000);
      await expenseWithContext(acc, 'op-exp-attr-1', 5000, '2025-01-10', spenderId: 'member-1');

      final result = await reportRepo.expenseBySpender(janReq());
      expect(result.isNotEmpty, isTrue);
      final alice = result.firstWhere(
        (r) => r.memberId == 'member-1',
        orElse: () => throw Exception('member-1 not found'),
      );
      expect(alice.totalMinorUnits, 5000);
      expect(alice.memberDisplayName, 'Alice');
    });

    test('2. Expense by beneficiary', () async {
      final acc = await createAccount('acc-attr-2');
      await seedIncome(acc, 'op-inc-attr-2', 20000);
      await expenseWithContext(acc, 'op-exp-attr-2', 3000, '2025-01-15', beneficiaryId: 'member-2');

      final result = await reportRepo.expenseByBeneficiary(janReq());
      expect(result.isNotEmpty, isTrue);
      final bob = result.firstWhere(
        (r) => r.memberId == 'member-2',
        orElse: () => throw Exception('member-2 not found'),
      );
      expect(bob.totalMinorUnits, 3000);
      expect(bob.memberDisplayName, 'Bob');
    });

    test('3. Expense by scope', () async {
      final acc = await createAccount('acc-attr-3');
      await seedIncome(acc, 'op-inc-attr-3', 30000);
      await expenseWithContext(
        acc,
        'op-exp-attr-3a',
        4000,
        '2025-01-10',
        scope: ExpenseScope.personal,
      );
      await expenseWithContext(
        acc,
        'op-exp-attr-3b',
        6000,
        '2025-01-12',
        scope: ExpenseScope.household,
      );

      final result = await reportRepo.expenseByScope(janReq());
      final personal = result.firstWhere(
        (r) => r.scope == ExpenseScope.personal,
        orElse: () => throw Exception('personal scope not found'),
      );
      final household = result.firstWhere(
        (r) => r.scope == ExpenseScope.household,
        orElse: () => throw Exception('household scope not found'),
      );
      expect(personal.totalMinorUnits, 4000);
      expect(household.totalMinorUnits, 6000);
    });

    test('4. Multiple spenders grouped correctly', () async {
      final acc = await createAccount('acc-attr-4');
      await seedIncome(acc, 'op-inc-attr-4', 30000);
      await expenseWithContext(acc, 'op-exp-attr-4a', 2000, '2025-01-10', spenderId: 'member-1');
      await expenseWithContext(acc, 'op-exp-attr-4b', 3000, '2025-01-11', spenderId: 'member-1');
      await expenseWithContext(acc, 'op-exp-attr-4c', 7000, '2025-01-12', spenderId: 'member-2');

      final result = await reportRepo.expenseBySpender(janReq());
      final alice = result.firstWhere((r) => r.memberId == 'member-1');
      final bob = result.firstWhere((r) => r.memberId == 'member-2');
      expect(alice.totalMinorUnits, 5000, reason: '2000 + 3000 = 5000 for Alice');
      expect(bob.totalMinorUnits, 7000);
    });

    test('5. Scope: personal vs spouse', () async {
      final acc = await createAccount('acc-attr-5');
      await seedIncome(acc, 'op-inc-attr-5', 30000);
      await expenseWithContext(
        acc,
        'op-exp-attr-5a',
        5000,
        '2025-01-10',
        scope: ExpenseScope.personal,
      );
      await expenseWithContext(
        acc,
        'op-exp-attr-5b',
        4000,
        '2025-01-11',
        scope: ExpenseScope.spouse,
      );

      final result = await reportRepo.expenseByScope(janReq());
      expect(result.any((r) => r.scope == ExpenseScope.personal), isTrue);
      expect(result.any((r) => r.scope == ExpenseScope.spouse), isTrue);
    });

    test('6. No context = not in spender breakdown', () async {
      final acc = await createAccount('acc-attr-6');
      await seedIncome(acc, 'op-inc-attr-6', 10000);
      // Expense without spenderMemberId
      await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-exp-attr-6',
          householdId: _hh,
          sourceAccountId: acc,
          amountMinorUnits: 3000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-10',
          createdBy: 'test',
        ),
      );

      final result = await reportRepo.expenseBySpender(janReq());
      expect(result.isEmpty, isTrue, reason: 'Expenses without spender context are excluded');
    });

    test('7. Cross-household isolation', () async {
      final acc1 = await createAccount('acc-attr-7a');
      final acc2 = await createAccount('acc-attr-7b', householdId: _hh2);

      await db.customStatement(
        "INSERT INTO household_members (id, household_id, display_name, role, is_archived, created_at, updated_at) "
        "VALUES ('member-hh2', '$_hh2', 'Other', 'primaryUser', 0, '2024-01-01', '2024-01-01')",
      );

      await seedIncome(acc1, 'op-inc-hh1', 10000);
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-inc-hh2',
          householdId: _hh2,
          destinationAccountId: acc2,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      await expenseWithContext(acc1, 'op-exp-hh1', 4000, '2025-01-10', spenderId: 'member-1');
      await expenseWithContext(
        acc2,
        'op-exp-hh2',
        6000,
        '2025-01-10',
        spenderId: 'member-hh2',
        householdId: _hh2,
      );

      final result = await reportRepo.expenseBySpender(janReq());
      expect(
        result.any((r) => r.memberId == 'member-hh2'),
        isFalse,
        reason: 'HH2 spender not in HH1 report',
      );
    });

    test('8. Multiple currencies separate in scope breakdown', () async {
      final accEgp = await createAccount('acc-attr-8a', currency: 'EGP');
      final accUsd = await createAccount('acc-attr-8b', currency: 'USD');

      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-inc-egp',
          householdId: _hh,
          destinationAccountId: accEgp,
          amountMinorUnits: 20000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-inc-usd',
          householdId: _hh,
          destinationAccountId: accUsd,
          amountMinorUnits: 10000,
          currencyCode: 'USD',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      );
      await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-exp-egp',
          householdId: _hh,
          sourceAccountId: accEgp,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-10',
          createdBy: 'test',
          scope: ExpenseScope.personal,
        ),
      );
      await ledgerRepo.recordExpense(
        RecordExpenseParams(
          operationId: 'op-exp-usd',
          householdId: _hh,
          sourceAccountId: accUsd,
          amountMinorUnits: 3000,
          currencyCode: 'USD',
          effectiveDate: '2025-01-10',
          createdBy: 'test',
          scope: ExpenseScope.personal,
        ),
      );

      final result = await reportRepo.expenseByScope(janReq());
      final egp = result.where((r) => r.currencyCode == 'EGP').toList();
      final usd = result.where((r) => r.currencyCode == 'USD').toList();
      expect(egp.isNotEmpty, isTrue);
      expect(usd.isNotEmpty, isTrue);
    });

    test('9. Period boundary for attribution', () async {
      final acc = await createAccount('acc-attr-9');
      await seedIncome(acc, 'op-inc-attr-9', 30000);
      await expenseWithContext(
        acc,
        'op-exp-attr-9a',
        2000,
        '2024-12-31', // before period
        spenderId: 'member-1',
      );
      await expenseWithContext(
        acc,
        'op-exp-attr-9b',
        3000,
        '2025-01-15', // in period
        spenderId: 'member-1',
      );
      await expenseWithContext(
        acc,
        'op-exp-attr-9c',
        4000,
        '2025-02-01', // after period (exclusive)
        spenderId: 'member-1',
      );

      final result = await reportRepo.expenseBySpender(janReq());
      final alice = result.firstWhere(
        (r) => r.memberId == 'member-1',
        orElse: () => throw Exception('member-1 not found'),
      );
      expect(alice.totalMinorUnits, 3000, reason: 'Only in-period expense (3000) counted');
    });

    test('10. Beneficiary with display name from household_members', () async {
      final acc = await createAccount('acc-attr-10');
      await seedIncome(acc, 'op-inc-attr-10', 20000);
      await expenseWithContext(
        acc,
        'op-exp-attr-10',
        4500,
        '2025-01-10',
        beneficiaryId: 'member-2',
      );

      final result = await reportRepo.expenseByBeneficiary(janReq());
      final bob = result.firstWhere(
        (r) => r.memberId == 'member-2',
        orElse: () => throw Exception('member-2 not found'),
      );
      expect(bob.memberDisplayName, 'Bob', reason: 'Display name fetched from household_members');
      expect(bob.totalMinorUnits, 4500);
    });
  });
}
