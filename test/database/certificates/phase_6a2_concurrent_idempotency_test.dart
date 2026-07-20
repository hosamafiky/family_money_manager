/// Phase 6A.2 — Concurrent certificate idempotency (two connections).
library;

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/certificates/application/certificate_use_cases.dart';
import 'package:family_money_manager/features/certificates/data/certificate_write_boundary.dart';
import 'package:family_money_manager/features/certificates/data/drift_certificate_repository.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _hh = 'hh-cidmp';
const _hh2 = 'hh-cidmp-b';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late Directory dir;
  late String path;
  late AppDatabase db1;
  late AppDatabase db2;
  late DriftAccountRepository accounts1;
  late DriftLedgerRepository ledger1;
  late CreateCertificateUseCase create1;
  late CreateCertificateUseCase create2;
  late RecordCertificateProfitUseCase profit1;
  late RecordCertificateProfitUseCase profit2;
  late RedeemCertificateUseCase redeem1;
  late RedeemCertificateUseCase redeem2;
  late ReverseCertificatePurchaseUseCase revPurch1;
  late ReverseCertificatePurchaseUseCase revPurch2;
  late ReverseCertificateProfitUseCase revProfit1;
  late ReverseCertificateProfitUseCase revProfit2;
  late DriftCertificateRepository certs1;

  Future<void> seed() async {
    await db1.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'HH', 'u1', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
    await db1.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh2', 'HH2', 'u2', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
  }

  Future<void> createAcct(String id, {String hh = _hh}) async {
    await accounts1.createAccount(
      CreateAccountParams(
        id: id,
        householdId: hh,
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

  Future<void> credit(String id, int amount, {String hh = _hh}) async {
    await ledger1.recordIncome(
      RecordIncomeParams(
        operationId: 'inc-$id-$amount-${DateTime.now().microsecondsSinceEpoch}',
        householdId: hh,
        destinationAccountId: id,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'test',
      ),
    );
  }

  Future<int> count(String sql) async =>
      (await db1.customSelect(sql).get()).first.read<int>('c');

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fmm_cidmp_');
    path = p.join(dir.path, 'conc.db');
    db1 = AppDatabase.forFile(path);
    db2 = AppDatabase.forFile(path);
    await db1.customStatement('PRAGMA busy_timeout = 5000');
    await db2.customStatement('PRAGMA busy_timeout = 5000');
    accounts1 = DriftAccountRepository(db1);
    ledger1 = DriftLedgerRepository(db1);
    certs1 = DriftCertificateRepository(db1);
    final certs2 = DriftCertificateRepository(db2);
    create1 = CreateCertificateUseCase(
      certRepository: certs1,
      accountRepository: accounts1,
    );
    create2 = CreateCertificateUseCase(
      certRepository: certs2,
      accountRepository: DriftAccountRepository(db2),
    );
    profit1 = RecordCertificateProfitUseCase(
      certRepository: certs1,
      accountRepository: accounts1,
    );
    profit2 = RecordCertificateProfitUseCase(
      certRepository: certs2,
      accountRepository: DriftAccountRepository(db2),
    );
    redeem1 = RedeemCertificateUseCase(
      certRepository: certs1,
      accountRepository: accounts1,
    );
    redeem2 = RedeemCertificateUseCase(
      certRepository: certs2,
      accountRepository: DriftAccountRepository(db2),
    );
    revPurch1 = ReverseCertificatePurchaseUseCase(certs1);
    revPurch2 = ReverseCertificatePurchaseUseCase(certs2);
    revProfit1 = ReverseCertificateProfitUseCase(certs1);
    revProfit2 = ReverseCertificateProfitUseCase(certs2);
    await seed();
  });

  tearDown(() async {
    await db1.close();
    await db2.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('CIDMP-1. Equivalent concurrent create → same result, one workflow', () async {
    await createAcct('src');
    await credit('src', 200000);
    final results = await Future.wait([
      create1.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 50000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src',
        idempotencyKey: 'cidmp-eq',
      ),
      create2.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 50000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src',
        idempotencyKey: 'cidmp-eq',
      ),
    ]);
    expect(results.whereType<AppOk<SavingsCertificate>>().length, 2);
    expect(
      results.whereType<AppPersistenceFailure<SavingsCertificate>>(),
      isEmpty,
    );
    expect(await count('SELECT COUNT(*) as c FROM savings_certificates'), 1);
    expect(
      await count(
        "SELECT COUNT(*) as c FROM financial_accounts WHERE type='certificate'",
      ),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM operations WHERE type='certificateFunding'",
      ),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM certificate_events WHERE event_type='purchased'",
      ),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM certificate_events WHERE event_type='created'",
      ),
      1,
    );
    final ids = results
        .whereType<AppOk<SavingsCertificate>>()
        .map((r) => r.value.id)
        .toSet();
    expect(ids, hasLength(1));
  });

  test(
    'CIDMP-2. Conflicting concurrent create → one ok + AppDuplicateConflict',
    () async {
      await createAcct('src');
      await credit('src', 200000);
      final results = await Future.wait([
        create1.execute(
          householdId: _hh,
          institutionName: 'Bank-A',
          currencyCode: 'EGP',
          principalMinorUnits: 50000,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          sourceAccountId: 'src',
          idempotencyKey: 'cidmp-cf',
        ),
        create2.execute(
          householdId: _hh,
          institutionName: 'Bank-B',
          currencyCode: 'EGP',
          principalMinorUnits: 50000,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          sourceAccountId: 'src',
          idempotencyKey: 'cidmp-cf',
        ),
      ]);
      expect(results.whereType<AppOk<SavingsCertificate>>().length, 1);
      expect(
        results.whereType<AppDuplicateConflict<SavingsCertificate>>().length,
        1,
      );
      expect(await count('SELECT COUNT(*) as c FROM savings_certificates'), 1);
    },
  );

  test('CIDMP-3. Cross-household same key is isolated', () async {
    await createAcct('src-a');
    await createAcct('src-b', hh: _hh2);
    await credit('src-a', 200000);
    await credit('src-b', 200000, hh: _hh2);
    final a = await create1.execute(
      householdId: _hh,
      institutionName: 'Bank',
      currencyCode: 'EGP',
      principalMinorUnits: 40000,
      startDate: '2025-01-01',
      maturityDate: '2026-01-01',
      sourceAccountId: 'src-a',
      idempotencyKey: 'shared-key',
    );
    final b = await create2.execute(
      householdId: _hh2,
      institutionName: 'Bank',
      currencyCode: 'EGP',
      principalMinorUnits: 40000,
      startDate: '2025-01-01',
      maturityDate: '2026-01-01',
      sourceAccountId: 'src-b',
      idempotencyKey: 'shared-key',
    );
    expect(a, isA<AppOk<SavingsCertificate>>());
    expect(b, isA<AppOk<SavingsCertificate>>());
    expect(await count('SELECT COUNT(*) as c FROM savings_certificates'), 2);
  });

  test('CIDMP-4. Failure then retry equivalent create succeeds once', () async {
    await createAcct('src');
    await credit('src', 200000);
    final failing = DriftCertificateRepository(
      db1,
      debugFailAfter: CertificateFailAfter.accountInsert,
    );
    final failUc = CreateCertificateUseCase(
      certRepository: failing,
      accountRepository: accounts1,
    );
    final fail = await failUc.execute(
      householdId: _hh,
      institutionName: 'Bank',
      currencyCode: 'EGP',
      principalMinorUnits: 40000,
      startDate: '2025-01-01',
      maturityDate: '2026-01-01',
      sourceAccountId: 'src',
      idempotencyKey: 'cidmp-retry',
    );
    expect(fail, isA<AppPersistenceFailure<SavingsCertificate>>());
    expect(await count('SELECT COUNT(*) as c FROM savings_certificates'), 0);

    final ok = await create1.execute(
      householdId: _hh,
      institutionName: 'Bank',
      currencyCode: 'EGP',
      principalMinorUnits: 40000,
      startDate: '2025-01-01',
      maturityDate: '2026-01-01',
      sourceAccountId: 'src',
      idempotencyKey: 'cidmp-retry',
    );
    expect(ok, isA<AppOk<SavingsCertificate>>());
    expect(await count('SELECT COUNT(*) as c FROM savings_certificates'), 1);
  });

  test('CIDMP-5. Equivalent concurrent profit → same result', () async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 200000);
    final cert =
        ((await create1.execute(
                  householdId: _hh,
                  institutionName: 'Bank',
                  currencyCode: 'EGP',
                  principalMinorUnits: 50000,
                  startDate: '2019-01-01',
                  maturityDate: '2020-01-01',
                  sourceAccountId: 'src',
                  idempotencyKey: 'cidmp-p-cert',
                ))
                as AppOk<SavingsCertificate>)
            .value;
    final results = await Future.wait([
      profit1.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst',
        amountMinorUnits: 1000,
        idempotencyKey: 'cidmp-p-eq',
      ),
      profit2.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst',
        amountMinorUnits: 1000,
        idempotencyKey: 'cidmp-p-eq',
      ),
    ]);
    expect(results.whereType<AppOk<CertificateProfitReceipt>>().length, 2);
    expect(
      results.whereType<AppPersistenceFailure<CertificateProfitReceipt>>(),
      isEmpty,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM certificate_events WHERE event_type='profitReceived'",
      ),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM operations WHERE type='income' "
        "AND category_code='certificate_profit'",
      ),
      1,
    );
  });

  test('CIDMP-6. Conflicting concurrent profit → ok + conflict', () async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 200000);
    final cert =
        ((await create1.execute(
                  householdId: _hh,
                  institutionName: 'Bank',
                  currencyCode: 'EGP',
                  principalMinorUnits: 50000,
                  startDate: '2019-01-01',
                  maturityDate: '2020-01-01',
                  sourceAccountId: 'src',
                  idempotencyKey: 'cidmp-pc-cert',
                ))
                as AppOk<SavingsCertificate>)
            .value;
    final results = await Future.wait([
      profit1.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst',
        amountMinorUnits: 1000,
        idempotencyKey: 'cidmp-pc',
      ),
      profit2.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst',
        amountMinorUnits: 2000,
        idempotencyKey: 'cidmp-pc',
      ),
    ]);
    expect(results.whereType<AppOk<CertificateProfitReceipt>>().length, 1);
    expect(
      results
          .whereType<AppDuplicateConflict<CertificateProfitReceipt>>()
          .length,
      1,
    );
  });

  test('CIDMP-7. Equivalent concurrent redeem → same result', () async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 200000);
    final cert =
        ((await create1.execute(
                  householdId: _hh,
                  institutionName: 'Bank',
                  currencyCode: 'EGP',
                  principalMinorUnits: 50000,
                  startDate: '2019-01-01',
                  maturityDate: '2020-01-01',
                  sourceAccountId: 'src',
                  idempotencyKey: 'cidmp-r-cert',
                ))
                as AppOk<SavingsCertificate>)
            .value;
    final results = await Future.wait([
      redeem1.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst',
        principalMinorUnits: 50000,
        idempotencyKey: 'cidmp-r-eq',
      ),
      redeem2.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst',
        principalMinorUnits: 50000,
        idempotencyKey: 'cidmp-r-eq',
      ),
    ]);
    final oks = results.whereType<AppOk<CertificateRedemptionSummary>>().length;
    expect(oks, 2);
    expect(
      results.whereType<AppPersistenceFailure<CertificateRedemptionSummary>>(),
      isEmpty,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM certificate_events WHERE event_type='redeemed'",
      ),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM operations WHERE type='certificateMaturity'",
      ),
      1,
    );
    final ids = results
        .whereType<AppOk<CertificateRedemptionSummary>>()
        .map((r) => r.value.event?.id)
        .toSet();
    expect(ids, hasLength(1));
    expect(ids.single, isNotNull);
  });

  test(
    'CIDMP-8. Concurrent purchase reversal equivalent → success semantics',
    () async {
      await createAcct('src');
      await credit('src', 200000);
      final cert =
          ((await create1.execute(
                    householdId: _hh,
                    institutionName: 'Bank',
                    currencyCode: 'EGP',
                    principalMinorUnits: 50000,
                    startDate: '2025-01-01',
                    maturityDate: '2026-01-01',
                    sourceAccountId: 'src',
                    idempotencyKey: 'cidmp-rev-cert',
                  ))
                  as AppOk<SavingsCertificate>)
              .value;
      final results = await Future.wait([
        revPurch1.execute(
          certificateId: cert.id,
          householdId: _hh,
          idempotencyKey: 'cidmp-rev-a',
        ),
        revPurch2.execute(
          certificateId: cert.id,
          householdId: _hh,
          idempotencyKey: 'cidmp-rev-b',
        ),
      ]);
      // Concurrent equivalent (same purchase already-reversed path): both AppOk.
      final oks = results.whereType<AppOk<void>>().length;
      expect(oks, 2);
      expect(results.whereType<AppPersistenceFailure<void>>(), isEmpty);
      final reversed = await count(
        "SELECT COUNT(*) as c FROM operations WHERE type='reversal'",
      );
      expect(reversed, 1);
    },
  );

  test(
    'CIDMP-9. Concurrent profit reversal + redemption reversal unsupported',
    () async {
      await createAcct('src');
      await createAcct('dst');
      await credit('src', 200000);
      final cert =
          ((await create1.execute(
                    householdId: _hh,
                    institutionName: 'Bank',
                    currencyCode: 'EGP',
                    principalMinorUnits: 50000,
                    startDate: '2019-01-01',
                    maturityDate: '2020-01-01',
                    sourceAccountId: 'src',
                    idempotencyKey: 'cidmp-pr-cert',
                  ))
                  as AppOk<SavingsCertificate>)
              .value;
      final profit =
          ((await profit1.execute(
                    certificateId: cert.id,
                    householdId: _hh,
                    destinationAccountId: 'dst',
                    amountMinorUnits: 1500,
                    idempotencyKey: 'cidmp-pr-p',
                  ))
                  as AppOk<CertificateProfitReceipt>)
              .value;
      final results = await Future.wait([
        revProfit1.execute(
          certificateId: cert.id,
          householdId: _hh,
          originalProfitOperationId: profit.incomeOperationId,
          idempotencyKey: 'cidmp-pr-a',
        ),
        revProfit2.execute(
          certificateId: cert.id,
          householdId: _hh,
          originalProfitOperationId: profit.incomeOperationId,
          idempotencyKey: 'cidmp-pr-b',
        ),
      ]);
      expect(results.whereType<AppOk<void>>().length, 2);
      expect(results.whereType<AppPersistenceFailure<void>>(), isEmpty);
      expect(
        await count(
          "SELECT COUNT(*) as c FROM operations WHERE type='reversal'",
        ),
        1,
      );

      final redeemReject = await ReverseCertificateRedemptionUseCase(
        certs1,
      ).execute(certificateId: cert.id, householdId: _hh);
      expect(redeemReject, isA<AppValidationFailure<void>>());
    },
  );
}
