import 'dart:async';

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/accounts/application/account_use_cases.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/accounts_screen.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_account_repository.dart';
import '../../../helpers/fake_balance_repository.dart';

const _householdId = 'household-v1';

FinancialAccount _makeAccount({
  String id = 'a1',
  String name = 'Test Account',
  bool isSpendable = true,
  bool isProtected = false,
}) => FinancialAccount(
  id: id,
  householdId: _householdId,
  name: name,
  type: FinancialAccountType.personalCashWallet,
  ownerType: AccountOwnerType.user,
  fundPurpose: FundPurpose.available,
  currencyCode: 'EGP',
  isSpendable: isSpendable,
  isProtected: isProtected,
  includeInNetWorth: true,
  includeInZakat: true,
  isArchived: false,
  displayOrder: 0,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
  createdBy: 'user1',
);

/// Builds a widget test environment with overridden Riverpod providers.
Widget _buildScreen({
  required List<FinancialAccount> accounts,
  bool simulateError = false,
}) {
  final fakeAccountRepo = FakeAccountRepository();
  final fakeBalanceRepo = FakeBalanceRepository();

  for (final account in accounts) {
    fakeBalanceRepo.setBalance(account.id, 0);
  }

  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith(
        () => _FixedLocaleNotifier(const Locale('ar')),
      ),
      appThemeModeProvider.overrideWith(
        () => _FixedThemeModeNotifier(ThemeMode.light),
      ),
      // Override repositories with typed interface providers.
      accountRepositoryProvider.overrideWithValue(fakeAccountRepo),
      balanceRepositoryProvider.overrideWithValue(fakeBalanceRepo),
      listAccountsUseCaseProvider.overrideWithValue(
        ListAccountsUseCase(fakeAccountRepo),
      ),
      accountsProvider(_householdId).overrideWith(
        (_) async => simulateError
            ? const AppPersistenceFailure<List<FinancialAccount>>()
            : AppOk<List<FinancialAccount>>(accounts),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: AccountsScreen(),
    ),
  );
}

void main() {
  group('AccountsScreen widget tests', () {
    testWidgets('loading state shows loading indicator text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.development),
            appLocaleProvider.overrideWith(
              () => _FixedLocaleNotifier(const Locale('ar')),
            ),
            appThemeModeProvider.overrideWith(
              () => _FixedThemeModeNotifier(ThemeMode.light),
            ),
            accountRepositoryProvider.overrideWithValue(
              FakeAccountRepository(),
            ),
            balanceRepositoryProvider.overrideWithValue(
              FakeBalanceRepository(),
            ),
            listAccountsUseCaseProvider.overrideWithValue(
              ListAccountsUseCase(FakeAccountRepository()),
            ),
            accountsProvider(_householdId).overrideWith(
              (_) => Completer<AppResult<List<FinancialAccount>>>().future,
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: AccountsScreen(),
          ),
        ),
      );

      await tester.pump();
      // Loading indicator text (Arabic: 'جارٍ التحميل...')
      expect(find.textContaining('جارٍ'), findsOneWidget);
    });

    testWidgets('empty state shows empty message', (tester) async {
      await tester.pumpWidget(_buildScreen(accounts: []));
      await tester.pumpAndSettle();

      expect(find.textContaining('لا توجد حسابات'), findsOneWidget);
    });

    testWidgets('error state shows error message', (tester) async {
      await tester.pumpWidget(_buildScreen(accounts: [], simulateError: true));
      await tester.pumpAndSettle();

      expect(find.textContaining('حدث خطأ'), findsOneWidget);
    });

    testWidgets('populated state shows account names', (tester) async {
      final accounts = [
        _makeAccount(id: 'a1', name: 'محفظتي'),
        _makeAccount(id: 'a2', name: 'توفير المنزل', isSpendable: false),
      ];
      await tester.pumpWidget(_buildScreen(accounts: accounts));
      await tester.pumpAndSettle();

      expect(find.text('محفظتي'), findsOneWidget);
      expect(find.text('توفير المنزل'), findsOneWidget);
    });

    testWidgets('FAB is present on accounts screen', (tester) async {
      await tester.pumpWidget(_buildScreen(accounts: []));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('app bar shows accounts title in Arabic', (tester) async {
      await tester.pumpWidget(_buildScreen(accounts: []));
      await tester.pumpAndSettle();

      expect(find.text('الحسابات'), findsWidgets);
    });
  });
}

class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier(this._locale);
  final Locale _locale;

  @override
  Locale build() => _locale;
}

class _FixedThemeModeNotifier extends ThemeModeNotifier {
  _FixedThemeModeNotifier(this._themeMode);
  final ThemeMode _themeMode;

  @override
  ThemeMode build() => _themeMode;
}
