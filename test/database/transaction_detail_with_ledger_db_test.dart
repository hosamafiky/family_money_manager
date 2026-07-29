/// The detail query: ledger lines, resolved names, and the reversal pair.
///
/// The screen above this was printing UUIDs where names belong and had no way
/// to show the two sides of a double entry at all. These tests pin the joins
/// that fix both, and the walk between the halves of a reversal — which is
/// what makes an append-only ledger navigable rather than merely honest.
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
import 'package:family_money_manager/features/transactions/data/drift_transaction_query_repository.dart';
import 'package:family_money_manager/features/transactions/data/transaction_query_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _householdId = 'hh-detail';
const _memberId = 'member-hana';

void main() {
  late AppDatabase db;
  late AccountRepository accountRepo;
  late LedgerRepository ledgerRepo;
  late TransactionQueryRepository queryRepo;

  setUp(() async {
    db = AppDatabase.forTesting();
    accountRepo = DriftAccountRepository(db);
    ledgerRepo = DriftLedgerRepository(db);
    queryRepo = DriftTransactionQueryRepository(db);

    await db
        .into(db.households)
        .insert(
          HouseholdsCompanion.insert(
            id: _householdId,
            name: 'Detail household',
            ownerUserId: _memberId,
            createdAt: '2026-07-01T00:00:00Z',
            updatedAt: '2026-07-01T00:00:00Z',
          ),
        );
    await db
        .into(db.householdMembers)
        .insert(
          HouseholdMembersCompanion.insert(
            id: _memberId,
            householdId: _householdId,
            displayName: 'هناء عبد الرحمن',
            role: 'spouse',
            createdAt: '2026-07-01T00:00:00Z',
            updatedAt: '2026-07-01T00:00:00Z',
          ),
        );

    await accountRepo.createAccount(
      const CreateAccountParams(
        id: 'acc-wallet',
        householdId: _householdId,
        name: 'محفظة نقدية شخصية',
        type: FinancialAccountType.personalCashWallet,
        ownerType: AccountOwnerType.user,
        fundPurpose: FundPurpose.available,
        currencyCode: 'EGP',
        isSpendable: true,
        isProtected: false,
        includeInNetWorth: true,
        includeInZakat: false,
        displayOrder: 0,
        createdBy: _memberId,
      ),
    );
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: 'op-fund',
        householdId: _householdId,
        destinationAccountId: 'acc-wallet',
        amountMinorUnits: 50000,
        currencyCode: 'EGP',
        effectiveDate: '2026-07-01',
        createdBy: _memberId,
      ),
    );
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: 'op-groceries',
        householdId: _householdId,
        sourceAccountId: 'acc-wallet',
        amountMinorUnits: 38250,
        currencyCode: 'EGP',
        effectiveDate: '2026-07-25',
        createdBy: _memberId,
        categoryCode: 'groceries',
      ),
    );
  });

  tearDown(() async => db.close());

  Future<void> reverseGroceries() => ledgerRepo
      .reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'op-rev',
          originalOperationId: 'op-groceries',
          householdId: _householdId,
          effectiveDate: '2026-07-25',
          createdBy: _memberId,
          reason: 'أُدخلت مرتين',
        ),
      )
      .then((_) {});

  test('DETAIL-1. Both sides of the double entry come back, named', () async {
    final detail = await queryRepo.operationDetailWithLedger(
      operationId: 'op-groceries',
      householdId: _householdId,
    );

    expect(detail, isNotNull);
    expect(detail!.ledgerLines, hasLength(1));

    final line = detail.ledgerLines.single;
    expect(line.direction, LedgerDirection.debit);
    expect(line.accountId, 'acc-wallet');
    // The whole point of the join: a name, not a UUID.
    expect(line.accountName, 'محفظة نقدية شخصية');
    expect(line.amountMinorUnits, 38250);
  });

  test('DETAIL-2. Account and member ids resolve to display names', () async {
    final detail = await queryRepo.operationDetailWithLedger(
      operationId: 'op-groceries',
      householdId: _householdId,
    );

    expect(detail!.summary.sourceAccountName, 'محفظة نقدية شخصية');
    expect(detail.summary.createdByName, 'هناء عبد الرحمن');
  });

  test('DETAIL-3. An unreversed operation has no counterpart', () async {
    final detail = await queryRepo.operationDetailWithLedger(
      operationId: 'op-groceries',
      householdId: _householdId,
    );

    expect(detail!.counterpart, isNull);
    expect(detail.isNeutralised, isFalse);
  });

  test('DETAIL-4. From the original, the counterpart is the reversing entry, '
      'with its reason and author', () async {
    await reverseGroceries();

    final detail = await queryRepo.operationDetailWithLedger(
      operationId: 'op-groceries',
      householdId: _householdId,
    );

    final counterpart = detail!.counterpart;
    expect(counterpart, isNotNull);
    expect(counterpart!.operationId, 'op-rev');
    expect(counterpart.isReversingEntry, isTrue);
    expect(counterpart.reason, 'أُدخلت مرتين');
    expect(counterpart.authorName, 'هناء عبد الرحمن');
    expect(detail.isNeutralised, isTrue);
  });

  test(
    'DETAIL-5. From the reversal, the counterpart is the original — the walk '
    'goes both ways',
    () async {
      await reverseGroceries();

      final detail = await queryRepo.operationDetailWithLedger(
        operationId: 'op-rev',
        householdId: _householdId,
      );

      final counterpart = detail!.counterpart;
      expect(counterpart, isNotNull);
      expect(counterpart!.operationId, 'op-groceries');
      expect(counterpart.isReversingEntry, isFalse);
      // The reason lives on the reversal being viewed, so it is still shown.
      expect(counterpart.reason, 'أُدخلت مرتين');
      expect(detail.summary.operation.type, OperationType.reversal);
    },
  );

  test('DETAIL-6. A reversed original keeps its ledger lines — they were never '
      'deleted', () async {
    await reverseGroceries();

    final detail = await queryRepo.operationDetailWithLedger(
      operationId: 'op-groceries',
      householdId: _householdId,
    );

    expect(detail!.ledgerLines, hasLength(1));
    expect(detail.ledgerLines.single.amountMinorUnits, 38250);
    expect(detail.summary.operation.isReversed, isTrue);
  });

  test(
    'DETAIL-7. A missing operation returns null, not an empty detail',
    () async {
      final detail = await queryRepo.operationDetailWithLedger(
        operationId: 'op-does-not-exist',
        householdId: _householdId,
      );

      expect(detail, isNull);
    },
  );

  test('DETAIL-8. Another household cannot read this operation', () async {
    final detail = await queryRepo.operationDetailWithLedger(
      operationId: 'op-groceries',
      householdId: 'hh-other',
    );

    expect(detail, isNull);
  });
}
