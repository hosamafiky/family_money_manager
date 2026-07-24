import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/resolve_message_key.dart';
import 'package:family_money_manager/features/accounts/domain/account_eligibility.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/goals/presentation/goal_money_formatter.dart';
import 'package:family_money_manager/features/goals/presentation/providers/goal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

const _householdId = 'household-v1';

/// Screen to add funds from a source account to a goal's reserve.
///
/// Displays: source account selector (excludes goalReserve, certificate,
/// protected, and non-spendable accounts), amount field, projected
/// before/after balances, and a note that this is an internal transfer
/// (not an expense).
class FundGoalScreen extends ConsumerStatefulWidget {
  const FundGoalScreen({required this.goalId, super.key});

  final String goalId;

  @override
  ConsumerState<FundGoalScreen> createState() => _FundGoalScreenState();
}

class _FundGoalScreenState extends ConsumerState<FundGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedSourceAccountId;
  bool _isSubmitting = false;

  /// Generated once per user intent in [initState].
  /// Reused for duplicate taps and retries; rotated on success.
  late String _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = const Uuid().v4();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit(SavingsGoal goal) async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    if (_selectedSourceAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGoalSourceAccountRequired)),
      );
      return;
    }

    final amountText = _amountController.text.replaceAll(',', '').trim();
    final amount = ((double.tryParse(amountText) ?? 0) * 100).round();
    if (amount <= 0) return;

    setState(() => _isSubmitting = true);
    final useCase = ref.read(fundGoalUseCaseProvider);

    final result = await useCase.execute(
      goalId: widget.goalId,
      sourceAccountId: _selectedSourceAccountId!,
      amountMinorUnits: amount,
      householdId: _householdId,
      idempotencyKey: _idempotencyKey,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result is AppOk) {
      _idempotencyKey = const Uuid().v4();
      invalidateGoalMoneyProviders(ref, goalId: widget.goalId);
      context.pop();
    } else if (result is AppInsufficientFunds) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGoalInsufficientReserve)),
      );
    } else if (result is AppValidationFailure<SavingsGoal>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resolveMessageKey(l10n, result.messageKey))),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goalAsync = ref.watch(goalDetailProvider(widget.goalId));
    final accountsAsync = ref.watch(accountsProvider(_householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalFundTitle)),
      body: goalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (result) {
          if (result is! AppOk<SavingsGoal?> || result.value == null) {
            return Center(child: Text(l10n.goalNotFound));
          }
          final goal = result.value!;

          // Filter eligible source accounts via shared AccountEligibility.
          final sources = accountsAsync.when(
            data: (ar) {
              if (ar is! AppOk<List<FinancialAccount>>) {
                return <FinancialAccount>[];
              }
              return ar.value
                  .where(
                    (a) =>
                        AccountEligibility.isGoalFundingSource(
                          a,
                          currencyCode: goal.currencyCode,
                        ) &&
                        a.id != goal.reserveAccountId,
                  )
                  .toList();
            },
            loading: () => <FinancialAccount>[],
            error: (_, _) => <FinancialAccount>[],
          );

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(goal.name, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${l10n.goalTarget}: ${goal.currencyCode} ${GoalMoneyFormatter.format(goal.targetMinorUnits, goal.currencyCode)}',
                ),
                const SizedBox(height: 16),

                // Source account selector
                DropdownButtonFormField<String>(
                  initialValue: _selectedSourceAccountId,
                  decoration: InputDecoration(
                    labelText: l10n.goalSourceAccount,
                    border: const OutlineInputBorder(),
                  ),
                  items: sources
                      .map(
                        (a) => DropdownMenuItem<String>(
                          value: a.id,
                          child: Text(a.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedSourceAccountId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Amount field
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: l10n.goalAmount,
                    border: const OutlineInputBorder(),
                    prefixText: '${goal.currencyCode} ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final parsed = double.tryParse(v.replaceAll(',', ''));
                    if (parsed == null || parsed <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Transfer note
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(l10n.goalTransferNote)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submit(goal),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.goalFundAction),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
