/// Income workflow DB tests (Phase 3B §9).
///
/// Uses real AppDatabase.forTesting() + DriftLedgerRepository.
/// All 10 required tests are included.
///
/// Tests:
/// 1. Valid income → operation row, credit entry, context row created.
/// 2. Amount 0 rejected at domain params level.
/// 3. Amount negative rejected at domain params level.
/// 4. Archived destination rejected.
/// 5. Account in wrong household rejected.
/// 6. Same idempotency key + same operation ID → alreadyExists, no duplicate rows.
/// 7. Same idempotency key + different operation ID → conflict result.
/// 8. Income excluded from transfer totals (count operations by type).
/// 9. Opening-balance analytics unaffected by income.
/// 10. Income operation_contexts row is append-only (immutability check).
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/balance/data/drift_balance_repository.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;
  late DriftBalanceRepository balanceRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    balanceRepo = DriftBalanceRepository(db);
    await db.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('hh-inc', 'Test HH', 'user-1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<String> createAccount({
    String suffix = '1',
    bool isArchived = false,
    String householdId = 'hh-inc',
  }) async {
    final id = 'acc-inc-$suffix';
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
    if (isArchived) {
      await db.customStatement(
        "UPDATE financial_accounts SET is_archived = 1 WHERE id = '$id'",
      );
    }
    return id;
  }

  group('Income persistence', () {
    test(
      '1: valid income → operation row, credit entry, context row created',
      () async {
        final acc = await createAccount(suffix: 't1');

        final result = await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-inc-t1',
            householdId: 'hh-inc',
            destinationAccountId: acc,
            amountMinorUnits: 8000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );
        expect(result, IdempotentOperationResult.created);

        // Operation row.
        final opRows = await db
            .customSelect("SELECT type FROM operations WHERE id = 'op-inc-t1'")
            .get();
        expect(opRows.length, 1);
        expect(opRows.first.read<String>('type'), 'income');

        // Credit entry.
        final entryRows = await db
            .customSelect(
              "SELECT direction, amount_minor_units FROM ledger_entries "
              "WHERE operation_id = 'op-inc-t1'",
            )
            .get();
        expect(entryRows.length, 1);
        expect(entryRows.first.read<String>('direction'), 'credit');
        expect(entryRows.first.read<int>('amount_minor_units'), 8000);

        // Context row.
        final ctxRows = await db
            .customSelect(
              "SELECT household_id FROM operation_contexts "
              "WHERE operation_id = 'op-inc-t1'",
            )
            .get();
        expect(ctxRows.length, 1);
        expect(ctxRows.first.read<String>('household_id'), 'hh-inc');

        // Balance.
        final balance = await balanceRepo.currentBalanceMinorUnits(
          accountId: acc,
          householdId: 'hh-inc',
        );
        expect(balance, 8000);
      },
    );

    test('2: amount 0 rejected at domain params level', () {
      expect(
        () => RecordIncomeParams(
          operationId: 'op-inc-t2',
          householdId: 'hh-inc',
          destinationAccountId: 'some-acc',
          amountMinorUnits: 0,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('3: amount negative rejected at domain params level', () {
      expect(
        () => RecordIncomeParams(
          operationId: 'op-inc-t3',
          householdId: 'hh-inc',
          destinationAccountId: 'some-acc',
          amountMinorUnits: -100,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      '4: archived destination rejected with ArchivedAccountError',
      () async {
        final acc = await createAccount(suffix: 't4', isArchived: true);

        await expectLater(
          ledgerRepo.recordIncome(
            RecordIncomeParams(
              operationId: 'op-inc-t4',
              householdId: 'hh-inc',
              destinationAccountId: acc,
              amountMinorUnits: 1000,
              currencyCode: 'EGP',
              effectiveDate: '2024-01-01',
              createdBy: 'user-1',
            ),
          ),
          throwsA(isA<ArchivedAccountError>()),
        );
      },
    );

    test('5: account in wrong household rejected with ArgumentError', () async {
      // Create account in a different household.
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('hh-other', 'Other HH', 'user-1', '2024-01-01', '2024-01-01')",
      );
      final acc = await createAccount(suffix: 't5', householdId: 'hh-other');

      await expectLater(
        ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-inc-t5',
            householdId: 'hh-inc', // wrong household
            destinationAccountId: acc, // account belongs to hh-other
            amountMinorUnits: 1000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      '6: same idempotency key + same operation ID → alreadyExists, no duplicate rows',
      () async {
        final acc = await createAccount(suffix: 't6');
        const opId = 'op-inc-t6';

        final r1 = await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: opId,
            householdId: 'hh-inc',
            destinationAccountId: acc,
            amountMinorUnits: 3000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );
        expect(r1, IdempotentOperationResult.created);

        final r2 = await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: opId,
            householdId: 'hh-inc',
            destinationAccountId: acc,
            amountMinorUnits: 3000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );
        expect(r2, IdempotentOperationResult.alreadyExists);

        // No duplicate rows.
        final opCount = await db
            .customSelect(
              "SELECT COUNT(*) AS cnt FROM operations WHERE id = '$opId'",
            )
            .get();
        expect(opCount.first.read<int>('cnt'), 1);

        final balance = await balanceRepo.currentBalanceMinorUnits(
          accountId: acc,
          householdId: 'hh-inc',
        );
        expect(balance, 3000); // not doubled
      },
    );

    test(
      '7: same idempotency key + different operation ID → conflict',
      () async {
        final acc = await createAccount(suffix: 't7');
        const idemKey = 'idem-key-t7';

        await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-inc-t7a',
            idempotencyKey: idemKey,
            householdId: 'hh-inc',
            destinationAccountId: acc,
            amountMinorUnits: 2000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );

        final r2 = await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-inc-t7b', // DIFFERENT operation ID
            idempotencyKey: idemKey, // SAME idempotency key
            householdId: 'hh-inc',
            destinationAccountId: acc,
            amountMinorUnits: 2000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );
        expect(r2, IdempotentOperationResult.conflict);
      },
    );

    test(
      '8: income excluded from transfer totals (count operations by type)',
      () async {
        final acc = await createAccount(suffix: 't8');

        // Record income.
        await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-inc-t8-inc',
            householdId: 'hh-inc',
            destinationAccountId: acc,
            amountMinorUnits: 5000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );

        // Count operations of type 'transfer' — should be 0.
        final transferCount = await db
            .customSelect(
              "SELECT COUNT(*) AS cnt FROM operations "
              "WHERE household_id = 'hh-inc' AND type = 'transfer'",
            )
            .get();
        expect(transferCount.first.read<int>('cnt'), 0);

        // Count operations of type 'income' — should be 1.
        final incomeCount = await db
            .customSelect(
              "SELECT COUNT(*) AS cnt FROM operations "
              "WHERE household_id = 'hh-inc' AND type = 'income'",
            )
            .get();
        expect(incomeCount.first.read<int>('cnt'), 1);
      },
    );

    test('9: opening-balance analytics unaffected by income', () async {
      final acc = await createAccount(suffix: 't9');

      // Record opening balance.
      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'op-inc-t9-ob',
          householdId: 'hh-inc',
          accountId: acc,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

      // Record income.
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-inc-t9-inc',
          householdId: 'hh-inc',
          destinationAccountId: acc,
          amountMinorUnits: 2000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
      );

      // Opening-balance entries should still be exactly 1.
      final obEntries = await db
          .customSelect(
            "SELECT COUNT(*) AS cnt FROM ledger_entries "
            "WHERE account_id = '$acc' AND entry_type = 'openingBalance'",
          )
          .get();
      expect(obEntries.first.read<int>('cnt'), 1);

      // Total balance = 10000 + 2000 = 12000.
      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: acc,
        householdId: 'hh-inc',
      );
      expect(balance, 12000);
    });

    test(
      '10: income operation_contexts row is append-only (immutability check)',
      () async {
        final acc = await createAccount(suffix: 't10');

        await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-inc-t10',
            householdId: 'hh-inc',
            destinationAccountId: acc,
            amountMinorUnits: 1500,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );

        await expectLater(
          db.customStatement(
            "UPDATE operation_contexts SET note = 'tampered' "
            "WHERE operation_id = 'op-inc-t10'",
          ),
          throwsA(anything),
        );
      },
    );
  });
}
