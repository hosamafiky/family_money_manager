import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/accounts/domain/account_eligibility.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';

/// Maps [AccountEligibility.ordinaryEndpointRejection] to an [AppResult] failure.
///
/// Returns `null` when [account] is eligible for ordinary I/E/transfer.
AppResult<T>? ordinaryEndpointFailure<T>(
  FinancialAccount account, {
  required String field,
}) {
  switch (AccountEligibility.ordinaryEndpointRejection(account)) {
    case AccountIneligibilityReason.archived:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorAccountArchived',
      );
    case AccountIneligibilityReason.goalReserve:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorGoalReserveNotAllowedInOrdinaryTransaction',
      );
    case AccountIneligibilityReason.certificate:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorCertificateAccountNotAllowedInOrdinaryTransaction',
      );
    case AccountIneligibilityReason.protected:
    case AccountIneligibilityReason.notSpendable:
    case AccountIneligibilityReason.currencyMismatch:
    case AccountIneligibilityReason.otherRestricted:
    case null:
      return null;
  }
}

/// Maps [AccountEligibility.goalFundingSourceRejection] to an [AppResult] failure.
///
/// Returns `null` when [account] is eligible as a goal funding source.
AppResult<T>? goalFundingSourceFailure<T>(
  FinancialAccount account, {
  required String currencyCode,
  String field = 'sourceAccountId',
}) {
  switch (AccountEligibility.goalFundingSourceRejection(
    account,
    currencyCode: currencyCode,
  )) {
    case AccountIneligibilityReason.archived:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorAccountArchived',
      );
    case AccountIneligibilityReason.protected:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorGoalSourceIsProtected',
      );
    case AccountIneligibilityReason.goalReserve:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorGoalSourceIsReserve',
      );
    case AccountIneligibilityReason.certificate:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorCertificateAccountNotAllowedAsSource',
      );
    case AccountIneligibilityReason.notSpendable:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorGoalSourceNotSpendable',
      );
    case AccountIneligibilityReason.currencyMismatch:
      return AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    case AccountIneligibilityReason.otherRestricted:
    case null:
      return null;
  }
}

/// Maps [AccountEligibility.goalReleaseDestinationRejection] to an [AppResult]
/// failure.
///
/// Returns `null` when [account] is eligible as a goal release destination.
AppResult<T>? goalReleaseDestinationFailure<T>(
  FinancialAccount account, {
  required String currencyCode,
  String field = 'destinationAccountId',
}) {
  switch (AccountEligibility.goalReleaseDestinationRejection(
    account,
    currencyCode: currencyCode,
  )) {
    case AccountIneligibilityReason.archived:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorAccountArchived',
      );
    case AccountIneligibilityReason.goalReserve:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorGoalSourceIsReserve',
      );
    case AccountIneligibilityReason.certificate:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorCertificateAccountNotAllowedAsDestination',
      );
    case AccountIneligibilityReason.notSpendable:
      return AppValidationFailure(
        field: field,
        messageKey: 'errorGoalDestinationNotSpendable',
      );
    case AccountIneligibilityReason.currencyMismatch:
      return AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    case AccountIneligibilityReason.protected:
    case AccountIneligibilityReason.otherRestricted:
    case null:
      return null;
  }
}
