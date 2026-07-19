import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/certificates/data/certificate_write_boundary.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';

/// Repository for savings certificates (Phase 6A).
///
/// No Drift types in signatures. Principal is never stored — derive via
/// [getPrincipalBalance]. Revisions and events are append-only.
abstract interface class CertificateRepository {
  /// Atomically creates certificate account + row + revision + purchase transfer.
  ///
  /// Requires [purchase] with positive principal. No unfunded certificates.
  Future<AppResult<SavingsCertificate>> createCertificate({
    required SavingsCertificate certificate,
    required CertificateRevision initialRevision,
    required FinancialAccount certificateAccount,
    required CertificatePurchaseFunding purchase,
  });

  Future<AppResult<SavingsCertificate?>> findById(String certificateId);

  Future<AppResult<List<SavingsCertificate>>> listCertificates({
    required String householdId,
    bool includeArchived = false,
  });

  Future<AppResult<int>> getPrincipalBalance({
    required String certificateAccountId,
    required String householdId,
  });

  Future<AppResult<List<CertificateRevision>>> getRevisions(
    String certificateId,
  );

  Future<AppResult<List<CertificateEvent>>> getEvents(String certificateId);

  /// Append a revision for allowed metadata fields only.
  Future<AppResult<CertificateRevision>> reviseDefinition({
    required CertificateRevision revision,
  });

  /// Atomic profit income + certificate event.
  Future<AppResult<CertificateProfitReceipt>> recordProfit({
    required String certificateId,
    required String householdId,
    required String operationId,
    required String eventId,
    required String idempotencyKey,
    required String destinationAccountId,
    required int amountMinorUnits,
    required String currencyCode,
    required String effectiveDate,
    required String createdBy,
    String? note,
  });

  /// Full maturity redemption + optional profit in one transaction.
  ///
  /// [principalMinorUnits] must equal the full remaining certificate balance.
  Future<AppResult<CertificateRedemptionSummary>> redeem({
    required String certificateId,
    required String householdId,
    required String principalOperationId,
    required String eventId,
    required String idempotencyKey,
    required String destinationAccountId,
    required int principalMinorUnits,
    required String effectiveDate,
    required String createdBy,
    required String todayLocal,
    CertificateMaturityProfitParams? maturityProfit,
    String? note,
  });

  Future<AppResult<void>> archive({
    required String certificateId,
    required String householdId,
    String? idempotencyKey,
  });

  Future<AppResult<void>> restore({
    required String certificateId,
    required String householdId,
    String? idempotencyKey,
  });

  /// Reverse purchase while active and before any profit/redemption.
  Future<AppResult<void>> reversePurchase({
    required String certificateId,
    required String householdId,
    required String reversalOperationId,
    required String idempotencyKey,
    required String effectiveDate,
    required String createdBy,
    String? reason,
  });

  /// Reverse a prior profit income + append profitReversed event.
  Future<AppResult<void>> reverseProfit({
    required String certificateId,
    required String householdId,
    required String originalIncomeOperationId,
    required String reversalOperationId,
    required String idempotencyKey,
    required String effectiveDate,
    required String createdBy,
    String? reason,
  });

  /// Explicitly rejected in V1 — redemption reversal is deferred.
  Future<AppResult<void>> reverseRedemption({
    required String certificateId,
    required String householdId,
  });
}
