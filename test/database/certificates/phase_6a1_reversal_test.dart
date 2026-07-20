/// Phase 6A.1 — REV-PUR / REV-PROF / REV-REDEEM-REJECT.
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

const _hh = 'hh-6a1-rev';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accounts;
  late DriftLedgerRepository ledger;
  late DriftCertificateRepository certs;
  late CreateCertificateUseCase createUc;
  late RecordCertificateProfitUseCase profitUc;
  late RedeemCertificateUseCase redeemUc;
  late ReverseCertificatePurchaseUseCase reversePurchaseUc;
  late ReverseCertificateProfitUseCase reverseProfitUc;
  late ReverseCertificateRedemptionUseCase reverseRedeemUc;

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
    reversePurchaseUc = ReverseCertificatePurchaseUseCase(certs);
    reverseProfitUc = ReverseCertificateProfitUseCase(certs);
    reverseRedeemUc = ReverseCertificateRedemptionUseCase(certs);
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

  Future<int> bal(String id) async =>
      (await db
              .customSelect(
                "SELECT COALESCE(SUM(CASE WHEN direction = 'credit' "
                'THEN amount_minor_units ELSE -amount_minor_units END), 0) AS bal '
                "FROM ledger_entries WHERE account_id = '$id'",
              )
              .get())
          .first
          .read<int>('bal');

  Future<SavingsCertificate> makeCert(
    String ikey, {
    int principal = 40000,
  }) async {
    await createAcct('src-$ikey');
    await createAcct('dst-$ikey');
    await credit('src-$ikey', 200000);
    final r = await createUc.execute(
      householdId: _hh,
      institutionName: 'Bank',
      currencyCode: 'EGP',
      principalMinorUnits: principal,
      startDate: '2019-01-01',
      maturityDate: '2020-01-01',
      sourceAccountId: 'src-$ikey',
      idempotencyKey: ikey,
    );
    return (r as AppOk<SavingsCertificate>).value;
  }

  test(
    'REV-PUR-1. Purchase reversal archives and restores source balance',
    () async {
      final cert = await makeCert('rev-p1');
      final srcBefore = await bal('src-rev-p1');
      final result = await reversePurchaseUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        idempotencyKey: 'rev-pur-1',
      );
      expect(result, isA<AppOk<void>>());
      final updated =
          (await certs.findById(cert.id) as AppOk<SavingsCertificate?>).value!;
      expect(updated.lifecycle, CertificateLifecycle.archived);
      expect(await bal('src-rev-p1'), srcBefore + 40000);
      expect(await bal(cert.certificateAccountId), 0);
    },
  );

  test('REV-PUR-2. Rejected when profit history exists', () async {
    final cert = await makeCert('rev-p2');
    await profitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-rev-p2',
      amountMinorUnits: 100,
      idempotencyKey: 'prof-block',
    );
    final result = await reversePurchaseUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      idempotencyKey: 'rev-pur-2',
    );
    expect(result, isA<AppValidationFailure<void>>());
  });

  for (final entry in <(String, CertificateFailAfter)>[
    ('REV-PUR-ROLL-1', CertificateFailAfter.operationInsert),
    ('REV-PUR-ROLL-2', CertificateFailAfter.firstLedgerEntry),
    ('REV-PUR-ROLL-3', CertificateFailAfter.eventInsert),
    ('REV-PUR-ROLL-4', CertificateFailAfter.lifecycleUpdate),
    ('REV-PUR-ROLL-5', CertificateFailAfter.preCommit),
  ]) {
    test('${entry.$1}. Fail after ${entry.$2.name} → still active', () async {
      final cert = await makeCert(entry.$1);
      final srcBefore = await bal('src-${entry.$1}');
      wire(failAfter: entry.$2);
      final failing = await reversePurchaseUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        idempotencyKey: 'roll-${entry.$1}',
      );
      expect(failing, isA<AppPersistenceFailure<void>>());
      final still =
          (await DriftCertificateRepository(db).findById(cert.id)
                  as AppOk<SavingsCertificate?>)
              .value!;
      expect(still.lifecycle, CertificateLifecycle.active);
      expect(await bal(cert.certificateAccountId), 40000);
      expect(await bal('src-${entry.$1}'), srcBefore);

      wire();
      final ok = await reversePurchaseUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        idempotencyKey: 'roll-${entry.$1}',
      );
      expect(ok, isA<AppOk<void>>());
    });
  }

  test('REV-PROF-1. Profit reversal restores destination balance', () async {
    final cert = await makeCert('rev-f1');
    final profit = await profitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-rev-f1',
      amountMinorUnits: 2500,
      idempotencyKey: 'prof-f1',
    );
    final opId =
        (profit as AppOk<CertificateProfitReceipt>).value.incomeOperationId;
    final dstBefore = await bal('dst-rev-f1');
    final result = await reverseProfitUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      originalProfitOperationId: opId,
      idempotencyKey: 'rev-prof-1',
    );
    expect(result, isA<AppOk<void>>());
    expect(await bal('dst-rev-f1'), dstBefore - 2500);
  });

  for (final entry in <(String, CertificateFailAfter)>[
    ('REV-PROF-ROLL-1', CertificateFailAfter.operationInsert),
    ('REV-PROF-ROLL-2', CertificateFailAfter.firstLedgerEntry),
    ('REV-PROF-ROLL-3', CertificateFailAfter.eventInsert),
    ('REV-PROF-ROLL-4', CertificateFailAfter.preCommit),
  ]) {
    test('${entry.$1}. Fail after ${entry.$2.name}', () async {
      final cert = await makeCert(entry.$1);
      final profit = await profitUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        destinationAccountId: 'dst-${entry.$1}',
        amountMinorUnits: 900,
        idempotencyKey: 'prof-${entry.$1}',
      );
      final opId =
          (profit as AppOk<CertificateProfitReceipt>).value.incomeOperationId;
      final dstBefore = await bal('dst-${entry.$1}');
      wire(failAfter: entry.$2);
      final failing = await reverseProfitUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        originalProfitOperationId: opId,
        idempotencyKey: 'rev-${entry.$1}',
      );
      expect(failing, isA<AppPersistenceFailure<void>>());
      expect(await bal('dst-${entry.$1}'), dstBefore);
      wire();
      final ok = await reverseProfitUc.execute(
        certificateId: cert.id,
        householdId: _hh,
        originalProfitOperationId: opId,
        idempotencyKey: 'rev-${entry.$1}',
      );
      expect(ok, isA<AppOk<void>>());
    });
  }

  test('REV-REDEEM-REJECT-1. Use case rejects redemption reversal', () async {
    final cert = await makeCert('rev-r1', principal: 15000);
    await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-rev-r1',
      principalMinorUnits: 15000,
      idempotencyKey: 'redeem-r1',
    );
    final result = await reverseRedeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
    );
    expect(result, isA<AppValidationFailure<void>>());
  });

  test('REV-REDEEM-REJECT-2. Repository rejects redemption reversal', () async {
    final cert = await makeCert('rev-r2', principal: 11000);
    await redeemUc.execute(
      certificateId: cert.id,
      householdId: _hh,
      destinationAccountId: 'dst-rev-r2',
      principalMinorUnits: 11000,
      idempotencyKey: 'redeem-r2',
    );
    final result = await certs.reverseRedemption(
      certificateId: cert.id,
      householdId: _hh,
    );
    expect(result, isA<AppValidationFailure<void>>());
  });
}
