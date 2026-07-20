/// Phase 6A.2 — Certificate-event balanced-operation SQL rejection tests.
///
/// These exercise DB triggers via raw SQL bypass. Application construction is
/// NOT classified as Database-tested here.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
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

const _hh = 'hh-6a2-bal';

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
    await credit('src', 300000);
    final r = await createUc.execute(
      householdId: _hh,
      institutionName: 'Bank',
      currencyCode: 'EGP',
      principalMinorUnits: 50000,
      startDate: '2019-01-01',
      maturityDate: '2020-01-01',
      sourceAccountId: 'src',
      idempotencyKey: 'ik-bal',
    );
    return (r as AppOk<SavingsCertificate>).value;
  }

  Future<void> expectAbort(Future<void> Function() body) async {
    await expectLater(body, throwsA(anything));
  }

  Future<void> insertPurchaseEvent({
    required SavingsCertificate cert,
    required String opId,
    required int amount,
    required String currency,
  }) async {
    await db.customStatement(
      "INSERT INTO certificate_events "
      "(id, certificate_id, household_id, event_type, related_operation_id, "
      "amount_minor_units, currency_code, effective_at, created_at, schema_version) "
      "VALUES ('evt-$opId', '${cert.id}', '$_hh', 'purchased', '$opId', $amount, "
      "'$currency', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', 1)",
    );
  }

  test('BAL-EVT-1. Missing debit leg rejected', () async {
    final cert = await seedCert();
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "destination_account_id, source_account_id) "
        "VALUES ('op-miss', '$_hh', 'certificateFunding', '2025-01-01', '2025-01-01T00:00:00Z', "
        "100, 'EGP', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', "
        "'${cert.certificateAccountId}', 'src')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('miss-c', 'op-miss', '$_hh', '${cert.certificateAccountId}', 'credit', 100, "
        "'EGP', 'transferIn', '2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await insertPurchaseEvent(
        cert: cert,
        opId: 'op-miss',
        amount: 100,
        currency: 'EGP',
      );
    });
  });

  test('BAL-EVT-2. Unequal legs rejected', () async {
    final cert = await seedCert();
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "destination_account_id, source_account_id) "
        "VALUES ('op-uneq', '$_hh', 'certificateFunding', '2025-01-01', '2025-01-01T00:00:00Z', "
        "100, 'EGP', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', "
        "'${cert.certificateAccountId}', 'src')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('uneq-d', 'op-uneq', '$_hh', 'src', 'debit', 100, 'EGP', 'transferOut', "
        "'2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('uneq-c', 'op-uneq', '$_hh', '${cert.certificateAccountId}', 'credit', 50, "
        "'EGP', 'transferIn', '2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await insertPurchaseEvent(
        cert: cert,
        opId: 'op-uneq',
        amount: 100,
        currency: 'EGP',
      );
    });
  });

  test('BAL-EVT-3. Wrong currency rejected', () async {
    final cert = await seedCert();
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "destination_account_id, source_account_id) "
        "VALUES ('op-cur', '$_hh', 'certificateFunding', '2025-01-01', '2025-01-01T00:00:00Z', "
        "100, 'USD', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', "
        "'${cert.certificateAccountId}', 'src')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('cur-d', 'op-cur', '$_hh', 'src', 'debit', 100, 'USD', 'transferOut', "
        "'2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('cur-c', 'op-cur', '$_hh', '${cert.certificateAccountId}', 'credit', 100, "
        "'USD', 'transferIn', '2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await insertPurchaseEvent(
        cert: cert,
        opId: 'op-cur',
        amount: 100,
        currency: 'EGP',
      );
    });
  });

  test('BAL-EVT-4. Wrong household on legs rejected', () async {
    final cert = await seedCert();
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('hh-other', 'O', 'u2', '2024-01-01', '2024-01-01')",
    );
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "destination_account_id, source_account_id) "
        "VALUES ('op-hh', '$_hh', 'certificateFunding', '2025-01-01', '2025-01-01T00:00:00Z', "
        "100, 'EGP', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', "
        "'${cert.certificateAccountId}', 'src')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('hh-d', 'op-hh', 'hh-other', 'src', 'debit', 100, 'EGP', 'transferOut', "
        "'2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('hh-c', 'op-hh', '$_hh', '${cert.certificateAccountId}', 'credit', 100, "
        "'EGP', 'transferIn', '2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await insertPurchaseEvent(
        cert: cert,
        opId: 'op-hh',
        amount: 100,
        currency: 'EGP',
      );
    });
  });

  test('BAL-EVT-5. Third leg rejected', () async {
    final cert = await seedCert();
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "destination_account_id, source_account_id) "
        "VALUES ('op-3', '$_hh', 'certificateFunding', '2025-01-01', '2025-01-01T00:00:00Z', "
        "100, 'EGP', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', "
        "'${cert.certificateAccountId}', 'src')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('t3-d', 'op-3', '$_hh', 'src', 'debit', 100, 'EGP', 'transferOut', "
        "'2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('t3-c', 'op-3', '$_hh', '${cert.certificateAccountId}', 'credit', 100, "
        "'EGP', 'transferIn', '2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('t3-x', 'op-3', '$_hh', 'dst', 'credit', 1, 'EGP', 'income', "
        "'2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await insertPurchaseEvent(
        cert: cert,
        opId: 'op-3',
        amount: 100,
        currency: 'EGP',
      );
    });
  });

  test('BAL-EVT-6. Unrelated operation rejected', () async {
    final cert = await seedCert();
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
        "destination_account_id, source_account_id) "
        "VALUES ('op-unrel', '$_hh', 'transfer', '2025-01-01', '2025-01-01T00:00:00Z', "
        "100, 'EGP', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', "
        "'${cert.certificateAccountId}', 'src')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('ur-d', 'op-unrel', '$_hh', 'src', 'debit', 100, 'EGP', 'transferOut', "
        "'2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('ur-c', 'op-unrel', '$_hh', '${cert.certificateAccountId}', 'credit', 100, "
        "'EGP', 'transferIn', '2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
      await insertPurchaseEvent(
        cert: cert,
        opId: 'op-unrel',
        amount: 100,
        currency: 'EGP',
      );
    });
  });

  test('BAL-EVT-7. Positive control: valid purchase event accepted', () async {
    final cert = await seedCert();
    // Credit source so debit won't trip negative-balance trigger.
    await credit('src', 500);
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
      "destination_account_id, source_account_id) "
      "VALUES ('op-ok', '$_hh', 'certificateFunding', '2025-01-01', '2025-01-01T00:00:00Z', "
      "100, 'EGP', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', "
      "'${cert.certificateAccountId}', 'src')",
    );
    await db.customStatement(
      "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
      "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
      "VALUES ('ok-d', 'op-ok', '$_hh', 'src', 'debit', 100, 'EGP', 'transferOut', "
      "'2025-01-01', '2025-01-01T00:00:00Z', 't')",
    );
    await db.customStatement(
      "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
      "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
      "VALUES ('ok-c', 'op-ok', '$_hh', '${cert.certificateAccountId}', 'credit', 100, "
      "'EGP', 'transferIn', '2025-01-01', '2025-01-01T00:00:00Z', 't')",
    );
    await insertPurchaseEvent(
      cert: cert,
      opId: 'op-ok',
      amount: 100,
      currency: 'EGP',
    );
    final rows = await db
        .customSelect(
          "SELECT COUNT(*) as c FROM certificate_events WHERE id='evt-op-ok'",
        )
        .get();
    expect(rows.first.read<int>('c'), 1);
  });

  test('BAL-EVT-8. prevent_negative_account_balance rejects raw overdraft debit', () async {
    await createAcct('cash');
    await credit('cash', 100);
    await db.customStatement(
      "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
      "total_amount_minor_units, currency_code, created_by, created_at, updated_at, "
      "source_account_id) "
      "VALUES ('op-neg', '$_hh', 'expense', '2025-01-01', '2025-01-01T00:00:00Z', "
      "500, 'EGP', 't', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z', 'cash')",
    );
    await expectAbort(() async {
      await db.customStatement(
        "INSERT INTO ledger_entries (id, operation_id, household_id, account_id, direction, "
        "amount_minor_units, currency_code, entry_type, effective_date, recorded_at, created_by) "
        "VALUES ('neg-d', 'op-neg', '$_hh', 'cash', 'debit', 500, 'EGP', 'expense', "
        "'2025-01-01', '2025-01-01T00:00:00Z', 't')",
      );
    });
  });
}
