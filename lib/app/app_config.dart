import 'package:flutter/widgets.dart';

/// Compile-time configuration for the application.
///
/// Instances are constant so they can be embedded in [ProviderScope] overrides
/// during testing without requiring Flutter bindings.
///
/// ## What belongs here
/// Non-secret compile-time constants: display name, currency, locale defaults.
///
/// ## What does NOT belong here
/// API keys, Firebase credentials, encryption keys, or AI secrets. These must
/// never be embedded in the mobile application binary.
@immutable
final class AppConfig {
  const AppConfig({
    required this.appName,
    required this.appNameAr,
    required this.packageName,
    required this.currencyCode,
    required this.defaultLocale,
    required this.isProduction,
  });

  static const AppConfig production = AppConfig(
    appName: 'Family Money Manager',
    appNameAr: 'مدير مالية الأسرة',
    packageName: 'com.familymoney.manager',
    currencyCode: 'EGP',
    defaultLocale: Locale('ar', 'EG'),
    isProduction: true,
  );

  static const AppConfig staging = AppConfig(
    appName: 'Family Money Manager (Staging)',
    appNameAr: 'مدير مالية الأسرة (تجريبي)',
    packageName: 'com.familymoney.manager',
    currencyCode: 'EGP',
    defaultLocale: Locale('ar', 'EG'),
    isProduction: false,
  );

  static const AppConfig development = AppConfig(
    appName: 'Family Money Manager (Dev)',
    appNameAr: 'مدير مالية الأسرة (تطوير)',
    packageName: 'com.familymoney.manager',
    currencyCode: 'EGP',
    defaultLocale: Locale('ar', 'EG'),
    isProduction: false,
  );

  final String appName;
  final String appNameAr;

  /// Fully qualified reverse-domain package name.
  final String packageName;

  /// ISO 4217 currency code for the default household currency.
  final String currencyCode;

  /// The locale used on first launch before the user changes it.
  final Locale defaultLocale;

  final bool isProduction;

  /// Throws [StateError] if any required field is empty or invalid.
  ///
  /// Called during application startup so misconfiguration fails early
  /// with a clear message instead of a cryptic runtime error.
  void validate() {
    if (appName.isEmpty) {
      throw StateError('AppConfig: appName must not be empty');
    }
    if (appNameAr.isEmpty) {
      throw StateError('AppConfig: appNameAr must not be empty');
    }
    if (packageName.isEmpty) {
      throw StateError('AppConfig: packageName must not be empty');
    }
    if (currencyCode.isEmpty) {
      throw StateError('AppConfig: currencyCode must not be empty');
    }
  }
}
