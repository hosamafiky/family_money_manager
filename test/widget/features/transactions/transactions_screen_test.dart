/// The transaction list.
///
/// The claims under test are the ones the design insists on: rows name people
/// and accounts rather than UUIDs, days are headed and counted, the transfer
/// total is labelled and kept out of income and expense, and a reversed pair
/// appears as two adjacent rows that between them explain the balance.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:family_money_manager/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';
const _walletName = 'محفظة نقدية شخصية';
const _spenderName = 'هناء';

TransactionSummary _tx({
  required String id,
  required OperationType type,
  required int amount,
  String date = '2026-07-25',
  String currency = 'EGP',
  bool isReversed = false,
  String? reversalReason,
  String? description,
  String? spenderName = _spenderName,
  String? sourceAccountName = _walletName,
}) => TransactionSummary(
  operation: Operation(
    id: id,
    householdId: _householdId,
    type: type,
    effectiveDate: date,
    recordedAt: DateTime.utc(2026, 7, 25),
    totalAmountMinorUnits: amount,
    currencyCode: currency,
    createdBy: 'member-hana',
    createdAt: '2026-07-25T00:00:00Z',
    updatedAt: '2026-07-25T00:00:00Z',
    isReversed: isReversed,
    reversalReason: reversalReason,
    description: description,
    sourceAccountId: 'acc-1',
  ),
  categoryCode: 'groceries',
  isRecurring: false,
  spenderName: spenderName,
  sourceAccountName: sourceAccountName,
);

/// Records the filters the screen asked the list provider for.
final List<TransactionFilter> requestedFilters = [];

Widget _buildApp(
  AppResult<List<TransactionSummary>> result, {
  AppResult<List<TransactionSummary>>? filteredResult,
  int unfilteredCount = 1248,
}) {
  final router = GoRouter(
    initialLocation: '/transactions',
    routes: [
      GoRoute(
        path: '/transactions',
        builder: (_, _) => const TransactionsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, _) => const Scaffold(body: Text('New transaction')),
          ),
          GoRoute(
            path: ':operationId',
            builder: (_, state) => Scaffold(
              body: Text('Detail ${state.pathParameters['operationId']}'),
            ),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase.forTesting();
        ref.onDispose(db.close);
        return db;
      }),
      transactionListProvider.overrideWith((ref, args) async {
        final (_, filter) = args;
        requestedFilters.add(filter);
        final isFiltered =
            filter.hasActiveCriteria ||
            (filter.searchQuery?.isNotEmpty ?? false);
        return isFiltered ? (filteredResult ?? result) : result;
      }),
      transactionCountProvider.overrideWith((ref, args) async {
        final (_, filter) = args;
        return filter.hasActiveCriteria ? 87 : unfilteredCount;
      }),
    ],
    child: MaterialApp.router(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
}

/// The type chip inside the filter sheet.
///
/// Scoped to the sheet on purpose: the same type label is on every list row
/// behind it, so an unscoped finder is ambiguous.
Finder _typeChip(AppLocalizations l10n, OperationType type) => find.descendant(
  of: find.byType(FilterChip),
  matching: find.text(operationTypeLabel(l10n, type)),
);

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(TransactionsScreen)));

void main() {
  setUp(() {
    requestedFilters.clear();
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 3200);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  testWidgets('rows name the spender and the account, never UUIDs', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        AppOk([_tx(id: 'a', type: OperationType.expense, amount: 38250)]),
      ),
    );
    await tester.pump();

    expect(find.textContaining(_walletName), findsWidgets);
    expect(find.textContaining(_spenderName), findsWidgets);
    expect(find.textContaining('acc-1'), findsNothing);
  });

  testWidgets('each day is headed and carries its own count', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        AppOk([
          _tx(
            id: 'a',
            type: OperationType.expense,
            amount: 38250,
            date: '2026-07-25',
          ),
          _tx(
            id: 'b',
            type: OperationType.expense,
            amount: 6800,
            date: '2026-07-25',
          ),
          _tx(
            id: 'c',
            type: OperationType.expense,
            amount: 450000,
            date: '2026-07-24',
          ),
        ]),
      ),
    );
    await tester.pump();

    final l10n = _l10n(tester);
    expect(find.textContaining('2026-07-25'), findsWidgets);
    expect(find.textContaining('2026-07-24'), findsWidgets);
    expect(find.text(l10n.transactionsGroupCount('2')), findsOneWidget);
    expect(find.text(l10n.transactionsGroupCount('1')), findsOneWidget);
  });

  testWidgets(
    'the transfer total is labelled and separate from income and expense',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          AppOk([
            _tx(id: 'a', type: OperationType.income, amount: 1840000),
            _tx(id: 'b', type: OperationType.expense, amount: 968425),
            _tx(id: 'c', type: OperationType.transfer, amount: 5228200),
          ]),
        ),
      );
      await tester.pump();

      final l10n = _l10n(tester);
      final transferMetric = tester.widget<FinancialMetric>(
        find.ancestor(
          of: find.text(l10n.transactionsSummaryTransfer),
          matching: find.byType(FinancialMetric),
        ),
      );
      expect(transferMetric.minorUnits, 5228200);

      final incomeMetric = tester.widget<FinancialMetric>(
        find.ancestor(
          of: find.text(l10n.transactionsSummaryIncome),
          matching: find.byType(FinancialMetric),
        ),
      );
      // The transfer is nowhere in the income figure.
      expect(incomeMetric.minorUnits, 1840000);
      expect(find.text(l10n.transactionsTransferNotCounted), findsOneWidget);
    },
  );

  testWidgets('a second currency gets its own summary, and says so', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        AppOk([
          _tx(id: 'a', type: OperationType.expense, amount: 38250),
          _tx(
            id: 'b',
            type: OperationType.income,
            amount: 32000,
            currency: 'USD',
          ),
        ]),
      ),
    );
    await tester.pump();

    final l10n = _l10n(tester);
    expect(
      find.text(l10n.transactionsSummaryCurrencyOnly('EGP')),
      findsOneWidget,
    );
    expect(
      find.text(l10n.transactionsSummaryCurrencyOnly('USD')),
      findsOneWidget,
    );
  });

  testWidgets(
    'a reversed pair shows both rows: the original says it was kept, the '
    'reversing entry says why',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          AppOk([
            _tx(
              id: 'reversal',
              type: OperationType.reversal,
              amount: 127500,
              reversalReason: 'أُدخلت مرتين',
              description: 'حركة عكسية — فاتورة كهرباء',
            ),
            _tx(
              id: 'original',
              type: OperationType.expense,
              amount: 127500,
              isReversed: true,
              description: 'فاتورة كهرباء',
            ),
          ]),
        ),
      );
      await tester.pump();

      final l10n = _l10n(tester);
      // Both are present. Hiding either would make the ledger or the balance
      // incomprehensible.
      expect(find.text('فاتورة كهرباء'), findsOneWidget);
      expect(find.text('حركة عكسية — فاتورة كهرباء'), findsOneWidget);

      expect(find.text(l10n.transactionReversed), findsOneWidget);
      expect(
        find.textContaining(l10n.transactionsReversedOriginalMeta),
        findsOneWidget,
      );
      expect(find.textContaining('أُدخلت مرتين'), findsOneWidget);
    },
  );

  testWidgets('a reversed pair contributes nothing to the summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        AppOk([
          _tx(id: 'reversal', type: OperationType.reversal, amount: 127500),
          _tx(
            id: 'original',
            type: OperationType.expense,
            amount: 127500,
            isReversed: true,
          ),
          _tx(id: 'live', type: OperationType.expense, amount: 6800),
        ]),
      ),
    );
    await tester.pump();

    final l10n = _l10n(tester);
    final expenseMetric = tester.widget<FinancialMetric>(
      find.ancestor(
        of: find.text(l10n.transactionsSummaryExpense),
        matching: find.byType(FinancialMetric),
      ),
    );
    expect(expenseMetric.minorUnits, 6800);
  });

  testWidgets('tapping a row opens its detail', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        AppOk([_tx(id: 'op-7', type: OperationType.expense, amount: 38250)]),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(TransactionListTile));
    await tester.pumpAndSettle();

    expect(find.text('Detail op-7'), findsOneWidget);
  });

  testWidgets('an empty ledger offers the way to start one', (tester) async {
    await tester.pumpWidget(_buildApp(const AppOk(<TransactionSummary>[])));
    await tester.pump();

    final l10n = _l10n(tester);
    expect(find.text(l10n.transactionsEmpty), findsOneWidget);
    expect(find.text(l10n.actionRecordExpense), findsOneWidget);
  });

  testWidgets('a failed read says so without claiming anything was lost', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(const AppPersistenceFailure<List<TransactionSummary>>()),
    );
    await tester.pump();

    final l10n = _l10n(tester);
    expect(find.text(l10n.transactionsErrorTitle), findsOneWidget);
  });

  group('filtering and search', () {
    testWidgets(
      'the filter sheet puts its result count on the confirm button',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            AppOk([_tx(id: 'a', type: OperationType.expense, amount: 38250)]),
          ),
        );
        await tester.pump();

        final l10n = _l10n(tester);
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        // Nothing selected yet: the count is the whole ledger.
        expect(find.text(l10n.transactionsFilterApply('1248')), findsOneWidget);

        await tester.tap(_typeChip(l10n, OperationType.expense));
        await tester.pumpAndSettle();

        // Selecting a type changes the promised count before it is applied.
        expect(find.text(l10n.transactionsFilterApply('87')), findsOneWidget);
      },
    );

    testWidgets('applying a filter reaches the list query', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          AppOk([_tx(id: 'a', type: OperationType.expense, amount: 38250)]),
        ),
      );
      await tester.pump();

      final l10n = _l10n(tester);
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(_typeChip(l10n, OperationType.income));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.transactionsFilterApply('87')));
      await tester.pumpAndSettle();

      expect(requestedFilters.last.operationType, OperationType.income);
    });

    testWidgets('reversed history is shown unless deliberately excluded', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          AppOk([_tx(id: 'a', type: OperationType.expense, amount: 38250)]),
        ),
      );
      await tester.pump();

      // The default the screen opens with, not merely the sheet's toggle.
      expect(requestedFilters.first.includeReversed, isTrue);

      final l10n = _l10n(tester);
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.transactionsFilterShowReversed));
      await tester.pumpAndSettle();
      // By type, because the confirm label carries a count that moves with
      // the draft — asserting on the text here would re-test the count.
      await tester.tap(find.byType(PrimaryActionButton));
      await tester.pumpAndSettle();

      expect(requestedFilters.last.includeReversed, isFalse);
    });

    testWidgets('search drops the period, and says so', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          AppOk([_tx(id: 'a', type: OperationType.expense, amount: 38250)]),
        ),
      );
      await tester.pump();

      final l10n = _l10n(tester);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text(l10n.transactionsSearchIgnoresPeriod), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'بقالة 382');
      await tester.pumpAndSettle();

      expect(requestedFilters.last.searchQuery, 'بقالة 382');
      expect(requestedFilters.last.fromDate, isNull);
      expect(requestedFilters.last.toDate, isNull);
    });

    testWidgets(
      'an empty filtered result is a filter problem, not an empty ledger',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            AppOk([_tx(id: 'a', type: OperationType.expense, amount: 38250)]),
            filteredResult: const AppOk(<TransactionSummary>[]),
          ),
        );
        await tester.pump();

        final l10n = _l10n(tester);
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'nothing matches');
        await tester.pumpAndSettle();

        expect(find.text(l10n.transactionsEmptyFilteredTitle), findsOneWidget);
        // It names the count the user does have.
        expect(
          find.text(l10n.transactionsEmptyFilteredBody('1248')),
          findsOneWidget,
        );
        expect(find.text(l10n.transactionsClearFilters), findsOneWidget);
        // Not the empty-ledger copy.
        expect(find.text(l10n.transactionsEmpty), findsNothing);
      },
    );

    testWidgets('clearing the filter restores the unfiltered list', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          AppOk([_tx(id: 'a', type: OperationType.expense, amount: 38250)]),
          filteredResult: const AppOk(<TransactionSummary>[]),
        ),
      );
      await tester.pump();

      final l10n = _l10n(tester);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nothing matches');
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.transactionsClearFilters));
      await tester.pumpAndSettle();

      // The unfiltered list is back and the search field is gone. Asserting
      // on the recorded filter would be wrong here: the unfiltered query is
      // already cached, so clearing issues no new request.
      expect(find.byType(TransactionListTile), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
