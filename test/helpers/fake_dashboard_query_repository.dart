import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/dashboard/data/dashboard_query_repository.dart';
import 'package:family_money_manager/features/dashboard/domain/dashboard_summary.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';

/// Configurable fake implementation of [DashboardQueryRepository] for tests.
final class FakeDashboardQueryRepository implements DashboardQueryRepository {
  FakeDashboardQueryRepository({
    List<CurrencyAmountSummary>? spendable,
    List<CurrencyAmountSummary>? protected,
    List<PeriodFlowSummary>? flow,
    List<ExpenseScopeSummary>? scopes,
    List<SpouseWalletDashboardSummary>? wallets,
    List<TransactionSummary>? recent,
    bool throwOnCall = false,
  }) : _spendable = spendable ?? const [],
       _protected = protected ?? const [],
       _flow = flow ?? const [],
       _scopes = scopes ?? const [],
       _wallets = wallets ?? const [],
       _recent = recent ?? const [],
       _throwOnCall = throwOnCall;

  final List<CurrencyAmountSummary> _spendable;
  final List<CurrencyAmountSummary> _protected;
  final List<PeriodFlowSummary> _flow;
  final List<ExpenseScopeSummary> _scopes;
  final List<SpouseWalletDashboardSummary> _wallets;
  final List<TransactionSummary> _recent;
  final bool _throwOnCall;

  @override
  Future<List<CurrencyAmountSummary>> spendableBalances({required String householdId}) async {
    if (_throwOnCall) throw Exception('Fake error');
    return _spendable;
  }

  @override
  Future<List<CurrencyAmountSummary>> protectedBalances({required String householdId}) async {
    if (_throwOnCall) throw Exception('Fake error');
    return _protected;
  }

  @override
  Future<List<PeriodFlowSummary>> periodFlow({
    required String householdId,
    required DashboardPeriod period,
  }) async {
    if (_throwOnCall) throw Exception('Fake error');
    return _flow;
  }

  @override
  Future<List<ExpenseScopeSummary>> expensesByScope({
    required String householdId,
    required DashboardPeriod period,
  }) async {
    if (_throwOnCall) throw Exception('Fake error');
    return _scopes;
  }

  @override
  Future<List<SpouseWalletDashboardSummary>> spouseWalletSummaries({
    required String householdId,
    required DashboardPeriod period,
  }) async {
    if (_throwOnCall) throw Exception('Fake error');
    return _wallets;
  }

  @override
  Future<List<TransactionSummary>> recentActivity({
    required String householdId,
    int limit = 20,
  }) async {
    if (_throwOnCall) throw Exception('Fake error');
    return _recent;
  }
}
