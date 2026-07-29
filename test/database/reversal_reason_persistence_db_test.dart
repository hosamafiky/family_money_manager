/// The reversal reason survives the round trip, and cannot be edited after.
///
/// The v19→v20 migration test proves the column arrives. This proves it is
/// actually written, read back on the domain object, kept off the original,
/// and frozen by the append-only guard — which together are what make the
/// reason an audit field rather than a form value that happens to be stored.
library;

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:flutter_test/flutter_test.dart';

const _householdId = 'hh-reason';
const _userId = 'user-reason';

void main() {
  late AppDatabase db;
  late AccountRepository accountRepo;
  late LedgerRepository ledgerRepo;

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);

    // financial_accounts has a FK to households; seed the required household.
    await db
        .into(db.households)
        .insert(
          HouseholdsCompanion.insert(
            id: _householdId,
            name: 'Reason household',
            ownerUserId: _userId,
            createdAt: '2026-07-01T00:00:00Z',
            updatedAt: '2026-07-01T00:00:00Z',
          ),
        );

    await accountRepo.createAccount(
      const CreateAccountParams(
        id: 'acc-reason',
        householdId: _householdId,
        name: 'Wallet',
        type: FinancialAccountType.personalCashWallet,
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: _userId,
      ),
    );
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: 'op-fund',
        householdId: _householdId,
        destinationAccountId: 'acc-reason',
        amountMinorUnits: 50000,
        currencyCode: 'EGP',
        effectiveDate: '2026-07-01',
        createdBy: _userId,
      ),
    );
  });

  tearDown(() async => db.close());

  Future<void> reverseFundingWith(String? reason) => ledgerRepo
      .reverseOperation(
        ReverseOperationParams(
          reversalOperationId: 'op-rev',
          originalOperationId: 'op-fund',
          householdId: _householdId,
          effectiveDate: '2026-07-25',
          createdBy: _userId,
          reason: reason,
        ),
      )
      .then((_) {});

  test(
    'REASON-1. The reason is written on the reversal and read back',
    () async {
      await reverseFundingWith('أُدخلت مرتين بالخطأ');

      final reversal = await ledgerRepo.findOperation(
        operationId: 'op-rev',
        householdId: _householdId,
      );

      expect(reversal, isNotNull);
      expect(reversal!.type, OperationType.reversal);
      expect(reversal.reversalReason, 'أُدخلت مرتين بالخطأ');
    },
  );

  test('REASON-2. The original keeps no reason of its own', () async {
    await reverseFundingWith('Entered twice');

    final original = await ledgerRepo.findOperation(
      operationId: 'op-fund',
      householdId: _householdId,
    );

    // The original is marked reversed and linked — and nothing else about it
    // changes. A reason belongs to the correction, not to what was corrected.
    expect(original!.isReversed, isTrue);
    expect(original.reversedBy, 'op-rev');
    expect(original.reversalReason, isNull);
  });

  test('REASON-3. A reversal recorded without a reason reads back null, not a '
      'generated summary', () async {
    await reverseFundingWith(null);

    final reversal = await ledgerRepo.findOperation(
      operationId: 'op-rev',
      householdId: _householdId,
    );

    // `description` still carries the fallback text, so the two are not
    // interchangeable: a caller can tell "no reason was given" from
    // "the reason was ...".
    expect(reversal!.reversalReason, isNull);
    expect(reversal.description, contains('op-fund'));
  });

  test('REASON-4. A recorded reason cannot be edited afterwards', () async {
    await reverseFundingWith('Entered twice');

    await expectLater(
      db.customStatement(
        "UPDATE operations SET reversal_reason = 'something else' "
        "WHERE id = 'op-rev'",
      ),
      throwsA(anything),
    );

    final reversal = await ledgerRepo.findOperation(
      operationId: 'op-rev',
      householdId: _householdId,
    );
    expect(reversal!.reversalReason, 'Entered twice');
  });
}
