/// Account eligibility policies for ordinary money workflows.
///
/// UI filters are convenience only. Use cases and repositories remain the
/// authoritative gates; the database rejects structurally invalid writes via
/// triggers and classification rules.
library;

import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';

/// Why an account is ineligible for a given workflow.
enum AccountIneligibilityReason {
  archived,
  protected,
  goalReserve,
  certificate,
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

  /// Ordinary I/E/transfer picker: active, non–feature-managed accounts.
  static bool isOrdinaryTransactionEndpoint(FinancialAccount account) =>
      !account.isArchived && !isFeatureManagedType(account.type);

  /// Goal funding / creation source: same currency, not protected, not reserve.
  ///
  /// Matches [CreateGoalUseCase] / [FundGoalUseCase] application gates.
  /// Certificate accounts are not excluded here (legacy application behavior);
  /// DB/feature writers remain authoritative for certificate ledgers.
  static bool isGoalFundingSource(
    FinancialAccount account, {
    required String currencyCode,
  }) {
    return !account.isArchived &&
        !account.isProtected &&
        account.currencyCode == currencyCode &&
        account.type != FinancialAccountType.goalReserve;
  }

  /// Goal release destination: standard account (not reserve), same currency.
  static bool isGoalReleaseDestination(
    FinancialAccount account, {
    required String currencyCode,
  }) {
    return !account.isArchived &&
        account.currencyCode == currencyCode &&
        account.type != FinancialAccountType.goalReserve;
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
}
