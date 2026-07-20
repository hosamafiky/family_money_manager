import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountEntryField extends StatelessWidget {
  const AmountEntryField({
    required this.controller,
    required this.label,
    super.key,
    this.currencyCode,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? currencyCode;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: inputFormatters,
      style: context.textRoles.displayBalance.copyWith(fontSize: 28),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: context.textRoles.formLabel,
        errorText: errorText,
        suffixText: currencyCode,
        suffixStyle: context.textRoles.supportingMeta,
      ),
    );
  }
}

class AccountSelectorField<T> extends StatelessWidget {
  const AccountSelectorField({
    required this.label,
    required this.items,
    required this.itemLabel,
    super.key,
    this.value,
    this.onChanged,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(itemLabel(item))),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

class PeriodSelector<T> extends StatelessWidget {
  const PeriodSelector({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    super.key,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
      child: Row(
        children: [
          for (final option in options) ...[
            FilterChip(
              label: Text(labelOf(option)),
              selected: option == selected,
              onSelected: (_) => onSelected(option),
              showCheckmark: false,
            ),
            const SizedBox(width: AppTheme.space8),
          ],
        ],
      ),
    );
  }
}

class FilterChipGroup<T> extends StatelessWidget {
  const FilterChipGroup({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    super.key,
    this.multi = false,
  });

  final List<T> options;
  final Set<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<Set<T>> onChanged;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.space8,
      runSpacing: AppTheme.space8,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(labelOf(option)),
            selected: selected.contains(option),
            onSelected: (isSelected) {
              final next = Set<T>.from(selected);
              if (multi) {
                if (isSelected) {
                  next.add(option);
                } else {
                  next.remove(option);
                }
              } else {
                next
                  ..clear()
                  ..add(option);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}
