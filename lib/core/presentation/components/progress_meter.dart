/// Consumption of a plan — a budget or a goal — encoded so that colour
/// contributes nothing to reading it.
library;

import 'dart:math' as math;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/components/financial_amount_text.dart';
import 'package:family_money_manager/core/presentation/components/hatch_pattern.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// What a meter's overshoot means. Budgets and goals overshoot for opposite
/// reasons, and the band past the mark carries the difference.
enum ProgressMeterRole {
  /// Over budget: the excess is money that left.
  budget,

  /// Overfunded goal: the excess is money still held.
  goal,
}

/// A single meter serving budgets and goals alike.
///
/// One rule makes that possible: **consumption is always ink**. Ink means
/// "how much of the plan is used up" and carries no judgement, which is what
/// lets the same widget say "68% of your grocery budget" and "68% of the way
/// to the school fees" without implying that either is good or bad. The
/// [role] enters only as the hatch on an overshoot band, where a judgement
/// genuinely exists.
///
/// Filling a goal meter in `goalReserved` would quietly make this two
/// components again — the exact duplication the shared kit exists to prevent.
class ProgressMeter extends StatelessWidget {
  const ProgressMeter({
    required this.consumedMinorUnits,
    required this.totalMinorUnits,
    required this.currencyCode,
    required this.stateLabel,
    required this.role,
    super.key,
    this.label,
    this.semanticsContext,
  });

  final int consumedMinorUnits;
  final int totalMinorUnits;
  final String currencyCode;

  /// The state, already localised and already decided by the domain — "on
  /// track", "near the limit", "over budget".
  ///
  /// The meter never derives this. Thresholds are a domain rule; a widget
  /// that invented its own would be a second, silent source of truth about
  /// whether a household is overspending.
  final String stateLabel;

  final ProgressMeterRole role;
  final String? label;
  final String? semanticsContext;

  static const double _trackHeight = 12;

  /// Percentages **truncate**. 2,410 of 3,500 is 68%, never 69 — rounding a
  /// consumption figure upward tells a household it has less left than it
  /// does.
  int get percentUsed {
    if (totalMinorUnits <= 0) return 0;
    return (consumedMinorUnits * 100) ~/ totalMinorUnits;
  }

  bool get _hasOvershoot => consumedMinorUnits > totalMinorUnits;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    final roles = context.textRoles;

    return Semantics(
      container: true,
      label: [
        if (label case final String text) text,
        stateLabel,
        '$percentUsed%',
        if (semanticsContext case final String extra) extra,
      ].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label case final String text) ...[
            Row(
              children: [
                Expanded(child: Text(text, style: roles.cardTitle)),
                const SizedBox(width: AppTheme.space8),
                FinancialAmountText(
                  minorUnits: consumedMinorUnits,
                  currencyCode: currencyCode,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space8),
          ],
          _Track(
            fraction: totalMinorUnits <= 0
                ? 0
                : consumedMinorUnits / totalMinorUnits,
            role: role,
            hasOvershoot: _hasOvershoot,
          ),
          const SizedBox(height: AppTheme.space8),
          // The state is printed, so the meter is legible with no vision of
          // the bar at all — and the percentage is never the only signal.
          Text(
            stateLabel,
            style: roles.supportingMeta.copyWith(
              color: _hasOvershoot ? colors.primaryText : colors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.fraction,
    required this.role,
    required this.hasOvershoot,
  });

  final double fraction;
  final ProgressMeterRole role;
  final bool hasOvershoot;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    final overshootColor = switch (role) {
      ProgressMeterRole.budget => colors.expense,
      ProgressMeterRole.goal => colors.goalReserved,
    };

    return SizedBox(
      height: ProgressMeter._trackHeight,
      child: CustomPaint(
        painter: _MeterPainter(
          fraction: fraction,
          ink: colors.primaryText,
          remainderHatch: colors.secondaryText,
          overshootHatch: overshootColor,
          background: colors.secondarySurface,
          hasOvershoot: hasOvershoot,
          direction: Directionality.of(context),
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// Fill = ink. Remainder = hatch. Overshoot = a second hatch band that carries
/// the role — so the state is readable as geometry, in greyscale, before any
/// colour is perceived.
class _MeterPainter extends CustomPainter {
  const _MeterPainter({
    required this.fraction,
    required this.ink,
    required this.remainderHatch,
    required this.overshootHatch,
    required this.background,
    required this.hasOvershoot,
    required this.direction,
  });

  final double fraction;
  final Color ink;
  final Color remainderHatch;
  final Color overshootHatch;
  final Color background;
  final bool hasOvershoot;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    canvas.drawRect(full, Paint()..color = background);

    // Progress fills from the leading edge, so it mirrors with the language.
    final isRtl = direction == TextDirection.rtl;
    Rect leading(double fromFraction, double toFraction) {
      final from = size.width * fromFraction.clamp(0.0, 1.0);
      final to = size.width * toFraction.clamp(0.0, 1.0);
      return isRtl
          ? Rect.fromLTRB(size.width - to, 0, size.width - from, size.height)
          : Rect.fromLTRB(from, 0, to, size.height);
    }

    final consumed = math.min(fraction, 1.0);
    canvas.drawRect(leading(0, consumed), Paint()..color = ink);

    if (consumed < 1.0) {
      paintHatch(canvas, leading(consumed, 1), remainderHatch);
    }

    if (hasOvershoot) {
      // The overshoot band sits outside the mark, hatched in the role — a
      // second geometric channel, not a recolouring of the fill.
      paintHatch(
        canvas,
        leading(0, 1),
        overshootHatch,
        density: HatchDensity.dense,
      );
      canvas.drawRect(
        leading(0, 1),
        Paint()
          ..color = overshootHatch
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppTheme.regionRuleWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.fraction != fraction ||
      old.hasOvershoot != hasOvershoot ||
      old.direction != direction ||
      old.ink != ink;
}
