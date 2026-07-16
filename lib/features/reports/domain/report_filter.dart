/// Filter parameters for financial report queries.
library;

import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:meta/meta.dart';

/// Immutable set of filter criteria applied to any report request.
///
/// Empty lists mean "all values" (no filtering). Boolean flags control
/// inclusion of special-case data.
@immutable
final class ReportFilter {
  const ReportFilter({
    this.accountIds = const [],
    this.ownerTypes = const [],
    this.spenderMemberIds = const [],
    this.beneficiaryMemberIds = const [],
    this.scopes = const [],
    this.categoryCodes = const [],
    this.operationTypes = const [],
    this.currencyCodes = const [],
    this.includeReversed = true,
    this.protectedOnly = false,
  });

  /// Empty list = all accounts.
  final List<String> accountIds;

  /// Empty list = all owner types.
  final List<AccountOwnerType> ownerTypes;

  /// Empty list = all spenders.
  final List<String> spenderMemberIds;

  /// Empty list = all beneficiaries.
  final List<String> beneficiaryMemberIds;

  /// Empty list = all expense scopes.
  final List<ExpenseScope> scopes;

  /// Empty list = all category codes.
  final List<String> categoryCodes;

  /// Empty list = all operation types.
  final List<OperationType> operationTypes;

  /// Empty list = all currencies.
  final List<String> currencyCodes;

  /// When true, reversed operations are included in totals.
  final bool includeReversed;

  /// When true, only protected-fund withdrawals are shown.
  final bool protectedOnly;

  bool get isEmpty =>
      accountIds.isEmpty &&
      ownerTypes.isEmpty &&
      spenderMemberIds.isEmpty &&
      beneficiaryMemberIds.isEmpty &&
      scopes.isEmpty &&
      categoryCodes.isEmpty &&
      operationTypes.isEmpty &&
      currencyCodes.isEmpty &&
      includeReversed &&
      !protectedOnly;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportFilter &&
          _listEquals(other.accountIds, accountIds) &&
          _listEquals(other.ownerTypes, ownerTypes) &&
          _listEquals(other.spenderMemberIds, spenderMemberIds) &&
          _listEquals(other.beneficiaryMemberIds, beneficiaryMemberIds) &&
          _listEquals(other.scopes, scopes) &&
          _listEquals(other.categoryCodes, categoryCodes) &&
          _listEquals(other.operationTypes, operationTypes) &&
          _listEquals(other.currencyCodes, currencyCodes) &&
          other.includeReversed == includeReversed &&
          other.protectedOnly == protectedOnly;

  @override
  int get hashCode => Object.hashAll([
    Object.hashAll(accountIds),
    Object.hashAll(ownerTypes),
    Object.hashAll(spenderMemberIds),
    Object.hashAll(beneficiaryMemberIds),
    Object.hashAll(scopes),
    Object.hashAll(categoryCodes),
    Object.hashAll(operationTypes),
    Object.hashAll(currencyCodes),
    includeReversed,
    protectedOnly,
  ]);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
