/// Balance query semantics tests (Phase 3A.1 §2).
///
/// Verifies the typed [BalanceQueryResult] contract:
/// - Existing account with no entries → BalanceFound(minorUnits: 0)
/// - Existing account with balance → BalanceFound(minorUnits: N)
/// - Unknown account → BalanceAccountNotFound
/// - Account in different household → BalanceAccountNotFound
/// - Archived account → BalanceFound (history preserved)
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/balance/data/drift_balance_repository.dart';
import 'package:family_money_manager/features/balance/domain/balance_result.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftBalanceRepository balanceRepo;
  late DriftLedgerRepository ledgerRepo;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    balanceRepo = DriftBalanceRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
  });

  tearDown(() async => db.close());

  Future<void> insertHousehold(String id) => db.customStatement(
    'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
    "VALUES ('$id', 'HH $id', 'user-1', '2024-01-01', '2024-01-01')",
  );

  Future<String> createAccount(String householdId, {String suffix = '1'}) async {
    final id = 'acc-bal-$householdId-$suffix';
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

  group('balanceForAccount', () {
    test('existing account with no ledger entries → BalanceFound(minorUnits: 0)', () async {
      await insertHousehold('hh-bsem-1');
      final accId = await createAccount('hh-bsem-1');

      final result = await balanceRepo.balanceForAccount(
        accountId: accId,
        householdId: 'hh-bsem-1',
      );

      expect(result, isA<BalanceFound>());
      final found = result as BalanceFound;
      expect(found.minorUnits, 0);
      expect(found.currencyCode, 'EGP');
    });

    test('existing account with one income entry → BalanceFound(minorUnits: N)', () async {
      await insertHousehold('hh-bsem-2');
      final accId = await createAccount('hh-bsem-2');

      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-bsem-inc',
          householdId: 'hh-bsem-2',
          destinationAccountId: accId,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

      final result = await balanceRepo.balanceForAccount(
        accountId: accId,
        householdId: 'hh-bsem-2',
      );

      expect(result, isA<BalanceFound>());
      expect((result as BalanceFound).minorUnits, 5000);
    });

    test('unknown account (not in DB) → BalanceAccountNotFound', () async {
      await insertHousehold('hh-bsem-3');

      final result = await balanceRepo.balanceForAccount(
        accountId: 'acc-does-not-exist',
        householdId: 'hh-bsem-3',
      );

      expect(result, isA<BalanceAccountNotFound>());
    });

    test('account in different household → BalanceAccountNotFound (non-disclosing)', () async {
      await insertHousehold('hh-bsem-4a');
      await insertHousehold('hh-bsem-4b');

      final accIdA = await createAccount('hh-bsem-4a');

      // Query the account from household B → should not disclose it.
      final result = await balanceRepo.balanceForAccount(
        accountId: accIdA,
        householdId: 'hh-bsem-4b',
      );

      expect(result, isA<BalanceAccountNotFound>());
    });

    test('archived account → BalanceFound (history preserved)', () async {
      await insertHousehold('hh-bsem-5');
      final accId = await createAccount('hh-bsem-5');

      // Record income, then archive.
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-bsem-arch',
          householdId: 'hh-bsem-5',
          destinationAccountId: accId,
          amountMinorUnits: 3000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );
      // Manually archive by updating the row (archive use case zeroes the balance first,
      // but we're testing the repository directly here).
      await db.customStatement("UPDATE financial_accounts SET is_archived = 1 WHERE id = '$accId'");

      final result = await balanceRepo.balanceForAccount(
        accountId: accId,
        householdId: 'hh-bsem-5',
      );

      expect(result, isA<BalanceFound>());
      expect((result as BalanceFound).minorUnits, 3000);
    });
  });
}
