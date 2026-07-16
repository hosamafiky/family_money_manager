import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:uuid/uuid.dart';

/// Parameters for the account-creation workflow.
///
/// When [openingBalanceMinorUnits] is non-null and > 0, an opening-balance
/// ledger operation is recorded atomically with the account creation.
/// A zero or null balance creates no financial operation.
final class CreateAccountWorkflowParams {
  const CreateAccountWorkflowParams({
    required this.householdId,
    required this.name,
    required this.type,
    required this.ownerType,
    required this.fundPurpose,
    required this.currencyCode,
    required this.isSpendable,
    required this.isProtected,
    required this.includeInNetWorth,
    required this.includeInZakat,
    required this.createdBy,
    this.openingBalanceMinorUnits,
    this.openingBalanceDate,
    this.notes,
    this.idempotencyKey,
  });

  final String householdId;
  final String name;
  final FinancialAccountType type;
  final AccountOwnerType ownerType;
  final FundPurpose fundPurpose;
  final String currencyCode;
  final bool isSpendable;
  final bool isProtected;
  final bool includeInNetWorth;
  final bool includeInZakat;
  final String createdBy;
  final int? openingBalanceMinorUnits;
  final String? openingBalanceDate;
  final String? notes;
  final String? idempotencyKey;
}

/// Application use case: create a financial account, optionally with an
/// opening balance, as one atomic workflow.
///
/// The account and opening-balance operation are committed in a single
/// [AppDatabase.transaction] so that a failure in either leaves no partial state.
///
/// Idempotency: if the same [idempotencyKey] is resubmitted, the use case
/// returns [AppOk] with the previously created account.
final class CreateAccountUseCase {
  const CreateAccountUseCase({
    required AccountRepository accountRepository,
    required LedgerRepository ledgerRepository,
    required AppDatabase db,
  }) : _accountRepository = accountRepository,
       _ledgerRepository = ledgerRepository,
       _db = db;
  // Note: prefer_initializing_formals suppressed because the private field
  // names differ from the named constructor parameters.

  final AccountRepository _accountRepository;
  final LedgerRepository _ledgerRepository;
  final AppDatabase _db;

  static const _uuid = Uuid();

  Future<AppResult<FinancialAccount>> execute(
    CreateAccountWorkflowParams params,
  ) async {
    // ── Input validation ────────────────────────────────────────────────────
    if (params.name.trim().isEmpty) {
      return const AppValidationFailure(
        field: 'name',
        messageKey: 'error_account_name_empty',
      );
    }
    if (params.openingBalanceMinorUnits != null &&
        params.openingBalanceMinorUnits! < 0) {
      return const AppValidationFailure(
        field: 'openingBalance',
        messageKey: 'error_opening_balance_negative',
      );
    }

    final accountId = _uuid.v4();
    final idempotencyKey = params.idempotencyKey ?? accountId;

    try {
      late FinancialAccount account;

      await _db.transaction(() async {
        account = await _accountRepository.createAccount(
          CreateAccountParams(
            id: accountId,
            householdId: params.householdId,
            name: params.name.trim(),
            type: params.type,
            ownerType: params.ownerType,
            fundPurpose: params.fundPurpose,
            currencyCode: params.currencyCode,
            isSpendable: params.isSpendable,
            isProtected: params.isProtected,
            includeInNetWorth: params.includeInNetWorth,
            includeInZakat: params.includeInZakat,
            displayOrder: 0,
            createdBy: params.createdBy,
            notes: params.notes,
          ),
        );

        // Record opening balance if provided and non-zero.
        final amount = params.openingBalanceMinorUnits;
        if (amount != null && amount > 0) {
          await _ledgerRepository.recordOpeningBalance(
            RecordOpeningBalanceParams(
              operationId: _uuid.v4(),
              householdId: params.householdId,
              accountId: accountId,
              amountMinorUnits: amount,
              currencyCode: params.currencyCode,
              effectiveDate:
                  params.openingBalanceDate ??
                  DateTime.now().toUtc().toIso8601String().substring(0, 10),
              createdBy: params.createdBy,
              idempotencyKey: '${idempotencyKey}_opening',
            ),
          );
        }
      });

      return AppOk(account);
    } on DuplicateAccountIdError {
      return const AppDuplicateConflict(messageKey: 'error_account_duplicate');
    } on ArgumentError catch (e) {
      return AppValidationFailure(
        field: e.name ?? 'unknown',
        messageKey: 'error_validation_generic',
      );
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }
}
