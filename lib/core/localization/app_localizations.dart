import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The main application title shown in the header and title bar.
  ///
  /// In en, this message translates to:
  /// **'Family Money Manager'**
  String get appTitle;

  /// Title shown on the Phase 1 smoke screen.
  ///
  /// In en, this message translates to:
  /// **'Foundation Phase'**
  String get foundationTitle;

  /// Subtitle on the Phase 1 smoke screen.
  ///
  /// In en, this message translates to:
  /// **'Project infrastructure is ready.'**
  String get foundationSubtitle;

  /// Label for the language selector on the smoke screen.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get foundationLanguageLabel;

  /// Label for the theme toggle on the smoke screen.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get foundationThemeLabel;

  /// Label showing the current text direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get foundationDirectionLabel;

  /// Button text to switch the language to Arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get foundationSwitchToArabic;

  /// Button text to switch the language to English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get foundationSwitchToEnglish;

  /// Label for the light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get foundationThemeLight;

  /// Label for the dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get foundationThemeDark;

  /// Label indicating left-to-right text direction.
  ///
  /// In en, this message translates to:
  /// **'LTR'**
  String get foundationDirectionLtr;

  /// Label indicating right-to-left text direction.
  ///
  /// In en, this message translates to:
  /// **'RTL'**
  String get foundationDirectionRtl;

  /// Informational note on the smoke screen explaining the current phase.
  ///
  /// In en, this message translates to:
  /// **'No financial features exist yet. Phase 2 will introduce the ledger.'**
  String get foundationNote;

  /// User-facing message for a network error.
  ///
  /// In en, this message translates to:
  /// **'A network error occurred. Please check your connection and try again.'**
  String get errorNetwork;

  /// User-facing message for an authentication error.
  ///
  /// In en, this message translates to:
  /// **'Your session is invalid. Please sign in again.'**
  String get errorAuth;

  /// User-facing message for a local storage error.
  ///
  /// In en, this message translates to:
  /// **'A local storage error occurred. Please try again.'**
  String get errorStorage;

  /// User-facing message for an unknown error.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorUnknown;

  /// Title for the typed-route parameter demo screen (Phase 1 only).
  ///
  /// In en, this message translates to:
  /// **'Foundation Detail'**
  String get foundationDetailTitle;

  /// Label showing the typed-route probe parameter on the detail screen.
  ///
  /// In en, this message translates to:
  /// **'Probe: {probeId}'**
  String foundationDetailProbeLabel(String probeId);

  /// Bottom navigation label for accounts tab.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// Bottom navigation label for family members tab.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get navMembers;

  /// Bottom navigation label for settings tab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Title for the accounts screen.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// Empty-state message on the accounts screen.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Create your first account.'**
  String get accountsEmpty;

  /// FAB label to create a new account.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get accountsAddButton;

  /// Label for the total spendable amount.
  ///
  /// In en, this message translates to:
  /// **'Total Spendable'**
  String get accountsTotalSpendable;

  /// Label for the total protected amount.
  ///
  /// In en, this message translates to:
  /// **'Total Protected'**
  String get accountsTotalProtected;

  /// Account type label.
  ///
  /// In en, this message translates to:
  /// **'Personal Cash Wallet'**
  String get accountTypePersonalCash;

  /// Account type label.
  ///
  /// In en, this message translates to:
  /// **'Spouse Cash Wallet'**
  String get accountTypeSpouseCash;

  /// Account type label.
  ///
  /// In en, this message translates to:
  /// **'Household Cash'**
  String get accountTypeHouseholdCash;

  /// Account type label.
  ///
  /// In en, this message translates to:
  /// **'Home Savings'**
  String get accountTypeHomeSavings;

  /// Account type label.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get accountTypeBankAccount;

  /// Account type label.
  ///
  /// In en, this message translates to:
  /// **'Mobile Wallet'**
  String get accountTypeMobileWallet;

  /// Account type label.
  ///
  /// In en, this message translates to:
  /// **'Protected Child Fund'**
  String get accountTypeChildFund;

  /// Title for the account creation screen.
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get accountCreateTitle;

  /// Label for the account name field.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// Label for the account owner field.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get accountOwner;

  /// Label for the currency field.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountCurrency;

  /// Label for the optional opening balance field.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get accountOpeningBalance;

  /// Label for the optional notes field.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get accountNotes;

  /// Warning shown for protected accounts.
  ///
  /// In en, this message translates to:
  /// **'This is a protected account. Funds are not available for ordinary spending.'**
  String get accountProtectedWarning;

  /// Confirmation dialog title for child fund.
  ///
  /// In en, this message translates to:
  /// **'Confirm Child Fund Creation'**
  String get accountChildFundConfirmTitle;

  /// Confirmation dialog body for child fund.
  ///
  /// In en, this message translates to:
  /// **'Funds in this account will be protected and dedicated to the child. They cannot be used for ordinary spending.'**
  String get accountChildFundConfirmBody;

  /// Title for the account detail screen.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetailTitle;

  /// Label for the current balance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get accountDetailBalance;

  /// Section heading for financial history.
  ///
  /// In en, this message translates to:
  /// **'Financial History'**
  String get accountDetailHistory;

  /// Empty-state message for financial history.
  ///
  /// In en, this message translates to:
  /// **'No financial activity yet.'**
  String get accountDetailHistoryEmpty;

  /// Action label to archive an account.
  ///
  /// In en, this message translates to:
  /// **'Archive Account'**
  String get accountArchive;

  /// Archive confirmation dialog message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to archive this account?'**
  String get accountArchiveConfirm;

  /// Error shown when archiving fails due to non-zero balance.
  ///
  /// In en, this message translates to:
  /// **'Cannot archive account with non-zero balance.'**
  String get accountArchiveError;

  /// Title for the household members screen.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get membersTitle;

  /// Role label for primary user.
  ///
  /// In en, this message translates to:
  /// **'Primary User'**
  String get memberPrimaryUser;

  /// Role label for spouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get memberSpouse;

  /// Role label for child.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get memberChild;

  /// Action to add a spouse member.
  ///
  /// In en, this message translates to:
  /// **'Add Spouse'**
  String get memberAddSpouse;

  /// Action to add a child member.
  ///
  /// In en, this message translates to:
  /// **'Add Child'**
  String get memberAddChild;

  /// Label for the member name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get memberName;

  /// Action to rename a member.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get memberRename;

  /// Action to archive a member.
  ///
  /// In en, this message translates to:
  /// **'Archive Member'**
  String get memberArchive;

  /// Note about spouse login not being supported in V1.
  ///
  /// In en, this message translates to:
  /// **'Note: Separate spouse login is not available in V1.'**
  String get memberSpouseLoginNote;

  /// Title for the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Generic save button label.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic cancel button label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic confirm button label.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Badge label for protected accounts.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get protectedLabel;

  /// Badge label for spendable accounts.
  ///
  /// In en, this message translates to:
  /// **'Spendable'**
  String get spendableLabel;

  /// Badge label for archived accounts.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedLabel;

  /// Generic loading indicator label.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// Generic balance label.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceLabel;

  /// Generic error message.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorGeneric;

  /// Validation error when account name is empty.
  ///
  /// In en, this message translates to:
  /// **'Account name is required.'**
  String get errorAccountNameEmpty;

  /// Validation error for negative opening balance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance cannot be negative.'**
  String get errorOpeningBalanceNegative;

  /// Error when a duplicate account ID is used.
  ///
  /// In en, this message translates to:
  /// **'An account with this ID already exists.'**
  String get errorAccountDuplicate;

  /// Error when archiving an account with non-zero balance.
  ///
  /// In en, this message translates to:
  /// **'Cannot archive account with non-zero balance.'**
  String get errorArchiveNonzeroBalance;

  /// Error when account is already archived.
  ///
  /// In en, this message translates to:
  /// **'Account is already archived.'**
  String get errorAccountAlreadyArchived;

  /// Validation error when member name is empty.
  ///
  /// In en, this message translates to:
  /// **'Member name is required.'**
  String get errorMemberNameEmpty;

  /// Error when adding a second spouse.
  ///
  /// In en, this message translates to:
  /// **'A spouse is already registered for this household.'**
  String get errorSpouseDuplicate;

  /// Error when archiving the primary user.
  ///
  /// In en, this message translates to:
  /// **'Cannot archive the primary user.'**
  String get errorCannotArchivePrimaryUser;

  /// Error when member is already archived.
  ///
  /// In en, this message translates to:
  /// **'Member is already archived.'**
  String get errorMemberAlreadyArchived;

  /// Generic validation failure message.
  ///
  /// In en, this message translates to:
  /// **'Invalid input. Please check the form.'**
  String get errorValidationGeneric;

  /// Error when money input has invalid format.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount format.'**
  String get errorMoneyInvalidFormat;

  /// Error when money input has too many decimal places.
  ///
  /// In en, this message translates to:
  /// **'Too many decimal places for this currency.'**
  String get errorMoneyExcessDecimals;

  /// Error when money input overflows.
  ///
  /// In en, this message translates to:
  /// **'Amount is too large.'**
  String get errorMoneyOverflow;

  /// Bottom navigation label for transactions tab.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// Title for the transactions screen.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// Empty-state message on the transactions screen.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get transactionsEmpty;

  /// Filter option to show all transaction types.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transactionsFilterAll;

  /// Label for income operation type.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionTypeIncome;

  /// Label for expense operation type.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionTypeExpense;

  /// Label for transfer operation type.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionTypeTransfer;

  /// Label for opening balance operation type.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get transactionTypeOpeningBalance;

  /// Label for adjustment operation type.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get transactionTypeAdjustment;

  /// Label for reversal operation type.
  ///
  /// In en, this message translates to:
  /// **'Reversal'**
  String get transactionTypeReversal;

  /// Badge shown on reversed transactions.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get transactionReversed;

  /// Title for the create transaction screen.
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get createTransactionTitle;

  /// Action to record income.
  ///
  /// In en, this message translates to:
  /// **'Record Income'**
  String get createIncomeTitle;

  /// Action to record expense.
  ///
  /// In en, this message translates to:
  /// **'Record Expense'**
  String get createExpenseTitle;

  /// Action to transfer money.
  ///
  /// In en, this message translates to:
  /// **'Transfer Money'**
  String get createTransferTitle;

  /// Title for the income form screen.
  ///
  /// In en, this message translates to:
  /// **'Income Details'**
  String get incomeFormTitle;

  /// Title for the expense form screen.
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get expenseFormTitle;

  /// Title for the transfer form screen.
  ///
  /// In en, this message translates to:
  /// **'Transfer Details'**
  String get transferFormTitle;

  /// Title for review screens.
  ///
  /// In en, this message translates to:
  /// **'Review & Confirm'**
  String get reviewTitle;

  /// Label for destination account field.
  ///
  /// In en, this message translates to:
  /// **'Destination Account'**
  String get fieldDestinationAccount;

  /// Label for source account field.
  ///
  /// In en, this message translates to:
  /// **'Source Account'**
  String get fieldSourceAccount;

  /// Label for payment account field.
  ///
  /// In en, this message translates to:
  /// **'Payment Account'**
  String get fieldPaymentAccount;

  /// Label for amount field.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// Label for category field.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// Label for spender field.
  ///
  /// In en, this message translates to:
  /// **'Spender'**
  String get fieldSpender;

  /// Label for beneficiary field.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary'**
  String get fieldBeneficiary;

  /// Label for expense scope field.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get fieldScope;

  /// Label for effective date field.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldEffectiveDate;

  /// Label for optional note field.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get fieldNote;

  /// Label for recurring toggle.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get fieldRecurring;

  /// Label for one-time (non-recurring) option.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get recurringOneTime;

  /// Label for recurring option with disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Recurring (scheduling not yet active)'**
  String get recurringYes;

  /// Expense scope: personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get scopePersonal;

  /// Expense scope: spouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get scopeSpouse;

  /// Expense scope: household.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get scopeHousehold;

  /// Expense scope: child.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get scopeChild;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get catGroceries;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get catHousing;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get catUtilities;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get catTransportation;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducation;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Child Expenses'**
  String get catChildExpenses;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Personal Spending'**
  String get catPersonalSpending;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Spouse Spending'**
  String get catSpouseSpending;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Gifts & Donations'**
  String get catGiftsAndDonations;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Other Expense'**
  String get catOtherExpense;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get catSalary;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Business Income'**
  String get catBusinessIncome;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Gift Received'**
  String get catGiftReceived;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Interest Income'**
  String get catInterestIncome;

  /// Category label.
  ///
  /// In en, this message translates to:
  /// **'Other Income'**
  String get catOtherIncome;

  /// Warning for protected-fund withdrawals.
  ///
  /// In en, this message translates to:
  /// **'Warning: This is a protected fund. Withdrawals require justification.'**
  String get protectedWithdrawalWarning;

  /// Label for withdrawal reason field.
  ///
  /// In en, this message translates to:
  /// **'Reason for withdrawal'**
  String get fieldWithdrawalReason;

  /// Acknowledgement checkbox label.
  ///
  /// In en, this message translates to:
  /// **'I understand this is a protected fund'**
  String get fieldAcknowledgeWarning;

  /// Confirmation checkbox label.
  ///
  /// In en, this message translates to:
  /// **'I confirm this withdrawal is necessary'**
  String get fieldConfirmWithdrawal;

  /// Validation error for missing category.
  ///
  /// In en, this message translates to:
  /// **'Please select a category.'**
  String get errorCategoryRequired;

  /// Validation error for missing spender.
  ///
  /// In en, this message translates to:
  /// **'Please select a spender.'**
  String get errorSpenderRequired;

  /// Validation error for missing beneficiary.
  ///
  /// In en, this message translates to:
  /// **'Please select a beneficiary.'**
  String get errorBeneficiaryRequired;

  /// Validation error for missing scope.
  ///
  /// In en, this message translates to:
  /// **'Please select a scope.'**
  String get errorScopeRequired;

  /// Error when account has insufficient funds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds in the selected account.'**
  String get errorInsufficientFunds;

  /// Error when source and destination are the same.
  ///
  /// In en, this message translates to:
  /// **'Source and destination must be different accounts.'**
  String get errorSameAccount;

  /// Error when accounts have different currencies.
  ///
  /// In en, this message translates to:
  /// **'Accounts must use the same currency.'**
  String get errorCurrencyMismatch;

  /// Error when account is archived.
  ///
  /// In en, this message translates to:
  /// **'This account is archived and cannot receive new transactions.'**
  String get errorAccountArchived;

  /// Error when withdrawal reason is empty.
  ///
  /// In en, this message translates to:
  /// **'A non-empty reason is required for protected fund withdrawals.'**
  String get errorWithdrawalReasonRequired;

  /// Error when warning not acknowledged.
  ///
  /// In en, this message translates to:
  /// **'You must acknowledge the protected fund warning.'**
  String get errorWithdrawalAcknowledgmentRequired;

  /// Error when withdrawal not confirmed.
  ///
  /// In en, this message translates to:
  /// **'You must confirm the withdrawal.'**
  String get errorWithdrawalConfirmationRequired;

  /// Title for spouse wallet summary section.
  ///
  /// In en, this message translates to:
  /// **'Spouse Wallet Summary'**
  String get spouseWalletSummaryTitle;

  /// Label for total funded amount.
  ///
  /// In en, this message translates to:
  /// **'Total Funded'**
  String get spouseWalletFunded;

  /// Label for total spent amount.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get spouseWalletSpent;

  /// Label for total returned amount.
  ///
  /// In en, this message translates to:
  /// **'Total Returned'**
  String get spouseWalletReturned;

  /// Label for derived balance.
  ///
  /// In en, this message translates to:
  /// **'Derived Balance'**
  String get spouseWalletDerivedBalance;

  /// Action button to record income.
  ///
  /// In en, this message translates to:
  /// **'Record Income'**
  String get actionRecordIncome;

  /// Action button to record expense.
  ///
  /// In en, this message translates to:
  /// **'Record Expense'**
  String get actionRecordExpense;

  /// Action button to transfer money.
  ///
  /// In en, this message translates to:
  /// **'Transfer Money'**
  String get actionTransfer;

  /// Title for the transaction detail screen.
  ///
  /// In en, this message translates to:
  /// **'Transaction Detail'**
  String get transactionDetailTitle;

  /// Bottom navigation label for dashboard tab.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Title for the dashboard screen.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// Section heading for spendable balances.
  ///
  /// In en, this message translates to:
  /// **'Spendable Balances'**
  String get dashboardSpendableBalances;

  /// Section heading for protected balances.
  ///
  /// In en, this message translates to:
  /// **'Protected Balances'**
  String get dashboardProtectedBalances;

  /// Empty state for spendable balances.
  ///
  /// In en, this message translates to:
  /// **'No spendable accounts yet.'**
  String get dashboardNoSpendable;

  /// Empty state for protected balances.
  ///
  /// In en, this message translates to:
  /// **'No protected accounts.'**
  String get dashboardNoProtected;

  /// Label for income in period flow.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboardPeriodIncome;

  /// Label for expenses in period flow.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get dashboardPeriodExpenses;

  /// Label for net amount in period flow.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get dashboardPeriodNet;

  /// Empty state for period flow.
  ///
  /// In en, this message translates to:
  /// **'No income or expense activity in this period.'**
  String get dashboardPeriodNoActivity;

  /// Expense scope label: personal.
  ///
  /// In en, this message translates to:
  /// **'Personal Spending'**
  String get dashboardScopePersonal;

  /// Expense scope label: spouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse Spending'**
  String get dashboardScopeSpouse;

  /// Expense scope label: household.
  ///
  /// In en, this message translates to:
  /// **'Household Spending'**
  String get dashboardScopeHousehold;

  /// Expense scope label: child.
  ///
  /// In en, this message translates to:
  /// **'Child Spending'**
  String get dashboardScopeChild;

  /// Empty state for expense scopes.
  ///
  /// In en, this message translates to:
  /// **'No expense scope data for this period.'**
  String get dashboardScopeNoActivity;

  /// Section heading for spouse wallet.
  ///
  /// In en, this message translates to:
  /// **'Spouse Wallet'**
  String get dashboardSpouseWallet;

  /// Label for amount funded to spouse wallet.
  ///
  /// In en, this message translates to:
  /// **'Funded'**
  String get dashboardSpouseWalletFunded;

  /// Label for amount spent from spouse wallet.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get dashboardSpouseWalletSpent;

  /// Label for amount returned from spouse wallet.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get dashboardSpouseWalletReturned;

  /// Label for current spouse wallet balance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get dashboardSpouseWalletBalance;

  /// Empty state for spouse wallet.
  ///
  /// In en, this message translates to:
  /// **'No spouse wallet found.'**
  String get dashboardNoSpouseWallet;

  /// Section heading for recent activity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get dashboardRecentActivity;

  /// Empty state for recent activity.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions.'**
  String get dashboardNoRecentActivity;

  /// Link to view all transactions.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardViewAll;

  /// Period selector chip: current month.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get dashboardPeriodCurrentMonth;

  /// Period selector chip: previous month.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get dashboardPeriodPreviousMonth;

  /// Period selector chip: current year.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get dashboardPeriodCurrentYear;

  /// Period selector chip: custom range.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get dashboardPeriodCustom;

  /// Warning for negative balance.
  ///
  /// In en, this message translates to:
  /// **'Negative balance — data integrity issue'**
  String get dashboardNegativeBalanceWarning;

  /// Label for protected child fund balance row.
  ///
  /// In en, this message translates to:
  /// **'Child (Protected)'**
  String get dashboardChildProtected;

  /// Tooltip and semantic label for the refresh button.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get dashboardRefresh;

  /// Loading state message for dashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard...'**
  String get dashboardLoading;

  /// Error state message for dashboard.
  ///
  /// In en, this message translates to:
  /// **'Unable to load financial summary.'**
  String get dashboardError;

  /// Retry button label on dashboard error.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get dashboardRetry;

  /// Label for the period selector section.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get dashboardPeriodLabel;

  /// Title for the reports landing screen.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// Title for income/expense report screen.
  ///
  /// In en, this message translates to:
  /// **'Income & Expenses'**
  String get reportIncomeExpenseTitle;

  /// Title for spending attribution report screen.
  ///
  /// In en, this message translates to:
  /// **'Spending Attribution'**
  String get reportAttributionTitle;

  /// Title for category report screen.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get reportCategoriesTitle;

  /// Title for account flow report screen.
  ///
  /// In en, this message translates to:
  /// **'Account Flows'**
  String get reportAccountsTitle;

  /// Title for home savings report screen.
  ///
  /// In en, this message translates to:
  /// **'Home Savings'**
  String get reportHomeSavingsTitle;

  /// Title for spouse wallet report screen.
  ///
  /// In en, this message translates to:
  /// **'Spouse Wallet'**
  String get reportSpouseWalletTitle;

  /// Title for protected funds report screen.
  ///
  /// In en, this message translates to:
  /// **'Protected Funds'**
  String get reportProtectedFundsTitle;

  /// Label for gross income amount.
  ///
  /// In en, this message translates to:
  /// **'Gross Income'**
  String get reportGrossIncome;

  /// Label for gross expense amount.
  ///
  /// In en, this message translates to:
  /// **'Gross Expenses'**
  String get reportGrossExpense;

  /// Label for net income amount.
  ///
  /// In en, this message translates to:
  /// **'Net Income'**
  String get reportNetIncome;

  /// Label for net expense amount.
  ///
  /// In en, this message translates to:
  /// **'Net Expenses'**
  String get reportNetExpense;

  /// Label for reversal effect amount.
  ///
  /// In en, this message translates to:
  /// **'Reversal Effect'**
  String get reportReversalEffect;

  /// Label for net cash flow amount.
  ///
  /// In en, this message translates to:
  /// **'Net Cash Flow'**
  String get reportNetCashFlow;

  /// Section heading for spending by spender.
  ///
  /// In en, this message translates to:
  /// **'By Spender'**
  String get reportSpenderSection;

  /// Section heading for spending by beneficiary.
  ///
  /// In en, this message translates to:
  /// **'By Beneficiary'**
  String get reportBeneficiarySection;

  /// Section heading for spending by scope.
  ///
  /// In en, this message translates to:
  /// **'By Scope'**
  String get reportScopeSection;

  /// Label for opening balance.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get reportOpeningBalance;

  /// Label for closing balance.
  ///
  /// In en, this message translates to:
  /// **'Closing Balance'**
  String get reportClosingBalance;

  /// Label for current balance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get reportCurrentBalance;

  /// Label for funded amount in wallet report.
  ///
  /// In en, this message translates to:
  /// **'Funded'**
  String get reportFunded;

  /// Label for spent amount in wallet report.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get reportSpent;

  /// Label for returned amount in wallet report.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get reportReturned;

  /// Label for withdrawals section.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get reportWithdrawals;

  /// Label for withdrawal reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportWithdrawalReason;

  /// Label for beneficiary in protected fund.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary'**
  String get reportBeneficiary;

  /// Link to drill-down transaction list.
  ///
  /// In en, this message translates to:
  /// **'View Transactions'**
  String get reportDrillDown;

  /// Empty-state message for reports.
  ///
  /// In en, this message translates to:
  /// **'No data for this period.'**
  String get reportEmpty;

  /// Error message for report load failure.
  ///
  /// In en, this message translates to:
  /// **'Unable to load report.'**
  String get reportError;

  /// Refresh button label in reports.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get reportRefresh;

  /// Note that totals are per currency.
  ///
  /// In en, this message translates to:
  /// **'Totals shown per currency'**
  String get reportCurrencySeparate;

  /// Note about transfer exclusion.
  ///
  /// In en, this message translates to:
  /// **'Transfers are not included in income or expense totals.'**
  String get reportTransferNote;

  /// Note about reversal effect display.
  ///
  /// In en, this message translates to:
  /// **'Reversal effects are shown separately.'**
  String get reportReversalNote;

  /// Label for period closing balance.
  ///
  /// In en, this message translates to:
  /// **'Period Closing Balance'**
  String get reportPeriodClosingBalance;

  /// Link to audit detail.
  ///
  /// In en, this message translates to:
  /// **'View Audit'**
  String get reportAuditDrillDown;

  /// Count of transactions in a category.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String reportTransactionCount(int count);

  /// Dashboard button to open reports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get reportViewReports;

  /// Onboarding screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Enter your name to get started.'**
  String get onboardingSubtitle;

  /// Label for the name field on the onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onboardingNameLabel;

  /// Hint text for the name field on the onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmed'**
  String get onboardingNameHint;

  /// Submit button on the onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStartButton;

  /// Generic error message on the onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get onboardingGenericError;

  /// Title for the budgets section.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// Button/title for creating a new budget.
  ///
  /// In en, this message translates to:
  /// **'New Budget'**
  String get budgetNew;

  /// Label for the budget name field.
  ///
  /// In en, this message translates to:
  /// **'Budget name'**
  String get budgetName;

  /// Label for the budget currency field.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get budgetCurrency;

  /// Label for the budget limit field (monthly budget).
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get budgetLimit;

  /// Label for the budget limit field (fixed budget).
  ///
  /// In en, this message translates to:
  /// **'Budget limit'**
  String get budgetLimitFixed;

  /// Period type: monthly recurring budget.
  ///
  /// In en, this message translates to:
  /// **'Monthly (recurring)'**
  String get budgetPeriodMonthly;

  /// Period type: fixed date range budget.
  ///
  /// In en, this message translates to:
  /// **'Fixed period'**
  String get budgetPeriodFixed;

  /// Label for the budget start date field.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get budgetStartDate;

  /// Label for the budget end date field.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get budgetEndDate;

  /// Label for optional category filter.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get budgetCategoryFilter;

  /// Label for optional expense scope filter.
  ///
  /// In en, this message translates to:
  /// **'Scope (optional)'**
  String get budgetScopeFilter;

  /// Label for optional spender member filter.
  ///
  /// In en, this message translates to:
  /// **'Spender (optional)'**
  String get budgetSpenderFilter;

  /// Label for optional beneficiary member filter.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary (optional)'**
  String get budgetBeneficiaryFilter;

  /// Label for optional payment account filter.
  ///
  /// In en, this message translates to:
  /// **'Payment account (optional)'**
  String get budgetAccountFilter;

  /// Explanation that budgets can overlap.
  ///
  /// In en, this message translates to:
  /// **'Budgets may overlap — each is monitored independently'**
  String get budgetOverlapNote;

  /// Budget status: no spending yet.
  ///
  /// In en, this message translates to:
  /// **'No spending'**
  String get budgetStatusNoSpending;

  /// Budget status: on track.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get budgetStatusOnTrack;

  /// Budget status: near the limit.
  ///
  /// In en, this message translates to:
  /// **'Near limit'**
  String get budgetStatusNearLimit;

  /// Budget status: limit reached.
  ///
  /// In en, this message translates to:
  /// **'Limit reached'**
  String get budgetStatusLimitReached;

  /// Budget status: over budget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get budgetStatusOverBudget;

  /// Label for consumed/spent amount.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetConsumed;

  /// Label for remaining amount.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get budgetRemaining;

  /// Percentage of budget used.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String budgetPercent(int percent);

  /// Note explaining reversal semantics for budgets.
  ///
  /// In en, this message translates to:
  /// **'Fully reversed expenses count as zero toward this budget'**
  String get budgetReversalNote;

  /// Empty state message for budgets list.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet. Create one to start planning.'**
  String get budgetEmpty;

  /// Label indicating a budget is archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get budgetArchived;

  /// Button to archive a budget.
  ///
  /// In en, this message translates to:
  /// **'Archive budget'**
  String get budgetArchive;

  /// Button to restore an archived budget.
  ///
  /// In en, this message translates to:
  /// **'Restore budget'**
  String get budgetRestore;

  /// Section title for previous month history.
  ///
  /// In en, this message translates to:
  /// **'Previous periods'**
  String get budgetPreviousPeriods;

  /// Empty state for drill-down when no matching expenses.
  ///
  /// In en, this message translates to:
  /// **'No matching expenses in this period'**
  String get budgetNoMatching;

  /// Validation error: budget name is empty.
  ///
  /// In en, this message translates to:
  /// **'Budget name is required'**
  String get errorBudgetNameEmpty;

  /// Validation error: budget limit is zero.
  ///
  /// In en, this message translates to:
  /// **'Budget limit must be greater than zero'**
  String get errorBudgetLimitZero;

  /// Validation error: end date is before start date.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date'**
  String get errorBudgetEndBeforeStart;

  /// Validation error: currency not selected.
  ///
  /// In en, this message translates to:
  /// **'Currency is required'**
  String get errorBudgetCurrencyRequired;

  /// Title for the savings goals screen.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTitle;

  /// Button/title to create a new savings goal.
  ///
  /// In en, this message translates to:
  /// **'New Goal'**
  String get goalNew;

  /// Label for the goal name field.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalName;

  /// Label for the goal purpose field.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get goalPurpose;

  /// Label for the goal currency field.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get goalCurrency;

  /// Label for the goal target amount field.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get goalTarget;

  /// Label for the optional target date field.
  ///
  /// In en, this message translates to:
  /// **'Target date (optional)'**
  String get goalTargetDate;

  /// Label for the optional beneficiary member field.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary (optional)'**
  String get goalBeneficiary;

  /// Section label for optional initial funding.
  ///
  /// In en, this message translates to:
  /// **'Initial funding (optional)'**
  String get goalInitialFunding;

  /// Label for the initial funding source account.
  ///
  /// In en, this message translates to:
  /// **'Source account'**
  String get goalInitialFundingSource;

  /// Label for the initial funding amount.
  ///
  /// In en, this message translates to:
  /// **'Initial amount'**
  String get goalInitialFundingAmount;

  /// Goal status: active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get goalStatusActive;

  /// Goal status: target reached.
  ///
  /// In en, this message translates to:
  /// **'Target reached'**
  String get goalStatusTargetReached;

  /// Goal status: completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalStatusCompleted;

  /// Goal status: archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get goalStatusArchived;

  /// Progress state: no funds yet.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get goalProgressNotStarted;

  /// Progress state: partially funded.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get goalProgressInProgress;

  /// Progress state: at or above target.
  ///
  /// In en, this message translates to:
  /// **'Target reached'**
  String get goalProgressTargetReached;

  /// Progress state: balance exceeds target.
  ///
  /// In en, this message translates to:
  /// **'Overfunded'**
  String get goalProgressOverfunded;

  /// Label for the goal reserve balance.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get goalReserveBalance;

  /// Label for remaining amount to target.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get goalRemaining;

  /// Label prefix when goal is overfunded.
  ///
  /// In en, this message translates to:
  /// **'Overfunded by'**
  String get goalOverfunded;

  /// Progress percentage label.
  ///
  /// In en, this message translates to:
  /// **'{percent}% funded'**
  String goalPercent(int percent);

  /// Button to fund a goal.
  ///
  /// In en, this message translates to:
  /// **'Add funds'**
  String get goalFundAction;

  /// Button to release funds from a goal.
  ///
  /// In en, this message translates to:
  /// **'Release funds'**
  String get goalReleaseAction;

  /// Button to mark a goal as complete.
  ///
  /// In en, this message translates to:
  /// **'Mark as complete'**
  String get goalCompleteAction;

  /// Button to archive a goal.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get goalArchiveAction;

  /// Button to restore an archived goal.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get goalRestoreAction;

  /// Label for the release reason field.
  ///
  /// In en, this message translates to:
  /// **'Release reason'**
  String get goalReleaseReason;

  /// Movement type: funding.
  ///
  /// In en, this message translates to:
  /// **'Funding'**
  String get goalMovementFunding;

  /// Movement type: release.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get goalMovementRelease;

  /// Section title for goal revision history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get goalRevisions;

  /// Clarification note shown in goal detail.
  ///
  /// In en, this message translates to:
  /// **'Goal funds are NOT child-protected money'**
  String get goalChildFundNote;

  /// Note shown on fund-goal confirmation.
  ///
  /// In en, this message translates to:
  /// **'This is an internal transfer — not an expense'**
  String get goalTransferNote;

  /// Note shown on release-goal confirmation.
  ///
  /// In en, this message translates to:
  /// **'This is an internal transfer — not income'**
  String get goalReleaseTransferNote;

  /// Empty state message for goals list.
  ///
  /// In en, this message translates to:
  /// **'No goals yet. Create one to start saving.'**
  String get goalEmpty;

  /// Goal purpose: emergency fund.
  ///
  /// In en, this message translates to:
  /// **'Emergency fund'**
  String get purposeEmergencyFund;

  /// Goal purpose: home purchase.
  ///
  /// In en, this message translates to:
  /// **'Home purchase'**
  String get purposeHomePurchase;

  /// Goal purpose: education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get purposeEducation;

  /// Goal purpose: travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get purposeTravel;

  /// Goal purpose: major purchase.
  ///
  /// In en, this message translates to:
  /// **'Major purchase'**
  String get purposeMajorPurchase;

  /// Goal purpose: family event.
  ///
  /// In en, this message translates to:
  /// **'Family event'**
  String get purposeFamilyEvent;

  /// Goal purpose: other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get purposeOther;

  /// Validation error: goal name is empty.
  ///
  /// In en, this message translates to:
  /// **'Goal name is required'**
  String get errorGoalNameEmpty;

  /// Validation error: goal target is zero.
  ///
  /// In en, this message translates to:
  /// **'Target amount must be greater than zero'**
  String get errorGoalTargetZero;

  /// Validation error: currency not selected.
  ///
  /// In en, this message translates to:
  /// **'Currency is required'**
  String get errorGoalCurrencyRequired;

  /// Validation error: release reason is empty.
  ///
  /// In en, this message translates to:
  /// **'Release reason is required'**
  String get errorGoalReleaseReasonEmpty;

  /// Error when reserve has insufficient funds for release.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance in goal reserve'**
  String get errorGoalInsufficientReserve;

  /// Error when trying to archive a goal with non-zero reserve.
  ///
  /// In en, this message translates to:
  /// **'Cannot archive a goal with remaining funds. Release all funds first.'**
  String get errorGoalArchiveNonzeroBalance;

  /// Error when source account is a protected child fund.
  ///
  /// In en, this message translates to:
  /// **'Funding from a protected child account is not allowed'**
  String get errorGoalSourceIsProtected;

  /// Error when source account is a goalReserve account.
  ///
  /// In en, this message translates to:
  /// **'Cannot fund a goal from another goal reserve'**
  String get errorGoalSourceIsReserve;

  /// Error when funding source is non-spendable.
  ///
  /// In en, this message translates to:
  /// **'Goal funding requires a spendable account'**
  String get errorGoalSourceNotSpendable;

  /// Error when release destination is non-spendable.
  ///
  /// In en, this message translates to:
  /// **'Goal release requires a spendable destination account'**
  String get errorGoalDestinationNotSpendable;

  /// Title for the fund-goal screen.
  ///
  /// In en, this message translates to:
  /// **'Add Funds to Goal'**
  String get goalFundTitle;

  /// Title for the release-goal screen.
  ///
  /// In en, this message translates to:
  /// **'Release Goal Funds'**
  String get goalReleaseTitle;

  /// Label for source account in fund-goal screen.
  ///
  /// In en, this message translates to:
  /// **'Source account'**
  String get goalSourceAccount;

  /// Label for destination account in release-goal screen.
  ///
  /// In en, this message translates to:
  /// **'Destination account'**
  String get goalDestinationAccount;

  /// Label for amount field in goal fund/release screens.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get goalAmount;

  /// Label for projected balance section.
  ///
  /// In en, this message translates to:
  /// **'Projected balance'**
  String get goalProjectedBalance;

  /// Dashboard section showing goal-reserved amounts.
  ///
  /// In en, this message translates to:
  /// **'Goal reserves'**
  String get goalReservedBalances;

  /// Title for the savings certificates screen.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get certificatesTitle;

  /// Button/title to create a new savings certificate.
  ///
  /// In en, this message translates to:
  /// **'New Certificate'**
  String get certificateNew;

  /// Empty state message for certificates list.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet. Add one to track your fixed-term deposits.'**
  String get certificateEmpty;

  /// Label for the issuing institution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get certificateInstitution;

  /// Label for the certificate principal amount.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get certificatePrincipal;

  /// Label for profit on a certificate.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get certificateProfit;

  /// Label for the maturity date field.
  ///
  /// In en, this message translates to:
  /// **'Maturity date'**
  String get certificateMaturityDate;

  /// Label for the start date field.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get certificateStartDate;

  /// Label for the optional bank reference.
  ///
  /// In en, this message translates to:
  /// **'Reference / certificate number'**
  String get certificateReference;

  /// Label for annual interest rate in bps.
  ///
  /// In en, this message translates to:
  /// **'Annual rate (basis points)'**
  String get certificateAnnualRate;

  /// Label for the profit payment frequency.
  ///
  /// In en, this message translates to:
  /// **'Profit frequency'**
  String get certificateProfitFrequency;

  /// Label for the source account in certificate creation.
  ///
  /// In en, this message translates to:
  /// **'Funding source account'**
  String get certificateSourceAccount;

  /// Label for the destination account in profit/redemption.
  ///
  /// In en, this message translates to:
  /// **'Destination account'**
  String get certificateDestinationAccount;

  /// Button/title for redeeming a certificate.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get certificateRedeem;

  /// Title for the redeem certificate screen.
  ///
  /// In en, this message translates to:
  /// **'Redeem Certificate'**
  String get certificateRedeemTitle;

  /// Title for the record profit screen.
  ///
  /// In en, this message translates to:
  /// **'Record Profit'**
  String get certificateProfitTitle;

  /// Button to record certificate profit.
  ///
  /// In en, this message translates to:
  /// **'Record Profit'**
  String get certificateRecordProfit;

  /// Lifecycle label: active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get certificateLifecycleActive;

  /// Lifecycle label: redeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get certificateLifecycleRedeemed;

  /// Lifecycle label: archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get certificateLifecycleArchived;

  /// Term state label: not started.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get certificateTermNotStarted;

  /// Term state label: active term.
  ///
  /// In en, this message translates to:
  /// **'Active Term'**
  String get certificateTermActive;

  /// Term state label: matured.
  ///
  /// In en, this message translates to:
  /// **'Matured'**
  String get certificateTermMatured;

  /// Term state label: overdue redemption.
  ///
  /// In en, this message translates to:
  /// **'Overdue Redemption'**
  String get certificateTermOverdue;

  /// Term state label: fully redeemed.
  ///
  /// In en, this message translates to:
  /// **'Fully Redeemed'**
  String get certificateTermFullyRedeemed;

  /// Frequency label.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get certificateProfitFreqMonthly;

  /// Frequency label.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get certificateProfitFreqQuarterly;

  /// Frequency label.
  ///
  /// In en, this message translates to:
  /// **'Semi-Annual'**
  String get certificateProfitFreqSemiAnnual;

  /// Frequency label.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get certificateProfitFreqAnnual;

  /// Frequency label.
  ///
  /// In en, this message translates to:
  /// **'At Maturity'**
  String get certificateProfitFreqAtMaturity;

  /// Frequency label.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get certificateProfitFreqOther;

  /// Label for the current principal balance.
  ///
  /// In en, this message translates to:
  /// **'Principal balance'**
  String get certificatePrincipalBalance;

  /// Label for the original principal amount.
  ///
  /// In en, this message translates to:
  /// **'Original principal'**
  String get certificateOriginalPrincipal;

  /// Label for the optional note field.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get certificateNote;

  /// Label for amount field in profit/redemption screens.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get certificateAmount;

  /// Section header: principal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get certificatePrincipalSection;

  /// Section header: profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get certificateProfitSection;

  /// Redemption mode: principal only.
  ///
  /// In en, this message translates to:
  /// **'Principal only'**
  String get certificateRedeemPrincipalOnly;

  /// Redemption mode: profit only.
  ///
  /// In en, this message translates to:
  /// **'Profit only'**
  String get certificateRedeemProfitOnly;

  /// Redemption mode: principal and profit combined.
  ///
  /// In en, this message translates to:
  /// **'Principal + profit'**
  String get certificateRedeemCombined;

  /// Title for the certificate review step.
  ///
  /// In en, this message translates to:
  /// **'Review Certificate'**
  String get certificateReviewTitle;

  /// Category label for certificate profit income.
  ///
  /// In en, this message translates to:
  /// **'Certificate Profit'**
  String get catCertificateProfit;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Institution name is required'**
  String get errorCertificateInstitutionRequired;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Principal must be greater than zero'**
  String get errorCertificatePrincipalZero;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Currency is required'**
  String get errorCertificateCurrencyRequired;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Start and maturity dates are required'**
  String get errorCertificateDatesRequired;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Maturity date must be after start date'**
  String get errorCertificateMaturityBeforeStart;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Funding source account is required'**
  String get errorCertificateSourceRequired;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Funding from a protected child account is not allowed'**
  String get errorCertificateSourceIsProtected;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'A certificate account cannot be used as a funding source'**
  String get errorCertificateAccountNotAllowedAsSource;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'A certificate account cannot be used as a destination'**
  String get errorCertificateAccountNotAllowedAsDestination;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Certificate accounts cannot be used in ordinary transactions'**
  String get errorCertificateAccountNotAllowedInOrdinaryTransaction;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Certificate is archived'**
  String get errorCertificateArchived;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Certificate is not active'**
  String get errorCertificateNotActive;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Cannot archive a certificate with remaining principal. Redeem first.'**
  String get errorCertificateArchiveNonzeroBalance;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Certificate must be archived to restore'**
  String get errorCertificateRestoreRequiresArchived;

  /// Idempotency conflict error.
  ///
  /// In en, this message translates to:
  /// **'Duplicate certificate creation conflict'**
  String get errorCertificateIdempotencyConflict;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Certificate must be active to reverse purchase'**
  String get errorCertificateReversalRequiresActive;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Cannot reverse purchase after profit or redemption'**
  String get errorCertificateReversalNotAllowedAfterHistory;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Target operation is not a profit income operation'**
  String get errorCertificateProfitReversalInvalidType;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Redemption reversal is not supported'**
  String get errorCertificateRedemptionReversalNotSupported;

  /// Validation error when redeeming early.
  ///
  /// In en, this message translates to:
  /// **'Certificate has not reached maturity'**
  String get errorCertificateNotMatured;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Certificate has no remaining principal to redeem'**
  String get errorCertificateNoPrincipal;

  /// Validation error for partial redemption.
  ///
  /// In en, this message translates to:
  /// **'Only full principal redemption is supported'**
  String get errorCertificateFullRedemptionOnly;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
