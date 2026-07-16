import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Read-only review screen for an income transaction.
/// Submits to use case on confirmation.
class IncomeReviewScreen extends ConsumerWidget {
  const IncomeReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ctx = ref.watch(stagedIncomeContextProvider);
    final submitting = ref.watch(submittingProvider);

    if (ctx == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pop();
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReviewRow(
            label: l10n.fieldDestinationAccount,
            value: ctx.destinationAccountId,
          ),
          _ReviewRow(
            label: l10n.fieldAmount,
            value: ctx.amountMinorUnits.toString(),
          ),
          _ReviewRow(label: l10n.fieldCategory, value: ctx.category.code),
          _ReviewRow(label: l10n.fieldEffectiveDate, value: ctx.effectiveDate),
          if (ctx.note != null)
            _ReviewRow(label: l10n.fieldNote, value: ctx.note!),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: submitting
                ? null
                : () => _submit(context, ref, l10n, ctx),
            child: submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    IncomeContext ctx,
  ) async {
    ref.read(submittingProvider.notifier).setSubmitting(true);
    try {
      final useCase = ref.read(recordIncomeUseCaseProvider);
      final result = await useCase.execute(ctx);

      if (!context.mounted) return;

      switch (result) {
        case AppOk():
          ref.read(incomeFormProvider.notifier).regenerateKey();
          ref.read(stagedIncomeContextProvider.notifier).set(null);
          ref.invalidate(
            transactionListProvider((_householdId, const TransactionFilter())),
          );
          context.go('/transactions');
        case AppInsufficientFunds():
          _showSnackBar(context, l10n.errorInsufficientFunds);
        case AppValidationFailure(:final messageKey):
          _showSnackBar(context, _resolveMessage(l10n, messageKey));
        case AppDuplicateConflict():
          _showSnackBar(context, l10n.errorAccountDuplicate);
        default:
          _showSnackBar(context, l10n.errorGeneric);
      }
    } finally {
      if (context.mounted) {
        ref.read(submittingProvider.notifier).setSubmitting(false);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _resolveMessage(AppLocalizations l10n, String key) {
    return switch (key) {
      'errorAccountArchived' => l10n.errorAccountArchived,
      'errorCurrencyMismatch' => l10n.errorCurrencyMismatch,
      _ => l10n.errorGeneric,
    };
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
