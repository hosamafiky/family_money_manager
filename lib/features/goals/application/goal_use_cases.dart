import 'package:family_money_manager/core/application/app_result.dart';
import 'package:family_money_manager/core/financial/account_enums.dart';
import 'package:family_money_manager/core/financial/currency.dart';
import 'package:family_money_manager/features/accounts/data/account_repository.dart';
import 'package:family_money_manager/features/accounts/domain/financial_account.dart';
import 'package:family_money_manager/features/goals/application/complete_goal_params.dart';
import 'package:family_money_manager/features/goals/data/goal_repository.dart';
import 'package:family_money_manager/features/goals/domain/goal.dart';
import 'package:family_money_manager/features/ledger/data/ledger_repository.dart';
import 'package:family_money_manager/features/ledger/domain/child_withdrawal_audit.dart';
import 'package:family_money_manager/features/ledger/domain/operation.dart';
import 'package:uuid/uuid.dart';

export 'complete_goal_params.dart';

// ── Shared helpers ─────────────────────────────────────────────────────────

const _uuid = Uuid();

String _nowUtc() => DateTime.now().toUtc().toIso8601String();

bool _isSupportedCurrency(String code) {
  for (final c in Currency.values) {
    if (c.code == code) return true;
  }
  return false;
}

/// Validates source account for goal-funding operations.
///
/// Returns null when valid, or an [AppResult] error to propagate.
AppResult<T>? _validateFundingSource<T>(FinancialAccount? source) {
  if (source == null) return const AppNotFound();
  if (source.isArchived) {
    return const AppValidationFailure(
      field: 'sourceAccountId',
      messageKey: 'errorAccountArchived',
    );
  }
  if (source.isProtected) {
    return const AppValidationFailure(
      field: 'sourceAccountId',
      messageKey: 'errorGoalSourceIsProtected',
    );
  }
  if (source.type == FinancialAccountType.goalReserve) {
    return const AppValidationFailure(
      field: 'sourceAccountId',
      messageKey: 'errorGoalSourceIsReserve',
    );
  }
  return null;
}

// ── CreateGoalUseCase ──────────────────────────────────────────────────────

final class CreateGoalUseCase {
  const CreateGoalUseCase({
    required GoalRepository goalRepository,
    required AccountRepository accountRepository,
    // ledgerRepository kept for API compatibility; ledger ops are now inside
    // the atomic goal-repository transaction.
    LedgerRepository? ledgerRepository,
  }) : _goals = goalRepository,
       _accounts = accountRepository;

  final GoalRepository _goals;
  final AccountRepository _accounts;

  Future<AppResult<SavingsGoal>> execute({
    required String goalName,
    required GoalPurpose purpose,
    required String currencyCode,
    required int targetMinorUnits,
    required String householdId,
    required String idempotencyKey,
    String? targetDate,
    String? beneficiaryMemberId,
    String? initialFundingSourceAccountId,
    int initialFundingMinorUnits = 0,
  }) async {
    // ── Validation ──────────────────────────────────────────────────────────
    if (goalName.trim().isEmpty) {
      return const AppValidationFailure(
        field: 'name',
        messageKey: 'errorGoalNameEmpty',
      );
    }
    if (targetMinorUnits <= 0) {
      return const AppValidationFailure(
        field: 'targetMinorUnits',
        messageKey: 'errorGoalTargetZero',
      );
    }
    if (currencyCode.isEmpty || !_isSupportedCurrency(currencyCode)) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorGoalCurrencyRequired',
      );
    }

    // ── Build domain objects ─────────────────────────────────────────────────
    final goalId = _uuid.v4();
    final revisionId = _uuid.v4();
    final reserveAccountId = _uuid.v4();
    final now = _nowUtc();

    final revision = GoalRevision(
      id: revisionId,
      goalId: goalId,
      householdId: householdId,
      name: goalName.trim(),
      purpose: purpose,
      targetMinorUnits: targetMinorUnits,
      currencyCode: currencyCode,
      createdAt: now,
      revisionReason: 'initial',
      targetDate: targetDate,
      beneficiaryMemberId: beneficiaryMemberId,
    );

    final reserveAccount = FinancialAccount(
      id: reserveAccountId,
      householdId: householdId,
      name: 'Goal Reserve: ${goalName.trim()}',
      type: FinancialAccountType.goalReserve,
      ownerType: AccountOwnerType.household,
      fundPurpose: FundPurpose.goalReserve,
      currencyCode: currencyCode,
      isSpendable: false,
      isProtected: false,
      includeInNetWorth: true,
      includeInZakat: false,
      isArchived: false,
      displayOrder: 9999,
      createdAt: now,
      updatedAt: now,
      createdBy: 'system',
    );

    final goal = SavingsGoal(
      id: goalId,
      householdId: householdId,
      reserveAccountId: reserveAccountId,
      currencyCode: currencyCode,
      status: GoalStatus.active,
      currentRevision: revision,
      createdAt: now,
      idempotencyKey: idempotencyKey,
    );

    // ── Validate optional initial funding source ─────────────────────────────
    GoalInitialFunding? initialFunding;
    if (initialFundingMinorUnits > 0 &&
        initialFundingSourceAccountId != null &&
        initialFundingSourceAccountId.isNotEmpty) {
      final source = await _accounts.findById(
        id: initialFundingSourceAccountId,
        householdId: householdId,
      );
      final sourceError = _validateFundingSource<SavingsGoal>(source);
      if (sourceError != null) return sourceError;
      if (source!.currencyCode != currencyCode) {
        return const AppValidationFailure(
          field: 'currencyCode',
          messageKey: 'errorCurrencyMismatch',
        );
      }

      initialFunding = GoalInitialFunding(
        operationId: _uuid.v4(),
        idempotencyKey: idempotencyKey,
        sourceAccountId: initialFundingSourceAccountId,
        amountMinorUnits: initialFundingMinorUnits,
        currencyCode: currencyCode,
        effectiveDate: DateTime.now().toUtc().toIso8601String().substring(
          0,
          10,
        ),
        description: 'Initial goal funding: ${goalName.trim()}',
        movementId: _uuid.v4(),
        movementCreatedAt: now,
      );
    }

    // ── Persist goal + reserve account + optional initial funding atomically ─
    final createResult = await _goals.createGoal(
      goal: goal,
      initialRevision: revision,
      reserveAccount: reserveAccount,
      initialFunding: initialFunding,
    );
    if (createResult is! AppOk<SavingsGoal>) return createResult;

    return AppOk(createResult.value);
  }
}

// ── FundGoalUseCase ────────────────────────────────────────────────────────

final class FundGoalUseCase {
  const FundGoalUseCase({
    required GoalRepository goalRepository,
    required AccountRepository accountRepository,
    required LedgerRepository ledgerRepository,
  }) : _goals = goalRepository,
       _accounts = accountRepository,
       _ledger = ledgerRepository;

  final GoalRepository _goals;
  final AccountRepository _accounts;
  final LedgerRepository _ledger;

  Future<AppResult<SavingsGoal>> execute({
    required String goalId,
    required String sourceAccountId,
    required int amountMinorUnits,
    required String householdId,
    required String idempotencyKey,
  }) async {
    if (amountMinorUnits <= 0) {
      return const AppValidationFailure(
        field: 'amount',
        messageKey: 'error_amount_must_be_positive',
      );
    }

    // Load goal.
    final goalResult = await _goals.findGoalById(goalId);
    if (goalResult is! AppOk<SavingsGoal?>) {
      return const AppPersistenceFailure();
    }
    final goal = goalResult.value;
    if (goal == null) return const AppNotFound();
    if (goal.status != GoalStatus.active &&
        goal.status != GoalStatus.targetReached) {
      return const AppValidationFailure(
        field: 'goalId',
        messageKey: 'errorGoalNotActive',
      );
    }
    if (sourceAccountId == goal.reserveAccountId) {
      return const AppValidationFailure(
        field: 'sourceAccountId',
        messageKey: 'errorGoalSourceIsReserve',
      );
    }

    // Validate source account.
    final source = await _accounts.findById(
      id: sourceAccountId,
      householdId: householdId,
    );
    final sourceError = _validateFundingSource<SavingsGoal>(source);
    if (sourceError != null) return sourceError;
    if (source!.currencyCode != goal.currencyCode) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    }

    // Execute the transfer.
    final transferOperationId = _uuid.v4();
    final effectiveDate = DateTime.now().toUtc().toIso8601String().substring(
      0,
      10,
    );
    final now = _nowUtc();

    IdempotentOperationResult transferResult;
    try {
      transferResult = await _ledger.executeTransfer(
        ExecuteTransferParams(
          operationId: transferOperationId,
          idempotencyKey: idempotencyKey,
          householdId: householdId,
          sourceAccountId: sourceAccountId,
          destinationAccountId: goal.reserveAccountId,
          amountMinorUnits: amountMinorUnits,
          currencyCode: goal.currencyCode,
          effectiveDate: effectiveDate,
          createdBy: 'system',
          description: 'Goal funding: ${goal.name}',
        ),
      );
    } on InsufficientFundsError {
      return const AppInsufficientFunds();
    } catch (_) {
      return const AppPersistenceFailure();
    }

    // Conflicting payload under the same scoped key must not be silently
    // coerced into AppOk (Phase 5B.5 correction of Phase 5B.4 behaviour).
    if (transferResult == IdempotentOperationResult.conflict) {
      return const AppDuplicateConflict(
        messageKey: 'errorGoalIdempotencyConflict',
      );
    }

    // Record movement — skip on idempotent replay (equivalent payload).
    if (transferResult == IdempotentOperationResult.created) {
      await _goals.addMovement(
        GoalMovement(
          id: _uuid.v4(),
          goalId: goalId,
          householdId: householdId,
          transferOperationId: transferOperationId,
          movementType: GoalMovementType.funding,
          createdAt: now,
        ),
      );
    }

    // Check if target is now reached.
    final balanceResult = await _goals.getReserveBalance(
      reserveAccountId: goal.reserveAccountId,
      householdId: householdId,
    );
    if (balanceResult is AppOk<int>) {
      final balance = balanceResult.value;
      if (balance >= goal.targetMinorUnits &&
          goal.status == GoalStatus.active) {
        await _goals.updateGoalStatus(
          goalId: goalId,
          status: GoalStatus.targetReached,
        );
        // Return an updated goal reflecting new status.
        final updatedResult = await _goals.findGoalById(goalId);
        if (updatedResult is AppOk<SavingsGoal?> &&
            updatedResult.value != null) {
          return AppOk(updatedResult.value!);
        }
      }
    }

    final updatedResult = await _goals.findGoalById(goalId);
    if (updatedResult is AppOk<SavingsGoal?> && updatedResult.value != null) {
      return AppOk(updatedResult.value!);
    }
    return AppOk(goal);
  }
}

// ── ReleaseGoalFundsUseCase ────────────────────────────────────────────────

final class ReleaseGoalFundsUseCase {
  const ReleaseGoalFundsUseCase({
    required GoalRepository goalRepository,
    required AccountRepository accountRepository,
    required LedgerRepository ledgerRepository,
  }) : _goals = goalRepository,
       _accounts = accountRepository,
       _ledger = ledgerRepository;

  final GoalRepository _goals;
  final AccountRepository _accounts;
  final LedgerRepository _ledger;

  Future<AppResult<SavingsGoal>> execute({
    required String goalId,
    required String destinationAccountId,
    required int amountMinorUnits,
    required String releaseReason,
    required String householdId,
    required String idempotencyKey,
  }) async {
    if (amountMinorUnits <= 0) {
      return const AppValidationFailure(
        field: 'amount',
        messageKey: 'error_amount_must_be_positive',
      );
    }
    if (releaseReason.trim().isEmpty) {
      return const AppValidationFailure(
        field: 'releaseReason',
        messageKey: 'errorGoalReleaseReasonEmpty',
      );
    }

    // Load goal.
    final goalResult = await _goals.findGoalById(goalId);
    if (goalResult is! AppOk<SavingsGoal?>) {
      return const AppPersistenceFailure();
    }
    final goal = goalResult.value;
    if (goal == null) return const AppNotFound();
    if (goal.status == GoalStatus.archived) {
      return const AppValidationFailure(
        field: 'goalId',
        messageKey: 'errorGoalArchived',
      );
    }
    if (destinationAccountId == goal.reserveAccountId) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorGoalSourceIsReserve',
      );
    }

    // Validate destination account.
    final destination = await _accounts.findById(
      id: destinationAccountId,
      householdId: householdId,
    );
    if (destination == null) return const AppNotFound();
    if (destination.isArchived) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorAccountArchived',
      );
    }
    if (destination.type == FinancialAccountType.goalReserve) {
      return const AppValidationFailure(
        field: 'destinationAccountId',
        messageKey: 'errorGoalSourceIsReserve',
      );
    }
    if (destination.currencyCode != goal.currencyCode) {
      return const AppValidationFailure(
        field: 'currencyCode',
        messageKey: 'errorCurrencyMismatch',
      );
    }

    // Check reserve has sufficient balance.
    final balanceResult = await _goals.getReserveBalance(
      reserveAccountId: goal.reserveAccountId,
      householdId: householdId,
    );
    if (balanceResult is! AppOk<int>) return const AppPersistenceFailure();
    if (balanceResult.value < amountMinorUnits) {
      return const AppInsufficientFunds();
    }

    // Execute the transfer.
    final transferOperationId = _uuid.v4();
    final effectiveDate = DateTime.now().toUtc().toIso8601String().substring(
      0,
      10,
    );
    final now = _nowUtc();

    IdempotentOperationResult transferResult;
    try {
      transferResult = await _ledger.executeTransfer(
        ExecuteTransferParams(
          operationId: transferOperationId,
          idempotencyKey: idempotencyKey,
          householdId: householdId,
          sourceAccountId: goal.reserveAccountId,
          destinationAccountId: destinationAccountId,
          amountMinorUnits: amountMinorUnits,
          currencyCode: goal.currencyCode,
          effectiveDate: effectiveDate,
          createdBy: 'system',
          description: 'Goal release: ${goal.name} — ${releaseReason.trim()}',
        ),
      );
    } on InsufficientFundsError {
      return const AppInsufficientFunds();
    } catch (_) {
      return const AppPersistenceFailure();
    }

    if (transferResult == IdempotentOperationResult.conflict) {
      return const AppDuplicateConflict(
        messageKey: 'errorGoalIdempotencyConflict',
      );
    }

    // Record movement — skip on idempotent replay (equivalent payload).
    if (transferResult == IdempotentOperationResult.created) {
      await _goals.addMovement(
        GoalMovement(
          id: _uuid.v4(),
          goalId: goalId,
          householdId: householdId,
          transferOperationId: transferOperationId,
          movementType: GoalMovementType.release,
          createdAt: now,
          releaseReason: releaseReason.trim(),
        ),
      );
    }

    final updatedResult = await _goals.findGoalById(goalId);
    if (updatedResult is AppOk<SavingsGoal?> && updatedResult.value != null) {
      return AppOk(updatedResult.value!);
    }
    return AppOk(goal);
  }
}

// ── GetGoalProgressUseCase ─────────────────────────────────────────────────

final class GetGoalProgressUseCase {
  const GetGoalProgressUseCase(this._goals);

  final GoalRepository _goals;

  Future<AppResult<GoalProgress>> execute(String goalId) async {
    final goalResult = await _goals.findGoalById(goalId);
    if (goalResult is! AppOk<SavingsGoal?>) {
      return const AppPersistenceFailure();
    }
    final goal = goalResult.value;
    if (goal == null) return const AppNotFound();

    final revisionsResult = await _goals.getRevisions(goalId);
    if (revisionsResult is! AppOk<List<GoalRevision>>) {
      return const AppPersistenceFailure();
    }

    final movementsResult = await _goals.getMovements(goalId);
    if (movementsResult is! AppOk<List<GoalMovement>>) {
      return const AppPersistenceFailure();
    }

    final balanceResult = await _goals.getReserveBalance(
      reserveAccountId: goal.reserveAccountId,
      householdId: goal.householdId,
    );
    if (balanceResult is! AppOk<int>) return const AppPersistenceFailure();

    final balance = balanceResult.value;
    final target = goal.targetMinorUnits;

    final progressState = balance == 0
        ? GoalProgressState.notStarted
        : balance > target
        ? GoalProgressState.overfunded
        : balance == target
        ? GoalProgressState.targetReached
        : GoalProgressState.inProgress;

    return AppOk(
      GoalProgress(
        goal: goal,
        reserveBalanceMinorUnits: balance,
        currencyCode: goal.currencyCode,
        progressState: progressState,
        movements: movementsResult.value,
        revisions: revisionsResult.value,
      ),
    );
  }
}

// ── UpdateGoalRevisionUseCase ──────────────────────────────────────────────

final class UpdateGoalRevisionUseCase {
  const UpdateGoalRevisionUseCase(this._goals);

  final GoalRepository _goals;

  Future<AppResult<void>> execute({
    required String goalId,
    required String householdId,
    required String newName,
    required int newTargetMinorUnits,
    required GoalPurpose newPurpose,
    required String revisionReason,
    String? newTargetDate,
    String? newBeneficiaryMemberId,
  }) async {
    if (newName.trim().isEmpty) {
      return const AppValidationFailure(
        field: 'name',
        messageKey: 'errorGoalNameEmpty',
      );
    }
    if (newTargetMinorUnits <= 0) {
      return const AppValidationFailure(
        field: 'targetMinorUnits',
        messageKey: 'errorGoalTargetZero',
      );
    }

    final goalResult = await _goals.findGoalById(goalId);
    if (goalResult is! AppOk<SavingsGoal?>) {
      return const AppPersistenceFailure();
    }
    final goal = goalResult.value;
    if (goal == null) return const AppNotFound();

    final newRevision = GoalRevision(
      id: _uuid.v4(),
      goalId: goalId,
      householdId: householdId,
      name: newName.trim(),
      purpose: newPurpose,
      targetMinorUnits: newTargetMinorUnits,
      // Currency and household are immutable across revisions.
      currencyCode: goal.currencyCode,
      createdAt: _nowUtc(),
      revisionReason: revisionReason.trim().isEmpty
          ? 'updated'
          : revisionReason.trim(),
      targetDate: newTargetDate,
      beneficiaryMemberId: newBeneficiaryMemberId,
    );

    return _goals.addRevision(newRevision);
  }
}

// ── CompleteGoalUseCase ────────────────────────────────────────────────────

/// Transitions an active (or targetReached) goal to [GoalStatus.completed].
///
/// RULES:
/// - Archived goal → [AppValidationFailure] ('errorGoalArchived').
/// - Already completed → returns the existing goal idempotently (no mutation).
/// - Normal completion (earlyCompletion = false): allowed only when
///   reserveBalance >= targetMinorUnits.
/// - Early completion (earlyCompletion = true): any balance is allowed, but
///   earlyCompletionReason must be non-empty.
/// - No financial operation, ledger entry, or goal movement is created.
/// - Phase 5B.4: inserts an immutable [GoalLifecycleEvent] after completion.
final class CompleteGoalUseCase {
  const CompleteGoalUseCase(this._goals);

  final GoalRepository _goals;

  Future<AppResult<SavingsGoal>> execute(CompleteGoalParams params) async {
    // Load goal.
    final goalResult = await _goals.findGoalById(params.goalId);
    if (goalResult is! AppOk<SavingsGoal?>) {
      return const AppPersistenceFailure();
    }
    final goal = goalResult.value;
    if (goal == null) return const AppNotFound();

    // Archived goals cannot be completed.
    if (goal.status == GoalStatus.archived) {
      return const AppValidationFailure(
        field: 'goalId',
        messageKey: 'errorGoalArchived',
      );
    }

    // Already completed → idempotent.
    if (goal.status == GoalStatus.completed) return AppOk(goal);

    if (params.earlyCompletion) {
      // Early completion requires explicit confirmation flag.
      if (!params.earlyCompletionConfirmed) {
        return const AppValidationFailure(
          field: 'earlyCompletionConfirmed',
          messageKey: 'errorEarlyCompletionConfirmationRequired',
        );
      }
      // Early completion requires a non-empty reason.
      final reason = params.earlyCompletionReason?.trim() ?? '';
      if (reason.isEmpty) {
        return const AppValidationFailure(
          field: 'earlyCompletionReason',
          messageKey: 'errorEarlyCompletionReasonRequired',
        );
      }
    } else {
      // Normal completion: reserve balance must be >= target.
      final balResult = await _goals.getReserveBalance(
        reserveAccountId: goal.reserveAccountId,
        householdId: params.householdId,
      );
      if (balResult is! AppOk<int>) return const AppPersistenceFailure();
      final balance = balResult.value;
      if (balance < goal.targetMinorUnits) {
        return const AppValidationFailure(
          field: 'balance',
          messageKey: 'errorGoalNormalCompletionRequiresTarget',
        );
      }
    }

    final result = await _goals.completeGoal(params);
    if (result is! AppOk<SavingsGoal>) return result;

    // Insert an immutable lifecycle event recording this completion.
    final now = _nowUtc();
    final lifecycleEvent = GoalLifecycleEvent(
      id: '${params.goalId}-lce-complete-${now.replaceAll(':', '').replaceAll('.', '')}',
      goalId: params.goalId,
      householdId: params.householdId,
      eventType: GoalLifecycleEventType.completed,
      completionType: params.earlyCompletion ? 'early' : 'normal',
      earlyCompletionReason: params.earlyCompletion
          ? params.earlyCompletionReason
          : null,
      earlyCompletionConfirmed: params.earlyCompletionConfirmed,
      idempotencyKey: 'complete-${params.idempotencyKey}',
      effectiveAt: now,
      createdAt: now,
    );
    // Lifecycle event insertion failure is non-fatal (best-effort audit).
    await _goals.insertLifecycleEvent(lifecycleEvent);

    return result;
  }
}

// ── ArchiveGoalUseCase ─────────────────────────────────────────────────────

final class ArchiveGoalUseCase {
  const ArchiveGoalUseCase(this._goals);

  final GoalRepository _goals;

  Future<AppResult<void>> execute({
    required String goalId,
    required String householdId,
  }) async {
    final goalResult = await _goals.findGoalById(goalId);
    if (goalResult is! AppOk<SavingsGoal?>) {
      return const AppPersistenceFailure();
    }
    final goal = goalResult.value;
    if (goal == null) return const AppNotFound();

    // Balance must be zero before archiving.
    final balanceResult = await _goals.getReserveBalance(
      reserveAccountId: goal.reserveAccountId,
      householdId: householdId,
    );
    if (balanceResult is! AppOk<int>) return const AppPersistenceFailure();
    if (balanceResult.value != 0) {
      return const AppValidationFailure(
        field: 'balance',
        messageKey: 'errorGoalArchiveNonzeroBalance',
      );
    }

    return _goals.updateGoalStatus(
      goalId: goalId,
      status: GoalStatus.archived,
      archivedAt: _nowUtc(),
    );
  }
}

// ── RestoreGoalUseCase ─────────────────────────────────────────────────────

final class RestoreGoalUseCase {
  const RestoreGoalUseCase(this._goals);

  final GoalRepository _goals;

  Future<AppResult<void>> execute({
    required String goalId,
    String? idempotencyKey,
  }) async {
    final goalResult = await _goals.findGoalById(goalId);
    if (goalResult is! AppOk<SavingsGoal?>) {
      return const AppPersistenceFailure();
    }
    final goal = goalResult.value;
    if (goal == null) return const AppNotFound();

    if (goal.status != GoalStatus.archived) {
      return const AppValidationFailure(
        field: 'goalId',
        messageKey: 'errorGoalRestoreRequiresArchived',
      );
    }

    final updateResult = await _goals.updateGoalStatus(
      goalId: goalId,
      status: GoalStatus.active,
      archivedAt: null,
    );
    if (updateResult is! AppOk<void>) return updateResult;

    final now = _nowUtc();
    final key = idempotencyKey ?? 'restore-$goalId';
    await _goals.insertLifecycleEvent(
      GoalLifecycleEvent(
        id: '$goalId-lce-restore-${now.replaceAll(':', '').replaceAll('.', '')}',
        goalId: goalId,
        householdId: goal.householdId,
        eventType: GoalLifecycleEventType.restored,
        idempotencyKey: key,
        effectiveAt: now,
        createdAt: now,
      ),
    );
    return const AppOk(null);
  }
}

// ── ReverseGoalTransferUseCase ─────────────────────────────────────────────

/// Reverses a ledger transfer and, if the transfer was a goal funding or
/// release, creates a linked [GoalMovementType.reversal] movement on the goal.
///
/// Phase 5B.5: the entire reversal (idempotency, ledger mirrors, original
/// operation mark, operation context, and goal movement) is performed inside a
/// single repository transaction. Conflicting idempotency keys surface as
/// [AppDuplicateConflict].
final class ReverseGoalTransferUseCase {
  const ReverseGoalTransferUseCase({
    required GoalRepository goalRepository,
    // Kept for API compatibility; ledger work is inside the atomic goal repo.
    LedgerRepository? ledgerRepository,
  }) : _goals = goalRepository;

  final GoalRepository _goals;

  Future<AppResult<void>> execute({
    required String originalOperationId,
    required String reversalOperationId,
    required String householdId,
    required String effectiveDate,
    required String createdBy,
    String? reason,
    String? idempotencyKey,
  }) {
    return _goals.reverseGoalTransfer(
      originalOperationId: originalOperationId,
      reversalOperationId: reversalOperationId,
      householdId: householdId,
      effectiveDate: effectiveDate,
      createdBy: createdBy,
      reason: reason,
      idempotencyKey: idempotencyKey,
    );
  }
}
