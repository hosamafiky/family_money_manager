import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/goals/application/goal_use_cases.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/goals/presentation/goal_money_formatter.dart';
import 'package:family_money_manager/features/goals/presentation/providers/goal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Detail screen for a single savings goal.
///
/// Shows: name, purpose, currency, target, reserve balance, remaining,
/// percentage, status, progress bar, movements list, revisions, and action
/// buttons. Status badge always uses text + icon, never color alone.
class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({required this.goalId, super.key});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progressAsync = ref.watch(goalProgressProvider(goalId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalsTitle)),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (result) {
          if (result is! AppOk<GoalProgress>) {
            return Center(child: Text(l10n.goalEmpty));
          }
          return _GoalDetailContent(progress: result.value, goalId: goalId);
        },
      ),
    );
  }
}

class _GoalDetailContent extends ConsumerWidget {
  const _GoalDetailContent({required this.progress, required this.goalId});

  final GoalProgress progress;
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final goal = progress.goal;
    final pct = progress.percentageFunded ?? 0;
    final isActive =
        goal.status == GoalStatus.active ||
        goal.status == GoalStatus.targetReached;
    final canArchive =
        goal.status != GoalStatus.archived &&
        progress.reserveBalanceMinorUnits == 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status badge (text + icon — no color alone)
        Row(
          children: [
            Expanded(
              child: Text(
                goal.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            _StatusBadge(status: goal.status, l10n: l10n),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _purposeLabel(goal.purpose, l10n),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        // Progress section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: l10n.goalReserveBalance,
                  value:
                      '${goal.currencyCode} ${_fmt(progress.reserveBalanceMinorUnits)}',
                ),
                _InfoRow(
                  label: l10n.goalTarget,
                  value: '${goal.currencyCode} ${_fmt(goal.targetMinorUnits)}',
                ),
                _InfoRow(
                  label: l10n.goalRemaining,
                  value:
                      '${goal.currencyCode} ${_fmt(progress.remainingMinorUnits)}',
                ),
                if (progress.overfundedMinorUnits > 0)
                  _InfoRow(
                    label: l10n.goalOverfunded,
                    value:
                        '${goal.currencyCode} ${_fmt(progress.overfundedMinorUnits)}',
                  ),
                _InfoRow(
                  label: l10n.goalPercent(pct),
                  value: _progressStateLabel(progress.progressState, l10n),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Child-fund separation note
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.goalChildFundNote)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Action buttons
        if (isActive)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/goals/$goalId/fund'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.goalFundAction),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/goals/$goalId/release'),
                  icon: const Icon(Icons.arrow_upward),
                  label: Text(l10n.goalReleaseAction),
                ),
              ),
            ],
          ),
        if (isActive) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final uc = ref.read(completeGoalUseCaseProvider);
              await uc.execute(
                CompleteGoalParams(
                  goalId: goalId,
                  householdId: _householdId,
                  idempotencyKey: 'complete-$goalId',
                  earlyCompletion: true,
                  earlyCompletionConfirmed: true,
                  earlyCompletionReason: 'Completed from goal detail screen',
                ),
              );
              ref.invalidate(goalProgressProvider(goalId));
              ref.invalidate(goalsProvider(_householdId));
            },
            icon: const Icon(Icons.check_circle_outline),
            label: Text(l10n.goalCompleteAction),
          ),
        ],
        if (canArchive) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final uc = ref.read(archiveGoalUseCaseProvider);
              await uc.execute(goalId: goalId, householdId: _householdId);
              ref.invalidate(goalProgressProvider(goalId));
              ref.invalidate(goalsProvider(_householdId));
            },
            icon: const Icon(Icons.archive_outlined),
            label: Text(l10n.goalArchiveAction),
          ),
        ],
        if (goal.status == GoalStatus.archived) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final uc = ref.read(restoreGoalUseCaseProvider);
              await uc.execute(goalId: goalId);
              ref.invalidate(goalProgressProvider(goalId));
              ref.invalidate(goalsProvider(_householdId));
            },
            icon: const Icon(Icons.restore),
            label: Text(l10n.goalRestoreAction),
          ),
        ],

        // Movements list
        if (progress.movements.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.goalMovementFunding,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...progress.movements.map(
            (m) => ListTile(
              leading: Icon(
                m.movementType == GoalMovementType.funding
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
              ),
              title: Text(
                m.movementType == GoalMovementType.funding
                    ? l10n.goalMovementFunding
                    : l10n.goalMovementRelease,
              ),
              subtitle: Text(m.releaseReason ?? m.createdAt.substring(0, 10)),
              onTap: () =>
                  context.push('/transactions/${m.transferOperationId}'),
            ),
          ),
        ],

        // Revisions history
        if (progress.revisions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.goalRevisions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...progress.revisions.map(
            (r) => ListTile(
              title: Text(r.name),
              subtitle: Text(
                '${goal.currencyCode} ${_fmt(r.targetMinorUnits)} · ${r.revisionReason}',
              ),
              trailing: Text(
                r.createdAt.length >= 10
                    ? r.createdAt.substring(0, 10)
                    : r.createdAt,
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  String _fmt(int minorUnits) =>
      GoalMoneyFormatter.format(minorUnits, progress.currencyCode);

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

  String _progressStateLabel(GoalProgressState state, AppLocalizations l10n) =>
      switch (state) {
        GoalProgressState.notStarted => l10n.goalProgressNotStarted,
        GoalProgressState.inProgress => l10n.goalProgressInProgress,
        GoalProgressState.targetReached => l10n.goalProgressTargetReached,
        GoalProgressState.overfunded => l10n.goalProgressOverfunded,
      };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
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
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
