import 'package:family_money_manager/app/app_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    group('production config', () {
      test('validates without throwing', () {
        expect(() => AppConfig.production.validate(), returnsNormally);
      });

      test('has expected package name', () {
        expect(AppConfig.production.packageName, 'com.familymoney.manager');
      });

      test('default locale is Arabic Egypt', () {
        expect(AppConfig.production.defaultLocale, const Locale('ar', 'EG'));
      });

      test('currency code is EGP', () {
        expect(AppConfig.production.currencyCode, 'EGP');
      });

      test('isProduction is true', () {
        expect(AppConfig.production.isProduction, isTrue);
      });
    });

    group('development config', () {
      test('validates without throwing', () {
        expect(() => AppConfig.development.validate(), returnsNormally);
      });

      test('isProduction is false', () {
        expect(AppConfig.development.isProduction, isFalse);
      });
    });

    group('validate() rejects invalid configs', () {
      test('throws StateError when appName is empty', () {
        const invalid = AppConfig(
          appName: '',
          appNameAr: 'اسم',
          packageName: 'com.test.app',
          currencyCode: 'EGP',
          defaultLocale: Locale('ar'),
          isProduction: false,
        );
        expect(invalid.validate, throwsStateError);
      });

      test('throws StateError when currencyCode is empty', () {
        const invalid = AppConfig(
          appName: 'Test',
          appNameAr: 'اختبار',
          packageName: 'com.test.app',
          currencyCode: '',
          defaultLocale: Locale('ar'),
          isProduction: false,
        );
        expect(invalid.validate, throwsStateError);
      });

      test('throws StateError when packageName is empty', () {
        const invalid = AppConfig(
          appName: 'Test',
          appNameAr: 'اختبار',
          packageName: '',
          currencyCode: 'EGP',
          defaultLocale: Locale('ar'),
          isProduction: false,
        );
        expect(invalid.validate, throwsStateError);
      });
    });
  });
}
