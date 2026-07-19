import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:meta/meta.dart';

/// Immutable domain entity representing a financial account.
///
/// An account is a named location that holds money. Its balance is NEVER
/// stored here — it is derived from the ledger on every read (FINANCIAL_MODEL §3).
///
/// IMMUTABILITY RULES (FINANCIAL_MODEL §21 / Phase 3B.1):
///
/// | Field               | Enforcement                                      |
/// |---------------------|--------------------------------------------------|
/// | id                  | Always immutable (PK)                            |
/// | householdId         | Always immutable (FK)                            |
/// | type                | Always immutable — DB trigger + repo             |
/// | currencyCode        | Always immutable — DB trigger + repo             |
/// | ownerType           | Immutable after financial history — DB trigger   |
/// | fundPurpose         | Immutable after financial history — DB trigger   |
/// | isProtected         | Immutable after history; childProtectedFund      |
/// |                     | cannot disable even before history — DB trigger  |
/// | isSpendable         | Immutable after financial history — DB trigger   |
/// | includeInNetWorth   | Immutable after history — DB trigger + repo      |
/// | includeInZakat      | Immutable after history — DB trigger + repo      |
/// | name                | Always editable — no restriction                 |
/// | isArchived          | Only via archive workflow — not in generic update|
///
/// "Financial history" = at least one row in `ledger_entries` referencing
/// this account.
///
/// Archiving: sets [isArchived] to true. Does NOT delete ledger history.
/// Archived accounts are excluded from active balance totals but their
/// historical entries remain queryable (INV-015).
@immutable
final class FinancialAccount {
  const FinancialAccount({
    required this.id,
    required this.householdId,
    required this.name,
    required this.type,
    required this.ownerType,
    required this.fundPurpose,
    required this.currencyCode,
    required this.isSpendable,
    required this.isProtected,
    required this.includeInNetWorth,
    required this.includeInZakat,
    required this.isArchived,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.archivedAt,
    this.notes,
    this.metadata,
  });

  final String id;
  final String householdId;

  /// User-visible account name.
  final String name;

  /// IMMUTABLE: must not change after account creation.
  final FinancialAccountType type;

  final AccountOwnerType ownerType;
  final FundPurpose fundPurpose;

  /// ISO 4217 currency code. Immutable in V1 once the account has financial use.
  final String currencyCode;

  /// True when this account is included in the "available to spend" total.
  final bool isSpendable;

  /// True when any debit from this account requires extra confirmation.
  /// [FinancialAccountType.childProtectedFund] accounts are always protected.
  final bool isProtected;

  /// True when this account's balance contributes to net worth (INV-009).
  final bool includeInNetWorth;

  /// True when this account's balance is included in Zakat calculation.
  final bool includeInZakat;

  final bool isArchived;
  final DateTime? archivedAt;

  /// User-supplied display order within the account list.
  final int displayOrder;

  /// Optional free-text note. Not used for financial calculations.
  final String? notes;

  /// Type-specific structured data (bank name, certificate dates, gold weight, etc.).
  /// Stored as a JSON string in the database.
  final Map<String, dynamic>? metadata;

  /// ISO 8601 UTC creation timestamp.
  final String createdAt;

  /// ISO 8601 UTC last-updated timestamp.
  final String updatedAt;

  final String createdBy;

  // ── Derived predicates ───────────────────────────────────────────────────────

  /// True when any debit from this account MUST be accompanied by a
  /// [ChildWithdrawalAuditParams] record (INV-006).
  bool get requiresWithdrawalAudit => type.requiresProtectedWithdrawalAudit || isProtected;

  /// True when this account is a child-protected fund (always audited).
  bool get isChildProtectedFund => type == FinancialAccountType.childProtectedFund;

  // ── copyWith ─────────────────────────────────────────────────────────────────

  FinancialAccount copyWith({
    String? name,
    AccountOwnerType? ownerType,
    FundPurpose? fundPurpose,
    bool? isSpendable,
    bool? isProtected,
    bool? includeInNetWorth,
    bool? includeInZakat,
    bool? isArchived,
    DateTime? archivedAt,
    int? displayOrder,
    String? notes,
    Map<String, dynamic>? metadata,
    String? updatedAt,
  }) {
    return FinancialAccount(
      id: id,
      householdId: householdId,
      name: name ?? this.name,
      // type is intentionally excluded from copyWith (immutable after creation)
      type: type,
      // currencyCode is intentionally excluded (immutable after creation)
      currencyCode: currencyCode,
      ownerType: ownerType ?? this.ownerType,
      fundPurpose: fundPurpose ?? this.fundPurpose,
      isSpendable: isSpendable ?? this.isSpendable,
      isProtected: isProtected ?? this.isProtected,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      includeInZakat: includeInZakat ?? this.includeInZakat,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      displayOrder: displayOrder ?? this.displayOrder,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is FinancialAccount && other.id == id && other.householdId == householdId;

  @override
  int get hashCode => Object.hash(id, householdId);

  @override
  String toString() => 'FinancialAccount(id: $id, type: ${type.code})';
}

/// Parameters required to create a new [FinancialAccount].
@immutable
final class CreateAccountParams {
  const CreateAccountParams({
    required this.id,
    required this.householdId,
    required this.name,
    required this.type,
    required this.ownerType,
    required this.fundPurpose,
    required this.currencyCode,
    required this.isSpendable,
    required this.isProtected,
    required this.includeInNetWorth,
    required this.includeInZakat,
    required this.displayOrder,
    required this.createdBy,
    this.notes,
    this.metadata,
    this.idempotencyKey,
    this.idempotencyPayload,
  });

  final String id;
  final String householdId;
  final String name;
  final FinancialAccountType type;
  final AccountOwnerType ownerType;
  final FundPurpose fundPurpose;
  final String currencyCode;
  final bool isSpendable;
  final bool isProtected;
  final bool includeInNetWorth;
  final bool includeInZakat;
  final int displayOrder;
  final String createdBy;
  final String? notes;
  final Map<String, dynamic>? metadata;

  /// Optional idempotency key scoped to (householdId, idempotencyKey).
  /// When provided, a second call with the same key and matching payload
  /// returns the existing account without creating a duplicate.
  final String? idempotencyKey;

  /// Stable serialised fingerprint of the creation payload.
  /// Stored to detect same-key-different-payload conflicts.
  final String? idempotencyPayload;
}
