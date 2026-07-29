import 'package:family_money_manager/core/localization/app_localizations.dart';

/// Maps domain [messageKey] strings (camelCase or legacy snake_case)
/// to localized user-facing text. Never display raw keys in the UI.
String resolveMessageKey(AppLocalizations l10n, String key) {
  return switch (key) {
    'errorAccountArchived' => l10n.errorAccountArchived,
    'errorBeneficiaryRequired' => l10n.errorBeneficiaryRequired,
    'errorBudgetCurrencyRequired' => l10n.errorBudgetCurrencyRequired,
    'errorBudgetEndBeforeStart' => l10n.errorBudgetEndBeforeStart,
    'errorBudgetIdempotencyConflict' => l10n.errorBudgetIdempotencyConflict,
    'errorBudgetLimitZero' => l10n.errorBudgetLimitZero,
    'errorBudgetNameEmpty' => l10n.errorBudgetNameEmpty,
    'errorCategoryRequired' => l10n.errorCategoryRequired,
    'errorCertificateAccountNotAllowedAsDestination' =>
      l10n.errorCertificateAccountNotAllowedAsDestination,
    'errorCertificateAccountNotAllowedAsSource' =>
      l10n.errorCertificateAccountNotAllowedAsSource,
    'errorCertificateAccountNotAllowedInOrdinaryTransaction' =>
      l10n.errorCertificateAccountNotAllowedInOrdinaryTransaction,
    'errorCertificateArchiveNonzeroBalance' =>
      l10n.errorCertificateArchiveNonzeroBalance,
    'errorCertificateArchived' => l10n.errorCertificateArchived,
    'errorCertificateCurrencyRequired' => l10n.errorCertificateCurrencyRequired,
    'errorCertificateDatesRequired' => l10n.errorCertificateDatesRequired,
    'errorCertificateFullRedemptionOnly' =>
      l10n.errorCertificateFullRedemptionOnly,
    'errorCertificateIdempotencyConflict' =>
      l10n.errorCertificateIdempotencyConflict,
    'errorCertificateInstitutionRequired' =>
      l10n.errorCertificateInstitutionRequired,
    'errorCertificateMaturityBeforeStart' =>
      l10n.errorCertificateMaturityBeforeStart,
    'errorCertificateNoPrincipal' => l10n.errorCertificateNoPrincipal,
    'errorCertificateNotActive' => l10n.errorCertificateNotActive,
    'errorCertificateNotMatured' => l10n.errorCertificateNotMatured,
    'errorCertificatePrincipalZero' => l10n.errorCertificatePrincipalZero,
    'errorCertificateRedemptionReversalNotSupported' =>
      l10n.errorCertificateRedemptionReversalNotSupported,
    'errorCertificateRestoreRequiresArchived' =>
      l10n.errorCertificateRestoreRequiresArchived,
    'errorCertificateReversalNotAllowedAfterHistory' =>
      l10n.errorCertificateReversalNotAllowedAfterHistory,
    'errorCertificateReversalRequiresActive' =>
      l10n.errorCertificateReversalRequiresActive,
    'errorCertificateSourceInvalid' => l10n.errorCertificateSourceInvalid,
    'errorCertificateSourceIsProtected' =>
      l10n.errorCertificateSourceIsProtected,
    'errorCertificateSourceProtected' => l10n.errorCertificateSourceIsProtected,
    'errorCertificateSourceRequired' => l10n.errorCertificateSourceRequired,
    'errorCurrencyMismatch' => l10n.errorCurrencyMismatch,
    'errorEarlyCompletionConfirmationRequired' =>
      l10n.errorEarlyCompletionConfirmationRequired,
    'errorEarlyCompletionReasonRequired' =>
      l10n.errorEarlyCompletionReasonRequired,
    'errorGoalArchiveNonzeroBalance' => l10n.errorGoalArchiveNonzeroBalance,
    'errorGoalArchived' => l10n.errorGoalArchived,
    'errorGoalCurrencyRequired' => l10n.errorGoalCurrencyRequired,
    'errorGoalDestinationNotSpendable' => l10n.errorGoalDestinationNotSpendable,
    'errorGoalIdempotencyConflict' => l10n.errorGoalIdempotencyConflict,
    'errorGoalInsufficientReserve' => l10n.errorGoalInsufficientReserve,
    'errorGoalLifecycleRequiresTypedWorkflow' =>
      l10n.errorGoalLifecycleRequiresTypedWorkflow,
    'errorGoalNameEmpty' => l10n.errorGoalNameEmpty,
    'errorGoalNormalCompletionRequiresTarget' =>
      l10n.errorGoalNormalCompletionRequiresTarget,
    'errorGoalNotActive' => l10n.errorGoalNotActive,
    'errorGoalReleaseReasonEmpty' => l10n.errorGoalReleaseReasonEmpty,
    'errorGoalReserveNotAllowedInOrdinaryTransaction' =>
      l10n.errorGoalReserveNotAllowedInOrdinaryTransaction,
    'errorGoalRestoreRequiresArchived' => l10n.errorGoalRestoreRequiresArchived,
    'errorGoalReversalInvalidMovement' => l10n.errorGoalReversalInvalidMovement,
    'errorGoalSourceIsProtected' => l10n.errorGoalSourceIsProtected,
    'errorGoalSourceIsReserve' => l10n.errorGoalSourceIsReserve,
    'errorGoalSourceNotSpendable' => l10n.errorGoalSourceNotSpendable,
    'errorGoalTargetZero' => l10n.errorGoalTargetZero,
    'errorInsufficientFunds' => l10n.errorInsufficientFunds,
    'errorLifecycleEventConflict' => l10n.errorLifecycleEventConflict,
    'errorOperationAlreadyReversed' => l10n.errorOperationAlreadyReversed,
    'errorReversalConflict' => l10n.errorReversalConflict,
    'errorReversalReasonRequired' => l10n.errorReversalReasonRequired,
    'errorReversalReasonTooLong' => l10n.errorReversalReasonTooLong,
    'errorReversalRequiresProtectedAudit' =>
      l10n.errorReversalRequiresProtectedAudit,
    'errorSameAccount' => l10n.errorSameAccount,
    'errorSpenderRequired' => l10n.errorSpenderRequired,
    'errorValidationGeneric' => l10n.errorValidationGeneric,
    'errorWithdrawalAcknowledgmentRequired' =>
      l10n.errorWithdrawalAcknowledgmentRequired,
    'errorWithdrawalConfirmationRequired' =>
      l10n.errorWithdrawalConfirmationRequired,
    'errorWithdrawalReasonRequired' => l10n.errorWithdrawalReasonRequired,
    'error_account_already_archived' => l10n.errorAccountAlreadyArchived,
    'error_account_archived' => l10n.errorAccountArchived,
    'error_account_duplicate' => l10n.errorAccountDuplicate,
    'error_account_name_empty' => l10n.errorAccountNameEmpty,
    'error_account_required' => l10n.errorAccountRequired,
    'error_amount_must_be_positive' => l10n.errorAmountMustBePositive,
    'error_archive_nonzero_balance' => l10n.errorArchiveNonzeroBalance,
    'error_cannot_archive_primary_user' => l10n.errorCannotArchivePrimaryUser,
    'error_date_invalid' => l10n.errorDateInvalid,
    'error_household_already_initialized' =>
      l10n.errorHouseholdAlreadyInitialized,
    'error_household_id_empty' => l10n.errorHouseholdIdEmpty,
    'error_member_already_archived' => l10n.errorMemberAlreadyArchived,
    'error_member_name_empty' => l10n.errorMemberNameEmpty,
    'error_money_excess_decimals' => l10n.errorMoneyExcessDecimals,
    'error_money_invalid_format' => l10n.errorMoneyInvalidFormat,
    'error_money_overflow' => l10n.errorMoneyOverflow,
    'error_opening_balance_negative' => l10n.errorOpeningBalanceNegative,
    'error_spouse_duplicate' => l10n.errorSpouseDuplicate,
    'error_validation_generic' => l10n.errorValidationGeneric,
    _ => l10n.errorGeneric,
  };
}
