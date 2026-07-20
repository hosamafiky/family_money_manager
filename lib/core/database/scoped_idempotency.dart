/// Shared scoped-idempotency primitives for financial writers.
///
/// Feature modules own payload **builders** and persistence layout.
/// This library standardizes compare / replay / conflict decisions so
/// ledger, goals, and certificates do not drift.
library;

/// Outcome of a scoped identity + fingerprint check before a fresh insert.
enum ScopedIdempotencyDecision {
  /// No prior row — caller may proceed with the write.
  proceed,

  /// Same identity with an equivalent fingerprint — safe replay.
  replay,

  /// Same identity with a mismatched fingerprint — do not write again.
  conflict,
}

/// Field fingerprint used to decide equivalence for operations-table rows.
final class OperationIdempotencyFingerprint {
  const OperationIdempotencyFingerprint({
    required this.type,
    required this.amountMinorUnits,
    required this.currencyCode,
    this.sourceAccountId,
    this.destinationAccountId,
  });

  final String type;
  final int amountMinorUnits;
  final String currencyCode;
  final String? sourceAccountId;
  final String? destinationAccountId;

  bool matchesRow({
    required String type,
    required int amountMinorUnits,
    required String? currencyCode,
    required String? sourceAccountId,
    required String? destinationAccountId,
  }) {
    return this.type == type &&
        this.amountMinorUnits == amountMinorUnits &&
        this.currencyCode == currencyCode &&
        this.sourceAccountId == sourceAccountId &&
        this.destinationAccountId == destinationAccountId;
  }
}

/// Compares an incoming string fingerprint to a stored one (exact match).
ScopedIdempotencyDecision decideStringFingerprint({
  required String incoming,
  required String stored,
}) {
  return incoming == stored
      ? ScopedIdempotencyDecision.replay
      : ScopedIdempotencyDecision.conflict;
}

/// Compares operation field fingerprints when a scoped key already exists.
ScopedIdempotencyDecision decideOperationFingerprint({
  required OperationIdempotencyFingerprint incoming,
  required String existingType,
  required int existingAmountMinorUnits,
  required String? existingCurrencyCode,
  required String? existingSourceAccountId,
  required String? existingDestinationAccountId,
}) {
  final equivalent = incoming.matchesRow(
    type: existingType,
    amountMinorUnits: existingAmountMinorUnits,
    currencyCode: existingCurrencyCode,
    sourceAccountId: existingSourceAccountId,
    destinationAccountId: existingDestinationAccountId,
  );
  return equivalent
      ? ScopedIdempotencyDecision.replay
      : ScopedIdempotencyDecision.conflict;
}
