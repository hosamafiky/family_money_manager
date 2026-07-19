import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/reports/data/report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';

final class CategoryReport {
  const CategoryReport({
    required this.expenseByCategory,
    required this.incomeByCategory,
  });

  final List<CategoryBreakdown> expenseByCategory;
  final List<CategoryBreakdown> incomeByCategory;
}

final class GetCategoryReportUseCase {
  const GetCategoryReportUseCase(this._repository);

  final ReportQueryRepository _repository;

  Future<AppResult<CategoryReport>> execute(FinancialReportRequest req) async {
    if (req.householdId.isEmpty) {
      return const AppValidationFailure(
        field: 'householdId',
        messageKey: 'errorValidationGeneric',
      );
    }
    if (req.period.startDate.compareTo(req.period.endDate) >= 0) {
      return const AppValidationFailure(
        field: 'period',
        messageKey: 'errorValidationGeneric',
      );
    }
    try {
      final expense = await _repository.expenseByCategory(req);
      final income = await _repository.incomeByCategory(req);
      return AppOk(
        CategoryReport(expenseByCategory: expense, incomeByCategory: income),
      );
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}
