/// The transaction list.
///
/// Built for hundreds of rows: fixed-geometry tiles, sticky date headers, and
/// a period summary that never adds two currencies together. A reversed pair
/// appears as two adjacent rows — hiding the original would make the ledger a
/// lie, and hiding the correction would make the balance incomprehensible.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:family_money_manager/features/transactions/presentation/transaction_filter_sheet.dart';
import 'package:family_money_manager/features/transactions/presentation/transaction_list_grouping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Main transactions screen showing recent operation history.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionFilter _filter = const TransactionFilter();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final transactionsAsync = ref.watch(
      transactionListProvider((_householdId, _filter)),
    );
    // What the ledger holds regardless of the filter. An empty result has to
    // be able to say "you have 1,248 transactions, none match this".
    final unfilteredCount = ref
        .watch(
          transactionCountProvider((_householdId, const TransactionFilter())),
        )
        .maybeWhen(data: (count) => count, orElse: () => null);

    return AppScreenScaffold(
      title: _isSearching
          ? _SearchField(
              controller: _searchController,
              onChanged: _applySearch,
              onClose: _closeSearch,
            )
          : Text(l10n.transactionsTitle),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.transactionsSearchHint,
            onPressed: () => setState(() => _isSearching = true),
          ),
        IconButton(
          icon: Badge(
            isLabelVisible: _filter.hasActiveCriteria,
            label: Text('${_filter.activeCriteriaCount}'),
            child: const Icon(Icons.filter_list),
          ),
          tooltip: l10n.transactionsFilterTitle,
          onPressed: _openFilterSheet,
        ),
      ],
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        onPressed: () => context.push('/transactions/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_isSearching)
            // Said out loud rather than left to be discovered: a search that
            // silently spanned or silently respected the period would be
            // equally confusing, so the screen states which it does.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space8,
              ),
              child: Text(
                l10n.transactionsSearchIgnoresPeriod,
                style: context.textRoles.supportingMeta.copyWith(
                  color: context.financialColors.secondaryText,
                ),
              ),
            ),
          Expanded(
            child: transactionsAsync.when(
              // A skeleton at the real row pitch, not a spinner: the list's
              // geometry is already known, so nothing moves when data lands.
              loading: () => const AppSkeletonList(),
              error: (_, _) =>
                  AppErrorState(message: l10n.transactionsErrorTitle),
              data: (result) => switch (result) {
                AppOk(:final value) when value.isEmpty => _EmptyState(
                  isFiltered:
                      _filter.hasActiveCriteria ||
                      (_filter.searchQuery?.isNotEmpty ?? false),
                  unfilteredCount: unfilteredCount,
                  onClearFilters: _clearFilters,
                ),
                AppOk(:final value) => RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                      transactionListProvider((_householdId, _filter)),
                    );
                  },
                  child: _GroupedList(transactions: value),
                ),
                _ => AppErrorState(message: l10n.transactionsErrorTitle),
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Search deliberately drops the date bounds.
  ///
  /// Someone searching for an amount is looking for one specific transaction,
  /// not browsing a month — a search that silently honoured the active period
  /// would report "not found" for a transaction that exists.
  void _applySearch(String query) {
    setState(() {
      _filter = query.trim().isEmpty
          ? _filter.copyWith(clearSearchQuery: true)
          : _filter.copyWith(searchQuery: query, clearDates: true);
    });
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _filter = _filter.copyWith(clearSearchQuery: true);
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _filter = const TransactionFilter();
      _isSearching = false;
    });
  }

  Future<void> _openFilterSheet() async {
    final updated = await showTransactionFilterSheet(
      context: context,
      initial: _filter,
      householdId: _householdId,
    );
    if (updated == null || !mounted) return;
    setState(() => _filter = updated);
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      autofocus: true,
      // The field is a first-strong isolate by virtue of the app's direction;
      // a query like «بقالة 382» keeps its Latin numeric run intact because
      // nothing here re-orders it.
      decoration: InputDecoration(
        hintText: l10n.transactionsSearchHint,
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

/// Empty because the ledger is, or empty because a filter excluded everything.
///
/// The two are different problems and get different copy: a filtered-empty
/// result names the count the user does have and offers to drop the filter,
/// because an empty result is a filter problem, never a data problem.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isFiltered,
    required this.unfilteredCount,
    required this.onClearFilters,
  });

  final bool isFiltered;
  final int? unfilteredCount;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!isFiltered) {
      return AppEmptyState(
        title: l10n.transactionsEmpty,
        actionLabel: l10n.actionRecordExpense,
        onAction: () => context.push('/transactions/new'),
      );
    }
    return AppEmptyState(
      title: l10n.transactionsEmptyFilteredTitle,
      message: unfilteredCount == null
          ? null
          : l10n.transactionsEmptyFilteredBody('$unfilteredCount'),
      actionLabel: l10n.transactionsClearFilters,
      onAction: onClearFilters,
      icon: Icons.filter_list_off,
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.transactions});

  final List<TransactionSummary> transactions;

  @override
  Widget build(BuildContext context) {
    final groups = groupByEffectiveDate(transactions);
    final totals = totalsByCurrency(transactions);

    return ResponsiveContentContainer(
      child: CustomScrollView(
        slivers: [
          if (totals.isNotEmpty)
            SliverToBoxAdapter(child: _PeriodSummary(totals: totals)),
          for (final group in groups) ...[
            // Sticky, so the day a row belongs to is never off-screen while
            // its rows are.
            SliverPersistentHeader(
              pinned: true,
              delegate: _DateHeaderDelegate(
                date: group.effectiveDate,
                count: group.transactions.length,
              ),
            ),
            SliverList.builder(
              itemCount: group.transactions.length,
              itemBuilder: (context, index) =>
                  _TransactionTile(summary: group.transactions[index]),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.space32)),
        ],
      ),
    );
  }
}

/// Period figures, one block per currency.
class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({required this.totals});

  final List<TransactionPeriodTotals> totals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.financialColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final total in totals)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinancialSummary(
                  metrics: [
                    FinancialMetric(
                      label: l10n.transactionsSummaryIncome,
                      minorUnits: total.incomeMinorUnits,
                      currencyCode: total.currencyCode,
                      tone: FinancialAmountTone.income,
                      direction: FinancialAmountDirection.inflow,
                    ),
                    FinancialMetric(
                      label: l10n.transactionsSummaryExpense,
                      minorUnits: total.expenseMinorUnits,
                      currencyCode: total.currencyCode,
                      tone: FinancialAmountTone.expense,
                      direction: FinancialAmountDirection.outflow,
                    ),
                    // Third and labelled, never folded into the first two.
                    FinancialMetric(
                      label: l10n.transactionsSummaryTransfer,
                      minorUnits: total.transferMinorUnits,
                      currencyCode: total.currencyCode,
                      tone: FinancialAmountTone.transfer,
                      direction: FinancialAmountDirection.internal,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                // The summary states its own scope. Only one currency is
                // being totalled, and rows in others are still in the list
                // below carrying their own code.
                Text(
                  totals.length > 1
                      ? l10n.transactionsSummaryCurrencyOnly(total.currencyCode)
                      : l10n.transactionsTransferNotCounted,
                  style: context.textRoles.supportingMeta.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A pinned day header carrying that day's row count.
class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DateHeaderDelegate({required this.date, required this.count});

  final String date;
  final int count;

  static const double _height = 40;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final l10n = AppLocalizations.of(context);
    final colors = context.financialColors;
    return Container(
      height: _height,
      // Opaque: a pinned header that rows scroll through has to hide them.
      color: colors.mainSurface,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        children: [
          Expanded(
            child: Text(_label(l10n), style: context.textRoles.sectionTitle),
          ),
          Text(
            l10n.transactionsGroupCount('$count'),
            style: context.textRoles.supportingMeta.copyWith(
              color: colors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  /// "Today" and "Yesterday" carry more than a date does; anything older is
  /// better served by the date itself.
  String _label(AppLocalizations l10n) {
    final now = DateTime.now();
    final today = _iso(now);
    final yesterday = _iso(now.subtract(const Duration(days: 1)));
    if (date == today) return '${l10n.transactionsGroupToday} · $date';
    if (date == yesterday) return '${l10n.transactionsGroupYesterday} · $date';
    return date;
  }

  String _iso(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  @override
  bool shouldRebuild(_DateHeaderDelegate oldDelegate) =>
      oldDelegate.date != date || oldDelegate.count != count;
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.summary});

  final TransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final op = summary.operation;

    // Names, not ids. The id stays as the fallback so a missing join reads as
    // missing data rather than as a blank row.
    final source = summary.sourceAccountName ?? op.sourceAccountId;
    final destination =
        summary.destinationAccountName ?? op.destinationAccountId;
    final accountOrDirection = switch (op.type) {
      OperationType.transfer => '${source ?? '—'} → ${destination ?? '—'}',
      OperationType.income ||
      OperationType.openingBalance => destination ?? op.currencyCode,
      _ => source ?? op.currencyCode,
    };

    return TransactionListTile(
      typeLabel: operationTypeLabel(l10n, op.type),
      typeKind: _typeKind(op.type),
      primaryDescription: _description(l10n),
      accountOrDirection: accountOrDirection,
      effectiveDate: op.effectiveDate,
      minorUnits: op.totalAmountMinorUnits,
      currencyCode: op.currencyCode,
      // The spender is who the row is about; the category is what it was for.
      // Prefer the person, because "who spent this" is the question a
      // household asks of its own ledger first.
      memberOrCategory: summary.spenderName ?? _categoryLabel(l10n),
      associationLabel: _reversalMeta(l10n),
      isReversed: op.isReversed,
      reversedLabel: op.isReversed ? l10n.transactionReversed : null,
      onTap: () => context.push('/transactions/${op.id}'),
    );
  }

  String _description(AppLocalizations l10n) {
    final op = summary.operation;
    if (op.description?.trim().isNotEmpty ?? false) return op.description!;
    if (summary.note?.trim().isNotEmpty ?? false) return summary.note!;
    return _categoryLabel(l10n) ?? operationTypeLabel(l10n, op.type);
  }

  String? _categoryLabel(AppLocalizations l10n) => summary.categoryCode == null
      ? null
      : categoryLabelFromCode(l10n, summary.categoryCode!);

  /// What makes the reversed pair legible in the list itself.
  ///
  /// The original says its counter-entry exists; the reversing entry says what
  /// it answers and why. Read together, the two adjacent rows explain a
  /// balance that would otherwise look like a duplicate.
  String? _reversalMeta(AppLocalizations l10n) {
    final op = summary.operation;
    if (op.isReversed) return l10n.transactionsReversedOriginalMeta;
    if (op.type != OperationType.reversal) return null;
    if (op.reversalReason case final String reason) {
      return l10n.transactionsReversalRefersTo(op.effectiveDate, reason);
    }
    return null;
  }

  FinancialTypeKind _typeKind(OperationType type) => switch (type) {
    OperationType.income => FinancialTypeKind.income,
    OperationType.expense => FinancialTypeKind.expense,
    OperationType.transfer => FinancialTypeKind.transfer,
    OperationType.reversal => FinancialTypeKind.reversal,
    OperationType.adjustment => FinancialTypeKind.adjustment,
    _ => FinancialTypeKind.other,
  };
}
