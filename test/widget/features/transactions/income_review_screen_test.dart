import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
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

const _fakeCtx = IncomeContext(
  operationId: 'op-1',
  idempotencyKey: 'idem-1',
  householdId: 'household-v1',
  destinationAccountId: 'acc-1',
  amountMinorUnits: 10000,
  currencyCode: 'EGP',
  category: TransactionCategory.salary,
  effectiveDate: '2025-01-15',
  createdBy: 'member-primary-v1',
  note: 'Test note',
);

const _fakeCtxNoNote = IncomeContext(
  operationId: 'op-2',
  idempotencyKey: 'idem-2',
  householdId: 'household-v1',
  destinationAccountId: 'acc-1',
  amountMinorUnits: 5000,
  currencyCode: 'EGP',
  category: TransactionCategory.salary,
  effectiveDate: '2025-02-01',
  createdBy: 'member-primary-v1',
);

Widget _buildApp(IncomeContext? ctx) {
  final router = GoRouter(
    initialLocation: '/review',
    routes: [
      GoRoute(path: '/review', builder: (_, _) => const IncomeReviewScreen()),
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
      stagedIncomeContextProvider.overrideWith(() {
        final n = StagedIncomeContextNotifier();
        return n;
      }),
      accountsProvider.overrideWith(
        (ref, _) async => const AppOk<List<FinancialAccount>>([_fakeAccount]),
      ),
    ],
    child: _SeedAndRoute(ctx: ctx, router: router),
  );
}

class _SeedAndRoute extends ConsumerStatefulWidget {
  const _SeedAndRoute({required this.ctx, required this.router});
  final IncomeContext? ctx;
  final GoRouter router;

  @override
  ConsumerState<_SeedAndRoute> createState() => _SeedAndRouteState();
}

class _SeedAndRouteState extends ConsumerState<_SeedAndRoute> {
  @override
  void initState() {
    super.initState();
    if (widget.ctx != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(stagedIncomeContextProvider.notifier).set(widget.ctx);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
}

void main() {
  group('IncomeReviewScreen', () {
    testWidgets('1. shows nothing when staged context is null', (tester) async {
      await tester.pumpWidget(_buildApp(null));
      await tester.pumpAndSettle();
      // SizedBox.shrink() — no form content.
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('2. confirm button shown with valid context', (tester) async {
      await tester.pumpWidget(_buildApp(_fakeCtx));
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('3. account name resolved — not raw UUID', (tester) async {
      await tester.pumpWidget(_buildApp(_fakeCtx));
      await tester.pumpAndSettle();
      expect(find.text('محفظتي'), findsOneWidget);
      expect(find.text('acc-1'), findsNothing);
    });

    testWidgets('4. amount formatted as decimal + currency code', (tester) async {
      await tester.pumpWidget(_buildApp(_fakeCtx));
      await tester.pumpAndSettle();
      // 10000 minor units EGP → '100.00 EGP'
      expect(find.text('100.00 EGP'), findsOneWidget);
      expect(find.text('10000'), findsNothing);
    });

    testWidgets('5. optional note shown when present', (tester) async {
      await tester.pumpWidget(_buildApp(_fakeCtx));
      await tester.pumpAndSettle();
      expect(find.text('Test note'), findsOneWidget);
    });

    testWidgets('6. effective date shown', (tester) async {
      await tester.pumpWidget(_buildApp(_fakeCtx));
      await tester.pumpAndSettle();
      expect(find.text('2025-01-15'), findsOneWidget);
    });

    testWidgets('7. note row absent when context has no note', (tester) async {
      await tester.pumpWidget(_buildApp(_fakeCtxNoNote));
      await tester.pumpAndSettle();
      // '50.00 EGP' shown; note not visible.
      expect(find.text('50.00 EGP'), findsOneWidget);
      expect(find.text('Test note'), findsNothing);
    });
  });
}
