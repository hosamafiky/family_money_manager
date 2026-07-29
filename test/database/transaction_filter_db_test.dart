/// Filtering and searching the transaction list.
///
/// Three rules carry real weight here. An amount band never crosses a
/// currency. Reversed history is included unless someone deliberately asks
/// otherwise. And the count the filter sheet promises is the count the list
/// then shows — a button that says "87" and produces 40 is worse than no
/// count at all.
library;

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/data/drift_transaction_query_repository.dart';
import 'package:family_money_manager/features/transactions/data/transaction_query_repository.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:flutter_test/flutter_test.dart';

const _householdId = 'hh-filter';
const _memberId = 'member-1';

void main() {
  late AppDatabase db;
  late AccountRepository accountRepo;
  late LedgerRepository ledgerRepo;
  late TransactionQueryRepository queryRepo;

  Future<void> createAccount(String id, String name, String currency) =>
      accountRepo
          .createAccount(
            CreateAccountParams(
              id: id,
              householdId: _householdId,
              name: name,
              type: FinancialAccountType.personalCashWallet,
              ownerType: AccountOwnerType.user,
              fundPurpose: FundPurpose.available,
              currencyCode: currency,
              isSpendable: true,
              isProtected: false,
              includeInNetWorth: true,
              includeInZakat: false,
              displayOrder: 0,
              createdBy: _memberId,
            ),
          )
          .then((_) {});

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
            name: 'Filter household',
            ownerUserId: _memberId,
            createdAt: '2026-07-01T00:00:00Z',
            updatedAt: '2026-07-01T00:00:00Z',
          ),
        );

    await createAccount('acc-egp', 'محفظة نقدية', 'EGP');
    await createAccount('acc-usd', 'Freelance account', 'USD');

    // Fund both so expenses have something to spend.
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: 'op-fund-egp',
        householdId: _householdId,
        destinationAccountId: 'acc-egp',
        amountMinorUnits: 1000000,
        currencyCode: 'EGP',
        effectiveDate: '2026-07-01',
        createdBy: _memberId,
      ),
    );
    await ledgerRepo.recordIncome(
      RecordIncomeParams(
        operationId: 'op-fund-usd',
        householdId: _householdId,
        destinationAccountId: 'acc-usd',
        amountMinorUnits: 100000,
        currencyCode: 'USD',
        effectiveDate: '2026-07-01',
        createdBy: _memberId,
      ),
    );

    // 382.50 EGP, 1,204.75 EGP, and 60.00 USD.
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: 'op-small',
        householdId: _householdId,
        sourceAccountId: 'acc-egp',
        amountMinorUnits: 38250,
        currencyCode: 'EGP',
        effectiveDate: '2026-07-25',
        createdBy: _memberId,
        categoryCode: 'groceries',
        description: 'بقالة — سوبر ماركت الفتح',
      ),
    );
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: 'op-large',
        householdId: _householdId,
        sourceAccountId: 'acc-egp',
        amountMinorUnits: 120475,
        currencyCode: 'EGP',
        effectiveDate: '2026-07-18',
        createdBy: _memberId,
        categoryCode: 'groceries',
        description: 'بقالة — كارفور',
      ),
    );
    await ledgerRepo.recordExpense(
      RecordExpenseParams(
        operationId: 'op-usd',
        householdId: _householdId,
        sourceAccountId: 'acc-usd',
        amountMinorUnits: 6000,
        currencyCode: 'USD',
        effectiveDate: '2026-07-20',
        createdBy: _memberId,
        categoryCode: 'groceries',
        description: 'Groceries — Whole Foods',
      ),
    );
  });

  tearDown(() async => db.close());

  Future<List<String>> idsMatching(TransactionFilter filter) async {
    final rows = await queryRepo.recentOperations(
      householdId: _householdId,
      filter: filter,
    );
    return rows.map((r) => r.operation.id).toList();
  }

  group('an amount band never crosses a currency', () {
    test('FILTER-1. A band in EGP does not match a USD row', () async {
      // 60.00 USD is 6000 minor units, which sits inside this band. Only the
      // currency keeps it out.
      final ids = await idsMatching(
        const TransactionFilter(
          amountRange: TransactionAmountRange(
            currencyCode: 'EGP',
            minMinorUnits: 5000,
            maxMinorUnits: 50000,
          ),
        ),
      );

      expect(ids, contains('op-small'));
      expect(ids, isNot(contains('op-usd')));
    });

    test('FILTER-2. Both bounds are inclusive', () async {
      final ids = await idsMatching(
        const TransactionFilter(
          amountRange: TransactionAmountRange(
            currencyCode: 'EGP',
            minMinorUnits: 38250,
            maxMinorUnits: 38250,
          ),
        ),
      );

      expect(ids, ['op-small']);
    });

    test('FILTER-3. A one-sided band restricts only that side', () async {
      final ids = await idsMatching(
        const TransactionFilter(
          amountRange: TransactionAmountRange(
            currencyCode: 'EGP',
            minMinorUnits: 100000,
          ),
        ),
      );

      expect(ids, containsAll(<String>['op-large', 'op-fund-egp']));
      expect(ids, isNot(contains('op-small')));
    });
  });

  group('reversed history is included by default', () {
    setUp(() async {
      await ledgerRepo.reverseOperation(
        const ReverseOperationParams(
          reversalOperationId: 'op-rev',
          originalOperationId: 'op-small',
          householdId: _householdId,
          effectiveDate: '2026-07-26',
          createdBy: _memberId,
          reason: 'أُدخلت مرتين',
        ),
      );
    });

    test('FILTER-4. The default filter shows both halves', () async {
      final ids = await idsMatching(const TransactionFilter());

      expect(ids, containsAll(<String>['op-small', 'op-rev']));
    });

    test('FILTER-5. Opting out removes both halves, not just one', () async {
      final ids = await idsMatching(
        const TransactionFilter(includeReversed: false),
      );

      expect(ids, isNot(contains('op-small')));
      expect(ids, isNot(contains('op-rev')));
      // Everything else is untouched.
      expect(ids, contains('op-large'));
    });
  });

  group('search', () {
    test('FILTER-6. Matches a description', () async {
      final ids = await idsMatching(
        const TransactionFilter(searchQuery: 'كارفور'),
      );

      expect(ids, ['op-large']);
    });

    test('FILTER-7. Matches an account name', () async {
      final ids = await idsMatching(
        const TransactionFilter(searchQuery: 'Freelance'),
      );

      expect(ids, contains('op-usd'));
      expect(ids, isNot(contains('op-small')));
    });

    test(
      'FILTER-8. A wildcard character is searched for, not interpreted',
      () async {
        // Without escaping, '%' would match every row.
        final ids = await idsMatching(
          const TransactionFilter(searchQuery: '%'),
        );

        expect(ids, isEmpty);
      },
    );

    test('FILTER-9. Search composes with the other criteria', () async {
      final ids = await idsMatching(
        const TransactionFilter(
          searchQuery: 'بقالة',
          amountRange: TransactionAmountRange(
            currencyCode: 'EGP',
            maxMinorUnits: 50000,
          ),
        ),
      );

      expect(ids, ['op-small']);
    });
  });

  group('the promised count is the delivered count', () {
    test(
      'FILTER-10. countOperations agrees with the list it describes',
      () async {
        const filter = TransactionFilter(
          amountRange: TransactionAmountRange(
            currencyCode: 'EGP',
            minMinorUnits: 100000,
          ),
        );

        final count = await queryRepo.countOperations(
          householdId: _householdId,
          filter: filter,
        );
        final ids = await idsMatching(filter);

        expect(count, ids.length);
        expect(count, greaterThan(0));
      },
    );

    test(
      'FILTER-11. The count ignores the page size — it is the total the page '
      'would otherwise hide',
      () async {
        final count = await queryRepo.countOperations(
          householdId: _householdId,
          filter: const TransactionFilter(pageSize: 1),
        );
        final ids = await idsMatching(const TransactionFilter(pageSize: 1));

        expect(ids, hasLength(1));
        expect(count, 5);
      },
    );

    test('FILTER-12. A filter matching nothing counts zero', () async {
      final count = await queryRepo.countOperations(
        householdId: _householdId,
        filter: const TransactionFilter(searchQuery: 'nothing matches this'),
      );

      expect(count, 0);
    });

    test('FILTER-13. Another household is never counted', () async {
      final count = await queryRepo.countOperations(householdId: 'hh-other');

      expect(count, 0);
    });
  });

  test(
    'FILTER-14. Filtering by account matches both sides of a move',
    () async {
      final ids = await idsMatching(
        const TransactionFilter(accountId: 'acc-usd'),
      );

      expect(ids, containsAll(<String>['op-usd', 'op-fund-usd']));
      expect(ids, isNot(contains('op-small')));
    },
  );
}
