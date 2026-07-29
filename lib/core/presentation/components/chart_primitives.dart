/// Three chart primitives, and no more.
///
/// All ink. A chart in this product has no palette: a bar is not a colour, it
/// is a length on a shared baseline, and colour enters only as a hatch
/// carrying an exception — a reversed category, an overshoot. That is
/// [ProgressMeter]'s rule extended to charts, and it is what keeps every one
/// of them legible in greyscale, under dichromacy, and in forced-colours mode
/// without a second design.
///
/// There is no pie and there will not be one: wedges cannot be compared by
/// eye, and [ShareBar] answers the same question against a common baseline.
///
/// Lines get points, not curves. A smoothed line asserts values between
/// measurements, and in a ledger every value between two month-end snapshots
/// is a fiction.
///
/// **The governing rule for all three:** a chart follows the table of its own
/// numbers and never shows a figure that is not in that table. If the table
/// is removed, the chart goes with it — a picture nobody can check is
/// decoration, and this product does not decorate money.
library;

import 'dart:math' as math;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/components/hatch_pattern.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Mark geometry, fixed across all three primitives.
abstract final class _Mark {
  /// Bars never fill their slot; the leftover band is air.
  static const double maxBarThickness = 24;

  /// The data end is rounded, the baseline end is square — so the baseline
  /// stays a hard line and the bar cannot be mistaken for a pill.
  static const double dataEndRadius = 4;

  static const double lineWidth = 2;

  /// Big enough to be seen and to be hit.
  static const double markerRadius = 5;

  /// Marks are separated by surface, never by a stroke around them. A stroke
  /// is ink that is not data.
  static const double surfaceGap = 2;

  static const double gridLineWidth = 1;
}

// ── ShareBar ─────────────────────────────────────────────────────────────────

/// One part against its whole, on a common baseline.
///
/// The bar carries no colour, because a proportion is not a verdict: 27% of
/// the household's spending being housing is neither good nor bad, and a
/// green or red bar would say otherwise. The remainder is left empty rather
/// than filled with a second tone — an unfilled track reads as "not this"
/// faster than any second colour.
class ShareBar extends StatelessWidget {
  const ShareBar({
    required this.label,
    required this.fraction,
    required this.valueLabel,
    super.key,
    this.caption,
    this.isException = false,
  });

  final String label;

  /// Share of the whole, 0–1. Values outside the range are clamped: a share
  /// above its own whole is a query defect, and a bar drawn past its track
  /// would hide it rather than show it.
  final double fraction;

  /// The figure this bar draws, already formatted. Always present — a bar
  /// without its number is not checkable.
  final String valueLabel;

  final String? caption;

  /// Marks this share as carrying an exception, drawn as a hatch over the
  /// fill. The one place colour is admitted, and it is texture first.
  final bool isException;

  static const double _trackHeight = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    final roles = context.textRoles;
    final clamped = fraction.clamp(0.0, 1.0);

    return Semantics(
      // The bar is decoration over a number the label already carries; a
      // screen reader gets the pair as one phrase rather than a rectangle.
      container: true,
      excludeSemantics: true,
      label: '$label $valueLabel',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: roles.body)),
                const SizedBox(width: AppTheme.space8),
                Text(valueLabel, style: roles.supportingMeta),
              ],
            ),
            const SizedBox(height: AppTheme.space4),
            SizedBox(
              height: _trackHeight,
              child: CustomPaint(
                size: Size.infinite,
                painter: _ShareBarPainter(
                  fraction: clamped,
                  ink: colors.primaryText,
                  track: colors.secondarySurface,
                  exceptionHatch: colors.warning,
                  isException: isException,
                  direction: Directionality.of(context),
                ),
              ),
            ),
            if (caption case final String text) ...[
              const SizedBox(height: AppTheme.space4),
              Text(
                text,
                style: roles.supportingMeta.copyWith(
                  color: colors.secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareBarPainter extends CustomPainter {
  const _ShareBarPainter({
    required this.fraction,
    required this.ink,
    required this.track,
    required this.exceptionHatch,
    required this.isException,
    required this.direction,
  });

  final double fraction;
  final Color ink;
  final Color track;
  final Color exceptionHatch;
  final bool isException;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = track);
    if (fraction <= 0) return;

    // The bar grows from the leading edge, so it mirrors with the language
    // rather than always growing to the right.
    final isRtl = direction == TextDirection.rtl;
    final width = size.width * fraction;
    final rect = isRtl
        ? Rect.fromLTRB(size.width - width, 0, size.width, size.height)
        : Rect.fromLTRB(0, 0, width, size.height);

    // Rounded at the data end only; the baseline end stays square.
    const radius = Radius.circular(_Mark.dataEndRadius);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: isRtl ? radius : Radius.zero,
        bottomLeft: isRtl ? radius : Radius.zero,
        topRight: isRtl ? Radius.zero : radius,
        bottomRight: isRtl ? Radius.zero : radius,
      ),
      Paint()..color = ink,
    );

    if (isException) {
      paintHatch(canvas, rect, exceptionHatch, density: HatchDensity.dense);
    }
  }

  @override
  bool shouldRepaint(_ShareBarPainter old) =>
      old.fraction != fraction ||
      old.ink != ink ||
      old.track != track ||
      old.isException != isException ||
      old.direction != direction;
}

// ── BarSeries ────────────────────────────────────────────────────────────────

/// One bar in a [BarSeries].
@immutable
class ChartBar {
  const ChartBar({
    required this.label,
    required this.value,
    required this.valueLabel,
    this.isException = false,
  });

  final String label;

  /// Magnitude. Negative values are not drawn — a bar chart comparing
  /// categories compares sizes, and a ledger's outflows are already positive
  /// magnitudes by the time they reach a chart.
  final double value;

  /// The figure, already formatted. Shown at the bar's tip.
  final String valueLabel;

  /// Draws this bar hatched. Reserved for a category containing a reversal,
  /// which is the only reason one bar differs in kind from its neighbours.
  final bool isException;
}

/// Categories compared on one baseline, sorted by whoever supplies them.
///
/// Horizontal, not vertical, for one reason: category names in Arabic are
/// long, and a vertical column chart either truncates them or rotates them
/// 90°. A rotated label is a label nobody reads.
class BarSeries extends StatelessWidget {
  const BarSeries({required this.bars, super.key, this.maxValue});

  final List<ChartBar> bars;

  /// The value the longest bar represents. Defaults to the largest bar.
  ///
  /// Pass it explicitly when two series must be compared against each other:
  /// bars normalised to their own maxima look identical no matter what they
  /// contain, which is the most common way a bar chart lies.
  final double? maxValue;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();

    final colors = context.financialColors;
    final roles = context.textRoles;
    final scale =
        maxValue ??
        bars.fold<double>(0, (max, bar) => math.max(max, bar.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final bar in bars)
          Semantics(
            container: true,
            excludeSemantics: true,
            label: '${bar.label} ${bar.valueLabel}',
            child: Padding(
              // The gap between neighbours is surface, not a stroke.
              padding: const EdgeInsets.symmetric(
                vertical: _Mark.surfaceGap + AppTheme.space4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      bar.label,
                      style: roles.supportingMeta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: SizedBox(
                      height: 12,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _BarPainter(
                          fraction: scale <= 0
                              ? 0
                              : (bar.value / scale).clamp(0.0, 1.0),
                          ink: colors.primaryText,
                          exceptionHatch: colors.warning,
                          isException: bar.isException,
                          direction: Directionality.of(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  // Every bar is labelled here rather than selectively,
                  // because the design's rule is stronger than the general
                  // one: a chart shows no figure absent from its table, and
                  // this row *is* that table.
                  Text(bar.valueLabel, style: roles.supportingMeta),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.fraction,
    required this.ink,
    required this.exceptionHatch,
    required this.isException,
    required this.direction,
  });

  final double fraction;
  final Color ink;
  final Color exceptionHatch;
  final bool isException;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final isRtl = direction == TextDirection.rtl;
    final thickness = math.min(size.height, _Mark.maxBarThickness);
    final top = (size.height - thickness) / 2;

    // The baseline itself, always drawn: a bar with no baseline is a floating
    // rectangle, and zero has to be visible for a length to mean anything.
    final baselineX = isRtl ? size.width : 0.0;
    canvas.drawLine(
      Offset(baselineX, 0),
      Offset(baselineX, size.height),
      Paint()
        ..color = ink
        ..strokeWidth = _Mark.gridLineWidth,
    );

    if (fraction <= 0) return;

    final width = size.width * fraction;
    final rect = isRtl
        ? Rect.fromLTRB(size.width - width, top, size.width, top + thickness)
        : Rect.fromLTRB(0, top, width, top + thickness);

    const radius = Radius.circular(_Mark.dataEndRadius);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: isRtl ? radius : Radius.zero,
        bottomLeft: isRtl ? radius : Radius.zero,
        topRight: isRtl ? Radius.zero : radius,
        bottomRight: isRtl ? Radius.zero : radius,
      ),
      Paint()..color = ink,
    );

    if (isException) {
      paintHatch(canvas, rect, exceptionHatch, density: HatchDensity.dense);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.fraction != fraction ||
      old.ink != ink ||
      old.isException != isException ||
      old.direction != direction;
}

// ── LineSeries ───────────────────────────────────────────────────────────────

/// One measured point.
@immutable
class ChartPoint {
  const ChartPoint({required this.label, required this.value});

  /// What was measured — a month end, a statement date.
  final String label;

  final double value;
}

/// A value over time, as points joined by a thin line.
///
/// No smoothing, no gradient, no entry animation. A point is a measurement
/// and the segment between two points is a convenience for the eye, not a
/// claim about the days in between.
class LineSeries extends StatelessWidget {
  const LineSeries({
    required this.points,
    required this.valueLabels,
    super.key,
  });

  final List<ChartPoint> points;

  /// The formatted figure for each point, by index. Rendered under the axis
  /// so the chart never carries a number its own labels do not.
  final List<String> valueLabels;

  static const double _plotHeight = 120;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();

    final colors = context.financialColors;
    final roles = context.textRoles;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: [
        for (var i = 0; i < points.length; i++)
          '${points[i].label} ${i < valueLabels.length ? valueLabels[i] : ''}',
      ].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _plotHeight,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LinePainter(
                values: [for (final point in points) point.value],
                ink: colors.primaryText,
                grid: colors.divider,
                surface: colors.mainSurface,
                direction: Directionality.of(context),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Row(
            children: [
              for (final point in points)
                Expanded(
                  child: Text(
                    point.label,
                    style: roles.supportingMeta.copyWith(
                      color: colors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.values,
    required this.ink,
    required this.grid,
    required this.surface,
    required this.direction,
  });

  final List<double> values;
  final Color ink;
  final Color grid;
  final Color surface;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    // A flat series would divide by zero; give it a band so the line sits in
    // the middle rather than collapsing onto an edge.
    final span = max - min == 0 ? 1.0 : max - min;

    // A hairline baseline, solid. Never dashed — a dashed rule reads as a
    // boundary that means something, and this one is only a floor.
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = grid
        ..strokeWidth = _Mark.gridLineWidth,
    );

    final isRtl = direction == TextDirection.rtl;
    final step = values.length == 1 ? 0.0 : size.width / (values.length - 1);
    // Time runs with the language: the earliest measurement sits at the
    // leading edge in both scripts.
    Offset pointAt(int index) {
      final x = isRtl ? size.width - step * index : step * index;
      final normalised = (values[index] - min) / span;
      // Inset so a marker at an extreme is not clipped by the plot edge.
      final usable = size.height - _Mark.markerRadius * 2;
      final y = size.height - _Mark.markerRadius - normalised * usable;
      return Offset(x, y);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final point = pointAt(i);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = _Mark.lineWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < values.length; i++) {
      final point = pointAt(i);
      // A surface ring, not a stroke: it keeps the marker legible where it
      // crosses the line without adding ink that is not data.
      canvas
        ..drawCircle(
          point,
          _Mark.markerRadius + _Mark.surfaceGap,
          Paint()..color = surface,
        )
        ..drawCircle(point, _Mark.markerRadius, Paint()..color = ink);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      !listEquals(old.values, values) ||
      old.ink != ink ||
      old.grid != grid ||
      old.surface != surface ||
      old.direction != direction;
}
