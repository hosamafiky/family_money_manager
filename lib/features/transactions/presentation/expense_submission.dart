/// The one path an expense takes into the ledger.
///
/// Both the form's direct save and the review screen's confirm go through
/// here. A second write path would mean two places that decide what happens
/// after a duplicate conflict, and they would drift.
library;

import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/localization/app_localizations.dart';
import 'package:family_money_manager/core/localization/resolve_message_key.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What came of trying to write an expense.
sealed class ExpenseSubmission {
  const ExpenseSubmission();
}

/// The entry is in the ledger. The staged context has been cleared and the
/// money providers invalidated, so the caller only has to navigate.
final class ExpenseSaved extends ExpenseSubmission {
  const ExpenseSaved();
}

/// Nothing was written. [message] is localised and belongs on screen, next to
/// whatever caused it — never in a snackbar that dismisses itself.
final class ExpenseRejected extends ExpenseSubmission {
  const ExpenseRejected(this.message);

  final String message;
}

/// Writes [ctx] to the ledger.
///
/// The use case owns idempotency and validation; this only calls it and turns
/// its result into something a screen can render. On success it regenerates
/// the form's idempotency key, clears the staged context and invalidates the
/// money providers — all three are required for the *next* entry to be
/// correct, and forgetting one is the kind of bug that only shows up on the
/// second save.
Future<ExpenseSubmission> submitExpense({
  required WidgetRef ref,
  required AppLocalizations l10n,
  required ExpenseContext ctx,
}) async {
  final useCase = ref.read(recordExpenseUseCaseProvider);
  final result = await useCase.execute(ctx);

  return switch (result) {
    AppOk() => () {
      ref.read(expenseFormKeyProvider.notifier).regenerateKey();
      ref.read(stagedExpenseContextProvider.notifier).set(null);
      invalidateTransactionMoneyProviders(ref);
      return const ExpenseSaved();
    }(),
    AppInsufficientFunds() => ExpenseRejected(l10n.errorInsufficientFunds),
    AppValidationFailure(:final messageKey) => ExpenseRejected(
      resolveMessageKey(l10n, messageKey),
    ),
    AppDuplicateConflict() => ExpenseRejected(l10n.errorAccountDuplicate),
    _ => ExpenseRejected(l10n.errorGeneric),
  };
}
