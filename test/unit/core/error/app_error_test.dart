import 'package:family_money_manager/core/error/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppError', () {
    group('localizationKey', () {
      test('NetworkError returns non-empty key', () {
        expect(const NetworkError().localizationKey, isNotEmpty);
      });

      test('AuthError returns non-empty key', () {
        expect(const AuthError().localizationKey, isNotEmpty);
      });

      test('StorageError returns non-empty key', () {
        expect(const StorageError().localizationKey, isNotEmpty);
      });

      test('UnknownError returns non-empty key', () {
        expect(const UnknownError().localizationKey, isNotEmpty);
      });

      test('NetworkError key is errorNetwork', () {
        expect(const NetworkError().localizationKey, 'errorNetwork');
      });
    });

    group('resolveErrorMessage', () {
      test('calls localizedMessage with the correct key', () {
        const error = AuthError();
        String? capturedKey;

        resolveErrorMessage(
          error,
          localizedMessage: (key) {
            capturedKey = key;
            return 'localized $key';
          },
        );

        expect(capturedKey, 'errorAuth');
      });

      test('returns the string provided by localizedMessage', () {
        const error = UnknownError();

        final result = resolveErrorMessage(
          error,
          localizedMessage: (key) => 'translated:$key',
        );

        expect(result, 'translated:errorUnknown');
      });
    });
  });
}
