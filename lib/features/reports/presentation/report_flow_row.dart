/// One movement line in an account's period flow.
///
/// Not a new component — it returns a [CurrencyAmountRow] and adds no styling
/// of its own. What it owns is the one decision the report screens kept
/// getting subtly wrong: a stored figure may be signed or unsigned depending
/// on which query produced it, and [FinancialAmountText] takes a *magnitude*
/// and derives the sign from the direction. Passing a pre-negated value to it
/// renders a double negative; passing a positive value to a line that
/// represents a subtraction renders a lie. Deciding it once, here, is why
/// both flow reports can be read as arithmetic.
library;

import 'package:family_money_manager/core/presentation/components/components.dart';

/// A flow line whose direction comes from the sign of [signedMinorUnits].
///
/// Use for figures that can legitimately go either way — adjustments, the net
/// effect of reversals — where the sign is data rather than a property of the
/// row.
CurrencyAmountRow signedFlowRow({
  required String label,
  required int signedMinorUnits,
  required String currencyCode,
  FinancialAmountTone tone = FinancialAmountTone.neutral,
  bool isEmphasised = false,
  bool showDivider = true,
}) => CurrencyAmountRow(
  label: label,
  minorUnits: signedMinorUnits.abs(),
  currencyCode: currencyCode,
  tone: tone,
  direction: signedMinorUnits < 0
      ? FinancialAmountDirection.outflow
      : FinancialAmountDirection.inflow,
  isEmphasised: isEmphasised,
  showDivider: showDivider,
);

/// A flow line whose direction is fixed by what the row *is*.
///
/// [magnitudeMinorUnits] is always passed unsigned: an expense line is an
/// outflow because it is an expense, not because its stored value happens to
/// be negative.
CurrencyAmountRow flowRow({
  required String label,
  required int magnitudeMinorUnits,
  required String currencyCode,
  required FinancialAmountDirection direction,
  FinancialAmountTone tone = FinancialAmountTone.neutral,
  bool isEmphasised = false,
  bool showDivider = true,
}) => CurrencyAmountRow(
  label: label,
  minorUnits: magnitudeMinorUnits.abs(),
  currencyCode: currencyCode,
  tone: tone,
  direction: direction,
  isEmphasised: isEmphasised,
  showDivider: showDivider,
);

/// A stated balance: no sign, no glyph, because a balance is not a movement.
CurrencyAmountRow balanceRow({
  required String label,
  required int minorUnits,
  required String currencyCode,
  bool isEmphasised = false,
  bool showDivider = true,
}) => CurrencyAmountRow(
  label: label,
  minorUnits: minorUnits,
  currencyCode: currencyCode,
  isEmphasised: isEmphasised,
  showDivider: showDivider,
);
