import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Main transactions screen showing recent operation history.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    const filter = TransactionFilter();
    final transactionsAsync = ref.watch(
      transactionListProvider((_householdId, filter)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionsTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        onPressed: () => context.push('/transactions/new'),
        child: const Icon(Icons.add),
      ),
      body: transactionsAsync.when(
        loading: () => Center(child: Text(l10n.loadingLabel)),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (result) {
          return switch (result) {
            AppOk(:final value) =>
              value.isEmpty
                  ? Center(child: Text(l10n.transactionsEmpty))
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(
                          transactionListProvider((_householdId, filter)),
                        );
                      },
                      child: ListView.separated(
                        itemCount: value.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) =>
                            _TransactionTile(summary: value[i]),
                      ),
                    ),
            _ => Center(child: Text(l10n.errorGeneric)),
          };
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.summary});

  final TransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final op = summary.operation;
    final typeLabel = _typeLabel(l10n, op.type);
    final isCredit =
        op.type == OperationType.income ||
        op.type == OperationType.openingBalance;
    final amountColor = isCredit ? Colors.green : null;

    return ListTile(
      onTap: () => context.push('/transactions/${op.id}'),
      leading: CircleAvatar(
        backgroundColor: _typeColor(op.type).withAlpha(30),
        child: Icon(_typeIcon(op.type), color: _typeColor(op.type), size: 18),
      ),
      title: Row(
        children: [
          Expanded(child: Text(typeLabel)),
          if (op.isReversed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.transactionReversed,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey),
              ),
            ),
        ],
      ),
      subtitle: Text(op.effectiveDate),
      trailing: Text(
        '${isCredit ? '+' : '-'}${op.totalAmountMinorUnits}',
        style: TextStyle(color: amountColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _typeLabel(AppLocalizations l10n, OperationType type) {
    return switch (type) {
      OperationType.income => l10n.transactionTypeIncome,
      OperationType.expense => l10n.transactionTypeExpense,
      OperationType.transfer => l10n.transactionTypeTransfer,
      OperationType.openingBalance => l10n.transactionTypeOpeningBalance,
      OperationType.adjustment => l10n.transactionTypeAdjustment,
      OperationType.reversal => l10n.transactionTypeReversal,
      _ => type.code,
    };
  }

  IconData _typeIcon(OperationType type) {
    return switch (type) {
      OperationType.income => Icons.arrow_downward,
      OperationType.expense => Icons.arrow_upward,
      OperationType.transfer => Icons.swap_horiz,
      OperationType.openingBalance => Icons.account_balance,
      OperationType.adjustment => Icons.tune,
      OperationType.reversal => Icons.undo,
      _ => Icons.receipt_long_outlined,
    };
  }

  Color _typeColor(OperationType type) {
    return switch (type) {
      OperationType.income => Colors.green,
      OperationType.expense => Colors.red,
      OperationType.transfer => Colors.blue,
      OperationType.openingBalance => Colors.teal,
      OperationType.adjustment => Colors.orange,
      OperationType.reversal => Colors.grey,
      _ => Colors.blueGrey,
    };
  }
}
