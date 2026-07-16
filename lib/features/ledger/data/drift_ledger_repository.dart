import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/ledger_entry.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';

/// Drift-backed implementation of [LedgerRepository].
///
/// ## Idempotency (INV-008, Phase 2A hardening)
///
/// Every write uses `INSERT OR IGNORE` for the parent operation row and then
/// checks whether the row was actually inserted. This makes the existence check
/// atomic with the insert, eliminating the TOCTOU race that existed in Phase 2.
///
/// Idempotency concepts distinguished:
/// - **operation_id** — the row primary key. Unique across the household.
/// - **idempotency_key** — an optional caller-supplied key scoped by
///   `(household_id, idempotency_key)`. Defaults to `operation_id` when null.
///   A UNIQUE index enforces uniqueness in the DB.
/// - **ledger-entry id** — unique per entry (`${operationId}_debit` etc.).
/// - **reversal id** — the `reversalOperationId` stored in `reversedBy`.
/// - **original-operation reference** — the `originalOperationId` in a reversal.
///
/// Results:
/// - Same `operation_id` resubmitted → [IdempotentOperationResult.alreadyExists]
/// - Same `idempotency_key` but different `operation_id` → [IdempotentOperationResult.conflict]
///
/// ## Transaction boundaries (INV-007)
///
/// Every write wraps ALL database inserts (operation row, ledger entries, audit
/// record) in a single explicit `_db.transaction()`. The idempotency check is
/// performed inside the transaction using `INSERT OR IGNORE`, not with a prior
/// SELECT (TOCTOU-safe).
///
/// ## Append-only enforcement (INV-002, Phase 2A)
///
/// The `restrict_operations_update` trigger only allows mutations to
/// `is_reversed`, `reversed_by`, and `updated_at`. All other columns are
/// append-only.
///
/// ## Audit validation (INV-006, Phase 2A)
///
/// Before writing a [ChildWithdrawalAuditParams], the repository validates:
/// - `auditParams.operationId` matches the operation being written.
/// - `auditParams.accountId` matches the protected account being debited.
/// - `auditParams.householdId` matches the operation's household.
final class DriftLedgerRepository implements LedgerRepository {
  const DriftLedgerRepository(this._db);

  final AppDatabase _db;

  // ── Income ────────────────────────────────────────────────────────────────

  @override
  Future<IdempotentOperationResult> recordIncome(
    RecordIncomeParams params,
  ) async {
    // Validate account belongs to household before starting the transaction.
    await _requireAccount(params.destinationAccountId, params.householdId);

    final now = DateTime.now().toUtc().toIso8601String();
    late IdempotentOperationResult result;

    await _db.transaction(() async {
      final idemResult = await _checkIdempotency(
        operationId: params.operationId,
        householdId: params.householdId,
        idempotencyKey: params.resolvedIdempotencyKey,
      );
      if (idemResult != null) {
        result = idemResult;
        return;
      }

      await _insertOp(
        OperationsCompanion.insert(
          id: params.operationId,
          householdId: params.householdId,
          type: OperationType.income.code,
          effectiveDate: params.effectiveDate,
          recordedAt: now,
          totalAmountMinorUnits: params.amountMinorUnits,
          currencyCode: Value(params.currencyCode),
          createdBy: params.createdBy,
          createdAt: now,
          updatedAt: now,
          description: Value(params.description),
          categoryCode: Value(params.categoryCode),
          scope: Value(params.scope?.code),
          beneficiaryRole: Value(params.beneficiaryRole?.code),
          destinationAccountId: Value(params.destinationAccountId),
          tags: Value(params.tags.isEmpty ? null : params.tags.join(',')),
          idempotencyKey: Value(params.resolvedIdempotencyKey),
        ),
      );

      await _insertEntry(
        LedgerEntriesCompanion.insert(
          id: '${params.operationId}_credit',
          operationId: params.operationId,
          householdId: params.householdId,
          accountId: params.destinationAccountId,
          direction: LedgerDirection.credit.code,
          amountMinorUnits: params.amountMinorUnits,
          currencyCode: Value(params.currencyCode),
          entryType: LedgerEntryType.income.code,
          effectiveDate: params.effectiveDate,
          recordedAt: now,
          createdBy: params.createdBy,
        ),
      );

      result = IdempotentOperationResult.created;
    });

    return result;
  }

  // ── Expense ───────────────────────────────────────────────────────────────

  @override
  Future<IdempotentOperationResult> recordExpense(
    RecordExpenseParams params, {
    ChildWithdrawalAuditParams? auditParams,
  }) async {
    final account = await _requireAccount(
      params.sourceAccountId,
      params.householdId,
    );
    _checkProtectedWithdrawal(
      account: account,
      auditParams: auditParams,
      expectedOperationId: params.operationId,
      expectedHouseholdId: params.householdId,
    );
    await _checkSufficientBalance(
      params.sourceAccountId,
      params.householdId,
      params.amountMinorUnits,
    );

    final now = DateTime.now().toUtc().toIso8601String();
    final entryType = account.isChildProtectedFund
        ? LedgerEntryType.childFundWithdrawal
        : LedgerEntryType.expense;
    late IdempotentOperationResult result;

    await _db.transaction(() async {
      final idemResult = await _checkIdempotency(
        operationId: params.operationId,
        householdId: params.householdId,
        idempotencyKey: params.resolvedIdempotencyKey,
      );
      if (idemResult != null) {
        result = idemResult;
        return;
      }

      await _insertOp(
        OperationsCompanion.insert(
          id: params.operationId,
          householdId: params.householdId,
          type: account.isChildProtectedFund
              ? OperationType.childFundWithdrawal.code
              : OperationType.expense.code,
          effectiveDate: params.effectiveDate,
          recordedAt: now,
          totalAmountMinorUnits: params.amountMinorUnits,
          currencyCode: Value(params.currencyCode),
          createdBy: params.createdBy,
          createdAt: now,
          updatedAt: now,
          description: Value(params.description),
          categoryCode: Value(params.categoryCode),
          scope: Value(params.scope?.code),
          spenderRole: Value(params.spenderRole?.code),
          beneficiaryRole: Value(params.beneficiaryRole?.code),
          sourceAccountId: Value(params.sourceAccountId),
          tags: Value(params.tags.isEmpty ? null : params.tags.join(',')),
          idempotencyKey: Value(params.resolvedIdempotencyKey),
        ),
      );

      await _insertEntry(
        LedgerEntriesCompanion.insert(
          id: '${params.operationId}_debit',
          operationId: params.operationId,
          householdId: params.householdId,
          accountId: params.sourceAccountId,
          direction: LedgerDirection.debit.code,
          amountMinorUnits: params.amountMinorUnits,
          currencyCode: Value(params.currencyCode),
          entryType: entryType.code,
          effectiveDate: params.effectiveDate,
          recordedAt: now,
          createdBy: params.createdBy,
        ),
      );

      if (auditParams != null) {
        await _insertAudit(auditParams, now);
      }

      result = IdempotentOperationResult.created;
    });

    return result;
  }

  // ── Transfer ──────────────────────────────────────────────────────────────

  @override
  Future<IdempotentOperationResult> executeTransfer(
    ExecuteTransferParams params, {
    ChildWithdrawalAuditParams? auditParams,
  }) async {
    if (params.sourceAccountId == params.destinationAccountId) {
      throw SameAccountTransferError(params.sourceAccountId);
    }

    final source = await _requireAccount(
      params.sourceAccountId,
      params.householdId,
    );
    final destination = await _requireAccount(
      params.destinationAccountId,
      params.householdId,
    );

    if (source.currencyCode != destination.currencyCode) {
      throw CurrencyMismatchTransferError(
        sourceCode: source.currencyCode,
        destinationCode: destination.currencyCode,
      );
    }
    if (source.isArchived) {
      throw ArchivedAccountTransferError(params.sourceAccountId, 'source');
    }
    if (destination.isArchived) {
      throw ArchivedAccountTransferError(
        params.destinationAccountId,
        'destination',
      );
    }
    _checkProtectedWithdrawal(
      account: source,
      auditParams: auditParams,
      expectedOperationId: params.operationId,
      expectedHouseholdId: params.householdId,
    );
    await _checkSufficientBalance(
      params.sourceAccountId,
      params.householdId,
      params.amountMinorUnits,
    );

    final now = DateTime.now().toUtc().toIso8601String();
    late IdempotentOperationResult result;

    await _db.transaction(() async {
      final idemResult = await _checkIdempotency(
        operationId: params.operationId,
        householdId: params.householdId,
        idempotencyKey: params.resolvedIdempotencyKey,
      );
      if (idemResult != null) {
        result = idemResult;
        return;
      }

      await _insertOp(
        OperationsCompanion.insert(
          id: params.operationId,
          householdId: params.householdId,
          type: OperationType.transfer.code,
          effectiveDate: params.effectiveDate,
          recordedAt: now,
          totalAmountMinorUnits: params.amountMinorUnits,
          currencyCode: Value(params.currencyCode),
          createdBy: params.createdBy,
          createdAt: now,
          updatedAt: now,
          description: Value(params.description),
          sourceAccountId: Value(params.sourceAccountId),
          destinationAccountId: Value(params.destinationAccountId),
          tags: Value(params.tags.isEmpty ? null : params.tags.join(',')),
          idempotencyKey: Value(params.resolvedIdempotencyKey),
        ),
      );

      await _insertEntry(
        LedgerEntriesCompanion.insert(
          id: '${params.operationId}_debit',
          operationId: params.operationId,
          householdId: params.householdId,
          accountId: params.sourceAccountId,
          direction: LedgerDirection.debit.code,
          amountMinorUnits: params.amountMinorUnits,
          currencyCode: Value(params.currencyCode),
          entryType: LedgerEntryType.transferOut.code,
          effectiveDate: params.effectiveDate,
          recordedAt: now,
          createdBy: params.createdBy,
        ),
      );

      await _insertEntry(
        LedgerEntriesCompanion.insert(
          id: '${params.operationId}_credit',
          operationId: params.operationId,
          householdId: params.householdId,
          accountId: params.destinationAccountId,
          direction: LedgerDirection.credit.code,
          amountMinorUnits: params.amountMinorUnits,
          currencyCode: Value(params.currencyCode),
          entryType: LedgerEntryType.transferIn.code,
          effectiveDate: params.effectiveDate,
          recordedAt: now,
          createdBy: params.createdBy,
        ),
      );

      if (auditParams != null) {
        await _insertAudit(auditParams, now);
      }

      result = IdempotentOperationResult.created;
    });

    return result;
  }

  // ── Opening balance ───────────────────────────────────────────────────────

  @override
  Future<IdempotentOperationResult> recordOpeningBalance(
    RecordOpeningBalanceParams params,
  ) async {
    await _requireAccount(params.accountId, params.householdId);

    // Idempotency check: if this exact operation ID already exists → safe retry.
    final existing = await findOperation(
      operationId: params.operationId,
      householdId: params.householdId,
    );
    if (existing != null) return IdempotentOperationResult.alreadyExists;

    final alreadyHas = await _hasOpeningBalance(
      params.accountId,
      params.householdId,
    );
    if (alreadyHas) throw DuplicateOpeningBalanceError(params.accountId);

    final now = DateTime.now().toUtc().toIso8601String();
    late IdempotentOperationResult result;

    await _db.transaction(() async {
      final idemResult = await _checkIdempotency(
        operationId: params.operationId,
        householdId: params.householdId,
        idempotencyKey: params.resolvedIdempotencyKey,
      );
      if (idemResult != null) {
        result = idemResult;
        return;
      }

      await _insertOp(
        OperationsCompanion.insert(
          id: params.operationId,
          householdId: params.householdId,
          type: OperationType.openingBalance.code,
          effectiveDate: params.effectiveDate,
          recordedAt: now,
          totalAmountMinorUnits: params.amountMinorUnits,
          currencyCode: Value(params.currencyCode),
          createdBy: params.createdBy,
          createdAt: now,
          updatedAt: now,
          description: Value(params.description),
          destinationAccountId: Value(params.accountId),
          idempotencyKey: Value(params.resolvedIdempotencyKey),
        ),
      );

      // An opening balance of 0 is a valid state (empty account). The ledger
      // entry amount_minor_units > 0 constraint means we skip the entry for
      // zero-balance opens.
      if (params.amountMinorUnits > 0) {
        await _insertEntry(
          LedgerEntriesCompanion.insert(
            id: '${params.operationId}_credit',
            operationId: params.operationId,
            householdId: params.householdId,
            accountId: params.accountId,
            direction: LedgerDirection.credit.code,
            amountMinorUnits: params.amountMinorUnits,
            currencyCode: Value(params.currencyCode),
            entryType: LedgerEntryType.openingBalance.code,
            effectiveDate: params.effectiveDate,
            recordedAt: now,
            createdBy: params.createdBy,
          ),
        );
      }

      result = IdempotentOperationResult.created;
    });

    return result;
  }

  // ── Adjustment ────────────────────────────────────────────────────────────

  @override
  Future<IdempotentOperationResult> recordAdjustment(
    RecordAdjustmentParams params, {
    ChildWithdrawalAuditParams? auditParams,
  }) async {
    final account = await _requireAccount(params.accountId, params.householdId);

    if (!params.isCredit) {
      _checkProtectedWithdrawal(
        account: account,
        auditParams: auditParams,
        expectedOperationId: params.operationId,
        expectedHouseholdId: params.householdId,
      );
    }

    final absAmount = params.adjustmentAmountMinorUnits.abs();
    final now = DateTime.now().toUtc().toIso8601String();
    late IdempotentOperationResult result;

    await _db.transaction(() async {
      final idemResult = await _checkIdempotency(
        operationId: params.operationId,
        householdId: params.householdId,
        idempotencyKey: params.resolvedIdempotencyKey,
      );
      if (idemResult != null) {
        result = idemResult;
        return;
      }

      await _insertOp(
        OperationsCompanion.insert(
          id: params.operationId,
          householdId: params.householdId,
          type: OperationType.adjustment.code,
          effectiveDate: params.effectiveDate,
          recordedAt: now,
          totalAmountMinorUnits: absAmount,
          currencyCode: Value(params.currencyCode),
          createdBy: params.createdBy,
          createdAt: now,
          updatedAt: now,
          description: Value(params.reason),
          sourceAccountId: params.isCredit
              ? const Value.absent()
              : Value(params.accountId),
          destinationAccountId: params.isCredit
              ? Value(params.accountId)
              : const Value.absent(),
          idempotencyKey: Value(params.resolvedIdempotencyKey),
        ),
      );

      await _insertEntry(
        LedgerEntriesCompanion.insert(
          id: '${params.operationId}_entry',
          operationId: params.operationId,
          householdId: params.householdId,
          accountId: params.accountId,
          direction: params.isCredit
              ? LedgerDirection.credit.code
              : LedgerDirection.debit.code,
          amountMinorUnits: absAmount,
          currencyCode: Value(params.currencyCode),
          entryType: params.isCredit
              ? LedgerEntryType.adjustmentCredit.code
              : LedgerEntryType.adjustmentDebit.code,
          effectiveDate: params.effectiveDate,
          recordedAt: now,
          createdBy: params.createdBy,
        ),
      );

      if (auditParams != null) {
        await _insertAudit(auditParams, now);
      }

      result = IdempotentOperationResult.created;
    });

    return result;
  }

  // ── Reversal ──────────────────────────────────────────────────────────────

  @override
  Future<IdempotentOperationResult> reverseOperation(
    ReverseOperationParams params, {
    ChildWithdrawalAuditParams? auditParams,
  }) async {
    // Check idempotency first: if this exact reversal operation ID already
    // exists, the caller is retrying a completed reversal → alreadyExists.
    // This check must happen BEFORE the isReversed check so that retries
    // return alreadyExists rather than DuplicateReversalError.
    final existingReversal = await findOperation(
      operationId: params.reversalOperationId,
      householdId: params.householdId,
    );
    if (existingReversal != null) {
      return IdempotentOperationResult.alreadyExists;
    }

    final original = await findOperation(
      operationId: params.originalOperationId,
      householdId: params.householdId,
    );
    if (original == null) {
      throw OperationNotFoundError(params.originalOperationId);
    }
    if (original.isReversed) {
      throw DuplicateReversalError(params.originalOperationId);
    }

    final originalEntries =
        await (_db.select(_db.ledgerEntries)..where(
              (t) =>
                  t.operationId.equals(params.originalOperationId) &
                  t.householdId.equals(params.householdId),
            ))
            .get();

    // A reversal of an original CREDIT → a new DEBIT on that account.
    // If the account is protected, an audit record is required.
    for (final entry in originalEntries) {
      if (entry.direction == LedgerDirection.credit.code) {
        final account = await _requireAccount(
          entry.accountId,
          params.householdId,
        );
        if (account.requiresWithdrawalAudit) {
          if (auditParams == null) {
            throw MissingProtectedWithdrawalAuditError(entry.accountId);
          }
          // Validate that the audit references the correct reversal operation
          // and the correct protected account.
          if (auditParams.operationId != params.reversalOperationId) {
            throw AuditOperationMismatchError(
              auditOperationId: auditParams.operationId,
              expectedOperationId: params.reversalOperationId,
            );
          }
          if (auditParams.accountId != entry.accountId) {
            throw AuditAccountMismatchError(
              auditAccountId: auditParams.accountId,
              expectedAccountId: entry.accountId,
            );
          }
          if (auditParams.householdId != params.householdId) {
            throw ArgumentError(
              'AuditParams householdId (${auditParams.householdId}) '
              'does not match operation householdId (${params.householdId})',
            );
          }
        }
      }
    }

    final now = DateTime.now().toUtc().toIso8601String();
    late IdempotentOperationResult result;

    await _db.transaction(() async {
      final idemResult = await _checkIdempotency(
        operationId: params.reversalOperationId,
        householdId: params.householdId,
        idempotencyKey: params.reversalOperationId,
      );
      if (idemResult != null) {
        result = idemResult;
        return;
      }

      await _insertOp(
        OperationsCompanion.insert(
          id: params.reversalOperationId,
          householdId: params.householdId,
          type: OperationType.reversal.code,
          effectiveDate: params.effectiveDate,
          recordedAt: now,
          totalAmountMinorUnits: original.totalAmountMinorUnits,
          currencyCode: Value(original.currencyCode),
          createdBy: params.createdBy,
          createdAt: now,
          updatedAt: now,
          description: Value(
            params.reason ??
                'Reversal of operation ${params.originalOperationId}',
          ),
          sourceAccountId: Value(original.destinationAccountId),
          destinationAccountId: Value(original.sourceAccountId),
          idempotencyKey: Value(params.reversalOperationId),
        ),
      );

      for (final e in originalEntries) {
        final oppositeDirection = e.direction == LedgerDirection.credit.code
            ? LedgerDirection.debit.code
            : LedgerDirection.credit.code;
        final reversalEntryType = e.direction == LedgerDirection.credit.code
            ? LedgerEntryType.reversalDebit.code
            : LedgerEntryType.reversalCredit.code;

        await _insertEntry(
          LedgerEntriesCompanion.insert(
            id: '${params.reversalOperationId}_rev_${e.id}',
            operationId: params.reversalOperationId,
            householdId: params.householdId,
            accountId: e.accountId,
            direction: oppositeDirection,
            amountMinorUnits: e.amountMinorUnits,
            currencyCode: Value(e.currencyCode),
            entryType: reversalEntryType,
            effectiveDate: params.effectiveDate,
            recordedAt: now,
            createdBy: params.createdBy,
            isReversal: const Value(true),
            reversalOfEntryId: Value(e.id),
          ),
        );
      }

      // Mark the original operation as reversed. This is the ONLY permitted
      // mutation of an operations row after creation (INV-002).
      // The `restrict_operations_update` DB trigger enforces this restriction.
      await (_db.update(_db.operations)..where(
            (t) =>
                t.id.equals(params.originalOperationId) &
                t.householdId.equals(params.householdId),
          ))
          .write(
            OperationsCompanion(
              isReversed: const Value(true),
              reversedBy: Value(params.reversalOperationId),
              updatedAt: Value(now),
            ),
          );

      if (auditParams != null) {
        await _insertAudit(auditParams, now);
      }

      result = IdempotentOperationResult.created;
    });

    return result;
  }

  // ── Read operations ───────────────────────────────────────────────────────

  @override
  Future<List<LedgerEntry>> entriesForAccount({
    required String accountId,
    required String householdId,
  }) async {
    final rows =
        await (_db.select(_db.ledgerEntries)
              ..where(
                (t) =>
                    t.accountId.equals(accountId) &
                    t.householdId.equals(householdId),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.effectiveDate),
                (t) => OrderingTerm.asc(t.recordedAt),
                (t) => OrderingTerm.asc(t.id), // tie-breaker for INV-012
              ]))
            .get();
    return rows.map(_toLedgerEntry).toList();
  }

  @override
  Future<Operation?> findOperation({
    required String operationId,
    required String householdId,
  }) async {
    final row =
        await (_db.select(_db.operations)..where(
              (t) =>
                  t.id.equals(operationId) & t.householdId.equals(householdId),
            ))
            .getSingleOrNull();
    return row == null ? null : _toOperation(row);
  }

  @override
  Future<List<Operation>> operationsInRange({
    required String householdId,
    required String fromDate,
    required String toDate,
  }) async {
    final rows =
        await (_db.select(_db.operations)
              ..where(
                (t) =>
                    t.householdId.equals(householdId) &
                    t.effectiveDate.isBiggerOrEqualValue(fromDate) &
                    t.effectiveDate.isSmallerOrEqualValue(toDate),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.effectiveDate),
                (t) => OrderingTerm.asc(t.id), // tie-breaker for INV-012
              ]))
            .get();
    return rows.map(_toOperation).toList();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Checks idempotency atomically inside the current transaction.
  ///
  /// Returns:
  /// - `null` → no conflict; the caller should proceed with the insert.
  /// - [IdempotentOperationResult.alreadyExists] → exact retry (same operation
  ///   ID already stored).
  /// - [IdempotentOperationResult.conflict] → same idempotency key but a
  ///   different operation ID is already stored; caller error.
  ///
  /// This check must be called INSIDE a transaction so that the subsequent
  /// INSERT is atomic with the check (TOCTOU-safe).
  Future<IdempotentOperationResult?> _checkIdempotency({
    required String operationId,
    required String householdId,
    required String idempotencyKey,
  }) async {
    // Check 1: exact operation ID already exists → safe retry.
    final existingById =
        await (_db.select(_db.operations)..where(
              (t) =>
                  t.id.equals(operationId) & t.householdId.equals(householdId),
            ))
            .getSingleOrNull();
    if (existingById != null) return IdempotentOperationResult.alreadyExists;

    // Check 2: same scoped idempotency key but different operation ID → conflict.
    if (idempotencyKey != operationId) {
      final existingByKey =
          await (_db.select(_db.operations)..where(
                (t) =>
                    t.idempotencyKey.equals(idempotencyKey) &
                    t.householdId.equals(householdId),
              ))
              .getSingleOrNull();
      if (existingByKey != null) {
        return IdempotentOperationResult.conflict;
      }
    }

    return null; // proceed with insert
  }

  Future<FinancialAccount> _requireAccount(
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
    if (row.isArchived) throw ArchivedAccountError(accountId);
    return _rowToAccount(row);
  }

  Future<bool> _hasOpeningBalance(String accountId, String householdId) async {
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

  Future<void> _checkSufficientBalance(
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

  /// Validates a protected-withdrawal audit before inserting.
  ///
  /// Throws if [account.requiresWithdrawalAudit] is true and either:
  /// - [auditParams] is null → [MissingProtectedWithdrawalAuditError]
  /// - audit operation ID doesn't match → [AuditOperationMismatchError]
  /// - audit account ID doesn't match → [AuditAccountMismatchError]
  void _checkProtectedWithdrawal({
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

  Future<void> _insertOp(OperationsCompanion companion) async {
    await _db.into(_db.operations).insert(companion);
  }

  Future<void> _insertEntry(LedgerEntriesCompanion companion) async {
    await _db.into(_db.ledgerEntries).insert(companion);
  }

  Future<void> _insertAudit(
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

  // ── Mappers ───────────────────────────────────────────────────────────────

  LedgerEntry _toLedgerEntry(DbLedgerEntry row) => LedgerEntry(
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

  Operation _toOperation(DbOperation row) => Operation(
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
    createdBy: row.createdBy,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  FinancialAccount _rowToAccount(DbFinancialAccount row) => FinancialAccount(
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
