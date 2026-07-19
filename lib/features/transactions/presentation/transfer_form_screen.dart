import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
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
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _reasonController = TextEditingController();

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferFormTitle)),
      body: accountsAsync.when(
        loading: () => Center(child: Text(l10n.loadingLabel)),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (result) {
          if (result is! AppOk<List<FinancialAccount>>) {
            return Center(child: Text(l10n.errorGeneric));
          }
          final accounts = result.value.where((a) => !a.isArchived && a.type != FinancialAccountType.goalReserve).toList();

          // Clear invalid preselected IDs (archived accounts).
          if (_sourceAccountId != null && accounts.every((a) => a.id != _sourceAccountId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _sourceAccountId = null);
            });
          }
          if (_destinationAccountId != null && accounts.every((a) => a.id != _destinationAccountId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _destinationAccountId = null);
            });
          }

          final sourceAccount = accounts.where((a) => a.id == _sourceAccountId).firstOrNull;
          final destAccount = accounts.where((a) => a.id == _destinationAccountId).firstOrNull;
          final isProtectedSource = sourceAccount?.requiresWithdrawalAudit ?? false;
          final hasCurrencyMismatch = sourceAccount != null && destAccount != null && sourceAccount.currencyCode != destAccount.currencyCode;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAccountDropdown(
                context,
                l10n,
                label: l10n.fieldSourceAccount,
                value: _sourceAccountId,
                accounts: accounts,
                error: _sourceError,
                onChanged: (v) => setState(() {
                  _sourceAccountId = v;
                  _sourceError = null;
                  _destError = null;
                  _warningAcknowledged = false;
                  _confirmed = false;
                }),
              ),
              const SizedBox(height: 16),
              _buildAccountDropdown(
                context,
                l10n,
                label: l10n.fieldDestinationAccount,
                value: _destinationAccountId,
                accounts: accounts,
                error: _destError,
                onChanged: (v) => setState(() {
                  _destinationAccountId = v;
                  _destError = null;
                }),
              ),
              if (_sourceAccountId != null && _destinationAccountId != null && _sourceAccountId == _destinationAccountId)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l10n.errorSameAccount, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                ),
              if (hasCurrencyMismatch)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l10n.errorCurrencyMismatch, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                decoration: InputDecoration(labelText: l10n.fieldAmount, border: const OutlineInputBorder(), errorText: _amountError),
                onChanged: (_) => setState(() => _amountError = null),
              ),
              const SizedBox(height: 16),
              InkWell(
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
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: l10n.fieldNote, border: const OutlineInputBorder()),
                maxLines: 2,
              ),
              if (isProtectedSource) ...[const SizedBox(height: 24), _buildProtectedSection(context, l10n)],
              const SizedBox(height: 24),
              FilledButton(onPressed: () => _goToReview(context, l10n, accounts, isProtectedSource), child: Text(l10n.reviewTitle)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccountDropdown(
    BuildContext context,
    AppLocalizations l10n, {
    required String label,
    required String? value,
    required List<FinancialAccount> accounts,
    required String? error,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), errorText: error),
      items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
      onChanged: onChanged,
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
        const SizedBox(height: 8),
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

  void _goToReview(BuildContext context, AppLocalizations l10n, List<FinancialAccount> accounts, bool isProtected) {
    bool hasErrors = false;

    if (_sourceAccountId == null) {
      setState(() => _sourceError = l10n.errorGeneric);
      hasErrors = true;
    }
    if (_destinationAccountId == null) {
      setState(() => _destError = l10n.errorGeneric);
      hasErrors = true;
    }
    if (_sourceAccountId != null && _destinationAccountId != null && _sourceAccountId == _destinationAccountId) {
      setState(() => _destError = l10n.errorSameAccount);
      hasErrors = true;
    }

    // Block cross-currency transfers at the form level.
    if (_sourceAccountId != null && _destinationAccountId != null) {
      final src = accounts.where((a) => a.id == _sourceAccountId).firstOrNull;
      final dst = accounts.where((a) => a.id == _destinationAccountId).firstOrNull;
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
        setState(() => _confirmError = l10n.errorWithdrawalConfirmationRequired);
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
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      childWithdrawalAudit: withdrawalAudit,
    );

    ref.read(stagedTransferContextProvider.notifier).set(ctx);
    context.push('/transactions/new/transfer/review');
  }
}
