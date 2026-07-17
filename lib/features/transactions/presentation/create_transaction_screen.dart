import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Type-selector screen. Lets the user choose between income, expense, transfer.
class CreateTransactionScreen extends StatelessWidget {
  const CreateTransactionScreen({
    this.preselectedAccountId,
    this.preselectedType,
    super.key,
  });

  /// If navigated from an account detail screen, pre-select the account.
  final String? preselectedAccountId;

  /// One of 'income', 'expense', 'transfer' – pre-navigates when provided.
  final String? preselectedType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createTransactionTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TypeCard(
            icon: Icons.arrow_downward,
            color: Colors.green,
            title: l10n.createIncomeTitle,
            subtitle: l10n.transactionTypeIncome,
            onTap: () => context.push(
              '/transactions/new/income',
              extra: preselectedAccountId,
            ),
          ),
          const SizedBox(height: 12),
          _TypeCard(
            icon: Icons.arrow_upward,
            color: Colors.red,
            title: l10n.createExpenseTitle,
            subtitle: l10n.transactionTypeExpense,
            onTap: () => context.push(
              '/transactions/new/expense',
              extra: preselectedAccountId,
            ),
          ),
          const SizedBox(height: 12),
          _TypeCard(
            icon: Icons.swap_horiz,
            color: Colors.blue,
            title: l10n.createTransferTitle,
            subtitle: l10n.transactionTypeTransfer,
            onTap: () => context.push(
              '/transactions/new/transfer',
              extra: preselectedAccountId,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
