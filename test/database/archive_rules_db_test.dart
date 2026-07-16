/// Archive rules tests (Phase 3A.1 §8).
///
/// Verifies:
/// 1. Archive account with zero balance → succeeds.
/// 2. Archive account with non-zero balance → AppValidationFailure.
/// 3. Archive already-archived account → AppDuplicateConflict.
/// 4. Record income to archived account → ArchivedAccountError.
/// 5. Record expense to archived account → ArchivedAccountError.
/// 6. Archived account balance still readable.
/// 7. Archived account appears in findByHousehold(includeArchived: true).
/// 8. Archived account hidden in findByHousehold() (no includeArchived).
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/application/account_use_cases.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/balance/data/drift_balance_repository.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository accountRepo;
  late DriftBalanceRepository balanceRepo;
  late DriftLedgerRepository ledgerRepo;
  late ArchiveAccountUseCase archiveUseCase;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    balanceRepo = DriftBalanceRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    archiveUseCase = ArchiveAccountUseCase(
      accountRepository: accountRepo,
      balanceRepository: balanceRepo,
    );
  });

  tearDown(() async => db.close());

  Future<void> insertHousehold(String id) => db.customStatement(
    'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
    "VALUES ('$id', 'HH $id', 'user-1', '2024-01-01', '2024-01-01')",
  );

  Future<String> createAccount(
    String householdId, {
    String suffix = '1',
  }) async {
    final id = 'acc-arch-$householdId-$suffix';
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

  group('Archive rules', () {
    test('archive account with zero balance → AppOk', () async {
      await insertHousehold('hh-arch-1');
      final accId = await createAccount('hh-arch-1');

      final result = await archiveUseCase.execute(
        accountId: accId,
        householdId: 'hh-arch-1',
      );

      expect(result, isA<AppOk<dynamic>>());
    });

    test(
      'archive account with non-zero balance → AppValidationFailure',
      () async {
        await insertHousehold('hh-arch-2');
        final accId = await createAccount('hh-arch-2');

        await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-arch-2',
            householdId: 'hh-arch-2',
            destinationAccountId: accId,
            amountMinorUnits: 1000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );

        final result = await archiveUseCase.execute(
          accountId: accId,
          householdId: 'hh-arch-2',
        );

        expect(result, isA<AppValidationFailure<dynamic>>());
      },
    );

    test('archive already-archived account → AppDuplicateConflict', () async {
      await insertHousehold('hh-arch-3');
      final accId = await createAccount('hh-arch-3');

      // First archive.
      await archiveUseCase.execute(accountId: accId, householdId: 'hh-arch-3');

      // Second archive.
      final result = await archiveUseCase.execute(
        accountId: accId,
        householdId: 'hh-arch-3',
      );

      expect(result, isA<AppDuplicateConflict<dynamic>>());
    });

    test('record income to archived account → ArchivedAccountError', () async {
      await insertHousehold('hh-arch-4');
      final accId = await createAccount('hh-arch-4');
      await archiveUseCase.execute(accountId: accId, householdId: 'hh-arch-4');

      await expectLater(
        ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-arch-4-inc',
            householdId: 'hh-arch-4',
            destinationAccountId: accId,
            amountMinorUnits: 500,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        ),
        throwsA(isA<ArchivedAccountError>()),
      );
    });

    test('record expense to archived account → ArchivedAccountError', () async {
      await insertHousehold('hh-arch-5');
      final accId = await createAccount('hh-arch-5');

      // Fund first, then archive.
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-arch-5-fund',
          householdId: 'hh-arch-5',
          destinationAccountId: accId,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

      // Zero balance account by reversing, then archive.
      await db.customStatement(
        "UPDATE financial_accounts SET is_archived = 1 WHERE id = '$accId'",
      );

      await expectLater(
        ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-arch-5-exp',
            householdId: 'hh-arch-5',
            sourceAccountId: accId,
            amountMinorUnits: 100,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        ),
        throwsA(isA<ArchivedAccountError>()),
      );
    });

    test('archived account balance still readable', () async {
      await insertHousehold('hh-arch-6');
      final accId = await createAccount('hh-arch-6');

      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-arch-6-fund',
          householdId: 'hh-arch-6',
          destinationAccountId: accId,
          amountMinorUnits: 2500,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );
      await db.customStatement(
        "UPDATE financial_accounts SET is_archived = 1 WHERE id = '$accId'",
      );

      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: accId,
        householdId: 'hh-arch-6',
      );
      expect(balance, 2500);
    });

    test(
      'archived account appears in findByHousehold(includeArchived: true)',
      () async {
        await insertHousehold('hh-arch-7');
        final accId = await createAccount('hh-arch-7');
        await archiveUseCase.execute(
          accountId: accId,
          householdId: 'hh-arch-7',
        );

        final allAccounts = await accountRepo.findByHousehold(
          householdId: 'hh-arch-7',
          includeArchived: true,
        );
        expect(allAccounts.any((a) => a.id == accId), isTrue);
      },
    );

    test('archived account hidden in findByHousehold() default', () async {
      await insertHousehold('hh-arch-8');
      final accId = await createAccount('hh-arch-8');
      await archiveUseCase.execute(accountId: accId, householdId: 'hh-arch-8');

      final activeAccounts = await accountRepo.findByHousehold(
        householdId: 'hh-arch-8',
      );
      expect(activeAccounts.any((a) => a.id == accId), isFalse);
    });
  });
}
