import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/goals/presentation/goal_money_formatter.dart';
import 'package:family_money_manager/features/goals/presentation/providers/goal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Screen listing all savings goals for the current household.
///
/// Shows each goal's name, purpose, currency, target, reserve balance,
/// progress percentage, lifecycle badge, and derived progress badge
/// (text + icon, never color alone). No mixed-currency totals.
class GoalsListScreen extends ConsumerWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final goalsAsync = ref.watch(goalsProvider(_householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_goals',
        onPressed: () => context.push('/goals/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.goalNew),
      ),
      body: goalsAsync.when(
        loading: () => AppLoadingState(message: l10n.loadingLabel),
        error: (_, _) => AppErrorState(
          message: l10n.errorGeneric,
          retryLabel: l10n.retryAction,
          onRetry: () => ref.invalidate(goalsProvider(_householdId)),
        ),
        data: (result) {
          if (result is! AppOk<List<SavingsGoal>>) {
            return AppErrorState(message: l10n.errorGeneric);
          }
          final goals = result.value;
          if (goals.isEmpty) {
            return AppEmptyState(
              title: l10n.goalEmpty,
              icon: Icons.flag_outlined,
              actionLabel: l10n.goalNew,
              onAction: () => context.push('/goals/new'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space16,
              100,
            ),
            itemCount: goals.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppTheme.space8),
            itemBuilder: (context, index) => _GoalCard(goal: goals[index]),
          );
        },
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progressAsync = ref.watch(goalProgressProvider(goal.id));

    return Card(
      child: InkWell(
        onTap: () => context.push('/goals/${goal.id}'),
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
                      goal.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _LifecycleBadge(status: goal.status, l10n: l10n),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _purposeLabel(goal.purpose, l10n),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              progressAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (result) {
                  if (result is! AppOk<GoalProgress>) {
                    return const SizedBox.shrink();
                  }
                  final progress = result.value;
                  final pct = progress.percentageFunded ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProgressBadge(state: progress.progressState, l10n: l10n),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${goal.currencyCode} ${GoalMoneyFormatter.format(progress.reserveBalanceMinorUnits, goal.currencyCode)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            l10n.goalPercent(pct),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${goal.currencyCode} ${GoalMoneyFormatter.format(goal.targetMinorUnits, goal.currencyCode)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _purposeLabel(GoalPurpose purpose, AppLocalizations l10n) =>
      switch (purpose) {
        GoalPurpose.emergencyFund => l10n.purposeEmergencyFund,
        GoalPurpose.homePurchase => l10n.purposeHomePurchase,
        GoalPurpose.education => l10n.purposeEducation,
        GoalPurpose.travel => l10n.purposeTravel,
        GoalPurpose.majorPurchase => l10n.purposeMajorPurchase,
        GoalPurpose.familyEvent => l10n.purposeFamilyEvent,
        GoalPurpose.other => l10n.purposeOther,
      };
}

class _LifecycleBadge extends StatelessWidget {
  const _LifecycleBadge({required this.status, required this.l10n});

  final GoalStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (status) {
      GoalStatus.active => (l10n.goalStatusActive, Icons.radio_button_checked),
      GoalStatus.completed => (l10n.goalStatusCompleted, Icons.check_circle),
      GoalStatus.archived => (l10n.goalStatusArchived, Icons.archive_outlined),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.state, required this.l10n});

  final GoalProgressState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (state) {
      GoalProgressState.notStarted => (
        l10n.goalProgressNotStarted,
        Icons.flag_outlined,
      ),
      GoalProgressState.inProgress => (
        l10n.goalProgressInProgress,
        Icons.trending_up,
      ),
      GoalProgressState.targetReached => (
        l10n.goalProgressTargetReached,
        Icons.flag,
      ),
      GoalProgressState.overfunded => (
        l10n.goalProgressOverfunded,
        Icons.insights,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
