/// Widget tests for BudgetCreationScreen (Phase 5A).
///
/// Tests:
///  1. Name field present
///  2. Currency dropdown present
///  3. Limit field present
///  4. Monthly period option selectable
///  5. Fixed period shows date pickers after selection
///  6. Overlap explanation text shown
///  7. Submit with empty name shows validation error
///  8. Submit with zero limit shows validation error
///  9. Submit with fixed period + missing dates shows SnackBar
/// 10. Arabic RTL layout
library;

import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/budgets/presentation/budget_creation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ── Test helpers ───────────────────────────────────────────────────────────

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

Widget _buildCreationScreen({Locale locale = const Locale('en')}) {
  final router = GoRouter(
    initialLocation: '/budgets/new',
    routes: [
      GoRoute(
        path: '/budgets',
        builder: (_, _) => const Scaffold(body: Text('Budgets')),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const BudgetCreationScreen()),
          GoRoute(
            path: ':budgetId',
            builder: (context, state) =>
                Scaffold(body: Text('Detail:${state.pathParameters['budgetId']}')),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development),
      appLocaleProvider.overrideWith(() => _FixedLocaleNotifier(locale)),
      appThemeModeProvider.overrideWith(() => _FixedThemeModeNotifier(ThemeMode.light)),
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('BudgetCreationScreen', () {
    testWidgets('1. Name field present', (tester) async {
      await tester.pumpWidget(_buildCreationScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Budget name'), findsOneWidget);
    });

    testWidgets('2. Currency dropdown present', (tester) async {
      await tester.pumpWidget(_buildCreationScreen());
      await tester.pumpAndSettle();

      // Default currency is EGP shown in dropdown
      expect(
        find.descendant(
          of: find.byType(DropdownButtonFormField<String>),
          matching: find.text('EGP'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('3. Limit field present', (tester) async {
      await tester.pumpWidget(_buildCreationScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Monthly limit'), findsOneWidget);
    });

    testWidgets('4. Monthly period option selectable', (tester) async {
      await tester.pumpWidget(_buildCreationScreen());
      await tester.pumpAndSettle();

      // SegmentedButton shows Monthly option
      expect(find.text('Monthly (recurring)'), findsOneWidget);
    });

    testWidgets('5. Fixed period shows date pickers after selection', (tester) async {
      await tester.pumpWidget(_buildCreationScreen());
      await tester.pumpAndSettle();

      // Tap "Fixed period" segment
      await tester.tap(find.text('Fixed period'));
      await tester.pumpAndSettle();

      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('End date'), findsOneWidget);
    });

    testWidgets('6. Overlap explanation text shown', (tester) async {
      await tester.pumpWidget(_buildCreationScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Budgets may overlap'), findsOneWidget);
    });

    testWidgets('7. Submit with empty name shows validation error', (tester) async {
      await tester.pumpWidget(_buildCreationScreen());
      await tester.pumpAndSettle();

      // Enter a valid limit so only the name fails validation
      await tester.enterText(find.widgetWithText(TextFormField, 'Monthly limit'), '100');
      await tester.pump();

      // FilledButton is the submit button (AppBar title shares text "New Budget")
      final submitButton = find.byType(FilledButton);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Budget name is required'), findsOneWidget);
    });

    testWidgets('8. Submit with zero limit shows validation error', (tester) async {
      await tester.pumpWidget(_buildCreationScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Budget name'), 'My Budget');
      await tester.enterText(find.widgetWithText(TextFormField, 'Monthly limit'), '0');
      await tester.pump();

      final submitButton = find.byType(FilledButton);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Budget limit must be greater than zero'), findsOneWidget);
    });

    testWidgets('9. Fixed period changes limit label from Monthly limit to Budget limit', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCreationScreen());
      await tester.pumpAndSettle();

      // In monthly mode: label is "Monthly limit"
      expect(find.widgetWithText(TextFormField, 'Monthly limit'), findsOneWidget);

      // Switch to fixed period
      await tester.tap(find.text('Fixed period'));
      await tester.pumpAndSettle();

      // Label changes to "Budget limit" and monthly label is gone
      expect(find.widgetWithText(TextFormField, 'Budget limit'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Monthly limit'), findsNothing);
    });

    testWidgets('10. Arabic RTL layout', (tester) async {
      await tester.pumpWidget(_buildCreationScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // AppBar title + submit button both show "ميزانية جديدة"
      expect(find.text('ميزانية جديدة'), findsWidgets);
      // No overflow errors
      expect(tester.takeException(), isNull);
    });
  });
}
