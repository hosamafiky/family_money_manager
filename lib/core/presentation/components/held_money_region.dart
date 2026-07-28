/// The held-money region: everything the household owns but cannot spend.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/financial_amount_text.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// One held holding, already classified and already formatted by the screen.
@immutable
class HeldMoneyEntry {
  const HeldMoneyEntry({
    required this.name,
    required this.reasonLabel,
    required this.minorUnits,
    required this.currencyCode,
    required this.tone,
    this.detail,
    this.onTap,
  });

  final String name;

  /// Why it is held, localised — "certificate principal", "reserved for a
  /// goal", "protected".
  final String reasonLabel;

  final int minorUnits;
  final String currencyCode;

  /// The class colour. Chosen by the screen from the domain's reason, never
  /// inferred here.
  final FinancialAmountTone tone;

  /// Maturity date, progress, beneficiary — whatever makes the hold concrete.
  final String? detail;

  final VoidCallback? onTap;
}

/// A ruled, recessed region holding money that cannot be spent.
///
/// Held money never appears in the same list as spendable money — not greyed
/// out inside it, not sorted to the bottom of it. Four independent signals say
/// so: it sits below a 2 px ink rule, on the recessed surface, under its own
/// heading, and every row is labelled with its reason. The layout does the
/// work, so the distinction survives greyscale, privacy mode and a screen
/// reader.
///
/// The subtotal is per currency and is explicitly scoped to this region: it is
/// never added to the available balance, and the line beneath it says so.
class HeldMoneyRegion extends StatelessWidget {
  const HeldMoneyRegion({
    required this.entries,
    required this.subtotalsByCurrency,
    super.key,
  });

  final List<HeldMoneyEntry> entries;

  /// One subtotal per currency, keyed by ISO code. Computed by the query —
  /// summing a column of amounts is balance arithmetic, not layout.
  final Map<String, int> subtotalsByCurrency;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final colors = context.financialColors;
    final roles = context.textRoles;

    return Container(
      width: double.infinity,
      color: colors.recessedSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The region boundary. This is what M3 would have done with
          // elevation.
          Container(
            height: AppTheme.regionRuleWidth,
            color: colors.primaryText,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space24,
              AppTheme.space16,
              AppTheme.space8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.accountRegionHeld,
                    style: roles.sectionTitle,
                  ),
                ),
                Text(
                  l10n.dashboardHeldVaults(entries.length),
                  style: roles.supportingMeta,
                ),
              ],
            ),
          ),
          for (final entry in entries) _HeldRow(entry: entry),
          for (final currency in subtotalsByCurrency.keys)
            _Subtotal(
              currencyCode: currency,
              minorUnits: subtotalsByCurrency[currency]!,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space4,
              AppTheme.space16,
              AppTheme.space24,
            ),
            child: Text(
              l10n.dashboardHeldNotAdded,
              style: roles.supportingMeta.copyWith(color: colors.neutralInfo),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeldRow extends StatelessWidget {
  const _HeldRow({required this.entry});

  final HeldMoneyEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.financialColors;
    final roles = context.textRoles;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: entry.onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: colors.secondarySurface,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.name, style: roles.cardTitle, maxLines: 3),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      [entry.reasonLabel, ?entry.detail].join(' · '),
                      style: roles.supportingMeta,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Flexible(
                flex: 3,
                child: FinancialAmountText(
                  minorUnits: entry.minorUnits,
                  currencyCode: entry.currencyCode,
                  tone: entry.tone,
                  direction: FinancialAmountDirection.held,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Subtotal extends StatelessWidget {
  const _Subtotal({required this.currencyCode, required this.minorUnits});

  final String currencyCode;
  final int minorUnits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roles = context.textRoles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space12,
        AppTheme.space16,
        AppTheme.space4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.dashboardHeldSubtotal(currencyCode),
              style: roles.cardTitle,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Flexible(
            child: FinancialAmountText(
              minorUnits: minorUnits,
              currencyCode: currencyCode,
              size: FinancialAmountSize.report,
            ),
          ),
        ],
      ),
    );
  }
}
