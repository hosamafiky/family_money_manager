import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/tables/financial_accounts_table.dart';

/// Drift table for `savings_certificates` (Phase 6A).
///
/// A certificate pairs definition metadata with a dedicated `certificate`
/// financial account. Principal balance is NEVER stored here — it is
/// derived from the ledger on every read (FINANCIAL_MODEL §3).
///
/// MUTABILITY: lifecycle, redeemed_at, archived_at may change via typed
/// workflows. Household, currency, account link, original principal, and
/// contractual dates are immutable after creation.
///
/// IDEMPOTENCY: (household_id, idempotency_key) must be unique.
@DataClassName('DbSavingsCertificate')
class SavingsCertificatesTable extends Table {
  TextColumn get id => text()();

  TextColumn get householdId => text()();

  /// FK to financial_accounts.id — dedicated certificate account (1:1).
  TextColumn get certificateAccountId =>
      text().references(FinancialAccounts, #id)();

  /// ISO 4217 currency code. Immutable.
  TextColumn get currencyCode => text()();

  /// Original purchased principal in minor units. Immutable.
  IntColumn get originalPrincipalMinorUnits => integer()();

  /// Inclusive term start `yyyy-MM-dd`.
  TextColumn get startDate => text()();

  /// Maturity date `yyyy-MM-dd`.
  TextColumn get maturityDate => text()();

  /// Persisted lifecycle only: 'active', 'redeemed', 'archived'.
  TextColumn get lifecycle => text()();

  TextColumn get idempotencyKey => text()();

  TextColumn get idempotencyPayload => text()();

  TextColumn get createdAt => text()();

  TextColumn get redeemedAt => text().nullable()();

  TextColumn get archivedAt => text().nullable()();

  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'savings_certificates';
}

/// Append-only revision of certificate display / rate metadata.
@DataClassName('DbCertificateRevision')
class CertificateRevisionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get certificateId =>
      text().references(SavingsCertificatesTable, #id)();
  TextColumn get householdId => text()();
  TextColumn get institutionName => text()();
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Optional annual rate in basis points.
  IntColumn get annualRateBps => integer().nullable()();

  /// Optional frequency code (see CertificateProfitFrequency).
  TextColumn get profitFrequencyCode => text().nullable()();

  TextColumn get createdAt => text()();
  TextColumn get revisionReason => text()();

  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'certificate_revisions';
}

/// Append-only certificate event log (purchase, profit, redemption, etc.).
@DataClassName('DbCertificateEvent')
class CertificateEventsTable extends Table {
  TextColumn get id => text()();
  TextColumn get certificateId =>
      text().references(SavingsCertificatesTable, #id)();
  TextColumn get householdId => text()();

  /// See CertificateEventType.code.
  TextColumn get eventType => text()();

  /// Linked ledger operation for financial events.
  TextColumn get relatedOperationId => text().nullable()();

  IntColumn get amountMinorUnits => integer().nullable()();
  TextColumn get currencyCode => text().nullable()();

  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get payloadFingerprint => text().nullable()();
  TextColumn get note => text().nullable()();

  TextColumn get effectiveAt => text()();
  TextColumn get createdAt => text()();

  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'certificate_events';
}
