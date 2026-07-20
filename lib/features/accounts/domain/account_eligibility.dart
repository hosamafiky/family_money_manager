/// Account eligibility policies for ordinary money workflows.
///
/// UI filters are convenience only. Use cases and repositories remain the
/// authoritative gates; the database rejects structurally invalid writes via
/// triggers and classification rules.
///
/// **Financial invariant (Phase 6B.1.1):** Certificate accounts are owned
/// exclusively by approved certificate workflows (purchase, redemption,
/// controlled reversals, and other explicitly approved cert-owned ops). They
/// must never be used as goal funding sources, goal release destinations,
/// ordinary I/E/transfer endpoints, opening balances, or unrelated adjustments.
library;

import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';

/// Why an account is ineligible for a given workflow.
enum AccountIneligibilityReason {
  archived,
  protected,
  goalReserve,
  certificate,
  notSpendable,
  currencyMismatch,
  otherRestricted,
}

/// Shared eligibility checks for cash / transfer / goal / certificate UX.
abstract final class AccountEligibility {
  const AccountEligibility._();

  /// Accounts that must not appear as ordinary income/expense/transfer endpoints.
  static bool isFeatureManagedType(FinancialAccountType type) =>
      type == FinancialAccountType.goalReserve ||
      type == FinancialAccountType.certificate;

  /// True when the account is certificate-owned by type or fund purpose.
  ///
  /// Linkage to `savings_certificates` is enforced at repository/DB layers.
  static bool isCertificateOwned(FinancialAccount account) =>
      account.type == FinancialAccountType.certificate ||
      account.fundPurpose == FundPurpose.certificate;

  /// Ordinary I/E/transfer picker: active, non–feature-managed accounts.
  static bool isOrdinaryTransactionEndpoint(FinancialAccount account) =>
      !account.isArchived && !isFeatureManagedType(account.type);

  /// Goal funding / creation source: same currency, spendable, not protected,
  /// not reserve, not certificate-owned.
  ///
  /// Matches [CreateGoalUseCase] / [FundGoalUseCase] application gates and
  /// DB funding-source eligibility triggers (Phase 6B.1.1).
  static bool isGoalFundingSource(
    FinancialAccount account, {
    required String currencyCode,
  }) {
    return !account.isArchived &&
        !account.isProtected &&
        account.isSpendable &&
        account.currencyCode == currencyCode &&
        account.type != FinancialAccountType.goalReserve &&
        !isCertificateOwned(account);
  }

  /// Goal release destination: active, spendable, same currency, not reserve,
  /// not certificate-owned.
  static bool isGoalReleaseDestination(
    FinancialAccount account, {
    required String currencyCode,
  }) {
    return !account.isArchived &&
        account.isSpendable &&
        account.currencyCode == currencyCode &&
        account.type != FinancialAccountType.goalReserve &&
        !isCertificateOwned(account);
  }

  /// Certificate purchase source / profit destination convenience filter.
  static bool isCertificateCashEndpoint(
    FinancialAccount account, {
    required String currencyCode,
  }) {
    return !account.isArchived &&
        account.currencyCode == currencyCode &&
        !isFeatureManagedType(account.type);
  }

  /// Application-layer rejection reason for ordinary transaction endpoints.
  static AccountIneligibilityReason? ordinaryEndpointRejection(
    FinancialAccount account,
  ) {
    if (account.isArchived) return AccountIneligibilityReason.archived;
    if (account.type == FinancialAccountType.goalReserve) {
      return AccountIneligibilityReason.goalReserve;
    }
    if (account.type == FinancialAccountType.certificate) {
      return AccountIneligibilityReason.certificate;
    }
    return null;
  }

  /// Rejection reason for a goal funding / initial-funding source.
  static AccountIneligibilityReason? goalFundingSourceRejection(
    FinancialAccount account, {
    required String currencyCode,
  }) {
    if (account.isArchived) return AccountIneligibilityReason.archived;
    if (account.isProtected) return AccountIneligibilityReason.protected;
    if (account.type == FinancialAccountType.goalReserve) {
      return AccountIneligibilityReason.goalReserve;
    }
    if (isCertificateOwned(account)) {
      return AccountIneligibilityReason.certificate;
    }
    if (!account.isSpendable) return AccountIneligibilityReason.notSpendable;
    if (account.currencyCode != currencyCode) {
      return AccountIneligibilityReason.currencyMismatch;
    }
    return null;
  }

  /// Rejection reason for a goal release destination.
  static AccountIneligibilityReason? goalReleaseDestinationRejection(
    FinancialAccount account, {
    required String currencyCode,
  }) {
    if (account.isArchived) return AccountIneligibilityReason.archived;
    if (account.type == FinancialAccountType.goalReserve) {
      return AccountIneligibilityReason.goalReserve;
    }
    if (isCertificateOwned(account)) {
      return AccountIneligibilityReason.certificate;
    }
    if (!account.isSpendable) return AccountIneligibilityReason.notSpendable;
    if (account.currencyCode != currencyCode) {
      return AccountIneligibilityReason.currencyMismatch;
    }
    return null;
  }
}
