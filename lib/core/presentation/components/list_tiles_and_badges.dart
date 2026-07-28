import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/components/financial_amount_text.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

enum FinancialTypeKind {
  income,
  expense,
  transfer,
  reversal,
  adjustment,
  goal,
  certificate,
  other,
}

class FinancialTypeBadge extends StatelessWidget {
  const FinancialTypeBadge({
    required this.label,
    required this.kind,
    super.key,
  });

  final String label;
  final FinancialTypeKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    final (Color fg, IconData icon) = switch (kind) {
      FinancialTypeKind.income => (colors.income, Icons.south_west),
      FinancialTypeKind.expense => (colors.expense, Icons.north_east),
      FinancialTypeKind.transfer => (colors.transfer, Icons.swap_horiz),
      FinancialTypeKind.reversal => (colors.warning, Icons.undo),
      FinancialTypeKind.adjustment => (colors.neutralInfo, Icons.tune),
      FinancialTypeKind.goal => (colors.goalReserved, Icons.flag_outlined),
      FinancialTypeKind.certificate => (
        colors.certificatePrincipal,
        Icons.account_balance_outlined,
      ),
      FinancialTypeKind.other => (colors.neutralInfo, Icons.receipt_long),
    };
    return StatusBadge(label: label, foreground: fg, icon: icon);
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.foreground,
    super.key,
    this.icon,
  });

  final String label;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space8,
          vertical: AppTheme.space4,
        ),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
          border: Border.all(color: foreground.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: AppTheme.space4),
            ],
            Text(
              label,
              style: context.textRoles.statusLabel.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    required this.typeLabel,
    required this.typeKind,
    required this.primaryDescription,
    required this.accountOrDirection,
    required this.effectiveDate,
    required this.minorUnits,
    required this.currencyCode,
    super.key,
    this.memberOrCategory,
    this.isReversed = false,
    this.reversedLabel,
    this.associationLabel,
    this.onTap,
  });

  final String typeLabel;
  final FinancialTypeKind typeKind;
  final String primaryDescription;
  final String accountOrDirection;
  final String effectiveDate;
  final int minorUnits;
  final String currencyCode;
  final String? memberOrCategory;
  final bool isReversed;
  final String? reversedLabel;
  final String? associationLabel;
  final VoidCallback? onTap;

  /// Minimum, never fixed: a long Arabic description wraps and the tile grows.
  static const double minHeight = 64;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    final direction = switch (typeKind) {
      FinancialTypeKind.income => FinancialAmountDirection.inflow,
      FinancialTypeKind.expense => FinancialAmountDirection.outflow,
      FinancialTypeKind.transfer => FinancialAmountDirection.internal,
      FinancialTypeKind.goal ||
      FinancialTypeKind.certificate => FinancialAmountDirection.held,
      _ => FinancialAmountDirection.none,
    };
    final tone = switch (typeKind) {
      FinancialTypeKind.income => FinancialAmountTone.income,
      FinancialTypeKind.expense => FinancialAmountTone.expense,
      FinancialTypeKind.transfer => FinancialAmountTone.transfer,
      FinancialTypeKind.goal => FinancialAmountTone.goal,
      FinancialTypeKind.certificate => FinancialAmountTone.certificate,
      _ => FinancialAmountTone.neutral,
    };
    final colors = context.financialColors;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        // A tonal press, never a ripple: an expanding circle contradicts a
        // square system and reads as something happening to the money.
        splashFactory: NoSplash.splashFactory,
        highlightColor: colors.secondarySurface,
        child: Container(
          constraints: const BoxConstraints(minHeight: minHeight),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: FinancialTypeBadge(
                            label: typeLabel,
                            kind: typeKind,
                          ),
                        ),
                        if (isReversed && reversedLabel != null) ...[
                          const SizedBox(width: AppTheme.space8),
                          StatusBadge(
                            // A correction, not a threshold — grey ink with
                            // the undo glyph, never the warning role.
                            label: reversedLabel!,
                            foreground: colors.secondaryText,
                            icon: Icons.undo,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(primaryDescription, style: roles.body, maxLines: 3),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      [
                        accountOrDirection,
                        effectiveDate,
                        ?memberOrCategory,
                        ?associationLabel,
                      ].join(' · '),
                      style: roles.supportingMeta,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              // See AccountListTile: a non-flexible child in a Row is measured
              // against unbounded width and would starve the description.
              Flexible(
                child: FinancialAmountText(
                  minorUnits: minorUnits,
                  currencyCode: currencyCode,
                  // A reversed entry keeps its amount in place, struck through
                  // and quietened — the original is never removed.
                  tone: isReversed ? FinancialAmountTone.muted : tone,
                  direction: isReversed
                      ? FinancialAmountDirection.none
                      : direction,
                  isStruckThrough: isReversed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
