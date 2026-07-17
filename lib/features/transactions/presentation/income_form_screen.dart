import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
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

/// Form for recording a new income transaction.
class IncomeFormScreen extends ConsumerStatefulWidget {
  const IncomeFormScreen({this.preselectedAccountId, super.key});

  final String? preselectedAccountId;

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedAccountId;
  // Track the full account so we can read its currency at submission time.
  FinancialAccount? _selectedAccount;
  TransactionCategory? _selectedCategory;
  DateTime _effectiveDate = DateTime.now();
  String? _amountError;
  String? _accountError;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.preselectedAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.incomeFormTitle)),
      body: accountsAsync.when(
        loading: () => Center(child: Text(l10n.loadingLabel)),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (result) {
          if (result is! AppOk<List<FinancialAccount>>) {
            return Center(child: Text(l10n.errorGeneric));
          }
          final accounts = result.value.where((a) => !a.isArchived).toList();

          // Sync tracked account; clear preselected ID if account is now archived.
          if (_selectedAccountId != null) {
            final found = accounts
                .where((a) => a.id == _selectedAccountId)
                .firstOrNull;
            if (found == null) {
              // Archived or missing — schedule reset to avoid setState-in-build.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedAccountId = null;
                    _selectedAccount = null;
                  });
                }
              });
            } else {
              _selectedAccount ??= found;
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
                    Text(
                      l10n.accountsEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push('/accounts/new'),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.accountsAddButton),
                    ),
                  ],
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Destination Account
                _buildAccountDropdown(context, l10n, accounts),
                const SizedBox(height: 16),
                // Amount
                _buildAmountField(context, l10n),
                const SizedBox(height: 16),
                // Category
                _buildCategoryDropdown(context, l10n),
                const SizedBox(height: 16),
                // Effective date
                _buildDatePicker(context, l10n),
                const SizedBox(height: 16),
                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.fieldNote,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _goToReview(context, l10n),
                  child: Text(l10n.reviewTitle),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountDropdown(
    BuildContext context,
    AppLocalizations l10n,
    List<FinancialAccount> accounts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedAccountId,
          decoration: InputDecoration(
            labelText: l10n.fieldDestinationAccount,
            border: const OutlineInputBorder(),
            errorText: _accountError,
          ),
          items: accounts
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedAccountId = v;
              _selectedAccount = accounts.where((a) => a.id == v).firstOrNull;
              _accountError = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAmountField(BuildContext context, AppLocalizations l10n) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      decoration: InputDecoration(
        labelText: l10n.fieldAmount,
        border: const OutlineInputBorder(),
        errorText: _amountError,
      ),
      onChanged: (_) => setState(() => _amountError = null),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context, AppLocalizations l10n) {
    return DropdownButtonFormField<TransactionCategory>(
      // ignore: deprecated_member_use
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: l10n.fieldCategory,
        border: const OutlineInputBorder(),
        errorText: _categoryError,
      ),
      items: TransactionCategory.incomeCategories
          .map(
            (c) =>
                DropdownMenuItem(value: c, child: Text(categoryLabel(l10n, c))),
          )
          .toList(),
      onChanged: (v) => setState(() {
        _selectedCategory = v;
        _categoryError = null;
      }),
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
        decoration: InputDecoration(
          labelText: l10n.fieldEffectiveDate,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDate(_effectiveDate)),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }

  void _goToReview(BuildContext context, AppLocalizations l10n) {
    setState(() {
      _accountError = _selectedAccountId == null ? l10n.errorGeneric : null;
      _categoryError = _selectedCategory == null
          ? l10n.errorCategoryRequired
          : null;
    });

    if (_selectedAccountId == null || _selectedCategory == null) return;

    final rawAmount = _amountController.text.trim();
    final currencyCode = _selectedAccount?.currencyCode ?? 'EGP';
    final currency = Currency.fromCode(currencyCode);
    final parseResult = MoneyInputFormatter.parse(rawAmount, currency);
    if (parseResult is! MoneyParseOk) {
      setState(() => _amountError = l10n.errorMoneyInvalidFormat);
      return;
    }
    if (parseResult.value.minorUnits <= 0) {
      setState(() => _amountError = l10n.errorMoneyInvalidFormat);
      return;
    }
    final minorUnits = parseResult.value.minorUnits;
    final idemKey = ref.read(incomeFormProvider).idempotencyKey;

    final ctx = IncomeContext(
      operationId: const Uuid().v4(),
      idempotencyKey: idemKey,
      householdId: _householdId,
      destinationAccountId: _selectedAccountId!,
      amountMinorUnits: minorUnits,
      currencyCode: currencyCode,
      category: _selectedCategory!,
      effectiveDate: _formatDate(_effectiveDate),
      createdBy: _createdBy,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    ref.read(stagedIncomeContextProvider.notifier).set(ctx);
    context.push('/transactions/new/income/review');
  }
}
