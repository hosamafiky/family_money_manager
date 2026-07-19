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
///
/// VALIDATION: The public factory always executes validation regardless of
/// Dart compilation mode. [ArgumentError] is thrown if invariants are violated.
@immutable
final class LedgerEntry {
  // Private constructor — only reachable through the validated factory.
  const LedgerEntry._({
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
  });

  /// Creates a validated [LedgerEntry].
  ///
  /// Throws [ArgumentError] if [amountMinorUnits] is not strictly positive.
  /// This validation executes in all Dart compilation modes (debug and release).
  factory LedgerEntry({
    required String id,
    required String operationId,
    required String householdId,
    required String accountId,
    required LedgerDirection direction,
    required int amountMinorUnits,
    required String currencyCode,
    required LedgerEntryType entryType,
    required String effectiveDate,
    required DateTime recordedAt,
    required String createdBy,
    required bool isReversal,
    String? notes,
    String? reversalOfEntryId,
    Map<String, dynamic>? metadata,
  }) {
    if (amountMinorUnits <= 0) {
      throw ArgumentError.value(
        amountMinorUnits,
        'amountMinorUnits',
        'LedgerEntry amount must be a positive integer (> 0). '
            'Use LedgerDirection to express debit/credit direction.',
      );
    }
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'LedgerEntry id must not be empty');
    }
    if (operationId.isEmpty) {
      throw ArgumentError.value(operationId, 'operationId', 'LedgerEntry operationId must not be empty');
    }
    if (householdId.isEmpty) {
      throw ArgumentError.value(householdId, 'householdId', 'LedgerEntry householdId must not be empty');
    }
    if (accountId.isEmpty) {
      throw ArgumentError.value(accountId, 'accountId', 'LedgerEntry accountId must not be empty');
    }
    return LedgerEntry._(
      id: id,
      operationId: operationId,
      householdId: householdId,
      accountId: accountId,
      direction: direction,
      amountMinorUnits: amountMinorUnits,
      currencyCode: currencyCode,
      entryType: entryType,
      effectiveDate: effectiveDate,
      recordedAt: recordedAt,
      createdBy: createdBy,
      isReversal: isReversal,
      notes: notes,
      reversalOfEntryId: reversalOfEntryId,
      metadata: metadata,
    );
  }

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
  bool operator ==(Object other) => identical(this, other) || other is LedgerEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LedgerEntry(id: $id, type: ${entryType.code}, direction: ${direction.code})';
}
