import 'package:drift/drift.dart';
import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/database/app_database.dart';
import 'package:family_money_manager/core/financial/ledger_enums.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/goals/data/goal_repository.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart' show InsufficientFundsError;

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
  const DriftGoalRepository(this._db);

  final AppDatabase _db;

  // ── createGoal ────────────────────────────────────────────────────────────

  @override
  Future<AppResult<SavingsGoal>> createGoal({
    required SavingsGoal goal,
    required GoalRevision initialRevision,
    required FinancialAccount reserveAccount,
    GoalInitialFunding? initialFunding,
  }) async {
    try {
      // Idempotency check: same key + same payload → return existing goal.
      // This pre-check avoids unnecessary transaction overhead on retries.
      final existing = await _db
          .customSelect(
            'SELECT id, idempotency_payload FROM goals '
            'WHERE household_id = ? AND idempotency_key = ?',
            variables: [Variable.withString(goal.householdId), Variable.withString(goal.idempotencyKey)],
          )
          .get();

      if (existing.isNotEmpty) {
        final row = existing.first;
        final storedPayload = row.read<String>('idempotency_payload');
        final incomingPayload = _buildIdempotencyPayload(goal, initialRevision);
        if (storedPayload == incomingPayload) {
          final existingId = row.read<String>('id');
          final found = await _findById(existingId);
          if (found != null) return AppOk(found);
        }
        return const AppDuplicateConflict(messageKey: 'errorGoalIdempotencyConflict');
      }

      final payload = _buildIdempotencyPayload(goal, initialRevision);
      final now = DateTime.now().toUtc().toIso8601String();

      await _db.transaction(() async {
        // 1. Insert the goalReserve financial account.
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

        // 2. Insert the goal row.
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
                idempotencyPayload: payload,
                createdAt: goal.createdAt,
                completedAt: Value(goal.completedAt),
                archivedAt: Value(goal.archivedAt),
              ),
            );

        // 3. Insert the initial revision.
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

        // 4. Optional initial funding — all within the same transaction.
        if (initialFunding != null && initialFunding.amountMinorUnits > 0) {
          // Balance check inside the transaction (TOCTOU-safe for SQLite WAL).
          final balanceRows = await _db
              .customSelect(
                'SELECT COALESCE(SUM(CASE WHEN direction = ? THEN amount_minor_units '
                'ELSE -amount_minor_units END), 0) AS bal '
                'FROM ledger_entries WHERE account_id = ? AND household_id = ?',
                variables: [
                  Variable.withString(LedgerDirection.credit.code),
                  Variable.withString(initialFunding.sourceAccountId),
                  Variable.withString(goal.householdId),
                ],
              )
              .get();
          final sourceBalance = balanceRows.first.read<int>('bal');
          if (sourceBalance < initialFunding.amountMinorUnits) {
            throw InsufficientFundsError(
              accountId: initialFunding.sourceAccountId,
              availableMinorUnits: sourceBalance,
              requestedMinorUnits: initialFunding.amountMinorUnits,
            );
          }

          // Insert transfer operation.
          await _db.customStatement(
            'INSERT INTO operations '
            '(id, household_id, type, effective_date, recorded_at, '
            'total_amount_minor_units, currency_code, created_by, created_at, '
            'updated_at, description, source_account_id, destination_account_id, '
            'idempotency_key) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              initialFunding.operationId,
              goal.householdId,
              'transfer',
              initialFunding.effectiveDate,
              now,
              initialFunding.amountMinorUnits,
              initialFunding.currencyCode,
              'system',
              now,
              now,
              initialFunding.description,
              initialFunding.sourceAccountId,
              reserveAccount.id,
              initialFunding.idempotencyKey,
            ],
          );

          // Insert debit entry on source account.
          await _db.customStatement(
            'INSERT INTO ledger_entries '
            '(id, operation_id, household_id, account_id, direction, '
            'amount_minor_units, currency_code, entry_type, effective_date, '
            'recorded_at, created_by) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              '${initialFunding.operationId}_debit',
              initialFunding.operationId,
              goal.householdId,
              initialFunding.sourceAccountId,
              LedgerDirection.debit.code,
              initialFunding.amountMinorUnits,
              initialFunding.currencyCode,
              LedgerEntryType.transferOut.code,
              initialFunding.effectiveDate,
              now,
              'system',
            ],
          );

          // Insert credit entry on reserve account.
          await _db.customStatement(
            'INSERT INTO ledger_entries '
            '(id, operation_id, household_id, account_id, direction, '
            'amount_minor_units, currency_code, entry_type, effective_date, '
            'recorded_at, created_by) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              '${initialFunding.operationId}_credit',
              initialFunding.operationId,
              goal.householdId,
              reserveAccount.id,
              LedgerDirection.credit.code,
              initialFunding.amountMinorUnits,
              initialFunding.currencyCode,
              LedgerEntryType.transferIn.code,
              initialFunding.effectiveDate,
              now,
              'system',
            ],
          );

          // Insert operation context.
          await _db.customStatement(
            'INSERT INTO operation_contexts '
            '(operation_id, household_id, is_recurring, note, created_at) '
            'VALUES (?, ?, ?, ?, ?)',
            [initialFunding.operationId, goal.householdId, 0, initialFunding.description, now],
          );

          // Insert goal movement.
          await _db
              .into(_db.goalMovementsTable)
              .insert(
                GoalMovementsTableCompanion.insert(
                  id: initialFunding.movementId,
                  goalId: goal.id,
                  householdId: goal.householdId,
                  transferOperationId: initialFunding.operationId,
                  movementType: GoalMovementType.funding.name,
                  createdAt: initialFunding.movementCreatedAt,
                ),
              );
        }
      });

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
  Future<AppResult<List<SavingsGoal>>> listGoals({required String householdId, bool includeArchived = false}) async {
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
  Future<AppResult<void>> updateGoalStatus({required String goalId, required GoalStatus status, String? completedAt, String? archivedAt}) async {
    try {
      await (_db.update(_db.goalsTable)..where((t) => t.id.equals(goalId))).write(
        GoalsTableCompanion(status: Value(status.name), completedAt: Value(completedAt), archivedAt: Value(archivedAt)),
      );
      return const AppOk(null);
    } on Exception catch (_) {
      return const AppPersistenceFailure();
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
  Future<AppResult<int>> getReserveBalance({required String reserveAccountId, required String householdId}) async {
    try {
      final entries = await _db
          .customSelect(
            'SELECT direction, amount_minor_units FROM ledger_entries '
            'WHERE account_id = ? AND household_id = ?',
            variables: [Variable.withString(reserveAccountId), Variable.withString(householdId)],
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
    final goalRows = await _db.customSelect('SELECT * FROM goals WHERE id = ?', variables: [Variable.withString(goalId)]).get();
    if (goalRows.isEmpty) return null;
    final g = goalRows.first;

    // Load the most recent revision (by created_at DESC, then id DESC as tie-breaker).
    final revRows = await _db
        .customSelect('SELECT * FROM goal_revisions WHERE goal_id = ? ORDER BY created_at DESC, id DESC LIMIT 1', variables: [Variable.withString(goalId)])
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
    movementType: row.movementType == 'funding' ? GoalMovementType.funding : GoalMovementType.release,
    createdAt: row.createdAt,
    releaseReason: row.releaseReason,
  );

  GoalStatus _statusFromCode(String code) => switch (code) {
    'active' => GoalStatus.active,
    'targetReached' => GoalStatus.targetReached,
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
}
