import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/transactions/presentation/income_form_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _fakeAccount = FinancialAccount(
  id: 'acc-1',
  householdId: 'household-v1',
  name: 'محفظتي',
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

const _archivedAccount = FinancialAccount(
  id: 'acc-archived',
  householdId: 'household-v1',
  name: 'حساب مؤرشف',
  type: FinancialAccountType.personalCashWallet,
  ownerType: AccountOwnerType.user,
  fundPurpose: FundPurpose.available,
  currencyCode: 'EGP',
  isSpendable: true,
  isProtected: false,
  includeInNetWorth: true,
  includeInZakat: false,
  isArchived: true,
  displayOrder: 0,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
  createdBy: 'member-primary-v1',
);

const _localizations = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

AppDatabase _db(Ref ref) {
  final db = AppDatabase.forTesting();
  ref.onDispose(db.close);
  return db;
}

void main() {
  group('IncomeFormScreen', () {
    testWidgets('1. shows empty-state when no accounts exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async => const AppOk<List<FinancialAccount>>([]),
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
      // Empty state: a FilledButton to create an account, no form fields.
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets('2. shows form when accounts exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async =>
                  const AppOk<List<FinancialAccount>>([_fakeAccount]),
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
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('3. account name visible when dropdown opened', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async =>
                  const AppOk<List<FinancialAccount>>([_fakeAccount]),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: [Locale('ar'), Locale('en')],
            localizationsDelegates: _localizations,
            home: Scaffold(body: IncomeFormScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Open the dropdown.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('محفظتي'), findsWidgets);
    });

    testWidgets('4. stays on form when review tapped with no amount', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async =>
                  const AppOk<List<FinancialAccount>>([_fakeAccount]),
            ),
            incomeFormProvider.overrideWith(IncomeFormNotifier.new),
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
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      // Still on the same screen — no navigation occurred.
      expect(find.byType(IncomeFormScreen), findsOneWidget);
    });

    testWidgets('5. AppBar present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async => const AppOk<List<FinancialAccount>>([]),
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
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('6. error state when accounts provider fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) => Future<AppResult<List<FinancialAccount>>>.error(
                Exception('DB error'),
              ),
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
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets('7. archived accounts excluded — empty state shown', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async =>
                  const AppOk<List<FinancialAccount>>([_archivedAccount]),
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
      // Archived account → no active accounts → empty state.
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('حساب مؤرشف'), findsNothing);
    });

    testWidgets('8. amount text field visible when accounts exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith(_db),
            accountsProvider.overrideWith(
              (ref, _) async =>
                  const AppOk<List<FinancialAccount>>([_fakeAccount]),
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
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
