import 'package:flutter/material.dart';

/// Centralised design tokens and [ThemeData] factories.
///
/// All visual constants (colours, spacing, radii, text styles) must originate
/// from this file. Feature widgets must not hard-code color literals or font
/// sizes directly.
abstract final class AppTheme {
  // ─── Brand colours ─────────────────────────────────────────────────────

  static const Color _seedColor = Color(0xFF1A6B3C);
  static const Color _errorColor = Color(0xFFBA1A1A);

  // ─── Spacing tokens (8-pt grid) ────────────────────────────────────────

  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // ─── Touch targets ─────────────────────────────────────────────────────

  /// Minimum touch-target height required for accessibility.
  static const double minTouchTarget = 48.0;

  // ─── Border radii ──────────────────────────────────────────────────────

  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // ─── ThemeData factories ────────────────────────────────────────────────

  static ThemeData light() => _buildTheme(brightness: Brightness.light);
  static ThemeData dark() => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      error: _errorColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(colorScheme),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: space16, vertical: space12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMedium)),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: scheme.onSurface),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: scheme.onSurface),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: scheme.onSurface),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: scheme.onSurface),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface),
    );
  }
}
