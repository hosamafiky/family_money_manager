import 'package:family_money_manager/core/database/scoped_idempotency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decideStringFingerprint', () {
    test('matching fingerprints → replay', () {
      expect(
        decideStringFingerprint(incoming: 'a=1', stored: 'a=1'),
        ScopedIdempotencyDecision.replay,
      );
    });

    test('mismatched fingerprints → conflict', () {
      expect(
        decideStringFingerprint(incoming: 'a=1', stored: 'a=2'),
        ScopedIdempotencyDecision.conflict,
      );
    });
  });

  group('decideOperationFingerprint', () {
    const incoming = OperationIdempotencyFingerprint(
      type: 'transfer',
      amountMinorUnits: 1000,
      currencyCode: 'EGP',
      sourceAccountId: 'src',
      destinationAccountId: 'dst',
    );

    test('equivalent row → replay', () {
      expect(
        decideOperationFingerprint(
          incoming: incoming,
          existingType: 'transfer',
          existingAmountMinorUnits: 1000,
          existingCurrencyCode: 'EGP',
          existingSourceAccountId: 'src',
          existingDestinationAccountId: 'dst',
        ),
        ScopedIdempotencyDecision.replay,
      );
    });

    test('type mismatch → conflict', () {
      expect(
        decideOperationFingerprint(
          incoming: incoming,
          existingType: 'expense',
          existingAmountMinorUnits: 1000,
          existingCurrencyCode: 'EGP',
          existingSourceAccountId: 'src',
          existingDestinationAccountId: 'dst',
        ),
        ScopedIdempotencyDecision.conflict,
      );
    });

    test('null account asymmetry preserved', () {
      const income = OperationIdempotencyFingerprint(
        type: 'income',
        amountMinorUnits: 500,
        currencyCode: 'EGP',
        destinationAccountId: 'dst',
      );
      expect(
        decideOperationFingerprint(
          incoming: income,
          existingType: 'income',
          existingAmountMinorUnits: 500,
          existingCurrencyCode: 'EGP',
          existingSourceAccountId: null,
          existingDestinationAccountId: 'dst',
        ),
        ScopedIdempotencyDecision.replay,
      );
      expect(
        decideOperationFingerprint(
          incoming: income,
          existingType: 'income',
          existingAmountMinorUnits: 500,
          existingCurrencyCode: 'EGP',
          existingSourceAccountId: 'unexpected',
          existingDestinationAccountId: 'dst',
        ),
        ScopedIdempotencyDecision.conflict,
      );
    });
  });
}
