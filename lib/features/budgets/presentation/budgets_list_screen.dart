import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';
import 'package:family_money_manager/features/budgets/presentation/providers/budget_providers.dart';
import 'package:family_money_manager/features/reports/presentation/report_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Screen listing all budget plans for the current household.
class BudgetsListScreen extends ConsumerStatefulWidget {
  const BudgetsListScreen({super.key});

  @override
  ConsumerState<BudgetsListScreen> createState() => _BudgetsListScreenState();
}

class _BudgetsListScreenState extends ConsumerState<BudgetsListScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final budgetsAsync = ref.watch(budgetsProvider(_householdId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgetsTitle),
        actions: [
          IconButton(
            icon: Icon(
              _showArchived ? Icons.visibility_off : Icons.archive_outlined,
              semanticLabel: _showArchived ? 'Hide archived' : 'Show archived',
            ),
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_budgets',
        onPressed: () => context.push('/budgets/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.budgetNew),
      ),
      body: budgetsAsync.when(
        loading: () => AppLoadingState(message: l10n.loadingLabel),
        error: (_, _) => AppErrorState(
          message: l10n.errorGeneric,
          retryLabel: l10n.retryAction,
          onRetry: () => ref.invalidate(budgetsProvider(_householdId)),
        ),
        data: (result) {
          if (result is! AppOk<List<BudgetPlan>>) {
            return Center(child: Text(l10n.budgetEmpty));
          }
          final allPlans = result.value;
          final plans = _showArchived
              ? allPlans
              : allPlans.where((p) => !p.isArchived).toList();

          if (plans.isEmpty) {
            return AppEmptyState(
              title: l10n.budgetEmpty,
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: l10n.budgetNew,
              onAction: () => context.push('/budgets/new'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space16,
              100,
            ),
            itemCount: plans.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppTheme.space8),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _BudgetCard(plan: plan);
            },
          );
        },
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.plan});

  final BudgetPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progressAsync = ref.watch(budgetProgressProvider(plan.id));

    return Card(
      child: InkWell(
        onTap: () => context.push('/budgets/${plan.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (plan.isArchived)
                    Chip(
                      label: Text(
                        l10n.budgetArchived,
                        style: const TextStyle(fontSize: 11),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    plan.currencyCode,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              progressAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(e.toString()),
                data: (result) {
                  if (result is! AppOk<BudgetProgress>) {
                    return Text(l10n.budgetEmpty);
                  }
                  final progress = result.value;
                  return _ProgressSection(progress: progress, l10n: l10n);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.progress, required this.l10n});

  final BudgetProgress progress;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final consumed = ReportAmountText.formatMinorUnits(
      progress.consumedMinorUnits,
      progress.currencyCode,
    );
    final limit = ReportAmountText.formatMinorUnits(
      progress.limitMinorUnits,
      progress.currencyCode,
    );
    final pct = progress.percentageUsed;
    final fraction = progress.limitMinorUnits > 0
        ? (progress.consumedMinorUnits / progress.limitMinorUnits).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    return Semantics(
      label:
          '${l10n.budgetConsumed}: $consumed. ${l10n.budgetLimit}: $limit.'
          '${pct != null ? ' ${l10n.budgetPercent(pct)}.' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$consumed / $limit',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (pct != null)
                Text(
                  l10n.budgetPercent(pct),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
            child: LinearProgressIndicator(value: fraction, minHeight: 8),
          ),
          const SizedBox(height: AppTheme.space8),
          _StatusBadge(state: progress.usageState, l10n: l10n),
        ],
      ),
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
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
