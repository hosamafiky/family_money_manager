import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/goals/presentation/providers/goal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

const _householdId = 'household-v1';
const _uuid = Uuid();

/// Screen for creating a new savings goal.
class GoalCreationScreen extends ConsumerStatefulWidget {
  const GoalCreationScreen({super.key});

  @override
  ConsumerState<GoalCreationScreen> createState() => _GoalCreationScreenState();
}

class _GoalCreationScreenState extends ConsumerState<GoalCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _initialAmountController = TextEditingController();

  String _selectedCurrency = 'EGP';
  GoalPurpose _selectedPurpose = GoalPurpose.emergencyFund;
  DateTime? _targetDate;
  String? _selectedBeneficiaryMemberId;
  String? _selectedSourceAccountId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _initialAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final targetText = _targetController.text.replaceAll(',', '').trim();
    final targetAmount = (double.tryParse(targetText) ?? 0) * 100;
    if (targetAmount <= 0) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorGoalTargetZero)));
      return;
    }

    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context);
    final useCase = ref.read(createGoalUseCaseProvider);
    final idempotencyKey = _uuid.v4();

    int initialFunding = 0;
    if (_selectedSourceAccountId != null &&
        _initialAmountController.text.isNotEmpty) {
      final fundingText = _initialAmountController.text
          .replaceAll(',', '')
          .trim();
      initialFunding = ((double.tryParse(fundingText) ?? 0) * 100).round();
    }

    final result = await useCase.execute(
      goalName: _nameController.text.trim(),
      purpose: _selectedPurpose,
      currencyCode: _selectedCurrency,
      targetMinorUnits: targetAmount.round(),
      householdId: _householdId,
      idempotencyKey: idempotencyKey,
      targetDate: _targetDate?.toIso8601String().substring(0, 10),
      beneficiaryMemberId: _selectedBeneficiaryMemberId,
      initialFundingSourceAccountId: _selectedSourceAccountId,
      initialFundingMinorUnits: initialFunding,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result is AppOk<dynamic>) {
      ref.invalidate(goalsProvider);
      context.pop();
    } else if (result is AppValidationFailure<SavingsGoal>) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.messageKey)));
    } else if (result is AppInsufficientFunds) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGoalInsufficientReserve)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountsProvider(_householdId));

    // Filter accounts that can be used as funding source.
    final fundingSources = accountsAsync.when(
      data: (result) {
        if (result is! AppOk<List<FinancialAccount>>) {
          return <FinancialAccount>[];
        }
        return result.value
            .where(
              (a) =>
                  !a.isArchived &&
                  !a.isProtected &&
                  a.type != FinancialAccountType.goalReserve,
            )
            .toList();
      },
      loading: () => <FinancialAccount>[],
      error: (_, _) => <FinancialAccount>[],
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalNew)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Goal name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.goalName,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.errorGoalNameEmpty
                  : null,
            ),
            const SizedBox(height: 16),

            // Purpose
            DropdownButtonFormField<GoalPurpose>(
              initialValue: _selectedPurpose,
              decoration: InputDecoration(
                labelText: l10n.goalPurpose,
                border: const OutlineInputBorder(),
              ),
              items: GoalPurpose.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(_purposeLabel(p, l10n)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedPurpose = v!),
            ),
            const SizedBox(height: 16),

            // Currency
            DropdownButtonFormField<String>(
              initialValue: _selectedCurrency,
              decoration: InputDecoration(
                labelText: l10n.goalCurrency,
                border: const OutlineInputBorder(),
              ),
              items: Currency.values
                  .map(
                    (c) => DropdownMenuItem(value: c.code, child: Text(c.code)),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedCurrency = v!;
                _selectedSourceAccountId = null;
              }),
              validator: (v) => (v == null || v.isEmpty)
                  ? l10n.errorGoalCurrencyRequired
                  : null,
            ),
            const SizedBox(height: 16),

            // Target amount
            TextFormField(
              controller: _targetController,
              decoration: InputDecoration(
                labelText: l10n.goalTarget,
                border: const OutlineInputBorder(),
                prefixText: '$_selectedCurrency ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.errorGoalTargetZero;
                final parsed = double.tryParse(v.replaceAll(',', ''));
                if (parsed == null || parsed <= 0) {
                  return l10n.errorGoalTargetZero;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Optional target date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.goalTargetDate),
              subtitle: _targetDate == null
                  ? null
                  : Text(_targetDate!.toIso8601String().substring(0, 10)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickTargetDate,
            ),
            const Divider(),

            // Optional initial funding section
            Text(
              l10n.goalInitialFunding,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _selectedSourceAccountId,
              decoration: InputDecoration(
                labelText: l10n.goalInitialFundingSource,
                border: const OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('— None —'),
                ),
                ...fundingSources
                    .where((a) => a.currencyCode == _selectedCurrency)
                    .map(
                      (a) => DropdownMenuItem<String>(
                        value: a.id,
                        child: Text(a.name),
                      ),
                    ),
              ],
              onChanged: (v) => setState(() => _selectedSourceAccountId = v),
            ),
            if (_selectedSourceAccountId != null) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _initialAmountController,
                decoration: InputDecoration(
                  labelText: l10n.goalInitialFundingAmount,
                  border: const OutlineInputBorder(),
                  prefixText: '$_selectedCurrency ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Transfer note
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.goalTransferNote)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.goalNew),
            ),
          ],
        ),
      ),
    );
  }

  String _purposeLabel(GoalPurpose purpose, AppLocalizations l10n) =>
      switch (purpose) {
        GoalPurpose.emergencyFund => l10n.purposeEmergencyFund,
        GoalPurpose.homePurchase => l10n.purposeHomePurchase,
        GoalPurpose.education => l10n.purposeEducation,
        GoalPurpose.travel => l10n.purposeTravel,
        GoalPurpose.majorPurchase => l10n.purposeMajorPurchase,
        GoalPurpose.familyEvent => l10n.purposeFamilyEvent,
        GoalPurpose.other => l10n.purposeOther,
      };
}
