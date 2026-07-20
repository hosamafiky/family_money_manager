/// Phase 6A.4 — Preserve DB debit / structure guarantees (no schema bump).
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
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

const _hh = 'hh-6a4-db';

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

  test(
    'DB-G-1. prevent_negative_account_balance rejects raw overdraft SQL',
    () async {
      await createAcct('cash');
      await credit('cash', 1000);
      await db.customStatement(
        "INSERT INTO operations (id, household_id, type, effective_date, recorded_at, "
        "total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
        "VALUES ('op-over', '$_hh', 'expense', '2025-01-01', '2025-01-01T00:00:00Z', "
        "5000, 'EGP', 'test', '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z')",
      );
      await expectLater(
        () => db.customStatement(
          "INSERT INTO ledger_entries "
          "(id, operation_id, household_id, account_id, direction, "
          "amount_minor_units, currency_code, entry_type, effective_date, "
          "recorded_at, created_by) VALUES "
          "('raw-deb', 'op-over', '$_hh', 'cash', 'debit', 5000, 'EGP', "
          "'expense', '2025-01-01', '2025-01-01T00:00:00Z', 'test')",
        ),
        throwsA(anything),
      );
      expect(await bal('cash'), 1000);
    },
  );

  test('DB-G-2. Transfer legs stay balanced', () async {
    await createAcct('a');
    await createAcct('b');
    await credit('a', 5000);
    await ledger.executeTransfer(
      ExecuteTransferParams(
        operationId: 'xfer-1',
        householdId: _hh,
        sourceAccountId: 'a',
        destinationAccountId: 'b',
        amountMinorUnits: 2000,
        currencyCode: 'EGP',
        effectiveDate: '2025-01-01',
        createdBy: 'test',
      ),
    );
    final legs = await db
        .customSelect(
          "SELECT direction, amount_minor_units AS amt FROM ledger_entries "
          "WHERE operation_id='xfer-1' ORDER BY direction",
        )
        .get();
    expect(legs, hasLength(2));
    expect(legs.map((r) => r.read<int>('amt')).toSet(), {2000});
  });

  test(
    'DB-G-3. Rejected debit adjustment rolls back; no committed op',
    () async {
      await createAcct('cash');
      await credit('cash', 500);
      await expectLater(
        () => ledger.recordAdjustment(
          RecordAdjustmentParams(
            operationId: 'adj-over',
            householdId: _hh,
            accountId: 'cash',
            adjustmentAmountMinorUnits: -2000,
            currencyCode: 'EGP',
            effectiveDate: '2025-01-01',
            createdBy: 'test',
            reason: 'over',
          ),
        ),
        throwsA(isA<InsufficientFundsError>()),
      );
      final ops = await db
          .customSelect(
            "SELECT COUNT(*) as c FROM operations WHERE id='adj-over'",
          )
          .get();
      expect(ops.first.read<int>('c'), 0);
      expect(await bal('cash'), 500);
    },
  );

  test('DB-G-4. Certificate account cannot receive opening balance', () async {
    await createAcct('src');
    await credit('src', 100000);
    final cert =
        ((await createUc.execute(
                  householdId: _hh,
                  institutionName: 'Bank',
                  currencyCode: 'EGP',
                  principalMinorUnits: 10000,
                  startDate: '2025-01-01',
                  maturityDate: '2026-01-01',
                  sourceAccountId: 'src',
                  idempotencyKey: 'dbg4',
                ))
                as AppOk<SavingsCertificate>)
            .value;
    expect(
      () => ledger.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'ob-cert',
          householdId: _hh,
          accountId: cert.certificateAccountId,
          amountMinorUnits: 1,
          currencyCode: 'EGP',
          effectiveDate: '2025-01-01',
          createdBy: 'test',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('DB-G-5. Schema version remains 19', () async {
    final v = await db
        .customSelect('PRAGMA user_version')
        .get()
        .then((r) => r.first.read<int>('user_version'));
    expect(v, 19);
  });
}
