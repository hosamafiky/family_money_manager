/// Phase 6A.2 — XDEB-1..6 cross-feature debit races (two Drift connections).
library;

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/certificates/application/certificate_use_cases.dart';
import 'package:family_money_manager/features/certificates/data/drift_certificate_repository.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
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
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _hh = 'hh-xdeb';

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
  }) async => null;

  @override
  Future<List<HouseholdMember>> listMembers(String householdId) async => [
    HouseholdMember(
      id: 'u1',
      householdId: householdId,
      displayName: 'Owner',
      role: MemberRole.primaryUser,
      lifecycle: MemberLifecycle.active,
      isArchived: false,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    ),
  ];

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

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late Directory dir;
  late String path;
  late AppDatabase db1;
  late AppDatabase db2;
  late DriftAccountRepository accounts1;
  late DriftLedgerRepository ledger1;
  late DriftLedgerRepository ledger2;
  late CreateCertificateUseCase create1;
  late CreateCertificateUseCase create2;
  late RecordExpenseUseCase expense1;
  late RecordExpenseUseCase expense2;
  late ExecuteTransferUseCase transfer2;
  late CreateGoalUseCase createGoal1;
  late FundGoalUseCase fund1;
  late FundGoalUseCase fund2;

  Future<void> seed() async {
    await db1.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'HH', 'u1', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
  }

  Future<void> createAcct(String id) async {
    await accounts1.createAccount(
      CreateAccountParams(
        id: id,
        householdId: _hh,
        name: id,
        type: FinancialAccountType.bankAccount,
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
        householdId: _hh,
        destinationAccountId: id,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'test',
      ),
    );
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

  Future<SavingsGoal> makeGoal(String ikey) async {
    final r = await createGoal1.execute(
      goalName: 'G-$ikey',
      purpose: GoalPurpose.emergencyFund,
      currencyCode: 'EGP',
      targetMinorUnits: 100000,
      householdId: _hh,
      idempotencyKey: ikey,
    );
    return (r as AppOk<SavingsGoal>).value;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fmm_xdeb_');
    path = p.join(dir.path, 'conc.db');
    db1 = AppDatabase.forFile(path);
    db2 = AppDatabase.forFile(path);
    await db1.customStatement('PRAGMA busy_timeout = 5000');
    await db2.customStatement('PRAGMA busy_timeout = 5000');
    accounts1 = DriftAccountRepository(db1);
    ledger1 = DriftLedgerRepository(db1);
    ledger2 = DriftLedgerRepository(db2);
    final certs1 = DriftCertificateRepository(db1);
    final certs2 = DriftCertificateRepository(db2);
    create1 = CreateCertificateUseCase(
      certRepository: certs1,
      accountRepository: accounts1,
    );
    create2 = CreateCertificateUseCase(
      certRepository: certs2,
      accountRepository: DriftAccountRepository(db2),
    );
    expense1 = RecordExpenseUseCase(
      ledgerRepository: ledger1,
      accountRepository: accounts1,
      householdRepository: _NoopHouseholdRepository(),
    );
    expense2 = RecordExpenseUseCase(
      ledgerRepository: ledger2,
      accountRepository: DriftAccountRepository(db2),
      householdRepository: _NoopHouseholdRepository(),
    );
    transfer2 = ExecuteTransferUseCase(
      ledgerRepository: ledger2,
      accountRepository: DriftAccountRepository(db2),
    );
    final goals1 = DriftGoalRepository(db1);
    final goals2 = DriftGoalRepository(db2);
    createGoal1 = CreateGoalUseCase(
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
    await seed();
  });

  tearDown(() async {
    await db1.close();
    await db2.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test(
    'XDEB-1. Cert purchase vs cert purchase — only affordable set commits',
    () async {
      await createAcct('src');
      await credit('src', 100000);
      final results = await Future.wait([
        create1.execute(
          householdId: _hh,
          institutionName: 'Bank',
          currencyCode: 'EGP',
          principalMinorUnits: 80000,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          sourceAccountId: 'src',
          idempotencyKey: 'xdeb1-a',
        ),
        create2.execute(
          householdId: _hh,
          institutionName: 'Bank',
          currencyCode: 'EGP',
          principalMinorUnits: 80000,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          sourceAccountId: 'src',
          idempotencyKey: 'xdeb1-b',
        ),
      ]);
      final oks = results.whereType<AppOk<SavingsCertificate>>().length;
      final insuff = results
          .whereType<AppInsufficientFunds<SavingsCertificate>>()
          .length;
      expect(oks, 1);
      expect(insuff, 1);
      expect(
        results.whereType<AppPersistenceFailure<SavingsCertificate>>(),
        isEmpty,
      );
      expect(await bal(db1, 'src'), 20000);
      expect(
        await count(db1, "SELECT COUNT(*) as c FROM savings_certificates"),
        1,
      );
      expect(
        await count(
          db1,
          "SELECT COUNT(*) as c FROM certificate_events WHERE event_type='purchased'",
        ),
        1,
      );
      expect(
        await count(
          db1,
          "SELECT COUNT(*) as c FROM certificate_events WHERE event_type='created'",
        ),
        1,
      );
      expect(
        await count(
          db1,
          "SELECT COUNT(*) as c FROM operations WHERE type='certificateFunding'",
        ),
        1,
      );
      expect(
        await count(
          db1,
          "SELECT COUNT(*) as c FROM operation_contexts oc "
          "JOIN operations o ON o.id = oc.operation_id "
          "WHERE o.type='certificateFunding'",
        ),
        1,
      );
    },
  );

  test(
    'XDEB-2. Cert purchase vs expense — only affordable set commits',
    () async {
      await createAcct('src');
      await credit('src', 100000);
      final results = await Future.wait<Object>([
        create1.execute(
          householdId: _hh,
          institutionName: 'Bank',
          currencyCode: 'EGP',
          principalMinorUnits: 80000,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          sourceAccountId: 'src',
          idempotencyKey: 'xdeb2-cert',
        ),
        expense2.execute(
          const ExpenseContext(
            operationId: 'exp-xdeb2',
            idempotencyKey: 'xdeb2-exp',
            householdId: _hh,
            paymentAccountId: 'src',
            amountMinorUnits: 80000,
            currencyCode: 'EGP',
            effectiveDate: '2025-01-01',
            category: TransactionCategory.groceries,
            spenderMemberId: 'u1',
            beneficiaryMemberId: 'u1',
            scope: ExpenseScope.personal,
            isRecurring: false,
            createdBy: 'test',
          ),
        ),
      ]);
      final certOk = results.whereType<AppOk<SavingsCertificate>>().length;
      final expOk = results.whereType<AppOk<String>>().length;
      final certInsuff = results
          .whereType<AppInsufficientFunds<SavingsCertificate>>()
          .length;
      final expInsuff = results
          .whereType<AppInsufficientFunds<String>>()
          .length;
      expect(certOk + expOk, 1);
      expect(certInsuff + expInsuff, 1);
      expect(
        results.whereType<AppPersistenceFailure<SavingsCertificate>>(),
        isEmpty,
      );
      expect(results.whereType<AppPersistenceFailure<String>>(), isEmpty);
      expect(await bal(db1, 'src'), 20000);
      final certs = await count(
        db1,
        'SELECT COUNT(*) as c FROM savings_certificates',
      );
      final expenses = await count(
        db1,
        "SELECT COUNT(*) as c FROM operations WHERE type='expense'",
      );
      expect(certs + expenses, 1);
      expect(certs, certOk);
      expect(expenses, expOk);
    },
  );

  test('XDEB-3. Cert purchase vs ordinary transfer', () async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 100000);
    final results = await Future.wait<Object>([
      create1.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 80000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src',
        idempotencyKey: 'xdeb3-cert',
      ),
      transfer2.execute(
        const TransferContext(
          operationId: 'xfer-xdeb3',
          idempotencyKey: 'xdeb3-xfer',
          householdId: _hh,
          sourceAccountId: 'src',
          destinationAccountId: 'dst',
          amountMinorUnits: 80000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      ),
    ]);
    final certOk = results.whereType<AppOk<SavingsCertificate>>().length;
    final xferOk = results.whereType<AppOk<String>>().length;
    final certInsuff = results
        .whereType<AppInsufficientFunds<SavingsCertificate>>()
        .length;
    final xferInsuff = results.whereType<AppInsufficientFunds<String>>().length;
    expect(certOk + xferOk, 1);
    expect(certInsuff + xferInsuff, 1);
    expect(
      results.whereType<AppPersistenceFailure<SavingsCertificate>>(),
      isEmpty,
    );
    expect(results.whereType<AppPersistenceFailure<String>>(), isEmpty);
    expect(await bal(db1, 'src'), 20000);
    final certs = await count(
      db1,
      'SELECT COUNT(*) as c FROM savings_certificates',
    );
    final xfers = await count(
      db1,
      "SELECT COUNT(*) as c FROM operations WHERE type='transfer'",
    );
    expect(certs + xfers, 1);
  });

  test('XDEB-4. Cert purchase vs goal funding', () async {
    await createAcct('src');
    await credit('src', 100000);
    final goal = await makeGoal('xdeb4-g');
    final results = await Future.wait<Object>([
      create1.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 80000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src',
        idempotencyKey: 'xdeb4-cert',
      ),
      fund2.execute(
        goalId: goal.id,
        sourceAccountId: 'src',
        amountMinorUnits: 80000,
        householdId: _hh,
        idempotencyKey: 'xdeb4-fund',
      ),
    ]);
    final certOk = results.whereType<AppOk<SavingsCertificate>>().length;
    final fundOk = results.whereType<AppOk<SavingsGoal>>().length;
    final certInsuff = results
        .whereType<AppInsufficientFunds<SavingsCertificate>>()
        .length;
    final fundInsuff = results
        .whereType<AppInsufficientFunds<SavingsGoal>>()
        .length;
    expect(certOk + fundOk, 1);
    expect(certInsuff + fundInsuff, 1);
    expect(
      results.whereType<AppPersistenceFailure<SavingsCertificate>>(),
      isEmpty,
    );
    expect(results.whereType<AppPersistenceFailure<SavingsGoal>>(), isEmpty);
    expect(await bal(db1, 'src'), 20000);
    final certs = await count(
      db1,
      'SELECT COUNT(*) as c FROM savings_certificates',
    );
    final movs = await count(
      db1,
      "SELECT COUNT(*) as c FROM goal_movements WHERE goal_id='${goal.id}'",
    );
    expect(certs + movs, 1);
    expect(certs, certOk);
    expect(movs, fundOk);
  });

  test('XDEB-5. Expense vs ordinary transfer', () async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 100000);
    final results = await Future.wait([
      expense1.execute(
        const ExpenseContext(
          operationId: 'exp-xdeb5',
          idempotencyKey: 'xdeb5-exp',
          householdId: _hh,
          paymentAccountId: 'src',
          amountMinorUnits: 80000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          category: TransactionCategory.groceries,
          spenderMemberId: 'u1',
          beneficiaryMemberId: 'u1',
          scope: ExpenseScope.personal,
          isRecurring: false,
          createdBy: 'test',
        ),
      ),
      transfer2.execute(
        const TransferContext(
          operationId: 'xfer-xdeb5',
          idempotencyKey: 'xdeb5-xfer',
          householdId: _hh,
          sourceAccountId: 'src',
          destinationAccountId: 'dst',
          amountMinorUnits: 80000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      ),
    ]);
    final oks = results.whereType<AppOk<String>>().length;
    final insuff = results.whereType<AppInsufficientFunds<String>>().length;
    expect(oks, 1);
    expect(insuff, 1);
    expect(results.whereType<AppPersistenceFailure<String>>(), isEmpty);
    expect(await bal(db1, 'src'), 20000);
    final expenses = await count(
      db1,
      "SELECT COUNT(*) as c FROM operations WHERE type='expense'",
    );
    final xfers = await count(
      db1,
      "SELECT COUNT(*) as c FROM operations WHERE type='transfer'",
    );
    expect(expenses + xfers, 1);
  });

  test('XDEB-6. Goal funding vs ordinary transfer', () async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 100000);
    final goal = await makeGoal('xdeb6-g');
    final results = await Future.wait<Object>([
      fund1.execute(
        goalId: goal.id,
        sourceAccountId: 'src',
        amountMinorUnits: 80000,
        householdId: _hh,
        idempotencyKey: 'xdeb6-fund',
      ),
      transfer2.execute(
        const TransferContext(
          operationId: 'xfer-xdeb6',
          idempotencyKey: 'xdeb6-xfer',
          householdId: _hh,
          sourceAccountId: 'src',
          destinationAccountId: 'dst',
          amountMinorUnits: 80000,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      ),
    ]);
    final fundOk = results.whereType<AppOk<SavingsGoal>>().length;
    final xferOk = results.whereType<AppOk<String>>().length;
    final fundInsuff = results
        .whereType<AppInsufficientFunds<SavingsGoal>>()
        .length;
    final xferInsuff = results.whereType<AppInsufficientFunds<String>>().length;
    expect(await bal(db1, 'src'), 20000); // exactly one 80k debit from 100k
    final movs = await count(
      db1,
      "SELECT COUNT(*) as c FROM goal_movements WHERE goal_id='${goal.id}'",
    );
    // Goal funding persists type='transfer'; exclude those when counting ordinary xfers.
    final ordinaryXfers = await count(
      db1,
      "SELECT COUNT(*) as c FROM operations o WHERE o.type='transfer' "
      'AND NOT EXISTS (SELECT 1 FROM goal_movements m '
      'WHERE m.transfer_operation_id = o.id)',
    );
    expect(movs + ordinaryXfers, 1);
    expect(fundOk + xferOk, 1);
    expect(fundInsuff + xferInsuff, 1);
    expect(results.whereType<AppPersistenceFailure<SavingsGoal>>(), isEmpty);
    expect(results.whereType<AppPersistenceFailure<String>>(), isEmpty);
  });
}
