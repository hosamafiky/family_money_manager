/// The period selector shared by every report screen.
///
/// All that survives of the old `report_widgets.dart`. Everything else it
/// held — amount text, amount rows, currency headers, loading, error and
/// empty states, info notes — was a second, weaker copy of components the
/// design system already owns, and each copy had drifted: amounts printed
/// with a leading currency code, an ASCII hyphen, no bidi isolation and no
/// tabular figures. This is the one genuinely report-specific piece.
library;

import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:family_money_manager/features/reports/domain/report_models.dart';
import 'package:family_money_manager/features/reports/presentation/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Period selector ───────────────────────────────────────────────────────────

/// Period selector chips shared by all report screens.
///
/// Updates [reportRequestProvider] when a chip is selected.
class ReportPeriodSelector extends ConsumerStatefulWidget {
  const ReportPeriodSelector({super.key});

  @override
  ConsumerState<ReportPeriodSelector> createState() =>
      _ReportPeriodSelectorState();
}

class _ReportPeriodSelectorState extends ConsumerState<ReportPeriodSelector> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(reportRequestProvider);
    final current = req.period;

    // The margin belongs to the scroll view, not to a wrapper: an outer
    // Padding shrinks the viewport, so the chip row stops short of the screen
    // edge instead of running under it.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Chip(
            label: l10n.dashboardPeriodCurrentMonth,
            selected: current.label == DashboardPeriodLabel.currentMonth,
            onSelected: (_) => _setPeriod(
              DashboardPeriod.currentMonth(ref.read(clockProvider)),
            ),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: l10n.dashboardPeriodPreviousMonth,
            selected: current.label == DashboardPeriodLabel.previousMonth,
            onSelected: (_) => _setPeriod(
              DashboardPeriod.previousMonth(ref.read(clockProvider)),
            ),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: l10n.dashboardPeriodCurrentYear,
            selected: current.label == DashboardPeriodLabel.currentYear,
            onSelected: (_) => _setPeriod(
              DashboardPeriod.currentYear(ref.read(clockProvider)),
            ),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: l10n.dashboardPeriodCustom,
            selected: current.label == DashboardPeriodLabel.custom,
            onSelected: (_) => _showDateRangePicker(context),
          ),
        ],
      ),
    );
  }

  void _setPeriod(DashboardPeriod period) {
    final current = ref.read(reportRequestProvider);
    ref
        .read(reportRequestProvider.notifier)
        .update(
          FinancialReportRequest(
            householdId: current.householdId,
            period: period,
            filter: current.filter,
          ),
        );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
    );
    if (range == null) return;

    final startDate = _fmtDate(range.start);
    final endDate = _fmtDate(range.end.add(const Duration(days: 1)));
    _setPeriod(DashboardPeriod.custom(startDate: startDate, endDate: endDate));
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
