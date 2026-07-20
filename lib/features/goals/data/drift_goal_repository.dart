import 'package:drift/drift.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/database/scoped_idempotency.dart';
import 'package:family_money_manager/core/database/sqlite_contention_policy.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/goals/application/complete_goal_params.dart';
import 'package:family_money_manager/features/goals/data/goal_repository.dart';
import 'package:family_money_manager/features/goals/data/goal_transfer_write_boundary.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart'
    show InsufficientFundsError;
import 'package:meta/meta.dart';

/// Drift-backed implementation of [GoalRepository].
///
/// KEY INVARIANTS:
/// - Goal reserve balance is NEVER stored as a column; [getReserveBalance]
///   derives it from [ledger_entries] using the same CREDIT/DEBIT sum used
///   everywhere else in the codebase.
/// - [createGoal] inserts the goal, initial revision, and reserve account
///   inside a single database transaction.
/// - Movements and revisions are append-only (no UPDATE or DELETE).
final class DriftGoalRepository implements GoalRepository {
  DriftGoalRepository(
    this._db, {
    @visibleForTesting
    GoalTransferFailAfter debugFailAfter = GoalTransferFailAfter.none,
    @visibleForTesting
    GoalLifecycleFailAfter debugLifecycleFailAfter =
        GoalLifecycleFailAfter.none,
    @visibleForTesting Future<void> Function()? debugTransactionBarrier,
  }) : _debugFailAfter = debugFailAfter,
       _debugLifecycleFailAfter = debugLifecycleFailAfter,
       _debugTransactionBarrier = debugTransactionBarrier;

  final AppDatabase _db;

  /// Test-only: throw [GoalTransferInjectedFailure] after the named step.
  final GoalTransferFailAfter _debugFailAfter;

  /// Test-only: throw [GoalLifecycleInjectedFailure] after the named step.
  final GoalLifecycleFailAfter _debugLifecycleFailAfter;

  /// Test-only: awaited inside the write transaction after idempotency check.
  final Future<void> Function()? _debugTransactionBarrier;

  // ── createGoal ────────────────────────────────────────────────────────────

  @override
  Future<AppResult<SavingsGoal>> createGoal({
    required SavingsGoal goal,
    required GoalRevision initialRevision,
    required FinancialAccount reserveAccount,
    GoalInitialFunding? initialFunding,
  }) async {
    final incomingPayload = _buildIdempotencyPayload(goal, initialRevision);

    // Captured inside the transaction closure and read after it commits.
    AppResult<SavingsGoal>? idempotencyResult;

    try {
      await _db.transaction(() async {
        // ── Step 1: Idempotency reservation (inside transaction) ─────────────
        // Checking inside the transaction makes the check+insert atomic under
        // SQLite WAL serialised writers: no TOCTOU window for concurrent callers.
        final existing = await _db
            .customSelect(
              'SELECT id, idempotency_payload FROM goals '
              'WHERE household_id = ? AND idempotency_key = ?',
              variables: [
                Variable.withString(goal.householdId),
                Variable.withString(goal.idempotencyKey),
              ],
            )
            .get();

        if (existing.isNotEmpty) {
          final row = existing.first;
          final storedPayload = row.read<String>('idempotency_payload');
          if (storedPayload == incomingPayload) {
            final existingId = row.read<String>('id');
            final found = await _findById(existingId);
            idempotencyResult = found != null
                ? AppOk(found)
                : const AppPersistenceFailure();
          } else {
            idempotencyResult = const AppDuplicateConflict(
              messageKey: 'errorGoalIdempotencyConflict',
            );
          }
          return; // Exit transaction cleanly; only reads occurred.
        }

        // ── Step 2: Insert the goalReserve financial account ─────────────────
        await _db
            .into(_db.financialAccounts)
            .insert(
              FinancialAccountsCompanion.insert(
                id: reserveAccount.id,
                householdId: reserveAccount.householdId,
                name: reserveAccount.name,
                type: reserveAccount.type.code,
                ownerType: reserveAccount.ownerType.code,
                fundPurpose: Value(reserveAccount.fundPurpose.code),
                currencyCode: Value(reserveAccount.currencyCode),
                isSpendable: Value(reserveAccount.isSpendable),
                isProtected: Value(reserveAccount.isProtected),
                includeInNetWorth: Value(reserveAccount.includeInNetWorth),
                includeInZakat: Value(reserveAccount.includeInZakat),
                displayOrder: Value(reserveAccount.displayOrder),
                createdBy: reserveAccount.createdBy,
                createdAt: reserveAccount.createdAt,
                updatedAt: reserveAccount.updatedAt,
              ),
            );

        // ── Step 3: Insert the goal row ───────────────────────────────────────
        await _db
            .into(_db.goalsTable)
            .insert(
              GoalsTableCompanion.insert(
                id: goal.id,
                householdId: goal.householdId,
                reserveAccountId: goal.reserveAccountId,
                currencyCode: goal.currencyCode,
                status: goal.status.name,
                idempotencyKey: goal.idempotencyKey,
                idempotencyPayload: incomingPayload,
                createdAt: goal.createdAt,
                completedAt: Value(goal.completedAt),
                archivedAt: Value(goal.archivedAt),
                earlyCompletionReason: Value(goal.earlyCompletionReason),
              ),
            );

        // ── Step 4: Insert the initial revision ───────────────────────────────
        await _db
            .into(_db.goalRevisionsTable)
            .insert(
              GoalRevisionsTableCompanion.insert(
                id: initialRevision.id,
                goalId: initialRevision.goalId,
                householdId: initialRevision.householdId,
                name: initialRevision.name,
                purposeCode: initialRevision.purpose.code,
                targetMinorUnits: initialRevision.targetMinorUnits,
                currencyCode: initialRevision.currencyCode,
                createdAt: initialRevision.createdAt,
                revisionReason: initialRevision.revisionReason,
                targetDate: Value(initialRevision.targetDate),
                beneficiaryMemberId: Value(initialRevision.beneficiaryMemberId),
              ),
            );

        // ── Steps 5+: Optional initial funding via unified transfer boundary ───
        if (initialFunding != null && initialFunding.amountMinorUnits > 0) {
          final fundResult = await _runGoalAssociatedTransferSteps(
            GoalAssociatedTransferParams.funding(
              goalId: goal.id,
              householdId: goal.householdId,
              operationId: initialFunding.operationId,
              idempotencyKey: initialFunding.idempotencyKey,
              sourceAccountId: initialFunding.sourceAccountId,
              destinationAccountId: reserveAccount.id,
              amountMinorUnits: initialFunding.amountMinorUnits,
              currencyCode: initialFunding.currencyCode,
              effectiveDate: initialFunding.effectiveDate,
              createdBy: 'system',
              description: initialFunding.description,
              movementId: initialFunding.movementId,
              movementCreatedAt: initialFunding.movementCreatedAt,
            ),
          );
          if (fundResult is AppDuplicateConflict<GoalTransferWriteResult>) {
            idempotencyResult = AppDuplicateConflict(
              messageKey: fundResult.messageKey,
            );
            return;
          }
          if (fundResult is! AppOk<GoalTransferWriteResult>) {
            // Must throw Exception (not Error) so the outer catch rolls back.
            throw Exception('initial funding failed: $fundResult');
          }
        }
      });

      if (idempotencyResult != null) return idempotencyResult!;
      return AppOk(goal);
    } on InsufficientFundsError {
      return const AppInsufficientFunds();
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  // ── findGoalById ──────────────────────────────────────────────────────────

  @override
  Future<AppResult<SavingsGoal?>> findGoalById(String goalId) async {
    try {
      final found = await _findById(goalId);
      return AppOk(found);
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  // ── listGoals ─────────────────────────────────────────────────────────────

  @override
  Future<AppResult<List<SavingsGoal>>> listGoals({
    required String householdId,
    bool includeArchived = false,
  }) async {
    try {
      final rows = await _db
          .customSelect(
            includeArchived
                ? 'SELECT id FROM goals WHERE household_id = ? ORDER BY created_at ASC'
                : "SELECT id FROM goals WHERE household_id = ? AND status != 'archived' ORDER BY created_at ASC",
            variables: [Variable.withString(householdId)],
          )
          .get();

      final goals = <SavingsGoal>[];
      for (final row in rows) {
        final g = await _findById(row.read<String>('id'));
        if (g != null) goals.add(g);
      }
      return AppOk(goals);
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  // ── updateGoalStatus ──────────────────────────────────────────────────────

  @override
  Future<AppResult<void>> updateGoalStatus({
    required String goalId,
    required GoalStatus status,
    String? completedAt,
    String? archivedAt,
  }) async {
    // Phase 5B.8: no direct status writes. Lifecycle uses typed workflows;
    // progress is ledger-derived and never persisted on goals.status.
    return const AppValidationFailure(
      field: 'status',
      messageKey: 'errorGoalLifecycleRequiresTypedWorkflow',
    );
  }

  // ── completeGoal (atomic) ─────────────────────────────────────────────────

  @override
  Future<AppResult<SavingsGoal>> completeGoal(CompleteGoalParams params) async {
    final scopedKey = 'complete-${params.idempotencyKey}';
    final completionType = params.earlyCompletion ? 'early' : 'normal';
    final normalizedReason = params.earlyCompletion
        ? (params.earlyCompletionReason?.trim() ?? '')
        : '';
    final incomingPayload = _completionPayloadFingerprint(
      goalId: params.goalId,
      householdId: params.householdId,
      completionType: completionType,
      earlyCompletionConfirmed: params.earlyCompletionConfirmed,
      earlyCompletionReason: normalizedReason,
      actorMetadata: params.actorMetadata,
    );

    try {
      late AppResult<SavingsGoal> result;
      await _db.transaction(() async {
        result = await _runCompleteGoalSteps(
          params: params,
          scopedKey: scopedKey,
          completionType: completionType,
          normalizedReason: normalizedReason,
          incomingPayload: incomingPayload,
        );
      });
      return result;
    } on GoalLifecycleInjectedFailure {
      return const AppPersistenceFailure();
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  Future<AppResult<SavingsGoal>> _runCompleteGoalSteps({
    required CompleteGoalParams params,
    required String scopedKey,
    required String completionType,
    required String normalizedReason,
    required String incomingPayload,
  }) async {
    // 1–2. Completion idempotency lookup + payload equivalence/conflict
    final existingEvents = await _db
        .customSelect(
          'SELECT * FROM goal_lifecycle_events '
          'WHERE household_id = ? AND idempotency_key = ?',
          variables: [
            Variable.withString(params.householdId),
            Variable.withString(scopedKey),
          ],
        )
        .get();
    if (existingEvents.isNotEmpty) {
      final row = existingEvents.first;
      final stored = _completionPayloadFromLifecycleRow(row);
      if (stored == incomingPayload) {
        final found = await _findById(params.goalId);
        if (found == null) return const AppPersistenceFailure();
        return AppOk(found);
      }
      return const AppDuplicateConflict(
        messageKey: 'errorGoalIdempotencyConflict',
      );
    }

    // 3–5. Goal lookup, household validation, current lifecycle validation
    final goalRows = await _db
        .customSelect(
          'SELECT * FROM goals WHERE id = ?',
          variables: [Variable.withString(params.goalId)],
        )
        .get();
    if (goalRows.isEmpty) return const AppNotFound();
    final goalRow = goalRows.first;
    final householdId = goalRow.read<String>('household_id');
    if (householdId != params.householdId) return const AppNotFound();

    final statusCode = goalRow.read<String>('status');
    final status = _statusFromCode(statusCode);

    if (status == GoalStatus.archived) {
      return const AppValidationFailure(
        field: 'goalId',
        messageKey: 'errorGoalArchived',
      );
    }

    if (status == GoalStatus.completed) {
      // Already completed without this key — compare against original event.
      final completedEvents = await _db
          .customSelect(
            "SELECT * FROM goal_lifecycle_events "
            "WHERE goal_id = ? AND household_id = ? AND event_type = 'completed' "
            'ORDER BY created_at ASC LIMIT 1',
            variables: [
              Variable.withString(params.goalId),
              Variable.withString(params.householdId),
            ],
          )
          .get();
      if (completedEvents.isEmpty) {
        // Fallback to columns on the goal row.
        final storedType =
            (goalRow.readNullable<String>('early_completion_reason') != null &&
                (goalRow.readNullable<String>('early_completion_reason') ?? '')
                    .isNotEmpty)
            ? 'early'
            : 'normal';
        final storedReason =
            goalRow.readNullable<String>('early_completion_reason')?.trim() ??
            '';
        final storedPayload = _completionPayloadFingerprint(
          goalId: params.goalId,
          householdId: params.householdId,
          completionType: storedType,
          earlyCompletionConfirmed: storedType == 'early',
          earlyCompletionReason: storedReason,
          actorMetadata: null,
        );
        if (storedPayload == incomingPayload) {
          final found = await _findById(params.goalId);
          if (found == null) return const AppPersistenceFailure();
          return AppOk(found);
        }
        return const AppDuplicateConflict(
          messageKey: 'errorGoalIdempotencyConflict',
        );
      }
      final stored = _completionPayloadFromLifecycleRow(completedEvents.first);
      if (stored == incomingPayload) {
        final found = await _findById(params.goalId);
        if (found == null) return const AppPersistenceFailure();
        return AppOk(found);
      }
      return const AppDuplicateConflict(
        messageKey: 'errorGoalIdempotencyConflict',
      );
    }

    await _lifecycleFailAfter(GoalLifecycleFailAfter.afterGoalValidation);

    // 6–8. Reserve balance + target / early completion checks
    final reserveAccountId = goalRow.read<String>('reserve_account_id');
    final targetRows = await _db
        .customSelect(
          'SELECT target_minor_units FROM goal_revisions '
          'WHERE goal_id = ? ORDER BY created_at DESC, id DESC LIMIT 1',
          variables: [Variable.withString(params.goalId)],
        )
        .get();
    if (targetRows.isEmpty) return const AppPersistenceFailure();
    final target = targetRows.first.read<int>('target_minor_units');

    final balanceRows = await _db
        .customSelect(
          'SELECT COALESCE(SUM(CASE WHEN direction = ? THEN amount_minor_units '
          'ELSE -amount_minor_units END), 0) AS bal '
          'FROM ledger_entries WHERE account_id = ? AND household_id = ?',
          variables: [
            Variable.withString(LedgerDirection.credit.code),
            Variable.withString(reserveAccountId),
            Variable.withString(params.householdId),
          ],
        )
        .get();
    final balance = balanceRows.first.read<int>('bal');
    await _lifecycleFailAfter(GoalLifecycleFailAfter.afterBalanceCalculation);

    if (params.earlyCompletion) {
      if (!params.earlyCompletionConfirmed) {
        return const AppValidationFailure(
          field: 'earlyCompletionConfirmed',
          messageKey: 'errorEarlyCompletionConfirmationRequired',
        );
      }
      if (normalizedReason.isEmpty) {
        return const AppValidationFailure(
          field: 'earlyCompletionReason',
          messageKey: 'errorEarlyCompletionReasonRequired',
        );
      }
    } else {
      if (balance < target) {
        return const AppValidationFailure(
          field: 'balance',
          messageKey: 'errorGoalNormalCompletionRequiresTarget',
        );
      }
    }

    final now = DateTime.now().toUtc().toIso8601String();

    // 9. Goal status update
    await _db.customStatement(
      "UPDATE goals SET status = 'completed' WHERE id = ? AND household_id = ?",
      [params.goalId, params.householdId],
    );
    await _lifecycleFailAfter(GoalLifecycleFailAfter.afterGoalStatusUpdate);

    // 10. Completion timestamp (+ early reason) update
    await _db.customStatement(
      'UPDATE goals SET completed_at = ?, early_completion_reason = ? '
      'WHERE id = ? AND household_id = ?',
      [
        now,
        params.earlyCompletion ? normalizedReason : null,
        params.goalId,
        params.householdId,
      ],
    );
    await _lifecycleFailAfter(
      GoalLifecycleFailAfter.afterCompletionTimestampUpdate,
    );

    // 11. Immutable lifecycle-event insertion
    final eventId =
        '${params.goalId}-lce-complete-${now.replaceAll(':', '').replaceAll('.', '')}';
    await _db.customStatement(
      'INSERT INTO goal_lifecycle_events '
      '(id, goal_id, household_id, event_type, completion_type, '
      'early_completion_reason, early_completion_confirmed, '
      'idempotency_key, actor_metadata, effective_at, created_at, schema_version) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 15)',
      [
        eventId,
        params.goalId,
        params.householdId,
        GoalLifecycleEventType.completed.code,
        completionType,
        params.earlyCompletion ? normalizedReason : null,
        params.earlyCompletionConfirmed ? 1 : 0,
        scopedKey,
        params.actorMetadata,
        now,
        now,
      ],
    );
    await _lifecycleFailAfter(
      GoalLifecycleFailAfter.afterLifecycleEventInsertion,
    );

    // 12. Final pre-commit boundary
    await _lifecycleFailAfter(GoalLifecycleFailAfter.preCommit);

    final found = await _findById(params.goalId);
    if (found == null) return const AppPersistenceFailure();
    return AppOk(found);
  }

  String _completionPayloadFingerprint({
    required String goalId,
    required String householdId,
    required String completionType,
    required bool earlyCompletionConfirmed,
    required String earlyCompletionReason,
    required String? actorMetadata,
  }) =>
      'goal=$goalId|hh=$householdId|type=$completionType|'
      'confirmed=$earlyCompletionConfirmed|'
      'reason=$earlyCompletionReason|'
      'actor=${actorMetadata ?? ''}';

  String _completionPayloadFromLifecycleRow(QueryRow row) =>
      _completionPayloadFingerprint(
        goalId: row.read<String>('goal_id'),
        householdId: row.read<String>('household_id'),
        completionType: row.readNullable<String>('completion_type') ?? '',
        earlyCompletionConfirmed:
            row.read<int>('early_completion_confirmed') == 1,
        earlyCompletionReason:
            row.readNullable<String>('early_completion_reason')?.trim() ?? '',
        actorMetadata: row.readNullable<String>('actor_metadata'),
      );

  // ── archiveGoal (atomic) ──────────────────────────────────────────────────

  @override
  Future<AppResult<void>> archiveGoal({
    required String goalId,
    required String householdId,
    String? idempotencyKey,
  }) async {
    final scopedKey = idempotencyKey ?? 'archive-$goalId';
    try {
      late AppResult<void> result;
      await _db.transaction(() async {
        result = await _runArchiveGoalSteps(
          goalId: goalId,
          householdId: householdId,
          scopedKey: scopedKey,
        );
      });
      return result;
    } on GoalLifecycleInjectedFailure {
      return const AppPersistenceFailure();
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  Future<AppResult<void>> _runArchiveGoalSteps({
    required String goalId,
    required String householdId,
    required String scopedKey,
  }) async {
    final existing = await _db
        .customSelect(
          'SELECT id FROM goal_lifecycle_events '
          'WHERE household_id = ? AND idempotency_key = ?',
          variables: [
            Variable.withString(householdId),
            Variable.withString(scopedKey),
          ],
        )
        .get();
    if (existing.isNotEmpty) {
      final goal = await _findById(goalId);
      if (goal != null && goal.status == GoalStatus.archived) {
        return const AppOk(null);
      }
      return const AppDuplicateConflict(
        messageKey: 'errorGoalIdempotencyConflict',
      );
    }

    final goalRows = await _db
        .customSelect(
          'SELECT id, household_id, reserve_account_id, status FROM goals '
          'WHERE id = ?',
          variables: [Variable.withString(goalId)],
        )
        .get();
    if (goalRows.isEmpty) return const AppNotFound();
    final goalRow = goalRows.first;
    if (goalRow.read<String>('household_id') != householdId) {
      return const AppNotFound();
    }
    final status = _statusFromCode(goalRow.read<String>('status'));
    if (status == GoalStatus.archived) return const AppOk(null);

    await _lifecycleFailAfter(GoalLifecycleFailAfter.afterGoalValidation);

    final reserveAccountId = goalRow.read<String>('reserve_account_id');
    final balanceRows = await _db
        .customSelect(
          'SELECT COALESCE(SUM(CASE WHEN direction = ? THEN amount_minor_units '
          'ELSE -amount_minor_units END), 0) AS bal '
          'FROM ledger_entries WHERE account_id = ? AND household_id = ?',
          variables: [
            Variable.withString(LedgerDirection.credit.code),
            Variable.withString(reserveAccountId),
            Variable.withString(householdId),
          ],
        )
        .get();
    final balance = balanceRows.first.read<int>('bal');
    await _lifecycleFailAfter(GoalLifecycleFailAfter.afterBalanceCalculation);

    if (balance != 0) {
      return const AppValidationFailure(
        field: 'balance',
        messageKey: 'errorGoalArchiveNonzeroBalance',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();

    await _db.customStatement(
      "UPDATE goals SET status = 'archived' WHERE id = ? AND household_id = ?",
      [goalId, householdId],
    );
    await _lifecycleFailAfter(GoalLifecycleFailAfter.afterGoalStatusUpdate);

    await _db.customStatement(
      'UPDATE goals SET archived_at = ? WHERE id = ? AND household_id = ?',
      [now, goalId, householdId],
    );
    await _lifecycleFailAfter(
      GoalLifecycleFailAfter.afterCompletionTimestampUpdate,
    );

    await _db.customStatement(
      'INSERT INTO goal_lifecycle_events '
      '(id, goal_id, household_id, event_type, completion_type, '
      'early_completion_reason, early_completion_confirmed, '
      'idempotency_key, actor_metadata, effective_at, created_at, schema_version) '
      'VALUES (?, ?, ?, ?, NULL, NULL, 0, ?, NULL, ?, ?, 15)',
      [
        '$goalId-lce-archive-${now.replaceAll(':', '').replaceAll('.', '')}',
        goalId,
        householdId,
        GoalLifecycleEventType.archived.code,
        scopedKey,
        now,
        now,
      ],
    );
    await _lifecycleFailAfter(
      GoalLifecycleFailAfter.afterLifecycleEventInsertion,
    );
    await _lifecycleFailAfter(GoalLifecycleFailAfter.preCommit);
    return const AppOk(null);
  }

  // ── restoreGoal (atomic) ──────────────────────────────────────────────────

  @override
  Future<AppResult<void>> restoreGoal({
    required String goalId,
    required String householdId,
    String? idempotencyKey,
  }) async {
    final scopedKey = idempotencyKey ?? 'restore-$goalId';
    try {
      late AppResult<void> result;
      await _db.transaction(() async {
        result = await _runRestoreGoalSteps(
          goalId: goalId,
          householdId: householdId,
          scopedKey: scopedKey,
        );
      });
      return result;
    } on GoalLifecycleInjectedFailure {
      return const AppPersistenceFailure();
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  Future<AppResult<void>> _runRestoreGoalSteps({
    required String goalId,
    required String householdId,
    required String scopedKey,
  }) async {
    final existing = await _db
        .customSelect(
          'SELECT id FROM goal_lifecycle_events '
          'WHERE household_id = ? AND idempotency_key = ?',
          variables: [
            Variable.withString(householdId),
            Variable.withString(scopedKey),
          ],
        )
        .get();
    if (existing.isNotEmpty) {
      final goal = await _findById(goalId);
      if (goal != null && goal.status == GoalStatus.active) {
        return const AppOk(null);
      }
      return const AppDuplicateConflict(
        messageKey: 'errorGoalIdempotencyConflict',
      );
    }

    final goalRows = await _db
        .customSelect(
          'SELECT id, household_id, status FROM goals WHERE id = ?',
          variables: [Variable.withString(goalId)],
        )
        .get();
    if (goalRows.isEmpty) return const AppNotFound();
    final goalRow = goalRows.first;
    if (goalRow.read<String>('household_id') != householdId) {
      return const AppNotFound();
    }
    final status = _statusFromCode(goalRow.read<String>('status'));
    if (status != GoalStatus.archived) {
      return const AppValidationFailure(
        field: 'goalId',
        messageKey: 'errorGoalRestoreRequiresArchived',
      );
    }

    await _lifecycleFailAfter(GoalLifecycleFailAfter.afterGoalValidation);
    // Balance calc not required for restore; honour fail-after slot for matrix.
    await _lifecycleFailAfter(GoalLifecycleFailAfter.afterBalanceCalculation);

    final now = DateTime.now().toUtc().toIso8601String();

    await _db.customStatement(
      "UPDATE goals SET status = 'active' WHERE id = ? AND household_id = ?",
      [goalId, householdId],
    );
    await _lifecycleFailAfter(GoalLifecycleFailAfter.afterGoalStatusUpdate);

    await _db.customStatement(
      'UPDATE goals SET archived_at = NULL WHERE id = ? AND household_id = ?',
      [goalId, householdId],
    );
    await _lifecycleFailAfter(
      GoalLifecycleFailAfter.afterCompletionTimestampUpdate,
    );

    await _db.customStatement(
      'INSERT INTO goal_lifecycle_events '
      '(id, goal_id, household_id, event_type, completion_type, '
      'early_completion_reason, early_completion_confirmed, '
      'idempotency_key, actor_metadata, effective_at, created_at, schema_version) '
      'VALUES (?, ?, ?, ?, NULL, NULL, 0, ?, NULL, ?, ?, 15)',
      [
        '$goalId-lce-restore-${now.replaceAll(':', '').replaceAll('.', '')}',
        goalId,
        householdId,
        GoalLifecycleEventType.restored.code,
        scopedKey,
        now,
        now,
      ],
    );
    await _lifecycleFailAfter(
      GoalLifecycleFailAfter.afterLifecycleEventInsertion,
    );
    await _lifecycleFailAfter(GoalLifecycleFailAfter.preCommit);
    return const AppOk(null);
  }

  Future<void> _lifecycleFailAfter(GoalLifecycleFailAfter step) async {
    if (_debugLifecycleFailAfter == step) {
      throw GoalLifecycleInjectedFailure(step);
    }
  }

  // ── addRevision ───────────────────────────────────────────────────────────

  @override
  Future<AppResult<void>> addRevision(GoalRevision revision) async {
    try {
      await _db
          .into(_db.goalRevisionsTable)
          .insert(
            GoalRevisionsTableCompanion.insert(
              id: revision.id,
              goalId: revision.goalId,
              householdId: revision.householdId,
              name: revision.name,
              purposeCode: revision.purpose.code,
              targetMinorUnits: revision.targetMinorUnits,
              currencyCode: revision.currencyCode,
              createdAt: revision.createdAt,
              revisionReason: revision.revisionReason,
              targetDate: Value(revision.targetDate),
              beneficiaryMemberId: Value(revision.beneficiaryMemberId),
            ),
          );
      return const AppOk(null);
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  // ── getRevisions ──────────────────────────────────────────────────────────

  @override
  Future<AppResult<List<GoalRevision>>> getRevisions(String goalId) async {
    try {
      final rows =
          await (_db.select(_db.goalRevisionsTable)
                ..where((t) => t.goalId.equals(goalId))
                ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
              .get();
      return AppOk(rows.map(_toRevision).toList());
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  // ── addMovement ───────────────────────────────────────────────────────────

  @override
  Future<AppResult<void>> addMovement(GoalMovement movement) async {
    try {
      if (movement.movementType == GoalMovementType.reversal) {
        // Reversal movements include reversal_of_movement_id — use raw SQL
        // since the companion does not expose this column in older migrations.
        await _db.customStatement(
          'INSERT INTO goal_movements '
          '(id, goal_id, household_id, transfer_operation_id, movement_type, '
          'created_at, release_reason, reversal_of_movement_id) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            movement.id,
            movement.goalId,
            movement.householdId,
            movement.transferOperationId,
            'reversal',
            movement.createdAt,
            movement.releaseReason,
            movement.reversalOfMovementId,
          ],
        );
      } else {
        await _db
            .into(_db.goalMovementsTable)
            .insert(
              GoalMovementsTableCompanion.insert(
                id: movement.id,
                goalId: movement.goalId,
                householdId: movement.householdId,
                transferOperationId: movement.transferOperationId,
                movementType: movement.movementType.name,
                createdAt: movement.createdAt,
                releaseReason: Value(movement.releaseReason),
              ),
            );
      }
      return const AppOk(null);
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  // ── getMovements ──────────────────────────────────────────────────────────

  @override
  Future<AppResult<List<GoalMovement>>> getMovements(String goalId) async {
    try {
      final rows =
          await (_db.select(_db.goalMovementsTable)
                ..where((t) => t.goalId.equals(goalId))
                ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
              .get();
      return AppOk(rows.map(_toMovement).toList());
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  // ── getReserveBalance ─────────────────────────────────────────────────────
  //
  // Derives balance exactly like DriftLedgerRepository._checkSufficientBalance:
  // SUM of credit entries minus SUM of debit entries on the reserve account.
  // This is the canonical single-source-of-truth balance; it is never stored.

  @override
  Future<AppResult<int>> getReserveBalance({
    required String reserveAccountId,
    required String householdId,
  }) async {
    try {
      final entries = await _db
          .customSelect(
            'SELECT direction, amount_minor_units FROM ledger_entries '
            'WHERE account_id = ? AND household_id = ?',
            variables: [
              Variable.withString(reserveAccountId),
              Variable.withString(householdId),
            ],
          )
          .get();

      var balance = 0;
      for (final e in entries) {
        final direction = e.read<String>('direction');
        final amount = e.read<int>('amount_minor_units');
        if (direction == 'credit') {
          balance += amount;
        } else {
          balance -= amount;
        }
      }
      return AppOk(balance);
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Loads a [SavingsGoal] with its current (latest) revision.
  Future<SavingsGoal?> _findById(String goalId) async {
    final goalRows = await _db
        .customSelect(
          'SELECT * FROM goals WHERE id = ?',
          variables: [Variable.withString(goalId)],
        )
        .get();
    if (goalRows.isEmpty) return null;
    final g = goalRows.first;

    // Load the most recent revision (by created_at DESC, then id DESC as tie-breaker).
    final revRows = await _db
        .customSelect(
          'SELECT * FROM goal_revisions WHERE goal_id = ? ORDER BY created_at DESC, id DESC LIMIT 1',
          variables: [Variable.withString(goalId)],
        )
        .get();
    if (revRows.isEmpty) return null;
    final rev = revRows.first;

    final revision = GoalRevision(
      id: rev.read<String>('id'),
      goalId: rev.read<String>('goal_id'),
      householdId: rev.read<String>('household_id'),
      name: rev.read<String>('name'),
      purpose: _purposeFromCode(rev.read<String>('purpose_code')),
      targetMinorUnits: rev.read<int>('target_minor_units'),
      currencyCode: rev.read<String>('currency_code'),
      createdAt: rev.read<String>('created_at'),
      revisionReason: rev.read<String>('revision_reason'),
      targetDate: rev.readNullable<String>('target_date'),
      beneficiaryMemberId: rev.readNullable<String>('beneficiary_member_id'),
    );

    return SavingsGoal(
      id: g.read<String>('id'),
      householdId: g.read<String>('household_id'),
      reserveAccountId: g.read<String>('reserve_account_id'),
      currencyCode: g.read<String>('currency_code'),
      status: _statusFromCode(g.read<String>('status')),
      currentRevision: revision,
      createdAt: g.read<String>('created_at'),
      idempotencyKey: g.read<String>('idempotency_key'),
      completedAt: g.readNullable<String>('completed_at'),
      archivedAt: g.readNullable<String>('archived_at'),
      earlyCompletionReason: g.readNullable<String>('early_completion_reason'),
    );
  }

  GoalRevision _toRevision(DbGoalRevision row) => GoalRevision(
    id: row.id,
    goalId: row.goalId,
    householdId: row.householdId,
    name: row.name,
    purpose: _purposeFromCode(row.purposeCode),
    targetMinorUnits: row.targetMinorUnits,
    currencyCode: row.currencyCode,
    createdAt: row.createdAt,
    revisionReason: row.revisionReason,
    targetDate: row.targetDate,
    beneficiaryMemberId: row.beneficiaryMemberId,
  );

  GoalMovement _toMovement(DbGoalMovement row) => GoalMovement(
    id: row.id,
    goalId: row.goalId,
    householdId: row.householdId,
    transferOperationId: row.transferOperationId,
    movementType: switch (row.movementType) {
      'funding' => GoalMovementType.funding,
      'reversal' => GoalMovementType.reversal,
      _ => GoalMovementType.release,
    },
    createdAt: row.createdAt,
    releaseReason: row.releaseReason,
    reversalOfMovementId: row.reversalOfMovementId,
  );

  GoalStatus _statusFromCode(String code) => switch (code) {
    'active' => GoalStatus.active,
    // Legacy pre-5B.8 value migrated to active; treat as active if seen.
    'targetReached' => GoalStatus.active,
    'completed' => GoalStatus.completed,
    'archived' => GoalStatus.archived,
    _ => GoalStatus.active,
  };

  GoalPurpose _purposeFromCode(String code) {
    for (final p in GoalPurpose.values) {
      if (p.code == code) return p;
    }
    return GoalPurpose.other;
  }

  /// Builds a deterministic idempotency payload string.
  String _buildIdempotencyPayload(SavingsGoal goal, GoalRevision revision) =>
      'hh=${goal.householdId}|name=${revision.name}|'
      'cur=${goal.currencyCode}|target=${revision.targetMinorUnits}|'
      'purpose=${revision.purpose.code}';

  // ── insertLifecycleEvent ──────────────────────────────────────────────────

  @override
  Future<AppResult<GoalLifecycleEvent>> insertLifecycleEvent(
    GoalLifecycleEvent event,
  ) async {
    try {
      final incomingFingerprint = _lifecyclePayloadFingerprint(event);

      // Idempotency: household-scoped key + payload fingerprint.
      if (event.idempotencyKey != null) {
        final existing = await _db
            .customSelect(
              'SELECT * FROM goal_lifecycle_events '
              'WHERE household_id = ? AND idempotency_key = ?',
              variables: [
                Variable.withString(event.householdId),
                Variable.withString(event.idempotencyKey!),
              ],
            )
            .get();
        if (existing.isNotEmpty) {
          final row = existing.first;
          final storedFingerprint = _lifecyclePayloadFingerprintFromRow(row);
          if (storedFingerprint == incomingFingerprint) {
            return AppOk(_rowToLifecycleEvent(row));
          }
          return const AppDuplicateConflict(
            messageKey: 'errorLifecycleEventConflict',
          );
        }
      }

      await _db.customStatement(
        'INSERT INTO goal_lifecycle_events '
        '(id, goal_id, household_id, event_type, completion_type, '
        'early_completion_reason, early_completion_confirmed, '
        'idempotency_key, actor_metadata, effective_at, created_at, schema_version) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 15)',
        [
          event.id,
          event.goalId,
          event.householdId,
          event.eventType.code,
          event.completionType,
          event.earlyCompletionReason,
          event.earlyCompletionConfirmed ? 1 : 0,
          event.idempotencyKey,
          event.actorMetadata,
          event.effectiveAt,
          event.createdAt,
        ],
      );
      return AppOk(event);
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  String _lifecyclePayloadFingerprint(GoalLifecycleEvent event) =>
      'type=${event.eventType.code}|'
      'completion=${event.completionType ?? ''}|'
      'reason=${event.earlyCompletionReason ?? ''}|'
      'confirmed=${event.earlyCompletionConfirmed}|'
      'goal=${event.goalId}';

  String _lifecyclePayloadFingerprintFromRow(QueryRow row) =>
      'type=${row.read<String>('event_type')}|'
      'completion=${row.readNullable<String>('completion_type') ?? ''}|'
      'reason=${row.readNullable<String>('early_completion_reason') ?? ''}|'
      'confirmed=${row.read<int>('early_completion_confirmed') == 1}|'
      'goal=${row.read<String>('goal_id')}';

  // ── findMovementByOperationId ─────────────────────────────────────────────

  @override
  Future<AppResult<GoalMovement?>> findMovementByOperationId(
    String transferOperationId,
  ) async {
    try {
      final rows = await _db
          .customSelect(
            'SELECT * FROM goal_movements WHERE transfer_operation_id = ? LIMIT 1',
            variables: [Variable.withString(transferOperationId)],
          )
          .get();
      if (rows.isEmpty) return const AppOk(null);
      final row = rows.first;
      return AppOk(
        GoalMovement(
          id: row.read<String>('id'),
          goalId: row.read<String>('goal_id'),
          householdId: row.read<String>('household_id'),
          transferOperationId: row.read<String>('transfer_operation_id'),
          movementType: switch (row.read<String>('movement_type')) {
            'funding' => GoalMovementType.funding,
            'reversal' => GoalMovementType.reversal,
            _ => GoalMovementType.release,
          },
          createdAt: row.read<String>('created_at'),
          releaseReason: row.readNullable<String>('release_reason'),
          reversalOfMovementId: row.readNullable<String>(
            'reversal_of_movement_id',
          ),
        ),
      );
    } on Exception catch (_) {
      return const AppPersistenceFailure();
    }
  }

  // ── fundGoalTransfer / releaseGoalTransfer (atomic) ───────────────────────

  @override
  Future<AppResult<GoalTransferWriteResult>> fundGoalTransfer(
    GoalAssociatedTransferParams params,
  ) {
    assert(params.kind == GoalAssociatedTransferKind.funding);
    return _executeGoalAssociatedTransfer(params);
  }

  @override
  Future<AppResult<GoalTransferWriteResult>> releaseGoalTransfer(
    GoalAssociatedTransferParams params,
  ) {
    assert(params.kind == GoalAssociatedTransferKind.release);
    return _executeGoalAssociatedTransfer(params);
  }

  // ── reverseGoalTransfer (atomic) ──────────────────────────────────────────

  @override
  Future<AppResult<void>> reverseGoalTransfer({
    required String originalOperationId,
    required String reversalOperationId,
    required String householdId,
    required String effectiveDate,
    required String createdBy,
    String? reason,
    String? idempotencyKey,
  }) async {
    final scopedKey = idempotencyKey ?? reversalOperationId;
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      return await runAuthoritativeWriteWithContentionRetry(() async {
        try {
          late AppResult<void> result;
          await _db.transaction(() async {
            result = await _runGoalReversalSteps(
              originalOperationId: originalOperationId,
              reversalOperationId: reversalOperationId,
              householdId: householdId,
              effectiveDate: effectiveDate,
              createdBy: createdBy,
              reason: reason,
              scopedKey: scopedKey,
              now: now,
            );
          });
          return result;
        } on GoalTransferInjectedFailure {
          return const AppPersistenceFailure();
        } on InsufficientFundsError {
          return const AppInsufficientFunds();
        } on Exception catch (e) {
          if (isNegativeBalanceAbort(e)) {
            return const AppInsufficientFunds();
          }
          if (isRetryableSqliteContention(e)) rethrow;
          return const AppPersistenceFailure();
        }
      });
    } on SqliteContentionExhausted {
      return const AppPersistenceFailure();
    }
  }

  GoalLifecycleEvent _rowToLifecycleEvent(QueryRow row) => GoalLifecycleEvent(
    id: row.read<String>('id'),
    goalId: row.read<String>('goal_id'),
    householdId: row.read<String>('household_id'),
    eventType: _lifecycleEventTypeFromCode(row.read<String>('event_type')),
    completionType: row.readNullable<String>('completion_type'),
    earlyCompletionReason: row.readNullable<String>('early_completion_reason'),
    earlyCompletionConfirmed: row.read<int>('early_completion_confirmed') == 1,
    idempotencyKey: row.readNullable<String>('idempotency_key'),
    actorMetadata: row.readNullable<String>('actor_metadata'),
    effectiveAt: row.read<String>('effective_at'),
    createdAt: row.read<String>('created_at'),
  );

  GoalLifecycleEventType _lifecycleEventTypeFromCode(String code) =>
      switch (code) {
        'created' => GoalLifecycleEventType.created,
        'completed' => GoalLifecycleEventType.completed,
        'archived' => GoalLifecycleEventType.archived,
        'restored' => GoalLifecycleEventType.restored,
        _ => GoalLifecycleEventType.completed,
      };

  // ── Unified goal-associated transfer write boundary ───────────────────────

  Future<void> _awaitDebugBarrier() async {
    final barrier = _debugTransactionBarrier;
    if (barrier != null) await barrier();
  }

  Future<void> _failAfter(GoalTransferFailAfter step) async {
    if (_debugFailAfter == step) {
      throw GoalTransferInjectedFailure(step);
    }
  }

  Future<AppResult<GoalTransferWriteResult>> _executeGoalAssociatedTransfer(
    GoalAssociatedTransferParams params,
  ) async {
    try {
      return await runAuthoritativeWriteWithContentionRetry(() async {
        late AppResult<GoalTransferWriteResult> result;
        try {
          await _db.transaction(() async {
            result = await _runGoalAssociatedTransferSteps(params);
          });
          return result;
        } on InsufficientFundsError {
          return const AppInsufficientFunds();
        } on GoalTransferInjectedFailure {
          return const AppPersistenceFailure();
        } on Exception catch (e) {
          if (isNegativeBalanceAbort(e)) {
            return const AppInsufficientFunds();
          }
          if (isGoalFundingSourceEligibilityAbort(e)) {
            return const AppValidationFailure(
              field: 'sourceAccountId',
              messageKey: 'errorCertificateAccountNotAllowedAsSource',
            );
          }
          if (isGoalReleaseDestinationEligibilityAbort(e)) {
            return const AppValidationFailure(
              field: 'destinationAccountId',
              messageKey: 'errorCertificateAccountNotAllowedAsDestination',
            );
          }
          if (isRetryableSqliteContention(e)) rethrow;
          return const AppPersistenceFailure();
        }
      });
    } on SqliteContentionExhausted {
      return const AppPersistenceFailure();
    }
  }

  /// Core steps for funding/release. Caller must already be inside a transaction
  /// when nesting under [createGoal]; otherwise use [_executeGoalAssociatedTransfer].
  Future<AppResult<GoalTransferWriteResult>> _runGoalAssociatedTransferSteps(
    GoalAssociatedTransferParams params,
  ) async {
    final scopedKey = params.idempotencyKey;

    // 1. Scoped idempotency lookup
    final existingById = await _db
        .customSelect(
          'SELECT id, type, total_amount_minor_units, currency_code, '
          'source_account_id, destination_account_id, description '
          'FROM operations WHERE id = ? AND household_id = ?',
          variables: [
            Variable.withString(params.operationId),
            Variable.withString(params.householdId),
          ],
        )
        .get();
    if (existingById.isNotEmpty) {
      final row = existingById.first;
      final equivalent = _transferPayloadEquivalent(
        row: row,
        expectedType: 'transfer',
        amount: params.amountMinorUnits,
        currency: params.currencyCode,
        sourceAccountId: params.sourceAccountId,
        destinationAccountId: params.destinationAccountId,
      );
      if (!equivalent) {
        return const AppPersistenceFailure();
      }
      final complete = await _isCompleteGoalTransferWorkflow(
        operationId: params.operationId,
        householdId: params.householdId,
        goalId: params.goalId,
        movementType: params.movementType,
      );
      if (!complete) return const AppPersistenceFailure();
      return const AppOk(GoalTransferWriteResult.alreadyExists);
    }

    if (scopedKey != params.operationId) {
      final existingByKey = await _db
          .customSelect(
            'SELECT id, type, total_amount_minor_units, currency_code, '
            'source_account_id, destination_account_id, description '
            'FROM operations WHERE household_id = ? AND idempotency_key = ?',
            variables: [
              Variable.withString(params.householdId),
              Variable.withString(scopedKey),
            ],
          )
          .get();
      if (existingByKey.isNotEmpty) {
        final row = existingByKey.first;
        final equivalent = _transferPayloadEquivalent(
          row: row,
          expectedType: 'transfer',
          amount: params.amountMinorUnits,
          currency: params.currencyCode,
          sourceAccountId: params.sourceAccountId,
          destinationAccountId: params.destinationAccountId,
        );
        if (!equivalent) {
          return const AppDuplicateConflict(
            messageKey: 'errorGoalIdempotencyConflict',
          );
        }
        final existingOpId = row.read<String>('id');
        final complete = await _isCompleteGoalTransferWorkflow(
          operationId: existingOpId,
          householdId: params.householdId,
          goalId: params.goalId,
          movementType: params.movementType,
        );
        if (!complete) return const AppPersistenceFailure();
        return const AppOk(GoalTransferWriteResult.alreadyExists);
      }
    }

    await _awaitDebugBarrier();

    // 2-4. Goal + source/destination validation
    final goalRows = await _db
        .customSelect(
          'SELECT id, reserve_account_id, currency_code, status, household_id '
          'FROM goals WHERE id = ?',
          variables: [Variable.withString(params.goalId)],
        )
        .get();
    if (goalRows.isEmpty) return const AppNotFound();
    final goal = goalRows.first;
    if (goal.read<String>('household_id') != params.householdId) {
      return const AppNotFound();
    }

    final srcRows = await _db
        .customSelect(
          'SELECT id, currency_code, is_archived, type, is_protected, '
          'is_spendable, fund_purpose '
          'FROM financial_accounts WHERE id = ? AND household_id = ?',
          variables: [
            Variable.withString(params.sourceAccountId),
            Variable.withString(params.householdId),
          ],
        )
        .get();
    final dstRows = await _db
        .customSelect(
          'SELECT id, currency_code, is_archived, type, is_spendable, '
          'fund_purpose '
          'FROM financial_accounts WHERE id = ? AND household_id = ?',
          variables: [
            Variable.withString(params.destinationAccountId),
            Variable.withString(params.householdId),
          ],
        )
        .get();
    if (srcRows.isEmpty || dstRows.isEmpty) return const AppNotFound();
    final src = srcRows.first;
    final dst = dstRows.first;
    if (src.read<int>('is_archived') == 1 ||
        dst.read<int>('is_archived') == 1) {
      return const AppValidationFailure(
        field: 'accountId',
        messageKey: 'errorAccountArchived',
      );
    }
    if (src.read<String>('currency_code') != params.currencyCode ||
        dst.read<String>('currency_code') != params.currencyCode) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    }

    // Phase 6B.1.1 — certificate / spendable endpoint ownership.
    final endpointGate = await _validateGoalTransferEndpoints(
      params: params,
      src: src,
      dst: dst,
    );
    if (endpointGate != null) return endpointGate;

    // 5. Balance calculation (inside transaction)
    final balanceRows = await _db
        .customSelect(
          'SELECT COALESCE(SUM(CASE WHEN direction = ? THEN amount_minor_units '
          'ELSE -amount_minor_units END), 0) AS bal '
          'FROM ledger_entries WHERE account_id = ? AND household_id = ?',
          variables: [
            Variable.withString(LedgerDirection.credit.code),
            Variable.withString(params.sourceAccountId),
            Variable.withString(params.householdId),
          ],
        )
        .get();
    final sourceBalance = balanceRows.first.read<int>('bal');

    // 6. Sufficient-funds validation
    if (sourceBalance < params.amountMinorUnits) {
      throw InsufficientFundsError(
        accountId: params.sourceAccountId,
        availableMinorUnits: sourceBalance,
        requestedMinorUnits: params.amountMinorUnits,
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();

    // 7. Operation insertion
    await _db.customStatement(
      'INSERT INTO operations '
      '(id, household_id, type, effective_date, recorded_at, '
      'total_amount_minor_units, currency_code, created_by, created_at, '
      'updated_at, description, source_account_id, destination_account_id, '
      'idempotency_key) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        params.operationId,
        params.householdId,
        'transfer',
        params.effectiveDate,
        now,
        params.amountMinorUnits,
        params.currencyCode,
        params.createdBy,
        now,
        now,
        params.description,
        params.sourceAccountId,
        params.destinationAccountId,
        scopedKey,
      ],
    );
    await _failAfter(GoalTransferFailAfter.operationInsert);

    // 8. Debit ledger entry
    await _db.customStatement(
      'INSERT INTO ledger_entries '
      '(id, operation_id, household_id, account_id, direction, '
      'amount_minor_units, currency_code, entry_type, effective_date, '
      'recorded_at, created_by) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        '${params.operationId}_debit',
        params.operationId,
        params.householdId,
        params.sourceAccountId,
        LedgerDirection.debit.code,
        params.amountMinorUnits,
        params.currencyCode,
        LedgerEntryType.transferOut.code,
        params.effectiveDate,
        now,
        params.createdBy,
      ],
    );
    await _failAfter(GoalTransferFailAfter.firstLedgerEntry);

    // 9. Credit ledger entry
    await _db.customStatement(
      'INSERT INTO ledger_entries '
      '(id, operation_id, household_id, account_id, direction, '
      'amount_minor_units, currency_code, entry_type, effective_date, '
      'recorded_at, created_by) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        '${params.operationId}_credit',
        params.operationId,
        params.householdId,
        params.destinationAccountId,
        LedgerDirection.credit.code,
        params.amountMinorUnits,
        params.currencyCode,
        LedgerEntryType.transferIn.code,
        params.effectiveDate,
        now,
        params.createdBy,
      ],
    );
    await _failAfter(GoalTransferFailAfter.secondLedgerEntry);

    // 10. Operation context/audit
    await _db.customStatement(
      'INSERT INTO operation_contexts '
      '(operation_id, household_id, is_recurring, note, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [params.operationId, params.householdId, 0, params.description, now],
    );
    await _failAfter(GoalTransferFailAfter.operationContext);

    // 11. Goal movement
    await _db.customStatement(
      'INSERT INTO goal_movements '
      '(id, goal_id, household_id, transfer_operation_id, movement_type, '
      'created_at, release_reason, reversal_of_movement_id) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, NULL)',
      [
        params.movementId,
        params.goalId,
        params.householdId,
        params.operationId,
        params.movementType.name,
        params.movementCreatedAt,
        params.releaseReason,
      ],
    );
    await _failAfter(GoalTransferFailAfter.goalMovement);

    // 14. Final pre-commit point
    await _failAfter(GoalTransferFailAfter.preCommit);

    return const AppOk(GoalTransferWriteResult.created);
  }

  /// Validates funding source / release destination ownership (Phase 6B.1.1).
  ///
  /// Rejects certificate type, certificate purpose, savings_certificates
  /// linkage, non-spendable ordinary endpoints, protected funding sources,
  /// and goalReserve on the non-reserve side of the transfer.
  Future<AppResult<GoalTransferWriteResult>?> _validateGoalTransferEndpoints({
    required GoalAssociatedTransferParams params,
    required QueryRow src,
    required QueryRow dst,
  }) async {
    Future<bool> isLinkedCertificate(String accountId) async {
      final rows = await _db
          .customSelect(
            'SELECT 1 AS ok FROM savings_certificates '
            'WHERE certificate_account_id = ? LIMIT 1',
            variables: [Variable.withString(accountId)],
          )
          .get();
      return rows.isNotEmpty;
    }

    bool isCertificateMarked(QueryRow row) =>
        row.read<String>('type') == 'certificate' ||
        row.read<String>('fund_purpose') == 'certificate';

    if (params.kind == GoalAssociatedTransferKind.funding) {
      final srcType = src.read<String>('type');
      if (srcType == 'goalReserve') {
        return const AppValidationFailure(
          field: 'sourceAccountId',
          messageKey: 'errorGoalSourceIsReserve',
        );
      }
      if (src.read<int>('is_protected') == 1) {
        return const AppValidationFailure(
          field: 'sourceAccountId',
          messageKey: 'errorGoalSourceIsProtected',
        );
      }
      if (isCertificateMarked(src) ||
          await isLinkedCertificate(params.sourceAccountId)) {
        return const AppValidationFailure(
          field: 'sourceAccountId',
          messageKey: 'errorCertificateAccountNotAllowedAsSource',
        );
      }
      if (src.read<int>('is_spendable') != 1) {
        return const AppValidationFailure(
          field: 'sourceAccountId',
          messageKey: 'errorGoalSourceNotSpendable',
        );
      }
    } else if (params.kind == GoalAssociatedTransferKind.release) {
      final dstType = dst.read<String>('type');
      if (dstType == 'goalReserve') {
        return const AppValidationFailure(
          field: 'destinationAccountId',
          messageKey: 'errorGoalSourceIsReserve',
        );
      }
      if (isCertificateMarked(dst) ||
          await isLinkedCertificate(params.destinationAccountId)) {
        return const AppValidationFailure(
          field: 'destinationAccountId',
          messageKey: 'errorCertificateAccountNotAllowedAsDestination',
        );
      }
      if (dst.read<int>('is_spendable') != 1) {
        return const AppValidationFailure(
          field: 'destinationAccountId',
          messageKey: 'errorGoalDestinationNotSpendable',
        );
      }
    }
    return null;
  }

  bool _transferPayloadEquivalent({
    required QueryRow row,
    required String expectedType,
    required int amount,
    required String currency,
    required String? sourceAccountId,
    required String? destinationAccountId,
  }) {
    return decideOperationFingerprint(
          incoming: OperationIdempotencyFingerprint(
            type: expectedType,
            amountMinorUnits: amount,
            currencyCode: currency,
            sourceAccountId: sourceAccountId,
            destinationAccountId: destinationAccountId,
          ),
          existingType: row.read<String>('type'),
          existingAmountMinorUnits: row.read<int>('total_amount_minor_units'),
          existingCurrencyCode: row.read<String>('currency_code'),
          existingSourceAccountId: row.readNullable<String>(
            'source_account_id',
          ),
          existingDestinationAccountId: row.readNullable<String>(
            'destination_account_id',
          ),
        ) ==
        ScopedIdempotencyDecision.replay;
  }

  Future<bool> _isCompleteGoalTransferWorkflow({
    required String operationId,
    required String householdId,
    required String goalId,
    required GoalMovementType movementType,
  }) async {
    final entries = await _db
        .customSelect(
          'SELECT direction FROM ledger_entries '
          'WHERE operation_id = ? AND household_id = ?',
          variables: [
            Variable.withString(operationId),
            Variable.withString(householdId),
          ],
        )
        .get();
    if (entries.length != 2) return false;
    final dirs = entries.map((e) => e.read<String>('direction')).toSet();
    if (!dirs.contains('debit') || !dirs.contains('credit')) return false;

    final ctx = await _db
        .customSelect(
          'SELECT operation_id FROM operation_contexts WHERE operation_id = ?',
          variables: [Variable.withString(operationId)],
        )
        .get();
    if (ctx.isEmpty) return false;

    final mov = await _db
        .customSelect(
          'SELECT id FROM goal_movements '
          'WHERE transfer_operation_id = ? AND goal_id = ? AND movement_type = ?',
          variables: [
            Variable.withString(operationId),
            Variable.withString(goalId),
            Variable.withString(movementType.name),
          ],
        )
        .get();
    return mov.isNotEmpty;
  }

  Future<AppResult<void>> _runGoalReversalSteps({
    required String originalOperationId,
    required String reversalOperationId,
    required String householdId,
    required String effectiveDate,
    required String createdBy,
    required String? reason,
    required String scopedKey,
    required String now,
  }) async {
    // 1. Idempotency by operation id
    final existingById = await _db
        .customSelect(
          'SELECT id, type, total_amount_minor_units, currency_code, '
          'source_account_id, destination_account_id, description '
          'FROM operations WHERE id = ? AND household_id = ?',
          variables: [
            Variable.withString(reversalOperationId),
            Variable.withString(householdId),
          ],
        )
        .get();
    if (existingById.isNotEmpty) {
      return _validateCompleteReversalReplay(
        existing: existingById.first,
        originalOperationId: originalOperationId,
        reversalOperationId: reversalOperationId,
        householdId: householdId,
        reason: reason,
      );
    }

    // Idempotency by scoped key
    if (scopedKey != reversalOperationId) {
      final existingByKey = await _db
          .customSelect(
            'SELECT id, type, total_amount_minor_units, currency_code, '
            'source_account_id, destination_account_id, description '
            'FROM operations WHERE household_id = ? AND idempotency_key = ?',
            variables: [
              Variable.withString(householdId),
              Variable.withString(scopedKey),
            ],
          )
          .get();
      if (existingByKey.isNotEmpty) {
        final row = existingByKey.first;
        final existingId = row.read<String>('id');
        final validated = await _validateCompleteReversalReplay(
          existing: row,
          originalOperationId: originalOperationId,
          reversalOperationId: existingId,
          householdId: householdId,
          reason: reason,
        );
        if (validated is AppOk<void>) return validated;
        if (validated is AppPersistenceFailure<void>) {
          // Existing key points at incomplete/unrelated op → conflict when
          // payloads differ; persistence when PK/incomplete.
          return const AppDuplicateConflict(
            messageKey: 'errorGoalIdempotencyConflict',
          );
        }
        return validated;
      }
    }

    await _awaitDebugBarrier();

    // 2. Validate original operation
    final originalRows = await _db
        .customSelect(
          'SELECT id, is_reversed, total_amount_minor_units, currency_code, '
          'source_account_id, destination_account_id, type '
          'FROM operations WHERE id = ? AND household_id = ?',
          variables: [
            Variable.withString(originalOperationId),
            Variable.withString(householdId),
          ],
        )
        .get();
    if (originalRows.isEmpty) return const AppNotFound();
    final original = originalRows.first;
    if (original.read<int>('is_reversed') == 1) {
      return const AppDuplicateConflict(
        messageKey: 'errorOperationAlreadyReversed',
      );
    }

    final amount = original.read<int>('total_amount_minor_units');
    final currency = original.read<String>('currency_code');
    final origSource = original.readNullable<String>('source_account_id');
    final origDest = original.readNullable<String>('destination_account_id');
    final revDescription =
        reason ?? 'Reversal of operation $originalOperationId';

    // 3. Optional original goal movement
    final movRows = await _db
        .customSelect(
          'SELECT * FROM goal_movements WHERE transfer_operation_id = ? LIMIT 1',
          variables: [Variable.withString(originalOperationId)],
        )
        .get();
    final originalMovement = movRows.isEmpty ? null : movRows.first;
    if (originalMovement != null) {
      final movType = originalMovement.read<String>('movement_type');
      if (movType != 'funding' && movType != 'release') {
        return const AppValidationFailure(
          field: 'originalOperationId',
          messageKey: 'errorGoalReversalInvalidMovement',
        );
      }
    }

    // 4. Insert reversal operation
    await _db.customStatement(
      'INSERT INTO operations '
      '(id, household_id, type, effective_date, recorded_at, '
      'total_amount_minor_units, currency_code, created_by, created_at, '
      'updated_at, description, source_account_id, destination_account_id, '
      'idempotency_key, is_reversed) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)',
      [
        reversalOperationId,
        householdId,
        OperationType.reversal.code,
        effectiveDate,
        now,
        amount,
        currency,
        createdBy,
        now,
        now,
        revDescription,
        origDest,
        origSource,
        scopedKey,
      ],
    );
    await _failAfter(GoalTransferFailAfter.operationInsert);

    // 5. Mirror ledger entries
    final origEntries = await _db
        .customSelect(
          'SELECT * FROM ledger_entries '
          'WHERE operation_id = ? AND household_id = ? '
          'ORDER BY id ASC',
          variables: [
            Variable.withString(originalOperationId),
            Variable.withString(householdId),
          ],
        )
        .get();

    for (var i = 0; i < origEntries.length; i++) {
      final e = origEntries[i];
      final dir = e.read<String>('direction');
      final opposite = dir == LedgerDirection.credit.code
          ? LedgerDirection.debit.code
          : LedgerDirection.credit.code;
      final entryType = dir == LedgerDirection.credit.code
          ? LedgerEntryType.reversalDebit.code
          : LedgerEntryType.reversalCredit.code;
      final entryId = e.read<String>('id');
      await _db.customStatement(
        'INSERT INTO ledger_entries '
        '(id, operation_id, household_id, account_id, direction, '
        'amount_minor_units, currency_code, entry_type, effective_date, '
        'recorded_at, created_by, is_reversal, reversal_of_entry_id) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)',
        [
          '${reversalOperationId}_rev_$entryId',
          reversalOperationId,
          householdId,
          e.read<String>('account_id'),
          opposite,
          e.read<int>('amount_minor_units'),
          e.read<String>('currency_code'),
          entryType,
          effectiveDate,
          now,
          createdBy,
          entryId,
        ],
      );
      if (i == 0) {
        await _failAfter(GoalTransferFailAfter.firstLedgerEntry);
      } else if (i == 1) {
        await _failAfter(GoalTransferFailAfter.secondLedgerEntry);
      }
    }

    // 6. Mark original reversed
    await _db.customStatement(
      'UPDATE operations SET is_reversed = 1, reversed_by = ?, '
      'updated_at = ? WHERE id = ? AND household_id = ?',
      [reversalOperationId, now, originalOperationId, householdId],
    );

    // 7. Operation context
    await _db.customStatement(
      'INSERT INTO operation_contexts '
      '(operation_id, household_id, is_recurring, note, created_at) '
      'VALUES (?, ?, 0, ?, ?)',
      [reversalOperationId, householdId, revDescription, now],
    );
    await _failAfter(GoalTransferFailAfter.operationContext);

    // 8. Reversal goal movement
    if (originalMovement != null) {
      await _db.customStatement(
        'INSERT INTO goal_movements '
        '(id, goal_id, household_id, transfer_operation_id, movement_type, '
        'created_at, release_reason, reversal_of_movement_id) '
        'VALUES (?, ?, ?, ?, ?, ?, NULL, ?)',
        [
          '$reversalOperationId-mov',
          originalMovement.read<String>('goal_id'),
          householdId,
          reversalOperationId,
          'reversal',
          now,
          originalMovement.read<String>('id'),
        ],
      );
      await _failAfter(GoalTransferFailAfter.goalMovement);
    }

    await _failAfter(GoalTransferFailAfter.preCommit);
    return const AppOk(null);
  }

  Future<AppResult<void>> _validateCompleteReversalReplay({
    required QueryRow existing,
    required String originalOperationId,
    required String reversalOperationId,
    required String householdId,
    required String? reason,
  }) async {
    // Unrelated primary-key / row collision
    if (existing.read<String>('type') != OperationType.reversal.code) {
      return const AppPersistenceFailure();
    }

    final originalRows = await _db
        .customSelect(
          'SELECT id, is_reversed, reversed_by, total_amount_minor_units, '
          'currency_code, source_account_id, destination_account_id '
          'FROM operations WHERE id = ? AND household_id = ?',
          variables: [
            Variable.withString(originalOperationId),
            Variable.withString(householdId),
          ],
        )
        .get();
    if (originalRows.isEmpty) return const AppPersistenceFailure();
    final original = originalRows.first;

    // Must reverse the requested original
    if (original.readNullable<String>('reversed_by') != reversalOperationId) {
      // Conflicting: existing reversal op does not reverse requested original
      final expectedDesc =
          reason ?? 'Reversal of operation $originalOperationId';
      final desc = existing.readNullable<String>('description');
      if (desc != expectedDesc) {
        return const AppDuplicateConflict(
          messageKey: 'errorGoalIdempotencyConflict',
        );
      }
      return const AppPersistenceFailure();
    }

    if (original.read<int>('is_reversed') != 1) {
      return const AppPersistenceFailure();
    }

    // Payload equivalence (accounts swapped relative to original)
    final origSource = original.readNullable<String>('source_account_id');
    final origDest = original.readNullable<String>('destination_account_id');
    final amount = original.read<int>('total_amount_minor_units');
    final currency = original.read<String>('currency_code');
    final equivalent = _transferPayloadEquivalent(
      row: existing,
      expectedType: OperationType.reversal.code,
      amount: amount,
      currency: currency,
      sourceAccountId: origDest,
      destinationAccountId: origSource,
    );
    if (!equivalent) {
      return const AppDuplicateConflict(
        messageKey: 'errorGoalIdempotencyConflict',
      );
    }

    // Context must exist
    final ctx = await _db
        .customSelect(
          'SELECT operation_id FROM operation_contexts WHERE operation_id = ?',
          variables: [Variable.withString(reversalOperationId)],
        )
        .get();
    if (ctx.isEmpty) return const AppPersistenceFailure();

    // If original had a goal movement, reversal movement must exist and link
    final origMov = await _db
        .customSelect(
          'SELECT id FROM goal_movements WHERE transfer_operation_id = ? '
          "AND movement_type IN ('funding', 'release') LIMIT 1",
          variables: [Variable.withString(originalOperationId)],
        )
        .get();
    if (origMov.isNotEmpty) {
      final origMovId = origMov.first.read<String>('id');
      final revMov = await _db
          .customSelect(
            'SELECT id, reversal_of_movement_id FROM goal_movements '
            'WHERE transfer_operation_id = ? AND movement_type = ?',
            variables: [
              Variable.withString(reversalOperationId),
              Variable.withString('reversal'),
            ],
          )
          .get();
      if (revMov.isEmpty) return const AppPersistenceFailure();
      if (revMov.first.readNullable<String>('reversal_of_movement_id') !=
          origMovId) {
        return const AppPersistenceFailure();
      }
    }

    return const AppOk(null);
  }
}
