/// The date sheet.
///
/// The rule under test is the one the stock picker could not express: bounds
/// come from what the date is *for*. Every call site used to invent its own
/// pair, and one of them let an expense be recorded a year in the future.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime? picked;
bool wasDismissed = false;

Widget _buildApp({
  required DatePurpose purpose,
  DateTime? initialDate,
  DateTime? earliest,
}) => MaterialApp(
  theme: AppTheme.light(),
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
            picked = await showAppDatePicker(
              context: context,
              initialDate: initialDate ?? DateTime.now(),
              purpose: purpose,
              earliest: earliest,
            );
            wasDismissed = picked == null;
          },
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

Future<AppLocalizations> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(CalendarDatePicker)));
}

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  setUp(() {
    picked = null;
    wasDismissed = false;
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 2400);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  group('a ledger entry cannot happen in the future', () {
    testWidgets('the grid stops at today', (tester) async {
      await tester.pumpWidget(_buildApp(purpose: DatePurpose.ledgerEntry));
      await _open(tester);

      final grid = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(grid.lastDate, _today);
    });

    testWidgets('and says why the days after it are grey', (tester) async {
      await tester.pumpWidget(_buildApp(purpose: DatePurpose.ledgerEntry));
      final l10n = await _open(tester);

      // An explained constraint is a rule; an unexplained one is a bug the
      // user works around.
      expect(find.text(l10n.datePickerNoFuture), findsOneWidget);
    });

    testWidgets('a stored future date opens on today, not on an assertion', (
      tester,
    ) async {
      // Data written before the bound existed — an expense dated next year.
      await tester.pumpWidget(
        _buildApp(
          purpose: DatePurpose.ledgerEntry,
          initialDate: _today.add(const Duration(days: 400)),
        ),
      );
      await _open(tester);

      expect(tester.takeException(), isNull);
      final grid = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(grid.initialDate, _today);
    });
  });

  group('a target date is nothing but the future', () {
    testWidgets('the grid runs well past today', (tester) async {
      await tester.pumpWidget(_buildApp(purpose: DatePurpose.futureTarget));
      await _open(tester);

      final grid = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(grid.lastDate.isAfter(_today), isTrue);
    });

    testWidgets('no future warning, because there is nothing to warn about', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(purpose: DatePurpose.futureTarget));
      final l10n = await _open(tester);

      expect(find.text(l10n.datePickerNoFuture), findsNothing);
    });

    testWidgets("a caller's own floor is honoured", (tester) async {
      final floor = _today.add(const Duration(days: 30));
      await tester.pumpWidget(
        _buildApp(
          purpose: DatePurpose.futureTarget,
          earliest: floor,
          initialDate: floor.add(const Duration(days: 10)),
        ),
      );
      await _open(tester);

      final grid = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(grid.firstDate, floor);
    });
  });

  group('the shortcuts', () {
    testWidgets('answer the question without opening the grid', (tester) async {
      await tester.pumpWidget(_buildApp(purpose: DatePurpose.ledgerEntry));
      final l10n = await _open(tester);

      await tester.tap(find.text(l10n.datePickerYesterday));
      await tester.pumpAndSettle();

      expect(picked, _today.subtract(const Duration(days: 1)));
    });

    testWidgets(
      'a shortcut outside the bounds is dropped, never offered and refused',
      (tester) async {
        // A goal aimed at least a month out: today and yesterday are both
        // impossible, so neither is shown.
        await tester.pumpWidget(
          _buildApp(
            purpose: DatePurpose.futureTarget,
            earliest: _today.add(const Duration(days: 30)),
            initialDate: _today.add(const Duration(days: 40)),
          ),
        );
        final l10n = await _open(tester);

        expect(find.text(l10n.datePickerToday), findsNothing);
        expect(find.text(l10n.datePickerYesterday), findsNothing);
        expect(find.text(l10n.datePickerStartOfMonth), findsNothing);
      },
    );
  });

  testWidgets('dismissing returns nothing', (tester) async {
    await tester.pumpWidget(_buildApp(purpose: DatePurpose.ledgerEntry));
    await _open(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(picked, isNull);
    expect(wasDismissed, isTrue);
  });

  testWidgets('confirming returns the selected date', (tester) async {
    final start = _today.subtract(const Duration(days: 5));
    await tester.pumpWidget(
      _buildApp(purpose: DatePurpose.ledgerEntry, initialDate: start),
    );
    final l10n = await _open(tester);

    await tester.tap(find.text(l10n.datePickerConfirm));
    await tester.pumpAndSettle();

    expect(picked, start);
  });
}
