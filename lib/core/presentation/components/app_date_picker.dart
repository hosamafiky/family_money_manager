/// The date sheet.
///
/// A sheet from the bottom, like every other choice in this app, rather than
/// a rounded dialog in the middle of the screen.
///
/// Two things it owns that the stock picker cannot. First, the three
/// shortcuts: almost every date this app asks for is today, yesterday or the
/// start of the month, and the calendar grid is the fallback rather than the
/// primary control. Second, and load-bearing, the future is disabled or
/// enabled *by what the date is for* — a ledger entry cannot happen in the
/// future, a goal's target date is nothing but the future. Every call site
/// previously passed its own ad-hoc bounds, and one of them let an expense be
/// recorded a year from now.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/states_forms_actions.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

/// What the date being chosen is *for*, which is what decides its bounds.
///
/// Passing bounds directly is what produced the defect this replaces: every
/// caller invented its own pair, and the one that mattered got it wrong. A
/// caller states the meaning and the component derives the range.
enum DatePurpose {
  /// A date something already happened on — an expense, a transfer, a
  /// statement. The future is disabled: a ledger records what happened.
  ledgerEntry,

  /// A date something is aimed at — a goal's target, a certificate's
  /// maturity. The future is the whole point.
  futureTarget,
}

/// Shows the date sheet and returns the chosen date, or null if dismissed.
///
/// [earliest] defaults to ten years back. That is a floor to keep the grid
/// finite, not a rule about the data: a caller with a real lower bound — a
/// certificate's start date, a budget's period — should pass it, because a
/// grid that offers impossible dates makes the user discover the constraint
/// by being rejected.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DatePurpose purpose,
  DateTime? earliest,
  DateTime? latest,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final first = earliest ?? DateTime(today.year - 10, today.month, today.day);
  final last =
      latest ??
      switch (purpose) {
        DatePurpose.ledgerEntry => today,
        // Far enough for a long certificate or a slow goal, and no further:
        // a grid reaching 2100 is a grid nobody scrolls.
        DatePurpose.futureTarget => DateTime(today.year + 25, 12, 31),
      };

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DateSheet(
      // Clamped, so a caller whose stored date falls outside its own bounds
      // opens on a valid day instead of tripping an assertion.
      initialDate: initialDate.isBefore(first)
          ? first
          : (initialDate.isAfter(last) ? last : initialDate),
      firstDate: first,
      lastDate: last,
      purpose: purpose,
    ),
  );
}

class _DateSheet extends StatefulWidget {
  const _DateSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.purpose,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final DatePurpose purpose;

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  late DateTime _selected = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.financialColors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final shortcuts = <(String, DateTime)>[
      (l10n.datePickerToday, today),
      (l10n.datePickerYesterday, today.subtract(const Duration(days: 1))),
      (l10n.datePickerStartOfMonth, DateTime(today.year, today.month)),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space8,
              AppTheme.space8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.datePickerTitle,
                    style: context.textRoles.screenTitle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // The shortcuts come before the grid because they answer the
          // question most of the time. A shortcut outside the caller's own
          // bounds is dropped rather than offered and refused.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space8,
              children: [
                for (final (label, date) in shortcuts)
                  if (!date.isBefore(widget.firstDate) &&
                      !date.isAfter(widget.lastDate))
                    ActionChip(
                      label: Text(label),
                      onPressed: () => Navigator.of(context).pop(date),
                    ),
              ],
            ),
          ),
          if (widget.purpose == DatePurpose.ledgerEntry)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space16,
                AppTheme.space12,
                AppTheme.space16,
                0,
              ),
              // Says why the greyed days are grey. An explained constraint is
              // a rule; an unexplained one is a bug the user works around.
              child: AppInlineNotice(message: l10n.datePickerNoFuture),
            ),
          Flexible(
            child: SingleChildScrollView(
              // Material's grid, this app's chrome and bounds. Month and
              // weekday names still come from Flutter's own bundle rather
              // than the ARB — the one part of the specification not met
              // here, and the reason is that it needs a hand-built grid.
              child: CalendarDatePicker(
                initialDate: _selected,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                onDateChanged: (date) => setState(() => _selected = date),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.divider)),
            ),
            padding: const EdgeInsets.all(AppTheme.space16),
            width: double.infinity,
            child: PrimaryActionButton(
              label: l10n.datePickerConfirm,
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ),
        ],
      ),
    );
  }
}
