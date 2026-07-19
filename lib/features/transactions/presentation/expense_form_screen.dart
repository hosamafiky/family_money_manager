import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:family_money_manager/features/household/presentation/providers/household_providers.dart';
import 'package:family_money_manager/features/transactions/domain/child_withdrawal_context.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_category.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

const _householdId = 'household-v1';
const _createdBy = 'member-primary-v1';

/// Form for recording a new expense transaction.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({this.preselectedAccountId, super.key});

  final String? preselectedAccountId;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _reasonController = TextEditingController();

  String? _paymentAccountId;
  FinancialAccount? _paymentAccount;
  TransactionCategory? _category;
  String? _spenderMemberId;
  String? _beneficiaryMemberId;
  ExpenseScope _scope = ExpenseScope.personal;
  bool _isRecurring = false;
  DateTime _effectiveDate = DateTime.now();

  // Protected withdrawal fields
  bool _warningAcknowledged = false;
  bool _confirmed = false;

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
    _amountController.dispose();
    _noteController.dispose();
    _reasonController.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenseFormTitle)),
      body: accountsAsync.when(
        loading: () => Center(child: Text(l10n.loadingLabel)),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (accountResult) => membersAsync.when(
          loading: () => Center(child: Text(l10n.loadingLabel)),
          error: (_, _) => Center(child: Text(l10n.errorGeneric)),
          data: (memberResult) {
            if (accountResult is! AppOk<List<FinancialAccount>>) {
              return Center(child: Text(l10n.errorGeneric));
            }
            if (memberResult is! AppOk<List<HouseholdMember>>) {
              return Center(child: Text(l10n.errorGeneric));
            }
            final accounts = accountResult.value.where((a) => !a.isArchived && a.type != FinancialAccountType.goalReserve).toList();
            final members = memberResult.value.where((m) => m.isActive).toList();

            // Sync tracked account; clear preselected ID if account is now archived.
            if (_paymentAccountId != null) {
              final found = accounts.where((a) => a.id == _paymentAccountId).firstOrNull;
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

            if (accounts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 48),
                      const SizedBox(height: 16),
                      Text(l10n.accountsEmpty, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      FilledButton.icon(onPressed: () => context.push('/accounts/new'), icon: const Icon(Icons.add), label: Text(l10n.accountsAddButton)),
                    ],
                  ),
                ),
              );
            }

            final selectedAccount = _paymentAccount ?? accounts.where((a) => a.id == _paymentAccountId).firstOrNull;

            if (members.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_outlined, size: 48),
                      const SizedBox(height: 16),
                      Text(l10n.membersTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.push('/members'),
                        icon: const Icon(Icons.person_add_outlined),
                        label: Text(l10n.memberAddChild),
                      ),
                    ],
                  ),
                ),
              );
            }
            final isProtected = selectedAccount?.requiresWithdrawalAudit ?? false;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAccountDropdown(context, l10n, accounts),
                const SizedBox(height: 16),
                _buildAmountField(context, l10n),
                const SizedBox(height: 16),
                _buildCategoryDropdown(context, l10n),
                const SizedBox(height: 16),
                _buildMemberDropdown(
                  context,
                  l10n,
                  label: l10n.fieldSpender,
                  value: _spenderMemberId,
                  members: members,
                  error: _spenderError,
                  onChanged: (v) => setState(() {
                    _spenderMemberId = v;
                    _spenderError = null;
                  }),
                ),
                const SizedBox(height: 16),
                _buildMemberDropdown(
                  context,
                  l10n,
                  label: l10n.fieldBeneficiary,
                  value: _beneficiaryMemberId,
                  members: members,
                  error: _beneficiaryError,
                  onChanged: (v) => setState(() {
                    _beneficiaryMemberId = v;
                    _beneficiaryError = null;
                  }),
                ),
                const SizedBox(height: 16),
                _buildScopeDropdown(context, l10n),
                const SizedBox(height: 16),
                _buildRecurringToggle(context, l10n),
                const SizedBox(height: 16),
                _buildDatePicker(context, l10n),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(labelText: l10n.fieldNote, border: const OutlineInputBorder()),
                  maxLines: 2,
                ),
                if (isProtected) ...[const SizedBox(height: 24), _buildProtectedSection(context, l10n)],
                const SizedBox(height: 24),
                FilledButton(onPressed: () => _goToReview(context, l10n, accounts, members, isProtected), child: Text(l10n.reviewTitle)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountDropdown(BuildContext context, AppLocalizations l10n, List<FinancialAccount> accounts) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: _paymentAccountId,
      decoration: InputDecoration(labelText: l10n.fieldPaymentAccount, border: const OutlineInputBorder(), errorText: _accountError),
      items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
      onChanged: (v) => setState(() {
        _paymentAccountId = v;
        _paymentAccount = accounts.where((a) => a.id == v).firstOrNull;
        _accountError = null;
        _warningAcknowledged = false;
        _confirmed = false;
      }),
    );
  }

  Widget _buildAmountField(BuildContext context, AppLocalizations l10n) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      decoration: InputDecoration(labelText: l10n.fieldAmount, border: const OutlineInputBorder(), errorText: _amountError),
      onChanged: (_) => setState(() => _amountError = null),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context, AppLocalizations l10n) {
    return DropdownButtonFormField<TransactionCategory>(
      // ignore: deprecated_member_use
      value: _category,
      decoration: InputDecoration(labelText: l10n.fieldCategory, border: const OutlineInputBorder(), errorText: _categoryError),
      items: TransactionCategory.expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(categoryLabel(l10n, c)))).toList(),
      onChanged: (v) => setState(() {
        _category = v;
        _categoryError = null;
      }),
    );
  }

  Widget _buildMemberDropdown(
    BuildContext context,
    AppLocalizations l10n, {
    required String label,
    required String? value,
    required List<HouseholdMember> members,
    required String? error,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), errorText: error),
      items: members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.displayName))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildScopeDropdown(BuildContext context, AppLocalizations l10n) {
    final scopeOptions = <ExpenseScope, String>{
      ExpenseScope.personal: l10n.scopePersonal,
      ExpenseScope.spouse: l10n.scopeSpouse,
      ExpenseScope.household: l10n.scopeHousehold,
      ExpenseScope.child: l10n.scopeChild,
    };
    return DropdownButtonFormField<ExpenseScope>(
      // ignore: deprecated_member_use
      value: _scope,
      decoration: InputDecoration(labelText: l10n.fieldScope, border: const OutlineInputBorder()),
      items: scopeOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: (v) => setState(() => _scope = v ?? ExpenseScope.personal),
    );
  }

  Widget _buildRecurringToggle(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l10n.fieldRecurring),
        Switch(value: _isRecurring, onChanged: (v) => setState(() => _isRecurring = v)),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, AppLocalizations l10n) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _effectiveDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _effectiveDate = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: l10n.fieldEffectiveDate, border: const OutlineInputBorder()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(_formatDate(_effectiveDate)), const Icon(Icons.calendar_today, size: 18)],
        ),
      ),
    );
  }

  Widget _buildProtectedSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.orange.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.protectedWithdrawalWarning)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _reasonController,
          decoration: InputDecoration(labelText: l10n.fieldWithdrawalReason, border: const OutlineInputBorder(), errorText: _reasonError),
          onChanged: (_) => setState(() => _reasonError = null),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _warningAcknowledged,
          title: Text(l10n.fieldAcknowledgeWarning),
          subtitle: _ackError != null ? Text(_ackError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)) : null,
          onChanged: (v) => setState(() {
            _warningAcknowledged = v ?? false;
            _ackError = null;
          }),
        ),
        CheckboxListTile(
          value: _confirmed,
          title: Text(l10n.fieldConfirmWithdrawal),
          subtitle: _confirmError != null ? Text(_confirmError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)) : null,
          onChanged: (v) => setState(() {
            _confirmed = v ?? false;
            _confirmError = null;
          }),
        ),
      ],
    );
  }

  void _goToReview(BuildContext context, AppLocalizations l10n, List<FinancialAccount> accounts, List<HouseholdMember> members, bool isProtected) {
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
        setState(() => _confirmError = l10n.errorWithdrawalConfirmationRequired);
        hasErrors = true;
      }
    }

    if (hasErrors) return;

    final rawAmountStr = _amountController.text.trim();
    final currencyCode = _paymentAccount?.currencyCode ?? 'EGP';
    final currency = Currency.fromCode(currencyCode);
    final parseResult = MoneyInputFormatter.parse(rawAmountStr, currency);
    if (parseResult is! MoneyParseOk) {
      setState(() => _amountError = l10n.errorMoneyInvalidFormat);
      return;
    }
    if (parseResult.value.minorUnits <= 0) {
      setState(() => _amountError = l10n.errorMoneyInvalidFormat);
      return;
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
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      childWithdrawalAudit: withdrawalAudit,
    );

    ref.read(stagedExpenseContextProvider.notifier).set(ctx);
    context.push('/transactions/new/expense/review');
  }
}
