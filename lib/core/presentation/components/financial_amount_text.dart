/// The money primitives. Everything else in the app delegates to these.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/amount_display_formatter.dart';
import 'package:family_money_manager/core/presentation/components/privacy_scope.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// Which *class* of money this is — what it is, not what it is doing.
///
/// Drives colour only. Orthogonal to [FinancialAmountDirection]: a protected
/// withdrawal is `protected` money moving `outflow`, and a transfer fee is
/// `expense` money inside a transfer.
enum FinancialAmountTone {
  neutral,
  income,
  expense,
  transfer,
  protected,
  goal,
  certificate,

  /// Reversed entries and other corrections: present, readable, and
  /// deliberately quiet. A correction is not a threshold, so it is grey ink
  /// rather than the warning role.
  muted,
}

/// What the money is *doing* — what it is, is [FinancialAmountTone].
///
/// Drives the sign and the direction glyph, which are two of the four
/// redundant channels that make a money row readable without colour.
enum FinancialAmountDirection {
  /// A stated balance. No sign, no glyph — a balance is not a movement.
  none,

  /// Into the household. Always `+` and `↓`.
  inflow,

  /// Out of the household. Always `−` (U+2212) and `↑`.
  outflow,

  /// Between the household's own accounts. `⇄`, and never a sign: a transfer
  /// changes no total, so it is neither positive nor negative.
  internal,

  /// Money that exists but cannot be spent. No sign; carries the lock.
  held,
}

/// One amount, one class, one direction.
///
/// The single point in the app where a number becomes pixels, and therefore
/// the only place sign placement, bidi isolation, tabular figures, privacy
/// masking and screen-reader phrasing are implemented. A feature that renders
/// an amount with `Text` has bypassed all five.
///
/// Callers pass the magnitude in minor units and let the component decide
/// everything about its presentation. They never pre-sign a string, never
/// append a currency code, and never colour it at the call site.
class FinancialAmountText extends StatelessWidget {
  const FinancialAmountText({
    required this.minorUnits,
    required this.currencyCode,
    super.key,
    this.tone = FinancialAmountTone.neutral,
    this.direction = FinancialAmountDirection.none,
    this.size = FinancialAmountSize.standard,
    this.isStruckThrough = false,
    this.semanticsContext,
  });

  /// The magnitude. The sign is taken from [direction], not from this value,
  /// so callers cannot accidentally render a double negative by passing a
  /// negative number to an outflow.
  final int minorUnits;

  final String currencyCode;
  final FinancialAmountTone tone;
  final FinancialAmountDirection direction;
  final FinancialAmountSize size;

  /// A reversed entry keeps its amount in place and strikes it through — the
  /// original is never removed from the ledger.
  final bool isStruckThrough;

  /// Extra context for screen readers, spoken after the amount: the account,
  /// the beneficiary, the reason it is held. Must already be localised.
  final String? semanticsContext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.financialColors;
    final roles = context.textRoles;
    final masked = PrivacyScope.isMasked(context);

    final style = switch (size) {
      FinancialAmountSize.display => roles.displayBalance,
      FinancialAmountSize.report => roles.reportValue,
      FinancialAmountSize.standard => roles.financialAmount,
    }.copyWith(color: _color(colors), decoration: _decoration);

    final formatted = AmountDisplayFormatter.format(minorUnits, currencyCode);
    final sign = _sign;
    final glyph = _glyph;

    return Semantics(
      // The amount is announced as one phrase; its parts must not be read as
      // separate nodes, or a screen reader says "minus" and the number in
      // whichever order the layout happened to produce.
      container: true,
      excludeSemantics: true,
      label: _semanticsLabel(l10n, formatted, masked: masked),
      // A Wrap, not a Row: amount and currency code are a flex-wrap pair, so
      // at 200% text scale the code drops below the number instead of
      // truncating it. A truncated amount is worse than a tall row.
      child: Wrap(
        spacing: AppTheme.space4,
        runSpacing: AppTheme.space4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (glyph != null) Text(glyph, style: style),
          if (direction == FinancialAmountDirection.held)
            Icon(Icons.lock_outline, size: _lockSize, color: _color(colors)),
          if (sign != null) Text(sign, style: style),
          // The number is its own child rather than part of a single string,
          // which is what keeps the sign on the correct side in RTL: its
          // position is a layout fact, not an outcome of the bidi algorithm.
          // The isolate then stops the digits themselves from reordering.
          if (masked)
            _MaskedDigits(formatted: _isolate(formatted), style: style)
          else
            Text(_isolate(formatted), style: style),
          // The code trails the number in both scripts. Because this wraps
          // under the ambient direction, "trails" resolves correctly on its
          // own: leftmost in RTL, rightmost in LTR.
          Text(
            currencyCode,
            style: roles.supportingMeta.copyWith(color: colors.secondaryText),
          ),
        ],
      ),
    );
  }

  double get _lockSize => switch (size) {
    FinancialAmountSize.display => 24,
    FinancialAmountSize.report => 18,
    FinancialAmountSize.standard => 16,
  };

  TextDecoration? get _decoration =>
      isStruckThrough ? TextDecoration.lineThrough : null;

  Color _color(AppFinancialColors colors) => switch (tone) {
    FinancialAmountTone.neutral => colors.primaryText,
    FinancialAmountTone.income => colors.income,
    FinancialAmountTone.expense => colors.expense,
    FinancialAmountTone.transfer => colors.transfer,
    FinancialAmountTone.protected => colors.protectedMoney,
    FinancialAmountTone.goal => colors.goalReserved,
    FinancialAmountTone.certificate => colors.certificatePrincipal,
    FinancialAmountTone.muted => colors.secondaryText,
  };

  /// U+2212 MINUS SIGN, not an ASCII hyphen: the hyphen is bidi-neutral and
  /// visually short beside tabular figures.
  String? get _sign => switch (direction) {
    FinancialAmountDirection.inflow => '+',
    FinancialAmountDirection.outflow => '−',
    FinancialAmountDirection.internal => null,
    FinancialAmountDirection.held => null,
    FinancialAmountDirection.none => null,
  };

  /// Describes money entering or leaving *the household*, not a direction on
  /// screen — so these are never mirrored in RTL. `⇄` is symmetric anyway.
  String? get _glyph => switch (direction) {
    FinancialAmountDirection.inflow => '↓',
    FinancialAmountDirection.outflow => '↑',
    FinancialAmountDirection.internal => '⇄',
    FinancialAmountDirection.held => null,
    FinancialAmountDirection.none => null,
  };

  /// U+2068 FIRST STRONG ISOLATE.
  static const String _fsi = '\u2068';

  /// U+2069 POP DIRECTIONAL ISOLATE.
  static const String _pdi = '\u2069';

  /// Wraps a numeric run in an isolate so the bidi algorithm cannot reorder
  /// it against the surrounding text.
  ///
  /// Written as escapes rather than literal characters on purpose: the code
  /// points are invisible, and a reviewer cannot see one that has been
  /// deleted or duplicated.
  static String _isolate(String value) => '$_fsi$value$_pdi';

  String _semanticsLabel(
    AppLocalizations l10n,
    String formatted, {
    required bool masked,
  }) {
    final parts = <String>[
      // The class leads, so a screen-reader user learns whether the money is
      // spendable before hearing what it is worth.
      switch (direction) {
        FinancialAmountDirection.inflow => l10n.transactionTypeIncome,
        FinancialAmountDirection.outflow => l10n.transactionTypeExpense,
        FinancialAmountDirection.internal => l10n.transactionTypeTransfer,
        FinancialAmountDirection.held =>
          '${l10n.amountHeld}, ${l10n.amountNotSpendable}',
        FinancialAmountDirection.none => '',
      },
      // Masked amounts expose that a value exists and is hidden — never the
      // value, and never a placeholder that could be mistaken for one. The
      // currency code is not repeated here; it is already in the label above.
      if (masked) l10n.amountHidden else '$formatted $currencyCode',
      if (semanticsContext case final String extra) extra,
    ];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }
}

/// Which type role an amount renders at. Not a font size — a position in the
/// hierarchy, of which only one `display` is allowed per screen.
enum FinancialAmountSize { standard, report, display }

/// Solid ink bars, one per digit group, at the exact width of the digits they
/// conceal.
///
/// Bars rather than blur: blur is expensive down a long list, survives
/// screenshots imperfectly, and still leaks magnitude. Bars leak the number of
/// digit groups, which is the same information the layout width already gives
/// away, and nothing more.
class _MaskedDigits extends StatelessWidget {
  const _MaskedDigits({required this.formatted, required this.style});

  /// The string the bars stand in for, isolates included.
  final String formatted;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final groups = AmountDisplayFormatter.digitGroups(formatted);
    final scaler = MediaQuery.textScalerOf(context);
    final barHeight = (style.fontSize ?? 16) * 0.62 * scaler.scale(1);

    final barWidths = [for (final g in groups) _measure(g, scaler)];

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        // The real text, fully transparent, is what sizes this widget.
        // Measuring with a TextPainter instead left the masked run about
        // 2.5 dp narrower than the visible one — enough to shift a column
        // when privacy is toggled, which is exactly what must not happen.
        // Nothing is rasterised at zero opacity, and the parent Semantics
        // excludes its descendants, so no value reaches the screen or a
        // screen reader.
        Opacity(opacity: 0, child: Text(formatted, style: style)),
        Positioned.fill(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < groups.length; i++)
                Container(
                  width: barWidths[i],
                  height: barHeight,
                  color: style.color,
                ),
            ],
          ),
        ),
      ],
    );
  }

  double _measure(String text, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    return painter.width;
  }
}
