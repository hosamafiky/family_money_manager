import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:family_money_manager/features/household/presentation/providers/household_providers.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Read-only review screen for an expense transaction.
class ExpenseReviewScreen extends ConsumerWidget {
  const ExpenseReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ctx = ref.watch(stagedExpenseContextProvider);
    final submitting = ref.watch(submittingProvider);
    final accountsAsync = ref.watch(accountsProvider(_householdId));
    final membersAsync = ref.watch(householdMembersProvider(_householdId));

    if (ctx == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && context.canPop()) context.pop();
      });
      return const SizedBox.shrink();
    }

    final accounts = accountsAsync.maybeWhen(
      data: (r) => r is AppOk<List<FinancialAccount>> ? r.value : <FinancialAccount>[],
      orElse: () => <FinancialAccount>[],
    );
    final members = membersAsync.maybeWhen(
      data: (r) => r is AppOk<List<HouseholdMember>> ? r.value : <HouseholdMember>[],
      orElse: () => <HouseholdMember>[],
    );

    String accountName(String id) => accounts.where((a) => a.id == id).firstOrNull?.name ?? id;
    String memberName(String id) => members.where((m) => m.id == id).firstOrNull?.displayName ?? id;

    String formatAmount(int minor, String code) {
      final currency = Currency.fromCode(code);
      final money = Money(minorUnits: minor, currency: currency);
      return '${MoneyInputFormatter.format(money)} $code';
    }

    String scopeLabel(ExpenseScope scope) => switch (scope) {
      ExpenseScope.personal => l10n.scopePersonal,
      ExpenseScope.spouse => l10n.scopeSpouse,
      ExpenseScope.household => l10n.scopeHousehold,
      ExpenseScope.child => l10n.scopeChild,
      ExpenseScope.shared => l10n.scopeHousehold,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Row(l10n.fieldPaymentAccount, accountName(ctx.paymentAccountId)),
          _Row(l10n.fieldAmount, formatAmount(ctx.amountMinorUnits, ctx.currencyCode)),
          _Row(l10n.fieldCategory, categoryLabel(l10n, ctx.category)),
          _Row(l10n.fieldSpender, memberName(ctx.spenderMemberId)),
          _Row(l10n.fieldBeneficiary, memberName(ctx.beneficiaryMemberId)),
          _Row(l10n.fieldScope, scopeLabel(ctx.scope)),
          _Row(l10n.fieldRecurring, ctx.isRecurring ? l10n.recurringYes : l10n.recurringOneTime),
          _Row(l10n.fieldEffectiveDate, ctx.effectiveDate),
          if (ctx.note != null) _Row(l10n.fieldNote, ctx.note!),
          if (ctx.childWithdrawalAudit != null)
            _Row(l10n.fieldWithdrawalReason, ctx.childWithdrawalAudit!.reason),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: submitting ? null : () => _submit(context, ref, l10n, ctx),
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
    ExpenseContext ctx,
  ) async {
    ref.read(submittingProvider.notifier).setSubmitting(true);
    try {
      final useCase = ref.read(recordExpenseUseCaseProvider);
      final result = await useCase.execute(ctx);

      if (!context.mounted) return;

      switch (result) {
        case AppOk():
          ref.read(expenseFormKeyProvider.notifier).regenerateKey();
          ref.read(stagedExpenseContextProvider.notifier).set(null);
          ref.invalidate(transactionListProvider((_householdId, const TransactionFilter())));
          ref.invalidate(accountsProvider(_householdId));
          ref.invalidate(accountBalanceProvider);
          ref.invalidate(dashboardSummaryProvider(_householdId));
          context.go('/transactions');
        case AppInsufficientFunds():
          _snack(context, l10n.errorInsufficientFunds);
        case AppValidationFailure(:final messageKey):
          _snack(context, _msg(l10n, messageKey));
        case AppDuplicateConflict():
          _snack(context, l10n.errorAccountDuplicate);
        default:
          _snack(context, l10n.errorGeneric);
      }
    } finally {
      if (context.mounted) {
        ref.read(submittingProvider.notifier).setSubmitting(false);
      }
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _msg(AppLocalizations l10n, String key) => switch (key) {
    'errorInsufficientFunds' => l10n.errorInsufficientFunds,
    'errorAccountArchived' => l10n.errorAccountArchived,
    'errorCurrencyMismatch' => l10n.errorCurrencyMismatch,
    'errorWithdrawalReasonRequired' => l10n.errorWithdrawalReasonRequired,
    'errorWithdrawalAcknowledgmentRequired' => l10n.errorWithdrawalAcknowledgmentRequired,
    'errorWithdrawalConfirmationRequired' => l10n.errorWithdrawalConfirmationRequired,
    _ => l10n.errorGeneric,
  };
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
