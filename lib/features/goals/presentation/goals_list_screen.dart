import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
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
/// progress percentage, and status badge (text + icon, never color alone).
/// No mixed-currency totals are displayed.
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (result) {
          if (result is! AppOk<List<SavingsGoal>>) {
            return Center(child: Text(l10n.goalEmpty));
          }
          final goals = result.value;
          if (goals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.goalEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/goals/new'),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.goalNew),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: goals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                  _StatusBadge(status: goal.status, l10n: l10n),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.l10n});

  final GoalStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (status) {
      GoalStatus.active => (l10n.goalStatusActive, Icons.radio_button_checked),
      GoalStatus.targetReached => (
        l10n.goalStatusTargetReached,
        Icons.check_circle_outline,
      ),
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
