/// Phase 6A.1 — CERT-EVT SQL bypass integrity for certificate events.
library;

import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/certificates/application/certificate_use_cases.dart';
import 'package:family_money_manager/features/certificates/data/drift_certificate_repository.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-6a1-evt';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accounts;
  late DriftLedgerRepository ledger;
  late CreateCertificateUseCase createUc;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accounts = DriftAccountRepository(db);
    ledger = DriftLedgerRepository(db);
    createUc = CreateCertificateUseCase(
      certRepository: DriftCertificateRepository(db),
      accountRepository: accounts,
    );
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
        operationId: 'inc-$id-$amount',
        householdId: _hh,
        destinationAccountId: id,
        amountMinorUnits: amount,
        currencyCode: 'EGP',
        effectiveDate: '2024-01-01',
        createdBy: 'test',
      ),
    );
  }

  Future<SavingsCertificate> seedCert() async {
    await createAcct('src');
    await createAcct('dst');
    await credit('src', 200000);
    final r = await createUc.execute(
      householdId: _hh,
      institutionName: 'Bank',
      currencyCode: 'EGP',
      principalMinorUnits: 50000,
      startDate: '2019-01-01',
      maturityDate: '2020-01-01',
      sourceAccountId: 'src',
      idempotencyKey: 'ik-evt',
    );
    return (r as AppOk<SavingsCertificate>).value;
  }

  Future<void> expectAbort(Future<void> Function() body) async {
    await expectLater(body, throwsA(anything));
  }

  test('CERT-EVT-1. Purchase event rejects wrong operation type', () async {
    final cert = await seedCert();
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "destination_account_id, source_account_id) "
        "VALUES ('bad-op', '$_hh', 'transfer', '2025-01-01', '2025-01-01T00:00:00Z', "
        "100, 'EGP', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', "
        "'${cert.certificateAccountId}', 'src')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('bad-d', 'bad-op', '$_hh', 'src', 'debit', 100, 'EGP', 'transferOut', "
        "'2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('bad-c', 'bad-op', '$_hh', '${cert.certificateAccountId}', 'credit', 100, "
        "'EGP', 'transferIn', '2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO certificate_events "
        "(id, certificate_id, household_id, event_type, related_operation_id, "
        "amount_minor_units, currency_code, effective_at, created_at, schema_version) "
        "VALUES ('e1', '${cert.id}', '$_hh', 'purchased', 'bad-op', 100, 'EGP', "
        "'2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', 1)",
      );
    });
  });

  test('CERT-EVT-2. Redemption event rejects destination = certificate', () async {
    final cert = await seedCert();
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "destination_account_id, source_account_id) "
        "VALUES ('bad-red', '$_hh', 'certificateMaturity', '2025-01-01', '2025-01-01T00:00:00Z', "
        "50000, 'EGP', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', "
        "'${cert.certificateAccountId}', '${cert.certificateAccountId}')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('br-d', 'bad-red', '$_hh', '${cert.certificateAccountId}', 'debit', 50000, "
        "'EGP', 'transferOut', '2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('br-c', 'bad-red', '$_hh', '${cert.certificateAccountId}', 'credit', 50000, "
        "'EGP', 'transferIn', '2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO certificate_events "
        "(id, certificate_id, household_id, event_type, related_operation_id, "
        "amount_minor_units, currency_code, effective_at, created_at, schema_version) "
        "VALUES ('e2', '${cert.id}', '$_hh', 'redeemed', 'bad-red', 50000, 'EGP', "
        "'2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', 1)",
      );
    });
  });

  test('CERT-EVT-3. Profit event rejects wrong category', () async {
    final cert = await seedCert();
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "destination_account_id, category_code) "
        "VALUES ('bad-p', '$_hh', 'income', '2025-01-01', '2025-01-01T00:00:00Z', "
        "100, 'EGP', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', 'dst', 'salary')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('bp-c', 'bad-p', '$_hh', 'dst', 'credit', 100, 'EGP', 'income', "
        "'2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO certificate_events "
        "(id, certificate_id, household_id, event_type, related_operation_id, "
        "amount_minor_units, currency_code, effective_at, created_at, schema_version) "
        "VALUES ('e3', '${cert.id}', '$_hh', 'profitReceived', 'bad-p', 100, 'EGP', "
        "'2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', 1)",
      );
    });
  });

  test('CERT-EVT-4. Profit event rejects destination = certificate', () async {
    final cert = await seedCert();
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "destination_account_id, category_code) "
        "VALUES ('bad-pc', '$_hh', 'income', '2025-01-01', '2025-01-01T00:00:00Z', "
        "100, 'EGP', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', "
        "'${cert.certificateAccountId}', 'certificate_profit')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('bpc', 'bad-pc', '$_hh', '${cert.certificateAccountId}', 'credit', 100, "
        "'EGP', 'income', '2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO certificate_events "
        "(id, certificate_id, household_id, event_type, related_operation_id, "
        "amount_minor_units, currency_code, effective_at, created_at, schema_version) "
        "VALUES ('e4', '${cert.id}', '$_hh', 'profitReceived', 'bad-pc', 100, 'EGP', "
        "'2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', 1)",
      );
    });
  });

  test('CERT-EVT-5. Cross-household event rejected', () async {
    final cert = await seedCert();
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('hh-x', 'X', 'u2', '2024-01-01', '2024-01-01')",
    );
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO certificate_events "
        "(id, certificate_id, household_id, event_type, related_operation_id, "
        "amount_minor_units, currency_code, effective_at, created_at, schema_version) "
        "VALUES ('e5', '${cert.id}', 'hh-x', 'created', NULL, NULL, NULL, "
        "'2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', 1)",
      );
    });
  });

  test('CERT-EVT-6. Events are append-only (UPDATE rejected)', () async {
    final cert = await seedCert();
    final rows = await db
        .customSelect(
          'SELECT id FROM certificate_events WHERE certificate_id = ? LIMIT 1',
          variables: [Variable.withString(cert.id)],
        )
        .get();
    final id = rows.first.read<String>('id');
    await expectAbort(() async {
      await db.customStatement(
        "UPDATE certificate_events SET note = 'hacked' WHERE id = '$id'",
      );
    });
  });

  test('CERT-EVT-7. Events cannot be deleted', () async {
    final cert = await seedCert();
    final rows = await db
        .customSelect(
          'SELECT id FROM certificate_events WHERE certificate_id = ? LIMIT 1',
          variables: [Variable.withString(cert.id)],
        )
        .get();
    final id = rows.first.read<String>('id');
    await expectAbort(() async {
      await db.customStatement(
        "DELETE FROM certificate_events WHERE id = '$id'",
      );
    });
  });

  test('CERT-EVT-8. Revisions are append-only (UPDATE rejected)', () async {
    final cert = await seedCert();
    await expectAbort(() async {
      await db.customStatement(
        "UPDATE certificate_revisions SET institution_name = 'Hacked' "
        "WHERE certificate_id = '${cert.id}'",
      );
    });
  });
}
