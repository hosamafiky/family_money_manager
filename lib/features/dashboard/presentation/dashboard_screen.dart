import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/dashboard_period.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:family_money_manager/features/dashboard/domain/dashboard_summary.dart';
import 'package:family_money_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// V1 single-household ID.
const _householdId = 'household-v1';

/// Arabic-first dashboard screen with financial summaries.
///
/// Displays: period selector, spendable balances, protected balances,
/// income/expense flow, expense by scope, spouse wallet summaries,
/// and recent activity.
///
/// NO charts. NO net worth. NO mixed-currency totals.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summaryAsync = ref.watch(dashboardSummaryProvider(_householdId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          Semantics(
            label: l10n.dashboardRefresh,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.dashboardRefresh,
              onPressed: () =>
                  ref.invalidate(dashboardSummaryProvider(_householdId)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(dashboardSummaryProvider(_householdId)),
        child: summaryAsync.when(
          loading: () => AppLoadingState(message: l10n.dashboardLoading),
          error: (_, _) => AppErrorState(
            message: l10n.dashboardError,
            retryLabel: l10n.dashboardRetry,
            onRetry: () =>
                ref.invalidate(dashboardSummaryProvider(_householdId)),
          ),
          data: (result) {
            if (result is AppOk<DashboardSummary>) {
              return _DashboardContent(summary: result.value, l10n: l10n);
            }
            return AppErrorState(
              message: l10n.dashboardError,
              retryLabel: l10n.dashboardRetry,
              onRetry: () =>
                  ref.invalidate(dashboardSummaryProvider(_householdId)),
            );
          },
        ),
      ),
    );
  }
}

// Loading / error use shared AppLoadingState / AppErrorState.

// ── Main content ──────────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary, required this.l10n});
  final DashboardSummary summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // The two money regions are full-bleed: a region is defined by its surface
    // and the 2 px rule at its edge, and inset margins would break both. Every
    // other section keeps the screen margin.
    Widget inset(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: child,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: AppTheme.space24),
      children: [
        // 1. Available to spend — the one dominant region on the screen.
        _AvailableToSpendHero(summary: summary, l10n: l10n),
        const SizedBox(height: 12),
        // 2. Quick transaction actions
        inset(_QuickActionsSection(l10n: l10n)),
        const SizedBox(height: 16),
        // 3. Period + income/expense
        _PeriodSelector(l10n: l10n),
        const SizedBox(height: 12),
        inset(_PeriodFlowSection(flows: summary.periodFlow, l10n: l10n)),
        const SizedBox(height: 12),
        // 4. Held money — its own recessed region, never summed with the hero.
        _HeldMoneySection(summary: summary, l10n: l10n),
        const SizedBox(height: 12),
        inset(
          _ExpenseScopesSection(scopes: summary.expensesByScope, l10n: l10n),
        ),
        const SizedBox(height: 12),
        inset(
          _SpouseWalletsSection(wallets: summary.spouseWallets, l10n: l10n),
        ),
        const SizedBox(height: 12),
        // 6. Recent activity
        inset(
          _RecentActivitySection(
            activities: summary.recentActivity,
            l10n: l10n,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.dashboardQuickActions),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () =>
                  _pushIfRouted(context, '/transactions/new/income'),
              icon: const Icon(Icons.south_west, size: 18),
              label: Text(l10n.actionRecordIncome),
            ),
            FilledButton.tonalIcon(
              onPressed: () =>
                  _pushIfRouted(context, '/transactions/new/expense'),
              icon: const Icon(Icons.north_east, size: 18),
              label: Text(l10n.actionRecordExpense),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  _pushIfRouted(context, '/transactions/new/transfer'),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: Text(l10n.actionTransfer),
            ),
          ],
        ),
      ],
    );
  }

  static void _pushIfRouted(BuildContext context, String location) {
    if (GoRouter.maybeOf(context) != null) {
      context.push(location);
    }
  }
}

/// Quiet pointer to Planning for goal reserves and certificate principal
/// without inventing new dashboard aggregates (behavior-preserving).
// ── Period selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends ConsumerStatefulWidget {
  const _PeriodSelector({required this.l10n});
  final AppLocalizations l10n;

  @override
  ConsumerState<_PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends ConsumerState<_PeriodSelector> {
  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final currentPeriod = ref.watch(dashboardPeriodProvider);
    final clock = ref.read(clockProvider);

    return Semantics(
      label: l10n.dashboardPeriodLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: Text(
              l10n.dashboardPeriodLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          // Full-bleed: the margin is on the scroll view so the chips run to
          // the screen edge instead of stopping at an inset viewport.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: Row(
              children: [
                _PeriodChip(
                  label: l10n.dashboardPeriodCurrentMonth,
                  selected:
                      currentPeriod.label == DashboardPeriodLabel.currentMonth,
                  onSelected: (_) => ref
                      .read(dashboardPeriodProvider.notifier)
                      .setPeriod(DashboardPeriod.currentMonth(clock)),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: l10n.dashboardPeriodPreviousMonth,
                  selected:
                      currentPeriod.label == DashboardPeriodLabel.previousMonth,
                  onSelected: (_) => ref
                      .read(dashboardPeriodProvider.notifier)
                      .setPeriod(DashboardPeriod.previousMonth(clock)),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: l10n.dashboardPeriodCurrentYear,
                  selected:
                      currentPeriod.label == DashboardPeriodLabel.currentYear,
                  onSelected: (_) => ref
                      .read(dashboardPeriodProvider.notifier)
                      .setPeriod(DashboardPeriod.currentYear(clock)),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: l10n.dashboardPeriodCustom,
                  selected: currentPeriod.label == DashboardPeriodLabel.custom,
                  onSelected: (_) => _showCustomDatePicker(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
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
    final endDay = range.end.add(const Duration(days: 1));
    final endDate = _fmtDate(endDay);

    ref
        .read(dashboardPeriodProvider.notifier)
        .setPeriod(
          DashboardPeriod.custom(startDate: startDate, endDate: endDate),
        );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final void Function(bool) onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

// ── Spendable balances section ────────────────────────────────────────────────

// ── Protected balances section ────────────────────────────────────────────────

/// The currency's own name. Falls back to the ISO code rather than rendering
/// nothing for a currency the enum does not know.
String _currencyName(AppLocalizations l10n, String code) {
  try {
    return currencyLabel(l10n, Currency.fromCode(code));
  } catch (_) {
    return code;
  }
}

// ── Available-to-spend hero ───────────────────────────────────────────────────

class _AvailableToSpendHero extends StatelessWidget {
  const _AvailableToSpendHero({required this.summary, required this.l10n});

  final DashboardSummary summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // The hero shows availableToSpend, not spendableBalances: the difference
    // is money the household holds but that is not theirs to spend from here,
    // and the query has already done that subtraction.
    final currencies = [
      for (final balance in summary.availableToSpend)
        BalanceHeroCurrency(
          currencyCode: balance.currencyCode,
          currencyLabel: _currencyName(l10n, balance.currencyCode),
          minorUnits: balance.totalMinorUnits,
          // A negative available balance is worth flagging. The notice
          // carries the warning role; the amount never does.
          warningLabel: balance.isNegative
              ? l10n.dashboardNegativeBalanceWarning
              : null,
        ),
    ];

    return BalanceHero(
      label: l10n.dashboardAvailableToSpend,
      currencies: currencies,
      // Stated, never implied: a headline figure that quietly omits money is
      // worse than one that explains what it left out.
      exclusionNote: summary.hasExcludedBalance || summary.hasHeldBalance
          ? l10n.dashboardExcludedFromAvailable
          : null,
    );
  }
}

// ── Held money ────────────────────────────────────────────────────────────────

class _HeldMoneySection extends StatelessWidget {
  const _HeldMoneySection({required this.summary, required this.l10n});

  final DashboardSummary summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final held in summary.heldByReason)
        if (held.totalMinorUnits != 0)
          HeldMoneyEntry(
            name: _reasonLabel(held.reason),
            reasonLabel: l10n.amountNotSpendable,
            minorUnits: held.totalMinorUnits,
            currencyCode: held.currencyCode,
            tone: _reasonTone(held.reason),
          ),
    ];

    // One subtotal per currency. Currencies are never combined, so a
    // household holding both EGP and USD sees two lines, not one sum.
    final subtotals = <String, int>{};
    for (final held in summary.heldByReason) {
      subtotals.update(
        held.currencyCode,
        (existing) => existing + held.totalMinorUnits,
        ifAbsent: () => held.totalMinorUnits,
      );
    }
    subtotals.removeWhere((_, total) => total == 0);

    return HeldMoneyRegion(entries: entries, subtotalsByCurrency: subtotals);
  }

  String _reasonLabel(HeldReason reason) => switch (reason) {
    HeldReason.certificatePrincipal => l10n.heldReasonCertificatePrincipal,
    HeldReason.goalReserve => l10n.heldReasonGoalReserve,
    HeldReason.childProtected => l10n.heldReasonChildProtected,
    HeldReason.other => l10n.heldReasonOther,
  };

  static FinancialAmountTone _reasonTone(HeldReason reason) => switch (reason) {
    HeldReason.certificatePrincipal => FinancialAmountTone.certificate,
    HeldReason.goalReserve => FinancialAmountTone.goal,
    HeldReason.childProtected => FinancialAmountTone.protected,
    HeldReason.other => FinancialAmountTone.neutral,
  };
}

// ── Period flow section ───────────────────────────────────────────────────────

class _PeriodFlowSection extends StatelessWidget {
  const _PeriodFlowSection({required this.flows, required this.l10n});
  final List<PeriodFlowSummary> flows;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '${l10n.dashboardPeriodIncome} / ${l10n.dashboardPeriodExpenses}',
      icon: Icons.swap_vert,
      child: flows.isEmpty
          ? _EmptyState(message: l10n.dashboardPeriodNoActivity)
          : Column(
              children: flows
                  .map((f) => _FlowRow(flow: f, l10n: l10n))
                  .toList(),
            ),
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({required this.flow, required this.l10n});
  final PeriodFlowSummary flow;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final net = flow.netIncomeMinorUnits - flow.netExpenseMinorUnits;
    final hasExpenseReversal = flow.expenseReversalMinorUnits != 0;
    final hasIncomeReversal = flow.incomeReversalMinorUnits != 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _LabelledAmount(
            label: l10n.dashboardPeriodIncome,
            minorUnits: flow.grossIncomeMinorUnits,
            currencyCode: flow.currencyCode,
            color: context.financialColors.income,
            icon: Icons.arrow_downward,
          ),
          if (hasIncomeReversal) ...[
            _LabelledAmount(
              label: l10n.reportReversalEffect,
              minorUnits: -flow.incomeReversalMinorUnits,
              currencyCode: flow.currencyCode,
              color: context.financialColors.secondaryText,
              icon: Icons.undo,
            ),
          ],
          _LabelledAmount(
            label: l10n.dashboardPeriodExpenses,
            minorUnits: flow.netExpenseMinorUnits,
            currencyCode: flow.currencyCode,
            color: context.financialColors.expense,
            icon: Icons.arrow_upward,
          ),
          if (hasExpenseReversal) ...[
            _LabelledAmount(
              label: l10n.reportReversalEffect,
              minorUnits: -flow.expenseReversalMinorUnits,
              currencyCode: flow.currencyCode,
              color: context.financialColors.secondaryText,
              icon: Icons.undo,
            ),
          ],
          _LabelledAmount(
            label: l10n.dashboardPeriodNet,
            minorUnits: net,
            currencyCode: flow.currencyCode,
            color: net >= 0
                ? context.financialColors.income
                : context.financialColors.expense,
            icon: Icons.calculate_outlined,
          ),
          const Divider(height: 8),
        ],
      ),
    );
  }
}

// ── Expense by scope section ──────────────────────────────────────────────────

class _ExpenseScopesSection extends StatelessWidget {
  const _ExpenseScopesSection({required this.scopes, required this.l10n});
  final List<ExpenseScopeSummary> scopes;
  final AppLocalizations l10n;

  String _scopeLabel(ExpenseScope scope) =>
      expenseScopeDashboardLabel(l10n, scope);

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: l10n.dashboardPeriodExpenses,
      icon: Icons.donut_small_outlined,
      child: scopes.isEmpty
          ? _EmptyState(message: l10n.dashboardScopeNoActivity)
          : Column(
              children: scopes
                  .map(
                    (s) => _LabelledAmount(
                      label: _scopeLabel(s.scope),
                      minorUnits: s.totalMinorUnits,
                      currencyCode: s.currencyCode,
                      color: null,
                      icon: Icons.label_outline,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

// ── Spouse wallets section ────────────────────────────────────────────────────

class _SpouseWalletsSection extends StatelessWidget {
  const _SpouseWalletsSection({required this.wallets, required this.l10n});
  final List<SpouseWalletDashboardSummary> wallets;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: l10n.dashboardSpouseWallet,
      icon: Icons.wallet_outlined,
      child: wallets.isEmpty
          ? _EmptyState(message: l10n.dashboardNoSpouseWallet)
          : Column(
              children: wallets
                  .map((w) => _WalletSubSection(wallet: w, l10n: l10n))
                  .toList(),
            ),
    );
  }
}

class _WalletSubSection extends StatelessWidget {
  const _WalletSubSection({required this.wallet, required this.l10n});
  final SpouseWalletDashboardSummary wallet;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(wallet.accountName, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        _LabelledAmount(
          label: l10n.dashboardSpouseWalletFunded,
          minorUnits: wallet.periodFundedMinorUnits,
          currencyCode: wallet.currencyCode,
          color: context.financialColors.income,
          icon: Icons.add_circle_outline,
        ),
        _LabelledAmount(
          label: l10n.dashboardSpouseWalletSpent,
          minorUnits: wallet.periodSpentMinorUnits,
          currencyCode: wallet.currencyCode,
          color: context.financialColors.expense,
          icon: Icons.remove_circle_outline,
        ),
        _LabelledAmount(
          label: l10n.dashboardSpouseWalletReturned,
          minorUnits: wallet.periodReturnedMinorUnits,
          currencyCode: wallet.currencyCode,
          color: null,
          icon: Icons.undo,
        ),
        _LabelledAmount(
          label: l10n.dashboardSpouseWalletBalance,
          minorUnits: wallet.currentBalanceMinorUnits,
          currencyCode: wallet.currencyCode,
          color: null,
          icon: Icons.account_balance_outlined,
        ),
        const Divider(height: 16),
      ],
    );
  }
}

// ── Recent activity section ───────────────────────────────────────────────────

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.activities, required this.l10n});
  final List<TransactionSummary> activities;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: l10n.dashboardRecentActivity,
      icon: Icons.history,
      trailing: TextButton(
        onPressed: () => context.go('/transactions'),
        child: Text(l10n.dashboardViewAll),
      ),
      child: activities.isEmpty
          ? _EmptyState(message: l10n.dashboardNoRecentActivity)
          : Column(
              children: activities
                  .map((a) => _ActivityRow(activity: a, l10n: l10n))
                  .toList(),
            ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.l10n});
  final TransactionSummary activity;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final op = activity.operation;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: _OperationTypeIcon(typeCode: op.type.code),
      title: Row(
        children: [
          Flexible(
            child: Text(
              op.description ?? operationTypeLabel(l10n, op.type),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (op.isReversed) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: context.financialColors.secondarySurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.transactionReversed,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.financialColors.secondaryText,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(op.effectiveDate),
      trailing: _AmountText(
        minorUnits: op.totalAmountMinorUnits,
        currencyCode: op.currencyCode,
      ),
    );
  }
}

class _OperationTypeIcon extends StatelessWidget {
  const _OperationTypeIcon({required this.typeCode});
  final String typeCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    IconData icon;
    Color color;
    switch (typeCode) {
      case 'income':
        icon = Icons.arrow_downward;
        color = colors.income;
      case 'expense':
      case 'childFundWithdrawal':
        icon = Icons.arrow_upward;
        color = colors.expense;
      case 'transfer':
        icon = Icons.swap_horiz;
        color = colors.transfer;
      case 'reversal':
        icon = Icons.undo;
        color = colors.secondaryText;
      case 'openingBalance':
        icon = Icons.flag_outlined;
        color = colors.secondaryText;
      default:
        icon = Icons.receipt_outlined;
        color = colors.secondaryText;
    }
    return Icon(icon, color: color, size: 20);
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _LabelledAmount extends StatelessWidget {
  const _LabelledAmount({
    required this.label,
    required this.minorUnits,
    required this.currencyCode,
    required this.color,
    required this.icon,
  });
  final String label;
  final int minorUnits;
  final String currencyCode;
  final Color? color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
          _AmountText(
            minorUnits: minorUnits,
            currencyCode: currencyCode,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// Formats minor-unit amounts for display.
///
/// Uses [Currency.fromCode] to determine decimal precision.
/// Falls back to 2 decimal places for unknown currency codes.
class _AmountText extends StatelessWidget {
  const _AmountText({
    required this.minorUnits,
    required this.currencyCode,
    this.color,
  });
  final int minorUnits;
  final String currencyCode;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = _format(minorUnits, currencyCode);
    return Semantics(
      label: '$text $currencyCode',
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static String _format(int minorUnits, String currencyCode) {
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
