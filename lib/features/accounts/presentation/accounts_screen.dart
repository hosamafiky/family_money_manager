import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Phase 3A limitation: a single household ID is used throughout.
const _householdId = 'household-v1';

/// Screen that lists all non-archived financial accounts for the household.
///
/// Shows:
/// - Derived spendable and protected totals
/// - Account cards with balance, and badge (spendable/protected)
/// - Empty state and error state
/// - FAB to create a new account
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountsProvider(_householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountsTitle), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_accounts',
        onPressed: () => context.push('/accounts/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.accountsAddButton),
      ),
      body: accountsAsync.when(
        loading: () => Center(child: Text(l10n.loadingLabel)),
        error: (_, _) => _ErrorBody(message: l10n.errorGeneric),
        data: (result) => switch (result) {
          AppOk(:final value) => _AccountsList(accounts: value),
          _ => _ErrorBody(message: l10n.errorGeneric),
        },
      ),
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList({required this.accounts});

  final List<FinancialAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (accounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.accountsEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final spendable = accounts.where((a) => a.isSpendable && !a.isProtected);
    final protected = accounts.where((a) => a.isProtected);
    final other = accounts.where((a) => !a.isSpendable && !a.isProtected);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _TotalsRow(accounts: accounts),
        const SizedBox(height: 16),
        if (spendable.isNotEmpty) ...[
          _SectionHeader(label: l10n.accountsTotalSpendable),
          ...spendable.map((a) => _AccountCard(account: a)),
          const SizedBox(height: 8),
        ],
        if (protected.isNotEmpty) ...[
          _SectionHeader(label: l10n.accountsTotalProtected),
          ...protected.map((a) => _AccountCard(account: a)),
          const SizedBox(height: 8),
        ],
        ...other.map((a) => _AccountCard(account: a)),
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.accounts});

  final List<FinancialAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spendableCount = accounts.where((a) => a.isSpendable).length;
    final protectedCount = accounts.where((a) => a.isProtected).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountsTotalSpendable,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$spendableCount',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountsTotalProtected,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$protectedCount',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account});

  final FinancialAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final balanceAsync = ref.watch(
      accountBalanceProvider((account.id, account.householdId)),
    );
    final typeLabel = _typeLabel(account.type, l10n);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/accounts/${account.id}'),
        title: Text(account.name),
        subtitle: Text(typeLabel),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            balanceAsync.when(
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (minorUnits) {
                final currency = Currency.fromCode(account.currencyCode);
                final formatted = MoneyInputFormatter.format(
                  Money(minorUnits: minorUnits, currency: currency),
                );
                return Text(
                  '$formatted ${account.currencyCode}',
                  style: Theme.of(context).textTheme.titleSmall,
                );
              },
            ),
            const SizedBox(height: 2),
            if (account.isProtected)
              _Badge(label: l10n.protectedLabel, color: Colors.orange)
            else if (account.isSpendable)
              _Badge(label: l10n.spendableLabel, color: Colors.green),
          ],
        ),
      ),
    );
  }

  static String _typeLabel(FinancialAccountType type, AppLocalizations l10n) =>
      switch (type) {
        FinancialAccountType.personalCashWallet => l10n.accountTypePersonalCash,
        FinancialAccountType.spouseCashWallet => l10n.accountTypeSpouseCash,
        FinancialAccountType.householdCash => l10n.accountTypeHouseholdCash,
        FinancialAccountType.homeSavingsCash => l10n.accountTypeHomeSavings,
        FinancialAccountType.bankAccount => l10n.accountTypeBankAccount,
        FinancialAccountType.mobileWallet => l10n.accountTypeMobileWallet,
        FinancialAccountType.childProtectedFund => l10n.accountTypeChildFund,
        _ => type.code,
      };
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
