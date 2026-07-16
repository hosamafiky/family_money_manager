/// Historical metadata enforcement tests (Phase 3A.1 §7).
///
/// Verifies that account type and currency_code are immutable at the DB level
/// via the `immutable_account_type_currency` trigger.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftLedgerRepository ledgerRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
  });

  tearDown(() async => db.close());

  Future<void> insertHousehold(String id) => db.customStatement(
    'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
    "VALUES ('$id', 'HH $id', 'user-1', '2024-01-01', '2024-01-01')",
  );

  Future<String> createAccount(
    String householdId, {
    String currency = 'EGP',
  }) async {
    const id = 'acc-hist-1';
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Test Account',
        type: FinancialAccountType.personalCashWallet,
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: currency,
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

  group('Immutable account type trigger', () {
    test('direct SQL UPDATE of type → SqliteException', () async {
      await insertHousehold('hh-hist-1');
      final accId = await createAccount('hh-hist-1');

      await expectLater(
        db.customStatement(
          "UPDATE financial_accounts SET type = 'bankAccount' WHERE id = '$accId'",
        ),
        throwsA(anything),
      );

      // Verify type is unchanged.
      final rows = await db
          .customSelect(
            "SELECT type FROM financial_accounts WHERE id = '$accId'",
          )
          .get();
      expect(rows.first.read<String>('type'), 'personalCashWallet');
    });

    test('direct SQL UPDATE of currency_code → SqliteException', () async {
      await insertHousehold('hh-hist-2');
      final accId = await createAccount('hh-hist-2');

      await expectLater(
        db.customStatement(
          "UPDATE financial_accounts SET currency_code = 'USD' WHERE id = '$accId'",
        ),
        throwsA(anything),
      );
    });

    test('UPDATE of name → succeeds (mutable field)', () async {
      await insertHousehold('hh-hist-3');
      final accId = await createAccount('hh-hist-3');

      await db.customStatement(
        "UPDATE financial_accounts SET name = 'New Name' WHERE id = '$accId'",
      );

      final rows = await db
          .customSelect(
            "SELECT name FROM financial_accounts WHERE id = '$accId'",
          )
          .get();
      expect(rows.first.read<String>('name'), 'New Name');
    });

    test(
      'UPDATE of is_protected after ledger entries → ClassificationImmutabilityError',
      () async {
        await insertHousehold('hh-hist-4');
        final accId = await createAccount('hh-hist-4');

        // Record an income so ledger entries exist.
        await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-hist-4',
            householdId: 'hh-hist-4',
            destinationAccountId: accId,
            amountMinorUnits: 1000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );

        // Attempt to flip is_protected via the repo layer.
        await expectLater(
          accountRepo.updateAccount(
            id: accId,
            householdId: 'hh-hist-4',
            isProtected: true,
            updatedAt: '2024-01-02T00:00:00Z',
          ),
          throwsA(anything),
        );
      },
    );
  });
}
