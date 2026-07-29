/// The filter sheet's pickers.
///
/// The filter and the query supported every one of these dimensions from the
/// start; only the sheet did not offer them. What is worth testing is the
/// part that can go wrong: that each control writes the dimension it claims
/// to, that clearing means cleared rather than "first option", and that the
/// amount band cannot exist without a currency.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:family_money_manager/features/household/presentation/providers/household_providers.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:family_money_manager/features/transactions/presentation/transaction_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _householdId = 'household-v1';

const _wallet = FinancialAccount(
  id: 'acc-wallet',
  householdId: _householdId,
  name: 'محفظة نقدية',
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
  createdBy: 'member-hana',
);

final _hana = HouseholdMember(
  id: 'member-hana',
  householdId: _householdId,
  displayName: 'هناء',
  role: MemberRole.spouse,
  lifecycle: MemberLifecycle.active,
  isArchived: false,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
);

/// The filter the sheet returned, or null if it was cancelled.
TransactionFilter? result;

Widget _buildApp({TransactionFilter initial = const TransactionFilter()}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase.forTesting();
        ref.onDispose(db.close);
        return db;
      }),
      accountsProvider.overrideWith(
        (ref, _) async => const AppOk<List<FinancialAccount>>([_wallet]),
      ),
      householdMembersProvider.overrideWith(
        (ref, _) async => AppOk<List<HouseholdMember>>([_hana]),
      ),
      transactionCountProvider.overrideWith((ref, _) async => 87),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showTransactionFilterSheet(
                  context: context,
                  initial: initial,
                  householdId: _householdId,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<AppLocalizations> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(AppBottomActionBar)));
}

Future<void> _apply(WidgetTester tester) async {
  await tester.tap(find.byType(PrimaryActionButton));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    result = null;
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 3600);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  testWidgets('every dimension the query supports is offered', (tester) async {
    await tester.pumpWidget(_buildApp());
    final l10n = await _openSheet(tester);

    for (final title in [
      l10n.transactionsFilterType,
      l10n.transactionsFilterCategory,
      l10n.transactionsFilterScope,
      l10n.transactionsFilterAccount,
      l10n.transactionsFilterSpender,
      l10n.transactionsFilterAmountRange,
    ]) {
      expect(find.text(title), findsWidgets, reason: '$title section missing');
    }
  });

  testWidgets('a category chip writes the category code, not its label', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    final l10n = await _openSheet(tester);

    await tester.tap(find.widgetWithText(FilterChip, l10n.catGroceries));
    await tester.pumpAndSettle();
    await _apply(tester);

    // The query matches on the stable code; a localised label would match
    // nothing, and would match differently per locale.
    expect(result!.categoryCode, 'groceries');
  });

  testWidgets('tapping the selected chip again clears that dimension', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    final l10n = await _openSheet(tester);

    final chip = find.widgetWithText(FilterChip, l10n.catGroceries);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await _apply(tester);

    expect(result!.categoryCode, isNull);
  });

  testWidgets('the account menu writes the account id', (tester) async {
    await tester.pumpWidget(_buildApp());
    await _openSheet(tester);

    // Open the menu by its hint, then pick the account from it.
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AppBottomActionBar)),
    );
    await tester.tap(find.text(l10n.transactionsFilterAllAccounts).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_wallet.name).last);
    await tester.pumpAndSettle();
    await _apply(tester);

    expect(result!.accountId, _wallet.id);
  });

  testWidgets('the spender menu writes the member id', (tester) async {
    await tester.pumpWidget(_buildApp());
    await _openSheet(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(AppBottomActionBar)),
    );
    await tester.tap(find.text(l10n.transactionsFilterAnyMember).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_hana.displayName).last);
    await tester.pumpAndSettle();
    await _apply(tester);

    expect(result!.spenderMemberId, _hana.id);
  });

  group('the amount band', () {
    testWidgets('always carries a currency', (tester) async {
      await tester.pumpWidget(_buildApp());
      final l10n = await _openSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextField, l10n.transactionsFilterMin),
        '300',
      );
      await tester.pumpAndSettle();
      await _apply(tester);

      // Never a bare min/max: a threshold without a currency compares across
      // them, which is the same error as a mixed total.
      expect(result!.amountRange!.currencyCode, isNotEmpty);
      expect(result!.amountRange!.minMinorUnits, 30000);
    });

    testWidgets('switching currency re-reads the typed bounds at its scale', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      final l10n = await _openSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextField, l10n.transactionsFilterMin),
        '300',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'USD'));
      await tester.pumpAndSettle();
      await _apply(tester);

      // The typed figure is re-parsed, not reinterpreted: 300 stays 300 in
      // the new currency rather than 30000 minor units changing meaning.
      expect(result!.amountRange!.currencyCode, 'USD');
      expect(result!.amountRange!.minMinorUnits, 30000);
    });

    testWidgets('clearing both bounds removes the band entirely', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      final l10n = await _openSheet(tester);

      final minField = find.widgetWithText(
        TextField,
        l10n.transactionsFilterMin,
      );
      await tester.enterText(minField, '300');
      await tester.pumpAndSettle();
      await tester.enterText(minField, '');
      await tester.pumpAndSettle();
      await _apply(tester);

      // Not a band with two nulls — no band. An empty range would still pin
      // the filter to one currency.
      expect(result!.amountRange, isNull);
    });
  });

  testWidgets('clear all drops every criterion at once', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        initial: const TransactionFilter(
          categoryCode: 'groceries',
          accountId: 'acc-wallet',
          includeReversed: false,
        ),
      ),
    );
    final l10n = await _openSheet(tester);

    expect(find.text(l10n.transactionsClearFiltersCount('3')), findsOneWidget);

    await tester.tap(find.text(l10n.transactionsClearFiltersCount('3')));
    await tester.pumpAndSettle();
    await _apply(tester);

    expect(result!.hasActiveCriteria, isFalse);
    // And reversed history comes back on, because that is the default the
    // ledger insists on rather than merely the last state.
    expect(result!.includeReversed, isTrue);
  });

  testWidgets('cancelling returns nothing, changing nothing', (tester) async {
    await tester.pumpWidget(_buildApp());
    final l10n = await _openSheet(tester);

    await tester.tap(find.widgetWithText(FilterChip, l10n.catGroceries));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.transactionsCancel));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
