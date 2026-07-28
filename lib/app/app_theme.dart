import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// Centralised design tokens and [ThemeData] factories.
///
/// Visual constants originate here or via [AppFinancialColors] /
/// [AppTextRoles]. Feature widgets must not hard-code brand colors, radii,
/// or elevations except for rare local semantic needs.
abstract final class AppTheme {
  /// Seed for stock Material widgets only.
  ///
  /// Every role the design cares about is now a literal in
  /// [AppFinancialColors]. This seed exists so that M3 components the app has
  /// not restyled still resolve a coherent [ColorScheme] — and it is ink, so
  /// what they resolve is neutral and cannot introduce a hue the design system
  /// does not contain.
  static const Color _neutralSeedColor = Color(0xFF201E1D);

  /// Matches the expense role deliberately: expense is the only red in the
  /// product, and a stock widget's error state must not introduce a second.
  static const Color _errorColor = Color(0xFFAE1800);

  // ─── Spacing ───────────────────────────────────────────────────────────

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;

  /// A tap target, not a spacing step — which is why it survives the deletion
  /// of the off-scale `space48` constant it used to share a value with.
  static const double minTouchTarget = 48.0;

  // ─── Shape roles ───────────────────────────────────────────────────────
  //
  // Zero everywhere. Elevation and radius are replaced by rules and tonal
  // fill: a card is a surface plus a 1 px hairline, and a region boundary is
  // a 2 px ink rule. Role names are kept so call sites keep reading as
  // intent rather than as a number.

  static const double radiusBadge = 0.0;
  static const double radiusChip = 0.0;
  static const double radiusInput = 0.0;
  static const double radiusButton = 0.0;
  static const double radiusCard = 0.0;
  static const double radiusDialog = 0.0;

  /// The only non-zero radius in the product.
  ///
  /// Not decoration: a perfectly square sheet edge over a square scaffold
  /// reads as a broken layout rather than as a layer.
  static const double radiusSheet = 2.0;

  /// Width of a rule that separates two *regions*, as opposed to two rows.
  ///
  /// This is the design's principal hierarchy device — it does the work M3
  /// assigns to elevation. Rows within a group are separated by a 1 px
  /// hairline in `divider`; regions are separated by ink.
  static const double regionRuleWidth = 2.0;

  /// Legacy aliases, all resolving to 0. Kept because they are referenced.
  static const double radiusSmall = radiusBadge;
  static const double radiusMedium = radiusChip;
  static const double radiusLarge = radiusDialog;
  static const double radiusXLarge = radiusSheet;

  // ─── Motion ────────────────────────────────────────────────────────────

  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionStandard = Duration(milliseconds: 220);

  /// Route push/pop. Shortened from 320 ms: that is noticeably slow on the
  /// app's single most repeated transition.
  static const Duration motionEmphasized = Duration(milliseconds: 280);

  // ─── Content widths ────────────────────────────────────────────────────

  static const double formContentMaxWidth = 720.0;
  static const double listContentMaxWidth = 960.0;
  static const double railBreakpoint = 840.0;

  /// Builds the light theme for [locale].
  ///
  /// [locale] genuinely changes the result: Latin and Arabic take different
  /// metrics and different families per text role. [MaterialApp] therefore has
  /// to rebuild its theme when the language changes, which `App` does by
  /// watching the locale provider.
  ///
  /// The English default is a convenience for tests and tooling, not the
  /// product default — that is `ar_EG`, from `AppConfig`.
  static ThemeData light({Locale locale = const Locale('en')}) =>
      _buildTheme(brightness: Brightness.light, locale: locale);

  /// Builds the dark theme for [locale]. See [light].
  static ThemeData dark({Locale locale = const Locale('en')}) =>
      _buildTheme(brightness: Brightness.dark, locale: locale);

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Locale locale,
  }) {
    final financial = brightness == Brightness.light
        ? AppFinancialColors.light
        : AppFinancialColors.dark;

    // The seed fills in the long tail of M3 roles nothing in this app names.
    // Every role a stock widget can actually put on screen is then pinned to
    // the literal palette — otherwise an unrestyled Material widget would
    // render a tone the design system does not contain. Note that seeding
    // from ink is not by itself enough: M3's tonal algorithm derives a
    // chromatic primary from any seed, including a near-black one.
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _neutralSeedColor,
          error: _errorColor,
          brightness: brightness,
        ).copyWith(
          primary: financial.primaryAction,
          onPrimary: financial.mainSurface,
          surface: financial.mainSurface,
          onSurface: financial.primaryText,
          onSurfaceVariant: financial.secondaryText,
          surfaceContainerLowest: financial.mainSurface,
          surfaceContainerLow: financial.secondarySurface,
          surfaceContainer: financial.secondarySurface,
          surfaceContainerHigh: financial.secondarySurface,
          surfaceContainerHighest: financial.recessedSurface,
          outline: financial.divider,
          outlineVariant: financial.divider,
          error: financial.expense,
          onError: financial.mainSurface,
        );
    final textRoles = AppTextRoles.forLocale(colorScheme, locale);

    final isArabic = locale.languageCode == 'ar';

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Base family for anything that escapes the semantic roles — stock
      // widgets, and any Text that inherits rather than naming a role.
      fontFamily: isArabic ? arabicFontFamily : latinFontFamily,
      fontFamilyFallback: isArabic
          ? const [latinFontFamily]
          : const [arabicFontFamily],
      extensions: [financial, textRoles],
      textTheme: _buildTextTheme(colorScheme, textRoles),
      // The page is now its own surface, so a card is separable from it by
      // value alone rather than by radius and shadow.
      scaffoldBackgroundColor: financial.ground,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        // A pinned bar reveals a rule on scroll instead of gaining elevation.
        // The rule itself is drawn by the bar; what matters here is that no
        // shadow appears under it.
        scrolledUnderElevation: 0,
        backgroundColor: financial.ground,
        foregroundColor: financial.primaryText,
        // The bar title is deliberately *not* screenTitle. In the redesign
        // screenTitle sits in the body, flush to the leading margin, where it
        // has room; the bar carries a smaller single-line style that can be
        // ellipsised without losing information.
        titleTextStyle: textRoles.screenTitle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        // Fill moves secondarySurface → mainSurface, and the half-alpha
        // outline becomes a solid hairline: a card is a surface plus a rule.
        color: financial.mainSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: financial.divider),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: financial.mainSurface,
        indicatorColor: colorScheme.secondaryContainer,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(color: financial.secondaryText),
        labelType: NavigationRailLabelType.all,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, minTouchTarget),
          textStyle: textRoles.buttonLabel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, minTouchTarget),
          textStyle: textRoles.buttonLabel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, minTouchTarget),
          textStyle: textRoles.buttonLabel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, minTouchTarget),
          textStyle: textRoles.buttonLabel,
        ),
      ),
      // A field is a ruled row, not a rounded box. The focus indicator is a
      // 2 px ink bottom rule on the field; the offset focusRing that
      // accompanies it lives outside the control and so cannot be expressed
      // here — it is drawn by the field wrapper in a later phase.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: financial.secondarySurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space12,
        ),
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: financial.divider),
        ),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: financial.divider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(
            color: financial.primaryAction,
            width: regionRuleWidth,
          ),
        ),
        errorBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(
            color: financial.expense,
            width: regionRuleWidth,
          ),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(
            color: financial.expense,
            width: regionRuleWidth,
          ),
        ),
        disabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: financial.disabled),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusChip),
        ),
        side: BorderSide(color: financial.divider),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: financial.mainSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusDialog),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: financial.mainSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusSheet),
          ),
        ),
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(
        color: financial.divider,
        space: 1,
        thickness: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme, AppTextRoles roles) {
    return TextTheme(
      displayLarge: roles.displayBalance,
      headlineMedium: roles.screenTitle,
      titleLarge: roles.sectionTitle,
      titleMedium: roles.cardTitle,
      bodyLarge: roles.body,
      bodyMedium: roles.body.copyWith(fontSize: 14),
      bodySmall: roles.supportingMeta,
      labelLarge: roles.buttonLabel,
      labelMedium: roles.formLabel,
      labelSmall: roles.statusLabel,
    );
  }
}
