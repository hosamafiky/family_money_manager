import 'package:family_money_manager/features/accounts/domain/financial_account.dart';

/// Repository abstraction for financial account persistence.
///
/// ARCHITECTURE RULES:
/// - No Flutter widgets may call methods on this interface directly.
///   All access must go through an application-layer use case or provider.
/// - No Drift types appear in the method signatures. The implementation maps
///   between Drift rows and [FinancialAccount] domain objects.
/// - [FinancialAccountType] is immutable after creation. No method in this
///   interface allows changing an account's type.
/// - Hard deletes are not supported. Use [archiveAccount] instead.
abstract interface class AccountRepository {
  /// Creates and persists a new financial account.
  ///
  /// Throws [DuplicateAccountIdError] when [params.id] already exists.
  Future<FinancialAccount> createAccount(CreateAccountParams params);

  /// Returns the account with [id] within [householdId], or null when not found.
  Future<FinancialAccount?> findById({
    required String id,
    required String householdId,
  });

  /// Returns all accounts for [householdId].
  ///
  /// Archived accounts are excluded by default. Pass [includeArchived: true]
  /// to include them (e.g. for historical reports).
  Future<List<FinancialAccount>> findByHousehold({
    required String householdId,
    bool includeArchived = false,
  });

  /// Checks whether an opening balance has already been recorded for [accountId].
  ///
  /// Used to enforce the single-opening-balance rule (FINANCIAL_MODEL §5.1).
  Future<bool> hasOpeningBalance({
    required String accountId,
    required String householdId,
  });

  /// Marks the account as archived.
  ///
  /// Does NOT delete ledger entries (INV-015).
  /// Throws [AccountNotFoundError] when the account does not exist.
  /// Throws [AccountAlreadyArchivedError] when already archived.
  Future<FinancialAccount> archiveAccount({
    required String id,
    required String householdId,
    required DateTime archivedAt,
    required String updatedAt,
  });

  /// Updates the mutable metadata of an account.
  ///
  /// The [type] and [currencyCode] fields are intentionally excluded; this
  /// method cannot change them. Throws [AccountNotFoundError] when not found.
  Future<FinancialAccount> updateAccount({
    required String id,
    required String householdId,
    String? name,
    bool? isSpendable,
    bool? isProtected,
    bool? includeInNetWorth,
    bool? includeInZakat,
    int? displayOrder,
    String? notes,
    Map<String, dynamic>? metadata,
    required String updatedAt,
  });
}

// ── Domain errors ────────────────────────────────────────────────────────────

final class DuplicateAccountIdError extends Error {
  DuplicateAccountIdError(this.accountId);
  final String accountId;
  @override
  String toString() =>
      'DuplicateAccountIdError: account $accountId already exists';
}

final class AccountNotFoundError extends Error {
  AccountNotFoundError(this.accountId);
  final String accountId;
  @override
  String toString() => 'AccountNotFoundError: account $accountId not found';
}

final class AccountAlreadyArchivedError extends Error {
  AccountAlreadyArchivedError(this.accountId);
  final String accountId;
  @override
  String toString() =>
      'AccountAlreadyArchivedError: account $accountId is already archived';
}
