/// The numpad-first expense form.
///
/// The behaviour under test is B1's claim: the sheet opens with the pad up,
/// every default it applied is printed rather than hidden, and the full field
/// set is a disclosure on the same sheet rather than a second screen.
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
import 'package:family_money_manager/features/transactions/presentation/expense_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _egpAccount = FinancialAccount(
  id: 'acc-egp',
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

const _jpyAccount = FinancialAccount(
  id: 'acc-jpy',
  householdId: 'household-v1',
  name: 'حساب ين',
  type: FinancialAccountType.bankAccount,
  ownerType: AccountOwnerType.user,
  fundPurpose: FundPurpose.available,
  currencyCode: 'JPY',
  isSpendable: true,
  isProtected: false,
  includeInNetWorth: true,
  includeInZakat: false,
  isArchived: false,
  displayOrder: 1,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
  createdBy: 'member-primary-v1',
);

final _primary = HouseholdMember(
  id: 'member-primary-v1',
  householdId: 'household-v1',
  displayName: 'أحمد',
  role: MemberRole.primaryUser,
  lifecycle: MemberLifecycle.active,
  isArchived: false,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
);

Widget _app({
  List<FinancialAccount> accounts = const [_egpAccount],
  String? preselected,
}) => ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWith((ref) {
      final db = AppDatabase.forTesting();
      ref.onDispose(db.close);
      return db;
    }),
    accountsProvider.overrideWith(
      (ref, _) async => AppOk<List<FinancialAccount>>(accounts),
    ),
    householdMembersProvider.overrideWith(
      (ref, _) async => AppOk<List<HouseholdMember>>([_primary]),
    ),
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
    home: ExpenseFormScreen(preselectedAccountId: preselected),
  ),
);

void main() {
  testWidgets('the sheet opens with the pad up', (tester) async {
    await tester.pumpWidget(_app(preselected: 'acc-egp'));
    await tester.pumpAndSettle();

    expect(find.byType(AmountKeypad), findsOneWidget);
    // The full field set is behind a disclosure, not on screen yet.
    expect(find.byType(AppFormSection), findsNothing);
  });

  testWidgets('typing on the pad fills the amount', (tester) async {
    await tester.pumpWidget(_app(preselected: 'acc-egp'));
    await tester.pumpAndSettle();

    for (final key in ['3', '8', '2', '.', '5', '0']) {
      await tester.tap(
        find.descendant(
          of: find.byType(AmountKeypad),
          matching: find.text(key),
        ),
      );
      await tester.pump();
    }

    expect(find.text('382.50'), findsOneWidget);
  });

  testWidgets('backspace removes the last character', (tester) async {
    await tester.pumpWidget(_app(preselected: 'acc-egp'));
    await tester.pumpAndSettle();

    for (final key in ['1', '2']) {
      await tester.tap(
        find.descendant(
          of: find.byType(AmountKeypad),
          matching: find.text(key),
        ),
      );
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(find.text('1'), findsWidgets);
    expect(find.text('12'), findsNothing);
  });

  testWidgets('the pad refuses digits past the currency scale', (tester) async {
    // Two decimal places for EGP: a third would be rounded away by the ledger,
    // so the pad declines it rather than accepting and discarding it.
    await tester.pumpWidget(_app(preselected: 'acc-egp'));
    await tester.pumpAndSettle();

    for (final key in ['1', '.', '2', '3', '4']) {
      await tester.tap(
        find.descendant(
          of: find.byType(AmountKeypad),
          matching: find.text(key),
        ),
      );
      await tester.pump();
    }

    expect(find.text('1.23'), findsOneWidget);
    expect(find.text('1.234'), findsNothing);
  });

  testWidgets('a zero-scale currency gets no separator key', (tester) async {
    await tester.pumpWidget(
      _app(accounts: const [_jpyAccount], preselected: 'acc-jpy'),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AmountKeypad), matching: find.text('.')),
      findsNothing,
    );
  });

  testWidgets('every applied default is printed under the amount', (
    tester,
  ) async {
    // Defaults are pre-answered, never hidden — the meta line is what makes
    // the three-tap path honest rather than merely fast.
    await tester.pumpWidget(_app(preselected: 'acc-egp'));
    await tester.pumpAndSettle();

    expect(find.textContaining('محفظة نقدية شخصية'), findsWidgets);
  });

  testWidgets('the category chip row scrolls edge to edge', (tester) async {
    await tester.pumpWidget(_app(preselected: 'acc-egp'));
    await tester.pumpAndSettle();

    final row = find.descendant(
      of: find.byType(ExpenseFormScreen),
      matching: find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      ),
    );
    expect(row, findsOneWidget);

    // The margin is on the scroll view itself. The check is that the viewport
    // is as wide as the list it sits in — an outer Padding would make it
    // narrower, so the chips would stop short instead of running to the edge
    // of the content measure.
    final scroller = tester.widget<SingleChildScrollView>(row);
    expect(scroller.padding, isNotNull);
    expect(
      tester.getSize(row).width,
      tester.getSize(find.byType(ListView)).width,
    );
  });

  testWidgets('more detail reveals the full field set on the same sheet', (
    tester,
  ) async {
    await tester.pumpWidget(_app(preselected: 'acc-egp'));
    await tester.pumpAndSettle();

    // Targeted by label: the action bar also holds a secondary button now.
    final moreDetail = find.textContaining('تفاصيل أكثر');
    await tester.scrollUntilVisible(
      moreDetail,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(moreDetail);
    await tester.pumpAndSettle();

    // Same sheet, same amount, same action bar — the pad simply retires.
    expect(find.byType(AppFormSection), findsWidgets);
    expect(find.byType(AmountKeypad), findsNothing);
    expect(find.byType(ExpenseFormScreen), findsOneWidget);
  });

  testWidgets('the append-only consequence is always shown', (tester) async {
    await tester.pumpWidget(_app(preselected: 'acc-egp'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'بعد الحفظ لا يمكن الحذف — التصحيح يكون بحركة عكسية تبقى في السجل.',
      ),
      findsOneWidget,
    );
  });
  testWidgets('save is reachable from the pad without visiting review', (
    tester,
  ) async {
    // The three-tap claim: amount, category, save. Review is an optional stop,
    // not a toll on every entry.
    await tester.pumpWidget(_app(preselected: 'acc-egp'));
    await tester.pumpAndSettle();

    for (final key in ['5', '0']) {
      await tester.tap(
        find.descendant(
          of: find.byType(AmountKeypad),
          matching: find.text(key),
        ),
      );
      await tester.pump();
    }
    await tester.tap(find.byType(FilterChip).first);
    await tester.pump();

    expect(find.byType(PrimaryActionButton), findsOneWidget);
    await tester.tap(find.byType(PrimaryActionButton));
    await tester.pumpAndSettle();

    // The write fails against an empty test database, and the point of this
    // test is where that failure lands: on the form, never in a snackbar.
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(ExpenseFormScreen), findsOneWidget);
  });
}
