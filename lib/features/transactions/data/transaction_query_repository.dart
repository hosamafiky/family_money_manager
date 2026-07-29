import 'package:family_money_manager/features/transactions/domain/transaction_detail.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:meta/meta.dart';

/// Read-only repository for querying transaction history with rich context.
///
/// ARCHITECTURE RULES:
/// - No widget may call these methods directly; use a use case.
/// - No Drift types appear in any method signature.
abstract interface class TransactionQueryRepository {
  /// Returns recent operations for a household, newest first.
  ///
  /// Ordering: effective_date DESC, recorded_at DESC, id DESC.
  Future<List<TransactionSummary>> recentOperations({
    required String householdId,
    TransactionFilter filter = const TransactionFilter(),
  });

  /// Returns all operations that involve [accountId] (as source or destination).
  Future<List<TransactionSummary>> operationsForAccount({
    required String accountId,
    required String householdId,
    TransactionFilter filter = const TransactionFilter(),
  });

  /// Returns the full detail for a single operation, including context.
  ///
  /// Returns `null` when no matching operation exists in [householdId].
  Future<TransactionSummary?> operationDetail({
    required String operationId,
    required String householdId,
  });

  /// Counts every operation matching [filter], ignoring its page size.
  ///
  /// Exists so the filter sheet can put the result count on its own confirm
  /// button: knowing a filter matches 87 of 1,248 *before* committing to it
  /// makes filtering to nothing a rare accident rather than the normal way to
  /// discover the empty state.
  Future<int> countOperations({
    required String householdId,
    TransactionFilter filter = const TransactionFilter(),
  });

  /// Returns [operationDetail] plus its ledger lines, resolved names, and the
  /// other half of its reversal pair when it has one.
  ///
  /// Separate from [operationDetail] because it costs three more joins: list
  /// callers that only need the summary should not pay for them.
  ///
  /// Returns `null` when no matching operation exists in [householdId].
  Future<TransactionDetail?> operationDetailWithLedger({
    required String operationId,
    required String householdId,
  });

  /// Computes a spouse-wallet summary for a given date range.
  ///
  /// - [totalFunded]: sum of all transferIn credits to the spouse account.
  /// - [totalSpent]: sum of all expense (and childFundWithdrawal) debits from the account.
  /// - [totalReturned]: sum of all transferOut debits from the account (returns).
  /// - [derivedBalance]: funded − spent − returned.
  Future<SpouseWalletSummary> spouseWalletSummary({
    required String spouseAccountId,
    required String householdId,
    required String fromDate,
    required String toDate,
  });
}

// ── SpouseWalletSummary ───────────────────────────────────────────────────────

@immutable
final class SpouseWalletSummary {
  const SpouseWalletSummary({
    required this.totalFunded,
    required this.totalSpent,
    required this.totalReturned,
    required this.derivedBalance,
    required this.currencyCode,
  });

  /// Sum of all transferIn credits to the spouse account (minor units).
  final int totalFunded;

  /// Sum of all expense / childFundWithdrawal debits from the account (minor units).
  final int totalSpent;

  /// Sum of all transferOut debits from the account (money returned, minor units).
  final int totalReturned;

  /// Computed: [totalFunded] − [totalSpent] − [totalReturned].
  final int derivedBalance;

  /// ISO 4217 currency code for the account.
  final String currencyCode;
}
