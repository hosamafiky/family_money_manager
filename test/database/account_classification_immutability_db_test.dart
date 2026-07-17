/// Phase 3B.1 — Account classification immutability DB-trigger tests.
///
/// Tests that the two new schema-v6 triggers correctly enforce:
///   1. restrict_account_classification_update — blocks changes to 8 fields
///      once the account has any ledger entries (post-history lock).
///   2. restrict_child_fund_unprotect — always blocks clearing is_protected
///      on a childProtectedFund account, regardless of financial history.
///
/// All trigger tests use raw SQL (db.customStatement) to bypass Drift's
/// typed-update layer so the trigger is exercised directly.
///
/// Use-case integration tests (tests 19–23) use the real
/// [UpdateAccountMetadataUseCase] backed by an in-memory Drift database.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/application/account_use_cases.dart';
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

  Future<void> insertHousehold(String id) => db.customStatement(
    'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
    "VALUES ('$id', 'HH $id', 'user-1', '2024-01-01', '2024-01-01')",
  );

  Future<String> createAccount(
    String householdId, {
    String suffix = '1',
    FinancialAccountType type = FinancialAccountType.personalCashWallet,
    AccountOwnerType ownerType = AccountOwnerType.user,
    FundPurpose fundPurpose = FundPurpose.available,
    bool isProtected = false,
    bool isSpendable = true,
    bool includeInNetWorth = true,
    bool includeInZakat = false,
  }) async {
    final id = 'acc-ci-$householdId-$suffix';
    await accountRepo.createAccount(
      CreateAccountParams(
        id: id,
        householdId: householdId,
        name: 'Account $suffix',
        type: type,
        ownerType: ownerType,
        fundPurpose: fundPurpose,
        currencyCode: 'EGP',
        isSpendable: isSpendable,
        isProtected: isProtected,
        includeInNetWorth: includeInNetWorth,
        includeInZakat: includeInZakat,
        displayOrder: 0,
        createdBy: 'user-1',
      ),
    );
    return id;
  }

  Future<void> recordIncome(String householdId, String accountId) => ledgerRepo.recordIncome(
    RecordIncomeParams(
      operationId: 'op-seed-${accountId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
      householdId: householdId,
      destinationAccountId: accountId,
      amountMinorUnits: 10000,
      currencyCode: 'EGP',
      effectiveDate: '2024-01-01',
      createdBy: 'user-1',
    ),
  );

  /// Asserts that [statement] throws an Exception whose message contains
  /// at least one of [fragments] (case-insensitive).
  Future<void> expectTriggerRejects(
    Future<void> Function() action, {
    List<String> fragments = const ['immutable', 'cannot', 'abort'],
  }) async {
    Object? caught;
    try {
      await action();
    } catch (e) {
      caught = e;
    }
    expect(caught, isNotNull, reason: 'Expected an exception but none was thrown');
    final msg = caught.toString().toLowerCase();
    final matched = fragments.any((f) => msg.contains(f.toLowerCase()));
    expect(matched, isTrue, reason: 'Exception message "$msg" did not match any of $fragments');
  }

  // ── Group: owner_type immutability ────────────────────────────────────────

  group('owner_type immutability', () {
    test('1: change owner_type BEFORE financial history succeeds (raw SQL)', () async {
      await insertHousehold('hh-ot-1');
      final acc = await createAccount('hh-ot-1', suffix: 'a', ownerType: AccountOwnerType.user);

      // No ledger entries yet → trigger WHEN condition is false → no raise.
      await db.customStatement("UPDATE financial_accounts SET owner_type = 'spouse' WHERE id = ?", [
        acc,
      ]);

      final updated = await accountRepo.findById(id: acc, householdId: 'hh-ot-1');
      expect(updated!.ownerType, AccountOwnerType.spouse);
    });

    test('2: change owner_type AFTER financial history is rejected (raw SQL)', () async {
      await insertHousehold('hh-ot-2');
      final acc = await createAccount('hh-ot-2', suffix: 'b', ownerType: AccountOwnerType.user);
      await recordIncome('hh-ot-2', acc);

      await expectTriggerRejects(
        () => db.customStatement(
          "UPDATE financial_accounts SET owner_type = 'spouse' WHERE id = ?",
          [acc],
        ),
        fragments: ['immutable'],
      );
    });
  });

  // ── Group: fund_purpose immutability ─────────────────────────────────────

  group('fund_purpose immutability', () {
    test('3: change fund_purpose BEFORE financial history succeeds (raw SQL)', () async {
      await insertHousehold('hh-fp-3');
      final acc = await createAccount('hh-fp-3', suffix: 'c', fundPurpose: FundPurpose.available);

      await db.customStatement(
        "UPDATE financial_accounts SET fund_purpose = 'personalSpending' WHERE id = ?",
        [acc],
      );

      final updated = await accountRepo.findById(id: acc, householdId: 'hh-fp-3');
      expect(updated!.fundPurpose, FundPurpose.personalSpending);
    });

    test('4: change fund_purpose AFTER financial history is rejected (raw SQL)', () async {
      await insertHousehold('hh-fp-4');
      final acc = await createAccount('hh-fp-4', suffix: 'd', fundPurpose: FundPurpose.available);
      await recordIncome('hh-fp-4', acc);

      await expectTriggerRejects(
        () => db.customStatement(
          "UPDATE financial_accounts SET fund_purpose = 'personalSpending' WHERE id = ?",
          [acc],
        ),
        fragments: ['immutable'],
      );
    });
  });

  // ── Group: is_protected immutability ─────────────────────────────────────

  group('is_protected immutability', () {
    test('5: change is_protected BEFORE financial history succeeds (non-child fund)', () async {
      await insertHousehold('hh-ip-5');
      final acc = await createAccount('hh-ip-5', suffix: 'e', isProtected: false);

      await db.customStatement('UPDATE financial_accounts SET is_protected = 1 WHERE id = ?', [
        acc,
      ]);

      final updated = await accountRepo.findById(id: acc, householdId: 'hh-ip-5');
      expect(updated!.isProtected, isTrue);
    });

    test('6: change is_protected AFTER financial history is rejected (raw SQL)', () async {
      await insertHousehold('hh-ip-6');
      final acc = await createAccount('hh-ip-6', suffix: 'f', isProtected: false);
      await recordIncome('hh-ip-6', acc);

      await expectTriggerRejects(
        () => db.customStatement('UPDATE financial_accounts SET is_protected = 1 WHERE id = ?', [
          acc,
        ]),
        fragments: ['immutable'],
      );
    });

    test('7: childProtectedFund cannot disable is_protected BEFORE financial history', () async {
      await insertHousehold('hh-ip-7');
      final acc = await createAccount(
        'hh-ip-7',
        suffix: 'g',
        type: FinancialAccountType.childProtectedFund,
        isProtected: true,
      );

      // No ledger entries → the post-history trigger does NOT fire.
      // But restrict_child_fund_unprotect fires unconditionally for childProtectedFund.
      await expectTriggerRejects(
        () => db.customStatement('UPDATE financial_accounts SET is_protected = 0 WHERE id = ?', [
          acc,
        ]),
        fragments: ['child protected fund', 'cannot', 'disabled'],
      );
    });
  });

  // ── Group: is_spendable immutability ─────────────────────────────────────

  group('is_spendable immutability', () {
    test('8: change is_spendable BEFORE financial history succeeds (raw SQL)', () async {
      await insertHousehold('hh-is-8');
      final acc = await createAccount('hh-is-8', suffix: 'h', isSpendable: true);

      await db.customStatement('UPDATE financial_accounts SET is_spendable = 0 WHERE id = ?', [
        acc,
      ]);

      final updated = await accountRepo.findById(id: acc, householdId: 'hh-is-8');
      expect(updated!.isSpendable, isFalse);
    });

    test('9: change is_spendable AFTER financial history is rejected (raw SQL)', () async {
      await insertHousehold('hh-is-9');
      final acc = await createAccount('hh-is-9', suffix: 'i', isSpendable: true);
      await recordIncome('hh-is-9', acc);

      await expectTriggerRejects(
        () => db.customStatement('UPDATE financial_accounts SET is_spendable = 0 WHERE id = ?', [
          acc,
        ]),
        fragments: ['immutable'],
      );
    });
  });

  // ── Group: include_in_net_worth immutability ──────────────────────────────

  group('include_in_net_worth immutability', () {
    test('10: change include_in_net_worth AFTER financial history is rejected', () async {
      await insertHousehold('hh-nw-10');
      final acc = await createAccount('hh-nw-10', suffix: 'j', includeInNetWorth: true);
      await recordIncome('hh-nw-10', acc);

      await expectTriggerRejects(
        () => db.customStatement(
          'UPDATE financial_accounts SET include_in_net_worth = 0 WHERE id = ?',
          [acc],
        ),
        fragments: ['immutable'],
      );
    });
  });

  // ── Group: include_in_zakat immutability ──────────────────────────────────

  group('include_in_zakat immutability', () {
    test('11: change include_in_zakat AFTER financial history is rejected', () async {
      await insertHousehold('hh-zk-11');
      final acc = await createAccount('hh-zk-11', suffix: 'k', includeInZakat: false);
      await recordIncome('hh-zk-11', acc);

      await expectTriggerRejects(
        () => db.customStatement(
          'UPDATE financial_accounts SET include_in_zakat = 1 WHERE id = ?',
          [acc],
        ),
        fragments: ['immutable'],
      );
    });
  });

  // ── Group: type immutability (always) ────────────────────────────────────

  group('type immutability (always)', () {
    test('12: change type BEFORE financial history is rejected (always-on trigger)', () async {
      await insertHousehold('hh-ty-12');
      final acc = await createAccount('hh-ty-12', suffix: 'l');

      await expectTriggerRejects(
        () => db.customStatement(
          "UPDATE financial_accounts SET type = 'bankAccount' WHERE id = ?",
          [acc],
        ),
        fragments: ['immutable', 'type', 'currency'],
      );
    });

    test('13: change type AFTER financial history is also rejected', () async {
      await insertHousehold('hh-ty-13');
      final acc = await createAccount('hh-ty-13', suffix: 'm');
      await recordIncome('hh-ty-13', acc);

      await expectTriggerRejects(
        () => db.customStatement(
          "UPDATE financial_accounts SET type = 'bankAccount' WHERE id = ?",
          [acc],
        ),
        fragments: ['immutable'],
      );
    });
  });

  // ── Group: currency_code immutability (always) ───────────────────────────

  group('currency_code immutability (always)', () {
    test(
      '14: change currency_code BEFORE financial history is rejected (always-on trigger)',
      () async {
        await insertHousehold('hh-cc-14');
        final acc = await createAccount('hh-cc-14', suffix: 'n');

        await expectTriggerRejects(
          () => db.customStatement(
            "UPDATE financial_accounts SET currency_code = 'USD' WHERE id = ?",
            [acc],
          ),
          fragments: ['immutable', 'type', 'currency'],
        );
      },
    );

    test('15: change currency_code AFTER financial history is also rejected', () async {
      await insertHousehold('hh-cc-15');
      final acc = await createAccount('hh-cc-15', suffix: 'o');
      await recordIncome('hh-cc-15', acc);

      await expectTriggerRejects(
        () => db.customStatement(
          "UPDATE financial_accounts SET currency_code = 'USD' WHERE id = ?",
          [acc],
        ),
        fragments: ['immutable'],
      );
    });
  });

  // ── Group: name mutability ────────────────────────────────────────────────

  group('name mutability (always editable)', () {
    test('16: change name BEFORE financial history succeeds', () async {
      await insertHousehold('hh-nm-16');
      final acc = await createAccount('hh-nm-16', suffix: 'p');

      await db.customStatement("UPDATE financial_accounts SET name = 'New Name' WHERE id = ?", [
        acc,
      ]);

      final updated = await accountRepo.findById(id: acc, householdId: 'hh-nm-16');
      expect(updated!.name, 'New Name');
    });

    test('17: change name AFTER financial history succeeds (name always editable)', () async {
      await insertHousehold('hh-nm-17');
      final acc = await createAccount('hh-nm-17', suffix: 'q');
      await recordIncome('hh-nm-17', acc);

      await db.customStatement(
        "UPDATE financial_accounts SET name = 'Renamed After History' WHERE id = ?",
        [acc],
      );

      final updated = await accountRepo.findById(id: acc, householdId: 'hh-nm-17');
      expect(updated!.name, 'Renamed After History');
    });
  });

  // ── Group: cross-household reassignment ──────────────────────────────────

  group('cross-household reassignment', () {
    test('18: change household_id to non-existent value is rejected (FK constraint)', () async {
      await insertHousehold('hh-xh-18a');
      final acc = await createAccount('hh-xh-18a', suffix: 'r');

      // PRAGMA foreign_keys = ON is set in beforeOpen.
      // Changing to a household that does not exist violates the FK.
      await expectTriggerRejects(
        () => db.customStatement(
          "UPDATE financial_accounts SET household_id = 'hh-nonexistent' WHERE id = ?",
          [acc],
        ),
        fragments: ['foreign key', 'constraint', 'violation', 'abort'],
      );
    });
  });

  // ── Group: use-case mapping ───────────────────────────────────────────────

  group('use-case mapping (UpdateAccountMetadataUseCase)', () {
    late UpdateAccountMetadataUseCase useCase;

    setUp(() {
      useCase = UpdateAccountMetadataUseCase(accountRepo);
    });

    test('19: name-only update returns AppOk', () async {
      await insertHousehold('hh-uc-19');
      await createAccount('hh-uc-19', suffix: 's');
      const accId = 'acc-ci-hh-uc-19-s';

      final result = await useCase.execute(
        accountId: accId,
        householdId: 'hh-uc-19',
        name: 'Updated Name',
      );

      expect(result, isA<AppOk<FinancialAccount>>());
      expect((result as AppOk<FinancialAccount>).value.name, 'Updated Name');
    });

    test('20: blank name returns AppValidationFailure', () async {
      await insertHousehold('hh-uc-20');
      await createAccount('hh-uc-20', suffix: 't');
      const accId = 'acc-ci-hh-uc-20-t';

      final result = await useCase.execute(accountId: accId, householdId: 'hh-uc-20', name: '   ');

      expect(result, isA<AppValidationFailure<FinancialAccount>>());
      expect((result as AppValidationFailure).field, 'name');
    });

    test('21: non-existent account returns AppNotFound', () async {
      await insertHousehold('hh-uc-21');

      final result = await useCase.execute(
        accountId: 'acc-does-not-exist',
        householdId: 'hh-uc-21',
        name: 'Anything',
      );

      expect(result, isA<AppNotFound<FinancialAccount>>());
    });

    test('22: name edit does not change ledger balance', () async {
      await insertHousehold('hh-uc-22');
      await createAccount('hh-uc-22', suffix: 'u');
      const accId = 'acc-ci-hh-uc-22-u';
      await recordIncome('hh-uc-22', accId);

      final balanceBefore = await balanceRepo.currentBalanceMinorUnits(
        accountId: accId,
        householdId: 'hh-uc-22',
      );

      await useCase.execute(accountId: accId, householdId: 'hh-uc-22', name: 'Renamed Account');

      final balanceAfter = await balanceRepo.currentBalanceMinorUnits(
        accountId: accId,
        householdId: 'hh-uc-22',
      );

      expect(balanceAfter, balanceBefore);
      expect(balanceAfter, 10000);
    });

    test('23: name edit does not affect ledger entry count (spendable totals unchanged)', () async {
      await insertHousehold('hh-uc-23');
      await createAccount('hh-uc-23', suffix: 'v', isSpendable: true);
      const accId = 'acc-ci-hh-uc-23-v';
      await recordIncome('hh-uc-23', accId);

      await useCase.execute(accountId: accId, householdId: 'hh-uc-23', name: 'Spendable Renamed');

      // The account is still found and still spendable after rename.
      final updated = await accountRepo.findById(id: accId, householdId: 'hh-uc-23');
      expect(updated, isNotNull);
      expect(updated!.isSpendable, isTrue);
      expect(updated.name, 'Spendable Renamed');

      // Balance is unchanged.
      final balance = await balanceRepo.currentBalanceMinorUnits(
        accountId: accId,
        householdId: 'hh-uc-23',
      );
      expect(balance, 10000);
    });
  });
}
