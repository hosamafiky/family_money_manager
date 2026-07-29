import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:family_money_manager/features/accounts/domain/account_eligibility.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:family_money_manager/features/household/presentation/providers/household_providers.dart';
import 'package:family_money_manager/features/transactions/domain/child_withdrawal_context.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:family_money_manager/features/transactions/presentation/expense_submission.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

const _householdId = 'household-v1';
const _createdBy = 'member-primary-v1';

/// Form for recording a new expense transaction (amount-first layout).
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({this.preselectedAccountId, super.key});

  final String? preselectedAccountId;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _scrollController = ScrollController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _reasonController = TextEditingController();
  final _amountFocus = FocusNode();

  String? _paymentAccountId;
  FinancialAccount? _paymentAccount;
  TransactionCategory? _category;
  String? _spenderMemberId;
  String? _beneficiaryMemberId;
  ExpenseScope _scope = ExpenseScope.personal;
  bool _isRecurring = false;
  DateTime _effectiveDate = DateTime.now();

  bool _warningAcknowledged = false;
  bool _confirmed = false;

  /// The sheet opens with the pad up and the amount focused: that is what
  /// makes the common case three taps — amount, category, save. Expanding
  /// reveals the full field set and retires the pad; it is a disclosure on the
  /// same sheet, not a navigation to a second screen.
  bool _expanded = false;

  /// A rejected write, held on screen next to the action that caused it.
  String? _submitError;

  String? _amountError;
  String? _accountError;
  String? _categoryError;
  String? _spenderError;
  String? _beneficiaryError;
  String? _reasonError;
  String? _ackError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _paymentAccountId = widget.preselectedAccountId;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _reasonController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  /// Applies one key to the amount text.
  ///
  /// Deliberately a text edit rather than arithmetic: the field holds what the
  /// user typed, and parsing to minor units stays in MoneyInputFormatter where
  /// it is already tested.
  void _onKeypadKey(AmountKeypadKey key, int minorUnitScale) {
    final current = _amountController.text;
    var next = current;

    switch (key) {
      case DigitKey(:final digit):
        // Refuse digits past the currency's scale instead of silently
        // truncating them later.
        final dot = current.indexOf('.');
        if (dot >= 0 && current.length - dot - 1 >= minorUnitScale) return;
        next = '$current$digit';
      case DecimalSeparatorKey():
        if (current.contains('.') || minorUnitScale == 0) return;
        next = current.isEmpty ? '0.' : '$current.';
      case BackspaceKey():
        if (current.isEmpty) return;
        next = current.substring(0, current.length - 1);
    }

    _amountController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    setState(() => _amountError = null);
  }

  /// A nudge when the spender is not the account's owner, or null.
  ///
  /// Non-blocking by design. An earlier draft required a note in this case and
  /// it taxed the household's single most common entry — a spouse spending
  /// from a wallet in the primary user's name — which defeats the three-tap
  /// goal it was meant to protect.
  String? _spenderNotOwnerHint(
    AppLocalizations l10n,
    FinancialAccount? account,
    List<HouseholdMember> members,
  ) {
    if (account == null || _spenderMemberId == null) return null;
    if (account.ownerType != AccountOwnerType.user) return null;
    final spender = members.where((m) => m.id == _spenderMemberId).firstOrNull;
    if (spender == null || spender.role == MemberRole.primaryUser) return null;
    return l10n.expenseSpenderNotOwnerHint(spender.displayName);
  }

  /// The currency's decimal places, defaulting to two when no account is
  /// chosen yet. Never guesses beyond that — an unknown scale would let the
  /// pad accept digits the ledger would then round away.
  int _minorUnitScaleOf(FinancialAccount? account) {
    if (account == null) return 2;
    try {
      return Currency.fromCode(account.currencyCode).minorUnitScale;
    } catch (_) {
      return 2;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountsProvider(_householdId));
    final membersAsync = ref.watch(householdMembersProvider(_householdId));

    return AppScreenScaffold(
      title: Text(l10n.expenseFormTitle),
      resizeToAvoidBottomInset: true,
      bottomBar: accountsAsync.maybeWhen(
        data: (accountResult) => membersAsync.maybeWhen(
          data: (memberResult) {
            if (accountResult is! AppOk<List<FinancialAccount>> ||
                memberResult is! AppOk<List<HouseholdMember>>) {
              return null;
            }
            final accounts = accountResult.value
                .where(AccountEligibility.isOrdinaryTransactionEndpoint)
                .toList();
            final members = memberResult.value
                .where((m) => m.isActive)
                .toList();
            if (accounts.isEmpty || members.isEmpty) return null;
            final selectedAccount =
                _paymentAccount ??
                accounts.where((a) => a.id == _paymentAccountId).firstOrNull;
            final isProtected =
                selectedAccount?.requiresWithdrawalAudit ?? false;
            final scale = _minorUnitScaleOf(selectedAccount);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The pad is chrome pinned above the action bar, not a field
                // in the scroll: the amount must stay visible while it is up.
                if (!_expanded)
                  AmountKeypad(
                    onKey: (key) => _onKeypadKey(key, scale),
                    showDecimalSeparator: scale > 0,
                  ),
                AppBottomActionBar(
                  // Permanent, not conditional — the user learns append-only
                  // here rather than by looking for a delete button later.
                  consequenceLabel: l10n.reviewAppendOnlyConsequence,
                  child: Row(
                    children: [
                      // Save is the third tap. Review is an optional stop for
                      // the entry the user wants to check, not a toll on
                      // every entry.
                      Expanded(
                        child: PrimaryActionButton(
                          label: l10n.expenseFormTitle,
                          isLoading: ref.watch(submittingProvider),
                          onPressed: ref.watch(submittingProvider)
                              ? null
                              : () => _save(context, l10n, isProtected),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: SecondaryActionButton(
                          label: l10n.reviewTitle,
                          onPressed: () => _goToReview(
                            context,
                            l10n,
                            accounts,
                            members,
                            isProtected,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          orElse: () => null,
        ),
        orElse: () => null,
      ),
      body: accountsAsync.when(
        loading: () => AppLoadingState(message: l10n.loadingLabel),
        error: (_, _) => AppErrorState(
          message: l10n.errorGeneric,
          retryLabel: l10n.retryAction,
          onRetry: () => ref.invalidate(accountsProvider(_householdId)),
        ),
        data: (accountResult) => membersAsync.when(
          loading: () => AppLoadingState(message: l10n.loadingLabel),
          error: (_, _) => AppErrorState(message: l10n.errorGeneric),
          data: (memberResult) {
            if (accountResult is! AppOk<List<FinancialAccount>>) {
              return AppErrorState(message: l10n.errorGeneric);
            }
            if (memberResult is! AppOk<List<HouseholdMember>>) {
              return AppErrorState(message: l10n.errorGeneric);
            }
            final accounts = accountResult.value
                .where(AccountEligibility.isOrdinaryTransactionEndpoint)
                .toList();
            final members = memberResult.value
                .where((m) => m.isActive)
                .toList();

            if (_paymentAccountId != null) {
              final found = accounts
                  .where((a) => a.id == _paymentAccountId)
                  .firstOrNull;
              if (found == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _paymentAccountId = null;
                      _paymentAccount = null;
                    });
                  }
                });
              } else {
                _paymentAccount ??= found;
              }
            }

            // Defaulted so the common case needs three taps, and printed in
            // the meta line so no default is applied invisibly.
            _spenderMemberId ??= members
                .where((m) => m.role == MemberRole.primaryUser)
                .firstOrNull
                ?.id;
            _spenderMemberId ??= members.firstOrNull?.id;
            _beneficiaryMemberId ??= _spenderMemberId;
            _paymentAccountId ??= accounts.firstOrNull?.id;
            _paymentAccount ??= accounts
                .where((a) => a.id == _paymentAccountId)
                .firstOrNull;

            if (accounts.isEmpty) {
              return AppEmptyState(
                title: l10n.accountsEmpty,
                icon: Icons.account_balance_wallet_outlined,
                actionLabel: l10n.accountsAddButton,
                onAction: () => context.push('/accounts/new'),
              );
            }
            if (members.isEmpty) {
              return AppEmptyState(
                title: l10n.membersTitle,
                icon: Icons.group_outlined,
                actionLabel: l10n.memberAddChild,
                onAction: () => context.push('/members'),
              );
            }

            final selectedAccount =
                _paymentAccount ??
                accounts.where((a) => a.id == _paymentAccountId).firstOrNull;
            final isProtected =
                selectedAccount?.requiresWithdrawalAudit ?? false;
            final currencyCode = selectedAccount?.currencyCode;

            return ResponsiveContentContainer(
              child: ListView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsetsDirectional.only(
                  top: AppTheme.space16,
                  bottom: AppTheme.space32,
                ),
                children: [
                  if (_submitError case final String error) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                      ),
                      child: AppInlineNotice(
                        message: error,
                        tone: AppNoticeTone.error,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16,
                    ),
                    child: AmountEntryField(
                      controller: _amountController,
                      label: l10n.fieldAmount,
                      currencyCode: currencyCode,
                      errorText: _amountError,
                      focusNode: _amountFocus,
                      autofocus: true,
                      // The pad supplies the digits while it is up; showing
                      // the system keyboard as well would stack two number
                      // rows on one screen.
                      readOnly: !_expanded,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      onChanged: (_) => setState(() => _amountError = null),
                    ),
                  ),
                  // Every default is printed, not hidden: the fast path is
                  // pre-answered and visible, so nothing is applied silently.
                  if (!_expanded) ...[
                    const SizedBox(height: AppTheme.space8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                      ),
                      child: Text(
                        l10n.expenseDefaultsLine(
                          selectedAccount?.name ?? '—',
                          _formatDate(_effectiveDate),
                          members
                                  .where((m) => m.id == _spenderMemberId)
                                  .firstOrNull
                                  ?.displayName ??
                              members.first.displayName,
                          expenseScopeLabel(l10n, _scope),
                        ),
                        style: context.textRoles.supportingMeta,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space20),
                    SectionHeader(title: l10n.formSectionCategory),
                    // Full-bleed chip row: the margin is on the scroll view so
                    // the categories run to the screen edge rather than
                    // stopping at an inset viewport.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                      ),
                      child: Row(
                        children: [
                          for (final category
                              in TransactionCategory.expenseCategories) ...[
                            FilterChip(
                              label: Text(categoryLabel(l10n, category)),
                              selected: _category == category,
                              onSelected: (_) => setState(() {
                                _category = category;
                                _categoryError = null;
                              }),
                            ),
                            const SizedBox(width: AppTheme.space8),
                          ],
                        ],
                      ),
                    ),
                    if (_categoryError case final String error) ...[
                      const SizedBox(height: AppTheme.space8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space16,
                        ),
                        child: AppInlineNotice(
                          message: error,
                          tone: AppNoticeTone.error,
                        ),
                      ),
                    ],
                    if (_spenderNotOwnerHint(l10n, selectedAccount, members)
                        case final String hint) ...[
                      const SizedBox(height: AppTheme.space16),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space16,
                        ),
                        // A nudge, never a block: requiring a note here would
                        // tax the household's most common entry.
                        child: AppInlineNotice(
                          message: hint,
                          tone: AppNoticeTone.warning,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.space20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                      ),
                      child: SecondaryActionButton(
                        label: l10n.expenseMoreDetails,
                        onPressed: () => setState(() => _expanded = true),
                      ),
                    ),
                  ],
                  if (_expanded)
                    AppFormSection(
                      title: l10n.formSectionAccount,
                      child: AccountSelectorField<FinancialAccount>(
                        label: l10n.fieldPaymentAccount,
                        items: accounts,
                        value: accounts
                            .where((a) => a.id == _paymentAccountId)
                            .firstOrNull,
                        itemLabel: (a) => a.name,
                        errorText: _accountError,
                        onChanged: (a) => setState(() {
                          _paymentAccountId = a?.id;
                          _paymentAccount = a;
                          _accountError = null;
                          _warningAcknowledged = false;
                          _confirmed = false;
                        }),
                      ),
                    ),
                  if (_expanded)
                    AppFormSection(
                      title: l10n.formSectionCategory,
                      child: DropdownButtonFormField<TransactionCategory>(
                        // ignore: deprecated_member_use
                        value: _category,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.fieldCategory,
                          errorText: _categoryError,
                        ),
                        items: TransactionCategory.expenseCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(categoryLabel(l10n, c)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _category = v;
                          _categoryError = null;
                        }),
                      ),
                    ),
                  if (_expanded)
                    AppFormSection(
                      title: l10n.formSectionAttribution,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _spenderMemberId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.fieldSpender,
                              errorText: _spenderError,
                            ),
                            items: members
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m.id,
                                    child: Text(m.displayName),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() {
                              _spenderMemberId = v;
                              _spenderError = null;
                            }),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _beneficiaryMemberId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.fieldBeneficiary,
                              errorText: _beneficiaryError,
                            ),
                            items: members
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m.id,
                                    child: Text(m.displayName),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() {
                              _beneficiaryMemberId = v;
                              _beneficiaryError = null;
                            }),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          DropdownButtonFormField<ExpenseScope>(
                            // ignore: deprecated_member_use
                            value: _scope,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.fieldScope,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: ExpenseScope.personal,
                                child: Text(l10n.scopePersonal),
                              ),
                              DropdownMenuItem(
                                value: ExpenseScope.spouse,
                                child: Text(l10n.scopeSpouse),
                              ),
                              DropdownMenuItem(
                                value: ExpenseScope.household,
                                child: Text(l10n.scopeHousehold),
                              ),
                              DropdownMenuItem(
                                value: ExpenseScope.child,
                                child: Text(l10n.scopeChild),
                              ),
                            ],
                            onChanged: (v) => setState(
                              () => _scope = v ?? ExpenseScope.personal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_expanded)
                    AppExpandableDetails(
                      title: l10n.formAdvancedDetails,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.fieldRecurring),
                              Switch(
                                value: _isRecurring,
                                onChanged: (v) =>
                                    setState(() => _isRecurring = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space12),
                          InkWell(
                            onTap: () async {
                              final picked = await showAppDatePicker(
                                context: context,
                                initialDate: _effectiveDate,
                                purpose: DatePurpose.ledgerEntry,
                              );
                              if (picked != null) {
                                setState(() => _effectiveDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.fieldEffectiveDate,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(_formatDate(_effectiveDate)),
                                  ),
                                  const Icon(Icons.calendar_today, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          TextFormField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              labelText: l10n.fieldNote,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  if (_expanded && isProtected) ...[
                    const SizedBox(height: AppTheme.space8),
                    AppInlineNotice(
                      message: l10n.protectedWithdrawalWarning,
                      tone: AppNoticeTone.warning,
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: _reasonController,
                      decoration: InputDecoration(
                        labelText: l10n.fieldWithdrawalReason,
                        errorText: _reasonError,
                      ),
                      onChanged: (_) => setState(() => _reasonError = null),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _warningAcknowledged,
                      title: Text(l10n.fieldAcknowledgeWarning),
                      subtitle: _ackError != null
                          ? Text(
                              _ackError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      onChanged: (v) => setState(() {
                        _warningAcknowledged = v ?? false;
                        _ackError = null;
                      }),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _confirmed,
                      title: Text(l10n.fieldConfirmWithdrawal),
                      subtitle: _confirmError != null
                          ? Text(
                              _confirmError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      onChanged: (v) => setState(() {
                        _confirmed = v ?? false;
                        _confirmError = null;
                      }),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _goToReview(
    BuildContext context,
    AppLocalizations l10n,
    List<FinancialAccount> accounts,
    List<HouseholdMember> members,
    bool isProtected,
  ) {
    final ctx = _validateAndBuild(l10n, isProtected);
    if (ctx == null) return;
    ref.read(stagedExpenseContextProvider.notifier).set(ctx);
    context.push('/transactions/new/expense/review');
  }

  /// Saves straight from the pad — the third of the three taps.
  ///
  /// Same validation and the same single write path as the review screen; the
  /// review is an optional stop, not a required one.
  Future<void> _save(
    BuildContext context,
    AppLocalizations l10n,
    bool isProtected,
  ) async {
    final ctx = _validateAndBuild(l10n, isProtected);
    if (ctx == null) return;

    ref.read(submittingProvider.notifier).setSubmitting(true);
    try {
      final outcome = await submitExpense(ref: ref, l10n: l10n, ctx: ctx);
      if (!context.mounted) return;
      switch (outcome) {
        case ExpenseSaved():
          context.go('/transactions');
        case ExpenseRejected(:final message):
          // At its cause and persistent, exactly as on the review screen.
          setState(() => _submitError = message);
      }
    } finally {
      if (mounted) {
        ref.read(submittingProvider.notifier).setSubmitting(false);
      }
    }
  }

  /// Validates the form and assembles the context, or null when a field is
  /// wrong. Every error it sets stays on screen until the user fixes it.
  ExpenseContext? _validateAndBuild(AppLocalizations l10n, bool isProtected) {
    bool hasErrors = false;

    if (_paymentAccountId == null) {
      setState(() => _accountError = l10n.errorGeneric);
      hasErrors = true;
    }
    if (_category == null) {
      setState(() => _categoryError = l10n.errorCategoryRequired);
      hasErrors = true;
    }
    if (_spenderMemberId == null) {
      setState(() => _spenderError = l10n.errorSpenderRequired);
      hasErrors = true;
    }
    if (_beneficiaryMemberId == null) {
      setState(() => _beneficiaryError = l10n.errorBeneficiaryRequired);
      hasErrors = true;
    }

    final rawAmount = _amountController.text.trim();
    if (rawAmount.isEmpty) {
      setState(() => _amountError = l10n.errorMoneyInvalidFormat);
      hasErrors = true;
    }

    if (isProtected) {
      if (_reasonController.text.trim().isEmpty) {
        setState(() => _reasonError = l10n.errorWithdrawalReasonRequired);
        hasErrors = true;
      }
      if (!_warningAcknowledged) {
        setState(() => _ackError = l10n.errorWithdrawalAcknowledgmentRequired);
        hasErrors = true;
      }
      if (!_confirmed) {
        setState(
          () => _confirmError = l10n.errorWithdrawalConfirmationRequired,
        );
        hasErrors = true;
      }
    }

    if (hasErrors) return null;

    final rawAmountStr = _amountController.text.trim();
    final currencyCode = _paymentAccount?.currencyCode ?? 'EGP';
    final currency = Currency.fromCode(currencyCode);
    final parseResult = MoneyInputFormatter.parse(rawAmountStr, currency);
    if (parseResult is! MoneyParseOk) {
      setState(() => _amountError = l10n.errorMoneyInvalidFormat);
      return null;
    }
    if (parseResult.value.minorUnits <= 0) {
      setState(() => _amountError = l10n.errorMoneyInvalidFormat);
      return null;
    }
    final minorUnits = parseResult.value.minorUnits;
    final idemKey = ref.read(expenseFormKeyProvider);

    ChildWithdrawalContext? withdrawalAudit;
    if (isProtected) {
      withdrawalAudit = ChildWithdrawalContext(
        protectedAccountId: _paymentAccountId!,
        beneficiaryMemberId: _beneficiaryMemberId!,
        reason: _reasonController.text.trim(),
        warningAcknowledged: _warningAcknowledged,
        confirmed: _confirmed,
      );
    }

    final ctx = ExpenseContext(
      operationId: const Uuid().v4(),
      idempotencyKey: idemKey,
      householdId: _householdId,
      paymentAccountId: _paymentAccountId!,
      amountMinorUnits: minorUnits,
      currencyCode: currencyCode,
      category: _category!,
      spenderMemberId: _spenderMemberId!,
      beneficiaryMemberId: _beneficiaryMemberId!,
      scope: _scope,
      isRecurring: _isRecurring,
      effectiveDate: _formatDate(_effectiveDate),
      createdBy: _createdBy,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      childWithdrawalAudit: withdrawalAudit,
    );

    return ctx;
  }
}
