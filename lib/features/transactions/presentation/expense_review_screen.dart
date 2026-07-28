import 'package:family_money_manager/app/app_theme.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/core/financial/money.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/enum_label_helpers.dart';
import 'package:family_money_manager/core/presentation/components/components.dart';
import 'package:family_money_manager/core/presentation/money_input_formatter.dart';
import 'package:family_money_manager/core/presentation/theme/app_theme_extensions.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/household/domain/household_member.dart';
import 'package:family_money_manager/features/household/presentation/providers/household_providers.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/presentation/category_label_helper.dart';
import 'package:family_money_manager/features/transactions/presentation/expense_submission.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _householdId = 'household-v1';

/// Read-only review screen for an expense transaction.
class ExpenseReviewScreen extends ConsumerStatefulWidget {
  const ExpenseReviewScreen({super.key});

  @override
  ConsumerState<ExpenseReviewScreen> createState() =>
      _ExpenseReviewScreenState();
}

class _ExpenseReviewScreenState extends ConsumerState<ExpenseReviewScreen> {
  /// The last write failure, kept on screen until the user acts on it.
  ///
  /// A failed ledger write is not a passing notification: it is a question the
  /// user has to answer, and a snackbar that dismisses itself takes the
  /// question away before they can read it.
  String? _failure;

  @override
  Widget build(BuildContext context) {
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
      data: (r) =>
          r is AppOk<List<FinancialAccount>> ? r.value : <FinancialAccount>[],
      orElse: () => <FinancialAccount>[],
    );
    final members = membersAsync.maybeWhen(
      data: (r) =>
          r is AppOk<List<HouseholdMember>> ? r.value : <HouseholdMember>[],
      orElse: () => <HouseholdMember>[],
    );

    String accountName(String id) =>
        accounts.where((a) => a.id == id).firstOrNull?.name ?? id;
    String memberName(String id) =>
        members.where((m) => m.id == id).firstOrNull?.displayName ?? id;

    String formatAmount(int minor, String code) {
      final currency = Currency.fromCode(code);
      final money = Money(minorUnits: minor, currency: currency);
      return '${MoneyInputFormatter.format(money)} $code';
    }

    String scopeLabel(ExpenseScope scope) => expenseScopeLabel(l10n, scope);

    return AppScreenScaffold(
      title: Text(l10n.reviewTitle),
      bottomBar: AppBottomActionBar(
        // Permanent, not conditional: it is how the app teaches append-only
        // before the user discovers it by trying to delete something.
        consequenceLabel: l10n.reviewAppendOnlyConsequence,
        child: PrimaryActionButton(
          label: l10n.confirm,
          isLoading: submitting,
          onPressed: submitting ? null : () => _submit(context, ref, l10n, ctx),
        ),
      ),
      body: ResponsiveContentContainer(
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            top: AppTheme.space16,
            bottom: AppTheme.space32,
          ),
          children: [
            if (_failure case final String failure) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                ),
                child: AppInlineNotice(
                  message: failure,
                  tone: AppNoticeTone.error,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
            ],
            AppInlineNotice(
              message: l10n.expenseDecreasesBalance,
              tone: AppNoticeTone.info,
            ),
            if (ctx.childWithdrawalAudit != null) ...[
              const SizedBox(height: AppTheme.space12),
              AppInlineNotice(
                message: l10n.protectedWithdrawalReviewNote,
                tone: AppNoticeTone.warning,
              ),
            ],
            const SizedBox(height: AppTheme.space16),
            // The read-back is the check. One sentence catches "wrong account"
            // and "wrong spender" faster than six labelled rows, because it is
            // read the way the user would say it.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: Text(
                l10n.expenseReadBack(
                  formatAmount(ctx.amountMinorUnits, ctx.currencyCode),
                  categoryLabel(l10n, ctx.category),
                  accountName(ctx.paymentAccountId),
                  memberName(ctx.spenderMemberId),
                  scopeLabel(ctx.scope),
                ),
                style: context.textRoles.body,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            // The double entry, for the user who wants to see it. Debit and
            // credit are stated as such rather than implied by a sign.
            SectionHeader(title: l10n.reviewLedgerEffect),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: Column(
                children: [
                  CurrencyAmountRow(
                    label: l10n.reviewDebitLabel(
                      categoryLabel(l10n, ctx.category),
                    ),
                    minorUnits: ctx.amountMinorUnits,
                    currencyCode: ctx.currencyCode,
                    tone: FinancialAmountTone.expense,
                    direction: FinancialAmountDirection.outflow,
                  ),
                  CurrencyAmountRow(
                    label: l10n.reviewCreditLabel(
                      accountName(ctx.paymentAccountId),
                    ),
                    minorUnits: ctx.amountMinorUnits,
                    currencyCode: ctx.currencyCode,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            AppReviewSection(
              title: l10n.reviewTitle,
              rows: [
                AppReviewRowData(
                  label: l10n.fieldBeneficiary,
                  value: memberName(ctx.beneficiaryMemberId),
                ),
                AppReviewRowData(
                  label: l10n.fieldRecurring,
                  value: ctx.isRecurring
                      ? l10n.recurringYes
                      : l10n.recurringOneTime,
                ),
                AppReviewRowData(
                  label: l10n.fieldEffectiveDate,
                  value: ctx.effectiveDate,
                ),
                if (ctx.note != null)
                  AppReviewRowData(label: l10n.fieldNote, value: ctx.note!),
                if (ctx.childWithdrawalAudit != null)
                  AppReviewRowData(
                    label: l10n.fieldWithdrawalReason,
                    value: ctx.childWithdrawalAudit!.reason,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ExpenseContext ctx,
  ) async {
    setState(() => _failure = null);
    ref.read(submittingProvider.notifier).setSubmitting(true);
    try {
      final outcome = await submitExpense(ref: ref, l10n: l10n, ctx: ctx);
      if (!context.mounted) return;
      switch (outcome) {
        case ExpenseSaved():
          context.go('/transactions');
        case ExpenseRejected(:final message):
          _fail(message);
      }
    } finally {
      if (context.mounted) {
        ref.read(submittingProvider.notifier).setSubmitting(false);
      }
    }
  }

  void _fail(String message) {
    if (mounted) setState(() => _failure = message);
  }
}
