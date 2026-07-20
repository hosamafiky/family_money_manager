/// Phase 6A.4 — Contention coverage for debit adjustment & controlled reversal.
library;

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _hh = 'hh-6a4-deb';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late Directory dir;
  late String path;
  late AppDatabase db1;
  late AppDatabase db2;
  late DriftAccountRepository accounts1;
  late DriftLedgerRepository ledger1;
  late DriftLedgerRepository ledger2;

  Future<void> seed() async {
    await db1.customStatement(
      "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
      "VALUES ('$_hh', 'HH', 'u1', '2024-01-01T00:00:00Z', '2024-01-01T00:00:00Z')",
    );
  }

  Future<void> createAcct(String id) async {
    await accounts1.createAccount(
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
        displayOrder: 1,
        createdBy: 'test',
      ),
    );
  }

  Future<void> credit(String id, int amount) async {
    await ledger1.recordIncome(
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
      (await db1
              .customSelect(
                "SELECT COALESCE(SUM(CASE WHEN direction = 'credit' "
                'THEN amount_minor_units ELSE -amount_minor_units END), 0) AS bal '
                "FROM ledger_entries WHERE account_id = '$id'",
              )
              .get())
          .first
          .read<int>('bal');

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fmm_6a4_deb_');
    path = p.join(dir.path, 'conc.db');
    db1 = AppDatabase.forFile(path);
    db2 = AppDatabase.forFile(path);
    await db1.customStatement('PRAGMA busy_timeout = 5000');
    await db2.customStatement('PRAGMA busy_timeout = 5000');
    accounts1 = DriftAccountRepository(db1);
    ledger1 = DriftLedgerRepository(db1);
    ledger2 = DriftLedgerRepository(db2);
    await seed();
  });

  tearDown(() async {
    await db1.close();
    await db2.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('DEB-CONT-1. Concurrent debit adjustments vs balance → '
      'one success + one InsufficientFundsError; bal never negative', () async {
    await createAcct('cash');
    await credit('cash', 20000);
    final results = await Future.wait([
      () async {
        try {
          return await ledger1.recordAdjustment(
            RecordAdjustmentParams(
              operationId: 'adj-a',
              householdId: _hh,
              accountId: 'cash',
              adjustmentAmountMinorUnits: -20000,
              currencyCode: 'EGP',
              effectiveDate: '2025-01-01',
              createdBy: 'test',
              reason: 'a',
            ),
          );
        } on InsufficientFundsError catch (e) {
          return e;
        }
      }(),
      () async {
        try {
          return await ledger2.recordAdjustment(
            RecordAdjustmentParams(
              operationId: 'adj-b',
              householdId: _hh,
              accountId: 'cash',
              adjustmentAmountMinorUnits: -20000,
              currencyCode: 'EGP',
              effectiveDate: '2025-01-01',
              createdBy: 'test',
              reason: 'b',
            ),
          );
        } on InsufficientFundsError catch (e) {
          return e;
        }
      }(),
    ]);
    final oks = results.whereType<IdempotentOperationResult>().length;
    final insuff = results.whereType<InsufficientFundsError>().length;
    expect(oks, 1);
    expect(insuff, 1);
    expect(await bal('cash'), 0);
  });

  test('DEB-CONT-2. Concurrent reverseOperation (income credit → debit) → '
      'typed outcomes; balance never negative', () async {
    await createAcct('cash');
    await credit('cash', 15000);
    // Two incomes of 15000 each so either reversal alone is fine, but
    // racing two full-balance debit reversals of the same income is N/A;
    // race two distinct incomes each 15000 against a drained account via
    // expense first: reverse income A vs expense of 15000.
    final income = await ledger1.recordIncome(
      RecordIncomeParams(
        operationId: 'inc-rev-target',
        householdId: _hh,
        destinationAccountId: 'cash',
        amountMinorUnits: 15000,
        currencyCode: 'EGP',
        effectiveDate: '2025-01-01',
        createdBy: 'test',
      ),
    );
    expect(income, IdempotentOperationResult.created);
    // Spend the full balance so reversing the income debit-competes with
    // a debit adjustment.
    await ledger1.recordExpense(
      RecordExpenseParams(
        operationId: 'exp-drain',
        householdId: _hh,
        sourceAccountId: 'cash',
        amountMinorUnits: 30000,
        currencyCode: 'EGP',
        effectiveDate: '2025-01-01',
        createdBy: 'test',
        categoryCode: 'food',
      ),
    );
    // Recredit exactly 15000 so only one of reverse-income / adjustment can win.
    await credit('cash', 15000);
    expect(await bal('cash'), 15000);

    final results = await Future.wait([
      () async {
        try {
          return await ledger1.reverseOperation(
            ReverseOperationParams(
              originalOperationId: 'inc-rev-target',
              reversalOperationId: 'rev-inc',
              householdId: _hh,
              effectiveDate: '2025-01-02',
              createdBy: 'test',
            ),
          );
        } on InsufficientFundsError catch (e) {
          return e;
        } on DuplicateReversalError catch (e) {
          return e;
        }
      }(),
      () async {
        try {
          return await ledger2.recordAdjustment(
            RecordAdjustmentParams(
              operationId: 'adj-race',
              householdId: _hh,
              accountId: 'cash',
              adjustmentAmountMinorUnits: -15000,
              currencyCode: 'EGP',
              effectiveDate: '2025-01-02',
              createdBy: 'test',
              reason: 'race',
            ),
          );
        } on InsufficientFundsError catch (e) {
          return e;
        }
      }(),
    ]);
    final successes = results.whereType<IdempotentOperationResult>().length;
    final insuff = results.whereType<InsufficientFundsError>().length;
    expect(successes + insuff, 2);
    expect(successes, 1);
    expect(insuff, 1);
    expect(await bal('cash'), greaterThanOrEqualTo(0));
    expect(await bal('cash'), 0);
  });
}
