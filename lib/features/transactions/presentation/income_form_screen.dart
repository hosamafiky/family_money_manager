import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/features/accounts/domain/account_eligibility.dart';
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

/// Form for recording a new income transaction (amount-first, progressive details).
class IncomeFormScreen extends ConsumerStatefulWidget {
  const IncomeFormScreen({this.preselectedAccountId, super.key});

  final String? preselectedAccountId;

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();
  final _noteFocus = FocusNode();

  String? _selectedAccountId;
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
    _scrollController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _ensureVisible(FocusNode node) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted || !node.hasFocus) return;
    final ctx = node.context;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 200),
        alignment: 0.2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountsProvider(_householdId));

    return AppScreenScaffold(
      title: Text(l10n.incomeFormTitle),
      resizeToAvoidBottomInset: true,
      bottomBar: accountsAsync.maybeWhen(
        data: (result) {
          if (result is! AppOk<List<FinancialAccount>>) return null;
          final accounts = result.value
              .where(AccountEligibility.isOrdinaryTransactionEndpoint)
              .toList();
          if (accounts.isEmpty) return null;
          return AppBottomActionBar(
            child: PrimaryActionButton(
              label: l10n.reviewTitle,
              onPressed: () => _goToReview(context, l10n),
            ),
          );
        },
        orElse: () => null,
      ),
      body: accountsAsync.when(
        loading: () => AppLoadingState(message: l10n.loadingLabel),
        error: (_, _) => AppErrorState(
          message: l10n.errorGeneric,
          retryLabel: l10n.retryAction,
          onRetry: () => ref.invalidate(accountsProvider(_householdId)),
        ),
        data: (result) {
          if (result is! AppOk<List<FinancialAccount>>) {
            return AppErrorState(message: l10n.errorGeneric);
          }
          final accounts = result.value
              .where(AccountEligibility.isOrdinaryTransactionEndpoint)
              .toList();

          if (_selectedAccountId != null) {
            final found = accounts
                .where((a) => a.id == _selectedAccountId)
                .firstOrNull;
            if (found == null) {
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
            return AppEmptyState(
              title: l10n.accountsEmpty,
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: l10n.accountsAddButton,
              onAction: () => context.push('/accounts/new'),
            );
          }

          final currencyCode = _selectedAccount?.currencyCode;

          return Form(
            key: _formKey,
            child: ResponsiveContentContainer(
              child: ListView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsetsDirectional.only(
                  top: AppTheme.space16,
                  bottom: AppTheme.space32,
                ),
                children: [
                  AppFormSection(
                    title: l10n.formSectionAmount,
                    child: AmountEntryField(
                      controller: _amountController,
                      label: l10n.fieldAmount,
                      currencyCode: currencyCode,
                      errorText: _amountError,
                      focusNode: _amountFocus,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      onChanged: (_) => setState(() => _amountError = null),
                    ),
                  ),
                  AppFormSection(
                    title: l10n.formSectionAccount,
                    child: AccountSelectorField<FinancialAccount>(
                      label: l10n.fieldDestinationAccount,
                      items: accounts,
                      value: accounts
                          .where((a) => a.id == _selectedAccountId)
                          .firstOrNull,
                      itemLabel: (a) => a.name,
                      errorText: _accountError,
                      onChanged: (a) {
                        setState(() {
                          _selectedAccountId = a?.id;
                          _selectedAccount = a;
                          _accountError = null;
                        });
                      },
                    ),
                  ),
                  AppFormSection(
                    title: l10n.formSectionCategory,
                    child: DropdownButtonFormField<TransactionCategory>(
                      // ignore: deprecated_member_use
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.fieldCategory,
                        errorText: _categoryError,
                      ),
                      items: TransactionCategory.incomeCategories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(categoryLabel(l10n, c)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedCategory = v;
                        _categoryError = null;
                      }),
                    ),
                  ),
                  AppExpandableDetails(
                    title: l10n.formAdvancedDetails,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _effectiveDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _effectiveDate = picked);
                            }
                            if (mounted) _amountFocus.requestFocus();
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
                          focusNode: _noteFocus,
                          textInputAction: TextInputAction.done,
                          onTap: () => _ensureVisible(_noteFocus),
                          decoration: InputDecoration(
                            labelText: l10n.fieldNote,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

    if (_selectedAccountId == null || _selectedCategory == null) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }

    final rawAmount = _amountController.text.trim();
    final currencyCode = _selectedAccount?.currencyCode ?? 'EGP';
    final currency = Currency.fromCode(currencyCode);
    final parseResult = MoneyInputFormatter.parse(rawAmount, currency);
    if (parseResult is! MoneyParseOk || parseResult.value.minorUnits <= 0) {
      setState(() => _amountError = l10n.errorMoneyInvalidFormat);
      _amountFocus.requestFocus();
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
