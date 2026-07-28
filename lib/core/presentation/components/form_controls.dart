import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The first thing the user sees in every entry flow.
///
/// A ruled row, not a boxed field: 56 dp tall, the currency code pinned at the
/// trailing edge, and a 2 px bottom rule that goes ink on focus and expense on
/// error. There is no spinner and no stepper — money is typed.
class AmountEntryField extends StatelessWidget {
  const AmountEntryField({
    required this.controller,
    required this.label,
    super.key,
    this.currencyCode,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.inputFormatters,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
  });

  final TextEditingController controller;

  /// Sits above the field, never inside it: a label that doubles as a
  /// placeholder disappears exactly when the user needs it.
  final String label;

  final String? currencyCode;

  /// Persistent. A validation failure stays on screen at its cause until the
  /// cause is fixed — it is never a snackbar.
  final String? errorText;

  /// Shown when there is no error — a reason the field is disabled, typically.
  final String? helperText;

  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;

  /// True when an [AmountKeypad] drives the value instead of the system
  /// keyboard. The field still shows a cursor and still takes focus.
  final bool readOnly;

  static const double fieldHeight = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    final roles = context.textRoles;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: roles.formLabel.copyWith(
            color: enabled ? colors.secondaryText : colors.disabled,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        SizedBox(
          height: fieldHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  autofocus: autofocus,
                  readOnly: readOnly,
                  // The pad supplies digits; showing the system keyboard as
                  // well would put two number rows on screen at once.
                  showCursor: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: inputFormatters,
                  style: roles.displayBalance.copyWith(
                    fontSize: 32,
                    color: enabled ? colors.primaryText : colors.disabled,
                  ),
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              if (currencyCode case final String code) ...[
                const SizedBox(width: AppTheme.space8),
                // Fixed at the trailing edge — it never scrolls with the
                // digits, so a long amount cannot push it off the row.
                Text(
                  code,
                  style: roles.supportingMeta.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
        // The rule is the field. Ink at rest, expense on error.
        Container(
          height: AppTheme.regionRuleWidth,
          color: hasError
              ? colors.expense
              : (enabled ? colors.primaryText : colors.disabled),
        ),
        if (errorText case final String error) ...[
          const SizedBox(height: AppTheme.space4),
          // liveRegion so a screen reader announces the failure without the
          // user having to go looking for it.
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: colors.expense),
                const SizedBox(width: AppTheme.space4),
                Flexible(
                  child: Text(
                    error,
                    style: roles.supportingMeta.copyWith(color: colors.expense),
                  ),
                ),
              ],
            ),
          ),
        ] else if (helperText case final String helper) ...[
          const SizedBox(height: AppTheme.space4),
          // A disabled control always carries a reason: `disabled` is 2.6:1
          // and cannot convey its own state.
          Text(
            helper,
            style: roles.supportingMeta.copyWith(color: colors.secondaryText),
          ),
        ],
      ],
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
    this.horizontalPadding = AppTheme.space16,
    super.key,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  /// Applied inside the scroll view so the row stays full-bleed.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // The margin lives here, never on a wrapping Padding: an outer Padding
      // shrinks the viewport so the chips stop short of the screen edge.
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppTheme.space4,
      ),
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
