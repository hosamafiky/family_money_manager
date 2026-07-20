import 'package:family_money_manager/features/certificates/domain/certificate.dart';

/// Outcome of a certificate financial write.
enum CertificateWriteResult { created, alreadyExists }

/// Fail-after hooks for rollback matrix tests (Phase 6A.1).
///
/// Points map to transactional boundaries on create / profit / redeem /
/// controlled-reversal write paths.
enum CertificateFailAfter {
  none,

  /// After idempotency lookup when no prior identity was found.
  idempotencyLookup,

  accountInsert,
  certificateInsert,
  revisionInsert,
  operationInsert,
  firstLedgerEntry,
  secondLedgerEntry,
  operationContext,

  /// Create path: after `created` event insert.
  createdEvent,

  /// Create path: after `purchased` event insert.
  purchasedEvent,

  /// Profit / redeem / generic event insert boundary.
  eventInsert,

  lifecycleUpdate,

  /// Redeem with optional maturity profit — mid-profit boundaries.
  profitOperationInsert,
  profitLedgerEntry,
  profitContext,
  profitEventInsert,

  preCommit,
}

final class CertificateInjectedFailure implements Exception {
  const CertificateInjectedFailure(this.after);
  final CertificateFailAfter after;

  @override
  String toString() => 'CertificateInjectedFailure($after)';
}

/// Params for optional maturity profit recorded inside redemption.
final class CertificateMaturityProfitParams {
  const CertificateMaturityProfitParams({
    required this.operationId,
    required this.idempotencyKey,
    required this.destinationAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.description,
  });

  final String operationId;
  final String idempotencyKey;
  final String destinationAccountId;
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String description;
}

/// Payload fingerprint builder shared by use cases and repository.
String buildCertificateIdempotencyPayload({
  required String householdId,
  required String institutionName,
  required String? reference,
  required String currencyCode,
  required int principalMinorUnits,
  required String startDate,
  required String maturityDate,
  required int? annualRateBps,
  required CertificateProfitFrequency? profitFrequency,
  required String sourceAccountId,
}) {
  return 'hh=$householdId'
      '|inst=${institutionName.trim()}'
      '|ref=${reference?.trim() ?? ''}'
      '|cur=$currencyCode'
      '|prin=$principalMinorUnits'
      '|start=$startDate'
      '|mat=$maturityDate'
      '|rate=${annualRateBps ?? ''}'
      '|freq=${profitFrequency?.code ?? ''}'
      '|src=$sourceAccountId';
}
