import 'package:drift/drift.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/sqlite_contention_policy.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/data/ledger_write_support.dart';
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
/// - Same `idempotency_key` + equivalent normalised payload →
///   [IdempotentOperationResult.alreadyExists] (safe retry, even with a new
///   client-generated operation ID)
/// - Same `idempotency_key` + conflicting payload →
///   [IdempotentOperationResult.conflict]
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
  DriftLedgerRepository(
    this._db, {
    Future<void> Function()? debugTransactionBarrier,
  }) : _debugTransactionBarrier = debugTransactionBarrier,
       _support = LedgerWriteSupport(_db);

  final AppDatabase _db;
  final LedgerWriteSupport _support;

  /// Test-only hook: awaited inside a write transaction after the idempotency
  /// check and before mutating inserts. Kept package-visible so production
  /// call sites (which omit the parameter) never see it. Never wire this from
  /// production DI.
  final Future<void> Function()? _debugTransactionBarrier;

  Future<void> _awaitDebugBarrier() async {
    final barrier = _debugTransactionBarrier;
    if (barrier != null) await barrier();
  }

  // ── Income ────────────────────────────────────────────────────────────────

  @override
  Future<IdempotentOperationResult> recordIncome(
    RecordIncomeParams params,
  ) async {
    // Validate account belongs to household before starting the transaction.
    await _support.requireActiveAccount(
      params.destinationAccountId,
      params.householdId,
    );

    final now = DateTime.now().toUtc().toIso8601String();
    late IdempotentOperationResult result;

    await _db.transaction(() async {
      final idemResult = await _support.checkOperationIdempotency(
        operationId: params.operationId,
        householdId: params.householdId,
        idempotencyKey: params.resolvedIdempotencyKey,
        expectedType: OperationType.income.code,
        expectedAmount: params.amountMinorUnits,
        expectedCurrency: params.currencyCode,
        expectedSourceAccountId: null,
        expectedDestinationAccountId: params.destinationAccountId,
      );
      if (idemResult != null) {
        result = idemResult;
        return;
      }

      await _awaitDebugBarrier();

      await _support.insertOp(
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

      await _support.insertEntry(
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

      await _support.insertContext(
        OperationContextsCompanion.insert(
          operationId: params.operationId,
          householdId: params.householdId,
          spenderMemberId: Value(params.spenderMemberId),
          beneficiaryMemberId: Value(params.beneficiaryMemberId),
          expenseScope: Value(params.scope?.code),
          isRecurring: Value(params.isRecurring),
          recurringNote: params.isRecurring
              ? const Value('recurring_marker_not_scheduled')
              : const Value.absent(),
          categoryCode: Value(params.categoryCode),
          note: Value(params.description),
          createdAt: now,
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
    final account = await _support.requireActiveAccount(
      params.sourceAccountId,
      params.householdId,
    );
    _support.checkProtectedWithdrawal(
      account: account,
      auditParams: auditParams,
      expectedOperationId: params.operationId,
      expectedHouseholdId: params.householdId,
    );

    final now = DateTime.now().toUtc().toIso8601String();
    final entryType = account.isChildProtectedFund
        ? LedgerEntryType.childFundWithdrawal
        : LedgerEntryType.expense;

    return runAuthoritativeWriteWithContentionRetry(() async {
      late IdempotentOperationResult result;
      try {
        await _db.transaction(() async {
          final idemResult = await _support.checkOperationIdempotency(
            operationId: params.operationId,
            householdId: params.householdId,
            idempotencyKey: params.resolvedIdempotencyKey,
            expectedType: account.isChildProtectedFund
                ? OperationType.childFundWithdrawal.code
                : OperationType.expense.code,
            expectedAmount: params.amountMinorUnits,
            expectedCurrency: params.currencyCode,
            expectedSourceAccountId: params.sourceAccountId,
            expectedDestinationAccountId: null,
          );
          if (idemResult != null) {
            result = idemResult;
            return;
          }

          await _awaitDebugBarrier();

          // Balance check inside the transaction (TOCTOU-safe under SQLite WAL).
          await _support.checkSufficientBalance(
            params.sourceAccountId,
            params.householdId,
            params.amountMinorUnits,
          );

          await _support.insertOp(
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

          await _support.insertEntry(
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
            await _support.insertAudit(auditParams, now);
          }

          await _support.insertContext(
            OperationContextsCompanion.insert(
              operationId: params.operationId,
              householdId: params.householdId,
              spenderMemberId: Value(params.spenderMemberId),
              beneficiaryMemberId: Value(params.beneficiaryMemberId),
              expenseScope: Value(params.scope?.code),
              isRecurring: Value(params.isRecurring),
              recurringNote: params.isRecurring
                  ? const Value('recurring_marker_not_scheduled')
                  : const Value.absent(),
              categoryCode: Value(params.categoryCode),
              note: Value(params.description),
              createdAt: now,
            ),
          );

          result = IdempotentOperationResult.created;
        });
      } on InsufficientFundsError {
        rethrow;
      } catch (e) {
        if (isNegativeBalanceAbort(e)) {
          throw InsufficientFundsError(
            accountId: params.sourceAccountId,
            availableMinorUnits: 0,
            requestedMinorUnits: params.amountMinorUnits,
          );
        }
        rethrow;
      }
      return result;
    });
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

    final source = await _support.requireActiveAccount(
      params.sourceAccountId,
      params.householdId,
    );
    final destination = await _support.requireActiveAccount(
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
    _support.checkProtectedWithdrawal(
      account: source,
      auditParams: auditParams,
      expectedOperationId: params.operationId,
      expectedHouseholdId: params.householdId,
    );

    final now = DateTime.now().toUtc().toIso8601String();

    return runAuthoritativeWriteWithContentionRetry(() async {
      late IdempotentOperationResult result;
      try {
        await _db.transaction(() async {
          final idemResult = await _support.checkOperationIdempotency(
            operationId: params.operationId,
            householdId: params.householdId,
            idempotencyKey: params.resolvedIdempotencyKey,
            expectedType: OperationType.transfer.code,
            expectedAmount: params.amountMinorUnits,
            expectedCurrency: params.currencyCode,
            expectedSourceAccountId: params.sourceAccountId,
            expectedDestinationAccountId: params.destinationAccountId,
          );
          if (idemResult != null) {
            result = idemResult;
            return;
          }

          await _awaitDebugBarrier();

          // Balance check inside the transaction (TOCTOU-safe under SQLite WAL).
          await _support.checkSufficientBalance(
            params.sourceAccountId,
            params.householdId,
            params.amountMinorUnits,
          );

          await _support.insertOp(
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

          await _support.insertEntry(
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

          await _support.insertEntry(
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
            await _support.insertAudit(auditParams, now);
          }

          await _support.insertContext(
            OperationContextsCompanion.insert(
              operationId: params.operationId,
              householdId: params.householdId,
              spenderMemberId: Value(params.spenderMemberId),
              beneficiaryMemberId: Value(params.beneficiaryMemberId),
              expenseScope: const Value.absent(),
              isRecurring: const Value(false),
              note: Value(params.description),
              createdAt: now,
            ),
          );

          result = IdempotentOperationResult.created;
        });
      } on InsufficientFundsError {
        rethrow;
      } catch (e) {
        if (isNegativeBalanceAbort(e)) {
          throw InsufficientFundsError(
            accountId: params.sourceAccountId,
            availableMinorUnits: 0,
            requestedMinorUnits: params.amountMinorUnits,
          );
        }
        rethrow;
      }
      return result;
    });
  }

  // ── Opening balance ───────────────────────────────────────────────────────

  @override
  Future<IdempotentOperationResult> recordOpeningBalance(
    RecordOpeningBalanceParams params,
  ) async {
    final acct = await _support.requireActiveAccount(
      params.accountId,
      params.householdId,
    );
    if (acct.type == FinancialAccountType.goalReserve) {
      throw ArgumentError(
        'Goal reserve accounts cannot receive opening balances. '
        'Account: ${params.accountId}',
      );
    }
    if (acct.type == FinancialAccountType.certificate) {
      throw ArgumentError(
        'Certificate accounts cannot receive opening balances. '
        'Account: ${params.accountId}',
      );
    }

    // Idempotency check: if this exact operation ID already exists → safe retry.
    final existing = await findOperation(
      operationId: params.operationId,
      householdId: params.householdId,
    );
    if (existing != null) return IdempotentOperationResult.alreadyExists;

    final alreadyHas = await _support.hasOpeningBalance(
      params.accountId,
      params.householdId,
    );
    if (alreadyHas) throw DuplicateOpeningBalanceError(params.accountId);

    final now = DateTime.now().toUtc().toIso8601String();
    late IdempotentOperationResult result;

    await _db.transaction(() async {
      final idemResult = await _support.checkOperationIdempotency(
        operationId: params.operationId,
        householdId: params.householdId,
        idempotencyKey: params.resolvedIdempotencyKey,
        expectedType: OperationType.openingBalance.code,
        expectedAmount: params.amountMinorUnits,
        expectedCurrency: params.currencyCode,
        expectedSourceAccountId: null,
        expectedDestinationAccountId: params.accountId,
      );
      if (idemResult != null) {
        result = idemResult;
        return;
      }

      await _awaitDebugBarrier();

      await _support.insertOp(
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
        await _support.insertEntry(
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

      await _support.insertContext(
        OperationContextsCompanion.insert(
          operationId: params.operationId,
          householdId: params.householdId,
          note: Value(params.description),
          createdAt: now,
        ),
      );

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
    final account = await _support.requireActiveAccount(
      params.accountId,
      params.householdId,
    );
    if (account.type == FinancialAccountType.goalReserve) {
      throw ArgumentError(
        'Goal reserve accounts cannot be adjusted directly. '
        'Account: ${params.accountId}',
      );
    }
    if (account.type == FinancialAccountType.certificate) {
      throw ArgumentError(
        'Certificate accounts cannot be adjusted directly. '
        'Account: ${params.accountId}',
      );
    }

    if (!params.isCredit) {
      _support.checkProtectedWithdrawal(
        account: account,
        auditParams: auditParams,
        expectedOperationId: params.operationId,
        expectedHouseholdId: params.householdId,
      );
    }

    final absAmount = params.adjustmentAmountMinorUnits.abs();
    final now = DateTime.now().toUtc().toIso8601String();

    return runAuthoritativeWriteWithContentionRetry(() async {
      late IdempotentOperationResult result;
      try {
        await _db.transaction(() async {
          final idemResult = await _support.checkOperationIdempotency(
            operationId: params.operationId,
            householdId: params.householdId,
            idempotencyKey: params.resolvedIdempotencyKey,
            expectedType: OperationType.adjustment.code,
            expectedAmount: absAmount,
            expectedCurrency: params.currencyCode,
            expectedSourceAccountId: params.isCredit ? null : params.accountId,
            expectedDestinationAccountId: params.isCredit
                ? params.accountId
                : null,
          );
          if (idemResult != null) {
            result = idemResult;
            return;
          }

          await _awaitDebugBarrier();

          // Debit adjustments must not drive the account negative (INV-005 /
          // Phase 6A.2). Check inside the IMMEDIATE write transaction; the
          // prevent_negative_account_balance trigger is the DB backstop.
          if (!params.isCredit) {
            await _support.checkSufficientBalance(
              params.accountId,
              params.householdId,
              absAmount,
            );
          }

          await _support.insertOp(
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

          await _support.insertEntry(
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
            await _support.insertAudit(auditParams, now);
          }

          await _support.insertContext(
            OperationContextsCompanion.insert(
              operationId: params.operationId,
              householdId: params.householdId,
              note: Value(params.reason),
              createdAt: now,
            ),
          );

          result = IdempotentOperationResult.created;
        });
      } on InsufficientFundsError {
        rethrow;
      } catch (e) {
        if (isNegativeBalanceAbort(e)) {
          throw InsufficientFundsError(
            accountId: params.accountId,
            availableMinorUnits: 0,
            requestedMinorUnits: absAmount,
          );
        }
        if (isRetryableSqliteContention(e)) rethrow;
        rethrow;
      }
      return result;
    });
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
    // REVERSAL EXCEPTION: Reversals are permitted on archived accounts
    // (append-only correction principle). Use loadAccount (no archived check).
    for (final entry in originalEntries) {
      if (entry.direction == LedgerDirection.credit.code) {
        final account = await _support.loadAccount(
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

    return runAuthoritativeWriteWithContentionRetry(() async {
      late IdempotentOperationResult result;
      try {
        await _db.transaction(() async {
          final idemResult = await _support.checkOperationIdempotency(
            operationId: params.reversalOperationId,
            householdId: params.householdId,
            idempotencyKey: params.reversalOperationId,
            expectedType: OperationType.reversal.code,
            expectedAmount: original.totalAmountMinorUnits,
            expectedCurrency: original.currencyCode,
            expectedSourceAccountId: original.destinationAccountId,
            expectedDestinationAccountId: original.sourceAccountId,
          );
          if (idemResult != null) {
            result = idemResult;
            return;
          }

          await _awaitDebugBarrier();

          // Debit legs of a reversal (mirroring original credits) must not
          // overdraft; check inside the IMMEDIATE writer txn.
          for (final e in originalEntries) {
            if (e.direction == LedgerDirection.credit.code) {
              await _support.checkSufficientBalance(
                e.accountId,
                params.householdId,
                e.amountMinorUnits,
              );
            }
          }

          await _support.insertOp(
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

            await _support.insertEntry(
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
            await _support.insertAudit(auditParams, now);
          }

          await _support.insertContext(
            OperationContextsCompanion.insert(
              operationId: params.reversalOperationId,
              householdId: params.householdId,
              note: Value(
                params.reason ??
                    'Reversal of operation ${params.originalOperationId}',
              ),
              createdAt: now,
            ),
          );

          result = IdempotentOperationResult.created;
        });
      } on InsufficientFundsError {
        rethrow;
      } catch (e) {
        if (isNegativeBalanceAbort(e)) {
          String accountId = params.originalOperationId;
          for (final entry in originalEntries) {
            if (entry.direction == LedgerDirection.credit.code) {
              accountId = entry.accountId;
              break;
            }
          }
          throw InsufficientFundsError(
            accountId: accountId,
            availableMinorUnits: 0,
            requestedMinorUnits: original.totalAmountMinorUnits,
          );
        }
        if (isRetryableSqliteContention(e)) rethrow;
        rethrow;
      }
      return result;
    });
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
    return rows.map(_support.toLedgerEntry).toList();
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
    return row == null ? null : _support.toOperation(row);
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
    return rows.map(_support.toOperation).toList();
  }
}
