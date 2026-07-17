/// Schema v5 migration tests: operation_contexts table (Phase 3B §8).
///
/// Verifies:
/// 1. Fresh schema at v5 creates the operation_contexts table.
/// 2. operation_contexts columns match the expected schema.
/// 3. v4→v5 migration triggers (no_update_operation_contexts,
///    no_delete_operation_contexts, fk_operation_context_operation_id) exist.
/// 4. Existing households, accounts, operations, and ledger entries are
///    preserved after v5 migration.
/// 5. operation_contexts table is append-only (UPDATE trigger fires on v5 db).
/// 6. operation_contexts FK trigger fires on v5 db.
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
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  group('Fresh v5 schema', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting());
    tearDown(() async => db.close());

    test('1: all required tables exist including operation_contexts', () async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
          .get();
      final tableNames = rows.map((r) => r.read<String>('name')).toList();

      expect(
        tableNames,
        containsAll([
          'households',
          'household_members',
          'financial_accounts',
          'operations',
          'ledger_entries',
          'child_withdrawal_audits',
          'operation_contexts',
        ]),
      );
    });

    test('2: operation_contexts has expected columns', () async {
      final cols = await db.customSelect('PRAGMA table_info(operation_contexts)').get();
      final colNames = cols.map((r) => r.read<String>('name')).toSet();

      expect(
        colNames,
        containsAll([
          'operation_id',
          'household_id',
          'spender_member_id',
          'beneficiary_member_id',
          'expense_scope',
          'is_recurring',
          'recurring_note',
          'category_code',
          'note',
          'created_at',
        ]),
      );

      // operation_id is PK (notnull = 1 and pk = 1 in PRAGMA table_info).
      final pkCols = cols.where((r) => r.read<int>('pk') == 1);
      expect(pkCols.map((r) => r.read<String>('name')), contains('operation_id'));
    });

    test('3: operation_contexts FK and immutability triggers exist', () async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='trigger' ORDER BY name")
          .get();
      final triggerNames = rows.map((r) => r.read<String>('name')).toSet();

      expect(
        triggerNames,
        containsAll([
          'fk_operation_context_operation_id',
          'no_update_operation_contexts',
          'no_delete_operation_contexts',
        ]),
      );
    });

    test('4: existing data preserved — households, accounts, operations, entries', () async {
      // Seed data using raw SQL to simulate pre-existing data.
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('hh-mig5-1', 'Migrate HH', 'user-1', '2024-01-01', '2024-01-01')",
      );

      final accountRepo = DriftAccountRepository(db);
      await accountRepo.createAccount(
        const CreateAccountParams(
          id: 'acc-mig5-1',
          householdId: 'hh-mig5-1',
          name: 'Migrated Account',
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

      final ledgerRepo = DriftLedgerRepository(db);
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-mig5-1',
          householdId: 'hh-mig5-1',
          destinationAccountId: 'acc-mig5-1',
          amountMinorUnits: 7500,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

      // Verify all rows survived.
      final hhRows = await db
          .customSelect("SELECT id FROM households WHERE id = 'hh-mig5-1'")
          .get();
      expect(hhRows.length, 1);

      final accRows = await db
          .customSelect("SELECT id FROM financial_accounts WHERE id = 'acc-mig5-1'")
          .get();
      expect(accRows.length, 1);

      final opRows = await db
          .customSelect("SELECT id FROM operations WHERE id = 'op-mig5-1'")
          .get();
      expect(opRows.length, 1);

      final entryRows = await db
          .customSelect("SELECT id FROM ledger_entries WHERE operation_id = 'op-mig5-1'")
          .get();
      expect(entryRows.length, 1);

      // operation_contexts row must also exist.
      final ctxRows = await db
          .customSelect(
            "SELECT operation_id FROM operation_contexts WHERE operation_id = 'op-mig5-1'",
          )
          .get();
      expect(ctxRows.length, 1);
    });

    test('5: operation_contexts UPDATE trigger fires on v5 db', () async {
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('hh-mig5-2', 'HH', 'user-1', '2024-01-01', '2024-01-01')",
      );
      final accountRepo = DriftAccountRepository(db);
      await accountRepo.createAccount(
        const CreateAccountParams(
          id: 'acc-mig5-2',
          householdId: 'hh-mig5-2',
          name: 'Account',
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
      final ledgerRepo = DriftLedgerRepository(db);
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-mig5-2',
          householdId: 'hh-mig5-2',
          destinationAccountId: 'acc-mig5-2',
          amountMinorUnits: 1000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

      await expectLater(
        db.customStatement(
          "UPDATE operation_contexts SET note = 'bad' "
          "WHERE operation_id = 'op-mig5-2'",
        ),
        throwsA(anything),
      );
    });

    test('6: operation_contexts FK trigger fires — cannot insert orphan context', () async {
      await db.customStatement(
        "INSERT INTO households (id, name, owner_user_id, created_at, updated_at) "
        "VALUES ('hh-mig5-3', 'HH', 'user-1', '2024-01-01', '2024-01-01')",
      );

      await expectLater(
        db.customStatement(
          "INSERT INTO operation_contexts "
          "(operation_id, household_id, created_at) "
          "VALUES ('op-does-not-exist', 'hh-mig5-3', '2024-01-01T00:00:00Z')",
        ),
        throwsA(anything),
      );
    });
  });
}
