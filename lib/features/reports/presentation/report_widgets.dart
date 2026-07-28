/// Shared widgets for all report screens.
library;

import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
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

// ── Loading / error / empty states ────────────────────────────────────────────

class ReportLoading extends StatelessWidget {
  const ReportLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class ReportErrorState extends StatelessWidget {
  const ReportErrorState({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(l10n.reportError),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: Text(l10n.reportRefresh),
          ),
        ],
      ),
    );
  }
}

class ReportEmptyState extends StatelessWidget {
  const ReportEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Text(
        l10n.reportEmpty,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Amount formatting ─────────────────────────────────────────────────────────

/// Formats and displays a minor-unit amount with currency code.
class ReportAmountText extends StatelessWidget {
  const ReportAmountText({
    required this.minorUnits,
    required this.currencyCode,
    this.color,
    this.bold = false,
    super.key,
  });

  final int minorUnits;
  final String currencyCode;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final text = formatMinorUnits(minorUnits, currencyCode);
    return Semantics(
      label: '$text $currencyCode',
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static String formatMinorUnits(int minorUnits, String currencyCode) {
    int scale;
    try {
      scale = Currency.fromCode(currencyCode).minorUnitScale;
    } catch (_) {
      scale = 2;
    }

    if (scale == 0) {
      return '$currencyCode $minorUnits';
    }

    final divisor = _pow10(scale);
    final absUnits = minorUnits.abs();
    final major = absUnits ~/ divisor;
    final minor = (absUnits % divisor).toString().padLeft(scale, '0');
    final sign = minorUnits < 0 ? '-' : '';
    return '$currencyCode $sign$major.$minor';
  }

  static int _pow10(int exp) {
    var result = 1;
    for (var i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }
}

// ── Labelled amount row ───────────────────────────────────────────────────────

class ReportAmountRow extends StatelessWidget {
  const ReportAmountRow({
    required this.label,
    required this.minorUnits,
    required this.currencyCode,
    this.color,
    this.icon,
    this.bold = false,
    super.key,
  });

  final String label;
  final int minorUnits;
  final String currencyCode;
  final Color? color;
  final IconData? icon;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: bold ? FontWeight.w600 : null,
              ),
            ),
          ),
          ReportAmountText(
            minorUnits: minorUnits,
            currencyCode: currencyCode,
            color: color,
            bold: bold,
          ),
        ],
      ),
    );
  }
}

// ── Currency section header ───────────────────────────────────────────────────

class CurrencyHeader extends StatelessWidget {
  const CurrencyHeader({required this.currencyCode, super.key});

  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        currencyCode,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Info note ─────────────────────────────────────────────────────────────────

class ReportInfoNote extends StatelessWidget {
  const ReportInfoNote({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: context.financialColors.neutralInfo,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.financialColors.neutralInfo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
