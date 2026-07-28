/// The numeric keypad every entry flow opens with.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// A key on the pad. Typed rather than a raw string so a caller cannot invent
/// a key the amount parser has no rule for.
sealed class AmountKeypadKey {
  const AmountKeypadKey();
}

/// One of `0`–`9`.
final class DigitKey extends AmountKeypadKey {
  const DigitKey(this.digit);

  final int digit;
}

/// The decimal separator. Suppressed entirely for zero-scale currencies —
/// there is no such thing as a fraction of a yen.
final class DecimalSeparatorKey extends AmountKeypadKey {
  const DecimalSeparatorKey();
}

/// Removes the last character.
final class BackspaceKey extends AmountKeypadKey {
  const BackspaceKey();
}

/// A fixed 3×4 numeric pad, sized so the amount stays visible above it.
///
/// The entry flows open with this already up and the amount focused, which is
/// what makes the common case three taps: amount, category, save. It is a
/// bespoke pad rather than the system keyboard for two reasons — the system
/// keyboard's layout and height vary by device and locale, and it offers keys
/// (letters, emoji, paste) that have no meaning in an amount.
///
/// Digits are Western in both locales, matching every amount the app renders.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    required this.onKey,
    super.key,
    this.showDecimalSeparator = true,
    this.decimalSeparator = '.',
    this.enabled = true,
  });

  final ValueChanged<AmountKeypadKey> onKey;

  /// False for zero-scale currencies such as JPY.
  final bool showDecimalSeparator;

  /// The glyph on the separator key. The parser is separator-agnostic; this is
  /// only what the key looks like.
  final String decimalSeparator;

  final bool enabled;

  /// Every key clears the 48 dp minimum target comfortably.
  static const double keyHeight = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondarySurface,
        border: Border(
          top: BorderSide(
            color: colors.primaryText,
            width: AppTheme.regionRuleWidth,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
          ])
            _Row(
              children: [
                for (final digit in row)
                  _Key(
                    label: '$digit',
                    onTap: enabled ? () => onKey(DigitKey(digit)) : null,
                  ),
              ],
            ),
          _Row(
            children: [
              // The separator key holds its place even when suppressed, so the
              // pad does not reflow between currencies mid-entry.
              showDecimalSeparator
                  ? _Key(
                      label: decimalSeparator,
                      onTap: enabled
                          ? () => onKey(const DecimalSeparatorKey())
                          : null,
                    )
                  : const _Key(label: '', onTap: null),
              _Key(
                label: '0',
                onTap: enabled ? () => onKey(const DigitKey(0)) : null,
              ),
              _Key(
                icon: Icons.backspace_outlined,
                semanticLabel: MaterialLocalizations.of(
                  context,
                ).deleteButtonTooltip,
                onTap: enabled ? () => onKey(const BackspaceKey()) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Row(children: [for (final child in children) Expanded(child: child)]);
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, this.onTap, this.semanticLabel});

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    final roles = context.textRoles;

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          // Square system: a tonal press, never an expanding circle.
          splashFactory: NoSplash.splashFactory,
          highlightColor: colors.mainSurface,
          child: Container(
            height: AmountKeypad.keyHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.divider),
                right: BorderSide(color: colors.divider),
              ),
            ),
            child: icon != null
                ? Icon(icon, size: 20, color: colors.primaryText)
                : Text(
                    label ?? '',
                    // Tabular so the keys do not jitter between digits.
                    style: roles.reportValue.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
