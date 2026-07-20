import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// Displays a pre-formatted money string (presentation only).
class FinancialAmountText extends StatelessWidget {
  const FinancialAmountText({
    required this.formattedAmount,
    super.key,
    this.style,
    this.semanticsLabel,
    this.tone = FinancialAmountTone.neutral,
    this.isDisplay = false,
  });

  final String formattedAmount;
  final TextStyle? style;
  final String? semanticsLabel;
  final FinancialAmountTone tone;
  final bool isDisplay;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    final roles = context.textRoles;
    final Color color = switch (tone) {
      FinancialAmountTone.income => colors.income,
      FinancialAmountTone.expense => colors.expense,
      FinancialAmountTone.transfer => colors.transfer,
      FinancialAmountTone.protected => colors.protectedMoney,
      FinancialAmountTone.goal => colors.goalReserved,
      FinancialAmountTone.certificate => colors.certificatePrincipal,
      FinancialAmountTone.neutral => colors.primaryText,
    };
    final base = isDisplay ? roles.displayBalance : roles.financialAmount;
    return Text(
      formattedAmount,
      style: (style ?? base).copyWith(color: color),
      semanticsLabel: semanticsLabel ?? formattedAmount,
      textAlign: TextAlign.start,
    );
  }
}

enum FinancialAmountTone {
  neutral,
  income,
  expense,
  transfer,
  protected,
  goal,
  certificate,
}

class CurrencyAmountRow extends StatelessWidget {
  const CurrencyAmountRow({
    required this.label,
    required this.formattedAmount,
    super.key,
    this.currencyCode,
    this.tone = FinancialAmountTone.neutral,
  });

  final String label;
  final String formattedAmount;
  final String? currencyCode;
  final FinancialAmountTone tone;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: roles.body)),
          if (currencyCode != null) ...[
            Text(currencyCode!, style: roles.supportingMeta),
            const SizedBox(width: AppTheme.space8),
          ],
          FinancialAmountText(formattedAmount: formattedAmount, tone: tone),
        ],
      ),
    );
  }
}

class FinancialMetric extends StatelessWidget {
  const FinancialMetric({
    required this.label,
    required this.formattedAmount,
    super.key,
    this.caption,
    this.tone = FinancialAmountTone.neutral,
    this.icon,
  });

  final String label;
  final String formattedAmount;
  final String? caption;
  final FinancialAmountTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: context.financialColors.secondaryText,
              ),
              const SizedBox(width: AppTheme.space8),
            ],
            Expanded(child: Text(label, style: roles.supportingMeta)),
          ],
        ),
        const SizedBox(height: AppTheme.space4),
        FinancialAmountText(formattedAmount: formattedAmount, tone: tone),
        if (caption != null) ...[
          const SizedBox(height: AppTheme.space4),
          Text(caption!, style: roles.supportingMeta),
        ],
      ],
    );
  }
}

class FinancialSummary extends StatelessWidget {
  const FinancialSummary({
    required this.title,
    required this.formattedAmount,
    super.key,
    this.subtitle,
    this.tone = FinancialAmountTone.neutral,
    this.child,
  });

  final String title;
  final String formattedAmount;
  final String? subtitle;
  final FinancialAmountTone tone;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final roles = context.textRoles;
    final colors = context.financialColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: colors.secondarySurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: roles.supportingMeta),
          const SizedBox(height: AppTheme.space8),
          FinancialAmountText(
            formattedAmount: formattedAmount,
            tone: tone,
            isDisplay: true,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.space8),
            Text(subtitle!, style: roles.supportingMeta),
          ],
          if (child != null) ...[
            const SizedBox(height: AppTheme.space16),
            child!,
          ],
        ],
      ),
    );
  }
}
