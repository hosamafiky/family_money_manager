/// Financial account type, owner, purpose, and scope enumerations.
///
/// All enum values are stored as stable English string codes in the database.
/// Display strings are provided through the localisation layer.
///
/// IMMUTABILITY RULE: [FinancialAccountType] must not be changed after an
/// account is created. See FINANCIAL_MODEL.md §21.
library;

/// The type of financial account.
///
/// Determines default behaviour for spendability, protection, net-worth
/// inclusion, and which ledger entry types are valid against it.
enum FinancialAccountType {
  personalCashWallet,
  spouseCashWallet,
  householdCash,
  homeSavingsCash,
  bankAccount,
  mobileWallet,
  childProtectedFund,
  goalReserve,
  certificate,
  goldHolding,
  investment,
  otherAsset;

  /// Serialises to the stable database code (matches the Dart name).
  String get code => name;

  /// Deserialises from a [code] string.
  /// Throws [ArgumentError] for unknown codes.
  static FinancialAccountType fromCode(String code) {
    for (final t in FinancialAccountType.values) {
      if (t.name == code) return t;
    }
    throw ArgumentError.value(code, 'code', 'Unknown FinancialAccountType');
  }

  /// Returns true when any debit on this account type requires a
  /// [ChildWithdrawalAudit] record. See INV-006 and FINANCIAL_MODEL.md §9.
  bool get requiresProtectedWithdrawalAudit =>
      this == FinancialAccountType.childProtectedFund;
}

/// Who owns the financial account.
enum AccountOwnerType {
  user,
  spouse,
  household,
  child,
  shared;

  String get code => name;

  static AccountOwnerType fromCode(String code) {
    for (final t in AccountOwnerType.values) {
      if (t.name == code) return t;
    }
    throw ArgumentError.value(code, 'code', 'Unknown AccountOwnerType');
  }
}

/// The purpose for which the fund was created.
enum FundPurpose {
  available,
  householdSpending,
  personalSpending,
  emergencySavings,
  longTermSavings,
  childProtected,
  investment,
  certificate,
  gold,
  custom;

  String get code => name;

  static FundPurpose fromCode(String code) {
    for (final t in FundPurpose.values) {
      if (t.name == code) return t;
    }
    throw ArgumentError.value(code, 'code', 'Unknown FundPurpose');
  }
}

/// The scope of a financial operation (personal, household, etc.).
enum ExpenseScope {
  personal,
  household,
  spouse,
  child,
  shared;

  String get code => name;

  static ExpenseScope fromCode(String code) {
    for (final t in ExpenseScope.values) {
      if (t.name == code) return t;
    }
    throw ArgumentError.value(code, 'code', 'Unknown ExpenseScope');
  }
}

/// A member role within the household.
enum HouseholdMemberRole {
  user,
  spouse,
  child,
  other;

  String get code => name;

  static HouseholdMemberRole fromCode(String code) {
    for (final t in HouseholdMemberRole.values) {
      if (t.name == code) return t;
    }
    throw ArgumentError.value(code, 'code', 'Unknown HouseholdMemberRole');
  }
}

/// Sync status for an entity. Used by the persistence layer only.
/// The domain layer does not depend on this enum.
enum SyncStatus {
  local,
  pending,
  uploading,
  synced,
  conflict,
  failed;

  String get code => name;

  static SyncStatus fromCode(String code) {
    for (final t in SyncStatus.values) {
      if (t.name == code) return t;
    }
    throw ArgumentError.value(code, 'code', 'Unknown SyncStatus');
  }
}
