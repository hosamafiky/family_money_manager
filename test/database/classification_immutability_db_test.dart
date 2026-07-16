/// Historical account classification immutability tests (Phase 2A §7).
///
/// Policy: once an account has ledger entries, the classification fields
/// isProtected, includeInNetWorth, and includeInZakat must not change.
/// Attempting to do so throws [ClassificationImmutabilityError].
///
/// Always-immutable fields (type, currencyCode, ownerType, fundPurpose) are
/// never accepted by updateAccount at all.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> insertHousehold(String id) => db.customStatement(
    'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
    "VALUES ('$id', 'HH $id', 'user-1', '2024-01-01', '2024-01-01')",
  );

  Future<String> createAccount(
    String householdId, {
    String suffix = '1',
    bool isProtected = false,
    bool includeInNetWorth = true,
    bool includeInZakat = false,
  }) async {
    final id = 'acc-$householdId-$suffix';
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
        isProtected: isProtected,
        includeInNetWorth: includeInNetWorth,
        includeInZakat: includeInZakat,
        displayOrder: 0,
        createdBy: 'user-1',
      ),
    );
    return id;
  }

  Future<void> recordIncome(String householdId, String accountId) =>
      ledgerRepo.recordIncome(
        RecordIncomeParams(
          operationId: 'op-seed-${accountId.replaceAll('-', '')}',
          householdId: householdId,
          destinationAccountId: accountId,
          amountMinorUnits: 10000,
          currencyCode: 'EGP',
          effectiveDate: '2024-01-01',
          createdBy: 'user-1',
        ),
      );

  // ── Classification fields: blocked once entries exist ─────────────────────

  group('Classification immutability – after first ledger entry (INV-017)', () {
    test(
      'changing isProtected after entries throws ClassificationImmutabilityError',
      () async {
        await insertHousehold('hh-ci-1');
        final acc = await createAccount('hh-ci-1', isProtected: false);
        await recordIncome('hh-ci-1', acc);

        await expectLater(
          accountRepo.updateAccount(
            id: acc,
            householdId: 'hh-ci-1',
            isProtected: true, // was false
            updatedAt: '2024-06-01',
          ),
          throwsA(isA<ClassificationImmutabilityError>()),
        );
      },
    );

    test(
      'changing includeInNetWorth after entries throws ClassificationImmutabilityError',
      () async {
        await insertHousehold('hh-ci-2');
        final acc = await createAccount('hh-ci-2', includeInNetWorth: true);
        await recordIncome('hh-ci-2', acc);

        await expectLater(
          accountRepo.updateAccount(
            id: acc,
            householdId: 'hh-ci-2',
            includeInNetWorth: false,
            updatedAt: '2024-06-01',
          ),
          throwsA(isA<ClassificationImmutabilityError>()),
        );
      },
    );

    test(
      'changing includeInZakat after entries throws ClassificationImmutabilityError',
      () async {
        await insertHousehold('hh-ci-3');
        final acc = await createAccount('hh-ci-3', includeInZakat: false);
        await recordIncome('hh-ci-3', acc);

        await expectLater(
          accountRepo.updateAccount(
            id: acc,
            householdId: 'hh-ci-3',
            includeInZakat: true,
            updatedAt: '2024-06-01',
          ),
          throwsA(isA<ClassificationImmutabilityError>()),
        );
      },
    );
  });

  // ── Classification fields: allowed before first ledger entry ─────────────

  group('Classification fields: mutable before first entry', () {
    test('isProtected may change before any ledger entries', () async {
      await insertHousehold('hh-ci-4');
      final acc = await createAccount('hh-ci-4', isProtected: false);

      final updated = await accountRepo.updateAccount(
        id: acc,
        householdId: 'hh-ci-4',
        isProtected: true,
        updatedAt: '2024-06-01',
      );
      expect(updated.isProtected, isTrue);
    });

    test('includeInNetWorth may change before any ledger entries', () async {
      await insertHousehold('hh-ci-5');
      final acc = await createAccount('hh-ci-5', includeInNetWorth: true);

      final updated = await accountRepo.updateAccount(
        id: acc,
        householdId: 'hh-ci-5',
        includeInNetWorth: false,
        updatedAt: '2024-06-01',
      );
      expect(updated.includeInNetWorth, isFalse);
    });
  });

  // ── Display-only fields: always mutable ──────────────────────────────────

  group('Display fields: always mutable even after entries', () {
    test('name, displayOrder, notes may change after entries', () async {
      await insertHousehold('hh-ci-6');
      final acc = await createAccount('hh-ci-6');
      await recordIncome('hh-ci-6', acc);

      final updated = await accountRepo.updateAccount(
        id: acc,
        householdId: 'hh-ci-6',
        name: 'Renamed Account',
        displayOrder: 5,
        notes: 'Some note',
        updatedAt: '2024-06-01',
      );
      expect(updated.name, 'Renamed Account');
      expect(updated.displayOrder, 5);
      expect(updated.notes, 'Some note');
    });
  });

  // ── Archived accounts preserve history ───────────────────────────────────

  group('Archived accounts preserve complete history', () {
    test('archiving an account does not remove its ledger entries', () async {
      await insertHousehold('hh-ci-7');
      final acc = await createAccount('hh-ci-7');
      await recordIncome('hh-ci-7', acc);

      await accountRepo.archiveAccount(
        id: acc,
        householdId: 'hh-ci-7',
        archivedAt: DateTime.utc(2024, 6, 1),
        updatedAt: '2024-06-01',
      );

      // The ledger entry must still exist.
      final entries = await ledgerRepo.entriesForAccount(
        accountId: acc,
        householdId: 'hh-ci-7',
      );
      expect(entries, isNotEmpty);
    });

    test('archived account still found by findById', () async {
      await insertHousehold('hh-ci-8');
      final acc = await createAccount('hh-ci-8');

      await accountRepo.archiveAccount(
        id: acc,
        householdId: 'hh-ci-8',
        archivedAt: DateTime.utc(2024, 6, 1),
        updatedAt: '2024-06-01',
      );

      final found = await accountRepo.findById(id: acc, householdId: 'hh-ci-8');
      expect(found, isNotNull);
      expect(found!.isArchived, isTrue);
    });
  });
}
