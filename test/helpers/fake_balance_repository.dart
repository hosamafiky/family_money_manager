import 'package:family_money_manager/core/financial/ledger_calculator.dart';
import 'package:family_money_manager/features/balance/domain/balance_repository.dart';
import 'package:family_money_manager/features/balance/domain/balance_result.dart';

/// In-memory fake [BalanceRepository] for tests.
///
/// All balances default to 0 unless explicitly set via [setBalance].
final class FakeBalanceRepository implements BalanceRepository {
  final Map<String, int> _balances = {};

  void setBalance(String accountId, int minorUnits) {
    _balances[accountId] = minorUnits;
  }

  @override
  Future<int> currentBalanceMinorUnits({
    required String accountId,
    required String householdId,
  }) async => _balances[accountId] ?? 0;

  @override
  Future<BalanceQueryResult> balanceForAccount({
    required String accountId,
    required String householdId,
  }) async {
    if (!_balances.containsKey(accountId)) {
      return const BalanceAccountNotFound();
    }
    return BalanceFound(minorUnits: _balances[accountId]!, currencyCode: 'EGP');
  }

  @override
  Future<int> historicalBalanceMinorUnits({
    required String accountId,
    required String householdId,
    required String asOfDate,
  }) async => _balances[accountId] ?? 0;

  @override
  Future<List<AccountBalance>> netWorthBalances({
    required String householdId,
  }) async => [];
}
