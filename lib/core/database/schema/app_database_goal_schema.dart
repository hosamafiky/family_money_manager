part of '../app_database.dart';

/// Goals / reserve / lifecycle schema helpers (Phases 5B–5B.8).
mixin _AppDatabaseGoalSchema on _$AppDatabase {
  Future<void> _applyGoalImmutabilityTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_goal_revisions
      BEFORE UPDATE ON goal_revisions
      BEGIN
        SELECT RAISE(ABORT, 'goal_revisions are immutable and cannot be updated');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_goal_revisions
      BEFORE DELETE ON goal_revisions
      BEGIN
        SELECT RAISE(ABORT, 'goal_revisions cannot be deleted');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_goal_movements
      BEFORE UPDATE ON goal_movements
      BEGIN
        SELECT RAISE(ABORT, 'goal_movements are immutable and cannot be updated');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_goal_movements
      BEFORE DELETE ON goal_movements
      BEGIN
        SELECT RAISE(ABORT, 'goal_movements cannot be deleted');
      END
    ''');
  }

  // ── Goal indexes (Phase 5B) ────────────────────────────────────────────────

  Future<void> _applyGoalIndexes() async {
    // One reserve account per goal, and each reserve account belongs to at
    // most one goal.
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goals_reserve_account
      ON goals(reserve_account_id)
    ''');
    // Scoped idempotency for goals.
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goals_idempotency
      ON goals(household_id, idempotency_key)
    ''');
    // Performance index for revision queries.
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_goal_revisions_goal
      ON goal_revisions(goal_id)
    ''');
    // Performance index for movement queries.
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_goal_movements_goal
      ON goal_movements(goal_id)
    ''');
    // Enables fast lookup of all movements for a given transfer operation.
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_goal_movements_operation
      ON goal_movements(transfer_operation_id)
    ''');
  }

  // ── Goal table hardening triggers (Phase 5B.1) ────────────────────────────
  //
  // 1. Prevents updating immutable goal fields after creation.
  // 2. Prevents deleting a goal that has any linked revisions or movements.
  // 3. Enforces valid status transitions.

  Future<void> _applyGoalTableHardeningTriggers() async {
    // Block mutation of structural/identity fields.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_goal_immutable
      BEFORE UPDATE ON goals
      FOR EACH ROW
      WHEN NEW.household_id     != OLD.household_id
        OR NEW.reserve_account_id != OLD.reserve_account_id
        OR NEW.currency_code    != OLD.currency_code
        OR NEW.idempotency_key  != OLD.idempotency_key
        OR NEW.created_at       != OLD.created_at
      BEGIN
        SELECT RAISE(ABORT, 'goal immutable fields cannot be changed');
      END
    ''');

    // Prevent deleting a goal that has audit history.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_goal_with_history
      BEFORE DELETE ON goals
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'cannot delete goal with revisions or movements')
        WHERE EXISTS (SELECT 1 FROM goal_revisions WHERE goal_id = OLD.id)
           OR EXISTS (SELECT 1 FROM goal_movements WHERE goal_id = OLD.id);
      END
    ''');

    // Enforce recognised lifecycle status transitions (Phase 5B.8).
    // Valid: active→completed, active→archived,
    //        completed→archived, archived→active (restore).
    // Progress is never persisted — no targetReached transitions.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_status_valid_transition
      BEFORE UPDATE ON goals
      FOR EACH ROW
      WHEN NEW.status != OLD.status
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal status transition')
        WHERE NOT (
          (OLD.status = 'active'    AND NEW.status IN ('completed','archived'))
          OR (OLD.status = 'completed' AND NEW.status = 'archived')
          OR (OLD.status = 'archived'  AND NEW.status = 'active')
        );
      END
    ''');
  }

  // ── Reserve-account classification hardening (Phase 5B.1) ─────────────────
  //
  // 1. Prevents reclassifying a goalReserve account to any other type.
  //    (Defense-in-depth: immutable_account_type_currency already blocks all
  //    type changes; this trigger adds a clear semantic error message.)
  // 2. Prevents archiving a reserve account while its goal is still active.

  Future<void> _applyReserveAccountHardeningTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_retype_reserve_account
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.type != 'goalReserve'
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve account type cannot be changed');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_archive_active_reserve
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve'
        AND NEW.is_archived = 1
        AND OLD.is_archived = 0
      BEGIN
        SELECT RAISE(ABORT, 'cannot archive reserve account of an active goal')
        WHERE EXISTS (
          SELECT 1 FROM goals
          WHERE reserve_account_id = OLD.id
            AND status != 'archived'
        );
      END
    ''');
  }

  // ── Goal movements hardening (Phase 5B.1 / 5B.4) ─────────────────────────
  //
  // 1. Release movements must have a non-empty release_reason.
  // 2. The linked operation must exist and be of type 'transfer' (v11) or
  //    'reversal' (v12+, for reversal goal movements).
  //
  // Use [_applyGoalMovementsHardeningTriggersV12] for all fresh installs.
  // The legacy [_applyGoalMovementsHardeningTriggers] kept for reference;
  // call only during historical migration paths that don't reach v12 yet.

  Future<void> _applyGoalMovementsHardeningTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_movement_release_reason
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'release'
        AND (NEW.release_reason IS NULL OR length(trim(NEW.release_reason)) = 0)
      BEGIN
        SELECT RAISE(ABORT, 'release movement must have a non-empty release_reason');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_movement_transfer_type
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'goal movement must reference a transfer operation')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations
          WHERE id = NEW.transfer_operation_id
            AND type = 'transfer'
        );
      END
    ''');
  }

  Future<void> _applyGoalMovementsHardeningTriggersV12() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_movement_release_reason
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'release'
        AND (NEW.release_reason IS NULL OR length(trim(NEW.release_reason)) = 0)
      BEGIN
        SELECT RAISE(ABORT, 'release movement must have a non-empty release_reason');
      END
    ''');

    // In v12+, reversal goal movements reference a 'reversal' operation;
    // allow both 'transfer' and 'reversal' operation types.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_movement_transfer_type
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'goal movement must reference a transfer or reversal operation')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations
          WHERE id = NEW.transfer_operation_id
            AND type IN ('transfer', 'reversal')
        );
      END
    ''');
  }

  // ── Beneficiary household integrity (Phase 5B.1) ──────────────────────────
  //
  // Ensures that when a beneficiary_member_id is set on a goal revision,
  // that member belongs to the same household as the goal.

  Future<void> _applyGoalRevisionBeneficiaryTrigger() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_revision_beneficiary_same_household
      BEFORE INSERT ON goal_revisions
      FOR EACH ROW
      WHEN NEW.beneficiary_member_id IS NOT NULL
      BEGIN
        SELECT RAISE(ABORT, 'beneficiary must belong to same household as goal')
        WHERE NOT EXISTS (
          SELECT 1 FROM household_members hm
          JOIN goals g ON g.household_id = hm.household_id
          WHERE hm.id = NEW.beneficiary_member_id
            AND g.id  = NEW.goal_id
        );
      END
    ''');
  }

  // ── Goal movements unique-operation index (Phase 5B.1) ────────────────────
  //
  // Each transfer operation can link to at most one goal movement,
  // preventing duplicate movements for the same underlying transfer.

  Future<void> _applyGoalMovementsUniqueIndex() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_movements_unique_operation
      ON goal_movements(transfer_operation_id)
    ''');
  }

  // ── Reserve is_spendable / is_protected immutability (Phase 5B.2) ─────────
  //
  // A goalReserve account's is_spendable and is_protected columns must never
  // change after creation, regardless of whether financial history exists.
  // This is defence-in-depth on top of the post-history classification lock.

  Future<void> _applyReserveSpendableProtectedTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_reserve_spendable
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.is_spendable != OLD.is_spendable
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve is_spendable cannot be changed');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_reserve_protected
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.is_protected != OLD.is_protected
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve is_protected cannot be changed');
      END
    ''');
  }

  // ── Goal movement direction-validation triggers (Phase 5B.2) ─────────────
  //
  // Funding movements: the linked transfer operation must have the goal's
  // reserve account as destination.
  //
  // Release movements: the linked transfer operation must have the goal's
  // reserve account as source, AND the release_reason must be non-empty.

  Future<void> _applyGoalMovementsDirectionTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_funding_movement
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'funding'
      BEGIN
        SELECT RAISE(ABORT, 'funding movement: operation must be a transfer to the reserve')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations o
          JOIN goals g ON g.id = NEW.goal_id
          WHERE o.id = NEW.transfer_operation_id
            AND o.type = 'transfer'
            AND o.destination_account_id = g.reserve_account_id
            AND o.household_id = NEW.household_id
        );
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_release_movement
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'release'
      BEGIN
        SELECT RAISE(ABORT, 'release movement: operation must be a transfer from the reserve, reason required')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations o
          JOIN goals g ON g.id = NEW.goal_id
          WHERE o.id = NEW.transfer_operation_id
            AND o.type = 'transfer'
            AND o.source_account_id = g.reserve_account_id
            AND o.household_id = NEW.household_id
        )
        OR (NEW.release_reason IS NULL OR length(trim(NEW.release_reason)) = 0);
      END
    ''');
  }

  // ── Phase 5B.3: Goal-reserve INSERT validator (legacy, v11 only) ──────────
  //
  // Ensures every new goal row references an account that is a goalReserve
  // type in the same household with the same currency, is not spendable,
  // and is not protected.
  //
  // Use [_applyGoalReserveInsertValidatorV12] for all fresh installs and v12+
  // migrations — it additionally enforces owner_type = 'household'.

  Future<void> _applyGoalReserveInsertValidator() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_goal_reserve_on_insert
      BEFORE INSERT ON goals
      BEGIN
        SELECT RAISE(ABORT, 'goal reserve must be a goalReserve account in the same household with same currency')
        WHERE NOT EXISTS (
          SELECT 1 FROM financial_accounts fa
          WHERE fa.id = NEW.reserve_account_id
            AND fa.type = 'goalReserve'
            AND fa.household_id = NEW.household_id
            AND fa.currency_code = NEW.currency_code
            AND fa.is_spendable = 0
            AND fa.is_protected = 0
        );
      END
    ''');
  }

  // ── Phase 5B.4: Goal-reserve INSERT validator (v12) ───────────────────────
  //
  // Extended to also require owner_type = 'household', rejecting child,
  // spouse, and personal-owner reserves.

  Future<void> _applyGoalReserveInsertValidatorV12() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_goal_reserve_on_insert
      BEFORE INSERT ON goals
      BEGIN
        SELECT RAISE(ABORT, 'goal reserve must be a goalReserve account: correct type, household, currency, owner')
        WHERE NOT EXISTS (
          SELECT 1 FROM financial_accounts fa
          WHERE fa.id = NEW.reserve_account_id
            AND fa.type = 'goalReserve'
            AND fa.household_id = NEW.household_id
            AND fa.currency_code = NEW.currency_code
            AND fa.is_spendable = 0
            AND fa.is_protected = 0
            AND fa.owner_type = 'household'
        );
      END
    ''');
  }

  // ── Phase 5B.4: Reserve owner_type immutability trigger ──────────────────
  //
  // Prevents post-linkage mutation of owner_type on a goalReserve account.

  Future<void> _applyReserveOwnerTypeTrigger() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_reserve_owner_type
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.owner_type != OLD.owner_type
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve owner_type cannot be changed after linkage');
      END
    ''');
  }

  // ── Phase 5B.4: Goal lifecycle events triggers ────────────────────────────
  //
  // goal_lifecycle_events rows are write-once (no UPDATE or DELETE).

  Future<void> _applyGoalLifecycleEventsTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_goal_lifecycle_events
      BEFORE UPDATE ON goal_lifecycle_events
      BEGIN
        SELECT RAISE(ABORT, 'goal lifecycle events are immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_goal_lifecycle_events
      BEFORE DELETE ON goal_lifecycle_events
      BEGIN
        SELECT RAISE(ABORT, 'goal lifecycle events cannot be deleted');
      END
    ''');
    // Enforce household_id FK: the goal_lifecycle_events.household_id must
    // reference an existing row in households (simulated FK since the Drift
    // table definition uses plain TextColumn, not .references()).
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS fk_goal_lifecycle_event_household_id
      BEFORE INSERT ON goal_lifecycle_events
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'goal_lifecycle_events.household_id must reference a valid household')
        WHERE NOT EXISTS (
          SELECT 1 FROM households WHERE id = NEW.household_id
        );
      END
    ''');
  }

  // ── Phase 5B.4: Goal lifecycle events idempotency index ──────────────────

  Future<void> _applyGoalLifecycleEventsIndex() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_lifecycle_events_idempotency
      ON goal_lifecycle_events(idempotency_key)
      WHERE idempotency_key IS NOT NULL
    ''');
  }

  // ── Phase 5B.3: Extended movement household validation ────────────────────
  //
  // Validates that the operation's household, source/destination accounts'
  // households all match the movement's household_id.

  Future<void> _applyGoalMovementsHouseholdTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_funding_movement_household
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'funding'
      BEGIN
        SELECT RAISE(ABORT, 'funding movement validation failed: cross-household or wrong direction')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations o
          JOIN goals g ON g.id = NEW.goal_id
          JOIN financial_accounts src ON src.id = o.source_account_id
          JOIN financial_accounts dst ON dst.id = o.destination_account_id
          WHERE o.id = NEW.transfer_operation_id
            AND o.type = 'transfer'
            AND o.destination_account_id = g.reserve_account_id
            AND o.household_id = NEW.household_id
            AND g.household_id = NEW.household_id
            AND src.household_id = NEW.household_id
            AND dst.household_id = NEW.household_id
        );
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_release_movement_household
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'release'
      BEGIN
        SELECT RAISE(ABORT, 'release movement validation failed: cross-household or wrong direction')
        WHERE NOT EXISTS (
          SELECT 1 FROM operations o
          JOIN goals g ON g.id = NEW.goal_id
          JOIN financial_accounts src ON src.id = o.source_account_id
          JOIN financial_accounts dst ON dst.id = o.destination_account_id
          WHERE o.id = NEW.transfer_operation_id
            AND o.type = 'transfer'
            AND o.source_account_id = g.reserve_account_id
            AND o.household_id = NEW.household_id
            AND g.household_id = NEW.household_id
            AND src.household_id = NEW.household_id
            AND dst.household_id = NEW.household_id
        )
        OR (NEW.release_reason IS NULL OR length(trim(NEW.release_reason)) = 0);
      END
    ''');
  }

  // ── Phase 5B.5: Reversal linkage + lifecycle household isolation ──────────

  Future<void> _applyPhase5B5ReversalAndLifecycleHardening() async {
    // Reversal movement must reference a valid original of the same
    // goal/household; the linked operation must be type = 'reversal'.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_reversal_movement_link
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.reversal_of_movement_id IS NOT NULL OR NEW.movement_type = 'reversal'
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal reversal linkage')
        WHERE NOT EXISTS (
          SELECT 1 FROM goal_movements orig
          JOIN operations o ON o.id = NEW.transfer_operation_id
          WHERE orig.id = NEW.reversal_of_movement_id
            AND orig.goal_id = NEW.goal_id
            AND orig.household_id = NEW.household_id
            AND orig.movement_type IN ('funding', 'release')
            AND o.type = 'reversal'
            AND o.household_id = NEW.household_id
        );
      END
    ''');

    // V1: at most one reversal movement per original movement.
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_movements_one_reversal_per_original
      ON goal_movements(reversal_of_movement_id)
      WHERE reversal_of_movement_id IS NOT NULL
    ''');

    // Lifecycle event household must equal the referenced goal's household.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_lifecycle_household_matches_goal
      BEFORE INSERT ON goal_lifecycle_events
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'lifecycle event household must match goal household')
        WHERE NOT EXISTS (
          SELECT 1 FROM goals g
          WHERE g.id = NEW.goal_id
            AND g.household_id = NEW.household_id
        );
      END
    ''');

    // Replace global unique idempotency with household-scoped uniqueness.
    await customStatement(
      'DROP INDEX IF EXISTS idx_goal_lifecycle_events_idempotency',
    );
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_lifecycle_hh_idem
      ON goal_lifecycle_events(household_id, idempotency_key)
      WHERE idempotency_key IS NOT NULL
    ''');
  }

  // ── Phase 5B.6: Balanced goal-transfer ledger linkage ─────────────────────
  //
  // Before a funding/release goal movement is inserted, prove the linked
  // operation has exactly one debit and one credit, amounts equal and positive,
  // accounts matching operation source/destination, and matching currency /
  // household. Additional legs are rejected.

  Future<void> _applyPhase5B6BalancedMovementTrigger() async {
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS validate_goal_transfer_balanced_legs '
      'BEFORE INSERT ON goal_movements '
      'FOR EACH ROW '
      "WHEN NEW.movement_type IN ('funding', 'release') "
      'BEGIN '
      '  SELECT RAISE( '
      '    ABORT, '
      "    'goal movement requires exactly two balanced ledger legs matching operation' "
      '  ) '
      '  WHERE ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      '  ) != 2 '
      '  OR ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      "      AND e.direction = 'debit' "
      '  ) != 1 '
      '  OR ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      "      AND e.direction = 'credit' "
      '  ) != 1 '
      '  OR NOT EXISTS ( '
      '    SELECT 1 '
      '    FROM operations o '
      "    JOIN ledger_entries d ON d.operation_id = o.id AND d.direction = 'debit' "
      "    JOIN ledger_entries c ON c.operation_id = o.id AND c.direction = 'credit' "
      '    WHERE o.id = NEW.transfer_operation_id '
      '      AND o.household_id = NEW.household_id '
      '      AND d.account_id = o.source_account_id '
      '      AND c.account_id = o.destination_account_id '
      '      AND d.amount_minor_units = c.amount_minor_units '
      '      AND d.amount_minor_units = o.total_amount_minor_units '
      '      AND d.amount_minor_units > 0 '
      '      AND c.amount_minor_units > 0 '
      '      AND d.currency_code = o.currency_code '
      '      AND c.currency_code = o.currency_code '
      '      AND d.household_id = o.household_id '
      '      AND c.household_id = o.household_id '
      '  ); '
      'END',
    );
  }

  // ── Phase 5B.7: Reversal balanced legs + explicit status-transition alias ──

  Future<void> _applyPhase5B7ReversalBalancedAndStatusTriggers() async {
    // Reversal goal movements must prove balanced inverse mirror legs.
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS validate_goal_reversal_balanced_legs '
      'BEFORE INSERT ON goal_movements '
      'FOR EACH ROW '
      "WHEN NEW.movement_type = 'reversal' "
      'BEGIN '
      '  SELECT RAISE( '
      '    ABORT, '
      "    'goal reversal movement requires balanced inverse ledger legs' "
      '  ) '
      '  WHERE NEW.reversal_of_movement_id IS NULL '
      '  OR ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      '  ) != 2 '
      '  OR ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      "      AND e.direction = 'debit' "
      '  ) != 1 '
      '  OR ( '
      '    SELECT COUNT(*) FROM ledger_entries e '
      '    WHERE e.operation_id = NEW.transfer_operation_id '
      "      AND e.direction = 'credit' "
      '  ) != 1 '
      '  OR NOT EXISTS ( '
      '    SELECT 1 '
      '    FROM operations rev '
      '    JOIN goal_movements orig_mov ON orig_mov.id = NEW.reversal_of_movement_id '
      '    JOIN operations orig ON orig.id = orig_mov.transfer_operation_id '
      "    JOIN ledger_entries d ON d.operation_id = rev.id AND d.direction = 'debit' "
      "    JOIN ledger_entries c ON c.operation_id = rev.id AND c.direction = 'credit' "
      '    WHERE rev.id = NEW.transfer_operation_id '
      "      AND rev.type = 'reversal' "
      '      AND rev.household_id = NEW.household_id '
      '      AND orig.household_id = NEW.household_id '
      '      AND orig_mov.goal_id = NEW.goal_id '
      '      AND orig_mov.household_id = NEW.household_id '
      "      AND orig_mov.movement_type IN ('funding', 'release') "
      '      AND orig.is_reversed = 1 '
      '      AND orig.reversed_by = rev.id '
      // Entry accounts must be the inverse of the original transfer accounts:
      // debit the original destination; credit the original source.
      '      AND d.account_id = orig.destination_account_id '
      '      AND c.account_id = orig.source_account_id '
      '      AND d.account_id = rev.source_account_id '
      '      AND c.account_id = rev.destination_account_id '
      '      AND d.amount_minor_units = c.amount_minor_units '
      '      AND d.amount_minor_units = rev.total_amount_minor_units '
      '      AND d.amount_minor_units = orig.total_amount_minor_units '
      '      AND d.amount_minor_units > 0 '
      '      AND c.amount_minor_units > 0 '
      '      AND d.currency_code = rev.currency_code '
      '      AND c.currency_code = rev.currency_code '
      '      AND rev.currency_code = orig.currency_code '
      '      AND d.household_id = rev.household_id '
      '      AND c.household_id = rev.household_id '
      '  ); '
      'END',
    );

    // Explicit product-policy alias (same allowed set as goal_status_valid_transition).
    // Forbidden: completed→active, archived→completed, targetReached, and any other path.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS reject_unsupported_goal_status_transition
      BEFORE UPDATE OF status ON goals
      FOR EACH ROW
      WHEN NEW.status != OLD.status
        AND NOT (
          (OLD.status = 'active' AND NEW.status IN ('completed','archived'))
          OR (OLD.status = 'completed' AND NEW.status = 'archived')
          OR (OLD.status = 'archived' AND NEW.status = 'active')
        )
      BEGIN
        SELECT RAISE(ABORT, 'unsupported goal status transition');
      END
    ''');
  }

  // ── Phase 5B.8: Lifecycle / derived-progress separation ───────────────────

  Future<void> _applyPhase5B8LifecycleProgressSeparation() async {
    // Drop transition triggers BEFORE migrating rows: the legacy allowed set
    // never included targetReached→active, so the data fix would abort.
    await customStatement(
      'DROP TRIGGER IF EXISTS goal_status_valid_transition',
    );
    await customStatement(
      'DROP TRIGGER IF EXISTS reject_unsupported_goal_status_transition',
    );
    await customStatement('DROP TRIGGER IF EXISTS check_goal_lifecycle_status');
    await customStatement(
      'DROP TRIGGER IF EXISTS check_goal_lifecycle_status_update',
    );

    // Migrate any persisted progress-as-lifecycle rows to active.
    // Does NOT insert completion lifecycle events.
    await customStatement(
      "UPDATE goals SET status = 'active' WHERE status = 'targetReached'",
    );

    // Recreate transition triggers without targetReached.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS goal_status_valid_transition
      BEFORE UPDATE ON goals
      FOR EACH ROW
      WHEN NEW.status != OLD.status
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal status transition')
        WHERE NOT (
          (OLD.status = 'active'    AND NEW.status IN ('completed','archived'))
          OR (OLD.status = 'completed' AND NEW.status = 'archived')
          OR (OLD.status = 'archived'  AND NEW.status = 'active')
        );
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS reject_unsupported_goal_status_transition
      BEFORE UPDATE OF status ON goals
      FOR EACH ROW
      WHEN NEW.status != OLD.status
        AND NOT (
          (OLD.status = 'active' AND NEW.status IN ('completed','archived'))
          OR (OLD.status = 'completed' AND NEW.status = 'archived')
          OR (OLD.status = 'archived' AND NEW.status = 'active')
        )
      BEGIN
        SELECT RAISE(ABORT, 'unsupported goal status transition');
      END
    ''');

    // Reject invalid lifecycle values on INSERT / UPDATE OF status.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_goal_lifecycle_status
      BEFORE INSERT ON goals
      FOR EACH ROW
      WHEN NEW.status NOT IN ('active', 'completed', 'archived')
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal lifecycle status');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_goal_lifecycle_status_update
      BEFORE UPDATE OF status ON goals
      FOR EACH ROW
      WHEN NEW.status NOT IN ('active', 'completed', 'archived')
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal lifecycle status');
      END
    ''');
  }

  // ── Phase 6A: Savings certificates ────────────────────────────────────────

}
