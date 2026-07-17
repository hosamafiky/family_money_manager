import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/reports/data/report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';

/// Attribution report: expense by spender, beneficiary, and scope.
final class SpendingAttributionReport {
  const SpendingAttributionReport({
    required this.bySpender,
    required this.byBeneficiary,
    required this.byScope,
  });

  final List<MemberSpendingBreakdown> bySpender;
  final List<MemberSpendingBreakdown> byBeneficiary;
  final List<ExpenseScopeBreakdown> byScope;
}

final class GetSpendingAttributionReportUseCase {
  const GetSpendingAttributionReportUseCase(this._repository);

  final ReportQueryRepository _repository;

  Future<AppResult<SpendingAttributionReport>> execute(FinancialReportRequest req) async {
    if (req.householdId.isEmpty) {
      return const AppValidationFailure(field: 'householdId', messageKey: 'errorValidationGeneric');
    }
    if (req.period.startDate.compareTo(req.period.endDate) >= 0) {
      return const AppValidationFailure(field: 'period', messageKey: 'errorValidationGeneric');
    }
    try {
      final bySpender = await _repository.expenseBySpender(req);
      final byBeneficiary = await _repository.expenseByBeneficiary(req);
      final byScope = await _repository.expenseByScope(req);
      return AppOk(
        SpendingAttributionReport(
          bySpender: bySpender,
          byBeneficiary: byBeneficiary,
          byScope: byScope,
        ),
      );
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}
