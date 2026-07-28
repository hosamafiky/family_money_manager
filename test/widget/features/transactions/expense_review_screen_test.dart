/// The expense review screen.
///
/// Two things are being asserted that the previous screen did not do: the
/// sentence read-back replaces the table of labelled rows, and a failed write
/// stays on screen at its cause instead of auto-dismissing in a snackbar.
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
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/presentation/expense_review_screen.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _account = FinancialAccount(
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

final _spender = HouseholdMember(
  id: 'member-spouse',
  householdId: 'household-v1',
  displayName: 'هناء',
  role: MemberRole.spouse,
  lifecycle: MemberLifecycle.active,
  isArchived: false,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
);

const _ctx = ExpenseContext(
  operationId: 'op-1',
  idempotencyKey: 'idem-1',
  householdId: 'household-v1',
  paymentAccountId: 'acc-1',
  amountMinorUnits: 38250,
  currencyCode: 'EGP',
  category: TransactionCategory.groceries,
  spenderMemberId: 'member-spouse',
  beneficiaryMemberId: 'member-spouse',
  scope: ExpenseScope.household,
  isRecurring: false,
  effectiveDate: '2026-07-25',
  createdBy: 'member-primary-v1',
);

Widget _buildApp() {
  final router = GoRouter(
    initialLocation: '/review',
    routes: [
      GoRoute(path: '/review', builder: (_, _) => const ExpenseReviewScreen()),
      GoRoute(
        path: '/transactions',
        builder: (_, _) => const Scaffold(body: Text('Transactions')),
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
      accountsProvider.overrideWith(
        (ref, _) async => const AppOk<List<FinancialAccount>>([_account]),
      ),
      householdMembersProvider.overrideWith(
        (ref, _) async => AppOk<List<HouseholdMember>>([_spender]),
      ),
    ],
    child: _Seed(router: router),
  );
}

class _Seed extends ConsumerStatefulWidget {
  const _Seed({required this.router});

  final GoRouter router;

  @override
  ConsumerState<_Seed> createState() => _SeedState();
}

class _SeedState extends ConsumerState<_Seed> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(stagedExpenseContextProvider.notifier).set(_ctx);
      }
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: widget.router,
  );
}

void main() {
  testWidgets('the read-back is one sentence, not a table of labels', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // Every fact the user needs to catch a mistake, in the order they would
    // say it — assembled by ARB as a whole sentence, never concatenated.
    final sentence = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((t) => t.contains('صرفت'), orElse: () => '');

    expect(sentence, isNotEmpty, reason: 'the read-back sentence is missing');
    expect(sentence, contains('382.50'));
    expect(sentence, contains('محفظة نقدية شخصية'));
    expect(sentence, contains('هناء'));
  });

  testWidgets('the double entry is stated as debit and credit', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('أثر هذه الحركة على السجل'), findsOneWidget);
    // Both sides, each named — not implied by a sign alone.
    expect(find.textContaining('مدين —'), findsOneWidget);
    expect(find.textContaining('دائن —'), findsOneWidget);
  });

  testWidgets('the append-only consequence is always shown', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // Permanent, not conditional: the user learns append-only here rather
    // than by hunting for a delete button.
    expect(
      find.text(
        'بعد الحفظ لا يمكن الحذف — التصحيح يكون بحركة عكسية تبقى في السجل.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a write failure persists on screen, not in a snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // The staged context references accounts that do not exist in the test
    // database, so the write fails.
    await tester.tap(find.byType(PrimaryActionButton));
    await tester.pumpAndSettle();

    // A snackbar would take the message away before it could be read.
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(AppInlineNotice), findsWidgets);
    // And the user is still on the review screen, able to act on it.
    expect(find.byType(ExpenseReviewScreen), findsOneWidget);
  });
}
