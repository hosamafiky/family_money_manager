/// Account-creation idempotency tests (Phase 3A.1 §4).
///
/// Tests the CreateAccountUseCase idempotency behaviour:
/// - First creation → AppOk + account row exists.
/// - Same key, same payload → AppOk with the SAME account (no new row).
/// - Same key, different payload (name) → AppDuplicateConflict.
/// - Same key, different payload (currency) → AppDuplicateConflict.
/// - Same key in different household → creates new account independently.
/// - No key provided → each call creates a new account.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/application/create_account_use_case.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CreateAccountUseCase useCase;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase.forTesting();
    useCase = CreateAccountUseCase(
      accountRepository: DriftAccountRepository(db),
      ledgerRepository: DriftLedgerRepository(db),
      db: db,
    );
  });

  tearDown(() async => db.close());

  Future<void> insertHousehold(String id) => db.customStatement(
    'INSERT INTO households (id, name, owner_user_id, created_at, updated_at) '
    "VALUES ('$id', 'HH $id', 'user-1', '2024-01-01', '2024-01-01')",
  );

  Future<int> countAccounts(String householdId) async {
    final rows = await db
        .customSelect("SELECT id FROM financial_accounts WHERE household_id = '$householdId'")
        .get();
    return rows.length;
  }

  CreateAccountWorkflowParams baseParams({
    required String householdId,
    String name = 'My Account',
    String currency = 'EGP',
    String? idempotencyKey,
  }) => CreateAccountWorkflowParams(
    householdId: householdId,
    name: name,
    type: FinancialAccountType.personalCashWallet,
    ownerType: AccountOwnerType.user,
    fundPurpose: FundPurpose.available,
    currencyCode: currency,
    isSpendable: true,
    isProtected: false,
    includeInNetWorth: true,
    includeInZakat: false,
    createdBy: 'user-1',
    idempotencyKey: idempotencyKey,
  );

  group('Account-creation idempotency', () {
    test('first creation → AppOk and account row exists', () async {
      await insertHousehold('hh-aidem-1');

      final result = await useCase.execute(
        baseParams(householdId: 'hh-aidem-1', idempotencyKey: 'key-a'),
      );

      expect(result, isA<AppOk<dynamic>>());
      expect(await countAccounts('hh-aidem-1'), 1);
    });

    test('same key, same payload → AppOk, no new rows created', () async {
      await insertHousehold('hh-aidem-2');

      final r1 = await useCase.execute(
        baseParams(householdId: 'hh-aidem-2', idempotencyKey: 'key-b'),
      );
      expect(r1, isA<AppOk<dynamic>>());
      final firstId = (r1 as AppOk).value.id as String;

      final r2 = await useCase.execute(
        baseParams(householdId: 'hh-aidem-2', idempotencyKey: 'key-b'),
      );
      expect(r2, isA<AppOk<dynamic>>());
      expect((r2 as AppOk).value.id, firstId);
      expect(await countAccounts('hh-aidem-2'), 1);
    });

    test('same key, different name → AppDuplicateConflict', () async {
      await insertHousehold('hh-aidem-3');

      await useCase.execute(
        baseParams(householdId: 'hh-aidem-3', name: 'Original Name', idempotencyKey: 'key-c'),
      );

      final r2 = await useCase.execute(
        baseParams(householdId: 'hh-aidem-3', name: 'Different Name', idempotencyKey: 'key-c'),
      );

      expect(r2, isA<AppDuplicateConflict<dynamic>>());
    });

    test('same key, different currency → AppDuplicateConflict', () async {
      await insertHousehold('hh-aidem-4');

      await useCase.execute(
        baseParams(householdId: 'hh-aidem-4', currency: 'EGP', idempotencyKey: 'key-d'),
      );

      final r2 = await useCase.execute(
        baseParams(householdId: 'hh-aidem-4', currency: 'USD', idempotencyKey: 'key-d'),
      );

      expect(r2, isA<AppDuplicateConflict<dynamic>>());
    });

    test('same key, different household → creates new account (key is scoped)', () async {
      await insertHousehold('hh-aidem-5a');
      await insertHousehold('hh-aidem-5b');

      final rA = await useCase.execute(
        baseParams(householdId: 'hh-aidem-5a', idempotencyKey: 'shared-key'),
      );
      expect(rA, isA<AppOk<dynamic>>());

      final rB = await useCase.execute(
        baseParams(householdId: 'hh-aidem-5b', idempotencyKey: 'shared-key'),
      );
      expect(rB, isA<AppOk<dynamic>>());
      expect((rA as AppOk).value.id, isNot((rB as AppOk).value.id));
    });

    test('no key provided → each call creates a new account', () async {
      await insertHousehold('hh-aidem-6');

      await useCase.execute(baseParams(householdId: 'hh-aidem-6'));
      await useCase.execute(baseParams(householdId: 'hh-aidem-6'));

      expect(await countAccounts('hh-aidem-6'), 2);
    });
  });
}
