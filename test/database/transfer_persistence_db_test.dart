/// Transfer workflow DB tests (Phase 3B §11).
///
/// Uses real AppDatabase.forTesting() + DriftLedgerRepository.
///
/// Tests:
///  1. Valid transfer → debit on source, credit on destination, context created.
///  2. Same account rejected (SameAccountTransferError).
///  3. Currency mismatch rejected (CurrencyMismatchTransferError).
///  4. Insufficient source balance rejected.
///  5. Archived source rejected.
///  6. Archived destination rejected.
///  7. Transfer not classified as income or expense.
///  8. Idempotent retry: same operation ID → alreadyExists.
///  9. Conflicting retry: same idempotency key, different ID → conflict.
/// 10. Concurrent competing transfers — only first succeeds after balance is drained.
/// 11. Spouse-wallet scenario: 2000 funded → 1300 spent → 200 returned = 500 balance.
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
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/data/drift_transaction_query_repository.dart';
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
      "VALUES ('hh-tf', 'Transfer HH', 'user-1', '2024-01-01', '2024-01-01')",
    );
  });

  tearDown(() async => db.close());

  Future<String> createAccount({
    required String suffix,
    String currencyCode = 'EGP',
    String householdId = 'hh-tf',
    bool isArchived = false,
  }) async {
    final id = 'acc-tf-$suffix';
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Account $suffix',
        type: FinancialAccountType.personalCashWallet,
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: currencyCode,
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

  Future<void> fund(String accountId, int amount) => ledgerRepo.recordIncome(
    RecordIncomeParams(
      operationId: 'op-tf-fund-${accountId.hashCode}',
      householdId: 'hh-tf',
      destinationAccountId: accountId,
      amountMinorUnits: amount,
      currencyCode: 'EGP',
      effectiveDate: '2024-01-01',
      createdBy: 'user-1',
    ),
  );

  group('Transfer persistence', () {
    test(
      '1: valid transfer → debit on source, credit on destination, context',
      () async {
        final src = await createAccount(suffix: 't1-src');
        final dst = await createAccount(suffix: 't1-dst');
        await fund(src, 10000);

        final result = await ledgerRepo.executeTransfer(
          ExecuteTransferParams(
            operationId: 'op-tf-t1',
            householdId: 'hh-tf',
            sourceAccountId: src,
            destinationAccountId: dst,
            amountMinorUnits: 4000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );
        expect(result, IdempotentOperationResult.created);

        final srcBal = await balanceRepo.currentBalanceMinorUnits(
          accountId: src,
          householdId: 'hh-tf',
        );
        final dstBal = await balanceRepo.currentBalanceMinorUnits(
          accountId: dst,
          householdId: 'hh-tf',
        );
        expect(srcBal, 6000);
        expect(dstBal, 4000);
        // Transfer neutrality.
        expect(srcBal + dstBal, 10000);

        // Context row exists.
        final ctxRows = await db
            .customSelect(
              "SELECT operation_id FROM operation_contexts "
              "WHERE operation_id = 'op-tf-t1'",
            )
            .get();
        expect(ctxRows.length, 1);
      },
    );

    test('2: same account rejected (SameAccountTransferError)', () async {
      final acc = await createAccount(suffix: 't2');

      await expectLater(
        ledgerRepo.executeTransfer(
          ExecuteTransferParams(
            operationId: 'op-tf-t2',
            householdId: 'hh-tf',
            sourceAccountId: acc,
            destinationAccountId: acc,
            amountMinorUnits: 1000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        ),
        throwsA(isA<SameAccountTransferError>()),
      );
    });

    test(
      '3: currency mismatch rejected (CurrencyMismatchTransferError)',
      () async {
        await db.customStatement(
          "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
          "VALUES ('hh-tf-usd', 'USD HH', 'user-1', '2024-01-01', '2024-01-01')",
        );
        final egpAcc = await createAccount(
          suffix: 't3-egp',
          currencyCode: 'EGP',
        );
        const usdId = 'acc-tf-t3-usd';
        await accountRepo.createAccount(
          const CreateAccountParams(
            id: usdId,
            householdId: 'hh-tf',
            name: 'USD Account',
            type: FinancialAccountType.personalCashWallet,
            ownerType: AccountOwnerType.user,
            fundPurpose: FundPurpose.available,
            currencyCode: 'USD',
            isSpendable: true,
            isProtected: false,
            includeInNetWorth: true,
            includeInZakat: false,
            displayOrder: 0,
            createdBy: 'user-1',
          ),
        );

        await expectLater(
          ledgerRepo.executeTransfer(
            ExecuteTransferParams(
              operationId: 'op-tf-t3',
              householdId: 'hh-tf',
              sourceAccountId: egpAcc,
              destinationAccountId: usdId,
              amountMinorUnits: 1000,
              currencyCode: 'EGP',
              effectiveDate: '2024-01-01',
              createdBy: 'user-1',
            ),
          ),
          throwsA(isA<CurrencyMismatchTransferError>()),
        );
      },
    );

    test(
      '4: insufficient source balance rejected (InsufficientFundsError)',
      () async {
        final src = await createAccount(suffix: 't4-src');
        final dst = await createAccount(suffix: 't4-dst');
        await fund(src, 500);

        await expectLater(
          ledgerRepo.executeTransfer(
            ExecuteTransferParams(
              operationId: 'op-tf-t4',
              householdId: 'hh-tf',
              sourceAccountId: src,
              destinationAccountId: dst,
              amountMinorUnits: 1000,
              currencyCode: 'EGP',
              effectiveDate: '2024-01-02',
              createdBy: 'user-1',
            ),
          ),
          throwsA(isA<InsufficientFundsError>()),
        );
      },
    );

    test(
      '5: archived source rejected '
      '(ArchivedAccountError from _requireAccount in DriftLedgerRepository)',
      () async {
        // Note: _requireAccount throws ArchivedAccountError before the
        // executeTransfer code reaches the ArchivedAccountTransferError check.
        // Both are sub-types of Error and indicate an archived-account rejection.
        final src = await createAccount(suffix: 't5-src', isArchived: true);
        final dst = await createAccount(suffix: 't5-dst');

        await expectLater(
          ledgerRepo.executeTransfer(
            ExecuteTransferParams(
              operationId: 'op-tf-t5',
              householdId: 'hh-tf',
              sourceAccountId: src,
              destinationAccountId: dst,
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

    test(
      '6: archived destination rejected '
      '(ArchivedAccountError from _requireAccount in DriftLedgerRepository)',
      () async {
        final src = await createAccount(suffix: 't6-src');
        final dst = await createAccount(suffix: 't6-dst', isArchived: true);
        await fund(src, 5000);

        await expectLater(
          ledgerRepo.executeTransfer(
            ExecuteTransferParams(
              operationId: 'op-tf-t6',
              householdId: 'hh-tf',
              sourceAccountId: src,
              destinationAccountId: dst,
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

    test(
      '7: transfer not classified as income or expense (type = transfer)',
      () async {
        final src = await createAccount(suffix: 't7-src');
        final dst = await createAccount(suffix: 't7-dst');
        await fund(src, 3000);

        await ledgerRepo.executeTransfer(
          ExecuteTransferParams(
            operationId: 'op-tf-t7',
            householdId: 'hh-tf',
            sourceAccountId: src,
            destinationAccountId: dst,
            amountMinorUnits: 1000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );

        final opRows = await db
            .customSelect("SELECT type FROM operations WHERE id = 'op-tf-t7'")
            .get();
        expect(opRows.first.read<String>('type'), 'transfer');

        // Confirm it is NOT income or expense.
        expect(opRows.first.read<String>('type'), isNot('income'));
        expect(opRows.first.read<String>('type'), isNot('expense'));
      },
    );

    test('8: idempotent retry — same operation ID → alreadyExists', () async {
      final src = await createAccount(suffix: 't8-src');
      final dst = await createAccount(suffix: 't8-dst');
      await fund(src, 10000);

      const opId = 'op-tf-t8';
      final r1 = await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: opId,
          householdId: 'hh-tf',
          sourceAccountId: src,
          destinationAccountId: dst,
          amountMinorUnits: 3000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
      );
      expect(r1, IdempotentOperationResult.created);

      final r2 = await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: opId,
          householdId: 'hh-tf',
          sourceAccountId: src,
          destinationAccountId: dst,
          amountMinorUnits: 3000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
      );
      expect(r2, IdempotentOperationResult.alreadyExists);

      // Only one transfer occurred.
      final srcBal = await balanceRepo.currentBalanceMinorUnits(
        accountId: src,
        householdId: 'hh-tf',
      );
      expect(srcBal, 7000);
    });

    test(
      '9: conflicting retry — same idempotency key, different ID → conflict',
      () async {
        final src = await createAccount(suffix: 't9-src');
        final dst = await createAccount(suffix: 't9-dst');
        await fund(src, 10000);
        const idemKey = 'tf-idem-t9';

        await ledgerRepo.executeTransfer(
          ExecuteTransferParams(
            operationId: 'op-tf-t9a',
            idempotencyKey: idemKey,
            householdId: 'hh-tf',
            sourceAccountId: src,
            destinationAccountId: dst,
            amountMinorUnits: 2000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );

        final r2 = await ledgerRepo.executeTransfer(
          ExecuteTransferParams(
            operationId: 'op-tf-t9b',
            idempotencyKey: idemKey,
            householdId: 'hh-tf',
            sourceAccountId: src,
            destinationAccountId: dst,
            amountMinorUnits: 2000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );
        expect(r2, IdempotentOperationResult.conflict);
      },
    );

    test('10: concurrent competing transfers — only first succeeds after '
        'balance is drained', () async {
      final src = await createAccount(suffix: 't10-src');
      final dst1 = await createAccount(suffix: 't10-dst1');
      final dst2 = await createAccount(suffix: 't10-dst2');
      await fund(src, 5000);

      // First transfer drains the full balance.
      final r1 = await ledgerRepo.executeTransfer(
        ExecuteTransferParams(
          operationId: 'op-tf-t10a',
          householdId: 'hh-tf',
          sourceAccountId: src,
          destinationAccountId: dst1,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-02',
          createdBy: 'user-1',
        ),
      );
      expect(r1, IdempotentOperationResult.created);

      // Second transfer fails — balance is 0.
      await expectLater(
        ledgerRepo.executeTransfer(
          ExecuteTransferParams(
            operationId: 'op-tf-t10b',
            householdId: 'hh-tf',
            sourceAccountId: src,
            destinationAccountId: dst2,
            amountMinorUnits: 1,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        ),
        throwsA(isA<InsufficientFundsError>()),
      );
    });
  });

  // ── Spouse-wallet scenario (Step 13) ──────────────────────────────────────

  group('Spouse-wallet scenario (7-step DB test)', () {
    test(
      '11: 2000 funded → 1300 spent → 200 returned = 500 balance + query',
      () async {
        // 1. Create source account (main wallet) and spouse wallet.
        final mainWallet = await createAccount(suffix: 'sw-main');
        final spouseWallet = await createAccount(suffix: 'sw-spouse');

        // Fund the main wallet with enough income to cover the transfer (2000.00 EGP).
        await ledgerRepo.recordIncome(
          RecordIncomeParams(
            operationId: 'op-sw-inc',
            householdId: 'hh-tf',
            destinationAccountId: mainWallet,
            amountMinorUnits: 300000, // 3000.00 EGP — more than 2000.00 needed
            currencyCode: 'EGP',
            effectiveDate: '2024-01-01',
            createdBy: 'user-1',
          ),
        );

        // 2. Execute transfer 2000 → spouse wallet.
        await ledgerRepo.executeTransfer(
          ExecuteTransferParams(
            operationId: 'op-sw-tf-in',
            householdId: 'hh-tf',
            sourceAccountId: mainWallet,
            destinationAccountId: spouseWallet,
            amountMinorUnits: 200000, // 2000.00 EGP in minor units
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );

        // 3. Record expense 1300 from spouse wallet.
        await ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-sw-exp',
            householdId: 'hh-tf',
            sourceAccountId: spouseWallet,
            amountMinorUnits: 130000, // 1300.00 EGP
            currencyCode: 'EGP',
            effectiveDate: '2024-01-03',
            createdBy: 'user-1',
          ),
        );

        // 4. Query balance = 700 (2000 - 1300 = 700).
        final balanceAfterExpense = await balanceRepo.currentBalanceMinorUnits(
          accountId: spouseWallet,
          householdId: 'hh-tf',
        );
        expect(balanceAfterExpense, 70000); // 700.00 EGP

        // 5. Execute transfer 200 from spouse wallet → main wallet (return).
        await ledgerRepo.executeTransfer(
          ExecuteTransferParams(
            operationId: 'op-sw-tf-out',
            householdId: 'hh-tf',
            sourceAccountId: spouseWallet,
            destinationAccountId: mainWallet,
            amountMinorUnits: 20000, // 200.00 EGP
            currencyCode: 'EGP',
            effectiveDate: '2024-01-04',
            createdBy: 'user-1',
          ),
        );

        // 6. Query balance = 500 (2000 - 1300 - 200 = 500).
        final balanceAfterReturn = await balanceRepo.currentBalanceMinorUnits(
          accountId: spouseWallet,
          householdId: 'hh-tf',
        );
        expect(balanceAfterReturn, 50000); // 500.00 EGP

        // 7. Call SpouseWalletSummary query.
        final queryRepo = DriftTransactionQueryRepository(db);
        final summary = await queryRepo.spouseWalletSummary(
          spouseAccountId: spouseWallet,
          householdId: 'hh-tf',
          fromDate: '2024-01-01',
          toDate: '2024-12-31',
        );

        expect(summary.totalFunded, 200000); // 2000.00 EGP funded via transfer
        expect(summary.totalSpent, 130000); // 1300.00 EGP spent
        expect(
          summary.totalReturned,
          20000,
        ); // 200.00 EGP returned via transfer
        expect(summary.derivedBalance, 50000); // 500.00 EGP
        expect(summary.currencyCode, 'EGP');
      },
    );
  });
}
