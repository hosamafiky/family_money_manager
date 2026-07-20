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

class AccountListTile extends StatelessWidget {
  const AccountListTile({
    required this.name,
    required this.formattedBalance,
    required this.subtitle,
    super.key,
    this.trailingBadge,
    this.onTap,
    this.isSecondary = false,
  });

  final String name;
  final String formattedBalance;
  final String subtitle;
  final Widget? trailingBadge;
  final VoidCallback? onTap;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    final opacity = isSecondary ? 0.72 : 1.0;
    return Opacity(
      opacity: opacity,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space4,
        ),
        title: Text(name, style: roles.cardTitle),
        subtitle: Text(subtitle, style: roles.supportingMeta),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formattedBalance, style: roles.financialAmount),
            if (trailingBadge != null) ...[
              const SizedBox(height: AppTheme.space4),
              trailingBadge!,
            ],
          ],
        ),
        onTap: onTap,
        minVerticalPadding: AppTheme.space8,
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
    required this.formattedAmount,
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
  final String formattedAmount;
  final String? memberOrCategory;
  final bool isReversed;
  final String? reversedLabel;
  final String? associationLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    final tone = switch (typeKind) {
      FinancialTypeKind.income => FinancialAmountTone.income,
      FinancialTypeKind.expense => FinancialAmountTone.expense,
      FinancialTypeKind.transfer => FinancialAmountTone.transfer,
      FinancialTypeKind.goal => FinancialAmountTone.goal,
      FinancialTypeKind.certificate => FinancialAmountTone.certificate,
      _ => FinancialAmountTone.neutral,
    };
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      isThreeLine: true,
      title: Row(
        children: [
          Flexible(
            child: FinancialTypeBadge(label: typeLabel, kind: typeKind),
          ),
          if (isReversed && reversedLabel != null) ...[
            const SizedBox(width: AppTheme.space8),
            StatusBadge(
              label: reversedLabel!,
              foreground: context.financialColors.warning,
              icon: Icons.undo,
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.space4),
          Text(
            primaryDescription,
            style: roles.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: FinancialAmountText(
        formattedAmount: formattedAmount,
        tone: isReversed ? FinancialAmountTone.neutral : tone,
      ),
      onTap: onTap,
    );
  }
}
