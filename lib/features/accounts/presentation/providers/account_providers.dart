import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/database_providers.dart';
import 'package:family_money_manager/features/accounts/application/account_use_cases.dart';
import 'package:family_money_manager/features/accounts/application/create_account_use_case.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/data/drift_account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/balance/data/drift_balance_repository.dart';
import 'package:family_money_manager/features/balance/domain/balance_repository.dart';
import 'package:family_money_manager/features/ledger/data/drift_ledger_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Repository providers ──────────────────────────────────────────────────

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftAccountRepository(db);
});

final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftBalanceRepository(db);
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftLedgerRepository(db);
});

// ── Use-case providers ────────────────────────────────────────────────────

final listAccountsUseCaseProvider = Provider((ref) {
  return ListAccountsUseCase(ref.watch(accountRepositoryProvider));
});

final archiveAccountUseCaseProvider = Provider((ref) {
  return ArchiveAccountUseCase(
    accountRepository: ref.watch(accountRepositoryProvider),
    balanceRepository: ref.watch(balanceRepositoryProvider),
  );
});

final updateAccountMetadataUseCaseProvider = Provider((ref) {
  return UpdateAccountMetadataUseCase(ref.watch(accountRepositoryProvider));
});

final createAccountUseCaseProvider = Provider<CreateAccountUseCase>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CreateAccountUseCase(
    accountRepository: ref.watch(accountRepositoryProvider),
    ledgerRepository: ref.watch(ledgerRepositoryProvider),
    db: db,
  );
});

// ── Account list provider ─────────────────────────────────────────────────

final accountsProvider =
    FutureProvider.family<AppResult<List<FinancialAccount>>, String>((
      ref,
      householdId,
    ) {
      final useCase = ref.watch(listAccountsUseCaseProvider);
      return useCase.execute(householdId);
    });

// ── Single account provider ───────────────────────────────────────────────

final accountDetailProvider =
    FutureProvider.family<FinancialAccount?, (String, String)>((ref, args) {
      final (accountId, householdId) = args;
      final repo = ref.watch(accountRepositoryProvider);
      return repo.findById(id: accountId, householdId: householdId);
    });

// ── Account balance provider ──────────────────────────────────────────────

final accountBalanceProvider = FutureProvider.family<int, (String, String)>((
  ref,
  args,
) {
  final (accountId, householdId) = args;
  final repo = ref.watch(balanceRepositoryProvider);
  return repo.currentBalanceMinorUnits(
    accountId: accountId,
    householdId: householdId,
  );
});
