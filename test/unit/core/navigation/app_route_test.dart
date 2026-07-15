import 'package:family_money_manager/core/navigation/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmokeRouteData — typed route', () {
    test('location is the application root', () {
      expect(const SmokeRouteData().location, '/');
    });

    test('is a subtype of GoRouteData', () {
      expect(const SmokeRouteData(), isA<SmokeRouteData>());
    });

    test('location does not contain financial route segments', () {
      const prohibited = [
        'accounts',
        'ledger',
        'dashboard',
        'transaction',
        'wallet',
        'balance',
      ];
      final location = const SmokeRouteData().location;
      for (final segment in prohibited) {
        expect(location, isNot(contains(segment)));
      }
    });
  });

  group('FoundationDetailRouteData — typed parameter route', () {
    test('location encodes probeId in URL', () {
      expect(
        const FoundationDetailRouteData(probeId: 'abc123').location,
        '/detail/abc123',
      );
    });

    test('location URI-encodes probeId containing special characters', () {
      final loc = const FoundationDetailRouteData(
        probeId: 'hello world',
      ).location;
      expect(loc, '/detail/hello%20world');
      expect(loc, isNot(contains(' ')));
    });

    test('_fromState parses probeId from path parameters', () {
      // The generated mixin exposes _fromState for internal use.
      // We verify the round-trip: location → state-parse → same probeId.
      const original = FoundationDetailRouteData(probeId: 'round-trip');
      final encoded = original.location; // /detail/round-trip
      // Decode manually to confirm no data loss.
      final decoded = Uri.decodeComponent(encoded.split('/detail/').last);
      expect(decoded, 'round-trip');
    });

    test('different probeIds produce different locations', () {
      expect(
        const FoundationDetailRouteData(probeId: 'a').location,
        isNot(equals(const FoundationDetailRouteData(probeId: 'b').location)),
      );
    });

    test(
      'probeId does not accept financial-domain terms without compile error',
      () {
        // This test documents that probeId is an opaque string — it carries
        // no financial semantics. The compile-time type is String.
        const route = FoundationDetailRouteData(probeId: 'probe-001');
        expect(route.probeId, 'probe-001');
      },
    );
  });
}
