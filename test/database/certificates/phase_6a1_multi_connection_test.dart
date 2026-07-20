/// Phase 6A.1 — MC-CERT-1..5 multi-connection concurrency tests.
///
/// TWO Drift connections to ONE physical temporary SQLite file.
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

const _hh = 'hh-mc-cert';

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
  Future<List<HouseholdMember>> listMembers(String householdId) async => [];

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
  late CreateCertificateUseCase create1;
  late CreateCertificateUseCase create2;
  late DriftAccountRepository accounts1;
  late DriftLedgerRepository ledger1;
  late DriftLedgerRepository ledger2;
  late RecordExpenseUseCase expense2;
  late ExecuteTransferUseCase transfer2;

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

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fmm_mc_cert_');
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
    expense2 = RecordExpenseUseCase(
      ledgerRepository: ledger2,
      accountRepository: DriftAccountRepository(db2),
      householdRepository: _NoopHouseholdRepository(),
    );
    transfer2 = ExecuteTransferUseCase(
      ledgerRepository: ledger2,
      accountRepository: DriftAccountRepository(db2),
    );
    await seed();
  });

  tearDown(() async {
    await db1.close();
    await db2.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('MC-CERT-1. Equivalent concurrent certificate creation', () async {
    await createAcct('src-mc1');
    await credit('src-mc1', 100000);
    final results = await Future.wait([
      create1.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 30000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src-mc1',
        idempotencyKey: 'ik-mc1',
      ),
      create2.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 30000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src-mc1',
        idempotencyKey: 'ik-mc1',
      ),
    ]);
    final oks = results.whereType<AppOk<SavingsCertificate>>().toList();
    // Phase 6A.2: after lock contention, loser re-reads winner idempotency → AppOk.
    expect(oks, hasLength(2));
    expect(
      results.whereType<AppPersistenceFailure<SavingsCertificate>>(),
      isEmpty,
    );
    expect(
      await count(db1, 'SELECT COUNT(*) as c FROM savings_certificates'),
      1,
    );
    expect(
      await count(
        db1,
        "SELECT COUNT(*) as c FROM operations WHERE type = 'certificateFunding'",
      ),
      1,
    );
    expect(await bal(db1, 'src-mc1'), 70000);
    if (oks.length == 2) {
      expect(oks[0].value.id, oks[1].value.id);
    }
  });

  test('MC-CERT-2. Conflicting concurrent certificate creation', () async {
    await createAcct('src-mc2');
    await credit('src-mc2', 200000);
    final results = await Future.wait([
      create1.execute(
        householdId: _hh,
        institutionName: 'Bank-A',
        currencyCode: 'EGP',
        principalMinorUnits: 20000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src-mc2',
        idempotencyKey: 'ik-mc2',
      ),
      create2.execute(
        householdId: _hh,
        institutionName: 'Bank-B',
        currencyCode: 'EGP',
        principalMinorUnits: 20000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src-mc2',
        idempotencyKey: 'ik-mc2',
      ),
    ]);
    final oks = results.whereType<AppOk<SavingsCertificate>>().length;
    final conflicts = results
        .whereType<AppDuplicateConflict<SavingsCertificate>>()
        .length;
    // Phase 6A.2: loser re-reads conflicting payload → AppDuplicateConflict.
    expect(oks, 1);
    expect(conflicts, 1);
    expect(
      await count(db1, 'SELECT COUNT(*) as c FROM savings_certificates'),
      1,
    );
    expect(await bal(db1, 'src-mc2'), greaterThanOrEqualTo(0));
  });

  test('MC-CERT-3. Two certificates compete for insufficient source', () async {
    await createAcct('src-mc3');
    await credit('src-mc3', 50000);
    final results = await Future.wait([
      create1.execute(
        householdId: _hh,
        institutionName: 'A',
        currencyCode: 'EGP',
        principalMinorUnits: 40000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src-mc3',
        idempotencyKey: 'ik-mc3a',
      ),
      create2.execute(
        householdId: _hh,
        institutionName: 'B',
        currencyCode: 'EGP',
        principalMinorUnits: 40000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src-mc3',
        idempotencyKey: 'ik-mc3b',
      ),
    ]);
    final oks = results.whereType<AppOk<SavingsCertificate>>().length;
    final insuff = results
        .whereType<AppInsufficientFunds<SavingsCertificate>>()
        .length;
    final fails = results
        .whereType<AppPersistenceFailure<SavingsCertificate>>()
        .length;
    expect(oks, 1);
    // Prefer typed insufficient funds; lock-timeout may still surface persistence.
    expect(insuff + fails, 1);
    expect(
      await count(db1, 'SELECT COUNT(*) as c FROM savings_certificates'),
      1,
    );
    expect(await bal(db1, 'src-mc3'), greaterThanOrEqualTo(0));
    expect(await bal(db1, 'src-mc3'), lessThanOrEqualTo(50000));
  });

  test('MC-CERT-4. Purchase vs ordinary expense across connections', () async {
    await createAcct('src-mc4');
    await credit('src-mc4', 50000);
    final results = await Future.wait([
      create1.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 40000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src-mc4',
        idempotencyKey: 'ik-mc4',
      ),
      expense2.execute(
        const ExpenseContext(
          operationId: 'exp-mc4',
          idempotencyKey: 'exp-mc4-idem',
          householdId: _hh,
          paymentAccountId: 'src-mc4',
          amountMinorUnits: 40000,
          currencyCode: 'EGP',
          effectiveDate: '2025-06-01',
          category: TransactionCategory.groceries,
          spenderMemberId: 'u1',
          beneficiaryMemberId: 'u1',
          scope: ExpenseScope.personal,
          isRecurring: false,
          createdBy: 'test',
        ),
      ),
    ]);
    final certOk = results[0] is AppOk<SavingsCertificate>;
    final expenseOk = results[1] is AppOk<String>;
    // Phase 6A.2: IMMEDIATE txn + non-neg trigger → exactly one commits.
    expect(certOk ^ expenseOk, isTrue);
    expect(await bal(db1, 'src-mc4'), greaterThanOrEqualTo(0));
  });

  test('MC-CERT-5. Purchase vs ordinary transfer across connections', () async {
    await createAcct('src-mc5');
    await createAcct('dst-mc5');
    await credit('src-mc5', 50000);
    final results = await Future.wait([
      create1.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 40000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src-mc5',
        idempotencyKey: 'ik-mc5',
      ),
      transfer2.execute(
        const TransferContext(
          operationId: 'xfer-mc5',
          idempotencyKey: 'xfer-mc5-idem',
          householdId: _hh,
          sourceAccountId: 'src-mc5',
          destinationAccountId: 'dst-mc5',
          amountMinorUnits: 40000,
          currencyCode: 'EGP',
          effectiveDate: '2025-06-01',
          createdBy: 'test',
        ),
      ),
    ]);
    final certOk = results[0] is AppOk<SavingsCertificate>;
    final xferOk = results[1] is AppOk<String>;
    expect(certOk ^ xferOk, isTrue);
    expect(await bal(db1, 'src-mc5'), greaterThanOrEqualTo(0));
  });
}
