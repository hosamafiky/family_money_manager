import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/budgets/domain/budget.dart';
import 'package:family_money_manager/features/budgets/presentation/providers/budget_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

const _householdId = 'household-v1';

/// Screen for creating a new budget plan.
class BudgetCreationScreen extends ConsumerStatefulWidget {
  const BudgetCreationScreen({super.key});

  @override
  ConsumerState<BudgetCreationScreen> createState() => _BudgetCreationScreenState();
}

class _BudgetCreationScreenState extends ConsumerState<BudgetCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();

  String _selectedCurrency = 'EGP';
  BudgetPeriodType _periodType = BudgetPeriodType.monthly;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? (_startDate?.add(const Duration(days: 30)) ?? DateTime.now().add(const Duration(days: 30))));

    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2020), lastDate: DateTime(2050));
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_periodType == BudgetPeriodType.fixed) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end dates.')));
        return;
      }
      if (!_endDate!.isAfter(_startDate!)) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorBudgetEndBeforeStart)));
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final limitText = _limitController.text.replaceAll(',', '');
    final limitMajor = double.tryParse(limitText) ?? 0;
    final scale = Currency.fromCode(_selectedCurrency).minorUnitScale;
    final limitMinorUnits = (limitMajor * _pow10(scale)).round();

    BudgetPeriodDefinition period;
    if (_periodType == BudgetPeriodType.monthly) {
      period = const MonthlyBudgetPeriod();
    } else {
      final fmt = DateFormat('yyyy-MM-dd');
      period = FixedBudgetPeriod(startDateInclusive: fmt.format(_startDate!), endDateExclusive: fmt.format(_endDate!));
    }

    final useCase = ref.read(createBudgetUseCaseProvider);
    final result = await useCase.execute(
      householdId: _householdId,
      name: _nameController.text.trim(),
      currencyCode: _selectedCurrency,
      limitMinorUnits: limitMinorUnits,
      periodDefinition: period,
      filter: const BudgetFilter(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    switch (result) {
      case AppOk(:final value):
        ref.invalidate(budgetsProvider(_householdId));
        context.go('/budgets/${value.id}');
      case AppValidationFailure(:final messageKey):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageKey)));
      case AppDuplicateConflict():
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A budget with this configuration already exists.')));
      default:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create budget.')));
    }
  }

  int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetNew)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Budget name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.budgetName, border: const OutlineInputBorder()),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.errorBudgetNameEmpty : null,
            ),
            const SizedBox(height: 16),

            // Currency selector
            DropdownButtonFormField<String>(
              initialValue: _selectedCurrency,
              decoration: InputDecoration(labelText: l10n.budgetCurrency, border: const OutlineInputBorder()),
              items: Currency.values.map((c) => DropdownMenuItem(value: c.code, child: Text(c.code))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCurrency = v);
              },
              validator: (v) => (v == null || v.isEmpty) ? l10n.errorBudgetCurrencyRequired : null,
            ),
            const SizedBox(height: 16),

            // Limit field
            TextFormField(
              controller: _limitController,
              decoration: InputDecoration(
                labelText: _periodType == BudgetPeriodType.monthly ? l10n.budgetLimit : l10n.budgetLimitFixed,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.errorBudgetLimitZero;
                final parsed = double.tryParse(v.replaceAll(',', ''));
                if (parsed == null || parsed <= 0) {
                  return l10n.errorBudgetLimitZero;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Period type
            Text('Period Type', style: Theme.of(context).textTheme.titleSmall),
            SegmentedButton<BudgetPeriodType>(
              segments: [
                ButtonSegment(
                  value: BudgetPeriodType.monthly,
                  label: Text(l10n.budgetPeriodMonthly, style: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.repeat, size: 16),
                ),
                ButtonSegment(
                  value: BudgetPeriodType.fixed,
                  label: Text(l10n.budgetPeriodFixed, style: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.date_range, size: 16),
                ),
              ],
              selected: {_periodType},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) setState(() => _periodType = s.first);
              },
            ),

            if (_periodType == BudgetPeriodType.fixed) ...[
              const SizedBox(height: 8),
              _DatePickerTile(label: l10n.budgetStartDate, date: _startDate, onTap: () => _pickDate(isStart: true)),
              const SizedBox(height: 8),
              _DatePickerTile(label: l10n.budgetEndDate, date: _endDate, onTap: () => _pickDate(isStart: false)),
            ],

            const SizedBox(height: 16),

            // Overlap note
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.budgetOverlapNote, style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.budgetNew),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');
    return ListTile(
      title: Text(label),
      subtitle: Text(date != null ? fmt.format(date!) : 'Not selected'),
      trailing: const Icon(Icons.calendar_today),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      onTap: onTap,
    );
  }
}
