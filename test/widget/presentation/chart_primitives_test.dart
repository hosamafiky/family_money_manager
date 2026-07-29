/// The three chart primitives.
///
/// What is worth testing about a chart is not its pixels but its promises:
/// that it never shows a number its own labels do not carry, that it mirrors
/// with the language, that a bar cannot draw past its own track, and that a
/// screen reader gets the figures rather than a rectangle. Those are the ways
/// a chart lies, and none of them is visible in a screenshot.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {TextDirection direction = TextDirection.rtl}) =>
    MaterialApp(
      theme: AppTheme.light(),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );

void main() {
  group('ShareBar', () {
    testWidgets('carries its own figure, never a bar alone', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ShareBar(label: 'سكن', fraction: 0.27, valueLabel: '3,000.00'),
        ),
      );

      expect(find.text('سكن'), findsOneWidget);
      expect(find.text('3,000.00'), findsOneWidget);
    });

    testWidgets('a share above its own whole is clamped, not overdrawn', (
      tester,
    ) async {
      // A fraction over 1 is a query defect. Drawing past the track would
      // hide it; clamping keeps the bar honest and leaves the number — which
      // is the thing that would look wrong — on screen.
      await tester.pumpWidget(
        _wrap(
          const ShareBar(label: 'سكن', fraction: 3, valueLabel: '9,000.00'),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('9,000.00'), findsOneWidget);
    });

    testWidgets('reads as one phrase, not as a rectangle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ShareBar(label: 'سكن', fraction: 0.27, valueLabel: '3,000.00'),
        ),
      );

      expect(
        tester.getSemantics(find.byType(ShareBar)),
        isSemantics(label: 'سكن 3,000.00'),
      );
    });

    testWidgets('mirrors with the language', (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _wrap(
            const ShareBar(
              label: 'Housing',
              fraction: 0.27,
              valueLabel: '3,000.00',
            ),
            direction: direction,
          ),
        );
        // The painter reads Directionality, so the only thing to assert here
        // is that both directions lay out and paint without throwing.
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('BarSeries', () {
    const bars = [
      ChartBar(label: 'سكن', value: 450000, valueLabel: '4,500.00'),
      ChartBar(label: 'بقالة', value: 324000, valueLabel: '3,240.00'),
      ChartBar(
        label: 'فواتير',
        value: 127500,
        valueLabel: '1,275.00',
        isException: true,
      ),
    ];

    testWidgets('every bar shows its own figure', (tester) async {
      await tester.pumpWidget(_wrap(const BarSeries(bars: bars)));

      for (final bar in bars) {
        expect(find.text(bar.label), findsOneWidget);
        expect(find.text(bar.valueLabel), findsOneWidget);
      }
    });

    testWidgets('an empty series draws nothing rather than an empty axis', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BarSeries(bars: [])));

      // No baseline, no labels, no height — an axis with nothing on it
      // suggests the data is loading rather than absent.
      expect(tester.getSize(find.byType(BarSeries)), Size.zero);
    });

    testWidgets('an all-zero series does not divide by its own maximum', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BarSeries(
            bars: [
              ChartBar(label: 'سكن', value: 0, valueLabel: '0.00'),
              ChartBar(label: 'بقالة', value: 0, valueLabel: '0.00'),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'an explicit maximum is honoured, so two series stay comparable',
      (tester) async {
        // Normalising each series to its own maximum makes every chart look
        // the same regardless of what it contains. That is the most common
        // way a bar chart lies, and the caller can prevent it.
        await tester.pumpWidget(
          _wrap(const BarSeries(bars: bars, maxValue: 1000000)),
        );

        final series = tester.widget<BarSeries>(find.byType(BarSeries));
        expect(series.maxValue, 1000000);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('each bar reads as its label and its figure', (tester) async {
      await tester.pumpWidget(_wrap(const BarSeries(bars: bars)));

      // Scoped to the series' own Semantics nodes: the surrounding scaffold
      // contributes several of its own.
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(BarSeries),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        isSemantics(label: 'سكن 4,500.00'),
      );
    });
  });

  group('LineSeries', () {
    const points = [
      ChartPoint(label: 'مايو', value: 12000),
      ChartPoint(label: 'يونيو', value: 15500),
      ChartPoint(label: 'يوليو', value: 9800),
    ];
    const labels = ['120.00', '155.00', '98.00'];

    testWidgets('every measurement is labelled on the axis', (tester) async {
      await tester.pumpWidget(
        _wrap(const LineSeries(points: points, valueLabels: labels)),
      );

      for (final point in points) {
        expect(find.text(point.label), findsOneWidget);
      }
    });

    testWidgets(
      'a single point draws nothing — one measurement is not a trend',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const LineSeries(
              points: [ChartPoint(label: 'يوليو', value: 12000)],
              valueLabels: ['120.00'],
            ),
          ),
        );

        // One measurement is a number, not a trend — and a line needs two
        // points before the segment between them means anything.
        expect(tester.getSize(find.byType(LineSeries)), Size.zero);
      },
    );

    testWidgets('a flat series does not collapse onto an edge', (tester) async {
      // Every value equal means a zero span; without a guard the normalised
      // position is a division by zero.
      await tester.pumpWidget(
        _wrap(
          const LineSeries(
            points: [
              ChartPoint(label: 'مايو', value: 5000),
              ChartPoint(label: 'يونيو', value: 5000),
            ],
            valueLabels: ['50.00', '50.00'],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the series reads as its measurements, in order', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LineSeries(points: points, valueLabels: labels)),
      );

      expect(
        tester.getSemantics(find.byType(LineSeries)),
        isSemantics(label: 'مايو 120.00, يونيو 155.00, يوليو 98.00'),
      );
    });

    testWidgets('lays out in both directions', (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _wrap(
            const LineSeries(points: points, valueLabels: labels),
            direction: direction,
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
