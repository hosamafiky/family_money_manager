import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
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

/// Screen to release funds from a goal's reserve to a destination account.
///
/// Requires a release reason. Displays a note that this is an internal
/// transfer (not income).
class ReleaseGoalScreen extends ConsumerStatefulWidget {
  const ReleaseGoalScreen({required this.goalId, super.key});

  final String goalId;

  @override
  ConsumerState<ReleaseGoalScreen> createState() => _ReleaseGoalScreenState();
}

class _ReleaseGoalScreenState extends ConsumerState<ReleaseGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _selectedDestinationAccountId;
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
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit(SavingsGoal goal) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDestinationAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a destination account.')));
      return;
    }

    final amountText = _amountController.text.replaceAll(',', '').trim();
    final amount = ((double.tryParse(amountText) ?? 0) * 100).round();
    if (amount <= 0) return;

    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context);
    final useCase = ref.read(releaseGoalFundsUseCaseProvider);

    final result = await useCase.execute(
      goalId: widget.goalId,
      destinationAccountId: _selectedDestinationAccountId!,
      amountMinorUnits: amount,
      releaseReason: _reasonController.text.trim(),
      householdId: _householdId,
      idempotencyKey: _idempotencyKey,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result is AppOk) {
      _idempotencyKey = const Uuid().v4();
      ref.invalidate(goalProgressProvider(widget.goalId));
      ref.invalidate(goalsProvider(_householdId));
      context.pop();
    } else if (result is AppInsufficientFunds) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorGoalInsufficientReserve)));
    } else if (result is AppValidationFailure<SavingsGoal>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.messageKey)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goalAsync = ref.watch(goalDetailProvider(widget.goalId));
    final accountsAsync = ref.watch(accountsProvider(_householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalReleaseTitle)),
      body: goalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (result) {
          if (result is! AppOk<SavingsGoal?> || result.value == null) {
            return const Center(child: Text('Goal not found.'));
          }
          final goal = result.value!;

          // Eligible destinations: same currency, not goalReserve, not archived.
          final destinations = accountsAsync.when(
            data: (ar) {
              if (ar is! AppOk<List<FinancialAccount>>) {
                return <FinancialAccount>[];
              }
              return ar.value
                  .where(
                    (a) => !a.isArchived && a.type != FinancialAccountType.goalReserve && a.currencyCode == goal.currencyCode && a.id != goal.reserveAccountId,
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
                const SizedBox(height: 16),

                // Destination account selector
                DropdownButtonFormField<String>(
                  initialValue: _selectedDestinationAccountId,
                  decoration: InputDecoration(labelText: l10n.goalDestinationAccount, border: const OutlineInputBorder()),
                  items: destinations.map((a) => DropdownMenuItem<String>(value: a.id, child: Text(a.name))).toList(),
                  onChanged: (v) => setState(() => _selectedDestinationAccountId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Amount field
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: l10n.goalAmount, border: const OutlineInputBorder(), prefixText: '${goal.currencyCode} '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final parsed = double.tryParse(v.replaceAll(',', ''));
                    if (parsed == null || parsed <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Release reason (required)
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(labelText: l10n.goalReleaseReason, border: const OutlineInputBorder()),
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.errorGoalReleaseReasonEmpty : null,
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
                        Expanded(child: Text(l10n.goalReleaseTransferNote)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submit(goal),
                  child: _isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.goalReleaseAction),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
