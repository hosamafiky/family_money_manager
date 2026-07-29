/// The account-flow report tells you when its own figures do not add up.
///
/// `AccountFlowBreakdown.reconciles` has always been able to check the
/// accounting identity, and until now nothing above the domain layer asked
/// it. A period breakdown whose lines do not sum to its own closing balance
/// is the one thing a ledger must never present in silence.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/account_flow_report_screen.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// opening 50.00 + income 30.00 − expense 10.00 = closing 70.00.
const _balanced = AccountFlowBreakdown(
  accountId: 'acc-1',
  accountName: 'محفظة نقدية',
  currencyCode: 'EGP',
  openingBalanceMinorUnits: 5000,
  incomeMinorUnits: 3000,
  expenseMinorUnits: 1000,
  transfersInMinorUnits: 0,
  transfersOutMinorUnits: 0,
  adjustmentsMinorUnits: 0,
  reversalEffectMinorUnits: 0,
  closingBalanceMinorUnits: 7000,
);

/// The same account with a closing balance that the movements cannot produce
/// — what a broken query would look like from the screen's side.
const _unbalanced = AccountFlowBreakdown(
  accountId: 'acc-1',
  accountName: 'محفظة نقدية',
  currencyCode: 'EGP',
  openingBalanceMinorUnits: 5000,
  incomeMinorUnits: 3000,
  expenseMinorUnits: 1000,
  transfersInMinorUnits: 0,
  transfersOutMinorUnits: 0,
  adjustmentsMinorUnits: 0,
  reversalEffectMinorUnits: 0,
  closingBalanceMinorUnits: 9900,
);

Widget _buildApp(AccountFlowBreakdown account) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase.forTesting();
        ref.onDispose(db.close);
        return db;
      }),
      accountFlowReportProvider.overrideWith(
        (ref, _) async => AppOk([account]),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar'), Locale('en')],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AccountFlowReportScreen(),
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(AccountFlowReportScreen)));

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

  test('the identity is what it claims to be', () {
    expect(_balanced.reconciles, isTrue);
    expect(_unbalanced.reconciles, isFalse);
  });

  testWidgets('a table that adds up says nothing extra', (tester) async {
    await tester.pumpWidget(_buildApp(_balanced));
    await tester.pump();

    final l10n = _l10n(tester);
    expect(find.textContaining(l10n.reportDoesNotReconcile), findsNothing);
  });

  testWidgets('a table that does not add up says so, in the warning tone', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(_unbalanced));
    await tester.pump();

    final l10n = _l10n(tester);
    expect(find.textContaining(l10n.reportDoesNotReconcile), findsOneWidget);

    final notice = tester.widget<AppInlineNotice>(
      find.ancestor(
        of: find.textContaining(l10n.reportDoesNotReconcile),
        matching: find.byType(AppInlineNotice),
      ),
    );
    // A warning, not an error: nothing is broken in the ledger, and the
    // error role belongs to failures the user caused or can retry.
    expect(notice.tone, AppNoticeTone.warning);
  });

  testWidgets(
    'the warning separates what is suspect from what is still trustworthy',
    (tester) async {
      await tester.pumpWidget(_buildApp(_unbalanced));
      await tester.pump();

      final l10n = _l10n(tester);
      // The balances are derived from the ledger and remain correct; only the
      // period attribution is in doubt. Saying only "these do not add up"
      // would call the balances into question too.
      expect(
        find.textContaining(l10n.reportDoesNotReconcileBody),
        findsOneWidget,
      );
      // And the figures stay on screen — hiding them would leave the user
      // with a warning about something they cannot see.
      expect(find.byType(CurrencyAmountRow), findsWidgets);
    },
  );
}
