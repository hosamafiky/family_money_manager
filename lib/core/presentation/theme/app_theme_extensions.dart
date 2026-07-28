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
    required this.ground,
    required this.recessedSurface,
    required this.focusRing,
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

  /// The page itself — `scaffoldBackgroundColor`, and nothing else.
  ///
  /// Distinct from [mainSurface] so that a card is separable from the page by
  /// value alone. Without it, card separation has to come back from radius and
  /// shadow, both of which the design removes.
  final Color ground;

  /// The held-money region, and only that. One surface, one meaning.
  ///
  /// Money that is neither spendable nor protected (certificate principal,
  /// goal reserves) sits on this surface rather than being marked by a
  /// row-level tint, so the distinction survives greyscale and privacy mode.
  final Color recessedSurface;

  /// Keyboard focus only — a 2 px ring at 2 px offset, outside the control.
  ///
  /// Never replaces a control's own border. This is the one place raw accent
  /// appears outside the [expense] role, because a focus ring is chrome, not
  /// money.
  final Color focusRing;

  /// Light palette. Every role is a literal.
  ///
  /// Eight of these used to read off `ColorScheme.fromSeed`. They no longer
  /// do, because the design is calibrated against an exact warm near-grey
  /// ground that Material's tonal algorithm will not produce from any seed —
  /// and leaving surfaces derived puts the whole design at the mercy of the
  /// palette generator. The [ColorScheme] survives for stock M3 widgets only.
  ///
  /// Contrast is measured against each role's intended background: content
  /// roles against [mainSurface] over [ground].
  static const AppFinancialColors light = AppFinancialColors(
    // Ink, not accent. Modernist puts the primary action on a solid red fill;
    // in a ledger red must mean one thing only, so the primary action is ink
    // and red is spent exclusively on outflow.
    primaryAction: Color(0xFF201E1D), // 14.9:1
    // Deep teal, not green. This is the most important value in the redesign:
    // it moves the income/expense axis off the green–red pair that both
    // common dichromacies collapse, onto the blue–yellow channel they retain.
    income: Color(0xFF14555F), // 7.5:1
    expense: Color(0xFFAE1800), // 6.4:1 — the only red in the product
    // Achromatic on purpose: a transfer changes no total, so it earns no hue.
    transfer: Color(0xFF605D5D), // 5.8:1
    protectedMoney: Color(0xFF6E4A1F), // 7.1:1
    goalReserved: Color(0xFF2B5C8A), // 6.3:1
    certificatePrincipal: Color(0xFF4A3E70), // 8.5:1
    // Was #B8831A at 3.3:1 — below AA for text. A compliance fix, not taste.
    warning: Color(0xFF8A5A00), // 5.3:1
    // Deliberately not the income teal: success confirms a *write*, never a
    // value. The two were byte-identical before this phase.
    success: Color(0xFF0E5A44), // 7.3:1
    // Was identical to secondaryText, so an informational notice had no
    // visual identity at all.
    neutralInfo: Color(0xFF3D4A52), // 8.2:1
    mainSurface: Color(0xFFFFFFFF),
    secondarySurface: Color(0xFFEAE9E9),
    divider: Color(0xFFC3BFBE), // 1 px hairline within a group
    primaryText: Color(0xFF201E1D), // 14.9:1
    secondaryText: Color(0xFF575351), // 6.8:1
    // Opaque now. As an alpha it composited unpredictably over the hatched
    // held region. Below AA by design, which is why a disabled control always
    // carries a reason line in secondaryText.
    disabled: Color(0xFF9B9797), // 2.6:1 — non-text only
    ground: Color(0xFFF3F2F2),
    recessedSurface: Color(0xFFDEDBDA),
    focusRing: Color(0xFFEC3013), // 3.9:1 vs ground — non-text
  );

  /// Dark palette. See [light]; every role is a literal for the same reasons.
  ///
  /// Contrast is measured against the dark [mainSurface].
  static const AppFinancialColors dark = AppFinancialColors(
    primaryAction: Color(0xFFF0EDEB), // 15.3:1
    income: Color(0xFF5FB8B0), // 7.6:1
    expense: Color(0xFFFF9783), // 8.5:1
    transfer: Color(0xFFB0ABA9), // 7.9:1
    // Real fix: the old #D7CCC8 was a near-grey that read as disabled rather
    // than protected.
    protectedMoney: Color(0xFFD6A85C), // 8.2:1
    // Was #80CBC4, a teal that collides with the new income role.
    goalReserved: Color(0xFF7FAFDD), // 7.7:1
    certificatePrincipal: Color(0xFFA99BD6), // 7.1:1
    warning: Color(0xFFE0AE4A), // 8.8:1
    success: Color(0xFF63BC94), // 7.8:1
    neutralInfo: Color(0xFF9DB2BE), // 8.1:1
    mainSurface: Color(0xFF221F1E),
    // The old light/dark asymmetry — light derived from surfaceContainerLow,
    // dark from …High — disappears here.
    secondarySurface: Color(0xFF2C2928),
    divider: Color(0xFF4A4645),
    primaryText: Color(0xFFF0EDEB), // 15.3:1
    secondaryText: Color(0xFFA8A3A0), // 7.1:1
    disabled: Color(0xFF6B6766), // 2.6:1 — non-text only
    ground: Color(0xFF181716),
    recessedSurface: Color(0xFF3A3635),
    focusRing: Color(0xFFFF563C), // 5.2:1 vs dark ground — non-text
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
    Color? ground,
    Color? recessedSurface,
    Color? focusRing,
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
      ground: ground ?? this.ground,
      recessedSurface: recessedSurface ?? this.recessedSurface,
      focusRing: focusRing ?? this.focusRing,
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
      ground: Color.lerp(ground, other.ground, t)!,
      recessedSurface: Color.lerp(recessedSurface, other.recessedSurface, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
    );
  }
}

/// Latin family. Bundled as a local asset — see `assets/fonts/OFL.txt`.
const String latinFontFamily = 'Archivo';

/// Arabic family. A naskh-grotesque chosen for its lining tabular numerals,
/// and because it shares an x-height with [latinFontFamily] — so a mixed
/// Arabic-with-Latin-numerals run does not visibly change font mid-line.
const String arabicFontFamily = 'IBM Plex Sans Arabic';

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

  /// Builds the eleven semantic text roles for [scheme] and [locale].
  ///
  /// Latin and Arabic take genuinely different metrics per role, not the same
  /// metrics in a different font, which is why the factory has to know the
  /// script. Two differences run through every role:
  ///
  ///   * **Arabic line height is +0.30 across the board.** Diacritics and
  ///     descending joins need the air; without it the script sets tight and
  ///     ascenders collide with the line above.
  ///   * **Arabic takes no letter-spacing, ever.** Tracking breaks the joins
  ///     between characters, which is a legibility bug rather than a style
  ///     choice.
  ///
  /// Sizes diverge too, and not always in the same direction — [supportingMeta]
  /// is the one role where Arabic is *larger*, because 11 px Arabic loses tooth
  /// detail. [cardTitle] and [buttonLabel] stay a weight lighter in Arabic
  /// because Plex Arabic's 700 is optically heavier than Archivo's 800 at the
  /// same optical size.
  factory AppTextRoles.forLocale(ColorScheme scheme, Locale locale) {
    // Text colour comes from the literal palette, not from the scheme. The
    // scheme is neutrally seeded for stock M3 widgets, so deriving text colour
    // from it would quietly de-calibrate every role against the exact ground
    // the design is measured on.
    final colors = scheme.brightness == Brightness.light
        ? AppFinancialColors.light
        : AppFinancialColors.dark;
    final on = colors.primaryText;
    final muted = colors.secondaryText;

    final isArabic = locale.languageCode == 'ar';
    final family = isArabic ? arabicFontFamily : latinFontFamily;
    // The fallback matters more than it looks: the app's most common string is
    // Arabic with Latin numerals and an ISO currency code. Naming the other
    // family as fallback keeps a mixed run from dropping to a system font
    // mid-line, which would change metrics inside a single amount.
    final fallback = isArabic
        ? const [latinFontFamily]
        : const [arabicFontFamily];

    // Amounts always render tabular *and* lining, so a column of figures
    // aligns on the decimal at every size and no digit sits below the baseline.
    const figures = [FontFeature.tabularFigures(), FontFeature.liningFigures()];

    TextStyle role({
      required double size,
      required FontWeight weight,
      required double height,
      Color? color,
      double? letterSpacing,
      List<FontFeature>? fontFeatures,
    }) => TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      // Arabic never takes tracking; the Latin value is ignored for it.
      letterSpacing: isArabic ? 0 : letterSpacing,
      fontFeatures: fontFeatures,
      color: color ?? on,
    );

    return AppTextRoles(
      displayBalance: role(
        size: isArabic ? 38 : 40,
        weight: isArabic ? FontWeight.w700 : FontWeight.w800,
        height: isArabic ? 1.25 : 1.05,
        letterSpacing: -0.8, // −0.02em at 40
        fontFeatures: figures,
      ),
      screenTitle: role(
        size: isArabic ? 24 : 25,
        weight: isArabic ? FontWeight.w700 : FontWeight.w800,
        height: isArabic ? 1.40 : 1.15,
        letterSpacing: -0.375, // −0.015em at 25
      ),
      // Deliberately small: the section heading is a tracked label above a
      // 2 px rule, and the rule carries the hierarchy, not the type size.
      sectionTitle: role(
        size: 13,
        weight: isArabic ? FontWeight.w700 : FontWeight.w800,
        height: isArabic ? 1.45 : 1.20,
        letterSpacing: 1.04, // +0.08em at 13
      ),
      cardTitle: role(
        size: isArabic ? 16 : 17,
        weight: isArabic ? FontWeight.w600 : FontWeight.w800,
        height: isArabic ? 1.45 : 1.20,
        letterSpacing: -0.17, // −0.01em at 17
      ),
      body: role(
        size: 15,
        weight: FontWeight.w400,
        height: isArabic ? 1.85 : 1.55,
      ),
      financialAmount: role(
        size: 17,
        weight: FontWeight.w600,
        height: isArabic ? 1.30 : 1.20,
        fontFeatures: figures,
      ),
      // The only role where Arabic is larger than Latin.
      supportingMeta: role(
        size: isArabic ? 12 : 11,
        weight: FontWeight.w400,
        height: isArabic ? 1.60 : 1.35,
        letterSpacing: 0.22, // +0.02em at 11
        color: muted,
      ),
      // A label above a field must not compete with the value inside it.
      formLabel: role(
        size: 12,
        weight: FontWeight.w400,
        height: isArabic ? 1.55 : 1.30,
      ),
      buttonLabel: role(
        size: 14,
        weight: isArabic ? FontWeight.w600 : FontWeight.w800,
        height: isArabic ? 1.30 : 1.20,
      ),
      statusLabel: role(
        size: 11,
        weight: FontWeight.w600,
        height: isArabic ? 1.45 : 1.20,
        letterSpacing: 0.22, // +0.02em at 11
      ),
      reportValue: role(
        size: 20,
        weight: isArabic ? FontWeight.w700 : FontWeight.w800,
        height: isArabic ? 1.30 : 1.15,
        letterSpacing: -0.2, // −0.01em at 20
        fontFeatures: figures,
      ),
    );
  }

  /// Locale-unaware delegate that assumes English.
  ///
  /// Retained so no call site breaks on the day [forLocale] lands. Once every
  /// caller passes a locale this is deleted — it cannot express Arabic
  /// metrics, so anything still calling it after phase 3 is a bug.
  @Deprecated('Use AppTextRoles.forLocale(scheme, locale) instead.')
  factory AppTextRoles.fromScheme(ColorScheme scheme) =>
      AppTextRoles.forLocale(scheme, const Locale('en'));

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
    return Theme.of(this).brightness == Brightness.light
        ? AppFinancialColors.light
        : AppFinancialColors.dark;
  }

  AppTextRoles get textRoles {
    final ext = Theme.of(this).extension<AppTextRoles>();
    if (ext != null) return ext;
    return AppTextRoles.forLocale(
      Theme.of(this).colorScheme,
      Localizations.maybeLocaleOf(this) ?? const Locale('en'),
    );
  }
}
