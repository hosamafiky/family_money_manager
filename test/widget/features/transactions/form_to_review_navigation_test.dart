/// Regression: staging a transaction context must survive the gap between the
/// form screen writing it and the review screen reading it.
///
/// When the staged-context providers were `autoDispose`, nothing listened to
/// them during the `set(ctx)` → `context.push(review)` gap, so they were
/// disposed and the review screen read `null`, popped immediately, and the
/// "Review & Confirm" button looked completely dead.
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:family_money_manager/features/transactions/presentation/income_form_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/income_review_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _fakeAccount = FinancialAccount(
  id: 'acc-1',
  householdId: 'household-v1',
  name: 'Wallet',
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

const _incomeCtx = IncomeContext(
  operationId: 'op-1',
  idempotencyKey: 'idem-1',
  householdId: 'household-v1',
  destinationAccountId: 'acc-1',
  amountMinorUnits: 10000,
  currencyCode: 'EGP',
  category: TransactionCategory.salary,
  effectiveDate: '2025-01-15',
  createdBy: 'member-primary-v1',
);

const _expenseCtx = ExpenseContext(
  operationId: 'op-2',
  idempotencyKey: 'idem-2',
  householdId: 'household-v1',
  paymentAccountId: 'acc-1',
  amountMinorUnits: 10000,
  currencyCode: 'EGP',
  category: TransactionCategory.groceries,
  spenderMemberId: 'member-primary-v1',
  beneficiaryMemberId: 'member-primary-v1',
  scope: ExpenseScope.personal,
  isRecurring: false,
  effectiveDate: '2025-01-15',
  createdBy: 'member-primary-v1',
);

const _transferCtx = TransferContext(
  operationId: 'op-3',
  idempotencyKey: 'idem-3',
  householdId: 'household-v1',
  sourceAccountId: 'acc-1',
  destinationAccountId: 'acc-2',
  amountMinorUnits: 10000,
  currencyCode: 'EGP',
  effectiveDate: '2025-01-15',
  createdBy: 'member-primary-v1',
);

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  group('staged context lifetime', () {
    test('income context survives an unlistened frame gap', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(stagedIncomeContextProvider.notifier).set(_incomeCtx);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(stagedIncomeContextProvider), _incomeCtx);
    });

    test('expense context survives an unlistened frame gap', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(stagedExpenseContextProvider.notifier).set(_expenseCtx);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(stagedExpenseContextProvider), _expenseCtx);
    });

    test('transfer context survives an unlistened frame gap', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(stagedTransferContextProvider.notifier).set(_transferCtx);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(stagedTransferContextProvider), _transferCtx);
    });
  });

  testWidgets('income form "Review & Confirm" navigates to the review screen', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/transactions/new/income',
      routes: [
        GoRoute(
          path: '/transactions',
          builder: (_, _) => const Scaffold(body: Text('TX-LIST')),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, _) => const Scaffold(body: Text('PICKER')),
              routes: [
                GoRoute(
                  path: 'income',
                  builder: (_, _) => const IncomeFormScreen(),
                  routes: [
                    GoRoute(
                      path: 'review',
                      builder: (_, _) => const IncomeReviewScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase.forTesting();
            ref.onDispose(db.close);
            return db;
          }),
          accountsProvider.overrideWith(
            (ref, _) async =>
                const AppOk<List<FinancialAccount>>([_fakeAccount]),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<FinancialAccount>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wallet').last);
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(IncomeFormScreen)),
    );
    await tester.tap(find.byType(DropdownButtonFormField<TransactionCategory>));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(categoryLabel(l10n, TransactionCategory.salary)).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Review & Confirm'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/transactions/new/income/review');
    expect(find.byType(IncomeReviewScreen), findsOneWidget);
    expect(find.text('100.00 EGP'), findsOneWidget);
  });
}
