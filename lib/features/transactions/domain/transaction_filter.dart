import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:meta/meta.dart';

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

  /// Maximum number of results to return. Defaults to 50.
  final int pageSize;

  /// For cursor-based pagination: the operation ID after which to start.
  /// When provided, results begin after the operation with this ID in the
  /// canonical ordering.
  final String? offsetId;
}
