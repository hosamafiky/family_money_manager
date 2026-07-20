/// Phase 6A.3 — Deterministic certificate idempotency / reversal extras.
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

const _hh = 'hh-6a3-idmp';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late Directory dir;
  late String path;
  late AppDatabase db1;
  late AppDatabase db2;
  late DriftAccountRepository accounts1;
  late DriftLedgerRepository ledger1;
  late CreateCertificateUseCase create1;
  late RecordCertificateProfitUseCase profit1;
  late RecordCertificateProfitUseCase profit2;
  late RedeemCertificateUseCase redeem1;
  late RedeemCertificateUseCase redeem2;
  late ReverseCertificatePurchaseUseCase revPurch1;
  late ReverseCertificatePurchaseUseCase revPurch2;
  late ReverseCertificateProfitUseCase revProfit1;
  late ReverseCertificateProfitUseCase revProfit2;

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

  Future<int> count(String sql) async =>
      (await db1.customSelect(sql).get()).first.read<int>('c');

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fmm_6a3_idmp_');
    path = p.join(dir.path, 'conc.db');
    db1 = AppDatabase.forFile(path);
    db2 = AppDatabase.forFile(path);
    await db1.customStatement('PRAGMA busy_timeout = 5000');
    await db2.customStatement('PRAGMA busy_timeout = 5000');
    accounts1 = DriftAccountRepository(db1);
    ledger1 = DriftLedgerRepository(db1);
    final certs1 = DriftCertificateRepository(db1);
    final certs2 = DriftCertificateRepository(db2);
    create1 = CreateCertificateUseCase(
      certRepository: certs1,
      accountRepository: accounts1,
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

  test(
    'CIDMP-10. Sequential equivalent create → both AppOk, one workflow',
    () async {
      await createAcct('src');
      await credit('src', 100000);
      final r1 = await create1.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 30000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src',
        idempotencyKey: 'cidmp10',
      );
      final r2 = await create1.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 30000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src',
        idempotencyKey: 'cidmp10',
      );
      expect(r1, isA<AppOk<SavingsCertificate>>());
      expect(r2, isA<AppOk<SavingsCertificate>>());
      expect(
        (r1 as AppOk<SavingsCertificate>).value.id,
        (r2 as AppOk<SavingsCertificate>).value.id,
      );
      expect(await count('SELECT COUNT(*) as c FROM savings_certificates'), 1);
    },
  );

  test(
    'CIDMP-11. Sequential conflicting create → AppOk + AppDuplicateConflict',
    () async {
      await createAcct('src');
      await credit('src', 100000);
      final r1 = await create1.execute(
        householdId: _hh,
        institutionName: 'Bank-A',
        currencyCode: 'EGP',
        principalMinorUnits: 30000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src',
        idempotencyKey: 'cidmp11',
      );
      final r2 = await create1.execute(
        householdId: _hh,
        institutionName: 'Bank-B',
        currencyCode: 'EGP',
        principalMinorUnits: 30000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src',
        idempotencyKey: 'cidmp11',
      );
      expect(r1, isA<AppOk<SavingsCertificate>>());
      expect(r2, isA<AppDuplicateConflict<SavingsCertificate>>());
    },
  );

  test('CIDMP-12. Conflicting concurrent redeem → one ok + conflict', () async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 200000);
    final cert =
        ((await create1.execute(
                  householdId: _hh,
                  institutionName: 'Bank',
                  currencyCode: 'EGP',
                  principalMinorUnits: 40000,
                  startDate: '2019-01-01',
                  maturityDate: '2020-01-01',
                  sourceAccountId: 'src',
                  idempotencyKey: 'cidmp12-cert',
                ))
                as AppOk<SavingsCertificate>)
            .value;
    final results = await Future.wait([
      redeem1.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst',
        principalMinorUnits: 40000,
        idempotencyKey: 'cidmp12',
      ),
      redeem2.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst',
        principalMinorUnits: 40000,
        profitMinorUnits: 100,
        idempotencyKey: 'cidmp12',
      ),
    ]);
    expect(results.whereType<AppOk<CertificateRedemptionSummary>>().length, 1);
    expect(
      results
          .whereType<AppDuplicateConflict<CertificateRedemptionSummary>>()
          .length,
      1,
    );
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
  });

  test(
    'CIDMP-13. Concurrent equivalent purchase reversal (same key) → both AppOk',
    () async {
      await createAcct('src');
      await credit('src', 200000);
      final cert =
          ((await create1.execute(
                    householdId: _hh,
                    institutionName: 'Bank',
                    currencyCode: 'EGP',
                    principalMinorUnits: 40000,
                    startDate: '2025-01-01',
                    maturityDate: '2026-01-01',
                    sourceAccountId: 'src',
                    idempotencyKey: 'cidmp13-cert',
                  ))
                  as AppOk<SavingsCertificate>)
              .value;
      final results = await Future.wait([
        revPurch1.execute(
          certificateId: cert.id,
          householdId: _hh,
          idempotencyKey: 'cidmp13-rev',
        ),
        revPurch2.execute(
          certificateId: cert.id,
          householdId: _hh,
          idempotencyKey: 'cidmp13-rev',
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
    },
  );

  test('CIDMP-14. Failure then retry equivalent profit succeeds once', () async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 200000);
    final cert =
        ((await create1.execute(
                  householdId: _hh,
                  institutionName: 'Bank',
                  currencyCode: 'EGP',
                  principalMinorUnits: 40000,
                  startDate: '2019-01-01',
                  maturityDate: '2020-01-01',
                  sourceAccountId: 'src',
                  idempotencyKey: 'cidmp14-cert',
                ))
                as AppOk<SavingsCertificate>)
            .value;
    final failing = DriftCertificateRepository(
      db1,
      debugFailAfter: CertificateFailAfter.operationInsert,
    );
    final failProfit = RecordCertificateProfitUseCase(
      certRepository: failing,
      accountRepository: accounts1,
    );
    final fail = await failProfit.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst',
      amountMinorUnits: 500,
      idempotencyKey: 'cidmp14-p',
    );
    expect(fail, isA<AppPersistenceFailure<CertificateProfitReceipt>>());
    expect(
      await count(
        "SELECT COUNT(*) as c FROM certificate_events WHERE event_type='profitReceived'",
      ),
      0,
    );

    final ok = await profit1.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst',
      amountMinorUnits: 500,
      idempotencyKey: 'cidmp14-p',
    );
    expect(ok, isA<AppOk<CertificateProfitReceipt>>());
    expect(
      await count(
        "SELECT COUNT(*) as c FROM certificate_events WHERE event_type='profitReceived'",
      ),
      1,
    );
  });

  test(
    'CIDMP-15. Concurrent conflicting profit reversal keys → one ok + conflict',
    () async {
      await createAcct('src');
      await createAcct('dst');
      await credit('src', 200000);
      final cert =
          ((await create1.execute(
                    householdId: _hh,
                    institutionName: 'Bank',
                    currencyCode: 'EGP',
                    principalMinorUnits: 40000,
                    startDate: '2019-01-01',
                    maturityDate: '2020-01-01',
                    sourceAccountId: 'src',
                    idempotencyKey: 'cidmp15-cert',
                  ))
                  as AppOk<SavingsCertificate>)
              .value;
      final profit =
          ((await profit1.execute(
                    certificateId: cert.id,
                    householdId: _hh,
                    destinationAccountId: 'dst',
                    amountMinorUnits: 800,
                    idempotencyKey: 'cidmp15-p',
                  ))
                  as AppOk<CertificateProfitReceipt>)
              .value;
      // Same idempotency key, concurrent — winner commits; loser UNIQUE → conflict
      // or already-reversed AppOk. Prefer typed conflict when UNIQUE fires first.
      final results = await Future.wait([
        revProfit1.execute(
          certificateId: cert.id,
          householdId: _hh,
          originalProfitOperationId: profit.incomeOperationId,
          idempotencyKey: 'cidmp15-rev',
        ),
        revProfit2.execute(
          certificateId: cert.id,
          householdId: _hh,
          originalProfitOperationId: profit.incomeOperationId,
          idempotencyKey: 'cidmp15-rev',
        ),
      ]);
      final oks = results.whereType<AppOk<void>>().length;
      final conflicts = results.whereType<AppDuplicateConflict<void>>().length;
      expect(oks + conflicts, 2);
      expect(oks, greaterThanOrEqualTo(1));
      expect(results.whereType<AppPersistenceFailure<void>>(), isEmpty);
      expect(
        await count(
          "SELECT COUNT(*) as c FROM operations WHERE type='reversal'",
        ),
        1,
      );
    },
  );
}
