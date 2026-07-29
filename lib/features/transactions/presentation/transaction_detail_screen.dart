/// A single operation, its real double entry, and the append-only correction
/// that can follow it.
///
/// There is no edit and no delete on this screen, and rather than hiding that,
/// the screen names it: a mistake is fixed by adding a reversing entry that
/// points at this one, and both stay in the ledger. Showing the debit and the
/// credit is what makes "balances are derived, never stored" legible — the
/// user learns the data model by reading their own transaction.
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_detail.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Shows full detail for a single operation with its ledger entries.
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.operationId, super.key});

  final String operationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(
      transactionDetailWithLedgerProvider((operationId, _householdId)),
    );

    return AppScreenScaffold(
      title: Text(l10n.transactionDetailTitle),
      body: detailAsync.when(
        loading: () => AppLoadingState(message: l10n.loadingLabel),
        error: (_, _) => AppErrorState(message: l10n.errorGeneric),
        data: (detail) {
          if (detail == null) return AppErrorState(message: l10n.errorGeneric);
          return _DetailBody(detail: detail);
        },
      ),
      bottomBar: detailAsync.maybeWhen(
        data: (detail) {
          if (detail == null) return null;
          // An operation is reversed once. The slot states why the action is
          // gone rather than silently dropping it, so the absence is
          // explained rather than mysterious.
          if (detail.isNeutralised) {
            return AppBottomActionBar(
              child: AppInlineNotice(
                message: l10n.detailAlreadyReversedNoAction,
                tone: AppNoticeTone.info,
              ),
            );
          }
          return AppBottomActionBar(
            child: SecondaryActionButton(
              label: l10n.detailAddReversalAction,
              onPressed: () =>
                  context.push('/transactions/$operationId/reverse'),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final TransactionDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.financialColors;
    final summary = detail.summary;
    final op = summary.operation;
    final isReversedOriginal = op.isReversed;

    final direction = switch (op.type) {
      OperationType.income => FinancialAmountDirection.inflow,
      OperationType.transfer => FinancialAmountDirection.internal,
      OperationType.reversal => FinancialAmountDirection.inflow,
      _ => FinancialAmountDirection.outflow,
    };
    // A neutralised operation's amount goes quiet rather than keeping its
    // class colour: its effect on every balance is now zero, and colouring it
    // as live money would contradict the banner directly above it.
    final tone = detail.isNeutralised
        ? FinancialAmountTone.muted
        : switch (op.type) {
            OperationType.income => FinancialAmountTone.income,
            OperationType.transfer => FinancialAmountTone.transfer,
            _ => FinancialAmountTone.expense,
          };

    return ResponsiveContentContainer(
      child: ListView(
        padding: const EdgeInsetsDirectional.only(
          top: AppTheme.space16,
          bottom: AppTheme.space32,
        ),
        children: [
          if (isReversedOriginal) ...[
            _horizontal(
              AppInlineNotice(
                message: l10n.detailReversedBannerBody(op.updatedAt),
                tone: AppNoticeTone.info,
                icon: Icons.undo,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
          ],
          _horizontal(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppTheme.space8,
                  runSpacing: AppTheme.space8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      operationTypeLabel(l10n, op.type),
                      style: context.textRoles.cardTitle,
                    ),
                    StatusBadge(
                      label: isReversedOriginal
                          ? l10n.transactionReversed
                          : l10n.detailStatusPosted,
                      foreground: isReversedOriginal
                          ? colors.secondaryText
                          : colors.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                // The one component that turns a number into pixels owns the
                // scale, the sign, the bidi isolation and the phrasing. This
                // screen printed raw minor units before — 382.50 as "38250".
                FinancialAmountText(
                  minorUnits: op.totalAmountMinorUnits,
                  currencyCode: op.currencyCode,
                  tone: tone,
                  direction: direction,
                  size: FinancialAmountSize.display,
                  isStruckThrough: isReversedOriginal,
                ),
              ],
            ),
          ),
          if (detail.counterpart case final ReversalCounterpart counterpart)
            ..._chain(context, l10n, counterpart),
          if (detail.ledgerLines.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space24),
            SectionHeader(
              title: isReversedOriginal
                  ? l10n.detailLedgerEntriesOriginalTitle
                  : l10n.detailLedgerEntriesTitle,
            ),
            // The two sides, stated as debit and credit rather than implied by
            // a sign. Both use CurrencyAmountRow — no new component.
            for (final line in detail.ledgerLines)
              CurrencyAmountRow(
                label: line.direction == LedgerDirection.debit
                    ? l10n.reviewDebitLabel(line.accountName)
                    : l10n.reviewCreditLabel(line.accountName),
                minorUnits: line.amountMinorUnits,
                currencyCode: line.currencyCode,
                tone: detail.isNeutralised
                    ? FinancialAmountTone.muted
                    : FinancialAmountTone.neutral,
              ),
            if (isReversedOriginal) ...[
              const SizedBox(height: AppTheme.space12),
              _horizontal(
                Text(
                  l10n.detailEntriesStillInLedgerNote,
                  style: context.textRoles.supportingMeta.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: AppTheme.space24),
          AppReviewSection(
            title: l10n.detailSectionTitle,
            rows: [
              AppReviewRowData(
                label: l10n.fieldEffectiveDate,
                value: op.effectiveDate,
              ),
              if (summary.categoryCode case final String code)
                AppReviewRowData(
                  label: l10n.fieldCategory,
                  value: categoryLabelFromCode(l10n, code),
                ),
              // Names, not UUIDs. The id remains the fallback so a missing
              // join reads as missing data rather than as a blank row.
              if (op.sourceAccountId case final String id)
                AppReviewRowData(
                  label: l10n.fieldSourceAccount,
                  value: summary.sourceAccountName ?? id,
                ),
              if (op.destinationAccountId case final String id)
                AppReviewRowData(
                  label: l10n.fieldDestinationAccount,
                  value: summary.destinationAccountName ?? id,
                ),
              if (summary.spenderMemberId case final String id)
                AppReviewRowData(
                  label: l10n.fieldSpender,
                  value: summary.spenderName ?? id,
                ),
              if (summary.beneficiaryMemberId case final String id)
                AppReviewRowData(
                  label: l10n.fieldBeneficiary,
                  value: summary.beneficiaryName ?? id,
                ),
              if (summary.scope case final scope?)
                AppReviewRowData(
                  label: l10n.fieldScope,
                  value: expenseScopeLabel(l10n, scope),
                ),
              AppReviewRowData(
                label: l10n.fieldRecurring,
                value: summary.isRecurring
                    ? l10n.recurringYes
                    : l10n.recurringOneTime,
              ),
              if (summary.note case final String note)
                AppReviewRowData(label: l10n.fieldNote, value: note),
              // The reversal's own reason, shown wherever the reversal is
              // opened: "reversed" says nothing, "entered twice" says
              // everything.
              if (op.reversalReason case final String reason)
                AppReviewRowData(
                  label: l10n.reversalReasonLabel,
                  value: reason,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space24),
          _horizontal(
            Text(
              l10n.detailRecordedAt(op.recordedAt.toIso8601String()),
              style: context.textRoles.supportingMeta.copyWith(
                color: colors.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          // The append-only explainer. Permanent, not conditional: it is how
          // the screen answers "where is edit" before the user goes looking.
          _horizontal(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.detailNoEditNoDeleteTitle,
                  style: context.textRoles.sectionTitle,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  l10n.detailNoEditNoDeleteBody,
                  style: context.textRoles.body.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The lineage, numbered, with "you are here" on the step being viewed.
  ///
  /// Two steps and a stated net of zero. Which step is which depends on which
  /// half the user opened, so the pair is assembled from the counterpart
  /// rather than assuming the original is always first on screen.
  List<Widget> _chain(
    BuildContext context,
    AppLocalizations l10n,
    ReversalCounterpart counterpart,
  ) {
    final op = detail.summary.operation;
    final viewingOriginal = counterpart.isReversingEntry;

    final here = _ChainStep(
      step: viewingOriginal ? '1' : '2',
      title: viewingOriginal
          ? l10n.detailChainStepOriginal('1', op.effectiveDate)
          : l10n.detailChainStepReversal('2', op.effectiveDate),
      caption: l10n.detailChainYouAreHere,
      minorUnits: op.totalAmountMinorUnits,
      currencyCode: op.currencyCode,
      direction: viewingOriginal
          ? FinancialAmountDirection.outflow
          : FinancialAmountDirection.inflow,
      operationId: null,
    );

    final other = _ChainStep(
      step: viewingOriginal ? '2' : '1',
      title: viewingOriginal
          ? l10n.detailChainStepReversal('2', counterpart.effectiveDate)
          : l10n.detailChainStepOriginal('1', counterpart.effectiveDate),
      caption: _counterpartCaption(l10n, counterpart),
      minorUnits: counterpart.totalAmountMinorUnits,
      currencyCode: counterpart.currencyCode,
      direction: viewingOriginal
          ? FinancialAmountDirection.inflow
          : FinancialAmountDirection.outflow,
      operationId: counterpart.operationId,
    );

    final steps = viewingOriginal ? [here, other] : [other, here];

    return [
      const SizedBox(height: AppTheme.space24),
      SectionHeader(title: l10n.detailChainTitle),
      for (final step in steps) step,
      // The net is stated, not implied: it is the whole claim of an
      // append-only correction.
      CurrencyAmountRow(
        label: l10n.reversalNetEffectOn(
          detail.summary.sourceAccountName ??
              detail.summary.destinationAccountName ??
              '',
        ),
        minorUnits: 0,
        currencyCode: op.currencyCode,
        isEmphasised: true,
        showDivider: false,
      ),
    ];
  }

  String? _counterpartCaption(
    AppLocalizations l10n,
    ReversalCounterpart counterpart,
  ) {
    // Only the reversing half carries a reason and an author worth naming.
    if (!counterpart.isReversingEntry) return null;
    if (counterpart.reason case final String reason) {
      return l10n.detailChainReasonBy(reason, counterpart.authorName ?? '');
    }
    return null;
  }

  Widget _horizontal(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
    child: child,
  );
}

/// One step of the reversal lineage.
class _ChainStep extends StatelessWidget {
  const _ChainStep({
    required this.step,
    required this.title,
    required this.caption,
    required this.minorUnits,
    required this.currencyCode,
    required this.direction,
    required this.operationId,
  });

  final String step;
  final String title;
  final String? caption;
  final int minorUnits;
  final String currencyCode;
  final FinancialAmountDirection direction;

  /// Null for the step being viewed; otherwise the half to open.
  final String? operationId;

  @override
  Widget build(BuildContext context) {
    return CurrencyAmountRow(
      label: title,
      caption: caption,
      minorUnits: minorUnits,
      currencyCode: currencyCode,
      tone: FinancialAmountTone.muted,
      direction: direction,
      // Null on the step being viewed, so only the other half is tappable —
      // and the component supplies the chevron and press treatment, rather
      // than this screen wrapping the row in its own InkWell.
      onTap: operationId == null
          ? null
          : () => context.push('/transactions/$operationId'),
    );
  }
}
