import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
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
        loading: () => AppLoadingState(message: l10n.loadingLabel),
        error: (_, _) => AppErrorState(message: l10n.errorGeneric),
        data: (result) {
          return switch (result) {
            AppOk(:final value) =>
              value.isEmpty
                  ? AppEmptyState(
                      title: l10n.transactionsEmpty,
                      actionLabel: l10n.actionRecordExpense,
                      onAction: () => context.push('/transactions/new'),
                    )
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
            _ => AppErrorState(message: l10n.errorGeneric),
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
    final kind = _typeKind(op.type);
    final isCredit =
        op.type == OperationType.income ||
        op.type == OperationType.openingBalance;
    final sign = isCredit ? '+' : '−';
    final formatted = '$sign${op.totalAmountMinorUnits} ${op.currencyCode}';
    final accountOrDirection = switch (op.type) {
      OperationType.transfer =>
        '${op.sourceAccountId ?? '—'} → ${op.destinationAccountId ?? '—'}',
      OperationType.income || OperationType.openingBalance =>
        op.destinationAccountId ?? op.currencyCode,
      _ => op.sourceAccountId ?? op.currencyCode,
    };

    return TransactionListTile(
      typeLabel: _typeLabel(l10n, op.type),
      typeKind: kind,
      primaryDescription: op.description?.trim().isNotEmpty == true
          ? op.description!
          : (summary.note?.trim().isNotEmpty == true
                ? summary.note!
                : _typeLabel(l10n, op.type)),
      accountOrDirection: accountOrDirection,
      effectiveDate: op.effectiveDate,
      formattedAmount: formatted,
      memberOrCategory: summary.categoryCode,
      isReversed: op.isReversed,
      reversedLabel: op.isReversed ? l10n.transactionReversed : null,
      onTap: () => context.push('/transactions/${op.id}'),
    );
  }

  FinancialTypeKind _typeKind(OperationType type) {
    return switch (type) {
      OperationType.income => FinancialTypeKind.income,
      OperationType.expense => FinancialTypeKind.expense,
      OperationType.transfer => FinancialTypeKind.transfer,
      OperationType.reversal => FinancialTypeKind.reversal,
      OperationType.adjustment => FinancialTypeKind.adjustment,
      _ => FinancialTypeKind.other,
    };
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
}
