import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:meta/meta.dart';

/// An amount band, in one currency.
///
/// The currency is required rather than optional because a range without one
/// is a mixed-currency comparison: "over 5,000" would silently match a USD
/// transaction against an EGP threshold. That is the same error as a mixed
/// total, and it is prevented here by making the invalid state
/// unrepresentable rather than by checking for it later.
@immutable
final class TransactionAmountRange {
  const TransactionAmountRange({
    required this.currencyCode,
    this.minMinorUnits,
    this.maxMinorUnits,
  });

  final String currencyCode;

  /// Inclusive lower bound. Null means no lower bound.
  final int? minMinorUnits;

  /// Inclusive upper bound. Null means no upper bound.
  final int? maxMinorUnits;

  /// True when neither bound is set, in which case the range restricts
  /// nothing and only the currency would apply.
  bool get isUnbounded => minMinorUnits == null && maxMinorUnits == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAmountRange &&
          other.currencyCode == currencyCode &&
          other.minMinorUnits == minMinorUnits &&
          other.maxMinorUnits == maxMinorUnits;

  @override
  int get hashCode => Object.hash(currencyCode, minMinorUnits, maxMinorUnits);
}

/// Filter parameters for transaction history queries.
///
/// All fields are optional; omitting a field means "no restriction".
@immutable
final class TransactionFilter {
  const TransactionFilter({
    this.accountId,
    this.operationType,
    this.categoryCode,
    this.spenderMemberId,
    this.beneficiaryMemberId,
    this.scope,
    this.fromDate,
    this.toDate,
    this.amountRange,
    this.searchQuery,
    this.includeReversed = true,
    this.pageSize = 50,
    this.offsetId,
  });

  /// Restrict to operations that involve this account (source or destination).
  final String? accountId;

  /// Restrict to a specific operation type.
  final OperationType? operationType;

  /// Restrict to a specific category code.
  final String? categoryCode;

  /// Restrict to operations where this member is the spender.
  final String? spenderMemberId;

  /// Restrict to operations where this member is the beneficiary.
  final String? beneficiaryMemberId;

  /// Restrict to a specific expense scope.
  final ExpenseScope? scope;

  /// Inclusive start date "YYYY-MM-DD". Null means no lower bound.
  final String? fromDate;

  /// Inclusive end date "YYYY-MM-DD". Null means no upper bound.
  final String? toDate;

  /// Restrict to an amount band in one currency.
  final TransactionAmountRange? amountRange;

  /// Free text matched against description, note and account names.
  ///
  /// Deliberately does *not* imply a date restriction: someone searching for
  /// an amount is looking for one specific transaction, not browsing a month.
  /// Callers that want the active period respected pass it in the date
  /// fields as usual.
  final String? searchQuery;

  /// Whether reversed originals and reversing entries are included.
  ///
  /// Defaults to true, and the UI defaults its toggle on: excluding them by
  /// default would quietly hide history, which is the one thing an
  /// append-only ledger exists to prevent.
  final bool includeReversed;

  /// Maximum number of results to return. Defaults to 50.
  final int pageSize;

  /// For cursor-based pagination: the operation ID after which to start.
  /// When provided, results begin after the operation with this ID in the
  /// canonical ordering.
  final String? offsetId;

  /// How many restrictions the user has applied.
  ///
  /// Drives the "clear all (3)" affordance, so it counts what a person would
  /// call a filter — not [pageSize] or [offsetId], which are plumbing, and
  /// not [searchQuery], which has its own visible field.
  int get activeCriteriaCount => [
    accountId != null,
    operationType != null,
    categoryCode != null,
    spenderMemberId != null,
    beneficiaryMemberId != null,
    scope != null,
    fromDate != null || toDate != null,
    amountRange != null,
    !includeReversed,
  ].where((isActive) => isActive).length;

  bool get hasActiveCriteria => activeCriteriaCount > 0;

  /// Copies with overrides. Pass a `clear*` flag to unset a field, since a
  /// null argument cannot be told apart from "not supplied".
  TransactionFilter copyWith({
    String? accountId,
    OperationType? operationType,
    String? categoryCode,
    String? spenderMemberId,
    String? beneficiaryMemberId,
    ExpenseScope? scope,
    String? fromDate,
    String? toDate,
    TransactionAmountRange? amountRange,
    String? searchQuery,
    bool? includeReversed,
    int? pageSize,
    String? offsetId,
    bool clearAccountId = false,
    bool clearOperationType = false,
    bool clearCategoryCode = false,
    bool clearSpenderMemberId = false,
    bool clearBeneficiaryMemberId = false,
    bool clearScope = false,
    bool clearDates = false,
    bool clearAmountRange = false,
    bool clearSearchQuery = false,
  }) => TransactionFilter(
    accountId: clearAccountId ? null : accountId ?? this.accountId,
    operationType: clearOperationType
        ? null
        : operationType ?? this.operationType,
    categoryCode: clearCategoryCode ? null : categoryCode ?? this.categoryCode,
    spenderMemberId: clearSpenderMemberId
        ? null
        : spenderMemberId ?? this.spenderMemberId,
    beneficiaryMemberId: clearBeneficiaryMemberId
        ? null
        : beneficiaryMemberId ?? this.beneficiaryMemberId,
    scope: clearScope ? null : scope ?? this.scope,
    fromDate: clearDates ? null : fromDate ?? this.fromDate,
    toDate: clearDates ? null : toDate ?? this.toDate,
    amountRange: clearAmountRange ? null : amountRange ?? this.amountRange,
    searchQuery: clearSearchQuery ? null : searchQuery ?? this.searchQuery,
    includeReversed: includeReversed ?? this.includeReversed,
    pageSize: pageSize ?? this.pageSize,
    offsetId: offsetId ?? this.offsetId,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilter &&
          other.accountId == accountId &&
          other.operationType == operationType &&
          other.categoryCode == categoryCode &&
          other.spenderMemberId == spenderMemberId &&
          other.beneficiaryMemberId == beneficiaryMemberId &&
          other.scope == scope &&
          other.fromDate == fromDate &&
          other.toDate == toDate &&
          other.amountRange == amountRange &&
          other.searchQuery == searchQuery &&
          other.includeReversed == includeReversed &&
          other.pageSize == pageSize &&
          other.offsetId == offsetId;

  @override
  int get hashCode => Object.hash(
    accountId,
    operationType,
    categoryCode,
    spenderMemberId,
    beneficiaryMemberId,
    scope,
    fromDate,
    toDate,
    amountRange,
    searchQuery,
    includeReversed,
    pageSize,
    offsetId,
  );
}
