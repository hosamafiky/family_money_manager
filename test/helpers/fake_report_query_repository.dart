import 'package:family_money_manager/features/reports/application/get_spending_attribution_report_use_case.dart';
import 'package:family_money_manager/features/reports/data/report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';

/// Configurable fake implementation of [ReportQueryRepository] for widget tests.
final class FakeReportQueryRepository implements ReportQueryRepository {
  FakeReportQueryRepository({
    List<CurrencyFlowSummary>? incomeExpenseFlows,
    SpendingAttributionReport? attribution,
    List<CategoryBreakdown>? expenseByCategory,
    List<CategoryBreakdown>? incomeByCategory,
    List<AccountFlowBreakdown>? accountFlows,
    List<HomeSavingsFlowSummary>? homeSavingsFlows,
    List<SpouseWalletReport>? spouseWalletReports,
    List<ProtectedFundsSummary>? protectedFundsReports,
    List<ReportTransactionRow>? drillDownRows,
    bool throwOnCall = false,
  }) : _incomeExpenseFlows = incomeExpenseFlows ?? const [],
       _attribution =
           attribution ??
           const SpendingAttributionReport(bySpender: [], byBeneficiary: [], byScope: []),
       _expenseByCategory = expenseByCategory ?? const [],
       _incomeByCategory = incomeByCategory ?? const [],
       _accountFlows = accountFlows ?? const [],
       _homeSavingsFlows = homeSavingsFlows ?? const [],
       _spouseWalletReports = spouseWalletReports ?? const [],
       _protectedFundsReports = protectedFundsReports ?? const [],
       _drillDownRows = drillDownRows ?? const [],
       _throwOnCall = throwOnCall;

  final List<CurrencyFlowSummary> _incomeExpenseFlows;
  final SpendingAttributionReport _attribution;
  final List<CategoryBreakdown> _expenseByCategory;
  final List<CategoryBreakdown> _incomeByCategory;
  final List<AccountFlowBreakdown> _accountFlows;
  final List<HomeSavingsFlowSummary> _homeSavingsFlows;
  final List<SpouseWalletReport> _spouseWalletReports;
  final List<ProtectedFundsSummary> _protectedFundsReports;
  final List<ReportTransactionRow> _drillDownRows;
  final bool _throwOnCall;

  void _maybeThrow() {
    if (_throwOnCall) throw Exception('FakeReportQueryRepository: fake error');
  }

  @override
  Future<List<CurrencyFlowSummary>> incomeExpenseFlow(FinancialReportRequest req) async {
    _maybeThrow();
    return _incomeExpenseFlows;
  }

  @override
  Future<List<ExpenseScopeBreakdown>> expenseByScope(FinancialReportRequest req) async {
    _maybeThrow();
    return _attribution.byScope;
  }

  @override
  Future<List<MemberSpendingBreakdown>> expenseBySpender(FinancialReportRequest req) async {
    _maybeThrow();
    return _attribution.bySpender;
  }

  @override
  Future<List<MemberSpendingBreakdown>> expenseByBeneficiary(FinancialReportRequest req) async {
    _maybeThrow();
    return _attribution.byBeneficiary;
  }

  @override
  Future<List<CategoryBreakdown>> expenseByCategory(FinancialReportRequest req) async {
    _maybeThrow();
    return _expenseByCategory;
  }

  @override
  Future<List<CategoryBreakdown>> incomeByCategory(FinancialReportRequest req) async {
    _maybeThrow();
    return _incomeByCategory;
  }

  @override
  Future<List<AccountFlowBreakdown>> accountFlows(FinancialReportRequest req) async {
    _maybeThrow();
    return _accountFlows;
  }

  @override
  Future<List<HomeSavingsFlowSummary>> homeSavingsFlows(FinancialReportRequest req) async {
    _maybeThrow();
    return _homeSavingsFlows;
  }

  @override
  Future<List<SpouseWalletReport>> spouseWalletReports(FinancialReportRequest req) async {
    _maybeThrow();
    return _spouseWalletReports;
  }

  @override
  Future<List<ProtectedFundsSummary>> protectedFundsReports(FinancialReportRequest req) async {
    _maybeThrow();
    return _protectedFundsReports;
  }

  @override
  Future<List<ReportTransactionRow>> drillDown(
    FinancialReportRequest req, {
    int limit = 100,
  }) async {
    _maybeThrow();
    return _drillDownRows;
  }
}
