/// Privacy mode, inherited once and read by exactly one widget.
///
/// `FinancialAmountText` is the only reader. No other component may implement
/// masking: the moment two widgets can each decide to hide a number, the
/// guarantee that *every* derived monetary value is concealed becomes a claim
/// nobody can check.
library;

import 'package:flutter/widgets.dart';

/// Makes privacy mode available to the money primitives beneath it.
///
/// Privacy mode is app-wide state, not a route and not a per-screen flag, so
/// it is supplied at the top of the tree and read implicitly. A screen never
/// passes `masked:` down by hand — doing so is how a row gets missed.
class PrivacyScope extends InheritedWidget {
  const PrivacyScope({required this.masked, required super.child, super.key});

  /// Whether monetary values are concealed.
  ///
  /// What this hides is deliberately narrow: amounts, and only amounts.
  /// Dates, names, categories, ratios, labels, regions, rules, hatching and
  /// the lock all stay visible, because a masked ledger must still answer
  /// *what happened* — it withholds only *how much*.
  final bool masked;

  static PrivacyScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PrivacyScope>();

  /// Whether amounts should be concealed at [context]. Defaults to visible.
  static bool isMasked(BuildContext context) =>
      maybeOf(context)?.masked ?? false;

  @override
  bool updateShouldNotify(PrivacyScope oldWidget) => masked != oldWidget.masked;
}
