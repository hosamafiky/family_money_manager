import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/transactions/data/transaction_query_repository.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';

/// Returns filtered transaction history for a household.
final class GetTransactionHistoryUseCase {
  const GetTransactionHistoryUseCase(this._repo);

  final TransactionQueryRepository _repo;

  Future<AppResult<List<TransactionSummary>>> execute({required String householdId, TransactionFilter filter = const TransactionFilter()}) async {
    try {
      final summaries = await _repo.recentOperations(householdId: householdId, filter: filter);
      return AppOk(summaries);
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }

  Future<AppResult<List<TransactionSummary>>> forAccount({
    required String accountId,
    required String householdId,
    TransactionFilter filter = const TransactionFilter(),
  }) async {
    try {
      final summaries = await _repo.operationsForAccount(accountId: accountId, householdId: householdId, filter: filter);
      return AppOk(summaries);
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}
