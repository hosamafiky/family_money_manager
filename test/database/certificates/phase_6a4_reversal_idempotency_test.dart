/// Phase 6A.4 — Purchase & profit reversal idempotency (exact typed outcomes).
///
/// Separate rows for equivalent vs conflicting; sequential vs concurrent.
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

const _hh = 'hh-6a4-rev';

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

  Future<SavingsCertificate> makeCert(
    String key, {
    int principal = 40000,
  }) async {
    final r = await create1.execute(
      householdId: _hh,
      institutionName: 'Bank',
      currencyCode: 'EGP',
      principalMinorUnits: principal,
      startDate: '2025-01-01',
      maturityDate: '2026-01-01',
      sourceAccountId: 'src',
      idempotencyKey: key,
    );
    return (r as AppOk<SavingsCertificate>).value;
  }

  Future<SavingsCertificate> makeMatureCert(
    String key, {
    int principal = 40000,
  }) async {
    final r = await create1.execute(
      householdId: _hh,
      institutionName: 'Bank',
      currencyCode: 'EGP',
      principalMinorUnits: principal,
      startDate: '2019-01-01',
      maturityDate: '2020-01-01',
      sourceAccountId: 'src',
      idempotencyKey: key,
    );
    return (r as AppOk<SavingsCertificate>).value;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fmm_6a4_rev_');
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
    profit1 = RecordCertificateProfitUseCase(
      certRepository: certs1,
      accountRepository: accounts1,
    );
    revPurch1 = ReverseCertificatePurchaseUseCase(certs1);
    revPurch2 = ReverseCertificatePurchaseUseCase(certs2);
    revProfit1 = ReverseCertificateProfitUseCase(certs1);
    revProfit2 = ReverseCertificateProfitUseCase(certs2);
    await seed();
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 500000);
  });

  tearDown(() async {
    await db1.close();
    await db2.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  // ── Purchase reversal ─────────────────────────────────────────────────────

  test('REV-PUR-SEQ-EQ. Sequential equivalent purchase reverse → both AppOk, '
      'same reversal op + cert event', () async {
    final cert = await makeCert('pur-seq-eq-cert');
    final r1 = await revPurch1.execute(
      certificateId: cert.id,
      householdId: _hh,
      idempotencyKey: 'pur-seq-eq',
      reason: 'same',
    );
    final r2 = await revPurch1.execute(
      certificateId: cert.id,
      householdId: _hh,
      idempotencyKey: 'pur-seq-eq',
      reason: 'same',
    );
    expect(r1, isA<AppOk<void>>());
    expect(r2, isA<AppOk<void>>());
    expect(r2, isNot(isA<AppDuplicateConflict<void>>()));
    expect(
      await count("SELECT COUNT(*) as c FROM operations WHERE type='reversal'"),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM certificate_events "
        "WHERE event_type='purchaseReversed'",
      ),
      1,
    );
  });

  test('REV-PUR-SEQ-CF. Sequential conflicting purchase reverse → '
      'AppOk then AppDuplicateConflict', () async {
    final cert = await makeCert('pur-seq-cf-cert');
    final r1 = await revPurch1.execute(
      certificateId: cert.id,
      householdId: _hh,
      idempotencyKey: 'pur-seq-cf',
      reason: 'reason-a',
    );
    final r2 = await revPurch1.execute(
      certificateId: cert.id,
      householdId: _hh,
      idempotencyKey: 'pur-seq-cf',
      reason: 'reason-b',
    );
    expect(r1, isA<AppOk<void>>());
    expect(r2, isA<AppDuplicateConflict<void>>());
    expect(
      await count("SELECT COUNT(*) as c FROM operations WHERE type='reversal'"),
      1,
    );
  });

  test('REV-PUR-CONC-EQ. Concurrent equivalent purchase reverse → both AppOk, '
      'one mirror ledger, one reversal event, lifecycle once', () async {
    final cert = await makeCert('pur-conc-eq-cert');
    final results = await Future.wait([
      revPurch1.execute(
        certificateId: cert.id,
        householdId: _hh,
        idempotencyKey: 'pur-conc-eq',
        reason: 'same',
      ),
      revPurch2.execute(
        certificateId: cert.id,
        householdId: _hh,
        idempotencyKey: 'pur-conc-eq',
        reason: 'same',
      ),
    ]);
    expect(results.whereType<AppOk<void>>().length, 2);
    expect(results.whereType<AppDuplicateConflict<void>>(), isEmpty);
    expect(results.whereType<AppPersistenceFailure<void>>(), isEmpty);
    expect(
      await count("SELECT COUNT(*) as c FROM operations WHERE type='reversal'"),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM ledger_entries "
        "WHERE entry_type='reversalDebit'",
      ),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM ledger_entries "
        "WHERE entry_type='reversalCredit'",
      ),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM certificate_events "
        "WHERE event_type='purchaseReversed'",
      ),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM certificate_events "
        "WHERE event_type='archived'",
      ),
      1,
    );
    final lifecycle =
        (await db1
                .customSelect(
                  "SELECT lifecycle FROM savings_certificates WHERE id='${cert.id}'",
                )
                .get())
            .first
            .read<String>('lifecycle');
    expect(lifecycle, 'archived');
  });

  test(
    'REV-PUR-CONC-CF. Concurrent conflicting purchase reverse → '
    'exactly one AppOk + one AppDuplicateConflict, one financial reversal',
    () async {
      final cert = await makeCert('pur-conc-cf-cert');
      final results = await Future.wait([
        revPurch1.execute(
          certificateId: cert.id,
          householdId: _hh,
          idempotencyKey: 'pur-conc-cf',
          reason: 'reason-a',
        ),
        revPurch2.execute(
          certificateId: cert.id,
          householdId: _hh,
          idempotencyKey: 'pur-conc-cf',
          reason: 'reason-b',
        ),
      ]);
      expect(results.whereType<AppOk<void>>().length, 1);
      expect(results.whereType<AppDuplicateConflict<void>>().length, 1);
      expect(results.whereType<AppPersistenceFailure<void>>(), isEmpty);
      expect(
        await count(
          "SELECT COUNT(*) as c FROM operations WHERE type='reversal'",
        ),
        1,
      );
    },
  );

  test(
    'REV-PUR-NEVER-CF-EQ. Equivalent purchase reverse never AppDuplicateConflict',
    () async {
      final cert = await makeCert('pur-never-cf-cert');
      final r1 = await revPurch1.execute(
        certificateId: cert.id,
        householdId: _hh,
        idempotencyKey: 'pur-never-cf',
      );
      final r2 = await revPurch1.execute(
        certificateId: cert.id,
        householdId: _hh,
        idempotencyKey: 'pur-never-cf',
      );
      expect(r1, isA<AppOk<void>>());
      expect(r2, isA<AppOk<void>>());
      expect(r1, isNot(isA<AppDuplicateConflict<void>>()));
      expect(r2, isNot(isA<AppDuplicateConflict<void>>()));
    },
  );

  // ── Profit reversal ───────────────────────────────────────────────────────

  test('REV-PROF-SEQ-EQ. Sequential equivalent profit reverse → both AppOk; '
      'one op, ledger, context, cert event', () async {
    final cert = await makeMatureCert('prof-seq-eq-cert');
    final profit =
        ((await profit1.execute(
                  certificateId: cert.id,
                  householdId: _hh,
                  destinationAccountId: 'dst',
                  amountMinorUnits: 900,
                  idempotencyKey: 'prof-seq-eq-p',
                ))
                as AppOk<CertificateProfitReceipt>)
            .value;
    final r1 = await revProfit1.execute(
      certificateId: cert.id,
      householdId: _hh,
      originalProfitOperationId: profit.incomeOperationId,
      idempotencyKey: 'prof-seq-eq',
      reason: 'same',
    );
    final r2 = await revProfit1.execute(
      certificateId: cert.id,
      householdId: _hh,
      originalProfitOperationId: profit.incomeOperationId,
      idempotencyKey: 'prof-seq-eq',
      reason: 'same',
    );
    expect(r1, isA<AppOk<void>>());
    expect(r2, isA<AppOk<void>>());
    expect(r2, isNot(isA<AppDuplicateConflict<void>>()));
    expect(
      await count("SELECT COUNT(*) as c FROM operations WHERE type='reversal'"),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM ledger_entries "
        "WHERE entry_type='reversalDebit'",
      ),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM operation_contexts oc "
        "JOIN operations o ON o.id = oc.operation_id WHERE o.type='reversal'",
      ),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM certificate_events "
        "WHERE event_type='profitReversed'",
      ),
      1,
    );
  });

  test('REV-PROF-SEQ-CF. Sequential conflicting profit reverse → '
      'AppOk then AppDuplicateConflict; no second reversal', () async {
    final cert = await makeMatureCert('prof-seq-cf-cert');
    final profit =
        ((await profit1.execute(
                  certificateId: cert.id,
                  householdId: _hh,
                  destinationAccountId: 'dst',
                  amountMinorUnits: 700,
                  idempotencyKey: 'prof-seq-cf-p',
                ))
                as AppOk<CertificateProfitReceipt>)
            .value;
    final r1 = await revProfit1.execute(
      certificateId: cert.id,
      householdId: _hh,
      originalProfitOperationId: profit.incomeOperationId,
      idempotencyKey: 'prof-seq-cf',
      reason: 'a',
    );
    final r2 = await revProfit1.execute(
      certificateId: cert.id,
      householdId: _hh,
      originalProfitOperationId: profit.incomeOperationId,
      idempotencyKey: 'prof-seq-cf',
      reason: 'b',
    );
    expect(r1, isA<AppOk<void>>());
    expect(r2, isA<AppDuplicateConflict<void>>());
    expect(
      await count("SELECT COUNT(*) as c FROM operations WHERE type='reversal'"),
      1,
    );
  });

  test('REV-PROF-CONC-EQ. Concurrent equivalent profit reverse → both AppOk, '
      'one financial reversal', () async {
    final cert = await makeMatureCert('prof-conc-eq-cert');
    final profit =
        ((await profit1.execute(
                  certificateId: cert.id,
                  householdId: _hh,
                  destinationAccountId: 'dst',
                  amountMinorUnits: 600,
                  idempotencyKey: 'prof-conc-eq-p',
                ))
                as AppOk<CertificateProfitReceipt>)
            .value;
    final results = await Future.wait([
      revProfit1.execute(
        certificateId: cert.id,
        householdId: _hh,
        originalProfitOperationId: profit.incomeOperationId,
        idempotencyKey: 'prof-conc-eq',
        reason: 'same',
      ),
      revProfit2.execute(
        certificateId: cert.id,
        householdId: _hh,
        originalProfitOperationId: profit.incomeOperationId,
        idempotencyKey: 'prof-conc-eq',
        reason: 'same',
      ),
    ]);
    expect(results.whereType<AppOk<void>>().length, 2);
    expect(results.whereType<AppDuplicateConflict<void>>(), isEmpty);
    expect(results.whereType<AppPersistenceFailure<void>>(), isEmpty);
    expect(
      await count("SELECT COUNT(*) as c FROM operations WHERE type='reversal'"),
      1,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM certificate_events "
        "WHERE event_type='profitReversed'",
      ),
      1,
    );
  });

  test('REV-PROF-CONC-CF. Concurrent conflicting profit reverse → '
      'exactly one AppOk + one AppDuplicateConflict, one reversal', () async {
    final cert = await makeMatureCert('prof-conc-cf-cert');
    final profit =
        ((await profit1.execute(
                  certificateId: cert.id,
                  householdId: _hh,
                  destinationAccountId: 'dst',
                  amountMinorUnits: 550,
                  idempotencyKey: 'prof-conc-cf-p',
                ))
                as AppOk<CertificateProfitReceipt>)
            .value;
    final results = await Future.wait([
      revProfit1.execute(
        certificateId: cert.id,
        householdId: _hh,
        originalProfitOperationId: profit.incomeOperationId,
        idempotencyKey: 'prof-conc-cf',
        reason: 'a',
      ),
      revProfit2.execute(
        certificateId: cert.id,
        householdId: _hh,
        originalProfitOperationId: profit.incomeOperationId,
        idempotencyKey: 'prof-conc-cf',
        reason: 'b',
      ),
    ]);
    expect(results.whereType<AppOk<void>>().length, 1);
    expect(results.whereType<AppDuplicateConflict<void>>().length, 1);
    expect(results.whereType<AppPersistenceFailure<void>>(), isEmpty);
    expect(
      await count("SELECT COUNT(*) as c FROM operations WHERE type='reversal'"),
      1,
    );
  });

  test(
    'REV-PROF-FAIL-RETRY. Failure then retry equivalent profit reverse succeeds once',
    () async {
      final cert = await makeMatureCert('prof-fail-retry-cert');
      final profit =
          ((await profit1.execute(
                    certificateId: cert.id,
                    householdId: _hh,
                    destinationAccountId: 'dst',
                    amountMinorUnits: 400,
                    idempotencyKey: 'prof-fail-retry-p',
                  ))
                  as AppOk<CertificateProfitReceipt>)
              .value;
      final failing = DriftCertificateRepository(
        db1,
        debugFailAfter: CertificateFailAfter.operationInsert,
      );
      final failUc = ReverseCertificateProfitUseCase(failing);
      final fail = await failUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        originalProfitOperationId: profit.incomeOperationId,
        idempotencyKey: 'prof-fail-retry',
        reason: 'same',
      );
      expect(fail, isA<AppPersistenceFailure<void>>());
      expect(
        await count(
          "SELECT COUNT(*) as c FROM certificate_events "
          "WHERE event_type='profitReversed'",
        ),
        0,
      );

      final ok = await revProfit1.execute(
        certificateId: cert.id,
        householdId: _hh,
        originalProfitOperationId: profit.incomeOperationId,
        idempotencyKey: 'prof-fail-retry',
        reason: 'same',
      );
      expect(ok, isA<AppOk<void>>());
      expect(
        await count(
          "SELECT COUNT(*) as c FROM operations WHERE type='reversal'",
        ),
        1,
      );
      expect(
        await count(
          "SELECT COUNT(*) as c FROM certificate_events "
          "WHERE event_type='profitReversed'",
        ),
        1,
      );
    },
  );

  test(
    'REV-PUR-FAIL-RETRY. Failure then retry equivalent purchase reverse succeeds once',
    () async {
      final cert = await makeCert('pur-fail-retry-cert');
      final failing = DriftCertificateRepository(
        db1,
        debugFailAfter: CertificateFailAfter.eventInsert,
      );
      final failUc = ReverseCertificatePurchaseUseCase(failing);
      final fail = await failUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        idempotencyKey: 'pur-fail-retry',
        reason: 'same',
      );
      expect(fail, isA<AppPersistenceFailure<void>>());
      expect(
        await count(
          "SELECT COUNT(*) as c FROM certificate_events "
          "WHERE event_type='purchaseReversed'",
        ),
        0,
      );
      final still =
          (await certs1.findById(cert.id) as AppOk<SavingsCertificate?>).value!;
      expect(still.lifecycle, CertificateLifecycle.active);

      final ok = await revPurch1.execute(
        certificateId: cert.id,
        householdId: _hh,
        idempotencyKey: 'pur-fail-retry',
        reason: 'same',
      );
      expect(ok, isA<AppOk<void>>());
      expect(
        await count(
          "SELECT COUNT(*) as c FROM operations WHERE type='reversal'",
        ),
        1,
      );
    },
  );
}
