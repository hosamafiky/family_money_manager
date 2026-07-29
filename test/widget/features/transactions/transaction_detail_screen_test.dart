/// Transaction detail.
///
/// Three claims are under test. The amount is money, not a raw integer — this
/// screen printed 382.50 EGP as "38250 EGP" before. Accounts and members are
/// named, not UUIDs. And the screen answers "where is edit" out loud: the
/// double entry is shown, the append-only explainer is permanent, and a
/// reversed operation renders the lineage instead of a second reversal.
library;

import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_detail.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:family_money_manager/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _operationId = 'op-1';
const _walletName = 'محفظة نقدية شخصية';
const _spenderName = 'هناء عبد الرحمن';

TransactionDetail _detail({
  bool isReversed = false,
  String? reversalReason,
  OperationType type = OperationType.expense,
  ReversalCounterpart? counterpart,
  List<OperationLedgerLine> ledgerLines = const [
    OperationLedgerLine(
      entryId: 'entry-debit',
      direction: LedgerDirection.debit,
      accountId: 'acc-1',
      accountName: _walletName,
      amountMinorUnits: 38250,
      currencyCode: 'EGP',
      entryType: LedgerEntryType.expense,
    ),
  ],
}) => TransactionDetail(
  summary: TransactionSummary(
    operation: Operation(
      id: _operationId,
      householdId: 'household-v1',
      type: type,
      effectiveDate: '2026-07-25',
      recordedAt: DateTime.utc(2026, 7, 25, 14, 21),
      totalAmountMinorUnits: 38250,
      currencyCode: 'EGP',
      createdBy: 'member-hana',
      createdAt: '2026-07-25T14:21:00Z',
      updatedAt: '2026-07-25T14:21:00Z',
      isReversed: isReversed,
      reversalReason: reversalReason,
      sourceAccountId: 'acc-1',
    ),
    categoryCode: 'groceries',
    spenderMemberId: 'member-hana',
    isRecurring: false,
    spenderName: _spenderName,
    sourceAccountName: _walletName,
    createdByName: _spenderName,
  ),
  ledgerLines: ledgerLines,
  counterpart: counterpart,
);

Widget _buildApp(TransactionDetail detail) {
  final router = GoRouter(
    initialLocation: '/transactions/$_operationId',
    routes: [
      GoRoute(
        path: '/transactions',
        builder: (_, _) => const Scaffold(body: Text('Transactions')),
        routes: [
          GoRoute(
            path: ':operationId',
            builder: (_, state) => TransactionDetailScreen(
              operationId: state.pathParameters['operationId']!,
            ),
            routes: [
              GoRoute(
                path: 'reverse',
                builder: (_, _) => const Scaffold(body: Text('Reverse screen')),
              ),
            ],
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
      transactionDetailWithLedgerProvider.overrideWith(
        (ref, _) async => detail,
      ),
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

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(
  tester.element(find.byType(TransactionDetailScreen).first),
);

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 3200);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  testWidgets('the amount goes through the money component, not raw units', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(_detail()));
    await tester.pump();

    final amount = tester.widget<FinancialAmountText>(
      find.byType(FinancialAmountText).first,
    );
    expect(amount.minorUnits, 38250);
    expect(amount.currencyCode, 'EGP');
    expect(amount.direction, FinancialAmountDirection.outflow);
    // The old rendering: minor units printed verbatim.
    expect(find.text('38250 EGP'), findsNothing);
  });

  testWidgets('the double entry is shown, named and labelled by side', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _detail(
          ledgerLines: const [
            OperationLedgerLine(
              entryId: 'entry-debit',
              direction: LedgerDirection.debit,
              accountId: 'cat-groceries',
              accountName: 'بقالة',
              amountMinorUnits: 38250,
              currencyCode: 'EGP',
              entryType: LedgerEntryType.expense,
            ),
            OperationLedgerLine(
              entryId: 'entry-credit',
              direction: LedgerDirection.credit,
              accountId: 'acc-1',
              accountName: _walletName,
              amountMinorUnits: 38250,
              currencyCode: 'EGP',
              entryType: LedgerEntryType.expense,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    final l10n = _l10n(tester);
    expect(find.text(l10n.detailLedgerEntriesTitle), findsOneWidget);
    expect(find.text(l10n.reviewDebitLabel('بقالة')), findsOneWidget);
    expect(find.text(l10n.reviewCreditLabel(_walletName)), findsOneWidget);
  });

  testWidgets('accounts and members are named, never UUIDs', (tester) async {
    await tester.pumpWidget(_buildApp(_detail()));
    await tester.pump();

    expect(find.text(_walletName), findsWidgets);
    expect(find.text(_spenderName), findsOneWidget);
    expect(find.text('acc-1'), findsNothing);
    expect(find.text('member-hana'), findsNothing);
  });

  testWidgets('the append-only explainer is always present', (tester) async {
    await tester.pumpWidget(_buildApp(_detail()));
    await tester.pump();

    final l10n = _l10n(tester);
    expect(find.text(l10n.detailNoEditNoDeleteTitle), findsOneWidget);
    expect(find.text(l10n.detailNoEditNoDeleteBody), findsOneWidget);
  });

  testWidgets('the reversal action opens the reversal route', (tester) async {
    await tester.pumpWidget(_buildApp(_detail()));
    await tester.pump();

    final l10n = _l10n(tester);
    await tester.tap(find.text(l10n.detailAddReversalAction));
    await tester.pumpAndSettle();

    expect(find.text('Reverse screen'), findsOneWidget);
  });

  testWidgets(
    'a reversed original is struck through, keeps its entries, and offers no '
    'second reversal',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _detail(
            isReversed: true,
            counterpart: const ReversalCounterpart(
              operationId: 'op-rev',
              effectiveDate: '2026-07-25',
              totalAmountMinorUnits: 38250,
              currencyCode: 'EGP',
              isReversingEntry: true,
              reason: 'أُدخلت مرتين',
              authorName: 'أحمد',
            ),
          ),
        ),
      );
      await tester.pump();

      final l10n = _l10n(tester);
      final amount = tester.widget<FinancialAmountText>(
        find.byType(FinancialAmountText).first,
      );
      expect(amount.isStruckThrough, isTrue);
      expect(amount.tone, FinancialAmountTone.muted);

      expect(find.text(l10n.detailAlreadyReversedNoAction), findsOneWidget);
      expect(find.text(l10n.detailAddReversalAction), findsNothing);
      // The entries are still there — they were answered, not erased.
      expect(find.text(l10n.detailLedgerEntriesOriginalTitle), findsOneWidget);
      expect(find.text(l10n.detailEntriesStillInLedgerNote), findsOneWidget);
    },
  );

  testWidgets(
    'the lineage is numbered, marks where you are, and states the net as zero',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _detail(
            isReversed: true,
            counterpart: const ReversalCounterpart(
              operationId: 'op-rev',
              effectiveDate: '2026-07-26',
              totalAmountMinorUnits: 38250,
              currencyCode: 'EGP',
              isReversingEntry: true,
              reason: 'أُدخلت مرتين',
              authorName: 'أحمد',
            ),
          ),
        ),
      );
      await tester.pump();

      final l10n = _l10n(tester);
      expect(find.text(l10n.detailChainTitle), findsOneWidget);
      expect(
        find.text(l10n.detailChainStepOriginal('1', '2026-07-25')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.detailChainStepReversal('2', '2026-07-26')),
        findsOneWidget,
      );
      expect(find.text(l10n.detailChainYouAreHere), findsOneWidget);
      // The reason and its author ride on the reversing step itself.
      expect(
        find.text(l10n.detailChainReasonBy('أُدخلت مرتين', 'أحمد')),
        findsOneWidget,
      );

      final netRow = tester.widget<CurrencyAmountRow>(
        find.ancestor(
          of: find.text(l10n.reversalNetEffectOn(_walletName)),
          matching: find.byType(CurrencyAmountRow),
        ),
      );
      expect(netRow.minorUnits, 0);
    },
  );

  testWidgets('the other half of the pair is reachable from the chain', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _detail(
          isReversed: true,
          counterpart: const ReversalCounterpart(
            operationId: 'op-rev',
            effectiveDate: '2026-07-26',
            totalAmountMinorUnits: 38250,
            currencyCode: 'EGP',
            isReversingEntry: true,
            reason: 'أُدخلت مرتين',
            authorName: 'أحمد',
          ),
        ),
      ),
    );
    await tester.pump();

    final l10n = _l10n(tester);
    await tester.tap(
      find.text(l10n.detailChainStepReversal('2', '2026-07-26')),
    );
    await tester.pumpAndSettle();

    // A second detail screen is now on top, opened on the other half. The
    // first is still mounted underneath, which is why offstage is included.
    expect(
      find.byType(TransactionDetailScreen, skipOffstage: false),
      findsNWidgets(2),
    );
    expect(
      tester
          .widgetList<TransactionDetailScreen>(
            find.byType(TransactionDetailScreen, skipOffstage: false),
          )
          .last
          .operationId,
      'op-rev',
    );
  });

  testWidgets('a recorded reversal reason is shown verbatim', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _detail(
          type: OperationType.reversal,
          reversalReason: 'أُدخلت مرتين بالخطأ',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('أُدخلت مرتين بالخطأ'), findsOneWidget);
  });
}
