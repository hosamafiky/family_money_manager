import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/balance/domain/balance_repository.dart';

/// Lists all non-archived accounts for a household.
final class ListAccountsUseCase {
  const ListAccountsUseCase(this._repo);
  final AccountRepository _repo;

  Future<AppResult<List<FinancialAccount>>> execute(String householdId) async {
    try {
      final accounts = await _repo.findByHousehold(householdId: householdId);
      return AppOk(accounts);
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}

/// Archives an account. Rejects archive if account has a non-zero balance.
final class ArchiveAccountUseCase {
  const ArchiveAccountUseCase({
    required AccountRepository accountRepository,
    required BalanceRepository balanceRepository,
  }) : _accountRepo = accountRepository,
       _balanceRepo = balanceRepository;

  final AccountRepository _accountRepo;
  final BalanceRepository _balanceRepo;

  Future<AppResult<FinancialAccount>> execute({
    required String accountId,
    required String householdId,
  }) async {
    try {
      final account = await _accountRepo.findById(id: accountId, householdId: householdId);
      if (account == null) return const AppNotFound();

      // A non-zero balance blocks archiving.
      final balance = await _balanceRepo.currentBalanceMinorUnits(
        accountId: accountId,
        householdId: householdId,
      );
      if (balance != 0) {
        return const AppValidationFailure(
          field: 'balance',
          messageKey: 'error_archive_nonzero_balance',
        );
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final archived = await _accountRepo.archiveAccount(
        id: accountId,
        householdId: householdId,
        archivedAt: DateTime.now().toUtc(),
        updatedAt: now,
      );
      return AppOk(archived);
    } on AccountNotFoundError {
      return const AppNotFound();
    } on AccountAlreadyArchivedError {
      return const AppDuplicateConflict(messageKey: 'error_account_already_archived');
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}

/// Updates safe metadata fields (name, notes) of an account.
///
/// ## Accepted inputs
/// Only [name] and [notes] are accepted. Classification fields (type,
/// currencyCode, ownerType, fundPurpose, isSpendable, isProtected,
/// includeInNetWorth, includeInZakat) and archive state are NOT accepted
/// here; they are locked by the repository and database-trigger layers.
///
/// ## V1 Display-Name Policy
/// Transaction lists, ledger entries, and audit records reference accounts
/// by their stable `account_id`. The displayed name is always resolved at
/// query time from the current `financial_accounts.name`. No historical name
/// snapshot is stored. This means if an account is renamed, all historical
/// displays show the new name. This is explicitly documented and acceptable
/// for V1. Audit correctness depends on stable IDs, not names.
final class UpdateAccountMetadataUseCase {
  const UpdateAccountMetadataUseCase(this._repo);
  final AccountRepository _repo;

  Future<AppResult<FinancialAccount>> execute({
    required String accountId,
    required String householdId,
    String? name,
    String? notes,
  }) async {
    if (name != null && name.trim().isEmpty) {
      return const AppValidationFailure(field: 'name', messageKey: 'error_account_name_empty');
    }
    try {
      final updated = await _repo.updateAccount(
        id: accountId,
        householdId: householdId,
        name: name?.trim(),
        notes: notes,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      return AppOk(updated);
    } on AccountNotFoundError {
      return const AppNotFound();
    } on ClassificationImmutabilityError catch (e) {
      return AppClassificationImmutabilityViolation(field: e.field);
    } catch (e) {
      // DB-trigger RAISE(ABORT, ...) surfaces as a SqliteException whose
      // message contains 'immutable'. Map it to AppClassificationImmutabilityViolation
      // for defense-in-depth (repo-layer check should normally fire first).
      final msg = e.toString().toLowerCase();
      if (msg.contains('immutable') || msg.contains('classification')) {
        return const AppClassificationImmutabilityViolation(field: 'classification');
      }
      return const AppPersistenceFailure();
    }
  }
}
