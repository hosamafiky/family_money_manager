import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// Centralised design tokens and [ThemeData] factories.
///
/// Visual constants originate here or via [AppFinancialColors] /
/// [AppTextRoles]. Feature widgets must not hard-code brand colors, radii,
/// or elevations except for rare local semantic needs.
abstract final class AppTheme {
  static const Color _seedColor = Color(0xFF1A6B3C);
  static const Color _errorColor = Color(0xFFBA1A1A);

  // ─── Spacing ───────────────────────────────────────────────────────────

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;

  /// @Deprecated — prefer [space4]; retained for call-site compatibility.
  static const double space2 = 2.0;

  /// @Deprecated — prefer [space40]; retained for call-site compatibility.
  static const double space48 = 48.0;

  static const double minTouchTarget = 48.0;

  // ─── Shape roles ───────────────────────────────────────────────────────

  static const double radiusBadge = 4.0;
  static const double radiusChip = 8.0;
  static const double radiusInput = 10.0;
  static const double radiusButton = 10.0;
  static const double radiusCard = 12.0;
  static const double radiusDialog = 16.0;
  static const double radiusSheet = 20.0;

  /// Legacy aliases.
  static const double radiusSmall = radiusBadge;
  static const double radiusMedium = radiusChip;
  static const double radiusLarge = radiusDialog;
  static const double radiusXLarge = radiusSheet;

  // ─── Motion ────────────────────────────────────────────────────────────

  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionStandard = Duration(milliseconds: 220);
  static const Duration motionEmphasized = Duration(milliseconds: 320);

  // ─── Content widths ────────────────────────────────────────────────────

  static const double formContentMaxWidth = 720.0;
  static const double listContentMaxWidth = 960.0;
  static const double railBreakpoint = 840.0;

  static ThemeData light() => _buildTheme(brightness: Brightness.light);
  static ThemeData dark() => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      error: _errorColor,
      brightness: brightness,
    );
    final financial = brightness == Brightness.light
        ? AppFinancialColors.light(colorScheme)
        : AppFinancialColors.dark(colorScheme);
    final textRoles = AppTextRoles.fromScheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [financial, textRoles],
      textTheme: _buildTextTheme(colorScheme, textRoles),
      scaffoldBackgroundColor: financial.mainSurface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: financial.mainSurface,
        foregroundColor: financial.primaryText,
        titleTextStyle: textRoles.screenTitle,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: financial.secondarySurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: financial.divider.withValues(alpha: 0.5)),
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: financial.secondarySurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: financial.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: financial.primaryAction, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusChip),
        ),
        side: BorderSide(color: financial.divider),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusDialog),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusSheet),
          ),
        ),
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(color: financial.divider, space: 1),
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
