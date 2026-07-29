/// The filter sheet.
///
/// Its one structural idea: the result count rides on the confirm button. You
/// know a filter matches 87 of 1,248 before committing to it, which turns
/// filtering to nothing into a rare accident rather than the normal way to
/// discover the empty state.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:family_money_manager/features/household/presentation/providers/household_providers.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What may be typed into an amount bound.
///
/// Western and Arabic-Indic digits, plus the decimal separators used in both
/// scripts. Narrower than this would defeat [MoneyInputFormatter], which
/// already accepts all of them — a field that silently refuses ٣٨٢٫٥٠ is
/// worse than one that accepts it and parses it correctly.
final _amountCharacters = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9\u0660-\u0669.\u066B\u060C]'),
);

/// The currencies an amount band may be expressed in.
///
/// Fixed rather than derived from the household's accounts: the band is a
/// threshold the user types, and a list that changed as accounts were added
/// or archived would move the meaning of a saved filter.
const _bandCurrencies = ['EGP', 'USD'];

/// The operation types a person filters by. The remaining types are system
/// bookkeeping and would be noise in a chip row.
const _filterableTypes = [
  OperationType.expense,
  OperationType.income,
  OperationType.transfer,
  OperationType.reversal,
];

/// Edits [initial] and returns the result, or null when cancelled.
Future<TransactionFilter?> showTransactionFilterSheet({
  required BuildContext context,
  required TransactionFilter initial,
  required String householdId,
}) => showModalBottomSheet<TransactionFilter>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _FilterSheet(initial: initial, householdId: householdId),
);

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial, required this.householdId});

  final TransactionFilter initial;
  final String householdId;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late TransactionFilter _draft = widget.initial;
  late final _minController = TextEditingController(
    text: _majorUnits(widget.initial.amountRange?.minMinorUnits),
  );
  late final _maxController = TextEditingController(
    text: _majorUnits(widget.initial.amountRange?.maxMinorUnits),
  );

  /// The currency an amount band applies to.
  ///
  /// A band without one would compare across currencies, so the sheet always
  /// has a currency in hand before it can offer a band at all.
  String _amountCurrency = 'EGP';

  @override
  void initState() {
    super.initState();
    _amountCurrency = widget.initial.amountRange?.currencyCode ?? 'EGP';
  }

  /// The draft's category code as an enum, for the chip row.
  ///
  /// The filter stores a code because that is what the query matches; the
  /// chips need the value. An unrecognised code selects nothing rather than
  /// throwing — a filter is not worth crashing a sheet over.
  TransactionCategory? get _selectedCategory {
    final code = _draft.categoryCode;
    if (code == null) return null;
    for (final category in TransactionCategory.values) {
      if (category.code == code) return category;
    }
    return null;
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.financialColors;
    final countAsync = ref.watch(
      transactionCountProvider((widget.householdId, _draft)),
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space16,
                AppTheme.space16,
                AppTheme.space16,
                AppTheme.space8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.transactionsFilterTitle,
                      style: context.textRoles.screenTitle,
                    ),
                  ),
                  if (_draft.hasActiveCriteria)
                    TextButton(
                      onPressed: _clearAll,
                      child: Text(
                        l10n.transactionsClearFiltersCount(
                          '${_draft.activeCriteriaCount}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: AppTheme.space16),
                children: [
                  AppFormSection(
                    title: l10n.transactionsFilterType,
                    child: FilterChipGroup<OperationType>(
                      options: _filterableTypes,
                      selected: {?_draft.operationType},
                      labelOf: (type) => operationTypeLabel(l10n, type),
                      onChanged: (selection) => setState(() {
                        final type = selection.firstOrNull;
                        _draft = type == null || type == _draft.operationType
                            ? _draft.copyWith(clearOperationType: true)
                            : _draft.copyWith(operationType: type);
                      }),
                    ),
                  ),
                  // Categories are a closed set the app defines, so they are
                  // chips. Accounts and members are household data of unknown
                  // size and unknown name length, so they are menus — a chip
                  // row of twelve accounts is a wall.
                  AppFormSection(
                    title: l10n.transactionsFilterCategory,
                    child: FilterChipGroup<TransactionCategory>(
                      options: TransactionCategory.values
                          .where((c) => c.type == CategoryType.expense)
                          .toList(),
                      selected: {?_selectedCategory},
                      labelOf: (category) => categoryLabel(l10n, category),
                      onChanged: (selection) => setState(() {
                        final category = selection.firstOrNull;
                        _draft =
                            category == null ||
                                category.code == _draft.categoryCode
                            ? _draft.copyWith(clearCategoryCode: true)
                            : _draft.copyWith(categoryCode: category.code);
                      }),
                    ),
                  ),
                  AppFormSection(
                    title: l10n.transactionsFilterScope,
                    child: FilterChipGroup<ExpenseScope>(
                      options: ExpenseScope.values,
                      selected: {?_draft.scope},
                      labelOf: (scope) => expenseScopeLabel(l10n, scope),
                      onChanged: (selection) => setState(() {
                        final scope = selection.firstOrNull;
                        _draft = scope == null || scope == _draft.scope
                            ? _draft.copyWith(clearScope: true)
                            : _draft.copyWith(scope: scope);
                      }),
                    ),
                  ),
                  _AccountPicker(
                    householdId: widget.householdId,
                    selectedId: _draft.accountId,
                    onChanged: (id) => setState(() {
                      _draft = id == null
                          ? _draft.copyWith(clearAccountId: true)
                          : _draft.copyWith(accountId: id);
                    }),
                  ),
                  _MemberPicker(
                    householdId: widget.householdId,
                    selectedId: _draft.spenderMemberId,
                    onChanged: (id) => setState(() {
                      _draft = id == null
                          ? _draft.copyWith(clearSpenderMemberId: true)
                          : _draft.copyWith(spenderMemberId: id);
                    }),
                  ),
                  AppFormSection(
                    title: l10n.transactionsFilterAmountRange,
                    // Named on the section itself, not buried in a hint: a
                    // min/max across EGP and USD is the same error as a mixed
                    // total, and the sheet says so before it is made.
                    subtitle: l10n.transactionsFilterAmountPerCurrency,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The currency is chosen before the band, not implied
                        // by it: changing it re-reads both bounds at the new
                        // scale rather than reinterpreting the old minor
                        // units, which would silently move the threshold.
                        FilterChipGroup<String>(
                          options: _bandCurrencies,
                          selected: {_amountCurrency},
                          labelOf: (code) => code,
                          onChanged: (selection) {
                            final code = selection.firstOrNull;
                            if (code == null || code == _amountCurrency) return;
                            setState(() => _amountCurrency = code);
                            _applyAmountRange();
                          },
                        ),
                        const SizedBox(height: AppTheme.space12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [_amountCharacters],
                                decoration: InputDecoration(
                                  labelText: l10n.transactionsFilterMin,
                                  suffixText: _amountCurrency,
                                ),
                                onChanged: (_) => _applyAmountRange(),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Expanded(
                              child: TextField(
                                controller: _maxController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [_amountCharacters],
                                decoration: InputDecoration(
                                  labelText: l10n.transactionsFilterMax,
                                  suffixText: _amountCurrency,
                                ),
                                onChanged: (_) => _applyAmountRange(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    value: _draft.includeReversed,
                    title: Text(l10n.transactionsFilterShowReversed),
                    onChanged: (value) => setState(
                      () => _draft = _draft.copyWith(includeReversed: value),
                    ),
                  ),
                ],
              ),
            ),
            AppBottomActionBar(
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryActionButton(
                      label: l10n.transactionsCancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    flex: 2,
                    child: PrimaryActionButton(
                      // The count is the point of the button. While it is in
                      // flight the label falls back to a plain apply rather
                      // than to a stale number.
                      label: countAsync.maybeWhen(
                        data: (count) => l10n.transactionsFilterApply('$count'),
                        orElse: () => l10n.transactionsFilterTitle,
                      ),
                      onPressed: () => Navigator.of(context).pop(_draft),
                    ),
                  ),
                ],
              ),
            ),
            if (countAsync.hasError)
              Padding(
                padding: const EdgeInsets.all(AppTheme.space12),
                child: Text(
                  l10n.errorGeneric,
                  style: context.textRoles.supportingMeta.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _clearAll() {
    _minController.clear();
    _maxController.clear();
    setState(() {
      _draft = TransactionFilter(
        searchQuery: _draft.searchQuery,
        pageSize: _draft.pageSize,
      );
    });
  }

  void _applyAmountRange() {
    final min = _minorUnits(_minController.text);
    final max = _minorUnits(_maxController.text);
    setState(() {
      _draft = min == null && max == null
          ? _draft.copyWith(clearAmountRange: true)
          : _draft.copyWith(
              amountRange: TransactionAmountRange(
                currencyCode: _amountCurrency,
                minMinorUnits: min,
                maxMinorUnits: max,
              ),
            );
    });
  }

  /// Parses a typed bound into minor units, or null when it is not a number.
  ///
  /// Goes through [MoneyInputFormatter] rather than doing its own arithmetic:
  /// that is the one place that knows a currency's scale, accepts
  /// Arabic-Indic digits and Arabic decimal separators, and never touches a
  /// double. A bound parsed any other way would disagree with the amounts it
  /// is being compared against.
  int? _minorUnits(String text) {
    final result = MoneyInputFormatter.parse(
      text,
      Currency.fromCode(_amountCurrency),
    );
    return switch (result) {
      MoneyParseOk(:final value) => value.minorUnits,
      _ => null,
    };
  }

  String _majorUnits(int? minorUnits) => minorUnits == null
      ? ''
      : MoneyInputFormatter.format(
          Money(
            minorUnits: minorUnits,
            currency: Currency.fromCode(_amountCurrency),
          ),
        );
}

/// One of the household's accounts, or all of them.
///
/// A menu rather than chips: accounts are household data of unknown size and
/// unknown name length, and a chip row of a dozen long Arabic names is a wall
/// rather than a control. While the list loads the section renders disabled
/// rather than absent, so the sheet does not reflow under the user's thumb.
class _AccountPicker extends ConsumerWidget {
  const _AccountPicker({
    required this.householdId,
    required this.selectedId,
    required this.onChanged,
  });

  final String householdId;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accounts = ref
        .watch(accountsProvider(householdId))
        .maybeWhen(
          data: (result) => result is AppOk<List<FinancialAccount>>
              ? result.value
              : const <FinancialAccount>[],
          orElse: () => const <FinancialAccount>[],
        );

    // Only pass a value the menu can actually show. The list arrives async,
    // so a filter naming an account before it loads would otherwise trip
    // DropdownButton's "exactly one matching item" assertion — a crash on
    // reopening the sheet with an account filter already active.
    final selectable = accounts.any((a) => a.id == selectedId)
        ? selectedId
        : null;

    return AppFormSection(
      title: l10n.transactionsFilterAccount,
      // Fully controlled by `value`, not seeded by `initialValue`: the draft
      // is the source of truth, and "clear all" has to be able to reset the
      // control it just cleared.
      child: DropdownButton<String?>(
        value: selectable,
        isExpanded: true,
        hint: Text(l10n.transactionsFilterAllAccounts),
        items: [
          DropdownMenuItem(child: Text(l10n.transactionsFilterAllAccounts)),
          for (final account in accounts)
            DropdownMenuItem(
              value: account.id,
              child: Text(account.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: accounts.isEmpty ? null : onChanged,
      ),
    );
  }
}

/// One of the household's members, as the spender.
///
/// Archived members stay selectable: they spent money that is still in the
/// ledger, and a filter that could not reach it would make that history
/// unsearchable.
class _MemberPicker extends ConsumerWidget {
  const _MemberPicker({
    required this.householdId,
    required this.selectedId,
    required this.onChanged,
  });

  final String householdId;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final members = ref
        .watch(householdMembersProvider(householdId))
        .maybeWhen(
          data: (result) => result is AppOk<List<HouseholdMember>>
              ? result.value
              : const <HouseholdMember>[],
          orElse: () => const <HouseholdMember>[],
        );

    final selectable = members.any((m) => m.id == selectedId)
        ? selectedId
        : null;

    return AppFormSection(
      title: l10n.transactionsFilterSpender,
      child: DropdownButton<String?>(
        value: selectable,
        isExpanded: true,
        hint: Text(l10n.transactionsFilterAnyMember),
        items: [
          DropdownMenuItem(child: Text(l10n.transactionsFilterAnyMember)),
          for (final member in members)
            DropdownMenuItem(
              value: member.id,
              child: Text(member.displayName, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: members.isEmpty ? null : onChanged,
      ),
    );
  }
}
