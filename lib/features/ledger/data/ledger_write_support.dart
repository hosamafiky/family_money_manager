import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/scoped_idempotency.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';

/// Internal Drift helpers shared by [DriftLedgerRepository] write paths.
///
/// Must be invoked on the same [AppDatabase] instance and, for idempotency /
/// balance checks, inside the same writer transaction as the inserts.
final class LedgerWriteSupport {
  LedgerWriteSupport(this._db);

  final AppDatabase _db;

  /// Scoped operation idempotency (INV-008). Call inside a transaction.
  ///
  /// Returns `null` when the caller may proceed with a fresh insert.
  Future<IdempotentOperationResult?> checkOperationIdempotency({
    required String operationId,
    required String householdId,
    required String idempotencyKey,
    String? expectedType,
    int? expectedAmount,
    String? expectedCurrency,
    String? expectedSourceAccountId,
    String? expectedDestinationAccountId,
  }) async {
    final existingById =
        await (_db.select(_db.operations)..where(
              (t) =>
                  t.id.equals(operationId) & t.householdId.equals(householdId),
            ))
            .getSingleOrNull();
    if (existingById != null) return IdempotentOperationResult.alreadyExists;

    if (idempotencyKey != operationId) {
      final existingByKey =
          await (_db.select(_db.operations)..where(
                (t) =>
                    t.idempotencyKey.equals(idempotencyKey) &
                    t.householdId.equals(householdId),
              ))
              .getSingleOrNull();
      if (existingByKey != null) {
        final fingerprintsProvided =
            expectedType != null &&
            expectedAmount != null &&
            expectedCurrency != null;

        if (fingerprintsProvided) {
          final decision = decideOperationFingerprint(
            incoming: OperationIdempotencyFingerprint(
              type: expectedType,
              amountMinorUnits: expectedAmount,
              currencyCode: expectedCurrency,
              sourceAccountId: expectedSourceAccountId,
              destinationAccountId: expectedDestinationAccountId,
            ),
            existingType: existingByKey.type,
            existingAmountMinorUnits: existingByKey.totalAmountMinorUnits,
            existingCurrencyCode: existingByKey.currencyCode,
            existingSourceAccountId: existingByKey.sourceAccountId,
            existingDestinationAccountId: existingByKey.destinationAccountId,
          );
          return decision == ScopedIdempotencyDecision.replay
              ? IdempotentOperationResult.alreadyExists
              : IdempotentOperationResult.conflict;
        }

        return IdempotentOperationResult.conflict;
      }
    }

    return null;
  }

  Future<FinancialAccount> requireActiveAccount(
    String accountId,
    String householdId,
  ) async {
    final account = await loadAccount(accountId, householdId);
    if (account.isArchived) throw ArchivedAccountError(accountId);
    return account;
  }

  /// Loads an account without archive rejection (reversals may target archived).
  Future<FinancialAccount> loadAccount(
    String accountId,
    String householdId,
  ) async {
    final row =
        await (_db.select(_db.financialAccounts)..where(
              (t) => t.id.equals(accountId) & t.householdId.equals(householdId),
            ))
            .getSingleOrNull();
    if (row == null) {
      throw ArgumentError(
        'Account $accountId not found in household $householdId',
      );
    }
    return rowToAccount(row);
  }

  Future<bool> hasOpeningBalance(String accountId, String householdId) async {
    final rows =
        await (_db.select(_db.ledgerEntries)..where(
              (t) =>
                  t.accountId.equals(accountId) &
                  t.householdId.equals(householdId) &
                  t.entryType.equals(LedgerEntryType.openingBalance.code),
            ))
            .get();
    return rows.isNotEmpty;
  }

  Future<void> checkSufficientBalance(
    String accountId,
    String householdId,
    int amount,
  ) async {
    final entries =
        await (_db.select(_db.ledgerEntries)..where(
              (t) =>
                  t.accountId.equals(accountId) &
                  t.householdId.equals(householdId),
            ))
            .get();

    var balance = 0;
    for (final e in entries) {
      if (e.direction == LedgerDirection.credit.code) {
        balance += e.amountMinorUnits;
      } else {
        balance -= e.amountMinorUnits;
      }
    }

    if (balance < amount) {
      throw InsufficientFundsError(
        accountId: accountId,
        availableMinorUnits: balance,
        requestedMinorUnits: amount,
      );
    }
  }

  void checkProtectedWithdrawal({
    required FinancialAccount account,
    required ChildWithdrawalAuditParams? auditParams,
    required String expectedOperationId,
    required String expectedHouseholdId,
  }) {
    if (!account.requiresWithdrawalAudit) return;

    if (auditParams == null) {
      throw MissingProtectedWithdrawalAuditError(account.id);
    }
    if (auditParams.operationId != expectedOperationId) {
      throw AuditOperationMismatchError(
        auditOperationId: auditParams.operationId,
        expectedOperationId: expectedOperationId,
      );
    }
    if (auditParams.accountId != account.id) {
      throw AuditAccountMismatchError(
        auditAccountId: auditParams.accountId,
        expectedAccountId: account.id,
      );
    }
    if (auditParams.householdId != expectedHouseholdId) {
      throw ArgumentError(
        'AuditParams householdId (${auditParams.householdId}) '
        'does not match operation householdId ($expectedHouseholdId)',
      );
    }
  }

  Future<void> insertOp(OperationsCompanion companion) async {
    await _db.into(_db.operations).insert(companion);
  }

  Future<void> insertEntry(LedgerEntriesCompanion companion) async {
    await _db.into(_db.ledgerEntries).insert(companion);
  }

  Future<void> insertContext(OperationContextsCompanion companion) async {
    await _db.into(_db.operationContexts).insert(companion);
  }

  Future<void> insertAudit(
    ChildWithdrawalAuditParams params,
    String now,
  ) async {
    await _db
        .into(_db.childWithdrawalAudits)
        .insert(
          ChildWithdrawalAuditsCompanion.insert(
            id: params.auditId,
            operationId: params.operationId,
            householdId: params.householdId,
            accountId: params.accountId,
            amountMinorUnits: params.amountMinorUnits,
            reason: params.reason,
            beneficiary: params.beneficiary.code,
            confirmedAt: params.confirmedAt.toUtc().toIso8601String(),
            confirmedBy: params.confirmedBy,
            createdAt: now,
            warningShown: Value(params.warningShown),
            biometricConfirmed: Value(params.biometricConfirmed),
          ),
        );
  }

  LedgerEntry toLedgerEntry(DbLedgerEntry row) => LedgerEntry(
    id: row.id,
    operationId: row.operationId,
    householdId: row.householdId,
    accountId: row.accountId,
    direction: LedgerDirection.fromCode(row.direction),
    amountMinorUnits: row.amountMinorUnits,
    currencyCode: row.currencyCode,
    entryType: LedgerEntryType.fromCode(row.entryType),
    effectiveDate: row.effectiveDate,
    recordedAt: DateTime.parse(row.recordedAt).toUtc(),
    notes: row.notes,
    createdBy: row.createdBy,
    isReversal: row.isReversal,
    reversalOfEntryId: row.reversalOfEntryId,
  );

  Operation toOperation(DbOperation row) => Operation(
    id: row.id,
    householdId: row.householdId,
    type: OperationType.fromCode(row.type),
    effectiveDate: row.effectiveDate,
    recordedAt: DateTime.parse(row.recordedAt).toUtc(),
    description: row.description,
    categoryCode: row.categoryCode,
    scope: row.scope != null ? ExpenseScope.fromCode(row.scope!) : null,
    spenderRole: row.spenderRole != null
        ? HouseholdMemberRole.fromCode(row.spenderRole!)
        : null,
    beneficiaryRole: row.beneficiaryRole != null
        ? HouseholdMemberRole.fromCode(row.beneficiaryRole!)
        : null,
    sourceAccountId: row.sourceAccountId,
    destinationAccountId: row.destinationAccountId,
    totalAmountMinorUnits: row.totalAmountMinorUnits,
    currencyCode: row.currencyCode,
    isRecurring: row.isRecurring,
    recurringRuleId: row.recurringRuleId,
    tags: row.tags != null
        ? row.tags!.split(',').where((String s) => s.isNotEmpty).toList()
        : <String>[],
    receiptPath: row.receiptPath,
    isReversed: row.isReversed,
    reversedBy: row.reversedBy,
    reversalReason: row.reversalReason,
    createdBy: row.createdBy,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  FinancialAccount rowToAccount(DbFinancialAccount row) => FinancialAccount(
    id: row.id,
    householdId: row.householdId,
    name: row.name,
    type: FinancialAccountType.fromCode(row.type),
    ownerType: AccountOwnerType.fromCode(row.ownerType),
    fundPurpose: FundPurpose.fromCode(row.fundPurpose),
    currencyCode: row.currencyCode,
    isSpendable: row.isSpendable,
    isProtected: row.isProtected,
    includeInNetWorth: row.includeInNetWorth,
    includeInZakat: row.includeInZakat,
    isArchived: row.isArchived,
    archivedAt: row.archivedAt != null
        ? DateTime.tryParse(row.archivedAt!)?.toUtc()
        : null,
    displayOrder: row.displayOrder,
    notes: row.notes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    createdBy: row.createdBy,
  );
}
