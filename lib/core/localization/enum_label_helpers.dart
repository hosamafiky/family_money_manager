import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/certificates/domain/certificate.dart';

/// Localized display label for [OperationType] (never uses [OperationType.code]).
String operationTypeLabel(AppLocalizations l10n, OperationType type) {
  return switch (type) {
    OperationType.income => l10n.transactionTypeIncome,
    OperationType.expense => l10n.transactionTypeExpense,
    OperationType.transfer => l10n.transactionTypeTransfer,
    OperationType.openingBalance => l10n.transactionTypeOpeningBalance,
    OperationType.adjustment => l10n.transactionTypeAdjustment,
    OperationType.reversal => l10n.transactionTypeReversal,
    OperationType.assetPurchase => l10n.transactionTypeAssetPurchase,
    OperationType.assetSale => l10n.transactionTypeAssetSale,
    OperationType.liabilityCreation => l10n.transactionTypeLiabilityCreation,
    OperationType.liabilityRepayment => l10n.transactionTypeLiabilityRepayment,
    OperationType.certificateFunding => l10n.transactionTypeCertificateFunding,
    OperationType.certificateMaturity =>
      l10n.transactionTypeCertificateMaturity,
    OperationType.interestIncome => l10n.transactionTypeInterestIncome,
    OperationType.goldPurchase => l10n.transactionTypeGoldPurchase,
    OperationType.goldSale => l10n.transactionTypeGoldSale,
    OperationType.goalFunding => l10n.transactionTypeGoalFunding,
    OperationType.goalWithdrawal => l10n.transactionTypeGoalWithdrawal,
    OperationType.childFundDeposit => l10n.transactionTypeChildFundDeposit,
    OperationType.childFundWithdrawal =>
      l10n.transactionTypeChildFundWithdrawal,
    OperationType.sadaqah => l10n.transactionTypeSadaqah,
    OperationType.zakat => l10n.transactionTypeZakat,
  };
}

/// Localized display label for [FinancialAccountType].
String accountTypeLabel(AppLocalizations l10n, FinancialAccountType type) {
  return switch (type) {
    FinancialAccountType.personalCashWallet => l10n.accountTypePersonalCash,
    FinancialAccountType.spouseCashWallet => l10n.accountTypeSpouseCash,
    FinancialAccountType.householdCash => l10n.accountTypeHouseholdCash,
    FinancialAccountType.homeSavingsCash => l10n.accountTypeHomeSavings,
    FinancialAccountType.bankAccount => l10n.accountTypeBankAccount,
    FinancialAccountType.mobileWallet => l10n.accountTypeMobileWallet,
    FinancialAccountType.childProtectedFund => l10n.accountTypeChildFund,
    FinancialAccountType.goalReserve => l10n.accountTypeGoalReserve,
    FinancialAccountType.certificate => l10n.accountTypeCertificate,
    FinancialAccountType.goldHolding => l10n.accountTypeGoldHolding,
    FinancialAccountType.investment => l10n.accountTypeInvestment,
    FinancialAccountType.otherAsset => l10n.accountTypeOtherAsset,
  };
}

/// Localized form/detail label for [ExpenseScope].
String expenseScopeLabel(AppLocalizations l10n, ExpenseScope scope) {
  return switch (scope) {
    ExpenseScope.personal => l10n.scopePersonal,
    ExpenseScope.spouse => l10n.scopeSpouse,
    ExpenseScope.household => l10n.scopeHousehold,
    ExpenseScope.child => l10n.scopeChild,
    ExpenseScope.shared => l10n.scopeShared,
  };
}

/// Localized dashboard/report label for [ExpenseScope].
String expenseScopeDashboardLabel(AppLocalizations l10n, ExpenseScope scope) {
  return switch (scope) {
    ExpenseScope.personal => l10n.dashboardScopePersonal,
    ExpenseScope.spouse => l10n.dashboardScopeSpouse,
    ExpenseScope.household => l10n.dashboardScopeHousehold,
    ExpenseScope.child => l10n.dashboardScopeChild,
    ExpenseScope.shared => l10n.dashboardScopeShared,
  };
}

/// Localized label for [CertificateEventType].
String certificateEventTypeLabel(
  AppLocalizations l10n,
  CertificateEventType type,
) {
  return switch (type) {
    CertificateEventType.created => l10n.certificateEventCreated,
    CertificateEventType.purchased => l10n.certificateEventPurchased,
    CertificateEventType.profitReceived => l10n.certificateEventProfitReceived,
    CertificateEventType.redeemed => l10n.certificateEventRedeemed,
    CertificateEventType.archived => l10n.certificateEventArchived,
    CertificateEventType.restored => l10n.certificateEventRestored,
    CertificateEventType.definitionRevised =>
      l10n.certificateEventDefinitionRevised,
    CertificateEventType.purchaseReversed =>
      l10n.certificateEventPurchaseReversed,
    CertificateEventType.profitReversed => l10n.certificateEventProfitReversed,
  };
}

/// Localized label for [CertificateLifecycle].
String certificateLifecycleLabel(
  AppLocalizations l10n,
  CertificateLifecycle lifecycle,
) {
  return switch (lifecycle) {
    CertificateLifecycle.active => l10n.certificateLifecycleActive,
    CertificateLifecycle.redeemed => l10n.certificateLifecycleRedeemed,
    CertificateLifecycle.archived => l10n.certificateLifecycleArchived,
  };
}

/// Localized label for [CertificateTermState].
String certificateTermStateLabel(
  AppLocalizations l10n,
  CertificateTermState state,
) {
  return switch (state) {
    CertificateTermState.notStarted => l10n.certificateTermNotStarted,
    CertificateTermState.activeTerm => l10n.certificateTermActive,
    CertificateTermState.matured => l10n.certificateTermMatured,
    CertificateTermState.overdueRedemption => l10n.certificateTermOverdue,
    CertificateTermState.fullyRedeemed => l10n.certificateTermFullyRedeemed,
  };
}

/// Localized label for [CertificateProfitFrequency].
String certificateProfitFrequencyLabel(
  AppLocalizations l10n,
  CertificateProfitFrequency frequency,
) {
  return switch (frequency) {
    CertificateProfitFrequency.monthly => l10n.certificateProfitFreqMonthly,
    CertificateProfitFrequency.quarterly => l10n.certificateProfitFreqQuarterly,
    CertificateProfitFrequency.semiAnnual =>
      l10n.certificateProfitFreqSemiAnnual,
    CertificateProfitFrequency.annual => l10n.certificateProfitFreqAnnual,
    CertificateProfitFrequency.atMaturity =>
      l10n.certificateProfitFreqAtMaturity,
    CertificateProfitFrequency.other => l10n.certificateProfitFreqOther,
  };
}

/// Localized display name for [Currency] (includes ISO code for clarity).
String currencyLabel(AppLocalizations l10n, Currency currency) {
  return switch (currency) {
    Currency.egp => l10n.currencyEgp,
    Currency.usd => l10n.currencyUsd,
    Currency.eur => l10n.currencyEur,
    Currency.gbp => l10n.currencyGbp,
    Currency.sar => l10n.currencySar,
    Currency.aed => l10n.currencyAed,
    Currency.jpy => l10n.currencyJpy,
    Currency.kwd => l10n.currencyKwd,
    Currency.bhd => l10n.currencyBhd,
    Currency.omr => l10n.currencyOmr,
  };
}
