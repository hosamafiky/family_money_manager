import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:meta/meta.dart';

/// One side of an operation's double entry, with its account named.
///
/// [TransactionSummary] carries account and member *ids*; a detail screen has
/// to render "محفظة نقدية شخصية", not a UUID. Resolving that in the query is
/// what makes the difference between a row a person can read and one they
/// cannot — and doing it there rather than per-widget means one join instead
/// of N lookups.
@immutable
final class OperationLedgerLine {
  const OperationLedgerLine({
    required this.entryId,
    required this.direction,
    required this.accountId,
    required this.accountName,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.entryType,
  });

  final String entryId;
  final LedgerDirection direction;
  final String accountId;

  /// The account's display name, or its id when the account is missing —
  /// never blank, because a blank row reads as a rendering bug rather than as
  /// missing data.
  final String accountName;

  final int amountMinorUnits;
  final String currencyCode;
  final LedgerEntryType entryType;
}

/// The other half of a reversal pair.
///
/// Present on both sides: on a reversed original it describes the correction,
/// and on a reversal it describes what was corrected. Either way the user can
/// walk from one to the other, which is what makes an append-only ledger
/// navigable rather than merely honest.
@immutable
final class ReversalCounterpart {
  const ReversalCounterpart({
    required this.operationId,
    required this.effectiveDate,
    required this.totalAmountMinorUnits,
    required this.currencyCode,
    required this.isReversingEntry,
    this.reason,
    this.authorName,
  });

  final String operationId;
  final String effectiveDate;
  final int totalAmountMinorUnits;
  final String currencyCode;

  /// True when *this counterpart* is the reversing entry — i.e. the operation
  /// being viewed is the original.
  final bool isReversingEntry;

  /// The reason recorded on the reversing entry, whichever side holds it.
  ///
  /// Null for reversals written before schema 20, and for the original half.
  final String? reason;

  /// Display name of whoever recorded the reversing entry.
  final String? authorName;
}

/// Everything the detail screen needs about one operation, named and joined.
@immutable
final class TransactionDetail {
  const TransactionDetail({
    required this.summary,
    required this.ledgerLines,
    this.counterpart,
  });

  final TransactionSummary summary;

  /// The operation's own ledger entries, debits first, then credits.
  ///
  /// Shown rather than summarised: the two sides are what make "balances are
  /// derived, never stored" legible. A reversed operation keeps its lines —
  /// they were never deleted, only answered by opposing ones.
  final List<OperationLedgerLine> ledgerLines;

  /// The other half of the reversal pair, when this operation is in one.
  final ReversalCounterpart? counterpart;

  /// True when this operation's effect on every balance has been answered.
  bool get isNeutralised =>
      summary.operation.isReversed ||
      summary.operation.type == OperationType.reversal;
}
