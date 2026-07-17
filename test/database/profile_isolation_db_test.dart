/// Profile isolation tests (Phase 2A §8).
///
/// Proves that the database layer isolates every financial row by household
/// (profile). Tests attempt direct cross-profile violations and verify that
/// they are rejected by DB-level constraints (FK, triggers, CHECK).
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/balance/data/drift_balance_repository.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftBalanceRepository balanceRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    balanceRepo = DriftBalanceRepository(db);
  });

  tearDown(() async => db.close());

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> insertHousehold(String id) async {
    await db.customStatement(
      'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
      "VALUES ('$id', 'HH $id', 'user-1', '2024-01-01', '2024-01-01')",
    );
  }

  Future<String> createAccount(
    String householdId, {
    String suffix = '1',
  }) async {
    final id = 'acc-$householdId-$suffix';
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Account $suffix',
        type: FinancialAccountType.personalCashWallet,
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'user-1',
      ),
    );
    return id;
  }

  // ── Cross-household account reference via repository ──────────────────────

  group('Repository-level cross-household isolation', () {
    test(
      'recordIncome with account from different household throws ArgumentError',
      () async {
        await insertHousehold('hhA');
        await insertHousehold('hhB');
        final accA = await createAccount('hhA');

        // Attempt to record income for hhB but target an account in hhA.
        await expectLater(
          ledgerRepo.recordIncome(
            RecordIncomeParams(
              operationId: 'op-iso-1',
              householdId: 'hhB',
              destinationAccountId: accA, // belongs to hhA, not hhB
              amountMinorUnits: 1000,
              currencyCode: 'EGP',
              effectiveDate: '2024-01-01',
              createdBy: 'user-1',
            ),
          ),
          throwsArgumentError, // _requireAccount fails because account not in hhB
        );
      },
    );

    test(
      'executeTransfer between accounts of different households throws',
      () async {
        await insertHousehold('hhC');
        await insertHousehold('hhD');
        final accC = await createAccount('hhC');
        final accD = await createAccount('hhD');

        await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-seed-c',
            householdId: 'hhC',
            destinationAccountId: accC,
            amountMinorUnits: 10000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );

        // hhC doesn't know about accD → ArgumentError.
        await expectLater(
          ledgerRepo.executeTransfer(
            ExecuteTransferParams(
              operationId: 'op-cross-tf',
              householdId: 'hhC',
              sourceAccountId: accC,
              destinationAccountId: accD, // wrong household
              amountMinorUnits: 1000,
              currencyCode: 'EGP',
              effectiveDate: '2024-01-01',
              createdBy: 'user-1',
            ),
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      'reverseOperation from different household returns OperationNotFoundError',
      () async {
        await insertHousehold('hhE');
        await insertHousehold('hhF');
        final accE = await createAccount('hhE');

        await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-in-hhE',
            householdId: 'hhE',
            destinationAccountId: accE,
            amountMinorUnits: 5000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );

        // hhF tries to reverse an operation in hhE.
        await expectLater(
          ledgerRepo.reverseOperation(
            const ReverseOperationParams(
              reversalOperationId: 'op-rev-cross',
              originalOperationId: 'op-in-hhE',
              householdId: 'hhF', // wrong household
              effectiveDate: '2024-01-02',
              createdBy: 'user-1',
            ),
          ),
          throwsA(isA<OperationNotFoundError>()),
        );
      },
    );
  });

  // ── DB-level: ledger_entries must match operation's household ─────────────

  group('DB-level cross-profile ledger_entries rejection', () {
    test('entry with mismatched household_id raises SqliteException', () async {
      await insertHousehold('hhG');
      await insertHousehold('hhH');
      await createAccount('hhG');

      await db.customStatement(
        "INSERT INTO operations "
        "(id, household_id, type, effective_date, recorded_at, "
        " total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
        "VALUES ('op-hhG', 'hhG', 'income', '2024-01-01', '2024-01-01', "
        "        100, 'EGP', 'user-1', '2024-01-01', '2024-01-01')",
      );

      await db.customStatement(
        "INSERT INTO financial_accounts "
        "(id, household_id, name, type, owner_type, fund_purpose, currency_code, "
        " created_at, updated_at, created_by) "
        "VALUES ('acc-hhH', 'hhH', 'Acc', 'wallet', 'user', 'general', 'EGP', "
        "        '2024-01-01', '2024-01-01', 'user-1')",
      );

      // Entry says household_id = hhH, but the operation_id is in hhG.
      // The FK trigger requires operation household_id == entry household_id.
      expect(
        () => db.customStatement(
          'INSERT INTO ledger_entries '
          '(id, operation_id, household_id, account_id, direction, amount_minor_units, '
          ' currency_code, entry_type, effective_date, recorded_at, created_by) '
          "VALUES ('e-cross', 'op-hhG', 'hhH', 'acc-hhH', 'credit', 100, "
          "        'EGP', 'income', '2024-01-01', '2024-01-01', 'user-1')",
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  // ── Balance query isolation ───────────────────────────────────────────────

  group('Balance query isolation', () {
    test(
      'currentBalanceMinorUnits is scoped to account within household',
      () async {
        await insertHousehold('hhI');
        await insertHousehold('hhJ');
        final accI = await createAccount('hhI');
        final accJ = await createAccount('hhJ');

        await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-i',
            householdId: 'hhI',
            destinationAccountId: accI,
            amountMinorUnits: 50000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );

        await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-j',
            householdId: 'hhJ',
            destinationAccountId: accJ,
            amountMinorUnits: 99999,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );

        final balI = await balanceRepo.currentBalanceMinorUnits(
          accountId: accI,
          householdId: 'hhI',
        );
        final balJ = await balanceRepo.currentBalanceMinorUnits(
          accountId: accJ,
          householdId: 'hhJ',
        );

        expect(balI, 50000);
        expect(balJ, 99999);

        // Cross-profile query: hhI asking for hhJ's account → 0 (not found).
        final crossBal = await balanceRepo.currentBalanceMinorUnits(
          accountId: accJ,
          householdId: 'hhI', // wrong household
        );
        expect(crossBal, 0);
      },
    );
  });
}
