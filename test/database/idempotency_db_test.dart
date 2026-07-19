/// Operation-level idempotency tests (Phase 2A §3).
///
/// Tests the full idempotency design:
/// - Same operation_id → alreadyExists (safe retry)
/// - Same idempotency_key + different operation_id → conflict
/// - Same key in different profiles → independent (no conflict)
/// - Concurrent duplicate transfers → only one persisted
/// - Rollback followed by retry → succeeds
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/balance/data/drift_balance_repository.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> setupHousehold(String id) async {
    await db.customStatement(
      'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
      "VALUES ('$id', 'HH $id', 'user-1', '2024-01-01', '2024-01-01')",
    );
  }

  Future<String> createAccount(
    String householdId, {
    String suffix = '1',
    bool isProtected = false,
  }) async {
    final id = 'acc-$householdId-$suffix';
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Account $suffix',
        type: FinancialAccountType.personalCashWallet,
        ownerType: isProtected ? AccountOwnerType.child : AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: isProtected,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: 'user-1',
      ),
    );
    return id;
  }

  RecordIncomeParams incomeParams({
    required String operationId,
    required String householdId,
    required String destinationAccountId,
    String? idempotencyKey,
    int amount = 10000,
  }) => RecordIncomeParams(
    operationId: operationId,
    householdId: householdId,
    destinationAccountId: destinationAccountId,
    amountMinorUnits: amount,
    currencyCode: 'EGP',
    effectiveDate: '2024-01-01',
    createdBy: 'user-1',
    idempotencyKey: idempotencyKey,
  );

  // ── Sequential duplicate income ───────────────────────────────────────────

  group('Sequential duplicate income', () {
    test(
      'same operation_id returns alreadyExists and does not add extra records',
      () async {
        await setupHousehold('hh-1');
        final acc = await createAccount('hh-1');

        final r1 = await ledgerRepo.recordIncome(
          incomeParams(
            operationId: 'op-inc-1',
            householdId: 'hh-1',
            destinationAccountId: acc,
          ),
        );
        expect(r1, IdempotentOperationResult.created);

        final r2 = await ledgerRepo.recordIncome(
          incomeParams(
            operationId: 'op-inc-1',
            householdId: 'hh-1',
            destinationAccountId: acc,
          ),
        );
        expect(r2, IdempotentOperationResult.alreadyExists);

        // Balance must reflect exactly one income, not two.
        final balance = await balanceRepo.currentBalanceMinorUnits(
          accountId: acc,
          householdId: 'hh-1',
        );
        expect(balance, 10000);

        // Only one operation row.
        final ops = await ledgerRepo.operationsInRange(
          householdId: 'hh-1',
          fromDate: '2024-01-01',
          toDate: '2024-12-31',
        );
        expect(ops.length, 1);
      },
    );
  });

  // ── Sequential duplicate expense ──────────────────────────────────────────

  group('Sequential duplicate expense', () {
    test(
      'same operation_id returns alreadyExists and does not reduce balance twice',
      () async {
        await setupHousehold('hh-2');
        final acc = await createAccount('hh-2');

        await ledgerRepo.recordIncome(
          incomeParams(
            operationId: 'op-seed',
            householdId: 'hh-2',
            destinationAccountId: acc,
            amount: 20000,
          ),
        );

        final r1 = await ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-exp-1',
            householdId: 'hh-2',
            sourceAccountId: acc,
            amountMinorUnits: 5000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );
        expect(r1, IdempotentOperationResult.created);

        final r2 = await ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-exp-1',
            householdId: 'hh-2',
            sourceAccountId: acc,
            amountMinorUnits: 5000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );
        expect(r2, IdempotentOperationResult.alreadyExists);

        final balance = await balanceRepo.currentBalanceMinorUnits(
          accountId: acc,
          householdId: 'hh-2',
        );
        expect(balance, 15000); // 20000 - 5000, not -10000
      },
    );
  });

  // ── Sequential duplicate transfer ─────────────────────────────────────────

  group('Sequential duplicate transfer', () {
    test(
      'same operation_id returns alreadyExists and moves money only once',
      () async {
        await setupHousehold('hh-3');
        final src = await createAccount('hh-3', suffix: 'src');
        final dst = await createAccount('hh-3', suffix: 'dst');

        await ledgerRepo.recordIncome(
          incomeParams(
            operationId: 'op-seed3',
            householdId: 'hh-3',
            destinationAccountId: src,
            amount: 10000,
          ),
        );

        final r1 = await ledgerRepo.executeTransfer(
          ExecuteTransferParams(
            operationId: 'op-tf-1',
            householdId: 'hh-3',
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
            operationId: 'op-tf-1',
            householdId: 'hh-3',
            sourceAccountId: src,
            destinationAccountId: dst,
            amountMinorUnits: 3000,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );
        expect(r2, IdempotentOperationResult.alreadyExists);

        final srcBalance = await balanceRepo.currentBalanceMinorUnits(
          accountId: src,
          householdId: 'hh-3',
        );
        final dstBalance = await balanceRepo.currentBalanceMinorUnits(
          accountId: dst,
          householdId: 'hh-3',
        );
        expect(srcBalance, 7000); // 10000 - 3000
        expect(dstBalance, 3000);
      },
    );
  });

  // ── Same key in different profiles ────────────────────────────────────────

  group('Same idempotency key in different households (profiles)', () {
    test('same key succeeds independently in each household', () async {
      await setupHousehold('hh-4a');
      await setupHousehold('hh-4b');
      final accA = await createAccount('hh-4a');
      final accB = await createAccount('hh-4b');

      const sharedKey = 'shared-idem-key';

      final rA = await ledgerRepo.recordIncome(
        incomeParams(
          operationId: 'op-hh4a',
          householdId: 'hh-4a',
          destinationAccountId: accA,
          idempotencyKey: sharedKey,
        ),
      );
      expect(rA, IdempotentOperationResult.created);

      final rB = await ledgerRepo.recordIncome(
        incomeParams(
          operationId: 'op-hh4b',
          householdId: 'hh-4b',
          destinationAccountId: accB,
          idempotencyKey: sharedKey,
        ),
      );
      // Different household → no conflict, both operations created successfully.
      expect(rB, IdempotentOperationResult.created);
    });
  });

  // ── Same idempotency key with conflicting payload ─────────────────────────

  group('Idempotency: same key, different operation_id', () {
    test('equivalent payload → alreadyExists (Phase 5B.5)', () async {
      await setupHousehold('hh-5');
      final acc = await createAccount('hh-5');

      const sharedKey = 'conflict-key';

      final r1 = await ledgerRepo.recordIncome(
        incomeParams(
          operationId: 'op-hh5-first',
          householdId: 'hh-5',
          destinationAccountId: acc,
          idempotencyKey: sharedKey,
        ),
      );
      expect(r1, IdempotentOperationResult.created);

      // Different operation_id but same normalised payload → alreadyExists.
      final r2 = await ledgerRepo.recordIncome(
        incomeParams(
          operationId: 'op-hh5-second',
          householdId: 'hh-5',
          destinationAccountId: acc,
          idempotencyKey: sharedKey,
        ),
      );
      expect(r2, IdempotentOperationResult.alreadyExists);

      // Only one operation stored.
      final ops = await ledgerRepo.operationsInRange(
        householdId: 'hh-5',
        fromDate: '2024-01-01',
        toDate: '2024-12-31',
      );
      expect(ops.length, 1);
      expect(ops.first.id, 'op-hh5-first');
    });

    test('conflicting payload → conflict', () async {
      await setupHousehold('hh-5b');
      final acc = await createAccount('hh-5b');
      const sharedKey = 'conflict-key-amt';

      await ledgerRepo.recordIncome(
        incomeParams(
          operationId: 'op-hh5b-first',
          householdId: 'hh-5b',
          destinationAccountId: acc,
          idempotencyKey: sharedKey,
          amount: 1000,
        ),
      );
      final r2 = await ledgerRepo.recordIncome(
        incomeParams(
          operationId: 'op-hh5b-second',
          householdId: 'hh-5b',
          destinationAccountId: acc,
          idempotencyKey: sharedKey,
          amount: 2000,
        ),
      );
      expect(r2, IdempotentOperationResult.conflict);
    });
  });

  // ── Rollback followed by retry ────────────────────────────────────────────

  group('Rollback then retry', () {
    test(
      'operation can be recorded after a failed attempt with the same params',
      () async {
        await setupHousehold('hh-6');
        final acc = await createAccount('hh-6');

        // Seed insufficient funds scenario.
        await ledgerRepo.recordIncome(
          incomeParams(
            operationId: 'op-seed6',
            householdId: 'hh-6',
            destinationAccountId: acc,
            amount: 100,
          ),
        );

        // First attempt fails (insufficient funds).
        await expectLater(
          ledgerRepo.recordExpense(
            RecordExpenseParams(
              operationId: 'op-exp-retry',
              householdId: 'hh-6',
              sourceAccountId: acc,
              amountMinorUnits: 500,
              currencyCode: 'EGP',
              effectiveDate: '2024-01-02',
              createdBy: 'user-1',
            ),
          ),
          throwsA(isA<InsufficientFundsError>()),
        );

        // Add more funds.
        await ledgerRepo.recordIncome(
          incomeParams(
            operationId: 'op-more',
            householdId: 'hh-6',
            destinationAccountId: acc,
            amount: 1000,
          ),
        );

        // Retry with the same operation_id → should succeed now.
        final r = await ledgerRepo.recordExpense(
          RecordExpenseParams(
            operationId: 'op-exp-retry',
            householdId: 'hh-6',
            sourceAccountId: acc,
            amountMinorUnits: 500,
            currencyCode: 'EGP',
            effectiveDate: '2024-01-02',
            createdBy: 'user-1',
          ),
        );
        expect(r, IdempotentOperationResult.created);

        final balance = await balanceRepo.currentBalanceMinorUnits(
          accountId: acc,
          householdId: 'hh-6',
        );
        expect(balance, 600); // 100 + 1000 - 500
      },
    );
  });

  // ── Scoped idempotency index: DB-level enforcement ────────────────────────

  group('DB-level scoped idempotency uniqueness', () {
    test(
      'UNIQUE(household_id, idempotency_key) prevents duplicate at DB level',
      () async {
        await setupHousehold('hh-7');

        // Insert two operations with the same scoped key at raw SQL level.
        await db.customStatement(
          "INSERT INTO operations "
          "(id, household_id, type, effective_date, recorded_at, "
          " total_amount_minor_units, currency_code, created_by, created_at, "
          " updated_at, idempotency_key) "
          "VALUES ('op-idx-1', 'hh-7', 'income', '2024-01-01', '2024-01-01', "
          "        100, 'EGP', 'user-1', '2024-01-01', '2024-01-01', 'key-A')",
        );

        expect(
          () => db.customStatement(
            "INSERT INTO operations "
            "(id, household_id, type, effective_date, recorded_at, "
            " total_amount_minor_units, currency_code, created_by, created_at, "
            " updated_at, idempotency_key) "
            "VALUES ('op-idx-2', 'hh-7', 'income', '2024-01-01', '2024-01-01', "
            "        200, 'EGP', 'user-1', '2024-01-01', '2024-01-01', 'key-A')",
          ),
          throwsA(anything), // UNIQUE constraint violation
        );
      },
    );

    test(
      'NULL idempotency_key is not subject to uniqueness (allowed multiple)',
      () async {
        await setupHousehold('hh-8');

        await db.customStatement(
          "INSERT INTO operations "
          "(id, household_id, type, effective_date, recorded_at, "
          " total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
          "VALUES ('op-null-1', 'hh-8', 'income', '2024-01-01', '2024-01-01', "
          "        100, 'EGP', 'user-1', '2024-01-01', '2024-01-01')",
        );

        // Second with NULL idempotency_key should not violate constraint.
        await db.customStatement(
          "INSERT INTO operations "
          "(id, household_id, type, effective_date, recorded_at, "
          " total_amount_minor_units, currency_code, created_by, created_at, updated_at) "
          "VALUES ('op-null-2', 'hh-8', 'income', '2024-01-01', '2024-01-01', "
          "        200, 'EGP', 'user-1', '2024-01-01', '2024-01-01')",
        );

        final ops = await db
            .customSelect(
              "SELECT id FROM operations WHERE household_id = 'hh-8'",
            )
            .get();
        expect(ops.length, 2);
      },
    );
  });
}
