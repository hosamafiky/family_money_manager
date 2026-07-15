import 'package:family_money_manager/core/navigation/app_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoute — typed routes', () {
    group('SmokeRoute', () {
      test('path is the application root', () {
        expect(const SmokeRoute().path, '/');
      });

      test('two instances with identical paths are equal via value', () {
        // SmokeRoute is a const final class; instances share the same path.
        expect(const SmokeRoute().path, const SmokeRoute().path);
      });

      test('is a subtype of AppRoute', () {
        expect(const SmokeRoute(), isA<AppRoute>());
      });

      test('path does not contain financial route segments', () {
        const prohibited = [
          'accounts',
          'ledger',
          'dashboard',
          'transaction',
          'wallet',
          'balance',
        ];
        final path = const SmokeRoute().path;
        for (final segment in prohibited) {
          expect(path, isNot(contains(segment)));
        }
      });
    });
  });
}
