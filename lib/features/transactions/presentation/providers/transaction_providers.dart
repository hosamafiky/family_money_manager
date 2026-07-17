import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/features/accounts/presentation/providers/account_providers.dart';
import 'package:family_money_manager/features/household/presentation/providers/household_providers.dart';
import 'package:family_money_manager/features/transactions/application/execute_transfer_use_case.dart';
import 'package:family_money_manager/features/transactions/application/get_spouse_wallet_summary_use_case.dart';
import 'package:family_money_manager/features/transactions/application/get_transaction_history_use_case.dart';
import 'package:family_money_manager/features/transactions/application/record_expense_use_case.dart';
import 'package:family_money_manager/features/transactions/application/record_income_use_case.dart';
import 'package:family_money_manager/features/transactions/data/drift_transaction_query_repository.dart';
import 'package:family_money_manager/features/transactions/data/transaction_query_repository.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_context.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_filter.dart';
import 'package:family_money_manager/features/transactions/domain/transaction_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final transactionQueryRepositoryProvider = Provider<TransactionQueryRepository>((ref) {
  return DriftTransactionQueryRepository(ref.watch(appDatabaseProvider));
});

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

final getTransactionHistoryUseCaseProvider = Provider<GetTransactionHistoryUseCase>((ref) {
  return GetTransactionHistoryUseCase(ref.watch(transactionQueryRepositoryProvider));
});

final getSpouseWalletSummaryUseCaseProvider = Provider<GetSpouseWalletSummaryUseCase>((ref) {
  return GetSpouseWalletSummaryUseCase(ref.watch(transactionQueryRepositoryProvider));
});

// ── Transaction list provider ─────────────────────────────────────────────────

final transactionListProvider =
    FutureProvider.family<AppResult<List<TransactionSummary>>, (String, TransactionFilter)>((
      ref,
      args,
    ) {
      final (householdId, filter) = args;
      final useCase = ref.watch(getTransactionHistoryUseCaseProvider);
      return useCase.execute(householdId: householdId, filter: filter);
    });

// ── Transaction detail provider ───────────────────────────────────────────────

final transactionDetailProvider = FutureProvider.family<TransactionSummary?, (String, String)>((
  ref,
  args,
) {
  final (operationId, householdId) = args;
  final repo = ref.watch(transactionQueryRepositoryProvider);
  return repo.operationDetail(operationId: operationId, householdId: householdId);
});

// ── Spouse wallet summary provider ────────────────────────────────────────────

typedef SpouseWalletArgs = ({
  String spouseAccountId,
  String householdId,
  String fromDate,
  String toDate,
});

final spouseWalletSummaryProvider =
    FutureProvider.family<AppResult<SpouseWalletSummary>, SpouseWalletArgs>((ref, args) {
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

final incomeFormProvider = NotifierProvider.autoDispose<IncomeFormNotifier, IncomeFormState>(
  IncomeFormNotifier.new,
);

/// Manages idempotency key for the expense form.
class ExpenseFormKeyNotifier extends Notifier<String> {
  @override
  String build() => const Uuid().v4();

  void regenerateKey() => state = const Uuid().v4();
}

final expenseFormKeyProvider = NotifierProvider.autoDispose<ExpenseFormKeyNotifier, String>(
  ExpenseFormKeyNotifier.new,
);

/// Manages idempotency key for the transfer form.
class TransferFormKeyNotifier extends Notifier<String> {
  @override
  String build() => const Uuid().v4();

  void regenerateKey() => state = const Uuid().v4();
}

final transferFormKeyProvider = NotifierProvider.autoDispose<TransferFormKeyNotifier, String>(
  TransferFormKeyNotifier.new,
);

// ── Submission state ──────────────────────────────────────────────────────────

class SubmittingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSubmitting(bool value) => state = value;
}

final submittingProvider = NotifierProvider.autoDispose<SubmittingNotifier, bool>(
  SubmittingNotifier.new,
);

// ── Staged context providers ──────────────────────────────────────────────────

class StagedIncomeContextNotifier extends Notifier<IncomeContext?> {
  @override
  IncomeContext? build() => null;

  void set(IncomeContext? ctx) => state = ctx;
}

final stagedIncomeContextProvider =
    NotifierProvider.autoDispose<StagedIncomeContextNotifier, IncomeContext?>(
      StagedIncomeContextNotifier.new,
    );

class StagedExpenseContextNotifier extends Notifier<ExpenseContext?> {
  @override
  ExpenseContext? build() => null;

  void set(ExpenseContext? ctx) => state = ctx;
}

final stagedExpenseContextProvider =
    NotifierProvider.autoDispose<StagedExpenseContextNotifier, ExpenseContext?>(
      StagedExpenseContextNotifier.new,
    );

class StagedTransferContextNotifier extends Notifier<TransferContext?> {
  @override
  TransferContext? build() => null;

  void set(TransferContext? ctx) => state = ctx;
}

final stagedTransferContextProvider =
    NotifierProvider.autoDispose<StagedTransferContextNotifier, TransferContext?>(
      StagedTransferContextNotifier.new,
    );
