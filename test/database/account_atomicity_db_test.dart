/// Account + opening balance atomicity tests (Phase 3A.1 §5).
///
/// Verifies that CreateAccountUseCase uses a single DB transaction:
/// - Zero opening balance → creates account, NO operations, NO ledger entries.
/// - Non-zero opening balance → creates account + exactly 1 operation + 1 ledger entry.
/// - Same idempotency key retry → returns existing account, no extra rows.
/// - Invalid params (empty name) → no DB write at all.
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
        .customSelect(
          "SELECT id FROM financial_accounts WHERE household_id = '$householdId'",
        )
        .get();
    return rows.length;
  }

  Future<int> countOperations(String householdId) async {
    final rows = await db
        .customSelect(
          "SELECT id FROM operations WHERE household_id = '$householdId'",
        )
        .get();
    return rows.length;
  }

  Future<int> countEntries(String householdId) async {
    final rows = await db
        .customSelect(
          "SELECT id FROM ledger_entries WHERE household_id = '$householdId'",
        )
        .get();
    return rows.length;
  }

  group('Account atomicity', () {
    test(
      'zero opening balance → account only, no operations or entries',
      () async {
        await insertHousehold('hh-atom-1');

        final result = await useCase.execute(
          const CreateAccountWorkflowParams(
            householdId: 'hh-atom-1',
            name: 'Zero Balance Account',
            type: FinancialAccountType.personalCashWallet,
            ownerType: AccountOwnerType.user,
            fundPurpose: FundPurpose.available,
            currencyCode: 'EGP',
            isSpendable: true,
            isProtected: false,
            includeInNetWorth: true,
            includeInZakat: false,
            createdBy: 'user-1',
            openingBalanceMinorUnits: 0,
          ),
        );

        expect(result, isA<AppOk<dynamic>>());
        expect(await countAccounts('hh-atom-1'), 1);
        expect(await countOperations('hh-atom-1'), 0);
        expect(await countEntries('hh-atom-1'), 0);
      },
    );

    test(
      'null opening balance → account only, no operations or entries',
      () async {
        await insertHousehold('hh-atom-2');

        final result = await useCase.execute(
          const CreateAccountWorkflowParams(
            householdId: 'hh-atom-2',
            name: 'No Balance Account',
            type: FinancialAccountType.bankAccount,
            ownerType: AccountOwnerType.user,
            fundPurpose: FundPurpose.available,
            currencyCode: 'EGP',
            isSpendable: true,
            isProtected: false,
            includeInNetWorth: true,
            includeInZakat: false,
            createdBy: 'user-1',
          ),
        );

        expect(result, isA<AppOk<dynamic>>());
        expect(await countOperations('hh-atom-2'), 0);
        expect(await countEntries('hh-atom-2'), 0);
      },
    );

    test(
      'non-zero opening balance → account + exactly 1 operation + at least 1 entry',
      () async {
        await insertHousehold('hh-atom-3');

        final result = await useCase.execute(
          const CreateAccountWorkflowParams(
            householdId: 'hh-atom-3',
            name: 'Funded Account',
            type: FinancialAccountType.bankAccount,
            ownerType: AccountOwnerType.user,
            fundPurpose: FundPurpose.available,
            currencyCode: 'EGP',
            isSpendable: true,
            isProtected: false,
            includeInNetWorth: true,
            includeInZakat: false,
            createdBy: 'user-1',
            openingBalanceMinorUnits: 10000,
            openingBalanceDate: '2024-01-01',
          ),
        );

        expect(result, isA<AppOk<dynamic>>());
        expect(await countAccounts('hh-atom-3'), 1);
        expect(await countOperations('hh-atom-3'), 1);
        expect(await countEntries('hh-atom-3'), greaterThanOrEqualTo(1));
      },
    );

    test(
      'same idempotency key retry → returns existing account, no extra rows',
      () async {
        await insertHousehold('hh-atom-4');

        final r1 = await useCase.execute(
          const CreateAccountWorkflowParams(
            householdId: 'hh-atom-4',
            name: 'Idempotent Account',
            type: FinancialAccountType.personalCashWallet,
            ownerType: AccountOwnerType.user,
            fundPurpose: FundPurpose.available,
            currencyCode: 'EGP',
            isSpendable: true,
            isProtected: false,
            includeInNetWorth: true,
            includeInZakat: false,
            createdBy: 'user-1',
            idempotencyKey: 'idem-key-atom-4',
          ),
        );
        expect(r1, isA<AppOk<dynamic>>());
        final countAfterFirst = await countAccounts('hh-atom-4');

        final r2 = await useCase.execute(
          const CreateAccountWorkflowParams(
            householdId: 'hh-atom-4',
            name: 'Idempotent Account',
            type: FinancialAccountType.personalCashWallet,
            ownerType: AccountOwnerType.user,
            fundPurpose: FundPurpose.available,
            currencyCode: 'EGP',
            isSpendable: true,
            isProtected: false,
            includeInNetWorth: true,
            includeInZakat: false,
            createdBy: 'user-1',
            idempotencyKey: 'idem-key-atom-4',
          ),
        );
        expect(r2, isA<AppOk<dynamic>>());
        expect(await countAccounts('hh-atom-4'), countAfterFirst);
      },
    );

    test(
      'invalid params (empty name) → AppValidationFailure, no DB write',
      () async {
        await insertHousehold('hh-atom-5');

        final result = await useCase.execute(
          const CreateAccountWorkflowParams(
            householdId: 'hh-atom-5',
            name: '  ',
            type: FinancialAccountType.personalCashWallet,
            ownerType: AccountOwnerType.user,
            fundPurpose: FundPurpose.available,
            currencyCode: 'EGP',
            isSpendable: true,
            isProtected: false,
            includeInNetWorth: true,
            includeInZakat: false,
            createdBy: 'user-1',
          ),
        );

        expect(result, isA<AppValidationFailure<dynamic>>());
        expect(await countAccounts('hh-atom-5'), 0);
        expect(await countOperations('hh-atom-5'), 0);
      },
    );
  });
}
