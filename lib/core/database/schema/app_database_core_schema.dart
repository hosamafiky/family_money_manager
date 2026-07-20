part of '../app_database.dart';

/// Core, account, household, and budget schema helpers (through Phase 5A).
mixin _AppDatabaseCoreSchema on _$AppDatabase {
  Future<void> _applyImmutabilityTriggers() async {
    // Ledger entries are immutable once written.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_ledger_entries
      BEFORE UPDATE ON ledger_entries
      BEGIN
        SELECT RAISE(ABORT, 'Ledger entries are immutable and cannot be updated');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_ledger_entries
      BEFORE DELETE ON ledger_entries
      BEGIN
        SELECT RAISE(ABORT, 'Ledger entries cannot be deleted');
      END
    ''');

    // Child withdrawal audits are immutable.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_child_audits
      BEFORE UPDATE ON child_withdrawal_audits
      BEGIN
        SELECT RAISE(ABORT, 'Child withdrawal audits are immutable and cannot be updated');
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_child_audits
      BEFORE DELETE ON child_withdrawal_audits
      BEGIN
        SELECT RAISE(ABORT, 'Child withdrawal audits cannot be deleted');
      END
    ''');
  }

  // ── Restricted-update trigger for operations (Phase 2A) ───────────────────
  //
  // Operations may only have [is_reversed], [reversed_by], and [updated_at]
  // mutated after creation. All other columns are append-only in practice.
  // This trigger enforces that restriction at the database engine level.

  Future<void> _applyAppendOnlyTriggers() async {
    // Only is_reversed, reversed_by, and updated_at may change.
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS restrict_operations_update '
      'BEFORE UPDATE ON operations '
      'WHEN NEW.id != OLD.id OR NEW.household_id != OLD.household_id '
      '  OR NEW.type != OLD.type OR NEW.effective_date != OLD.effective_date '
      '  OR NEW.recorded_at != OLD.recorded_at '
      '  OR NEW.total_amount_minor_units != OLD.total_amount_minor_units '
      '  OR NEW.currency_code != OLD.currency_code '
      '  OR NEW.created_by != OLD.created_by OR NEW.created_at != OLD.created_at '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Operations are append-only: only is_reversed, reversed_by, and updated_at may change'); "
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS no_delete_operations '
      'BEFORE DELETE ON operations '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Operations cannot be deleted; use a reversal operation instead'); "
      'END',
    );
  }

  // ── CHECK-enforcement triggers (Phase 2A) ─────────────────────────────────
  //
  // SQLite CHECK constraints added after table creation are not enforced.
  // These BEFORE INSERT triggers enforce the same rules reliably.

  Future<void> _applyCheckEnforcementTriggers() async {
    // ledger_entries: amount_minor_units > 0
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_ledger_entry_amount
      BEFORE INSERT ON ledger_entries
      WHEN NEW.amount_minor_units <= 0
      BEGIN
        SELECT RAISE(ABORT, 'ledger_entries.amount_minor_units must be > 0');
      END
    ''');

    // child_withdrawal_audits: amount_minor_units > 0
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_audit_amount
      BEFORE INSERT ON child_withdrawal_audits
      WHEN NEW.amount_minor_units <= 0
      BEGIN
        SELECT RAISE(ABORT, 'child_withdrawal_audits.amount_minor_units must be > 0');
      END
    ''');

    // child_withdrawal_audits: warning_shown must be 1 (true)
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_audit_warning_shown
      BEFORE INSERT ON child_withdrawal_audits
      WHEN NEW.warning_shown != 1
      BEGIN
        SELECT RAISE(ABORT, 'child_withdrawal_audits.warning_shown must be true (1)');
      END
    ''');

    // child_withdrawal_audits: reason must be non-empty
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_audit_reason
      BEFORE INSERT ON child_withdrawal_audits
      WHEN length(trim(NEW.reason)) = 0
      BEGIN
        SELECT RAISE(ABORT, 'child_withdrawal_audits.reason must not be empty');
      END
    ''');

    // operations: total_amount_minor_units must be >= 0
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_operation_amount
      BEFORE INSERT ON operations
      WHEN NEW.total_amount_minor_units < 0
      BEGIN
        SELECT RAISE(ABORT, 'operations.total_amount_minor_units must be >= 0');
      END
    ''');
  }

  // ── Foreign-key enforcement triggers (Phase 2A) ───────────────────────────
  //
  // Drift does not add FK from ledger_entries.operation_id → operations.id
  // because the column was defined as a plain TextColumn without .references().
  // A BEFORE INSERT trigger enforces the referential integrity at runtime.
  // (The FK from ledger_entries.account_id → financial_accounts is defined via
  // the Drift table DSL and enforced by PRAGMA foreign_keys = ON.)

  Future<void> _applyForeignKeyEnforcementTriggers() async {
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS fk_ledger_entry_operation_id '
      'BEFORE INSERT ON ledger_entries '
      'WHEN NOT EXISTS ('
      '  SELECT 1 FROM operations '
      '  WHERE id = NEW.operation_id AND household_id = NEW.household_id'
      ') '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'ledger_entries.operation_id must reference an existing operations.id in the same household'); "
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS fk_audit_operation_household '
      'BEFORE INSERT ON child_withdrawal_audits '
      'WHEN NOT EXISTS ('
      '  SELECT 1 FROM operations '
      '  WHERE id = NEW.operation_id AND household_id = NEW.household_id'
      ') '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'child_withdrawal_audits.operation_id must reference an operation in the same household'); "
      'END',
    );
  }

  // ── Indexes ───────────────────────────────────────────────────────────────

  Future<void> _applyIndexes() async {
    // The leg-level unique index prevents duplicate entries per operation leg.
    // It is NOT the primary idempotency mechanism (that is the PK on operations.id
    // and the scoped idempotency_key index below).
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ledger_idempotency
      ON ledger_entries(operation_id, account_id, direction, entry_type)
    ''');

    // Performance indexes.
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_ledger_entries_account
      ON ledger_entries(account_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_ledger_entries_operation
      ON ledger_entries(operation_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_ledger_entries_effective_date
      ON ledger_entries(effective_date)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_ledger_entries_household
      ON ledger_entries(household_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_operations_household
      ON operations(household_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_operations_date
      ON operations(effective_date)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_operations_type
      ON operations(type)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_financial_accounts_household
      ON financial_accounts(household_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_financial_accounts_archived
      ON financial_accounts(is_archived)
    ''');

    await _applyScopedIdempotencyIndex();
    await _applyAccountIdempotencyIndex();
  }

  /// Scoped idempotency: (household_id, idempotency_key) must be unique
  /// for all operations that provide an explicit idempotency key.
  /// NULL idempotency_key is excluded from the unique constraint
  /// (partial index using WHERE idempotency_key IS NOT NULL).
  Future<void> _applyScopedIdempotencyIndex() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_operations_idempotency_key
      ON operations(household_id, idempotency_key)
      WHERE idempotency_key IS NOT NULL
    ''');
  }

  // ── Household cardinality triggers (Phase 3A.1) ───────────────────────────
  //
  // Enforces V1 business rules at the database level:
  // - At most one active primary_user per household.
  // - At most one active spouse per household.
  // - Every household_members row must reference an existing household.

  Future<void> _applyHouseholdConstraintTriggers() async {
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS one_primary_user_per_household '
      'BEFORE INSERT ON household_members '
      "WHEN NEW.role = 'primary_user' AND NEW.is_archived = 0 "
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Only one active primary_user per household') "
      '  WHERE EXISTS ( '
      '    SELECT 1 FROM household_members '
      '    WHERE household_id = NEW.household_id '
      "      AND role = 'primary_user' "
      '      AND is_archived = 0 '
      '  ); '
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS one_spouse_per_household '
      'BEFORE INSERT ON household_members '
      "WHEN NEW.role = 'spouse' AND NEW.is_archived = 0 "
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Only one active spouse per household in V1') "
      '  WHERE EXISTS ( '
      '    SELECT 1 FROM household_members '
      '    WHERE household_id = NEW.household_id '
      "      AND role = 'spouse' "
      '      AND is_archived = 0 '
      '  ); '
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS no_cross_household_member '
      'BEFORE INSERT ON household_members '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'household_members.household_id must match household.id') "
      '  WHERE NOT EXISTS ( '
      '    SELECT 1 FROM households WHERE id = NEW.household_id '
      '  ); '
      'END',
    );
  }

  // ── Immutable account type and currency trigger (Phase 3A.1) ─────────────
  //
  // [type] and [currency_code] must never change after insertion.
  // This enforces the structural immutability rule at the DB engine level.

  Future<void> _applyAccountMetadataImmutabilityTrigger() async {
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS immutable_account_type_currency '
      'BEFORE UPDATE ON financial_accounts '
      'WHEN OLD.type != NEW.type OR OLD.currency_code != NEW.currency_code '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Account type and currency are immutable after creation'); "
      'END',
    );
  }

  // ── Post-history classification immutability trigger (Phase 3B.1) ────────
  //
  // Once an account has any ledger entries, the following classification fields
  // become immutable: type, currency_code, owner_type, fund_purpose,
  // is_protected, is_spendable, include_in_net_worth, include_in_zakat.
  //
  // Defense-in-depth: type and currency_code are ALSO blocked by the always-on
  // [_applyAccountMetadataImmutabilityTrigger]. This trigger adds the
  // post-history lock for the remaining fields as a DB-engine guarantee.

  Future<void> _applyAccountClassificationImmutabilityTrigger() async {
    await customStatement('''
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
      END
    ''');
  }

  // ── Child-protected-fund protection trigger (Phase 3B.1) ─────────────────
  //
  // A childProtectedFund account must ALWAYS have is_protected = true.
  // This rule applies even BEFORE any financial history exists.
  // Attempting to clear the flag raises an abort regardless of history.

  Future<void> _applyChildFundProtectionTrigger() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS restrict_child_fund_unprotect
      BEFORE UPDATE ON financial_accounts
      FOR EACH ROW
      WHEN NEW.type = 'childProtectedFund' AND NEW.is_protected = 0
      BEGIN
        SELECT RAISE(ABORT, 'Child protected fund cannot have is_protected disabled');
      END
    ''');
  }

  // ── Operation-context triggers (Phase 3B) ─────────────────────────────────
  //
  // 1. FK enforcement: operation_id must reference an existing operations row.
  // 2. Append-only: no update or delete permitted once written.

  Future<void> _applyOperationContextTriggers() async {
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS fk_operation_context_operation_id '
      'BEFORE INSERT ON operation_contexts '
      'WHEN NOT EXISTS ( '
      '  SELECT 1 FROM operations WHERE id = NEW.operation_id '
      ') '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'operation_contexts.operation_id must reference an existing operations.id'); "
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS no_update_operation_contexts '
      'BEFORE UPDATE ON operation_contexts '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Operation contexts are immutable and cannot be updated'); "
      'END',
    );

    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS no_delete_operation_contexts '
      'BEFORE DELETE ON operation_contexts '
      'BEGIN '
      "  SELECT RAISE(ABORT, 'Operation contexts cannot be deleted'); "
      'END',
    );
  }

  // ── Account idempotency index (Phase 3A.1) ────────────────────────────────

  Future<void> _applyAccountIdempotencyIndex() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_accounts_idempotency
      ON financial_accounts(household_id, idempotency_key)
      WHERE idempotency_key IS NOT NULL
    ''');
  }

  // ── Budget idempotency index (Phase 5A) ───────────────────────────────────

  Future<void> _applyBudgetIdempotencyIndex() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_idempotency
      ON budgets(household_id, idempotency_key)
    ''');
  }

  // ── Goal immutability triggers (Phase 5B) ─────────────────────────────────
  //
  // goal_revisions and goal_movements are append-only records. No application
  // code ever issues UPDATE or DELETE on these tables, but these triggers
  // enforce the constraint at the database engine level as a safety net.
}
