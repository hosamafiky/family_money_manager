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

  // ── Phase 3A ─────────────────────────────────────────────────────────────

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
  String get accountPurpose => 'Purpose';

  @override
  String get accountCurrency => 'Currency';

  @override
  String get accountOpeningBalance => 'Opening Balance';

  @override
  String get accountOpeningDate => 'Opening Balance Date';

  @override
  String get accountNotes => 'Notes';

  @override
  String get accountIsSpendable => 'Spendable';

  @override
  String get accountIsProtected => 'Protected';

  @override
  String get accountIncludeNetWorth => 'Include in Net Worth';

  @override
  String get accountIncludeZakat => 'Include in Zakat';

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
  String get accountProtectedWarning =>
      'This is a protected account. Funds are not available for ordinary spending.';

  @override
  String get accountChildFundConfirmTitle => 'Confirm Child Fund Creation';

  @override
  String get accountChildFundConfirmBody =>
      'Funds in this account will be protected and dedicated to the child. They cannot be used for ordinary spending.';

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
  String get ownerPrimaryUser => 'Primary User';

  @override
  String get ownerSpouse => 'Spouse';

  @override
  String get ownerChild => 'Child';

  @override
  String get ownerHousehold => 'Shared Household';

  @override
  String get purposeAvailable => 'Available';

  @override
  String get purposeSavings => 'Savings';

  @override
  String get purposeEmergency => 'Emergency';

  @override
  String get purposeChildEducation => 'Child Education';

  @override
  String get purposeChildFuture => 'Child Future';

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
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get edit => 'Edit';

  @override
  String get back => 'Back';

  @override
  String get protectedLabel => 'Protected';

  @override
  String get spendableLabel => 'Spendable';

  @override
  String get archivedLabel => 'Archived';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get errorGeneric => 'An error occurred. Please try again.';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navMembers => 'Family';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get balanceLabel => 'Balance';

  @override
  String get reviewTitle => 'Review';
}
