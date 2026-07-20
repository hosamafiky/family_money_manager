/// Phase 6A.3 — Debit DB enforcement regressions + failed-txn cleanup.
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
import 'package:sqlite3/common.dart' show SqliteException;

const _hh = 'hh-6a3-deb';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late DriftAccountRepository accounts;
  late DriftLedgerRepository ledger;
  late CreateCertificateUseCase createUc;

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

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).get()).first.read<int>('c');

  test(
    'DET-DEB-1. Raw SQL overdraft debit rejected by prevent_negative_account_balance',
    () async {
      await createAcct('src');
      await credit('src', 1000);
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
        "VALUES ('op-over', '$_hh', 'expense', '2024-01-02', '2024-01-02T00:00:00Z', "
        "5000, 'EGP', 'test', '2024-01-02T00:00:00Z', '2024-01-02T00:00:00Z')",
      );
      await expectLater(
        () => db.customStatement(
          "INSERT INTO ledger_entries "
          "(id, operation_id, household_id, account_id, direction, "
          "amount_minor_units, currency_code, entry_type, effective_date, "
          "recorded_at, created_by) VALUES "
          "('op-over_debit', 'op-over', '$_hh', 'src', 'debit', 5000, "
          "'EGP', 'expense', '2024-01-02', '2024-01-02T00:00:00Z', 'test')",
        ),
        throwsA(
          isA<SqliteException>().having(
            (e) => e.message,
            'message',
            contains('account balance cannot go negative'),
          ),
        ),
      );
      expect(
        await count(
          "SELECT COUNT(*) as c FROM ledger_entries WHERE id='op-over_debit'",
        ),
        0,
      );
      final bal =
          (await db
                  .customSelect(
                    "SELECT COALESCE(SUM(CASE WHEN direction='credit' "
                    "THEN amount_minor_units ELSE -amount_minor_units END), 0) AS bal "
                    "FROM ledger_entries WHERE account_id='src'",
                  )
                  .get())
              .first
              .read<int>('bal');
      expect(bal, 1000);
    },
  );

  test(
    'DET-DEB-2. Failed certificate debit leaves no committed op/context/event',
    () async {
      await createAcct('src');
      await credit('src', 50000);
      final failing = DriftCertificateRepository(
        db,
        debugFailAfter: CertificateFailAfter.accountInsert,
      );
      final failUc = CreateCertificateUseCase(
        certRepository: failing,
        accountRepository: accounts,
      );
      final result = await failUc.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 20000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src',
        idempotencyKey: 'det-deb-2',
      );
      expect(result, isA<AppPersistenceFailure<SavingsCertificate>>());
      expect(await count('SELECT COUNT(*) as c FROM savings_certificates'), 0);
      expect(
        await count(
          "SELECT COUNT(*) as c FROM operations WHERE type='certificateFunding'",
        ),
        0,
      );
      expect(
        await count(
          "SELECT COUNT(*) as c FROM operation_contexts oc "
          "JOIN operations o ON o.id = oc.operation_id "
          "WHERE o.type='certificateFunding'",
        ),
        0,
      );
      expect(await count('SELECT COUNT(*) as c FROM certificate_events'), 0);
      expect(
        await count(
          "SELECT COUNT(*) as c FROM financial_accounts WHERE type='certificate'",
        ),
        0,
      );
      final bal =
          (await db
                  .customSelect(
                    "SELECT COALESCE(SUM(CASE WHEN direction='credit' "
                    "THEN amount_minor_units ELSE -amount_minor_units END), 0) AS bal "
                    "FROM ledger_entries WHERE account_id='src'",
                  )
                  .get())
              .first
              .read<int>('bal');
      expect(bal, 50000);
    },
  );

  test(
    'DET-DEB-3. In-tx insufficient funds returns AppInsufficientFunds (no partial write)',
    () async {
      await createAcct('src');
      await credit('src', 10000);
      final result = await createUc.execute(
        householdId: _hh,
        institutionName: 'Bank',
        currencyCode: 'EGP',
        principalMinorUnits: 50000,
        startDate: '2025-01-01',
        maturityDate: '2026-01-01',
        sourceAccountId: 'src',
        idempotencyKey: 'det-deb-3',
      );
      expect(result, isA<AppInsufficientFunds<SavingsCertificate>>());
      expect(await count('SELECT COUNT(*) as c FROM savings_certificates'), 0);
      expect(
        await count(
          "SELECT COUNT(*) as c FROM operations WHERE type='certificateFunding'",
        ),
        0,
      );
    },
  );
}
