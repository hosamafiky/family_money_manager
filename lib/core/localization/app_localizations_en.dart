// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family Money Manager';

  @override
  String get foundationTitle => 'Foundation Phase';

  @override
  String get foundationSubtitle => 'Project infrastructure is ready.';

  @override
  String get foundationLanguageLabel => 'Language';

  @override
  String get foundationThemeLabel => 'Theme';

  @override
  String get foundationDirectionLabel => 'Direction';

  @override
  String get foundationSwitchToArabic => 'العربية';

  @override
  String get foundationSwitchToEnglish => 'English';

  @override
  String get foundationThemeLight => 'Light';

  @override
  String get foundationThemeDark => 'Dark';

  @override
  String get foundationDirectionLtr => 'LTR';

  @override
  String get foundationDirectionRtl => 'RTL';

  @override
  String get foundationNote =>
      'No financial features exist yet. Phase 2 will introduce the ledger.';

  @override
  String get errorNetwork =>
      'A network error occurred. Please check your connection and try again.';

  @override
  String get errorAuth => 'Your session is invalid. Please sign in again.';

  @override
  String get errorStorage =>
      'A local storage error occurred. Please try again.';

  @override
  String get errorUnknown => 'An unexpected error occurred. Please try again.';

  @override
  String get foundationDetailTitle => 'Foundation Detail';

  @override
  String foundationDetailProbeLabel(String probeId) {
    return 'Probe: $probeId';
  }

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navMembers => 'Family';

  @override
  String get navSettings => 'Settings';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsEmpty => 'No accounts yet. Create your first account.';

  @override
  String get accountsAddButton => 'Add Account';

  @override
  String get accountsTotalSpendable => 'Total Spendable';

  @override
  String get accountsTotalProtected => 'Total Protected';

  @override
  String get accountTypePersonalCash => 'Personal Cash Wallet';

  @override
  String get accountTypeSpouseCash => 'Spouse Cash Wallet';

  @override
  String get accountTypeHouseholdCash => 'Household Cash';

  @override
  String get accountTypeHomeSavings => 'Home Savings';

  @override
  String get accountTypeBankAccount => 'Bank Account';

  @override
  String get accountTypeMobileWallet => 'Mobile Wallet';

  @override
  String get accountTypeChildFund => 'Protected Child Fund';

  @override
  String get accountCreateTitle => 'New Account';

  @override
  String get accountName => 'Account Name';

  @override
  String get accountOwner => 'Owner';

  @override
  String get accountCurrency => 'Currency';

  @override
  String get accountOpeningBalance => 'Opening Balance';

  @override
  String get accountNotes => 'Notes';

  @override
  String get accountProtectedWarning =>
      'This is a protected account. Funds are not available for ordinary spending.';

  @override
  String get accountChildFundConfirmTitle => 'Confirm Child Fund Creation';

  @override
  String get accountChildFundConfirmBody =>
      'Funds in this account will be protected and dedicated to the child. They cannot be used for ordinary spending.';

  @override
  String get accountDetailTitle => 'Account Details';

  @override
  String get accountDetailBalance => 'Current Balance';

  @override
  String get accountDetailHistory => 'Financial History';

  @override
  String get accountDetailHistoryEmpty => 'No financial activity yet.';

  @override
  String get accountArchive => 'Archive Account';

  @override
  String get accountArchiveConfirm =>
      'Are you sure you want to archive this account?';

  @override
  String get accountArchiveError =>
      'Cannot archive account with non-zero balance.';

  @override
  String get membersTitle => 'Family Members';

  @override
  String get memberPrimaryUser => 'Primary User';

  @override
  String get memberSpouse => 'Spouse';

  @override
  String get memberChild => 'Child';

  @override
  String get memberAddSpouse => 'Add Spouse';

  @override
  String get memberAddChild => 'Add Child';

  @override
  String get memberName => 'Name';

  @override
  String get memberRename => 'Rename';

  @override
  String get memberArchive => 'Archive Member';

  @override
  String get memberSpouseLoginNote =>
      'Note: Separate spouse login is not available in V1.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get protectedLabel => 'Protected';

  @override
  String get spendableLabel => 'Spendable';

  @override
  String get archivedLabel => 'Archived';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get balanceLabel => 'Balance';

  @override
  String get errorGeneric => 'An error occurred. Please try again.';

  @override
  String get errorAccountNameEmpty => 'Account name is required.';

  @override
  String get errorOpeningBalanceNegative =>
      'Opening balance cannot be negative.';

  @override
  String get errorAccountDuplicate => 'An account with this ID already exists.';

  @override
  String get errorArchiveNonzeroBalance =>
      'Cannot archive account with non-zero balance.';

  @override
  String get errorAccountAlreadyArchived => 'Account is already archived.';

  @override
  String get errorMemberNameEmpty => 'Member name is required.';

  @override
  String get errorSpouseDuplicate =>
      'A spouse is already registered for this household.';

  @override
  String get errorCannotArchivePrimaryUser =>
      'Cannot archive the primary user.';

  @override
  String get errorMemberAlreadyArchived => 'Member is already archived.';

  @override
  String get errorValidationGeneric => 'Invalid input. Please check the form.';

  @override
  String get errorMoneyInvalidFormat => 'Invalid amount format.';

  @override
  String get errorMoneyExcessDecimals =>
      'Too many decimal places for this currency.';

  @override
  String get errorMoneyOverflow => 'Amount is too large.';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get transactionsEmpty => 'No transactions yet.';

  @override
  String get transactionsFilterAll => 'All';

  @override
  String get transactionTypeIncome => 'Income';

  @override
  String get transactionTypeExpense => 'Expense';

  @override
  String get transactionTypeTransfer => 'Transfer';

  @override
  String get transactionTypeOpeningBalance => 'Opening Balance';

  @override
  String get transactionTypeAdjustment => 'Adjustment';

  @override
  String get transactionTypeReversal => 'Reversal';

  @override
  String get transactionReversed => 'Reversed';

  @override
  String get createTransactionTitle => 'New Transaction';

  @override
  String get createIncomeTitle => 'Record Income';

  @override
  String get createExpenseTitle => 'Record Expense';

  @override
  String get createTransferTitle => 'Transfer Money';

  @override
  String get incomeFormTitle => 'Income Details';

  @override
  String get expenseFormTitle => 'Expense Details';

  @override
  String get transferFormTitle => 'Transfer Details';

  @override
  String get reviewTitle => 'Review & Confirm';

  @override
  String get fieldDestinationAccount => 'Destination Account';

  @override
  String get fieldSourceAccount => 'Source Account';

  @override
  String get fieldPaymentAccount => 'Payment Account';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldSpender => 'Spender';

  @override
  String get fieldBeneficiary => 'Beneficiary';

  @override
  String get fieldScope => 'Scope';

  @override
  String get fieldEffectiveDate => 'Date';

  @override
  String get fieldNote => 'Note (optional)';

  @override
  String get fieldRecurring => 'Recurring';

  @override
  String get recurringOneTime => 'One-time';

  @override
  String get recurringYes => 'Recurring (scheduling not yet active)';

  @override
  String get scopePersonal => 'Personal';

  @override
  String get scopeSpouse => 'Spouse';

  @override
  String get scopeHousehold => 'Household';

  @override
  String get scopeChild => 'Child';

  @override
  String get catGroceries => 'Groceries';

  @override
  String get catHousing => 'Housing';

  @override
  String get catUtilities => 'Utilities';

  @override
  String get catTransportation => 'Transportation';

  @override
  String get catHealth => 'Health';

  @override
  String get catEducation => 'Education';

  @override
  String get catChildExpenses => 'Child Expenses';

  @override
  String get catPersonalSpending => 'Personal Spending';

  @override
  String get catSpouseSpending => 'Spouse Spending';

  @override
  String get catGiftsAndDonations => 'Gifts & Donations';

  @override
  String get catOtherExpense => 'Other Expense';

  @override
  String get catSalary => 'Salary';

  @override
  String get catBusinessIncome => 'Business Income';

  @override
  String get catGiftReceived => 'Gift Received';

  @override
  String get catInterestIncome => 'Interest Income';

  @override
  String get catOtherIncome => 'Other Income';

  @override
  String get protectedWithdrawalWarning =>
      'Warning: This is a protected fund. Withdrawals require justification.';

  @override
  String get fieldWithdrawalReason => 'Reason for withdrawal';

  @override
  String get fieldAcknowledgeWarning => 'I understand this is a protected fund';

  @override
  String get fieldConfirmWithdrawal => 'I confirm this withdrawal is necessary';

  @override
  String get errorCategoryRequired => 'Please select a category.';

  @override
  String get errorSpenderRequired => 'Please select a spender.';

  @override
  String get errorBeneficiaryRequired => 'Please select a beneficiary.';

  @override
  String get errorScopeRequired => 'Please select a scope.';

  @override
  String get errorInsufficientFunds =>
      'Insufficient funds in the selected account.';

  @override
  String get errorSameAccount =>
      'Source and destination must be different accounts.';

  @override
  String get errorCurrencyMismatch => 'Accounts must use the same currency.';

  @override
  String get errorAccountArchived =>
      'This account is archived and cannot receive new transactions.';

  @override
  String get errorWithdrawalReasonRequired =>
      'A non-empty reason is required for protected fund withdrawals.';

  @override
  String get errorWithdrawalAcknowledgmentRequired =>
      'You must acknowledge the protected fund warning.';

  @override
  String get errorWithdrawalConfirmationRequired =>
      'You must confirm the withdrawal.';

  @override
  String get spouseWalletSummaryTitle => 'Spouse Wallet Summary';

  @override
  String get spouseWalletFunded => 'Total Funded';

  @override
  String get spouseWalletSpent => 'Total Spent';

  @override
  String get spouseWalletReturned => 'Total Returned';

  @override
  String get spouseWalletDerivedBalance => 'Derived Balance';

  @override
  String get actionRecordIncome => 'Record Income';

  @override
  String get actionRecordExpense => 'Record Expense';

  @override
  String get actionTransfer => 'Transfer Money';

  @override
  String get transactionDetailTitle => 'Transaction Detail';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardSpendableBalances => 'Spendable Balances';

  @override
  String get dashboardProtectedBalances => 'Protected Balances';

  @override
  String get dashboardNoSpendable => 'No spendable accounts yet.';

  @override
  String get dashboardNoProtected => 'No protected accounts.';

  @override
  String get dashboardPeriodIncome => 'Income';

  @override
  String get dashboardPeriodExpenses => 'Expenses';

  @override
  String get dashboardPeriodNet => 'Net';

  @override
  String get dashboardPeriodNoActivity =>
      'No income or expense activity in this period.';

  @override
  String get dashboardScopePersonal => 'Personal Spending';

  @override
  String get dashboardScopeSpouse => 'Spouse Spending';

  @override
  String get dashboardScopeHousehold => 'Household Spending';

  @override
  String get dashboardScopeChild => 'Child Spending';

  @override
  String get dashboardScopeNoActivity =>
      'No expense scope data for this period.';

  @override
  String get dashboardSpouseWallet => 'Spouse Wallet';

  @override
  String get dashboardSpouseWalletFunded => 'Funded';

  @override
  String get dashboardSpouseWalletSpent => 'Spent';

  @override
  String get dashboardSpouseWalletReturned => 'Returned';

  @override
  String get dashboardSpouseWalletBalance => 'Current Balance';

  @override
  String get dashboardNoSpouseWallet => 'No spouse wallet found.';

  @override
  String get dashboardRecentActivity => 'Recent Activity';

  @override
  String get dashboardNoRecentActivity => 'No recent transactions.';

  @override
  String get dashboardViewAll => 'View all';

  @override
  String get dashboardPeriodCurrentMonth => 'This Month';

  @override
  String get dashboardPeriodPreviousMonth => 'Last Month';

  @override
  String get dashboardPeriodCurrentYear => 'This Year';

  @override
  String get dashboardPeriodCustom => 'Custom';

  @override
  String get dashboardNegativeBalanceWarning =>
      'Negative balance — data integrity issue';

  @override
  String get dashboardChildProtected => 'Child (Protected)';

  @override
  String get dashboardRefresh => 'Refresh';

  @override
  String get dashboardLoading => 'Loading dashboard...';

  @override
  String get dashboardError => 'Unable to load financial summary.';

  @override
  String get dashboardRetry => 'Retry';

  @override
  String get dashboardPeriodLabel => 'Period';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportIncomeExpenseTitle => 'Income & Expenses';

  @override
  String get reportAttributionTitle => 'Spending Attribution';

  @override
  String get reportCategoriesTitle => 'Categories';

  @override
  String get reportAccountsTitle => 'Account Flows';

  @override
  String get reportHomeSavingsTitle => 'Home Savings';

  @override
  String get reportSpouseWalletTitle => 'Spouse Wallet';

  @override
  String get reportProtectedFundsTitle => 'Protected Funds';

  @override
  String get reportGrossIncome => 'Gross Income';

  @override
  String get reportGrossExpense => 'Gross Expenses';

  @override
  String get reportNetIncome => 'Net Income';

  @override
  String get reportNetExpense => 'Net Expenses';

  @override
  String get reportReversalEffect => 'Reversal Effect';

  @override
  String get reportNetCashFlow => 'Net Cash Flow';

  @override
  String get reportSpenderSection => 'By Spender';

  @override
  String get reportBeneficiarySection => 'By Beneficiary';

  @override
  String get reportScopeSection => 'By Scope';

  @override
  String get reportOpeningBalance => 'Opening Balance';

  @override
  String get reportClosingBalance => 'Closing Balance';

  @override
  String get reportCurrentBalance => 'Current Balance';

  @override
  String get reportFunded => 'Funded';

  @override
  String get reportSpent => 'Spent';

  @override
  String get reportReturned => 'Returned';

  @override
  String get reportWithdrawals => 'Withdrawals';

  @override
  String get reportWithdrawalReason => 'Reason';

  @override
  String get reportBeneficiary => 'Beneficiary';

  @override
  String get reportDrillDown => 'View Transactions';

  @override
  String get reportEmpty => 'No data for this period.';

  @override
  String get reportError => 'Unable to load report.';

  @override
  String get reportRefresh => 'Refresh';

  @override
  String get reportCurrencySeparate => 'Totals shown per currency';

  @override
  String get reportTransferNote =>
      'Transfers are not included in income or expense totals.';

  @override
  String get reportReversalNote => 'Reversal effects are shown separately.';

  @override
  String get reportPeriodClosingBalance => 'Period Closing Balance';

  @override
  String get reportAuditDrillDown => 'View Audit';

  @override
  String reportTransactionCount(int count) {
    return '$count transactions';
  }

  @override
  String get reportViewReports => 'View Reports';

  @override
  String get onboardingSubtitle => 'Welcome! Enter your name to get started.';

  @override
  String get onboardingNameLabel => 'Your name';

  @override
  String get onboardingNameHint => 'e.g. Ahmed';

  @override
  String get onboardingStartButton => 'Start';

  @override
  String get onboardingGenericError => 'An error occurred. Please try again.';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetNew => 'New Budget';

  @override
  String get budgetName => 'Budget name';

  @override
  String get budgetCurrency => 'Currency';

  @override
  String get budgetLimit => 'Monthly limit';

  @override
  String get budgetLimitFixed => 'Budget limit';

  @override
  String get budgetPeriodMonthly => 'Monthly (recurring)';

  @override
  String get budgetPeriodFixed => 'Fixed period';

  @override
  String get budgetStartDate => 'Start date';

  @override
  String get budgetEndDate => 'End date';

  @override
  String get budgetCategoryFilter => 'Category (optional)';

  @override
  String get budgetScopeFilter => 'Scope (optional)';

  @override
  String get budgetSpenderFilter => 'Spender (optional)';

  @override
  String get budgetBeneficiaryFilter => 'Beneficiary (optional)';

  @override
  String get budgetAccountFilter => 'Payment account (optional)';

  @override
  String get budgetOverlapNote =>
      'Budgets may overlap — each is monitored independently';

  @override
  String get budgetStatusNoSpending => 'No spending';

  @override
  String get budgetStatusOnTrack => 'On track';

  @override
  String get budgetStatusNearLimit => 'Near limit';

  @override
  String get budgetStatusLimitReached => 'Limit reached';

  @override
  String get budgetStatusOverBudget => 'Over budget';

  @override
  String get budgetConsumed => 'Spent';

  @override
  String get budgetRemaining => 'Remaining';

  @override
  String budgetPercent(int percent) {
    return '$percent% used';
  }

  @override
  String get budgetReversalNote =>
      'Fully reversed expenses count as zero toward this budget';

  @override
  String get budgetEmpty => 'No budgets yet. Create one to start planning.';

  @override
  String get budgetArchived => 'Archived';

  @override
  String get budgetArchive => 'Archive budget';

  @override
  String get budgetRestore => 'Restore budget';

  @override
  String get budgetPreviousPeriods => 'Previous periods';

  @override
  String get budgetNoMatching => 'No matching expenses in this period';

  @override
  String get errorBudgetNameEmpty => 'Budget name is required';

  @override
  String get errorBudgetLimitZero => 'Budget limit must be greater than zero';

  @override
  String get errorBudgetEndBeforeStart => 'End date must be after start date';

  @override
  String get errorBudgetCurrencyRequired => 'Currency is required';

  @override
  String get goalsTitle => 'Goals';

  @override
  String get goalNew => 'New Goal';

  @override
  String get goalName => 'Goal name';

  @override
  String get goalPurpose => 'Purpose';

  @override
  String get goalCurrency => 'Currency';

  @override
  String get goalTarget => 'Target amount';

  @override
  String get goalTargetDate => 'Target date (optional)';

  @override
  String get goalBeneficiary => 'Beneficiary (optional)';

  @override
  String get goalInitialFunding => 'Initial funding (optional)';

  @override
  String get goalInitialFundingSource => 'Source account';

  @override
  String get goalInitialFundingAmount => 'Initial amount';

  @override
  String get goalStatusActive => 'Active';

  @override
  String get goalStatusTargetReached => 'Target reached';

  @override
  String get goalStatusCompleted => 'Completed';

  @override
  String get goalStatusArchived => 'Archived';

  @override
  String get goalProgressNotStarted => 'Not started';

  @override
  String get goalProgressInProgress => 'In progress';

  @override
  String get goalProgressTargetReached => 'Target reached';

  @override
  String get goalProgressOverfunded => 'Overfunded';

  @override
  String get goalReserveBalance => 'Reserved';

  @override
  String get goalRemaining => 'Remaining';

  @override
  String get goalOverfunded => 'Overfunded by';

  @override
  String goalPercent(int percent) {
    return '$percent% funded';
  }

  @override
  String get goalFundAction => 'Add funds';

  @override
  String get goalReleaseAction => 'Release funds';

  @override
  String get goalCompleteAction => 'Mark as complete';

  @override
  String get goalArchiveAction => 'Archive';

  @override
  String get goalRestoreAction => 'Restore';

  @override
  String get goalReleaseReason => 'Release reason';

  @override
  String get goalMovementFunding => 'Funding';

  @override
  String get goalMovementRelease => 'Release';

  @override
  String get goalRevisions => 'History';

  @override
  String get goalChildFundNote => 'Goal funds are NOT child-protected money';

  @override
  String get goalTransferNote =>
      'This is an internal transfer — not an expense';

  @override
  String get goalReleaseTransferNote =>
      'This is an internal transfer — not income';

  @override
  String get goalEmpty => 'No goals yet. Create one to start saving.';

  @override
  String get purposeEmergencyFund => 'Emergency fund';

  @override
  String get purposeHomePurchase => 'Home purchase';

  @override
  String get purposeEducation => 'Education';

  @override
  String get purposeTravel => 'Travel';

  @override
  String get purposeMajorPurchase => 'Major purchase';

  @override
  String get purposeFamilyEvent => 'Family event';

  @override
  String get purposeOther => 'Other';

  @override
  String get errorGoalNameEmpty => 'Goal name is required';

  @override
  String get errorGoalTargetZero => 'Target amount must be greater than zero';

  @override
  String get errorGoalCurrencyRequired => 'Currency is required';

  @override
  String get errorGoalReleaseReasonEmpty => 'Release reason is required';

  @override
  String get errorGoalInsufficientReserve =>
      'Insufficient balance in goal reserve';

  @override
  String get errorGoalArchiveNonzeroBalance =>
      'Cannot archive a goal with remaining funds. Release all funds first.';

  @override
  String get errorGoalSourceIsProtected =>
      'Funding from a protected child account is not allowed';

  @override
  String get errorGoalSourceIsReserve =>
      'Cannot fund a goal from another goal reserve';

  @override
  String get errorGoalSourceNotSpendable =>
      'Goal funding requires a spendable account';

  @override
  String get errorGoalDestinationNotSpendable =>
      'Goal release requires a spendable destination account';

  @override
  String get goalFundTitle => 'Add Funds to Goal';

  @override
  String get goalReleaseTitle => 'Release Goal Funds';

  @override
  String get goalSourceAccount => 'Source account';

  @override
  String get goalDestinationAccount => 'Destination account';

  @override
  String get goalAmount => 'Amount';

  @override
  String get goalProjectedBalance => 'Projected balance';

  @override
  String get goalReservedBalances => 'Goal reserves';

  @override
  String get certificatesTitle => 'Certificates';

  @override
  String get certificateNew => 'New Certificate';

  @override
  String get certificateEmpty =>
      'No certificates yet. Add one to track your fixed-term deposits.';

  @override
  String get certificateInstitution => 'Institution';

  @override
  String get certificatePrincipal => 'Principal';

  @override
  String get certificateProfit => 'Profit';

  @override
  String get certificateMaturityDate => 'Maturity date';

  @override
  String get certificateStartDate => 'Start date';

  @override
  String get certificateReference => 'Reference / certificate number';

  @override
  String get certificateAnnualRate => 'Annual rate (basis points)';

  @override
  String get certificateProfitFrequency => 'Profit frequency';

  @override
  String get certificateSourceAccount => 'Funding source account';

  @override
  String get certificateDestinationAccount => 'Destination account';

  @override
  String get certificateRedeem => 'Redeem';

  @override
  String get certificateRedeemTitle => 'Redeem Certificate';

  @override
  String get certificateProfitTitle => 'Record Profit';

  @override
  String get certificateRecordProfit => 'Record Profit';

  @override
  String get certificateLifecycleActive => 'Active';

  @override
  String get certificateLifecycleRedeemed => 'Redeemed';

  @override
  String get certificateLifecycleArchived => 'Archived';

  @override
  String get certificateTermNotStarted => 'Not Started';

  @override
  String get certificateTermActive => 'Active Term';

  @override
  String get certificateTermMatured => 'Matured';

  @override
  String get certificateTermOverdue => 'Overdue Redemption';

  @override
  String get certificateTermFullyRedeemed => 'Fully Redeemed';

  @override
  String get certificateProfitFreqMonthly => 'Monthly';

  @override
  String get certificateProfitFreqQuarterly => 'Quarterly';

  @override
  String get certificateProfitFreqSemiAnnual => 'Semi-Annual';

  @override
  String get certificateProfitFreqAnnual => 'Annual';

  @override
  String get certificateProfitFreqAtMaturity => 'At Maturity';

  @override
  String get certificateProfitFreqOther => 'Other';

  @override
  String get certificatePrincipalBalance => 'Principal balance';

  @override
  String get certificateOriginalPrincipal => 'Original principal';

  @override
  String get certificateNote => 'Note';

  @override
  String get certificateAmount => 'Amount';

  @override
  String get certificatePrincipalSection => 'Principal';

  @override
  String get certificateProfitSection => 'Profit';

  @override
  String get certificateRedeemPrincipalOnly => 'Principal only';

  @override
  String get certificateRedeemProfitOnly => 'Profit only';

  @override
  String get certificateRedeemCombined => 'Principal + profit';

  @override
  String get certificateReviewTitle => 'Review Certificate';

  @override
  String get catCertificateProfit => 'Certificate Profit';

  @override
  String get errorCertificateInstitutionRequired =>
      'Institution name is required';

  @override
  String get errorCertificatePrincipalZero =>
      'Principal must be greater than zero';

  @override
  String get errorCertificateCurrencyRequired => 'Currency is required';

  @override
  String get errorCertificateDatesRequired =>
      'Start and maturity dates are required';

  @override
  String get errorCertificateMaturityBeforeStart =>
      'Maturity date must be after start date';

  @override
  String get errorCertificateSourceRequired =>
      'Funding source account is required';

  @override
  String get errorCertificateSourceIsProtected =>
      'Funding from a protected child account is not allowed';

  @override
  String get errorCertificateAccountNotAllowedAsSource =>
      'A certificate account cannot be used as a funding source';

  @override
  String get errorCertificateAccountNotAllowedAsDestination =>
      'A certificate account cannot be used as a destination';

  @override
  String get errorCertificateAccountNotAllowedInOrdinaryTransaction =>
      'Certificate accounts cannot be used in ordinary transactions';

  @override
  String get errorCertificateArchived => 'Certificate is archived';

  @override
  String get errorCertificateNotActive => 'Certificate is not active';

  @override
  String get errorCertificateArchiveNonzeroBalance =>
      'Cannot archive a certificate with remaining principal. Redeem first.';

  @override
  String get errorCertificateRestoreRequiresArchived =>
      'Certificate must be archived to restore';

  @override
  String get errorCertificateIdempotencyConflict =>
      'Duplicate certificate creation conflict';

  @override
  String get errorCertificateReversalRequiresActive =>
      'Certificate must be active to reverse purchase';

  @override
  String get errorCertificateReversalNotAllowedAfterHistory =>
      'Cannot reverse purchase after profit or redemption';

  @override
  String get errorCertificateProfitReversalInvalidType =>
      'Target operation is not a profit income operation';

  @override
  String get errorCertificateRedemptionReversalNotSupported =>
      'Redemption reversal is not supported';

  @override
  String get errorCertificateNotMatured =>
      'Certificate has not reached maturity';

  @override
  String get errorCertificateNoPrincipal =>
      'Certificate has no remaining principal to redeem';

  @override
  String get errorCertificateFullRedemptionOnly =>
      'Only full principal redemption is supported';

  @override
  String get navHome => 'Home';

  @override
  String get navPlanning => 'Planning';

  @override
  String get navReports => 'Reports';

  @override
  String get navMore => 'More';

  @override
  String get planningTitle => 'Planning';

  @override
  String get planningSubtitle => 'Budgets, goals, and certificates';

  @override
  String get moreTitle => 'More';

  @override
  String get moreSubtitle => 'Accounts, family, and settings';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get dashboardNeedsAttention => 'Needs attention';

  @override
  String get dashboardHeldBalances => 'Held balances';

  @override
  String get dashboardCertificatePrincipal => 'Certificate principal';

  @override
  String get accountRestrictionCertificate =>
      'Certificate principal — certificate workflows only';

  @override
  String get accountRestrictionGoalReserve =>
      'Goal reserve — manage through goals';

  @override
  String get accountRestrictionProtected =>
      'Protected — withdrawal restrictions apply';

  @override
  String get formSectionAmount => 'Amount';

  @override
  String get formSectionAccount => 'Account';

  @override
  String get formSectionCategory => 'Category';

  @override
  String get formSectionAttribution => 'Attribution';

  @override
  String get formAdvancedDetails => 'More details';

  @override
  String get operationTypeIncome => 'Income';

  @override
  String get operationTypeExpense => 'Expense';

  @override
  String get operationTypeTransfer => 'Transfer';

  @override
  String get fieldOperationType => 'Operation type';

  @override
  String get transferInternalExplanation =>
      'This is an internal transfer. The source balance decreases and the destination balance increases. It is not income and not an expense.';

  @override
  String get incomeIncreasesBalance =>
      'This income increases the destination account balance.';

  @override
  String get expenseDecreasesBalance =>
      'This expense decreases the payment account balance.';

  @override
  String get protectedWithdrawalReviewNote =>
      'Protected balance decreases. Reason and beneficiary are recorded and remain auditable.';

  @override
  String get retryAction => 'Retry';

  @override
  String get budgetDoesNotHoldMoney =>
      'Budgets monitor spending. They do not hold money and do not block expenses.';

  @override
  String get budgetOverlapIndependent =>
      'Overlapping budgets are monitored independently.';

  @override
  String get budgetRestatedReversals =>
      'Reversed expenses use the documented restated budget view.';

  @override
  String get goalReserveDedicated =>
      'A dedicated reserve account is created for this goal. Funding is an internal transfer — total assets do not increase.';

  @override
  String get goalNotChildProtected =>
      'Goal funds are not protected child funds.';

  @override
  String get goalCurrencyImmutable => 'Currency cannot change after creation.';

  @override
  String get certificatePrincipalNotExpense =>
      'Moving principal into a certificate is not an expense.';

  @override
  String get certificatePrincipalReturnNotIncome =>
      'Returning principal is not income.';

  @override
  String get filterClearAll => 'Clear all';

  @override
  String filterActiveCount(int count) {
    return '$count filters active';
  }

  @override
  String get lifecycleStatusLabel => 'Lifecycle';

  @override
  String get progressStatusLabel => 'Progress';

  @override
  String get errorAccountRequired => 'Account is required.';

  @override
  String get errorAmountMustBePositive => 'Amount must be greater than zero.';

  @override
  String get errorDateInvalid => 'Please enter a valid date.';

  @override
  String get errorHouseholdAlreadyInitialized =>
      'This household is already set up.';

  @override
  String get errorHouseholdIdEmpty => 'Household ID is required.';

  @override
  String get errorBudgetIdempotencyConflict =>
      'Duplicate budget creation conflict.';

  @override
  String get errorBudgetDatesRequired => 'Please select start and end dates.';

  @override
  String get errorBudgetDuplicate =>
      'A budget with this configuration already exists.';

  @override
  String get errorBudgetCreateFailed => 'Failed to create budget.';

  @override
  String get budgetPeriodTypeLabel => 'Period type';

  @override
  String get errorCertificateSourceInvalid =>
      'Selected funding source is not allowed.';

  @override
  String get errorEarlyCompletionConfirmationRequired =>
      'Early completion must be confirmed.';

  @override
  String get errorEarlyCompletionReasonRequired =>
      'Early completion reason is required.';

  @override
  String get errorGoalArchived => 'This goal is archived.';

  @override
  String get errorGoalIdempotencyConflict =>
      'Duplicate goal operation conflict.';

  @override
  String get errorGoalLifecycleRequiresTypedWorkflow =>
      'This lifecycle change requires the goal workflow screen.';

  @override
  String get errorGoalNormalCompletionRequiresTarget =>
      'Goal must reach its target before normal completion.';

  @override
  String get errorGoalNotActive => 'Goal is not active.';

  @override
  String get errorGoalReserveNotAllowedInOrdinaryTransaction =>
      'Goal reserve accounts cannot be used in ordinary transactions.';

  @override
  String get errorGoalRestoreRequiresArchived =>
      'Goal must be archived to restore.';

  @override
  String get errorGoalReversalInvalidMovement =>
      'This operation cannot be reversed for goals.';

  @override
  String get errorLifecycleEventConflict =>
      'Lifecycle event conflict. Refresh and try again.';

  @override
  String get errorOperationAlreadyReversed =>
      'This operation has already been reversed.';

  @override
  String get errorGoalSourceAccountRequired =>
      'Please select a source account.';

  @override
  String get errorGoalDestinationAccountRequired =>
      'Please select a destination account.';

  @override
  String get goalNotFound => 'Goal not found.';

  @override
  String get errorPageNotFound => 'Page not found.';

  @override
  String get goHome => 'Go home';

  @override
  String get certificateCurrency => 'Currency';

  @override
  String get errorUnexpected => 'An unexpected error occurred.';

  @override
  String get accountTypeGoalReserve => 'Goal Reserve';

  @override
  String get accountTypeCertificate => 'Certificate Account';

  @override
  String get accountTypeGoldHolding => 'Gold Holding';

  @override
  String get accountTypeInvestment => 'Investment Account';

  @override
  String get accountTypeOtherAsset => 'Other Asset';

  @override
  String get transactionTypeAssetPurchase => 'Asset Purchase';

  @override
  String get transactionTypeAssetSale => 'Asset Sale';

  @override
  String get transactionTypeLiabilityCreation => 'Liability Created';

  @override
  String get transactionTypeLiabilityRepayment => 'Liability Repayment';

  @override
  String get transactionTypeCertificateFunding => 'Certificate Funding';

  @override
  String get transactionTypeCertificateMaturity => 'Certificate Maturity';

  @override
  String get transactionTypeInterestIncome => 'Interest Income';

  @override
  String get transactionTypeGoldPurchase => 'Gold Purchase';

  @override
  String get transactionTypeGoldSale => 'Gold Sale';

  @override
  String get transactionTypeGoalFunding => 'Goal Funding';

  @override
  String get transactionTypeGoalWithdrawal => 'Goal Withdrawal';

  @override
  String get transactionTypeChildFundDeposit => 'Child Fund Deposit';

  @override
  String get transactionTypeChildFundWithdrawal => 'Child Fund Withdrawal';

  @override
  String get transactionTypeSadaqah => 'Sadaqah';

  @override
  String get transactionTypeZakat => 'Zakat';

  @override
  String get scopeShared => 'Shared';

  @override
  String get dashboardScopeShared => 'Shared Spending';

  @override
  String get certificateEventCreated => 'Created';

  @override
  String get certificateEventPurchased => 'Purchased';

  @override
  String get certificateEventProfitReceived => 'Profit Received';

  @override
  String get certificateEventRedeemed => 'Redeemed';

  @override
  String get certificateEventArchived => 'Archived';

  @override
  String get certificateEventRestored => 'Restored';

  @override
  String get certificateEventDefinitionRevised => 'Definition Revised';

  @override
  String get certificateEventPurchaseReversed => 'Purchase Reversed';

  @override
  String get certificateEventProfitReversed => 'Profit Reversed';

  @override
  String get currencyEgp => 'Egyptian Pound (EGP)';

  @override
  String get currencyUsd => 'US Dollar (USD)';

  @override
  String get currencyEur => 'Euro (EUR)';

  @override
  String get currencyGbp => 'British Pound (GBP)';

  @override
  String get currencySar => 'Saudi Riyal (SAR)';

  @override
  String get currencyAed => 'UAE Dirham (AED)';

  @override
  String get currencyJpy => 'Japanese Yen (JPY)';

  @override
  String get currencyKwd => 'Kuwaiti Dinar (KWD)';

  @override
  String get currencyBhd => 'Bahraini Dinar (BHD)';

  @override
  String get currencyOmr => 'Omani Rial (OMR)';
}
