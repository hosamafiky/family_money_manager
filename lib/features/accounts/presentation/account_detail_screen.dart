import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Screen showing full details for a single financial account.
///
/// Shows:
/// - Account metadata (name, type, owner, currency)
/// - Current balance
/// - Protected/spendable badges
/// - Ledger history (empty state in Phase 3A)
/// - Archive button (with balance check)
/// - Edit metadata button
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accountAsync = ref.watch(
      accountDetailProvider((accountId, _householdId)),
    );
    final balanceAsync = ref.watch(
      accountBalanceProvider((accountId, _householdId)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountDetailTitle)),
      body: accountAsync.when(
        loading: () => Center(child: Text(l10n.loadingLabel)),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (account) {
          if (account == null) {
            return Center(child: Text(l10n.errorGeneric));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Account header card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accountTypeLabel(l10n, account.type),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (account.isProtected)
                            _Chip(
                              label: l10n.protectedLabel,
                              color: Colors.orange,
                            )
                          else if (account.isSpendable)
                            _Chip(
                              label: l10n.spendableLabel,
                              color: Colors.green,
                            ),
                          if (account.isArchived) ...[
                            const SizedBox(width: 8),
                            _Chip(
                              label: l10n.archivedLabel,
                              color: Colors.grey,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Balance card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountDetailBalance,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      balanceAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (_, _) => Text(l10n.errorGeneric),
                        data: (minorUnits) {
                          final currency = Currency.fromCode(
                            account.currencyCode,
                          );
                          final formatted = MoneyInputFormatter.format(
                            Money(minorUnits: minorUnits, currency: currency),
                          );
                          return Text(
                            '$formatted ${account.currencyCode}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (account.isProtected) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.orange.withAlpha(30),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(l10n.accountProtectedWarning),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // History section
              Text(
                l10n.accountDetailHistory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      l10n.accountDetailHistoryEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Transaction actions (only for active accounts)
              if (!account.isArchived) ...[
                FilledButton.icon(
                  onPressed: () => context.push(
                    '/transactions/new/income',
                    extra: accountId,
                  ),
                  icon: const Icon(Icons.arrow_downward),
                  label: Text(l10n.actionRecordIncome),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.push(
                    '/transactions/new/expense',
                    extra: accountId,
                  ),
                  icon: const Icon(Icons.arrow_upward),
                  label: Text(l10n.actionRecordExpense),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.push(
                    '/transactions/new/transfer',
                    extra: accountId,
                  ),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l10n.actionTransfer),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Archive action
              if (!account.isArchived)
                OutlinedButton.icon(
                  onPressed: () => _confirmArchive(context, ref, l10n),
                  icon: const Icon(Icons.archive_outlined),
                  label: Text(l10n.accountArchive),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountArchive),
        content: Text(l10n.accountArchiveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final useCase = ref.read(archiveAccountUseCaseProvider);
    final result = await useCase.execute(
      accountId: accountId,
      householdId: _householdId,
    );

    if (!context.mounted) return;

    switch (result) {
      case AppOk():
        ref.invalidate(accountDetailProvider((accountId, _householdId)));
        ref.invalidate(accountsProvider(_householdId));
        context.pop();
      case AppValidationFailure(:final messageKey)
          when messageKey == 'error_archive_nonzero_balance':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.accountArchiveError)));
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
