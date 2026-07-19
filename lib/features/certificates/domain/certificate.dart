/// Immutable domain types for Savings Certificates / fixed-term deposits.
///
/// No Flutter, Drift, or JSON dependencies.
/// All monetary values use integer minor units (e.g. cents/piastres).
///
/// Principal is a ledger-backed asset held in a dedicated certificate account.
/// Authoritative principal = derived ledger balance of [certificateAccountId].
/// This feature must NOT claim full household net worth.
library;

/// Stable client-generated identifier for a savings certificate.
typedef CertificateId = String;

/// Persisted lifecycle status of a savings certificate.
///
/// Only these three values are ever written to `savings_certificates.lifecycle`.
/// Term progress (`notStarted` / `activeTerm` / `matured` / `fullyRedeemed` /
/// `overdueRedemption`) is derived solely via [CertificateTermState] — never
/// persisted on the certificate row.
enum CertificateLifecycle { active, redeemed, archived }

/// Optional coupon / profit frequency metadata (stable codes, not labels).
enum CertificateProfitFrequency {
  monthly,
  quarterly,
  semiAnnual,
  annual,
  atMaturity,
  other;

  String get code => name;

  static CertificateProfitFrequency? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final v in CertificateProfitFrequency.values) {
      if (v.name == code) return v;
    }
    return CertificateProfitFrequency.other;
  }
}

/// Append-only certificate event categories.
enum CertificateEventType {
  created,
  purchased,
  profitReceived,
  redeemed,
  archived,
  restored,
  definitionRevised,
  purchaseReversed,
  profitReversed;

  String get code => name;

  static CertificateEventType fromCode(String code) {
    for (final v in CertificateEventType.values) {
      if (v.name == code) return v;
    }
    throw ArgumentError.value(code, 'code', 'Unknown CertificateEventType');
  }
}

/// Derived term / maturity state — never persisted.
///
/// Computed from clock + ledger principal balance + start/maturity dates.
enum CertificateTermState {
  /// Local today is before [SavingsCertificate.startDate].
  notStarted,

  /// Within [startDate, maturityDate) and principal still invested.
  activeTerm,

  /// Local today >= maturityDate and principal still invested.
  matured,

  /// Lifecycle is redeemed (or principal balance is zero after redemption).
  fullyRedeemed,

  /// Matured with principal still held (alias emphasis for overdue cash-out).
  overdueRedemption;

  /// Canonical derivation path.
  ///
  /// [todayLocal] is a calendar date `yyyy-MM-dd` in the device local timezone
  /// (same policy as dashboard/reports: no household timezone in V1).
  static CertificateTermState derive({
    required CertificateLifecycle lifecycle,
    required String startDate,
    required String maturityDate,
    required String todayLocal,
    required int principalBalanceMinorUnits,
  }) {
    if (lifecycle == CertificateLifecycle.redeemed) {
      return CertificateTermState.fullyRedeemed;
    }
    // Archived (e.g. purchase cancel) with zero principal.
    if (lifecycle == CertificateLifecycle.archived &&
        principalBalanceMinorUnits == 0) {
      return CertificateTermState.fullyRedeemed;
    }
    if (todayLocal.compareTo(startDate) < 0) {
      return CertificateTermState.notStarted;
    }
    if (todayLocal.compareTo(maturityDate) < 0) {
      return CertificateTermState.activeTerm;
    }
    // Maturity reached or passed.
    if (principalBalanceMinorUnits > 0) {
      if (todayLocal.compareTo(maturityDate) == 0) {
        return CertificateTermState.matured;
      }
      return CertificateTermState.overdueRedemption;
    }
    return CertificateTermState.fullyRedeemed;
  }
}

/// Mutable-definition snapshot (append-only revisions).
///
/// Revisable: institution display name, reference, note, rate, frequency.
/// Rejected for revision: household, currency, account, original principal,
/// start date after purchase, maturity after financial history (V1 rejects
/// contractual amendments entirely via use-case policy).
final class CertificateRevision {
  const CertificateRevision({
    required this.id,
    required this.certificateId,
    required this.householdId,
    required this.institutionName,
    required this.createdAt,
    required this.revisionReason,
    this.reference,
    this.note,
    this.annualRateBps,
    this.profitFrequency,
  });

  final String id;
  final CertificateId certificateId;
  final String householdId;

  /// Display name of the issuing institution (not a translated label).
  final String institutionName;

  /// Optional bank reference / certificate number.
  final String? reference;

  final String? note;

  /// Optional annual rate in basis points (100 bps = 1%). Metadata only.
  final int? annualRateBps;

  final CertificateProfitFrequency? profitFrequency;

  /// UTC ISO 8601 timestamp.
  final String createdAt;

  final String revisionReason;
}

/// Core savings-certificate entity.
///
/// Currency and original principal are immutable after creation.
/// Authoritative remaining principal is NEVER stored here — derive from
/// the linked certificate account ledger balance.
final class SavingsCertificate {
  const SavingsCertificate({
    required this.id,
    required this.householdId,
    required this.certificateAccountId,
    required this.currencyCode,
    required this.originalPrincipalMinorUnits,
    required this.startDate,
    required this.maturityDate,
    required this.lifecycle,
    required this.currentRevision,
    required this.createdAt,
    required this.idempotencyKey,
    required this.schemaVersion,
    this.redeemedAt,
    this.archivedAt,
  });

  final CertificateId id;
  final String householdId;

  /// The [financial_accounts.id] of the dedicated certificate account.
  final String certificateAccountId;

  /// ISO 4217 currency code. Immutable after creation.
  final String currencyCode;

  /// Original purchased principal in minor units. Immutable.
  final int originalPrincipalMinorUnits;

  /// Inclusive term start (`yyyy-MM-dd`).
  final String startDate;

  /// Maturity calendar date (`yyyy-MM-dd`).
  final String maturityDate;

  final CertificateLifecycle lifecycle;

  final CertificateRevision currentRevision;

  /// UTC ISO 8601 timestamp.
  final String createdAt;

  final String idempotencyKey;

  final int schemaVersion;

  final String? redeemedAt;
  final String? archivedAt;

  // ── Convenience delegators ───────────────────────────────────────────────

  String get institutionName => currentRevision.institutionName;
  String? get reference => currentRevision.reference;
  String? get note => currentRevision.note;
  int? get annualRateBps => currentRevision.annualRateBps;
  CertificateProfitFrequency? get profitFrequency =>
      currentRevision.profitFrequency;
}

/// Append-only certificate event linking optional ledger operations.
final class CertificateEvent {
  const CertificateEvent({
    required this.id,
    required this.certificateId,
    required this.householdId,
    required this.eventType,
    required this.effectiveAt,
    required this.createdAt,
    this.relatedOperationId,
    this.amountMinorUnits,
    this.currencyCode,
    this.idempotencyKey,
    this.payloadFingerprint,
    this.note,
  });

  final String id;
  final CertificateId certificateId;
  final String householdId;
  final CertificateEventType eventType;

  /// Linked ledger operation when the event is financial.
  final String? relatedOperationId;

  /// Event amount in minor units (principal or profit), when applicable.
  final int? amountMinorUnits;

  final String? currencyCode;

  final String? idempotencyKey;
  final String? payloadFingerprint;
  final String? note;

  /// Business-effective timestamp (ISO 8601 UTC).
  final String effectiveAt;

  /// Row-creation timestamp (ISO 8601 UTC).
  final String createdAt;
}

/// Manual profit receipt recorded against a certificate (ordinary income).
final class CertificateProfitReceipt {
  const CertificateProfitReceipt({
    required this.event,
    required this.incomeOperationId,
    required this.destinationAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
  });

  final CertificateEvent event;
  final String incomeOperationId;
  final String destinationAccountId;
  final int amountMinorUnits;
  final String currencyCode;
}

/// Result of a full maturity redemption (principal out, optional profit).
final class CertificateRedemptionSummary {
  const CertificateRedemptionSummary({
    required this.certificate,
    required this.principalMinorUnits,
    required this.profitMinorUnits,
    required this.destinationAccountId,
    required this.currencyCode,
    required this.principalOperationId,
    this.profitOperationId,
    this.event,
  });

  final SavingsCertificate certificate;

  /// Principal returned via transfer (NOT income).
  final int principalMinorUnits;

  /// Optional maturity profit recorded as ordinary income (may be zero).
  final int profitMinorUnits;

  final String destinationAccountId;
  final String currencyCode;
  final String principalOperationId;
  final String? profitOperationId;
  final CertificateEvent? event;

  /// Combined cash landing in the destination (principal + profit).
  /// Never classify this total as all income.
  int get combinedCashMinorUnits => principalMinorUnits + profitMinorUnits;
}

/// Parameters for required principal purchase during certificate creation.
final class CertificatePurchaseFunding {
  const CertificatePurchaseFunding({
    required this.operationId,
    required this.idempotencyKey,
    required this.sourceAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.effectiveDate,
    required this.description,
    required this.eventId,
    required this.eventCreatedAt,
  });

  final String operationId;
  final String idempotencyKey;
  final String sourceAccountId;
  final int amountMinorUnits;
  final String currencyCode;
  final String effectiveDate;
  final String description;
  final String eventId;
  final String eventCreatedAt;
}

/// Derived progress snapshot — never persisted.
final class CertificateProgress {
  const CertificateProgress({
    required this.certificate,
    required this.principalBalanceMinorUnits,
    required this.currencyCode,
    required this.termState,
    required this.events,
    required this.revisions,
    required this.todayLocal,
  });

  final SavingsCertificate certificate;

  /// Current ledger-derived principal of the certificate account.
  final int principalBalanceMinorUnits;

  final String currencyCode;
  final CertificateTermState termState;
  final List<CertificateEvent> events;
  final List<CertificateRevision> revisions;

  /// Local calendar date used for derivation (`yyyy-MM-dd`).
  final String todayLocal;

  int get originalPrincipalMinorUnits =>
      certificate.originalPrincipalMinorUnits;

  bool get isMaturedOrOverdue =>
      termState == CertificateTermState.matured ||
      termState == CertificateTermState.overdueRedemption;

  bool get canRedeem =>
      certificate.lifecycle == CertificateLifecycle.active &&
      isMaturedOrOverdue &&
      principalBalanceMinorUnits > 0;

  bool get canRecordProfit =>
      certificate.lifecycle != CertificateLifecycle.archived;
}
