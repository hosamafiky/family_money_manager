import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';
import 'package:family_money_manager/features/budgets/presentation/providers/budget_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_widgets.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen showing detailed budget progress and drill-down transactions.
class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({required this.budgetId, super.key});

  final String budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progressAsync = ref.watch(budgetProgressProvider(budgetId));

    return Scaffold(
      appBar: AppBar(
        title: progressAsync.when(
          loading: () => Text(l10n.budgetsTitle),
          error: (_, _) => Text(l10n.budgetsTitle),
          data: (result) => Text(
            result is AppOk<BudgetProgress>
                ? result.value.budget.name
                : l10n.budgetsTitle,
          ),
        ),
        actions: [
          progressAsync.whenData((result) {
                if (result is! AppOk<BudgetProgress>) {
                  return const SizedBox.shrink();
                }
                final progress = result.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () =>
                          _toggleArchive(context, ref, progress.budget),
                      child: Text(
                        progress.budget.isArchived
                            ? l10n.budgetRestore
                            : l10n.budgetArchive,
                      ),
                    ),
                  ],
                );
              }).value ??
              const SizedBox.shrink(),
        ],
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (result) {
          if (result is! AppOk<BudgetProgress>) {
            return Center(child: Text(l10n.budgetEmpty));
          }
          final progress = result.value;
          return _DetailBody(progress: progress, l10n: l10n);
        },
      ),
    );
  }

  Future<void> _toggleArchive(
    BuildContext context,
    WidgetRef ref,
    BudgetPlan plan,
  ) async {
    if (plan.isArchived) {
      await ref.read(restoreBudgetUseCaseProvider).execute(plan.id);
    } else {
      await ref.read(archiveBudgetUseCaseProvider).execute(plan.id);
    }
    ref.invalidate(budgetProgressProvider(budgetId));
    ref.invalidate(budgetDetailProvider(budgetId));
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.progress, required this.l10n});

  final BudgetProgress progress;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = progress.budget;
    final currency = progress.currencyCode;
    final consumed = ReportAmountText.formatMinorUnits(
      progress.consumedMinorUnits,
      currency,
    );
    final limit = ReportAmountText.formatMinorUnits(
      progress.limitMinorUnits,
      currency,
    );
    final remaining = ReportAmountText.formatMinorUnits(
      progress.remainingMinorUnits.abs(),
      currency,
    );
    final pct = progress.percentageUsed;
    final fraction = progress.limitMinorUnits > 0
        ? (progress.consumedMinorUnits / progress.limitMinorUnits).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    final isMonthly = plan.periodDefinition is MonthlyBudgetPeriod;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.periodStart} → ${progress.periodEnd}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 12),

                // Consumed / limit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.budgetConsumed,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          consumed,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.budgetRemaining,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          remaining,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: progress.remainingMinorUnits < 0
                                    ? Colors.red
                                    : null,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Limit: $limit / ${pct != null ? l10n.budgetPercent(pct) : '-'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),

                // Status badge
                _StatusBadge(state: progress.usageState, l10n: l10n),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Reversal note
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.budgetReversalNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Drill-down transactions
        Text(
          l10n.transactionsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (progress.drillDown.isEmpty)
          Text(
            l10n.budgetNoMatching,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          ...progress.drillDown.map(
            (row) => ListTile(
              dense: true,
              leading: Icon(
                row.isReversed
                    ? Icons.undo_outlined
                    : Icons.receipt_long_outlined,
                size: 20,
              ),
              title: Text(
                ReportAmountText.formatMinorUnits(
                  row.amountMinorUnits,
                  row.currencyCode,
                ),
              ),
              subtitle: Text(
                row.categoryCode != null
                    ? '${row.effectiveDate} · ${categoryLabelFromCode(l10n, row.categoryCode!)}'
                    : row.effectiveDate,
              ),
              trailing: row.note != null
                  ? Tooltip(
                      message: row.note!,
                      child: const Icon(Icons.notes, size: 16),
                    )
                  : null,
              onTap: () => context.push('/transactions/${row.operationId}'),
            ),
          ),

        // Previous periods section (monthly only)
        if (isMonthly) ...[
          const SizedBox(height: 24),
          Text(
            l10n.budgetPreviousPeriods,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _PreviousPeriodsSection(budgetId: plan.id, l10n: l10n),
        ],
      ],
    );
  }
}

class _PreviousPeriodsSection extends ConsumerWidget {
  const _PreviousPeriodsSection({required this.budgetId, required this.l10n});

  final String budgetId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(budgetHistoryProvider(budgetId));
    return historyAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(e.toString()),
      data: (result) {
        if (result is! AppOk<List<BudgetProgress>>) {
          return Text(l10n.budgetEmpty);
        }
        final history = result.value;
        // Skip the first entry as it is the current month (already shown above)
        final previousMonths = history.skip(1).take(5).toList();
        if (previousMonths.isEmpty) {
          return Text(
            l10n.budgetNoMatching,
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        return Column(
          children: previousMonths.map((p) {
            final consumed = ReportAmountText.formatMinorUnits(
              p.consumedMinorUnits,
              p.currencyCode,
            );
            final limit = ReportAmountText.formatMinorUnits(
              p.limitMinorUnits,
              p.currencyCode,
            );
            return ListTile(
              dense: true,
              title: Text(p.periodStart),
              subtitle: Text('$consumed / $limit'),
              trailing: _StatusBadge(state: p.usageState, l10n: l10n),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state, required this.l10n});

  final BudgetUsageState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (state) {
      BudgetUsageState.noSpending => (
        l10n.budgetStatusNoSpending,
        Icons.circle_outlined,
      ),
      BudgetUsageState.onTrack => (
        l10n.budgetStatusOnTrack,
        Icons.check_circle_outline,
      ),
      BudgetUsageState.nearLimit => (
        l10n.budgetStatusNearLimit,
        Icons.warning_amber_outlined,
      ),
      BudgetUsageState.limitReached => (
        l10n.budgetStatusLimitReached,
        Icons.block_outlined,
      ),
      BudgetUsageState.overBudget => (
        l10n.budgetStatusOverBudget,
        Icons.error_outline,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, semanticLabel: label),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
