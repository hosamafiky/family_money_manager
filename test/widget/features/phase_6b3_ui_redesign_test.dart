/// Phase 6B.3 widget coverage — form hierarchy, notices, and shared states.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/budgets/presentation/budget_creation_screen.dart';
import 'package:family_money_manager/features/goals/presentation/goal_creation_screen.dart';
import 'package:family_money_manager/features/reports/presentation/reports_landing_screen.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/presentation/income_form_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/income_review_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:family_money_manager/features/transactions/presentation/transfer_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _localizations = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const _account = FinancialAccount(
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

AppDatabase _db(Ref ref) {
  final db = AppDatabase.forTesting();
  ref.onDispose(db.close);
  return db;
}

final class _SeededIncomeNotifier extends StagedIncomeContextNotifier {
  _SeededIncomeNotifier(this._value);
  final IncomeContext _value;

  @override
  IncomeContext? build() => _value;
}

void main() {
  group('Phase 6B.3 transaction forms', () {
    testWidgets('TF-1. Income form is amount-first with review in bottom bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async => const AppOk<List<FinancialAccount>>([_account]),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: [Locale('ar'), Locale('en')],
            localizationsDelegates: _localizations,
            home: IncomeFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AmountEntryField), findsOneWidget);
      expect(find.byType(AppBottomActionBar), findsOneWidget);
      expect(find.byType(AppExpandableDetails), findsOneWidget);
      expect(find.text('Amount'), findsWidgets);
    });

    testWidgets('TF-2. Transfer form shows internal-transfer explanation', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async => const AppOk<List<FinancialAccount>>([_account]),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: [Locale('ar'), Locale('en')],
            localizationsDelegates: _localizations,
            home: TransferFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppInlineNotice), findsWidgets);
      expect(find.byType(AmountEntryField), findsOneWidget);
    });

    testWidgets('TF-3. Income review uses shared review section', (
      tester,
    ) async {
      const ctx = IncomeContext(
        operationId: 'op-1',
        idempotencyKey: 'ik-1',
        householdId: 'household-v1',
        destinationAccountId: 'acc-1',
        amountMinorUnits: 10000,
        currencyCode: 'EGP',
        category: TransactionCategory.salary,
        effectiveDate: '2024-01-01',
        createdBy: 'member-primary-v1',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async => const AppOk<List<FinancialAccount>>([_account]),
            ),
            stagedIncomeContextProvider.overrideWith(
              () => _SeededIncomeNotifier(ctx),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: [Locale('ar'), Locale('en')],
            localizationsDelegates: _localizations,
            home: IncomeReviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppReviewSection), findsOneWidget);
      expect(find.byType(PrimaryActionButton), findsOneWidget);
      expect(find.textContaining('Income'), findsWidgets);
    });

    testWidgets('TF-4. Arabic income form loads without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async => const AppOk<List<FinancialAccount>>([_account]),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: [Locale('ar'), Locale('en')],
            localizationsDelegates: _localizations,
            home: IncomeFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(IncomeFormScreen), findsOneWidget);
    });
  });

  group('Phase 6B.3 planning and reports notices', () {
    testWidgets('PN-1. Budget creation shows non-holding-money notices', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith(_db)],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: [Locale('ar'), Locale('en')],
            localizationsDelegates: _localizations,
            home: BudgetCreationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppInlineNotice), findsWidgets);
      expect(find.textContaining('do not hold money'), findsOneWidget);
    });

    testWidgets('PN-2. Goal creation shows reserve and currency notices', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async => const AppOk<List<FinancialAccount>>([_account]),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: [Locale('ar'), Locale('en')],
            localizationsDelegates: _localizations,
            home: GoalCreationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppInlineNotice), findsWidgets);
      expect(find.textContaining('dedicated reserve'), findsOneWidget);
    });

    testWidgets('PN-3. Reports landing uses AppScreenScaffold', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          supportedLocales: [Locale('ar'), Locale('en')],
          localizationsDelegates: _localizations,
          home: ReportsLandingScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppScreenScaffold), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
    });
  });
}
