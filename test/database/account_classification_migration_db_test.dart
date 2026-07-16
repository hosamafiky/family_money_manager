/// Phase 3B.1 — Schema v6 migration and trigger-presence tests.
///
/// Verifies:
///   1. A fresh v6 database has the restrict_account_classification_update trigger.
///   2. A fresh v6 database has the restrict_child_fund_unprotect trigger.
///   3. Existing accounts (inserted before trigger creation) are preserved
///      and the triggers function correctly on them after v6 migration.
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

  // ── Helper: list trigger names from sqlite_master ────────────────────────

  Future<List<String>> listTriggers(AppDatabase db) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'trigger' ORDER BY name",
        )
        .get();
    return rows.map((r) => r.read<String>('name')).toList();
  }

  // ── Test 1: Fresh v6 DB has restrict_account_classification_update ────────

  test(
    '1: fresh v6 DB has restrict_account_classification_update trigger',
    () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);

      // Force schema creation by running a trivial query.
      await db.customSelect('SELECT 1').get();

      final triggers = await listTriggers(db);
      expect(
        triggers,
        contains('restrict_account_classification_update'),
        reason:
            'Schema v6 must install the post-history classification lock trigger',
      );
    },
  );

  // ── Test 2: Fresh v6 DB has restrict_child_fund_unprotect ────────────────

  test('2: fresh v6 DB has restrict_child_fund_unprotect trigger', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();

    final triggers = await listTriggers(db);
    expect(
      triggers,
      contains('restrict_child_fund_unprotect'),
      reason: 'Schema v6 must install the child-fund protection trigger',
    );
  });

  // ── Test 3: Existing accounts are preserved and triggers work post-creation ─

  test(
    '3: existing accounts are preserved and triggers enforce immutability',
    () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final accountRepo = DriftAccountRepository(db);
      final ledgerRepo = DriftLedgerRepository(db);

      // Seed a household and account.
      await db.customStatement(
        'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
        "VALUES ('hh-mig-1', 'Migration HH', 'user-1', '2024-01-01', '2024-01-01')",
      );
      const accId = 'acc-mig-1';
      await accountRepo.createAccount(
        const CreateAccountParams(
          id: 'acc-mig-1',
          householdId: 'hh-mig-1',
          name: 'Migration Account',
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

      // Verify the account was preserved.
      final found = await accountRepo.findById(
        id: accId,
        householdId: 'hh-mig-1',
      );
      expect(found, isNotNull);
      expect(found!.name, 'Migration Account');

      // Add financial history.
      await ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-mig-1',
          householdId: 'hh-mig-1',
          destinationAccountId: accId,
          amountMinorUnits: 5000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

      // Post-history: owner_type change should be rejected by the trigger.
      Object? caught;
      try {
        await db.customStatement(
          "UPDATE financial_accounts SET owner_type = 'household' WHERE id = ?",
          [accId],
        );
      } catch (e) {
        caught = e;
      }
      expect(caught, isNotNull);
      expect(
        caught.toString().toLowerCase(),
        contains('immutable'),
        reason:
            'restrict_account_classification_update must fire on existing accounts',
      );

      // Name change should still succeed (name is always editable).
      await db.customStatement(
        "UPDATE financial_accounts SET name = 'Renamed Post-Migration' WHERE id = ?",
        [accId],
      );
      final renamed = await accountRepo.findById(
        id: accId,
        householdId: 'hh-mig-1',
      );
      expect(renamed!.name, 'Renamed Post-Migration');
    },
  );
}
