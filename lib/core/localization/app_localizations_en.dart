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
}
