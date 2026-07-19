import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/transactions/data/transaction_query_repository.dart';

/// Returns a spouse-wallet funding/spending summary for a date range.
final class GetSpouseWalletSummaryUseCase {
  const GetSpouseWalletSummaryUseCase(this._repo);

  final TransactionQueryRepository _repo;

  Future<AppResult<SpouseWalletSummary>> execute({
    required String spouseAccountId,
    required String householdId,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final summary = await _repo.spouseWalletSummary(spouseAccountId: spouseAccountId, householdId: householdId, fromDate: fromDate, toDate: toDate);
      return AppOk(summary);
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}
