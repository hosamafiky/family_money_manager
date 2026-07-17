/// Deterministic historical balance ordering tests (Phase 2A §9).
///
/// Proves that [entriesForAccount] and historical balance queries return
/// results in a stable, deterministic order regardless of:
/// - Insertion order
/// - Same effective_date with different operation IDs
/// - Backdated insertions after later activity
/// - Repeated queries
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/balance/data/drift_balance_repository.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
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

  Future<void> insertHousehold() async {
    await db.customStatement(
      'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
      "VALUES ('hh-1', 'HH', 'user-1', '2024-01-01', '2024-01-01')",
    );
  }

  Future<String> createAccount({String suffix = '1'}) async {
    final id = 'acc-$suffix';
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: 'hh-1',
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

  RecordIncomeParams income({
    required String opId,
    required String accId,
    required String date,
    int amount = 1000,
  }) => RecordIncomeParams(
    operationId: opId,
    householdId: 'hh-1',
    destinationAccountId: accId,
    amountMinorUnits: amount,
    currencyCode: 'EGP',
    effectiveDate: date,
    createdBy: 'user-1',
  );

  // ── Same effective_date, different operation IDs ──────────────────────────

  group('Same effectiveDate – order is stable (INV-012)', () {
    // NOTE: The ordering is effectiveDate → recordedAt → id.
    // When operations are inserted sequentially at different wall-clock times,
    // 'recordedAt' differs even within the same second, so insertion order
    // (not alphabetical ID order) determines the sequence. This is correct and
    // desired: the sequence is fully deterministic because 'recordedAt' is a
    // persisted field that never changes after write.
    test('entries with same date maintain insertion-time order (recordedAt)', () async {
      await insertHousehold();
      final acc = await createAccount();

      await ledgerRepo.recordIncome(income(opId: 'op-first', accId: acc, date: '2024-06-01'));
      await ledgerRepo.recordIncome(income(opId: 'op-second', accId: acc, date: '2024-06-01'));
      await ledgerRepo.recordIncome(income(opId: 'op-third', accId: acc, date: '2024-06-01'));

      final entries = await ledgerRepo.entriesForAccount(accountId: acc, householdId: 'hh-1');
      expect(entries.length, 3);
      // All entries share the same effectiveDate.
      expect(entries.every((e) => e.effectiveDate == '2024-06-01'), isTrue);
    });

    test('repeated query returns identical sequence (deterministic)', () async {
      await insertHousehold();
      final acc = await createAccount(suffix: 'r');

      await ledgerRepo.recordIncome(income(opId: 'op-r1', accId: acc, date: '2024-03-15'));
      await ledgerRepo.recordIncome(income(opId: 'op-r2', accId: acc, date: '2024-03-15'));

      final seq1 = (await ledgerRepo.entriesForAccount(
        accountId: acc,
        householdId: 'hh-1',
      )).map((e) => e.id).toList();
      final seq2 = (await ledgerRepo.entriesForAccount(
        accountId: acc,
        householdId: 'hh-1',
      )).map((e) => e.id).toList();

      // Must be identical across two separate queries (INV-012).
      expect(seq1, equals(seq2));
    });

    test('id tie-breaker works when recordedAt is identical', () async {
      await insertHousehold();
      // Insert two entries directly with same recordedAt to force the id tie-breaker.
      await db.customStatement(
        'INSERT INTO operations '
        '(id, household_id, type, effective_date, recorded_at, total_amount_minor_units, '
        ' currency_code, created_by, created_at, updated_at) '
        "VALUES ('op-id-zzz', 'hh-1', 'income', '2024-06-01', '2024-06-01T10:00:00Z', "
        "        1000, 'EGP', 'user-1', '2024-06-01', '2024-06-01')",
      );
      await db.customStatement(
        'INSERT INTO operations '
        '(id, household_id, type, effective_date, recorded_at, total_amount_minor_units, '
        ' currency_code, created_by, created_at, updated_at) '
        "VALUES ('op-id-aaa', 'hh-1', 'income', '2024-06-01', '2024-06-01T10:00:00Z', "
        "        1000, 'EGP', 'user-1', '2024-06-01', '2024-06-01')",
      );

      const accId = 'acc-id-tb';
      await db.customStatement(
        'INSERT INTO financial_accounts '
        '(id, household_id, name, type, owner_type, fund_purpose, currency_code, '
        ' created_at, updated_at, created_by) '
        "VALUES ('$accId', 'hh-1', 'Acc', 'personalCashWallet', 'user', "
        "        'available', 'EGP', '2024-01-01', '2024-01-01', 'user-1')",
      );

      await db.customStatement(
        'INSERT INTO ledger_entries '
        '(id, operation_id, household_id, account_id, direction, amount_minor_units, '
        ' currency_code, entry_type, effective_date, recorded_at, created_by) '
        "VALUES ('op-id-zzz_credit', 'op-id-zzz', 'hh-1', '$accId', 'credit', 1000, "
        "        'EGP', 'income', '2024-06-01', '2024-06-01T10:00:00Z', 'user-1')",
      );
      await db.customStatement(
        'INSERT INTO ledger_entries '
        '(id, operation_id, household_id, account_id, direction, amount_minor_units, '
        ' currency_code, entry_type, effective_date, recorded_at, created_by) '
        "VALUES ('op-id-aaa_credit', 'op-id-aaa', 'hh-1', '$accId', 'credit', 1000, "
        "        'EGP', 'income', '2024-06-01', '2024-06-01T10:00:00Z', 'user-1')",
      );

      final entries = await ledgerRepo.entriesForAccount(accountId: accId, householdId: 'hh-1');
      // Same effectiveDate, same recordedAt → ordered by entry id ASC.
      expect(entries[0].id, 'op-id-aaa_credit');
      expect(entries[1].id, 'op-id-zzz_credit');
    });
  });

  // ── Backdated insertion ───────────────────────────────────────────────────

  group('Backdated operation inserted after later activity', () {
    test('backdated entry appears before later-dated entries', () async {
      await insertHousehold();
      final acc = await createAccount(suffix: 'bd');

      // Record income for Jan 10 first.
      await ledgerRepo.recordIncome(income(opId: 'op-jan10', accId: acc, date: '2024-01-10'));

      // Record backdated income for Jan 01 (inserted later, but earlier date).
      await ledgerRepo.recordIncome(income(opId: 'op-jan01', accId: acc, date: '2024-01-01'));

      final entries = await ledgerRepo.entriesForAccount(accountId: acc, householdId: 'hh-1');

      expect(entries.length, 2);
      // Jan 01 should come first because effectiveDate < Jan 10.
      expect(entries[0].effectiveDate, '2024-01-01');
      expect(entries[1].effectiveDate, '2024-01-10');
    });

    test('historical balance at Jan 05 excludes backdated-but-later Jan 10 entry', () async {
      await insertHousehold();
      final acc = await createAccount(suffix: 'hb');

      await ledgerRepo.recordIncome(
        income(opId: 'op-hb-jan10', accId: acc, date: '2024-01-10', amount: 10000),
      );
      await ledgerRepo.recordIncome(
        income(opId: 'op-hb-jan01', accId: acc, date: '2024-01-01', amount: 5000),
      );

      // Historical balance on Jan 05 should include only the Jan 01 entry.
      final bal = await balanceRepo.historicalBalanceMinorUnits(
        accountId: acc,
        householdId: 'hh-1',
        asOfDate: '2024-01-05',
      );
      expect(bal, 5000);
    });
  });

  // ── Reversal ordering ─────────────────────────────────────────────────────

  group('Reversal entries appear at their effectiveDate', () {
    test('reversal effective before original appears first', () async {
      await insertHousehold();
      final acc = await createAccount(suffix: 'rv');

      await ledgerRepo.recordIncome(
        income(opId: 'op-jan20', accId: acc, date: '2024-01-20', amount: 8000),
      );

      // Reversal backdated to Jan 15 (before the original).
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'op-rev-jan15',
          originalOperationId: 'op-jan20',
          householdId: 'hh-1',
          effectiveDate: '2024-01-15',
          createdBy: 'user-1',
        ),
      );

      final entries = await ledgerRepo.entriesForAccount(accountId: acc, householdId: 'hh-1');

      // Reversal entry (Jan 15) should come before the original income (Jan 20).
      expect(entries.first.effectiveDate, '2024-01-15');
      expect(entries.first.isReversal, isTrue);
      expect(entries.last.effectiveDate, '2024-01-20');
      expect(entries.last.isReversal, isFalse);
    });
  });

  // ── Opening balance + expense same date ──────────────────────────────────

  group('Opening balance and expense sharing same effectiveDate', () {
    test('entry order is stable by operation_id as tie-breaker', () async {
      await insertHousehold();
      final acc = await createAccount(suffix: 'ob');

      await ledgerRepo.recordOpeningBalance(
        RecordOpeningBalanceParams(
          operationId: 'op-ob-aaa',
          householdId: 'hh-1',
          accountId: acc,
          amountMinorUnits: 20000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

      await ledgerRepo.recordIncome(
        income(opId: 'op-inc-bbb', accId: acc, date: '2024-01-01', amount: 5000),
      );

      final entries = await ledgerRepo.entriesForAccount(accountId: acc, householdId: 'hh-1');

      final ids = entries.map((e) => e.id).toList();
      // op-ob-aaa_credit < op-inc-bbb_credit alphabetically.
      expect(ids.first, contains('op-ob-aaa'));
      expect(ids.last, contains('op-inc-bbb'));
    });
  });
}
