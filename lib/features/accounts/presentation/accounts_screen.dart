import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
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
///
/// NOTE (Phase 5B.2): Goal reserve accounts (type = goalReserve) are
/// intentionally hidden from this list. Their balance is visible in the
/// goal detail screen via [GoalProgress.reserveBalanceMinorUnits].
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
        loading: () => AppLoadingState(message: l10n.loadingLabel),
        error: (_, _) => AppErrorState(message: l10n.errorGeneric),
        data: (result) => switch (result) {
          AppOk(:final value) => _AccountsList(accounts: value),
          _ => AppErrorState(message: l10n.errorGeneric),
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

    // Goal reserve accounts are managed through the goal detail screen and
    // must not appear in the ordinary accounts list.
    final visible = accounts
        .where((a) => a.type != FinancialAccountType.goalReserve)
        .toList();

    if (visible.isEmpty) {
      return AppEmptyState(
        title: l10n.accountsEmpty,
        actionLabel: l10n.accountsAddButton,
        onAction: () => context.push('/accounts/new'),
      );
    }

    final spendable = visible.where((a) => a.isSpendable && !a.isProtected);
    final protected = visible.where((a) => a.isProtected);
    final certificates = visible.where(
      (a) => a.type == FinancialAccountType.certificate,
    );
    final other = visible.where(
      (a) =>
          !a.isSpendable &&
          !a.isProtected &&
          a.type != FinancialAccountType.certificate,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _TotalsRow(accounts: visible),
        const SizedBox(height: 16),
        if (spendable.isNotEmpty) ...[
          SectionHeader(title: l10n.accountsTotalSpendable),
          ...spendable.map((a) => _AccountCard(account: a)),
          const SizedBox(height: 8),
        ],
        if (protected.isNotEmpty) ...[
          SectionHeader(title: l10n.accountsTotalProtected),
          ...protected.map((a) => _AccountCard(account: a)),
          const SizedBox(height: 8),
        ],
        if (certificates.isNotEmpty) ...[
          SectionHeader(title: l10n.certificatesTitle),
          ...certificates.map((a) => _AccountCard(account: a)),
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
            if (account.type == FinancialAccountType.certificate)
              StatusBadge(
                label: l10n.accountRestrictionCertificate,
                foreground: context.financialColors.certificatePrincipal,
                icon: Icons.lock_outline,
              )
            else if (account.isProtected)
              StatusBadge(
                label: l10n.accountRestrictionProtected,
                foreground: context.financialColors.protectedMoney,
                icon: Icons.lock_outline,
              )
            else if (account.isSpendable)
              StatusBadge(
                label: l10n.spendableLabel,
                foreground: context.financialColors.income,
                icon: Icons.check_circle_outline,
              ),
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
        FinancialAccountType.certificate => l10n.certificatesTitle,
        _ => type.code,
      };
}
