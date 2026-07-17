/// Ledger entry and operation type enumerations.
///
/// All values are stored as stable English string codes in the database.
/// The full set of entry types is defined here for serialisation stability,
/// even though only a subset is used in Phase 2.
library;

/// The direction of a ledger entry.
///
/// Ledger entries always carry a positive [amountMinorUnits]; the direction
/// indicates whether money flows into (credit) or out of (debit) the account.
///
/// CREDIT:  Money flows into the account (increases balance).
/// DEBIT:   Money flows out of the account (decreases balance).
///
/// Balance formula (INV-001, INV-012):
///   balance = Σ(credit.amountMinorUnits) - Σ(debit.amountMinorUnits)
enum LedgerDirection {
  credit,
  debit;

  String get code => name;

  static LedgerDirection fromCode(String code) {
    for (final d in LedgerDirection.values) {
      if (d.name == code) return d;
    }
    throw ArgumentError.value(code, 'code', 'Unknown LedgerDirection');
  }

  LedgerDirection get opposite => this == LedgerDirection.credit
      ? LedgerDirection.debit
      : LedgerDirection.credit;
}

/// The specific type of a single ledger entry.
///
/// Used to classify entries for reporting and invariant checking.
/// Phase 2 implements: openingBalance, income, expense, transferOut,
/// transferIn, adjustmentDebit, adjustmentCredit, reversalDebit, reversalCredit,
/// childFundDeposit, childFundWithdrawal.
/// Remaining types are defined for stable code serialisation.
enum LedgerEntryType {
  openingBalance,
  income,
  expense,
  transferOut,
  transferIn,
  transferFee,
  adjustmentDebit,
  adjustmentCredit,
  assetPurchase,
  assetSale,
  liabilityCreation,
  liabilityRepayment,
  certificateFunding,
  certificateMaturityReturn,
  interestIncome,
  goldPurchase,
  goldSale,
  goalFunding,
  goalWithdrawal,
  childFundDeposit,
  childFundWithdrawal,
  reversalDebit,
  reversalCredit,
  sadaqahExpense,
  zakatExpense;

  String get code => name;

  static LedgerEntryType fromCode(String code) {
    for (final t in LedgerEntryType.values) {
      if (t.name == code) return t;
    }
    throw ArgumentError.value(code, 'code', 'Unknown LedgerEntryType');
  }

  /// Returns true when this entry type represents a debit (money leaving
  /// an account). Used for protected-fund checks.
  bool get isDebitType {
    switch (this) {
      case LedgerEntryType.expense:
      case LedgerEntryType.transferOut:
      case LedgerEntryType.transferFee:
      case LedgerEntryType.adjustmentDebit:
      case LedgerEntryType.assetPurchase:
      case LedgerEntryType.liabilityRepayment:
      case LedgerEntryType.certificateFunding:
      case LedgerEntryType.goldPurchase:
      case LedgerEntryType.goalFunding:
      case LedgerEntryType.childFundWithdrawal:
      case LedgerEntryType.reversalDebit:
      case LedgerEntryType.sadaqahExpense:
      case LedgerEntryType.zakatExpense:
        return true;
      default:
        return false;
    }
  }

  /// Returns true when this entry type represents a transfer (excluded from
  /// income/expense reports per INV-011).
  bool get isTransferType {
    return this == LedgerEntryType.transferOut ||
        this == LedgerEntryType.transferIn ||
        this == LedgerEntryType.transferFee;
  }
}

/// The logical type of a complete financial operation.
///
/// An operation groups one or more ledger entries into a single financial event.
/// Phase 2 implements: income, expense, transfer, openingBalance,
/// adjustment, reversal, childFundDeposit, childFundWithdrawal.
enum OperationType {
  income,
  expense,
  transfer,
  openingBalance,
  adjustment,
  assetPurchase,
  assetSale,
  liabilityCreation,
  liabilityRepayment,
  certificateFunding,
  certificateMaturity,
  interestIncome,
  goldPurchase,
  goldSale,
  goalFunding,
  goalWithdrawal,
  childFundDeposit,
  childFundWithdrawal,
  reversal,
  sadaqah,
  zakat;

  String get code => name;

  static OperationType fromCode(String code) {
    for (final t in OperationType.values) {
      if (t.name == code) return t;
    }
    throw ArgumentError.value(code, 'code', 'Unknown OperationType');
  }

  /// Returns true for operation types that should NOT appear in income or
  /// expense reports (INV-011).
  bool get isExcludedFromIncomeExpenseReports {
    return this == OperationType.transfer ||
        this == OperationType.goalFunding ||
        this == OperationType.certificateFunding ||
        this == OperationType.goldPurchase ||
        this == OperationType.openingBalance;
  }
}

/// Whether a transaction is intended to recur or is a one-time event.
///
/// Scheduling is deferred to a future phase.
/// [recurring] means the user flagged this as a recurring transaction
/// but no automatic generation occurs yet.
enum RecurringStatus {
  oneTime('one_time'),
  recurring('recurring');

  const RecurringStatus(this.code);

  final String code;

  static RecurringStatus fromCode(String c) => values.firstWhere(
    (v) => v.code == c,
    orElse: () =>
        throw ArgumentError.value(c, 'code', 'Unknown RecurringStatus'),
  );
}
