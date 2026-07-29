import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';

import 'package:family_money_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:family_money_manager/features/household/presentation/providers/household_providers.dart';
import 'package:family_money_manager/features/transactions/application/execute_transfer_use_case.dart';
import 'package:family_money_manager/features/transactions/application/get_spouse_wallet_summary_use_case.dart';
import 'package:family_money_manager/features/transactions/application/get_transaction_history_use_case.dart';
import 'package:family_money_manager/features/transactions/application/record_expense_use_case.dart';
import 'package:family_money_manager/features/transactions/application/record_income_use_case.dart';
import 'package:family_money_manager/features/transactions/application/reverse_transaction_use_case.dart';
import 'package:family_money_manager/features/transactions/data/drift_transaction_query_repository.dart';
import 'package:family_money_manager/features/transactions/data/transaction_query_repository.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_detail.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const _txHouseholdId = 'household-v1';

/// Invalidates transaction list + account/dashboard consumers after money writes.
void invalidateTransactionMoneyProviders(WidgetRef ref) {
  ref.invalidate(
    transactionListProvider((_txHouseholdId, const TransactionFilter())),
  );
  ref.invalidate(accountsProvider(_txHouseholdId));
  ref.invalidate(accountBalanceProvider);
  ref.invalidate(dashboardSummaryProvider(_txHouseholdId));
}

// ── Repository provider ───────────────────────────────────────────────────────

final transactionQueryRepositoryProvider = Provider<TransactionQueryRepository>(
  (ref) {
    return DriftTransactionQueryRepository(ref.watch(appDatabaseProvider));
  },
);

// ── Use-case providers ────────────────────────────────────────────────────────

final recordIncomeUseCaseProvider = Provider<RecordIncomeUseCase>((ref) {
  return RecordIncomeUseCase(
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
  );
});

final recordExpenseUseCaseProvider = Provider<RecordExpenseUseCase>((ref) {
  return RecordExpenseUseCase(
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    householdRepository: ref.watch(householdRepositoryProvider),
  );
});

final executeTransferUseCaseProvider = Provider<ExecuteTransferUseCase>((ref) {
  return ExecuteTransferUseCase(
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
  );
});

final reverseTransactionUseCaseProvider = Provider<ReverseTransactionUseCase>((
  ref,
) {
  return ReverseTransactionUseCase(
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
  );
});

final getTransactionHistoryUseCaseProvider =
    Provider<GetTransactionHistoryUseCase>((ref) {
      return GetTransactionHistoryUseCase(
        ref.watch(transactionQueryRepositoryProvider),
      );
    });

final getSpouseWalletSummaryUseCaseProvider =
    Provider<GetSpouseWalletSummaryUseCase>((ref) {
      return GetSpouseWalletSummaryUseCase(
        ref.watch(transactionQueryRepositoryProvider),
      );
    });

// ── Transaction list provider ─────────────────────────────────────────────────

final transactionListProvider =
    FutureProvider.family<
      AppResult<List<TransactionSummary>>,
      (String, TransactionFilter)
    >((ref, args) {
      final (householdId, filter) = args;
      final useCase = ref.watch(getTransactionHistoryUseCaseProvider);
      return useCase.execute(householdId: householdId, filter: filter);
    });

/// How many operations a filter matches, ignoring its page size.
///
/// Watched by the filter sheet so its confirm button can carry the count.
final transactionCountProvider =
    FutureProvider.family<int, (String, TransactionFilter)>((ref, args) {
      final (householdId, filter) = args;
      return ref
          .watch(transactionQueryRepositoryProvider)
          .countOperations(householdId: householdId, filter: filter);
    });

// ── Transaction detail provider ───────────────────────────────────────────────

final transactionDetailProvider =
    FutureProvider.family<TransactionSummary?, (String, String)>((ref, args) {
      final (operationId, householdId) = args;
      final repo = ref.watch(transactionQueryRepositoryProvider);
      return repo.operationDetail(
        operationId: operationId,
        householdId: householdId,
      );
    });

/// The detail screen's read: the operation, its ledger lines, resolved names,
/// and the other half of its reversal pair.
///
/// Kept separate from [transactionDetailProvider] so list callers, which only
/// need the summary, do not pay for the extra joins.
final transactionDetailWithLedgerProvider =
    FutureProvider.family<TransactionDetail?, (String, String)>((ref, args) {
      final (operationId, householdId) = args;
      final repo = ref.watch(transactionQueryRepositoryProvider);
      return repo.operationDetailWithLedger(
        operationId: operationId,
        householdId: householdId,
      );
    });

// ── Spouse wallet summary provider ────────────────────────────────────────────

typedef SpouseWalletArgs = ({
  String spouseAccountId,
  String householdId,
  String fromDate,
  String toDate,
});

final spouseWalletSummaryProvider =
    FutureProvider.family<AppResult<SpouseWalletSummary>, SpouseWalletArgs>((
      ref,
      args,
    ) {
      final useCase = ref.watch(getSpouseWalletSummaryUseCaseProvider);
      return useCase.execute(
        spouseAccountId: args.spouseAccountId,
        householdId: args.householdId,
        fromDate: args.fromDate,
        toDate: args.toDate,
      );
    });

// ── Form state notifiers (Riverpod 3 Notifier pattern) ───────────────────────

/// Manages idempotency key for the income form.
/// Key is stable during submission; regenerated only after success.
class IncomeFormNotifier extends Notifier<IncomeFormState> {
  @override
  IncomeFormState build() => IncomeFormState(idempotencyKey: const Uuid().v4());

  void regenerateKey() {
    state = IncomeFormState(idempotencyKey: const Uuid().v4());
  }
}

class IncomeFormState {
  const IncomeFormState({required this.idempotencyKey});

  final String idempotencyKey;
}

final incomeFormProvider =
    NotifierProvider.autoDispose<IncomeFormNotifier, IncomeFormState>(
      IncomeFormNotifier.new,
    );

/// Manages idempotency key for the expense form.
class ExpenseFormKeyNotifier extends Notifier<String> {
  @override
  String build() => const Uuid().v4();

  void regenerateKey() => state = const Uuid().v4();
}

final expenseFormKeyProvider =
    NotifierProvider.autoDispose<ExpenseFormKeyNotifier, String>(
      ExpenseFormKeyNotifier.new,
    );

/// Manages idempotency key for the transfer form.
class TransferFormKeyNotifier extends Notifier<String> {
  @override
  String build() => const Uuid().v4();

  void regenerateKey() => state = const Uuid().v4();
}

final transferFormKeyProvider =
    NotifierProvider.autoDispose<TransferFormKeyNotifier, String>(
      TransferFormKeyNotifier.new,
    );

/// Idempotency key for the reversal currently being confirmed.
///
/// The reversal operation's id *is* its idempotency key, so a retried confirm
/// — a double tap, a rebuild mid-write — appends one counter-entry, not two.
/// Regenerated only after a reversal is recorded.
class ReversalKeyNotifier extends Notifier<String> {
  @override
  String build() => const Uuid().v4();

  void regenerateKey() => state = const Uuid().v4();
}

final reversalKeyProvider =
    NotifierProvider.autoDispose<ReversalKeyNotifier, String>(
      ReversalKeyNotifier.new,
    );

// ── Submission state ──────────────────────────────────────────────────────────

class SubmittingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSubmitting(bool value) => state = value;
}

final submittingProvider =
    NotifierProvider.autoDispose<SubmittingNotifier, bool>(
      SubmittingNotifier.new,
    );

// ── Staged context providers ──────────────────────────────────────────────────
//
// These are intentionally NOT autoDispose. The form screen stages a context and
// immediately pushes the review route; with autoDispose the provider has no
// listener during that gap and is disposed before the review screen watches it,
// so review reads null and pops straight back — the button appears dead.
// Each review screen clears its staged context (`set(null)`) after a successful
// submit, so nothing leaks between operations.

class StagedIncomeContextNotifier extends Notifier<IncomeContext?> {
  @override
  IncomeContext? build() => null;

  void set(IncomeContext? ctx) => state = ctx;
}

final stagedIncomeContextProvider =
    NotifierProvider<StagedIncomeContextNotifier, IncomeContext?>(
      StagedIncomeContextNotifier.new,
    );

class StagedExpenseContextNotifier extends Notifier<ExpenseContext?> {
  @override
  ExpenseContext? build() => null;

  void set(ExpenseContext? ctx) => state = ctx;
}

final stagedExpenseContextProvider =
    NotifierProvider<StagedExpenseContextNotifier, ExpenseContext?>(
      StagedExpenseContextNotifier.new,
    );

class StagedTransferContextNotifier extends Notifier<TransferContext?> {
  @override
  TransferContext? build() => null;

  void set(TransferContext? ctx) => state = ctx;
}

final stagedTransferContextProvider =
    NotifierProvider<StagedTransferContextNotifier, TransferContext?>(
      StagedTransferContextNotifier.new,
    );
