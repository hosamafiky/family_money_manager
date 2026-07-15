import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:meta/meta.dart';

/// An immutable, append-only ledger entry.
///
/// INVARIANTS:
/// - [amountMinorUnits] is ALWAYS a positive integer. The sign of the
///   financial effect is conveyed by [direction] (credit/debit).
/// - Once written, a ledger entry is NEVER modified or deleted (INV-002).
///   Corrections are made through reversal operations.
/// - [operationId] groups all entries belonging to the same financial operation.
/// - [effectiveDate] is the user-chosen date (may be backdated).
/// - [recordedAt] is the system UTC timestamp of persistence.
@immutable
final class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.operationId,
    required this.householdId,
    required this.accountId,
    required this.direction,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.entryType,
    required this.effectiveDate,
    required this.recordedAt,
    required this.createdBy,
    required this.isReversal,
    this.notes,
    this.reversalOfEntryId,
    this.metadata,
  }) : assert(amountMinorUnits > 0, 'amountMinorUnits must be positive');

  final String id;
  final String operationId;
  final String householdId;
  final String accountId;

  /// Whether this entry is a credit (inflow) or debit (outflow).
  final LedgerDirection direction;

  /// Always a positive integer (minor units). Never zero, never negative.
  final int amountMinorUnits;

  final String currencyCode;
  final LedgerEntryType entryType;

  /// User-chosen effective date in "YYYY-MM-DD" format. May be backdated.
  final String effectiveDate;

  /// System UTC timestamp when this entry was persisted.
  final DateTime recordedAt;

  final String? notes;
  final String createdBy;

  /// True when this entry was created as part of a reversal operation.
  final bool isReversal;

  /// When [isReversal] is true, points to the original entry being cancelled.
  final String? reversalOfEntryId;

  /// Operation-specific supplementary data (JSON-encoded in the database).
  final Map<String, dynamic>? metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LedgerEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'LedgerEntry(id: $id, type: ${entryType.code}, direction: ${direction.code})';
}
