/// The reversal screen.
///
/// What is being asserted is the teaching, not the plumbing: the screen shows
/// what will be *added* and that the pair nets to zero, it will not submit
/// without a reason, an already-reversed transaction explains the missing
/// action instead of hiding it, and a failed write stays on screen.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:family_money_manager/features/transactions/presentation/reverse_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _operationId = 'op-1';

const _fakeAccount = FinancialAccount(
  id: 'acc-1',
  householdId: 'household-v1',
  name: 'محفظة نقدية شخصية',
  type: FinancialAccountType.personalCashWallet,
  ownerType: AccountOwnerType.user,
  fundPurpose: FundPurpose.available,
  currencyCode: 'EGP',
  isSpendable: true,
  isProtected: false,
  includeInNetWorth: true,
  includeInZakat: false,
  isArchived: false,
  displayOrder: 0,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
  createdBy: 'member-primary-v1',
);

TransactionSummary _summary({bool isReversed = false}) => TransactionSummary(
  operation: Operation(
    id: _operationId,
    householdId: 'household-v1',
    type: OperationType.expense,
    effectiveDate: '2026-07-25',
    recordedAt: DateTime.utc(2026, 7, 25, 14, 21),
    totalAmountMinorUnits: 38250,
    currencyCode: 'EGP',
    createdBy: 'member-primary-v1',
    createdAt: '2026-07-25T14:21:00Z',
    updatedAt: '2026-07-25T14:21:00Z',
    isReversed: isReversed,
    sourceAccountId: 'acc-1',
  ),
  categoryCode: 'groceries',
  isRecurring: false,
);

/// A ledger that answers reversals however the test needs.
final class _StubLedgerRepository implements LedgerRepository {
  _StubLedgerRepository({this.throwOnReverse});

  final Object? throwOnReverse;
  final List<ReverseOperationParams> reversals = [];

  @override
  Future<IdempotentOperationResult> reverseOperation(
    ReverseOperationParams params, {
    ChildWithdrawalAuditParams? auditParams,
  }) async {
    if (throwOnReverse case final Object error) throw error;
    reversals.add(params);
    return IdempotentOperationResult.created;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Widget _buildApp({
  required TransactionSummary summary,
  _StubLedgerRepository? ledger,
}) {
  final router = GoRouter(
    initialLocation: '/transactions/$_operationId/reverse',
    routes: [
      GoRoute(
        path: '/transactions',
        builder: (_, _) => const Scaffold(body: Text('Transactions')),
        routes: [
          GoRoute(
            path: ':operationId/reverse',
            builder: (_, state) => ReverseTransactionScreen(
              operationId: state.pathParameters['operationId']!,
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
      if (ledger != null) ledgerRepositoryProvider.overrideWithValue(ledger),
      transactionDetailProvider.overrideWith((ref, _) async => summary),
      accountsProvider.overrideWith(
        (ref, _) async => const AppOk<List<FinancialAccount>>([_fakeAccount]),
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

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(ReverseTransactionScreen)));

void main() {
  // A tall surface so the whole sheet is laid out at once. `ListView` builds
  // its children lazily even from a fixed list, and every assertion here is
  // about content that sits below a phone-height fold.
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

  testWidgets('the screen states what will be added, not "are you sure"', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(summary: _summary()));
    await tester.pump();

    final l10n = _l10n(tester);
    expect(find.text(l10n.reversalSheetIntro), findsOneWidget);
    expect(find.text(l10n.reversalOriginalStaysLabel), findsOneWidget);
    expect(find.text(l10n.reversalCounterEntryLabel), findsOneWidget);
    expect(find.text(l10n.reversalConfirmAction), findsOneWidget);
  });

  testWidgets('the net effect on the affected account is stated as zero', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(summary: _summary()));
    // Twice: the operation resolves on the first frame, the account name it
    // is labelled with on the second.
    await tester.pump();
    await tester.pump();

    final l10n = _l10n(tester);
    expect(
      find.text(l10n.reversalNetEffectOn(_fakeAccount.name)),
      findsOneWidget,
    );
    // The zero is on screen, not implied: it is the whole claim of an
    // append-only correction.
    final netRow = tester.widget<CurrencyAmountRow>(
      find.ancestor(
        of: find.text(l10n.reversalNetEffectOn(_fakeAccount.name)),
        matching: find.byType(CurrencyAmountRow),
      ),
    );
    expect(netRow.minorUnits, 0);
  });

  testWidgets('four suggested reasons are offered', (tester) async {
    await tester.pumpWidget(_buildApp(summary: _summary()));
    await tester.pump();

    final l10n = _l10n(tester);
    for (final preset in ReversalReasonPreset.values) {
      expect(
        find.text(reversalReasonPresetLabel(l10n, preset)),
        findsOneWidget,
      );
    }
  });

  testWidgets('tapping a suggestion fills the reason field', (tester) async {
    await tester.pumpWidget(_buildApp(summary: _summary()));
    await tester.pump();

    final l10n = _l10n(tester);
    final label = reversalReasonPresetLabel(
      l10n,
      ReversalReasonPreset.wrongAmount,
    );
    await tester.tap(find.text(label));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      label,
    );
  });

  testWidgets('confirming without a reason does not reach the ledger', (
    tester,
  ) async {
    final ledger = _StubLedgerRepository();
    await tester.pumpWidget(_buildApp(summary: _summary(), ledger: ledger));
    await tester.pump();

    final l10n = _l10n(tester);
    await tester.tap(find.text(l10n.reversalConfirmAction));
    await tester.pump();

    expect(ledger.reversals, isEmpty);
    expect(find.text(l10n.errorReversalReasonRequired), findsOneWidget);
  });

  testWidgets('a reason reaches the ledger with the reversal', (tester) async {
    final ledger = _StubLedgerRepository();
    await tester.pumpWidget(_buildApp(summary: _summary(), ledger: ledger));
    await tester.pump();

    final l10n = _l10n(tester);
    await tester.enterText(find.byType(TextField), 'أُدخلت مرتين');
    await tester.tap(find.text(l10n.reversalConfirmAction));
    await tester.pump();
    await tester.pump();

    expect(ledger.reversals.single.originalOperationId, _operationId);
    expect(ledger.reversals.single.reason, 'أُدخلت مرتين');
  });

  testWidgets('a failed write stays on screen as a notice, never a snackbar', (
    tester,
  ) async {
    final ledger = _StubLedgerRepository(
      throwOnReverse: DuplicateReversalError(_operationId),
    );
    await tester.pumpWidget(_buildApp(summary: _summary(), ledger: ledger));
    await tester.pump();

    final l10n = _l10n(tester);
    await tester.enterText(find.byType(TextField), 'Entered twice');
    await tester.tap(find.text(l10n.reversalConfirmAction));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text(l10n.errorOperationAlreadyReversed), findsOneWidget);
    // The user is still here and can act on it.
    expect(find.byType(ReverseTransactionScreen), findsOneWidget);
  });

  testWidgets(
    'an already-reversed transaction explains the missing action rather than '
    'hiding it',
    (tester) async {
      await tester.pumpWidget(_buildApp(summary: _summary(isReversed: true)));
      await tester.pump();

      final l10n = _l10n(tester);
      expect(find.text(l10n.detailAlreadyReversedNoAction), findsOneWidget);
      expect(find.text(l10n.reversalConfirmAction), findsNothing);
    },
  );
}
