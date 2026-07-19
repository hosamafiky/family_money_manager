import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/reports/data/report_query_repository.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';

final class GetSpouseWalletReportUseCase {
  const GetSpouseWalletReportUseCase(this._repository);

  final ReportQueryRepository _repository;

  Future<AppResult<List<SpouseWalletReport>>> execute(
    FinancialReportRequest req,
  ) async {
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
      final data = await _repository.spouseWalletReports(req);
      return AppOk(data);
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}
