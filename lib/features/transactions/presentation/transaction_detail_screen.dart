import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _householdId = 'household-v1';

/// Shows full detail for a single operation with context metadata.
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.operationId, super.key});

  final String operationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(transactionDetailProvider((operationId, _householdId)));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionDetailTitle)),
      body: detailAsync.when(
        loading: () => Center(child: Text(l10n.loadingLabel)),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (summary) {
          if (summary == null) {
            return Center(child: Text(l10n.errorGeneric));
          }
          return _DetailBody(summary: summary);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.summary});

  final TransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final op = summary.operation;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(operationTypeLabel(l10n, op.type), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (op.isReversed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.withAlpha(40), borderRadius: BorderRadius.circular(4)),
                        child: Text(l10n.transactionReversed, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${op.totalAmountMinorUnits} ${op.currencyCode}', style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _infoTile(context, l10n.fieldEffectiveDate, op.effectiveDate),
        if (summary.categoryCode != null) _infoTile(context, l10n.fieldCategory, categoryLabelFromCode(l10n, summary.categoryCode!)),
        if (op.sourceAccountId != null) _infoTile(context, l10n.fieldSourceAccount, op.sourceAccountId!),
        if (op.destinationAccountId != null) _infoTile(context, l10n.fieldDestinationAccount, op.destinationAccountId!),
        if (summary.spenderMemberId != null) _infoTile(context, l10n.fieldSpender, summary.spenderMemberId!),
        if (summary.beneficiaryMemberId != null) _infoTile(context, l10n.fieldBeneficiary, summary.beneficiaryMemberId!),
        if (summary.scope != null) _infoTile(context, l10n.fieldScope, expenseScopeLabel(l10n, summary.scope!)),
        _infoTile(context, l10n.fieldRecurring, summary.isRecurring ? l10n.recurringYes : l10n.recurringOneTime),
        if (summary.note != null) _infoTile(context, l10n.fieldNote, summary.note!),
      ],
    );
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
