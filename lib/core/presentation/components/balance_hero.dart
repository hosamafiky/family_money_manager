/// The dominant region of the dashboard and of every account detail.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/financial_amount_text.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// One currency's contribution to a balance hero.
///
/// A quantity holding — gold — is not a currency and never carries a money
/// value here; [quantityLabel] renders instead, because a gold valuation is a
/// market price, not a ledger fact.
@immutable
class BalanceHeroCurrency {
  const BalanceHeroCurrency({
    required this.currencyCode,
    required this.currencyLabel,
    required this.minorUnits,
    this.accountCount,
    this.quantityLabel,
    this.warningLabel,
  });

  final String currencyCode;

  /// The currency's own name, localised — "Egyptian pound", not "EGP".
  final String currencyLabel;

  final int minorUnits;

  /// How many accounts make up this figure. Shown only for the primary row.
  final int? accountCount;

  /// Set for a non-money holding. When present the row prints this instead of
  /// an amount.
  final String? quantityLabel;

  /// A notice about this figure, localised — a negative available balance,
  /// typically. `warning` sits on the notice, never on the amount.
  final String? warningLabel;
}

/// Answers "how much can I spend, in which currency" — and nothing else.
///
/// The primary currency is rendered at `displayBalance`, one per screen
/// maximum. Every other currency present follows beneath it at `reportValue`,
/// one per hairline-separated row. There is no switcher: hiding a currency
/// behind a control is how money gets forgotten.
///
/// It never shows a combined total, and never a figure the ledger did not
/// produce. Where a grand total would sit it prints a refusal line instead —
/// users read a missing total as a bug, so the absence is stated rather than
/// implied.
class BalanceHero extends StatelessWidget {
  const BalanceHero({
    required this.label,
    required this.currencies,
    super.key,
    this.exclusionNote,
    this.trailing,
  });

  /// What this balance is, localised.
  final String label;

  /// Primary currency first. An empty list renders nothing — a zero hero is
  /// not the answer to "how much can I spend", it is the absence of a
  /// question, and the empty state belongs to the screen.
  final List<BalanceHeroCurrency> currencies;

  /// What the figure deliberately leaves out, localised. Printed beneath the
  /// refusal line so the headline is never quietly incomplete.
  final String? exclusionNote;

  /// The privacy toggle, typically.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (currencies.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final colors = context.financialColors;
    final roles = context.textRoles;
    final primary = currencies.first;
    final secondary = currencies.skip(1).toList();

    return Container(
      width: double.infinity,
      color: colors.mainSurface,
      padding: const EdgeInsets.only(
        top: AppTheme.space40,
        bottom: AppTheme.space20,
        left: AppTheme.space16,
        right: AppTheme.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: roles.sectionTitle)),
              if (trailing case final Widget widget) widget,
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          FinancialAmountText(
            minorUnits: primary.minorUnits,
            currencyCode: primary.currencyCode,
            size: FinancialAmountSize.display,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            [
              primary.currencyLabel,
              if (primary.accountCount case final int count)
                l10n.dashboardFromAccounts(count),
            ].join(' · '),
            style: roles.supportingMeta,
          ),
          if (primary.warningLabel case final String warning) ...[
            const SizedBox(height: AppTheme.space8),
            _Warning(label: warning),
          ],
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            for (final currency in secondary) ...[
              _SecondaryRow(currency: currency),
              if (currency.warningLabel case final String warning)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space8),
                  child: _Warning(label: warning),
                ),
            ],
          ],
          const SizedBox(height: AppTheme.space12),
          // The 2 px ink rule that separates a region from what follows.
          Container(
            height: AppTheme.regionRuleWidth,
            color: colors.primaryText,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            l10n.dashboardNoCombinedTotal,
            style: roles.supportingMeta.copyWith(color: colors.neutralInfo),
          ),
          if (exclusionNote case final String note) ...[
            const SizedBox(height: AppTheme.space4),
            Text(
              note,
              style: roles.supportingMeta.copyWith(color: colors.neutralInfo),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecondaryRow extends StatelessWidget {
  const _SecondaryRow({required this.currency});

  final BalanceHeroCurrency currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    final roles = context.textRoles;

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
      child: Row(
        children: [
          Expanded(child: Text(currency.currencyLabel, style: roles.body)),
          const SizedBox(width: AppTheme.space12),
          if (currency.quantityLabel case final String quantity)
            // A quantity row, never a currency row: 50.000 g of gold is not
            // money and must never be summed with any of it.
            Text(quantity, style: roles.reportValue)
          else
            Flexible(
              child: FinancialAmountText(
                minorUnits: currency.minorUnits,
                currencyCode: currency.currencyCode,
                size: FinancialAmountSize.report,
              ),
            ),
        ],
      ),
    );
  }
}

/// A notice about a figure. The `warning` role goes here — on the notice
/// around the amount — and never on the amount itself.
class _Warning extends StatelessWidget {
  const _Warning({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    return Semantics(
      label: label,
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, size: 16, color: colors.warning),
          const SizedBox(width: AppTheme.space4),
          Flexible(
            child: Text(
              label,
              style: context.textRoles.supportingMeta.copyWith(
                color: colors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
