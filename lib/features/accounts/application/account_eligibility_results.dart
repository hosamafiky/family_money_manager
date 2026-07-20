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
    case AccountIneligibilityReason.currencyMismatch:
    case AccountIneligibilityReason.otherRestricted:
    case null:
      return null;
  }
}
