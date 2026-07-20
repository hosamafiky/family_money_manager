/// Phase 6A.1 — CREATE-ROLL / PROFIT-ROLL / REDEEM-ROLL matrices.
library;

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

const _hh = 'hh-6a1-roll';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accounts;
  late DriftLedgerRepository ledger;
  late DriftCertificateRepository certs;
  late CreateCertificateUseCase createUc;
  late RecordCertificateProfitUseCase profitUc;
  late RedeemCertificateUseCase redeemUc;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  void wire({CertificateFailAfter failAfter = CertificateFailAfter.none}) {
    certs = DriftCertificateRepository(db, debugFailAfter: failAfter);
    createUc = CreateCertificateUseCase(
      certRepository: certs,
      accountRepository: accounts,
    );
    profitUc = RecordCertificateProfitUseCase(
      certRepository: certs,
      accountRepository: accounts,
    );
    redeemUc = RedeemCertificateUseCase(
      certRepository: certs,
      accountRepository: accounts,
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting();
    accounts = DriftAccountRepository(db);
    ledger = DriftLedgerRepository(db);
    wire();
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'HH', 'u1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<void> createAcct(String id) async {
    await accounts.createAccount(
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
        displayOrder: 0,
        createdBy: 'test',
      ),
    );
  }

  Future<void> credit(String id, int amount) async {
    await ledger.recordIncome(
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

  Future<int> bal(String accountId) async =>
      (await db
              .customSelect(
                "SELECT COALESCE(SUM(CASE WHEN direction = 'credit' "
                'THEN amount_minor_units ELSE -amount_minor_units END), 0) AS bal '
                "FROM ledger_entries WHERE account_id = '$accountId'",
              )
              .get())
          .first
          .read<int>('bal');

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).get()).first.read<int>('c');

  Future<void> assertNoCertificateResidue({
    required String srcId,
    required int srcBefore,
  }) async {
    expect(await count('SELECT COUNT(*) as c FROM savings_certificates'), 0);
    expect(
      await count(
        "SELECT COUNT(*) as c FROM financial_accounts WHERE type = 'certificate'",
      ),
      0,
    );
    expect(await count('SELECT COUNT(*) as c FROM certificate_revisions'), 0);
    expect(await count('SELECT COUNT(*) as c FROM certificate_events'), 0);
    expect(
      await count(
        "SELECT COUNT(*) as c FROM operations WHERE type = 'certificateFunding'",
      ),
      0,
    );
    expect(await bal(srcId), srcBefore);
  }

  Future<SavingsCertificate> makeCert({
    required String src,
    required String ikey,
    int principal = 50000,
    String maturity = '2020-01-01',
  }) async {
    final r = await createUc.execute(
      householdId: _hh,
      institutionName: 'Bank-$ikey',
      currencyCode: 'EGP',
      principalMinorUnits: principal,
      startDate: '2019-01-01',
      maturityDate: maturity,
      sourceAccountId: src,
      idempotencyKey: ikey,
    );
    expect(r, isA<AppOk<SavingsCertificate>>());
    return (r as AppOk<SavingsCertificate>).value;
  }

  // ── CREATE-ROLL-1..11 ─────────────────────────────────────────────────────

  for (final entry in <(String, CertificateFailAfter)>[
    ('CREATE-ROLL-1', CertificateFailAfter.idempotencyLookup),
    ('CREATE-ROLL-2', CertificateFailAfter.accountInsert),
    ('CREATE-ROLL-3', CertificateFailAfter.certificateInsert),
    ('CREATE-ROLL-4', CertificateFailAfter.revisionInsert),
    ('CREATE-ROLL-5', CertificateFailAfter.operationInsert),
    ('CREATE-ROLL-6', CertificateFailAfter.firstLedgerEntry),
    ('CREATE-ROLL-7', CertificateFailAfter.secondLedgerEntry),
    ('CREATE-ROLL-8', CertificateFailAfter.operationContext),
    ('CREATE-ROLL-9', CertificateFailAfter.createdEvent),
    ('CREATE-ROLL-10', CertificateFailAfter.purchasedEvent),
    ('CREATE-ROLL-11', CertificateFailAfter.preCommit),
  ]) {
    test(
      '${entry.$1}. Fail after ${entry.$2.name} → absence; retry once',
      () async {
        final src = 'src-${entry.$1}';
        await createAcct(src);
        await credit(src, 200000);
        final before = await bal(src);
        final ikey = 'ik-${entry.$1}';

        wire(failAfter: entry.$2);
        final failing = await createUc.execute(
          householdId: _hh,
          institutionName: 'Bank',
          currencyCode: 'EGP',
          principalMinorUnits: 40000,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          sourceAccountId: src,
          idempotencyKey: ikey,
        );
        expect(failing, isA<AppPersistenceFailure<SavingsCertificate>>());
        await assertNoCertificateResidue(srcId: src, srcBefore: before);

        wire();
        final ok = await createUc.execute(
          householdId: _hh,
          institutionName: 'Bank',
          currencyCode: 'EGP',
          principalMinorUnits: 40000,
          startDate: '2025-01-01',
          maturityDate: '2026-01-01',
          sourceAccountId: src,
          idempotencyKey: ikey,
        );
        expect(ok, isA<AppOk<SavingsCertificate>>());
        expect(
          await count('SELECT COUNT(*) as c FROM savings_certificates'),
          1,
        );
        expect(
          await count(
            "SELECT COUNT(*) as c FROM operations WHERE type = 'certificateFunding'",
          ),
          1,
        );
        expect(await bal(src), before - 40000);
      },
    );
  }

  // ── PROFIT-ROLL / PROFIT-IDMP ──────────────────────────────────────────────

  for (final entry in <(String, CertificateFailAfter)>[
    ('PROFIT-ROLL-1', CertificateFailAfter.idempotencyLookup),
    ('PROFIT-ROLL-2', CertificateFailAfter.operationInsert),
    ('PROFIT-ROLL-3', CertificateFailAfter.firstLedgerEntry),
    ('PROFIT-ROLL-4', CertificateFailAfter.operationContext),
    ('PROFIT-ROLL-5', CertificateFailAfter.eventInsert),
    ('PROFIT-ROLL-6', CertificateFailAfter.preCommit),
  ]) {
    test(
      '${entry.$1}. Fail after ${entry.$2.name} → no orphan income/event',
      () async {
        await createAcct('src-p');
        await createAcct('dst-p');
        await credit('src-p', 100000);
        final cert = await makeCert(src: 'src-p', ikey: 'ik-${entry.$1}');
        final dstBefore = await bal('dst-p');
        final eventsBefore = await count(
          "SELECT COUNT(*) as c FROM certificate_events "
          "WHERE certificate_id = '${cert.id}'",
        );
        final incomeBefore = await count(
          "SELECT COUNT(*) as c FROM operations WHERE type = 'income' "
          "AND category_code = 'certificate_profit'",
        );

        wire(failAfter: entry.$2);
        final failing = await profitUc.execute(
          certificateId: cert.id,
          householdId: _hh,
          destinationAccountId: 'dst-p',
          amountMinorUnits: 1500,
          idempotencyKey: 'profit-${entry.$1}',
        );
        expect(failing, isA<AppPersistenceFailure<CertificateProfitReceipt>>());
        expect(await bal('dst-p'), dstBefore);
        expect(
          await count(
            "SELECT COUNT(*) as c FROM certificate_events "
            "WHERE certificate_id = '${cert.id}'",
          ),
          eventsBefore,
        );
        expect(
          await count(
            "SELECT COUNT(*) as c FROM operations WHERE type = 'income' "
            "AND category_code = 'certificate_profit'",
          ),
          incomeBefore,
        );

        wire();
        final ok = await profitUc.execute(
          certificateId: cert.id,
          householdId: _hh,
          destinationAccountId: 'dst-p',
          amountMinorUnits: 1500,
          idempotencyKey: 'profit-${entry.$1}',
        );
        expect(ok, isA<AppOk<CertificateProfitReceipt>>());
        expect(await bal('dst-p'), dstBefore + 1500);
      },
    );
  }

  test('PROFIT-IDMP-1. Equivalent retry returns same receipt', () async {
    await createAcct('src-pi');
    await createAcct('dst-pi');
    await credit('src-pi', 100000);
    final cert = await makeCert(src: 'src-pi', ikey: 'ik-pi1');
    final r1 = await profitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-pi',
      amountMinorUnits: 2000,
      idempotencyKey: 'ik-profit-eq',
    );
    final r2 = await profitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-pi',
      amountMinorUnits: 2000,
      idempotencyKey: 'ik-profit-eq',
    );
    expect(r1, isA<AppOk<CertificateProfitReceipt>>());
    expect(r2, isA<AppOk<CertificateProfitReceipt>>());
    expect(
      (r1 as AppOk<CertificateProfitReceipt>).value.incomeOperationId,
      (r2 as AppOk<CertificateProfitReceipt>).value.incomeOperationId,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM operations WHERE type = 'income' "
        "AND category_code = 'certificate_profit'",
      ),
      1,
    );
  });

  test('PROFIT-IDMP-2. Conflicting retry → AppDuplicateConflict', () async {
    await createAcct('src-pc');
    await createAcct('dst-pc');
    await credit('src-pc', 100000);
    final cert = await makeCert(src: 'src-pc', ikey: 'ik-pc');
    await profitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-pc',
      amountMinorUnits: 1000,
      idempotencyKey: 'ik-profit-conflict',
    );
    final conflict = await profitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-pc',
      amountMinorUnits: 9999,
      idempotencyKey: 'ik-profit-conflict',
    );
    expect(conflict, isA<AppDuplicateConflict<CertificateProfitReceipt>>());
  });

  test('PROFIT-IDMP-3. Same key in another household is isolated', () async {
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('hh-other', 'O', 'u2', '2024-01-01', '2024-01-01')",
    );
    await createAcct('src-x');
    await createAcct('dst-x');
    await credit('src-x', 100000);
    final cert = await makeCert(src: 'src-x', ikey: 'ik-x');
    await profitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-x',
      amountMinorUnits: 500,
      idempotencyKey: 'shared-profit-key',
    );

    // Seed other HH account and cert via SQL-free create path in other HH.
    await accounts.createAccount(
      const CreateAccountParams(
        id: 'src-o',
        householdId: 'hh-other',
        name: 'src-o',
        type: FinancialAccountType.bankAccount,
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
    await accounts.createAccount(
      const CreateAccountParams(
        id: 'dst-o',
        householdId: 'hh-other',
        name: 'dst-o',
        type: FinancialAccountType.bankAccount,
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
    await ledger.recordIncome(
      RecordIncomeParams(
        operationId: 'inc-o',
        householdId: 'hh-other',
        destinationAccountId: 'src-o',
        amountMinorUnits: 100000,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'test',
      ),
    );
    final otherCreate = CreateCertificateUseCase(
      certRepository: certs,
      accountRepository: accounts,
    );
    final otherCert = await otherCreate.execute(
      householdId: 'hh-other',
      institutionName: 'Other',
      currencyCode: 'EGP',
      principalMinorUnits: 10000,
      startDate: '2019-01-01',
      maturityDate: '2020-01-01',
      sourceAccountId: 'src-o',
      idempotencyKey: 'ik-other-cert',
    );
    final other = (otherCert as AppOk<SavingsCertificate>).value;
    final ok = await profitUc.execute(
      certificateId: other.id,
      householdId: 'hh-other',
      destinationAccountId: 'dst-o',
      amountMinorUnits: 500,
      idempotencyKey: 'shared-profit-key',
    );
    expect(ok, isA<AppOk<CertificateProfitReceipt>>());
  });

  // ── REDEEM-ROLL / REDEEM-IDMP ──────────────────────────────────────────────

  Future<void> assertStillActiveWithPrincipal(
    SavingsCertificate cert,
    int principal,
  ) async {
    final found = await certs.findById(cert.id);
    final c = (found as AppOk<SavingsCertificate?>).value!;
    expect(c.lifecycle, CertificateLifecycle.active);
    expect(c.redeemedAt, isNull);
    expect(await bal(cert.certificateAccountId), principal);
  }

  for (final entry in <(String, CertificateFailAfter)>[
    ('REDEEM-ROLL-1', CertificateFailAfter.idempotencyLookup),
    ('REDEEM-ROLL-2', CertificateFailAfter.operationInsert),
    ('REDEEM-ROLL-3', CertificateFailAfter.firstLedgerEntry),
    ('REDEEM-ROLL-4', CertificateFailAfter.secondLedgerEntry),
    ('REDEEM-ROLL-5', CertificateFailAfter.operationContext),
    ('REDEEM-ROLL-6', CertificateFailAfter.lifecycleUpdate),
    ('REDEEM-ROLL-7', CertificateFailAfter.eventInsert),
    ('REDEEM-ROLL-8', CertificateFailAfter.preCommit),
  ]) {
    test('${entry.$1}. Principal-only fail after ${entry.$2.name}', () async {
      await createAcct('src-r');
      await createAcct('dst-r');
      await credit('src-r', 100000);
      final cert = await makeCert(
        src: 'src-r',
        ikey: 'ik-${entry.$1}',
        principal: 30000,
      );
      final dstBefore = await bal('dst-r');

      wire(failAfter: entry.$2);
      final failing = await redeemUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst-r',
        principalMinorUnits: 30000,
        idempotencyKey: 'redeem-${entry.$1}',
      );
      expect(
        failing,
        isA<AppPersistenceFailure<CertificateRedemptionSummary>>(),
      );
      await assertStillActiveWithPrincipal(cert, 30000);
      expect(await bal('dst-r'), dstBefore);

      wire();
      final ok = await redeemUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst-r',
        principalMinorUnits: 30000,
        idempotencyKey: 'redeem-${entry.$1}',
      );
      expect(ok, isA<AppOk<CertificateRedemptionSummary>>());
      final updated =
          (await certs.findById(cert.id) as AppOk<SavingsCertificate?>).value!;
      expect(updated.lifecycle, CertificateLifecycle.redeemed);
      expect(updated.redeemedAt, isNotNull);
      expect(await bal(cert.certificateAccountId), 0);
      expect(await bal('dst-r'), dstBefore + 30000);
    });
  }

  for (final entry in <(String, CertificateFailAfter)>[
    ('REDEEM-ROLL-P1', CertificateFailAfter.profitOperationInsert),
    ('REDEEM-ROLL-P2', CertificateFailAfter.profitLedgerEntry),
    ('REDEEM-ROLL-P3', CertificateFailAfter.profitContext),
    ('REDEEM-ROLL-P4', CertificateFailAfter.profitEventInsert),
  ]) {
    test('${entry.$1}. Principal+profit fail after ${entry.$2.name}', () async {
      await createAcct('src-rp');
      await createAcct('dst-rp');
      await credit('src-rp', 100000);
      final cert = await makeCert(
        src: 'src-rp',
        ikey: 'ik-${entry.$1}',
        principal: 25000,
      );
      final dstBefore = await bal('dst-rp');

      wire(failAfter: entry.$2);
      final failing = await redeemUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst-rp',
        principalMinorUnits: 25000,
        profitMinorUnits: 800,
        idempotencyKey: 'redeem-p-${entry.$1}',
      );
      expect(
        failing,
        isA<AppPersistenceFailure<CertificateRedemptionSummary>>(),
      );
      await assertStillActiveWithPrincipal(cert, 25000);
      expect(await bal('dst-rp'), dstBefore);

      wire();
      final ok = await redeemUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst-rp',
        principalMinorUnits: 25000,
        profitMinorUnits: 800,
        idempotencyKey: 'redeem-p-${entry.$1}',
      );
      expect(ok, isA<AppOk<CertificateRedemptionSummary>>());
      expect(await bal('dst-rp'), dstBefore + 25000 + 800);
    });
  }

  test('REDEEM-IDMP-1. Equivalent retry returns same redemption', () async {
    await createAcct('src-ri');
    await createAcct('dst-ri');
    await credit('src-ri', 100000);
    final cert = await makeCert(src: 'src-ri', ikey: 'ik-ri', principal: 10000);
    final r1 = await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-ri',
      principalMinorUnits: 10000,
      idempotencyKey: 'redeem-eq',
    );
    final r2 = await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-ri',
      principalMinorUnits: 10000,
      idempotencyKey: 'redeem-eq',
    );
    expect(r1, isA<AppOk<CertificateRedemptionSummary>>());
    expect(r2, isA<AppOk<CertificateRedemptionSummary>>());
    expect(
      (r1 as AppOk<CertificateRedemptionSummary>).value.principalOperationId,
      (r2 as AppOk<CertificateRedemptionSummary>).value.principalOperationId,
    );
    expect(
      await count(
        "SELECT COUNT(*) as c FROM operations WHERE type = 'certificateMaturity'",
      ),
      1,
    );
  });

  test('REDEEM-IDMP-2. Conflicting retry → AppDuplicateConflict', () async {
    await createAcct('src-rc');
    await createAcct('dst-rc');
    await credit('src-rc', 100000);
    final cert = await makeCert(src: 'src-rc', ikey: 'ik-rc', principal: 12000);
    await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-rc',
      principalMinorUnits: 12000,
      idempotencyKey: 'redeem-conflict',
    );
    final conflict = await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-rc',
      principalMinorUnits: 12000,
      profitMinorUnits: 1,
      idempotencyKey: 'redeem-conflict',
    );
    expect(conflict, isA<AppDuplicateConflict<CertificateRedemptionSummary>>());
  });
}
