import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/features/accounts/application/create_account_use_case.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';
const _createdBy = 'household-v1-user';

/// Screen for creating a new financial account.
///
/// Shows:
/// - Account type selection (limited to 7 Phase-3A types)
/// - Owner selection (constrained by type)
/// - Name field with validation
/// - Currency selection
/// - Optional opening balance with validation
/// - Opening balance date picker
/// - Notes field
/// - Confirmation dialog for child fund
/// - Duplicate-tap prevention while submitting
class AccountCreationScreen extends ConsumerStatefulWidget {
  const AccountCreationScreen({super.key});

  @override
  ConsumerState<AccountCreationScreen> createState() => _AccountCreationScreenState();
}

class _AccountCreationScreenState extends ConsumerState<AccountCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  FinancialAccountType _type = FinancialAccountType.personalCashWallet;
  AccountOwnerType _ownerType = AccountOwnerType.user;
  FundPurpose _fundPurpose = FundPurpose.available;
  String _currencyCode = 'EGP';
  String? _openingDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const _supportedTypes = [
    FinancialAccountType.personalCashWallet,
    FinancialAccountType.spouseCashWallet,
    FinancialAccountType.householdCash,
    FinancialAccountType.homeSavingsCash,
    FinancialAccountType.bankAccount,
    FinancialAccountType.mobileWallet,
    FinancialAccountType.childProtectedFund,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(FinancialAccountType type) {
    setState(() {
      _type = type;
      _ownerType = _defaultOwner(type);
      _fundPurpose = _defaultPurpose(type);
    });
  }

  static AccountOwnerType _defaultOwner(FinancialAccountType type) => switch (type) {
    FinancialAccountType.spouseCashWallet => AccountOwnerType.spouse,
    FinancialAccountType.householdCash ||
    FinancialAccountType.homeSavingsCash => AccountOwnerType.household,
    FinancialAccountType.childProtectedFund => AccountOwnerType.child,
    _ => AccountOwnerType.user,
  };

  static FundPurpose _defaultPurpose(FinancialAccountType type) => switch (type) {
    FinancialAccountType.homeSavingsCash => FundPurpose.longTermSavings,
    FinancialAccountType.childProtectedFund => FundPurpose.childProtected,
    _ => FundPurpose.available,
  };

  static bool _isProtectedType(FinancialAccountType type) =>
      type == FinancialAccountType.childProtectedFund;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context);

    // Show child-fund confirmation dialog.
    if (_isProtectedType(_type)) {
      final confirmed = await _showChildFundDialog(l10n);
      if (!confirmed) return;
    }

    final currency = Currency.fromCode(_currencyCode);
    int? openingBalance;
    if (_balanceCtrl.text.trim().isNotEmpty) {
      final parsed = MoneyInputFormatter.parse(_balanceCtrl.text, currency);
      switch (parsed) {
        case MoneyParseOk(:final value):
          openingBalance = value.minorUnits;
        case MoneyParseEmpty():
          openingBalance = null;
        case MoneyParseValidationError(:final messageKey):
          setState(() => _errorMessage = _resolveKey(messageKey, l10n));
          return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final useCase = ref.read(createAccountUseCaseProvider);
    final result = await useCase.execute(
      CreateAccountWorkflowParams(
        householdId: _householdId,
        name: _nameCtrl.text,
        type: _type,
        ownerType: _ownerType,
        fundPurpose: _fundPurpose,
        currencyCode: _currencyCode,
        isSpendable: !_isProtectedType(_type),
        isProtected: _isProtectedType(_type),
        includeInNetWorth: true,
        includeInZakat: !_isProtectedType(_type),
        createdBy: _createdBy,
        openingBalanceMinorUnits: openingBalance,
        openingBalanceDate: _openingDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );

    if (!mounted) return;

    switch (result) {
      case AppOk():
        // Invalidate accounts list so it refreshes.
        ref.invalidate(accountsProvider(_householdId));
        context.pop();
      case AppValidationFailure(:final messageKey):
        setState(() {
          _isSubmitting = false;
          _errorMessage = _resolveKey(messageKey, l10n);
        });
      case AppDuplicateConflict(:final messageKey):
        setState(() {
          _isSubmitting = false;
          _errorMessage = _resolveKey(messageKey, l10n);
        });
      default:
        setState(() {
          _isSubmitting = false;
          _errorMessage = l10n.errorGeneric;
        });
    }
  }

  Future<bool> _showChildFundDialog(AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountChildFundConfirmTitle),
        content: Text(l10n.accountChildFundConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirm)),
        ],
      ),
    );
    return result ?? false;
  }

  String _resolveKey(String key, AppLocalizations l10n) => switch (key) {
    'error_account_name_empty' => l10n.errorAccountNameEmpty,
    'error_opening_balance_negative' => l10n.errorOpeningBalanceNegative,
    'error_account_duplicate' => l10n.errorAccountDuplicate,
    'error_validation_generic' => l10n.errorValidationGeneric,
    'error_money_invalid_format' => l10n.errorMoneyInvalidFormat,
    'error_money_excess_decimals' => l10n.errorMoneyExcessDecimals,
    'error_money_overflow' => l10n.errorMoneyOverflow,
    _ => l10n.errorGeneric,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountCreateTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selection
            DropdownButtonFormField<FinancialAccountType>(
              // ignore: deprecated_member_use
              value: _type,
              decoration: InputDecoration(
                labelText: l10n.accountOwner,
                border: const OutlineInputBorder(),
              ),
              items: _supportedTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t, l10n))))
                  .toList(),
              onChanged: (t) {
                if (t != null) _onTypeChanged(t);
              },
            ),
            const SizedBox(height: 16),
            // Name field
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.accountName,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.errorAccountNameEmpty;
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // Currency selection
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _currencyCode,
              decoration: InputDecoration(
                labelText: l10n.accountCurrency,
                border: const OutlineInputBorder(),
              ),
              items: Currency.values
                  .map((c) => DropdownMenuItem(value: c.code, child: Text(c.code)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _currencyCode = v);
              },
            ),
            const SizedBox(height: 16),
            // Opening balance
            TextFormField(
              controller: _balanceCtrl,
              decoration: InputDecoration(
                labelText: l10n.accountOpeningBalance,
                border: const OutlineInputBorder(),
                suffixText: _currencyCode,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: l10n.accountNotes,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            if (_isProtectedType(_type)) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer.withAlpha(80),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.accountProtectedWarning),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  static String _typeLabel(FinancialAccountType type, AppLocalizations l10n) => switch (type) {
    FinancialAccountType.personalCashWallet => l10n.accountTypePersonalCash,
    FinancialAccountType.spouseCashWallet => l10n.accountTypeSpouseCash,
    FinancialAccountType.householdCash => l10n.accountTypeHouseholdCash,
    FinancialAccountType.homeSavingsCash => l10n.accountTypeHomeSavings,
    FinancialAccountType.bankAccount => l10n.accountTypeBankAccount,
    FinancialAccountType.mobileWallet => l10n.accountTypeMobileWallet,
    FinancialAccountType.childProtectedFund => l10n.accountTypeChildFund,
    _ => type.code,
  };
}
