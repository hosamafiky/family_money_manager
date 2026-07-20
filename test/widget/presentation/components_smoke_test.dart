import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/more/presentation/more_hub_screen.dart';
import 'package:family_money_manager/features/planning/presentation/planning_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({
  required Widget child,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
  Size size = const Size(390, 844),
}) {
  return MaterialApp(
    locale: locale,
    theme: AppTheme.light(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) {
      return MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      );
    },
    home: child,
  );
}

void main() {
  testWidgets('components smoke builds in English', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: Scaffold(
          body: ListView(
            children: [
              const FinancialSummary(
                title: 'Spendable',
                formattedAmount: '1,250.00 EGP',
              ),
              const FinancialTypeBadge(
                label: 'Income',
                kind: FinancialTypeKind.income,
              ),
              const AppInlineNotice(message: 'Notice'),
              PrimaryActionButton(label: 'Save', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Spendable'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Notice'), findsOneWidget);
  });

  testWidgets('components smoke builds in Arabic RTL', (tester) async {
    await tester.pumpWidget(
      _wrap(
        locale: const Locale('ar'),
        child: const Scaffold(
          body: FinancialAmountText(
            formattedAmount: '100.00',
            tone: FinancialAmountTone.expense,
          ),
        ),
      ),
    );
    expect(find.text('100.00'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('100.00'))),
      TextDirection.rtl,
    );
  });

  testWidgets('planning hub lists budgets goals certificates', (tester) async {
    await tester.pumpWidget(_wrap(child: const PlanningHubScreen()));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.budgetsTitle), findsWidgets);
    expect(find.text(l10n.goalsTitle), findsWidgets);
    expect(find.text(l10n.certificatesTitle), findsWidgets);
  });

  testWidgets('more hub lists accounts members settings', (tester) async {
    await tester.pumpWidget(_wrap(child: const MoreHubScreen()));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.navAccounts), findsWidgets);
    expect(find.text(l10n.navMembers), findsWidgets);
    expect(find.text(l10n.navSettings), findsWidgets);
  });

  testWidgets('large text does not overflow amount entry', (tester) async {
    final controller = TextEditingController(text: '100.00');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _wrap(
        textScale: 1.6,
        child: Scaffold(
          body: AmountEntryField(
            controller: controller,
            label: 'Amount',
            currencyCode: 'EGP',
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Amount'), findsOneWidget);
  });

  testWidgets('wide layout still builds planning hub', (tester) async {
    await tester.pumpWidget(
      _wrap(size: const Size(1200, 800), child: const PlanningHubScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlanningHubScreen), findsOneWidget);
  });
}
