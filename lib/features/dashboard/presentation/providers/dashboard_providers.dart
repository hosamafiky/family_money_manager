import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/features/dashboard/application/get_dashboard_summary_use_case.dart';
import 'package:family_money_manager/features/dashboard/data/dashboard_query_repository.dart';
import 'package:family_money_manager/features/dashboard/data/drift_dashboard_query_repository.dart';
import 'package:family_money_manager/features/dashboard/domain/dashboard_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Clock ─────────────────────────────────────────────────────────────────────

/// Provides the application clock. Override in tests with a fake [Clock].
final clockProvider = Provider<Clock>((ref) => const SystemClock());

// ── Repository ────────────────────────────────────────────────────────────────

final dashboardQueryRepositoryProvider = Provider<DashboardQueryRepository>((ref) {
  return DriftDashboardQueryRepository(ref.watch(appDatabaseProvider));
});

// ── Use case ──────────────────────────────────────────────────────────────────

final getDashboardSummaryUseCaseProvider = Provider<GetDashboardSummaryUseCase>((ref) {
  return GetDashboardSummaryUseCase(queryRepository: ref.watch(dashboardQueryRepositoryProvider), clock: ref.watch(clockProvider));
});

// ── Period state ──────────────────────────────────────────────────────────────

/// Notifier that manages the currently selected dashboard period.
///
/// Public so that tests can override it with a fixed-period subclass.
class DashboardPeriodNotifier extends Notifier<DashboardPeriod> {
  @override
  DashboardPeriod build() {
    final clock = ref.watch(clockProvider);
    return DashboardPeriod.currentMonth(clock);
  }

  /// Replace the active period. Called from the period-selector widget.
  void setPeriod(DashboardPeriod period) => state = period;
}

/// The currently selected dashboard period.
///
/// Defaults to the current calendar month in local time.
/// Widgets and the period selector update this to trigger re-fetch.
final dashboardPeriodProvider = NotifierProvider<DashboardPeriodNotifier, DashboardPeriod>(DashboardPeriodNotifier.new);

// ── Dashboard summary ─────────────────────────────────────────────────────────

/// Async dashboard summary, re-fetched whenever the period changes.
///
/// Parameterised by [householdId] so that multiple households can be watched
/// independently (V1 only ever uses 'household-v1').
final dashboardSummaryProvider = FutureProvider.autoDispose.family<AppResult<DashboardSummary>, String>((ref, householdId) async {
  final period = ref.watch(dashboardPeriodProvider);
  final useCase = ref.watch(getDashboardSummaryUseCaseProvider);
  return useCase.execute(householdId: householdId, period: period);
});
