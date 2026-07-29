/// The append-only correction.
///
/// The one screen in the product where the UI has to teach the data model
/// rather than hide it: there is no edit and no delete, so a mistake is fixed
/// by adding an opposing entry that points at the original, and both stay
/// visible forever. The screen therefore shows what will be *added* — before,
/// after, and the net — instead of asking "are you sure".
library;

import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/localization/resolve_message_key.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/transactions/application/reverse_transaction_use_case.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// A reversal reason offered as a chip.
///
/// Four real ones rather than a bare required field: an empty free-text box
/// produces "mistake" on every entry, and four taps-to-fill options produce
/// reasons an auditor can actually use. Selecting one fills the field, which
/// stays editable — the presets are a starting point, not a closed list.
enum ReversalReasonPreset {
  duplicate,
  wrongAmount,
  wrongAccount,
  cancelledPurchase,
}

String reversalReasonPresetLabel(
  AppLocalizations l10n,
  ReversalReasonPreset preset,
) => switch (preset) {
  ReversalReasonPreset.duplicate => l10n.reversalReasonPresetDuplicate,
  ReversalReasonPreset.wrongAmount => l10n.reversalReasonPresetWrongAmount,
  ReversalReasonPreset.wrongAccount => l10n.reversalReasonPresetWrongAccount,
  ReversalReasonPreset.cancelledPurchase =>
    l10n.reversalReasonPresetCancelledPurchase,
};

/// Records a reversal of [operationId], with a required reason.
class ReverseTransactionScreen extends ConsumerStatefulWidget {
  const ReverseTransactionScreen({required this.operationId, super.key});

  final String operationId;

  @override
  ConsumerState<ReverseTransactionScreen> createState() =>
      _ReverseTransactionScreenState();
}

class _ReverseTransactionScreenState
    extends ConsumerState<ReverseTransactionScreen> {
  final _reasonController = TextEditingController();

  /// The last write failure, kept on screen until the user acts on it.
  String? _failure;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(
      transactionDetailProvider((widget.operationId, _householdId)),
    );

    return AppScreenScaffold(
      title: Text(l10n.reversalSheetTitle),
      body: detailAsync.when(
        loading: () => AppLoadingState(message: l10n.loadingLabel),
        error: (_, _) => AppErrorState(message: l10n.errorGeneric),
        data: (summary) {
          if (summary == null) return AppErrorState(message: l10n.errorGeneric);
          return _Body(
            summary: summary,
            reasonController: _reasonController,
            failure: _failure,
          );
        },
      ),
      bottomBar: detailAsync.maybeWhen(
        data: (summary) {
          if (summary == null) return null;
          // An operation is reversed once. Rather than hiding the action and
          // leaving the absence mysterious, the slot says why it is gone.
          if (summary.operation.isReversed) {
            return AppBottomActionBar(
              child: AppInlineNotice(
                message: l10n.detailAlreadyReversedNoAction,
                tone: AppNoticeTone.info,
              ),
            );
          }
          return AppBottomActionBar(
            consequenceLabel: l10n.reversalNoDeleteNote,
            child: DestructiveActionButton(
              label: l10n.reversalConfirmAction,
              onPressed: _submitting ? null : () => _submit(l10n, summary),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Future<void> _submit(
    AppLocalizations l10n,
    TransactionSummary summary,
  ) async {
    final reason = _reasonController.text.trim();
    // Checked here as well as in the use case so the empty case never costs a
    // round trip; the use case remains the authority.
    if (reason.isEmpty) {
      setState(() => _failure = l10n.errorReversalReasonRequired);
      return;
    }

    setState(() {
      _submitting = true;
      _failure = null;
    });
    try {
      final result = await ref
          .read(reverseTransactionUseCaseProvider)
          .execute(
            reversalOperationId: ref.read(reversalKeyProvider),
            originalOperationId: summary.operation.id,
            householdId: _householdId,
            effectiveDate: _todayIsoDate(),
            createdBy: summary.operation.createdBy,
            reason: reason,
          );

      if (!mounted) return;

      switch (result) {
        case AppOk():
          ref.read(reversalKeyProvider.notifier).regenerateKey();
          invalidateTransactionMoneyProviders(ref);
          ref.invalidate(
            transactionDetailProvider((widget.operationId, _householdId)),
          );
          // Back to the list, where the counter-entry appears above the
          // original and both stay visible.
          context.go('/transactions');
        case AppInsufficientFunds():
          setState(() => _failure = l10n.errorInsufficientFunds);
        case AppValidationFailure(:final messageKey):
          setState(() => _failure = resolveMessageKey(l10n, messageKey));
        case AppDuplicateConflict(:final messageKey):
          setState(() => _failure = resolveMessageKey(l10n, messageKey));
        case AppResult<String>():
          setState(() => _failure = l10n.errorGeneric);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// The reversal is recorded as happening today, never backdated to the
  /// original's date: the correction is a new event in the ledger's history.
  String _todayIsoDate() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    required this.summary,
    required this.reasonController,
    required this.failure,
  });

  final TransactionSummary summary;
  final TextEditingController reasonController;
  final String? failure;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  ReversalReasonPreset? _selectedPreset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final op = widget.summary.operation;
    final accountsAsync = ref.watch(accountsProvider(_householdId));
    final accounts = accountsAsync.maybeWhen(
      data: (r) =>
          r is AppOk<List<FinancialAccount>> ? r.value : <FinancialAccount>[],
      orElse: () => <FinancialAccount>[],
    );

    String accountName(String id) =>
        accounts.where((a) => a.id == id).firstOrNull?.name ?? id;

    // The account the money actually left or entered — the one whose balance
    // the user is about to see return to where it was.
    final affectedAccountId = op.sourceAccountId ?? op.destinationAccountId;

    final originalLabel = widget.summary.categoryCode != null
        ? categoryLabelFromCode(l10n, widget.summary.categoryCode!)
        : operationTypeLabel(l10n, op.type);

    final (originalDirection, counterDirection) = switch (op.type) {
      OperationType.income => (
        FinancialAmountDirection.inflow,
        FinancialAmountDirection.outflow,
      ),
      OperationType.transfer => (
        FinancialAmountDirection.internal,
        FinancialAmountDirection.internal,
      ),
      _ => (FinancialAmountDirection.outflow, FinancialAmountDirection.inflow),
    };

    return ResponsiveContentContainer(
      child: ListView(
        padding: const EdgeInsetsDirectional.only(
          top: AppTheme.space16,
          bottom: AppTheme.space32,
        ),
        children: [
          if (widget.failure case final String failure) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: AppInlineNotice(
                message: failure,
                tone: AppNoticeTone.error,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: Text(l10n.reversalSheetIntro, style: context.textRoles.body),
          ),
          const SizedBox(height: AppTheme.space24),
          SectionHeader(title: l10n.reversalBeforeAfterTitle),
          CurrencyAmountRow(
            label: originalLabel,
            caption: l10n.reversalOriginalStaysLabel,
            minorUnits: op.totalAmountMinorUnits,
            currencyCode: op.currencyCode,
            tone: FinancialAmountTone.muted,
            direction: originalDirection,
          ),
          CurrencyAmountRow(
            label: l10n.reversalCounterEntryLabel,
            caption: l10n.reversalCounterEntryReference,
            minorUnits: op.totalAmountMinorUnits,
            currencyCode: op.currencyCode,
            tone: FinancialAmountTone.muted,
            direction: counterDirection,
          ),
          // Stated, not implied. The whole claim of an append-only correction
          // is that the pair nets to zero, so the zero is on screen.
          CurrencyAmountRow(
            label: l10n.reversalNetEffectOn(
              affectedAccountId == null ? '' : accountName(affectedAccountId),
            ),
            minorUnits: 0,
            currencyCode: op.currencyCode,
            isEmphasised: true,
            showDivider: false,
          ),
          const SizedBox(height: AppTheme.space24),
          AppFormSection(
            title: l10n.reversalReasonLabel,
            subtitle: l10n.reversalReasonPermanenceNote,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilterChipGroup<ReversalReasonPreset>(
                  options: ReversalReasonPreset.values,
                  selected: {?_selectedPreset},
                  labelOf: (preset) => reversalReasonPresetLabel(l10n, preset),
                  onChanged: (selection) {
                    final preset = selection.firstOrNull;
                    if (preset == null) return;
                    setState(() => _selectedPreset = preset);
                    widget.reasonController.text = reversalReasonPresetLabel(
                      l10n,
                      preset,
                    );
                  },
                ),
                const SizedBox(height: AppTheme.space12),
                TextField(
                  controller: widget.reasonController,
                  maxLength: maxReversalReasonLength,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.reversalReasonLabel,
                  ),
                  // Typing over a preset detaches the chip: the field is the
                  // source of truth, the chip only seeded it.
                  onChanged: (value) {
                    final preset = _selectedPreset;
                    if (preset == null) return;
                    if (value != reversalReasonPresetLabel(l10n, preset)) {
                      setState(() => _selectedPreset = null);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
