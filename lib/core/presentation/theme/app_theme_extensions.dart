import 'package:flutter/material.dart';

/// Semantic financial and surface colors. Never use as the sole status cue —
/// pair with text, icon, or shape.
@immutable
class AppFinancialColors extends ThemeExtension<AppFinancialColors> {
  const AppFinancialColors({
    required this.primaryAction,
    required this.income,
    required this.expense,
    required this.transfer,
    required this.protectedMoney,
    required this.goalReserved,
    required this.certificatePrincipal,
    required this.warning,
    required this.success,
    required this.neutralInfo,
    required this.mainSurface,
    required this.secondarySurface,
    required this.divider,
    required this.primaryText,
    required this.secondaryText,
    required this.disabled,
  });

  final Color primaryAction;
  final Color income;
  final Color expense;
  final Color transfer;
  final Color protectedMoney;
  final Color goalReserved;
  final Color certificatePrincipal;
  final Color warning;
  final Color success;
  final Color neutralInfo;
  final Color mainSurface;
  final Color secondarySurface;
  final Color divider;
  final Color primaryText;
  final Color secondaryText;
  final Color disabled;

  static AppFinancialColors light(ColorScheme scheme) => AppFinancialColors(
    primaryAction: scheme.primary,
    income: const Color(0xFF2E7D4F),
    expense: const Color(0xFFB54A3F),
    transfer: const Color(0xFF4A6670),
    protectedMoney: const Color(0xFF6B5B3E),
    goalReserved: const Color(0xFF3D6B8A),
    certificatePrincipal: const Color(0xFF5A4E7C),
    warning: const Color(0xFFB8831A),
    success: const Color(0xFF2E7D4F),
    neutralInfo: scheme.onSurfaceVariant,
    mainSurface: scheme.surface,
    secondarySurface: scheme.surfaceContainerLow,
    divider: scheme.outlineVariant,
    primaryText: scheme.onSurface,
    secondaryText: scheme.onSurfaceVariant,
    disabled: scheme.onSurface.withValues(alpha: 0.38),
  );

  static AppFinancialColors dark(ColorScheme scheme) => AppFinancialColors(
    primaryAction: scheme.primary,
    income: const Color(0xFF81C784),
    expense: const Color(0xFFE57373),
    transfer: const Color(0xFF90A4AE),
    protectedMoney: const Color(0xFFD7CCC8),
    goalReserved: const Color(0xFF80CBC4),
    certificatePrincipal: const Color(0xFFB39DDB),
    warning: const Color(0xFFFFB74D),
    success: const Color(0xFF81C784),
    neutralInfo: scheme.onSurfaceVariant,
    mainSurface: scheme.surface,
    secondarySurface: scheme.surfaceContainerHigh,
    divider: scheme.outlineVariant,
    primaryText: scheme.onSurface,
    secondaryText: scheme.onSurfaceVariant,
    disabled: scheme.onSurface.withValues(alpha: 0.38),
  );

  @override
  AppFinancialColors copyWith({
    Color? primaryAction,
    Color? income,
    Color? expense,
    Color? transfer,
    Color? protectedMoney,
    Color? goalReserved,
    Color? certificatePrincipal,
    Color? warning,
    Color? success,
    Color? neutralInfo,
    Color? mainSurface,
    Color? secondarySurface,
    Color? divider,
    Color? primaryText,
    Color? secondaryText,
    Color? disabled,
  }) {
    return AppFinancialColors(
      primaryAction: primaryAction ?? this.primaryAction,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
      protectedMoney: protectedMoney ?? this.protectedMoney,
      goalReserved: goalReserved ?? this.goalReserved,
      certificatePrincipal: certificatePrincipal ?? this.certificatePrincipal,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      neutralInfo: neutralInfo ?? this.neutralInfo,
      mainSurface: mainSurface ?? this.mainSurface,
      secondarySurface: secondarySurface ?? this.secondarySurface,
      divider: divider ?? this.divider,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  AppFinancialColors lerp(ThemeExtension<AppFinancialColors>? other, double t) {
    if (other is! AppFinancialColors) return this;
    return AppFinancialColors(
      primaryAction: Color.lerp(primaryAction, other.primaryAction, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      protectedMoney: Color.lerp(protectedMoney, other.protectedMoney, t)!,
      goalReserved: Color.lerp(goalReserved, other.goalReserved, t)!,
      certificatePrincipal: Color.lerp(
        certificatePrincipal,
        other.certificatePrincipal,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      neutralInfo: Color.lerp(neutralInfo, other.neutralInfo, t)!,
      mainSurface: Color.lerp(mainSurface, other.mainSurface, t)!,
      secondarySurface: Color.lerp(
        secondarySurface,
        other.secondarySurface,
        t,
      )!,
      divider: Color.lerp(divider, other.divider, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }
}

/// Semantic text styles for financial UI.
@immutable
class AppTextRoles extends ThemeExtension<AppTextRoles> {
  const AppTextRoles({
    required this.displayBalance,
    required this.screenTitle,
    required this.sectionTitle,
    required this.cardTitle,
    required this.body,
    required this.financialAmount,
    required this.supportingMeta,
    required this.formLabel,
    required this.buttonLabel,
    required this.statusLabel,
    required this.reportValue,
  });

  final TextStyle displayBalance;
  final TextStyle screenTitle;
  final TextStyle sectionTitle;
  final TextStyle cardTitle;
  final TextStyle body;
  final TextStyle financialAmount;
  final TextStyle supportingMeta;
  final TextStyle formLabel;
  final TextStyle buttonLabel;
  final TextStyle statusLabel;
  final TextStyle reportValue;

  factory AppTextRoles.fromScheme(ColorScheme scheme) {
    final on = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    return AppTextRoles(
      displayBalance: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.5,
        color: on,
      ),
      screenTitle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: on,
      ),
      sectionTitle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: on,
      ),
      cardTitle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: on,
      ),
      body: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: on,
      ),
      financialAmount: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: on,
      ),
      supportingMeta: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: muted,
      ),
      formLabel: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: on,
      ),
      buttonLabel: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: on,
      ),
      statusLabel: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: on,
      ),
      reportValue: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.3,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: on,
      ),
    );
  }

  @override
  AppTextRoles copyWith({
    TextStyle? displayBalance,
    TextStyle? screenTitle,
    TextStyle? sectionTitle,
    TextStyle? cardTitle,
    TextStyle? body,
    TextStyle? financialAmount,
    TextStyle? supportingMeta,
    TextStyle? formLabel,
    TextStyle? buttonLabel,
    TextStyle? statusLabel,
    TextStyle? reportValue,
  }) {
    return AppTextRoles(
      displayBalance: displayBalance ?? this.displayBalance,
      screenTitle: screenTitle ?? this.screenTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      cardTitle: cardTitle ?? this.cardTitle,
      body: body ?? this.body,
      financialAmount: financialAmount ?? this.financialAmount,
      supportingMeta: supportingMeta ?? this.supportingMeta,
      formLabel: formLabel ?? this.formLabel,
      buttonLabel: buttonLabel ?? this.buttonLabel,
      statusLabel: statusLabel ?? this.statusLabel,
      reportValue: reportValue ?? this.reportValue,
    );
  }

  @override
  AppTextRoles lerp(ThemeExtension<AppTextRoles>? other, double t) {
    if (other is! AppTextRoles) return this;
    return AppTextRoles(
      displayBalance: TextStyle.lerp(displayBalance, other.displayBalance, t)!,
      screenTitle: TextStyle.lerp(screenTitle, other.screenTitle, t)!,
      sectionTitle: TextStyle.lerp(sectionTitle, other.sectionTitle, t)!,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      financialAmount: TextStyle.lerp(
        financialAmount,
        other.financialAmount,
        t,
      )!,
      supportingMeta: TextStyle.lerp(supportingMeta, other.supportingMeta, t)!,
      formLabel: TextStyle.lerp(formLabel, other.formLabel, t)!,
      buttonLabel: TextStyle.lerp(buttonLabel, other.buttonLabel, t)!,
      statusLabel: TextStyle.lerp(statusLabel, other.statusLabel, t)!,
      reportValue: TextStyle.lerp(reportValue, other.reportValue, t)!,
    );
  }
}

extension AppThemeExtensions on BuildContext {
  AppFinancialColors get financialColors {
    final ext = Theme.of(this).extension<AppFinancialColors>();
    if (ext != null) return ext;
    return AppFinancialColors.light(Theme.of(this).colorScheme);
  }

  AppTextRoles get textRoles {
    final ext = Theme.of(this).extension<AppTextRoles>();
    if (ext != null) return ext;
    return AppTextRoles.fromScheme(Theme.of(this).colorScheme);
  }
}
