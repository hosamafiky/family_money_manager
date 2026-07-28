/// Layout primitives for money. The only sanctioned ways to place a
/// label-and-amount pair, a labelled figure, or a group of figures.
///
/// None of them formats anything: each delegates its number to
/// [FinancialAmountText], which is why privacy masking, bidi isolation and
/// screen-reader phrasing arrive for free and identically in all three.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/components/financial_amount_text.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// A label on the leading edge, an amount on the trailing edge, a hairline
/// below. The row of a review section, a report table and a certificate card
/// alike — they were three near-identical widgets before this existed.
class CurrencyAmountRow extends StatelessWidget {
  const CurrencyAmountRow({
    required this.label,
    required this.minorUnits,
    required this.currencyCode,
    super.key,
    this.tone = FinancialAmountTone.neutral,
    this.direction = FinancialAmountDirection.none,
    this.caption,
    this.isEmphasised = false,
    this.showDivider = true,
    this.semanticsContext,
  });

  final String label;
  final int minorUnits;
  final String currencyCode;
  final FinancialAmountTone tone;
  final FinancialAmountDirection direction;

  /// A second line under the label — a reason, a scope, a date. Never an
  /// amount: a row states one figure.
  final String? caption;

  /// Totals and derived results. Weight, not colour: a hue on a derived figure
  /// would imply a judgement about it.
  final bool isEmphasised;

  final bool showDivider;
  final String? semanticsContext;

  /// Below this much room for the label, label and amount stop sharing a
  /// baseline and stack instead. Long Arabic names and 200% text otherwise
  /// force the amount to truncate, and a truncated amount is worse than a
  /// tall row.
  static const double _stackBelowLabelWidth = 148;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    final colors = context.financialColors;

    final labelStyle = isEmphasised
        ? roles.cardTitle
        : roles.body.copyWith(color: colors.primaryText);

    final amount = FinancialAmountText(
      minorUnits: minorUnits,
      currencyCode: currencyCode,
      tone: tone,
      direction: direction,
      semanticsContext: semanticsContext,
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider)),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: labelStyle),
              if (caption case final String text) ...[
                const SizedBox(height: AppTheme.space4),
                Text(text, style: roles.supportingMeta),
              ],
            ],
          );

          if (constraints.maxWidth < _stackBelowLabelWidth * 2) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                labelBlock,
                const SizedBox(height: AppTheme.space4),
                amount,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: labelBlock),
              const SizedBox(width: AppTheme.space12),
              amount,
            ],
          );
        },
      ),
    );
  }
}

/// A small label over a large figure. The unit a [FinancialSummary] is built
/// from, and the shape every report metric takes.
class FinancialMetric extends StatelessWidget {
  const FinancialMetric({
    required this.label,
    required this.minorUnits,
    required this.currencyCode,
    super.key,
    this.tone = FinancialAmountTone.neutral,
    this.direction = FinancialAmountDirection.none,
    this.caption,
    this.isEmphasised = false,
  });

  final String label;
  final int minorUnits;
  final String currencyCode;
  final FinancialAmountTone tone;
  final FinancialAmountDirection direction;
  final String? caption;

  /// Emphasis is a tonal fill, never a colour — the emphasised metric in a
  /// summary is usually a *derived* figure, and a hue would read as a verdict
  /// on it rather than as prominence.
  final bool isEmphasised;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    final colors = context.financialColors;

    return Container(
      width: double.infinity,
      color: isEmphasised ? colors.secondarySurface : null,
      padding: const EdgeInsets.all(AppTheme.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: roles.supportingMeta),
          const SizedBox(height: AppTheme.space4),
          FinancialAmountText(
            minorUnits: minorUnits,
            currencyCode: currencyCode,
            tone: tone,
            direction: direction,
            size: FinancialAmountSize.report,
          ),
          if (caption case final String text) ...[
            const SizedBox(height: AppTheme.space4),
            Text(text, style: roles.supportingMeta),
          ],
        ],
      ),
    );
  }
}

/// Two to four metrics in one ruled band — given / spent / returned /
/// remaining, gross / net, opening / closing.
///
/// Wraps to two columns when the width cannot give each metric room, rather
/// than shrinking the figures.
class FinancialSummary extends StatelessWidget {
  const FinancialSummary({required this.metrics, super.key});

  final List<FinancialMetric> metrics;

  /// Below this per-metric width the band goes two-up. Four figures across a
  /// compact phone would put each in about 80 dp, which cannot hold a
  /// grouped amount at 200% text scale.
  static const double _minMetricWidth = 120;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitsInOneRow =
            constraints.maxWidth >= _minMetricWidth * metrics.length;
        final columns = fitsInOneRow ? metrics.length : 2;

        return Container(
          decoration: BoxDecoration(
            color: colors.mainSurface,
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            children: [
              for (var start = 0; start < metrics.length; start += columns)
                // IntrinsicHeight gives the row a bound so its cells can
                // stretch to a common height — which is what makes the
                // internal hairline run the full depth of the band rather
                // than stopping at the shortest metric.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = start; i < start + columns; i++)
                        Expanded(
                          child: i < metrics.length
                              ? DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      // Internal hairlines only — the band's own
                                      // edge is drawn by the container.
                                      left: i > start
                                          ? BorderSide(color: colors.divider)
                                          : BorderSide.none,
                                      top: start > 0
                                          ? BorderSide(color: colors.divider)
                                          : BorderSide.none,
                                    ),
                                  ),
                                  child: metrics[i],
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
