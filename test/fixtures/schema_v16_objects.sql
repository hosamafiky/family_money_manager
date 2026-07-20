-- True schema v16 objects from onCreate at commit 86736ca (Phase 5B.8 docs pin).
-- Tables materialised separately from Drift CREATE TABLE DDL
-- (exclude savings_certificates / certificate_revisions / certificate_events).
-- This is NOT create-v17-then-delete; certificate objects are never created.

CREATE TRIGGER IF NOT EXISTS no_update_ledger_entries
      BEFORE UPDATE ON ledger_entries
      BEGIN
        SELECT RAISE(ABORT, 'Ledger entries are immutable and cannot be updated');
      END;

CREATE TRIGGER IF NOT EXISTS no_delete_ledger_entries
      BEFORE DELETE ON ledger_entries
      BEGIN
        SELECT RAISE(ABORT, 'Ledger entries cannot be deleted');
      END;

CREATE TRIGGER IF NOT EXISTS no_update_child_audits
      BEFORE UPDATE ON child_withdrawal_audits
      BEGIN
        SELECT RAISE(ABORT, 'Child withdrawal audits are immutable and cannot be updated');
      END;

CREATE TRIGGER IF NOT EXISTS no_delete_child_audits
      BEFORE DELETE ON child_withdrawal_audits
      BEGIN
        SELECT RAISE(ABORT, 'Child withdrawal audits cannot be deleted');
      END;

CREATE TRIGGER IF NOT EXISTS restrict_operations_update BEFORE UPDATE ON operations WHEN NEW.id != OLD.id OR NEW.household_id != OLD.household_id   OR NEW.type != OLD.type OR NEW.effective_date != OLD.effective_date   OR NEW.recorded_at != OLD.recorded_at   OR NEW.total_amount_minor_units != OLD.total_amount_minor_units   OR NEW.currency_code != OLD.currency_code   OR NEW.created_by != OLD.created_by OR NEW.created_at != OLD.created_at BEGIN   SELECT RAISE(ABORT, 'Operations are append-only: only is_reversed, reversed_by, and updated_at may change'); END;

CREATE TRIGGER IF NOT EXISTS no_delete_operations BEFORE DELETE ON operations BEGIN   SELECT RAISE(ABORT, 'Operations cannot be deleted; use a reversal operation instead'); END;

CREATE TRIGGER IF NOT EXISTS check_ledger_entry_amount
      BEFORE INSERT ON ledger_entries
      WHEN NEW.amount_minor_units <= 0
      BEGIN
        SELECT RAISE(ABORT, 'ledger_entries.amount_minor_units must be > 0');
      END;

CREATE TRIGGER IF NOT EXISTS check_audit_amount
      BEFORE INSERT ON child_withdrawal_audits
      WHEN NEW.amount_minor_units <= 0
      BEGIN
        SELECT RAISE(ABORT, 'child_withdrawal_audits.amount_minor_units must be > 0');
      END;

CREATE TRIGGER IF NOT EXISTS check_audit_warning_shown
      BEFORE INSERT ON child_withdrawal_audits
      WHEN NEW.warning_shown != 1
      BEGIN
        SELECT RAISE(ABORT, 'child_withdrawal_audits.warning_shown must be true (1)');
      END;

CREATE TRIGGER IF NOT EXISTS check_audit_reason
      BEFORE INSERT ON child_withdrawal_audits
      WHEN length(trim(NEW.reason)) = 0
      BEGIN
        SELECT RAISE(ABORT, 'child_withdrawal_audits.reason must not be empty');
      END;

CREATE TRIGGER IF NOT EXISTS check_operation_amount
      BEFORE INSERT ON operations
      WHEN NEW.total_amount_minor_units < 0
      BEGIN
        SELECT RAISE(ABORT, 'operations.total_amount_minor_units must be >= 0');
      END;

CREATE TRIGGER IF NOT EXISTS fk_ledger_entry_operation_id BEFORE INSERT ON ledger_entries WHEN NOT EXISTS (  SELECT 1 FROM operations   WHERE id = NEW.operation_id AND household_id = NEW.household_id) BEGIN   SELECT RAISE(ABORT, 'ledger_entries.operation_id must reference an existing operations.id in the same household'); END;

CREATE TRIGGER IF NOT EXISTS fk_audit_operation_household BEFORE INSERT ON child_withdrawal_audits WHEN NOT EXISTS (  SELECT 1 FROM operations   WHERE id = NEW.operation_id AND household_id = NEW.household_id) BEGIN   SELECT RAISE(ABORT, 'child_withdrawal_audits.operation_id must reference an operation in the same household'); END;

CREATE UNIQUE INDEX IF NOT EXISTS idx_ledger_idempotency
      ON ledger_entries(operation_id, account_id, direction, entry_type);

CREATE INDEX IF NOT EXISTS idx_ledger_entries_account
      ON ledger_entries(account_id);

CREATE INDEX IF NOT EXISTS idx_ledger_entries_operation
      ON ledger_entries(operation_id);

CREATE INDEX IF NOT EXISTS idx_ledger_entries_effective_date
      ON ledger_entries(effective_date);

CREATE INDEX IF NOT EXISTS idx_ledger_entries_household
      ON ledger_entries(household_id);

CREATE INDEX IF NOT EXISTS idx_operations_household
      ON operations(household_id);

CREATE INDEX IF NOT EXISTS idx_operations_date
      ON operations(effective_date);

CREATE INDEX IF NOT EXISTS idx_operations_type
      ON operations(type);

CREATE INDEX IF NOT EXISTS idx_financial_accounts_household
      ON financial_accounts(household_id);

CREATE INDEX IF NOT EXISTS idx_financial_accounts_archived
      ON financial_accounts(is_archived);

CREATE UNIQUE INDEX IF NOT EXISTS idx_operations_idempotency_key
      ON operations(household_id, idempotency_key)
      WHERE idempotency_key IS NOT NULL;

CREATE TRIGGER IF NOT EXISTS one_primary_user_per_household BEFORE INSERT ON household_members WHEN NEW.role = 'primary_user' AND NEW.is_archived = 0 BEGIN   SELECT RAISE(ABORT, 'Only one active primary_user per household')   WHERE EXISTS (     SELECT 1 FROM household_members     WHERE household_id = NEW.household_id       AND role = 'primary_user'       AND is_archived = 0   ); END;

CREATE TRIGGER IF NOT EXISTS one_spouse_per_household BEFORE INSERT ON household_members WHEN NEW.role = 'spouse' AND NEW.is_archived = 0 BEGIN   SELECT RAISE(ABORT, 'Only one active spouse per household in V1')   WHERE EXISTS (     SELECT 1 FROM household_members     WHERE household_id = NEW.household_id       AND role = 'spouse'       AND is_archived = 0   ); END;

CREATE TRIGGER IF NOT EXISTS no_cross_household_member BEFORE INSERT ON household_members BEGIN   SELECT RAISE(ABORT, 'household_members.household_id must match household.id')   WHERE NOT EXISTS (     SELECT 1 FROM households WHERE id = NEW.household_id   ); END;

CREATE TRIGGER IF NOT EXISTS immutable_account_type_currency BEFORE UPDATE ON financial_accounts WHEN OLD.type != NEW.type OR OLD.currency_code != NEW.currency_code BEGIN   SELECT RAISE(ABORT, 'Account type and currency are immutable after creation'); END;

CREATE TRIGGER IF NOT EXISTS restrict_account_classification_update
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN (
        (SELECT COUNT(*) FROM ledger_entries WHERE account_id = OLD.id) > 0
      )
      BEGIN
        SELECT CASE
          WHEN NEW.type != OLD.type THEN
            RAISE(ABORT, 'Account type is immutable once financial history exists')
          WHEN NEW.currency_code != OLD.currency_code THEN
            RAISE(ABORT, 'Account currency is immutable once financial history exists')
          WHEN NEW.owner_type != OLD.owner_type THEN
            RAISE(ABORT, 'Account owner_type is immutable once financial history exists')
          WHEN NEW.fund_purpose != OLD.fund_purpose THEN
            RAISE(ABORT, 'Account fund_purpose is immutable once financial history exists')
          WHEN NEW.is_protected != OLD.is_protected THEN
            RAISE(ABORT, 'Account is_protected is immutable once financial history exists')
          WHEN NEW.is_spendable != OLD.is_spendable THEN
            RAISE(ABORT, 'Account is_spendable is immutable once financial history exists')
          WHEN NEW.include_in_net_worth != OLD.include_in_net_worth THEN
            RAISE(ABORT, 'Account include_in_net_worth is immutable once financial history exists')
          WHEN NEW.include_in_zakat != OLD.include_in_zakat THEN
            RAISE(ABORT, 'Account include_in_zakat is immutable once financial history exists')
        END;
      END;

CREATE TRIGGER IF NOT EXISTS restrict_child_fund_unprotect
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN NEW.type = 'childProtectedFund' AND NEW.is_protected = 0
      BEGIN
        SELECT RAISE(ABORT, 'Child protected fund cannot have is_protected disabled');
      END;

CREATE TRIGGER IF NOT EXISTS fk_operation_context_operation_id BEFORE INSERT ON operation_contexts WHEN NOT EXISTS (   SELECT 1 FROM operations WHERE id = NEW.operation_id ) BEGIN   SELECT RAISE(ABORT, 'operation_contexts.operation_id must reference an existing operations.id'); END;

CREATE TRIGGER IF NOT EXISTS no_update_operation_contexts BEFORE UPDATE ON operation_contexts BEGIN   SELECT RAISE(ABORT, 'Operation contexts are immutable and cannot be updated'); END;

CREATE TRIGGER IF NOT EXISTS no_delete_operation_contexts BEFORE DELETE ON operation_contexts BEGIN   SELECT RAISE(ABORT, 'Operation contexts cannot be deleted'); END;

CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_accounts_idempotency
      ON financial_accounts(household_id, idempotency_key)
      WHERE idempotency_key IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_idempotency
      ON budgets(household_id, idempotency_key);

CREATE TRIGGER IF NOT EXISTS no_update_goal_revisions
      BEFORE UPDATE ON goal_revisions
      BEGIN
        SELECT RAISE(ABORT, 'goal_revisions are immutable and cannot be updated');
      END;

CREATE TRIGGER IF NOT EXISTS no_delete_goal_revisions
      BEFORE DELETE ON goal_revisions
      BEGIN
        SELECT RAISE(ABORT, 'goal_revisions cannot be deleted');
      END;

CREATE TRIGGER IF NOT EXISTS no_update_goal_movements
      BEFORE UPDATE ON goal_movements
      BEGIN
        SELECT RAISE(ABORT, 'goal_movements are immutable and cannot be updated');
      END;

CREATE TRIGGER IF NOT EXISTS no_delete_goal_movements
      BEFORE DELETE ON goal_movements
      BEGIN
        SELECT RAISE(ABORT, 'goal_movements cannot be deleted');
      END;

CREATE UNIQUE INDEX IF NOT EXISTS idx_goals_reserve_account
      ON goals(reserve_account_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_goals_idempotency
      ON goals(household_id, idempotency_key);

CREATE INDEX IF NOT EXISTS idx_goal_revisions_goal
      ON goal_revisions(goal_id);

CREATE INDEX IF NOT EXISTS idx_goal_movements_goal
      ON goal_movements(goal_id);

CREATE INDEX IF NOT EXISTS idx_goal_movements_operation
      ON goal_movements(transfer_operation_id);

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
      END;

CREATE TRIGGER IF NOT EXISTS no_delete_goal_with_history
      BEFORE DELETE ON goals
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'cannot delete goal with revisions or movements')
        WHERE EXISTS (SELECT 1 FROM goal_revisions WHERE goal_id = OLD.id)
           OR EXISTS (SELECT 1 FROM goal_movements WHERE goal_id = OLD.id);
      END;

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
      END;

CREATE TRIGGER IF NOT EXISTS no_retype_reserve_account
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.type != 'goalReserve'
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve account type cannot be changed');
      END;

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
      END;

CREATE TRIGGER IF NOT EXISTS goal_movement_release_reason
      BEFORE INSERT ON goal_movements
      FOR EACH ROW
      WHEN NEW.movement_type = 'release'
        AND (NEW.release_reason IS NULL OR length(trim(NEW.release_reason)) = 0)
      BEGIN
        SELECT RAISE(ABORT, 'release movement must have a non-empty release_reason');
      END;

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
      END;

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
      END;

CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_movements_unique_operation
      ON goal_movements(transfer_operation_id);

CREATE TRIGGER IF NOT EXISTS no_modify_reserve_spendable
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.is_spendable != OLD.is_spendable
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve is_spendable cannot be changed');
      END;

CREATE TRIGGER IF NOT EXISTS no_modify_reserve_protected
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.is_protected != OLD.is_protected
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve is_protected cannot be changed');
      END;

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
      END;

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
      END;

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
      END;

CREATE TRIGGER IF NOT EXISTS no_modify_reserve_owner_type
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'goalReserve' AND NEW.owner_type != OLD.owner_type
      BEGIN
        SELECT RAISE(ABORT, 'goalReserve owner_type cannot be changed after linkage');
      END;

CREATE TRIGGER IF NOT EXISTS no_update_goal_lifecycle_events
      BEFORE UPDATE ON goal_lifecycle_events
      BEGIN
        SELECT RAISE(ABORT, 'goal lifecycle events are immutable');
      END;

CREATE TRIGGER IF NOT EXISTS no_delete_goal_lifecycle_events
      BEFORE DELETE ON goal_lifecycle_events
      BEGIN
        SELECT RAISE(ABORT, 'goal lifecycle events cannot be deleted');
      END;

CREATE TRIGGER IF NOT EXISTS fk_goal_lifecycle_event_household_id
      BEFORE INSERT ON goal_lifecycle_events
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'goal_lifecycle_events.household_id must reference a valid household')
        WHERE NOT EXISTS (
          SELECT 1 FROM households WHERE id = NEW.household_id
        );
      END;

CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_lifecycle_events_idempotency
      ON goal_lifecycle_events(idempotency_key)
      WHERE idempotency_key IS NOT NULL;

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
      END;

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
      END;

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
      END;

CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_movements_one_reversal_per_original
      ON goal_movements(reversal_of_movement_id)
      WHERE reversal_of_movement_id IS NOT NULL;

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
      END;

CREATE UNIQUE INDEX IF NOT EXISTS idx_goal_lifecycle_hh_idem
      ON goal_lifecycle_events(household_id, idempotency_key)
      WHERE idempotency_key IS NOT NULL;

CREATE TRIGGER IF NOT EXISTS validate_goal_transfer_balanced_legs BEFORE INSERT ON goal_movements FOR EACH ROW WHEN NEW.movement_type IN ('funding', 'release') BEGIN   SELECT RAISE(     ABORT,     'goal movement requires exactly two balanced ledger legs matching operation'   )   WHERE (     SELECT COUNT(*) FROM ledger_entries e     WHERE e.operation_id = NEW.transfer_operation_id   ) != 2   OR (     SELECT COUNT(*) FROM ledger_entries e     WHERE e.operation_id = NEW.transfer_operation_id       AND e.direction = 'debit'   ) != 1   OR (     SELECT COUNT(*) FROM ledger_entries e     WHERE e.operation_id = NEW.transfer_operation_id       AND e.direction = 'credit'   ) != 1   OR NOT EXISTS (     SELECT 1     FROM operations o     JOIN ledger_entries d ON d.operation_id = o.id AND d.direction = 'debit'     JOIN ledger_entries c ON c.operation_id = o.id AND c.direction = 'credit'     WHERE o.id = NEW.transfer_operation_id       AND o.household_id = NEW.household_id       AND d.account_id = o.source_account_id       AND c.account_id = o.destination_account_id       AND d.amount_minor_units = c.amount_minor_units       AND d.amount_minor_units = o.total_amount_minor_units       AND d.amount_minor_units > 0       AND c.amount_minor_units > 0       AND d.currency_code = o.currency_code       AND c.currency_code = o.currency_code       AND d.household_id = o.household_id       AND c.household_id = o.household_id   ); END;

CREATE TRIGGER IF NOT EXISTS validate_goal_reversal_balanced_legs BEFORE INSERT ON goal_movements FOR EACH ROW WHEN NEW.movement_type = 'reversal' BEGIN   SELECT RAISE(     ABORT,     'goal reversal movement requires balanced inverse ledger legs'   )   WHERE NEW.reversal_of_movement_id IS NULL   OR (     SELECT COUNT(*) FROM ledger_entries e     WHERE e.operation_id = NEW.transfer_operation_id   ) != 2   OR (     SELECT COUNT(*) FROM ledger_entries e     WHERE e.operation_id = NEW.transfer_operation_id       AND e.direction = 'debit'   ) != 1   OR (     SELECT COUNT(*) FROM ledger_entries e     WHERE e.operation_id = NEW.transfer_operation_id       AND e.direction = 'credit'   ) != 1   OR NOT EXISTS (     SELECT 1     FROM operations rev     JOIN goal_movements orig_mov ON orig_mov.id = NEW.reversal_of_movement_id     JOIN operations orig ON orig.id = orig_mov.transfer_operation_id     JOIN ledger_entries d ON d.operation_id = rev.id AND d.direction = 'debit'     JOIN ledger_entries c ON c.operation_id = rev.id AND c.direction = 'credit'     WHERE rev.id = NEW.transfer_operation_id       AND rev.type = 'reversal'       AND rev.household_id = NEW.household_id       AND orig.household_id = NEW.household_id       AND orig_mov.goal_id = NEW.goal_id       AND orig_mov.household_id = NEW.household_id       AND orig_mov.movement_type IN ('funding', 'release')       AND orig.is_reversed = 1       AND orig.reversed_by = rev.id       AND d.account_id = orig.destination_account_id       AND c.account_id = orig.source_account_id       AND d.account_id = rev.source_account_id       AND c.account_id = rev.destination_account_id       AND d.amount_minor_units = c.amount_minor_units       AND d.amount_minor_units = rev.total_amount_minor_units       AND d.amount_minor_units = orig.total_amount_minor_units       AND d.amount_minor_units > 0       AND c.amount_minor_units > 0       AND d.currency_code = rev.currency_code       AND c.currency_code = rev.currency_code       AND rev.currency_code = orig.currency_code       AND d.household_id = rev.household_id       AND c.household_id = rev.household_id   ); END;

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
      END;

CREATE TRIGGER IF NOT EXISTS check_goal_lifecycle_status
      BEFORE INSERT ON goals
      FOR EACH ROW
      WHEN NEW.status NOT IN ('active', 'completed', 'archived')
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal lifecycle status');
      END;

CREATE TRIGGER IF NOT EXISTS check_goal_lifecycle_status_update
      BEFORE UPDATE OF status ON goals
      FOR EACH ROW
      WHEN NEW.status NOT IN ('active', 'completed', 'archived')
      BEGIN
        SELECT RAISE(ABORT, 'invalid goal lifecycle status');
      END;
