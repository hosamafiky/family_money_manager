import 'package:drift/drift.dart' show Variable;
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:uuid/uuid.dart';

/// Builds a stable, non-localized fingerprint string from creation params.
///
/// Used to detect same-key-different-payload conflicts for idempotent account
/// creation.  All fields are stable codes (enum.code, booleans, integers).
String _buildIdempotencyPayload(CreateAccountWorkflowParams p) {
  final name = p.name.trim();
  final type = p.type.code;
  final ownerType = p.ownerType.code;
  final fundPurpose = p.fundPurpose.code;
  final currency = p.currencyCode;
  final spendable = p.isSpendable;
  final protected = p.isProtected;
  final netWorth = p.includeInNetWorth;
  final zakat = p.includeInZakat;
  final openingBalance = p.openingBalanceMinorUnits ?? 0;
  return '$name|$type|$ownerType|$fundPurpose|$currency|$spendable|$protected|$netWorth|$zakat|$openingBalance';
}

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
  const CreateAccountUseCase({required AccountRepository accountRepository, required LedgerRepository ledgerRepository, required AppDatabase db})
    : _accountRepository = accountRepository,
      _ledgerRepository = ledgerRepository,
      _db = db;
  // Note: prefer_initializing_formals suppressed because the private field
  // names differ from the named constructor parameters.

  final AccountRepository _accountRepository;
  final LedgerRepository _ledgerRepository;
  final AppDatabase _db;

  static const _uuid = Uuid();

  Future<AppResult<FinancialAccount>> execute(CreateAccountWorkflowParams params) async {
    // ── Input validation ────────────────────────────────────────────────────
    if (params.name.trim().isEmpty) {
      return const AppValidationFailure(field: 'name', messageKey: 'error_account_name_empty');
    }
    if (params.openingBalanceMinorUnits != null && params.openingBalanceMinorUnits! < 0) {
      return const AppValidationFailure(field: 'openingBalance', messageKey: 'error_opening_balance_negative');
    }

    // ── Idempotency check ───────────────────────────────────────────────────
    // When a caller-supplied idempotency key is present, look for an existing
    // account with the same (householdId, idempotencyKey) pair.
    if (params.idempotencyKey != null) {
      final existing = await _accountRepository.findByIdempotencyKey(householdId: params.householdId, idempotencyKey: params.idempotencyKey!);
      if (existing != null) {
        // Compare payload fingerprints to distinguish a safe retry from a
        // conflicting call with the same key but different intent.
        final currentPayload = _buildIdempotencyPayload(params);
        final storedPayload = await _loadStoredPayload(params.householdId, params.idempotencyKey!);
        if (storedPayload == currentPayload) {
          return AppOk(existing);
        }
        return const AppDuplicateConflict(messageKey: 'error_account_duplicate');
      }
    }

    final accountId = _uuid.v4();
    final idempotencyKey = params.idempotencyKey ?? accountId;
    final idempotencyPayload = params.idempotencyKey != null ? _buildIdempotencyPayload(params) : null;

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
            idempotencyKey: params.idempotencyKey,
            idempotencyPayload: idempotencyPayload,
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
              effectiveDate: params.openingBalanceDate ?? DateTime.now().toUtc().toIso8601String().substring(0, 10),
              createdBy: params.createdBy,
              idempotencyKey: '${idempotencyKey}_opening',
            ),
          );
        }
      });

      return AppOk(account);
    } on DuplicateAccountIdError {
      return const AppDuplicateConflict(messageKey: 'error_account_duplicate');
    } on ArchivedAccountError {
      return const AppValidationFailure(field: 'account', messageKey: 'error_account_archived');
    } on ArgumentError catch (e) {
      return AppValidationFailure(field: e.name ?? 'unknown', messageKey: 'error_validation_generic');
    } catch (_) {
      return const AppPersistenceFailure();
    }
  }

  /// Loads the stored idempotency payload for a given key, if any.
  Future<String?> _loadStoredPayload(String householdId, String idempotencyKey) async {
    // Query the raw DB row to read the stored payload.
    final rows = await _db
        .customSelect(
          'SELECT idempotency_payload FROM financial_accounts '
          'WHERE household_id = ? AND idempotency_key = ?',
          variables: [Variable(householdId), Variable(idempotencyKey)],
        )
        .get();
    if (rows.isEmpty) return null;
    return rows.first.read<String?>('idempotency_payload');
  }
}
