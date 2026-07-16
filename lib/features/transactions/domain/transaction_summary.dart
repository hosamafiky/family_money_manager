import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:meta/meta.dart';

/// A read-only domain object that wraps an [Operation] with its rich context
/// metadata from the `operation_contexts` table.
///
/// Used for list views and detail screens. The [operation] field provides
/// all financial fields; context fields provide the stable-UUID metadata that
/// is not stored directly on the operations row.
@immutable
final class TransactionSummary {
  const TransactionSummary({
    required this.operation,
    this.categoryCode,
    this.spenderMemberId,
    this.beneficiaryMemberId,
    this.scope,
    required this.isRecurring,
    this.note,
  });

  /// The underlying financial operation (type, amount, date, accounts, etc.).
  final Operation operation;

  /// Stable category code (matches a [TransactionCategory.code]).
  final String? categoryCode;

  /// Stable UUID of the member who spent / initiated.
  final String? spenderMemberId;

  /// Stable UUID of the member who benefits.
  final String? beneficiaryMemberId;

  /// Expense scope (personal, household, spouse, child, shared).
  final ExpenseScope? scope;

  /// True when the operation was flagged as recurring.
  final bool isRecurring;

  /// Optional free-text note.
  final String? note;
}
