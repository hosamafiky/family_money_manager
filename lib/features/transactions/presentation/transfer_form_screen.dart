import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/features/accounts/domain/account_eligibility.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/transactions/domain/child_withdrawal_context.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

const _householdId = 'household-v1';
const _createdBy = 'member-primary-v1';

/// Form for executing a money transfer between two accounts.
class TransferFormScreen extends ConsumerStatefulWidget {
  const TransferFormScreen({this.preselectedAccountId, super.key});

  final String? preselectedAccountId;

  @override
  ConsumerState<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends ConsumerState<TransferFormScreen> {
  final _scrollController = ScrollController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _reasonController = TextEditingController();
  final _amountFocus = FocusNode();

  String? _sourceAccountId;
  String? _destinationAccountId;
  DateTime _effectiveDate = DateTime.now();

  bool _warningAcknowledged = false;
  bool _confirmed = false;

  String? _sourceError;
  String? _destError;
  String? _amountError;
  String? _reasonError;
  String? _ackError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _sourceAccountId = widget.preselectedAccountId;
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

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountsProvider(_householdId));

    return AppScreenScaffold(
      title: Text(l10n.transferFormTitle),
      resizeToAvoidBottomInset: true,
      bottomBar: accountsAsync.maybeWhen(
        data: (result) {
          if (result is! AppOk<List<FinancialAccount>>) return null;
          final accounts = result.value
              .where(AccountEligibility.isOrdinaryTransactionEndpoint)
              .toList();
          if (accounts.isEmpty) return null;
          final sourceAccount = accounts
              .where((a) => a.id == _sourceAccountId)
              .firstOrNull;
          final isProtectedSource =
              sourceAccount?.requiresWithdrawalAudit ?? false;
          return AppBottomActionBar(
            child: PrimaryActionButton(
              label: l10n.reviewTitle,
              onPressed: () =>
                  _goToReview(context, l10n, accounts, isProtectedSource),
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

          if (_sourceAccountId != null &&
              accounts.every((a) => a.id != _sourceAccountId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _sourceAccountId = null);
            });
          }
          if (_destinationAccountId != null &&
              accounts.every((a) => a.id != _destinationAccountId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _destinationAccountId = null);
            });
          }

          if (accounts.isEmpty) {
            return AppEmptyState(
              title: l10n.accountsEmpty,
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: l10n.accountsAddButton,
              onAction: () => context.push('/accounts/new'),
            );
          }

          final sourceAccount = accounts
              .where((a) => a.id == _sourceAccountId)
              .firstOrNull;
          final destAccount = accounts
              .where((a) => a.id == _destinationAccountId)
              .firstOrNull;
          final isProtectedSource =
              sourceAccount?.requiresWithdrawalAudit ?? false;
          final hasCurrencyMismatch =
              sourceAccount != null &&
              destAccount != null &&
              sourceAccount.currencyCode != destAccount.currencyCode;

          return ResponsiveContentContainer(
            child: ListView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsetsDirectional.only(
                top: AppTheme.space16,
                bottom: AppTheme.space32,
              ),
              children: [
                AppInlineNotice(
                  message: l10n.transferInternalExplanation,
                  tone: AppNoticeTone.info,
                ),
                const SizedBox(height: AppTheme.space16),
                AppFormSection(
                  title: l10n.formSectionAmount,
                  child: AmountEntryField(
                    controller: _amountController,
                    label: l10n.fieldAmount,
                    currencyCode: sourceAccount?.currencyCode,
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
                  child: Column(
                    children: [
                      AccountSelectorField<FinancialAccount>(
                        label: l10n.fieldSourceAccount,
                        items: accounts,
                        value: sourceAccount,
                        itemLabel: (a) => a.name,
                        errorText: _sourceError,
                        onChanged: (a) => setState(() {
                          _sourceAccountId = a?.id;
                          _sourceError = null;
                          _destError = null;
                          _warningAcknowledged = false;
                          _confirmed = false;
                        }),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      AccountSelectorField<FinancialAccount>(
                        label: l10n.fieldDestinationAccount,
                        items: accounts,
                        value: destAccount,
                        itemLabel: (a) => a.name,
                        errorText: _destError,
                        onChanged: (a) => setState(() {
                          _destinationAccountId = a?.id;
                          _destError = null;
                        }),
                      ),
                      if (_sourceAccountId != null &&
                          _destinationAccountId != null &&
                          _sourceAccountId == _destinationAccountId)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            top: AppTheme.space8,
                          ),
                          child: Text(
                            l10n.errorSameAccount,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (hasCurrencyMismatch)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            top: AppTheme.space8,
                          ),
                          child: Text(
                            l10n.errorCurrencyMismatch,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AppExpandableDetails(
                  title: l10n.formAdvancedDetails,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                        decoration: InputDecoration(labelText: l10n.fieldNote),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (isProtectedSource) ...[
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
    );
  }

  void _goToReview(
    BuildContext context,
    AppLocalizations l10n,
    List<FinancialAccount> accounts,
    bool isProtected,
  ) {
    bool hasErrors = false;

    if (_sourceAccountId == null) {
      setState(() => _sourceError = l10n.errorGeneric);
      hasErrors = true;
    }
    if (_destinationAccountId == null) {
      setState(() => _destError = l10n.errorGeneric);
      hasErrors = true;
    }
    if (_sourceAccountId != null &&
        _destinationAccountId != null &&
        _sourceAccountId == _destinationAccountId) {
      setState(() => _destError = l10n.errorSameAccount);
      hasErrors = true;
    }

    if (_sourceAccountId != null && _destinationAccountId != null) {
      final src = accounts.where((a) => a.id == _sourceAccountId).firstOrNull;
      final dst = accounts
          .where((a) => a.id == _destinationAccountId)
          .firstOrNull;
      if (src != null && dst != null && src.currencyCode != dst.currencyCode) {
        setState(() => _destError = l10n.errorCurrencyMismatch);
        hasErrors = true;
      }
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

    if (hasErrors) return;

    final sourceAccount = accounts.firstWhere((a) => a.id == _sourceAccountId);
    final currency = Currency.fromCode(sourceAccount.currencyCode);
    final parseResult = MoneyInputFormatter.parse(rawAmount, currency);
    if (parseResult is! MoneyParseOk || parseResult.value.minorUnits <= 0) {
      setState(() => _amountError = l10n.errorMoneyInvalidFormat);
      return;
    }
    final minorUnits = parseResult.value.minorUnits;
    final idemKey = ref.read(transferFormKeyProvider);

    ChildWithdrawalContext? withdrawalAudit;
    if (isProtected) {
      withdrawalAudit = ChildWithdrawalContext(
        protectedAccountId: _sourceAccountId!,
        beneficiaryMemberId: _createdBy,
        reason: _reasonController.text.trim(),
        warningAcknowledged: _warningAcknowledged,
        confirmed: _confirmed,
      );
    }

    final ctx = TransferContext(
      operationId: const Uuid().v4(),
      idempotencyKey: idemKey,
      householdId: _householdId,
      sourceAccountId: _sourceAccountId!,
      destinationAccountId: _destinationAccountId!,
      amountMinorUnits: minorUnits,
      currencyCode: sourceAccount.currencyCode,
      effectiveDate: _formatDate(_effectiveDate),
      createdBy: _createdBy,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      childWithdrawalAudit: withdrawalAudit,
    );

    ref.read(stagedTransferContextProvider.notifier).set(ctx);
    context.push('/transactions/new/transfer/review');
  }
}
