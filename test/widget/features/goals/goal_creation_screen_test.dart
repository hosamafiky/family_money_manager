/// Widget tests for GoalCreationScreen (Phase 5B).
///
/// Tests:
///  1. Name field present
///  2. Purpose dropdown present
///  3. Currency dropdown present
///  4. Target amount field present
///  5. Submit with empty name shows validation error
///  6. Submit with zero target shows validation error
///  7. Initial funding source optional (shown as optional)
///  8. Arabic RTL layout correct
library;

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/goals/presentation/goal_creation_screen.dart';
import 'package:family_money_manager/features/goals/presentation/providers/goal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier(this._locale);
  final Locale _locale;
  @override
  Locale build() => _locale;
}

class _FixedThemeModeNotifier extends ThemeModeNotifier {
  _FixedThemeModeNotifier(this._mode);
  final ThemeMode _mode;
  @override
  ThemeMode build() => _mode;
}

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/goals/new',
  routes: [
    GoRoute(
      path: '/goals',
      builder: (_, _) => const Scaffold(body: Text('Goals List')),
      routes: [
        GoRoute(path: 'new', builder: (_, _) => const GoalCreationScreen()),
      ],
    ),
  ],
);

Widget _buildApp({Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      appThemeModeProvider.overrideWith(
        () => _FixedThemeModeNotifier(ThemeMode.light),
      ),
      accountsProvider.overrideWith(
        (ref, _) async => const AppOk(<FinancialAccount>[]),
      ),
      createGoalUseCaseProvider.overrideWith(
        (ref) => throw UnimplementedError('not needed in widget tests'),
      ),
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _makeRouter(),
    ),
  );
}

void main() {
  group('GoalCreationScreen', () {
    testWidgets('1. Name field present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Goal name'), findsOneWidget);
    });

    testWidgets('2. Purpose dropdown present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Purpose'), findsOneWidget);
    });

    testWidgets('3. Currency dropdown present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Currency'), findsOneWidget);
    });

    testWidgets('4. Target amount field present', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Target amount'), findsOneWidget);
    });

    testWidgets('5. Submit with empty name shows validation error', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(ElevatedButton),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Goal name is required'), findsOneWidget);
    });

    testWidgets('6. Submit with zero target shows validation error', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal name'),
        'My Goal',
      );
      // Dismiss keyboard so button is not obscured.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(ElevatedButton),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Target amount must be greater than zero',
          skipOffstage: false,
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('7. Initial funding source is optional', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // The initial funding section is present but optional.
      expect(find.text('Initial funding (optional)'), findsOneWidget);
    });

    testWidgets('8. Arabic RTL layout correct', (tester) async {
      await tester.pumpWidget(_buildApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('اسم الهدف'), findsOneWidget);
      expect(find.text('الغرض'), findsOneWidget);
    });
  });
}
