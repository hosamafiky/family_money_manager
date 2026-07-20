part of '../app_database.dart';

/// Savings-certificate schema helpers (Phases 6A–6A.2).
mixin _AppDatabaseCertificateSchema on _$AppDatabase {
  Future<void> _applyPhase6ACertificateSchema() async {
    await _applyCertificateIndexes();
    await _applyCertificateImmutabilityTriggers();
    await _applyCertificateAccountHardeningTriggers();
    await _applyCertificateEventFinancialTriggers();
  }

  Future<void> _applyCertificateIndexes() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_savings_certificates_account
      ON savings_certificates(certificate_account_id)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_savings_certificates_idempotency
      ON savings_certificates(household_id, idempotency_key)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_savings_certificates_household
      ON savings_certificates(household_id, lifecycle, maturity_date)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_certificate_revisions_certificate
      ON certificate_revisions(certificate_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_certificate_events_certificate
      ON certificate_events(certificate_id, created_at)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_certificate_events_related_op
      ON certificate_events(related_operation_id)
      WHERE related_operation_id IS NOT NULL
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_certificate_events_idempotency
      ON certificate_events(household_id, idempotency_key)
      WHERE idempotency_key IS NOT NULL
    ''');
  }

  Future<void> _applyCertificateImmutabilityTriggers() async {
    // Revisions / events append-only.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_certificate_revisions
      BEFORE UPDATE ON certificate_revisions
      BEGIN
        SELECT RAISE(ABORT, 'certificate_revisions are immutable and cannot be updated');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_certificate_revisions
      BEFORE DELETE ON certificate_revisions
      BEGIN
        SELECT RAISE(ABORT, 'certificate_revisions cannot be deleted');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_certificate_events
      BEFORE UPDATE ON certificate_events
      BEGIN
        SELECT RAISE(ABORT, 'certificate_events are immutable and cannot be updated');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_certificate_events
      BEFORE DELETE ON certificate_events
      BEGIN
        SELECT RAISE(ABORT, 'certificate_events cannot be deleted');
      END
    ''');

    // Certificate structural immutability.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_update_certificate_immutable
      BEFORE UPDATE ON savings_certificates
      FOR EACH ROW
      WHEN NEW.household_id != OLD.household_id
        OR NEW.certificate_account_id != OLD.certificate_account_id
        OR NEW.currency_code != OLD.currency_code
        OR NEW.original_principal_minor_units != OLD.original_principal_minor_units
        OR NEW.start_date != OLD.start_date
        OR NEW.maturity_date != OLD.maturity_date
        OR NEW.idempotency_key != OLD.idempotency_key
        OR NEW.created_at != OLD.created_at
      BEGIN
        SELECT RAISE(ABORT, 'certificate immutable fields cannot be changed');
      END
    ''');

    // Lifecycle value CHECK.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_certificate_lifecycle_insert
      BEFORE INSERT ON savings_certificates
      FOR EACH ROW
      WHEN NEW.lifecycle NOT IN ('active', 'redeemed', 'archived')
      BEGIN
        SELECT RAISE(ABORT, 'invalid certificate lifecycle');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS check_certificate_lifecycle_update
      BEFORE UPDATE OF lifecycle ON savings_certificates
      FOR EACH ROW
      WHEN NEW.lifecycle NOT IN ('active', 'redeemed', 'archived')
      BEGIN
        SELECT RAISE(ABORT, 'invalid certificate lifecycle');
      END
    ''');

    // Valid lifecycle transitions: active→redeemed/archived; redeemed→archived;
    // archived→active (restore).
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS certificate_lifecycle_valid_transition
      BEFORE UPDATE OF lifecycle ON savings_certificates
      FOR EACH ROW
      WHEN NEW.lifecycle != OLD.lifecycle
        AND NOT (
          (OLD.lifecycle = 'active' AND NEW.lifecycle IN ('redeemed','archived'))
          OR (OLD.lifecycle = 'redeemed' AND NEW.lifecycle = 'archived')
          OR (OLD.lifecycle = 'archived' AND NEW.lifecycle = 'active')
        )
      BEGIN
        SELECT RAISE(ABORT, 'invalid certificate lifecycle transition');
      END
    ''');

    // No cascade financial delete: reject delete when events exist.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_delete_certificate_with_history
      BEFORE DELETE ON savings_certificates
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'cannot delete certificate with history')
        WHERE EXISTS (
          SELECT 1 FROM certificate_events WHERE certificate_id = OLD.id
        )
        OR EXISTS (
          SELECT 1 FROM certificate_revisions WHERE certificate_id = OLD.id
        );
      END
    ''');

    // Event household must match certificate household.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS certificate_event_household_match
      BEFORE INSERT ON certificate_events
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'certificate event household mismatch')
        WHERE NOT EXISTS (
          SELECT 1 FROM savings_certificates sc
          WHERE sc.id = NEW.certificate_id
            AND sc.household_id = NEW.household_id
        );
      END
    ''');

    // Revision household must match.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS certificate_revision_household_match
      BEFORE INSERT ON certificate_revisions
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT, 'certificate revision household mismatch')
        WHERE NOT EXISTS (
          SELECT 1 FROM savings_certificates sc
          WHERE sc.id = NEW.certificate_id
            AND sc.household_id = NEW.household_id
        );
      END
    ''');
  }

  Future<void> _applyCertificateAccountHardeningTriggers() async {
    // Validate certificate row references a proper certificate account.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_certificate_account_on_insert
      BEFORE INSERT ON savings_certificates
      FOR EACH ROW
      BEGIN
        SELECT RAISE(ABORT,
          'certificate account must be type certificate, same household/currency, non-spendable, not protected, household-owned')
        WHERE NOT EXISTS (
          SELECT 1 FROM financial_accounts fa
          WHERE fa.id = NEW.certificate_account_id
            AND fa.household_id = NEW.household_id
            AND fa.currency_code = NEW.currency_code
            AND fa.type = 'certificate'
            AND fa.is_spendable = 0
            AND fa.is_protected = 0
            AND fa.owner_type = 'household'
        );
      END
    ''');

    // Prevent retyping certificate accounts.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_retype_certificate_account
      BEFORE UPDATE OF type ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'certificate' AND NEW.type != 'certificate'
      BEGIN
        SELECT RAISE(ABORT, 'certificate account type cannot be changed');
      END
    ''');

    // Lock spendable / protected / owner on certificate accounts.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_certificate_spendable
      BEFORE UPDATE OF is_spendable ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'certificate' AND NEW.is_spendable != OLD.is_spendable
      BEGIN
        SELECT RAISE(ABORT, 'certificate is_spendable cannot be changed');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_certificate_protected
      BEFORE UPDATE OF is_protected ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'certificate' AND NEW.is_protected != OLD.is_protected
      BEGIN
        SELECT RAISE(ABORT, 'certificate is_protected cannot be changed');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS no_modify_certificate_owner_type
      BEFORE UPDATE OF owner_type ON financial_accounts
      FOR EACH ROW
      WHEN OLD.type = 'certificate' AND NEW.owner_type != OLD.owner_type
      BEGIN
        SELECT RAISE(ABORT, 'certificate owner_type cannot be changed');
      END
    ''');
  }

  Future<void> _applyCertificateEventFinancialTriggers() async {
    // Purchase event must link a certificateFunding transfer INTO the cert account
    // with exactly two balanced legs matching operation source/destination.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_certificate_purchase_event
      BEFORE INSERT ON certificate_events
      FOR EACH ROW
      WHEN NEW.event_type = 'purchased'
      BEGIN
        SELECT RAISE(ABORT, 'purchase event requires balanced transfer into certificate account')
        WHERE NEW.related_operation_id IS NULL
           OR NEW.amount_minor_units IS NULL
           OR NEW.currency_code IS NULL
           OR (
             SELECT COUNT(*) FROM ledger_entries le
             WHERE le.operation_id = NEW.related_operation_id
           ) != 2
           OR (
             SELECT COUNT(*) FROM ledger_entries le
             WHERE le.operation_id = NEW.related_operation_id
               AND le.direction = 'debit'
           ) != 1
           OR (
             SELECT COUNT(*) FROM ledger_entries le
             WHERE le.operation_id = NEW.related_operation_id
               AND le.direction = 'credit'
           ) != 1
           OR NOT EXISTS (
             SELECT 1
             FROM operations o
             JOIN savings_certificates sc ON sc.id = NEW.certificate_id
             JOIN ledger_entries d
               ON d.operation_id = o.id AND d.direction = 'debit'
             JOIN ledger_entries c
               ON c.operation_id = o.id AND c.direction = 'credit'
             WHERE o.id = NEW.related_operation_id
               AND o.household_id = NEW.household_id
               AND o.type = 'certificateFunding'
               AND o.source_account_id = d.account_id
               AND o.destination_account_id = c.account_id
               AND c.account_id = sc.certificate_account_id
               AND d.account_id != sc.certificate_account_id
               AND d.amount_minor_units = c.amount_minor_units
               AND d.amount_minor_units = o.total_amount_minor_units
               AND o.total_amount_minor_units = NEW.amount_minor_units
               AND o.currency_code = NEW.currency_code
               AND d.currency_code = NEW.currency_code
               AND c.currency_code = NEW.currency_code
               AND d.household_id = NEW.household_id
               AND c.household_id = NEW.household_id
           );
      END
    ''');

    // Redemption event must link a certificateMaturity transfer OUT of cert.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_certificate_redemption_event
      BEFORE INSERT ON certificate_events
      FOR EACH ROW
      WHEN NEW.event_type = 'redeemed'
      BEGIN
        SELECT RAISE(ABORT, 'redemption event requires balanced transfer out of certificate account')
        WHERE NEW.related_operation_id IS NULL
           OR NEW.amount_minor_units IS NULL
           OR NEW.currency_code IS NULL
           OR (
             SELECT COUNT(*) FROM ledger_entries le
             WHERE le.operation_id = NEW.related_operation_id
           ) != 2
           OR (
             SELECT COUNT(*) FROM ledger_entries le
             WHERE le.operation_id = NEW.related_operation_id
               AND le.direction = 'debit'
           ) != 1
           OR (
             SELECT COUNT(*) FROM ledger_entries le
             WHERE le.operation_id = NEW.related_operation_id
               AND le.direction = 'credit'
           ) != 1
           OR NOT EXISTS (
             SELECT 1
             FROM operations o
             JOIN savings_certificates sc ON sc.id = NEW.certificate_id
             JOIN ledger_entries d
               ON d.operation_id = o.id AND d.direction = 'debit'
             JOIN ledger_entries c
               ON c.operation_id = o.id AND c.direction = 'credit'
             WHERE o.id = NEW.related_operation_id
               AND o.household_id = NEW.household_id
               AND o.type = 'certificateMaturity'
               AND o.source_account_id = d.account_id
               AND o.destination_account_id = c.account_id
               AND d.account_id = sc.certificate_account_id
               AND c.account_id != sc.certificate_account_id
               AND d.amount_minor_units = c.amount_minor_units
               AND d.amount_minor_units = o.total_amount_minor_units
               AND o.total_amount_minor_units = NEW.amount_minor_units
               AND o.currency_code = NEW.currency_code
               AND d.currency_code = NEW.currency_code
               AND c.currency_code = NEW.currency_code
               AND d.household_id = NEW.household_id
               AND c.household_id = NEW.household_id
           );
      END
    ''');

    // Profit event must link an income op with certificate_profit category.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS validate_certificate_profit_event
      BEFORE INSERT ON certificate_events
      FOR EACH ROW
      WHEN NEW.event_type = 'profitReceived'
      BEGIN
        SELECT RAISE(ABORT, 'profit event requires income operation')
        WHERE NEW.related_operation_id IS NULL
           OR NEW.amount_minor_units IS NULL
           OR NEW.currency_code IS NULL
           OR (
             SELECT COUNT(*) FROM ledger_entries le
             WHERE le.operation_id = NEW.related_operation_id
               AND le.direction = 'credit'
           ) != 1
           OR (
             SELECT COUNT(*) FROM ledger_entries le
             WHERE le.operation_id = NEW.related_operation_id
           ) != 1
           OR NOT EXISTS (
             SELECT 1 FROM operations o
             JOIN savings_certificates sc ON sc.id = NEW.certificate_id
             JOIN ledger_entries le
               ON le.operation_id = o.id AND le.direction = 'credit'
             WHERE o.id = NEW.related_operation_id
               AND o.household_id = NEW.household_id
               AND o.type = 'income'
               AND o.category_code = 'certificate_profit'
               AND o.total_amount_minor_units = NEW.amount_minor_units
               AND o.currency_code = NEW.currency_code
               AND o.destination_account_id = le.account_id
               AND o.destination_account_id IS NOT NULL
               AND o.destination_account_id != sc.certificate_account_id
               AND le.amount_minor_units = NEW.amount_minor_units
               AND le.currency_code = NEW.currency_code
               AND le.household_id = NEW.household_id
           );
      END
    ''');
  }

  // ── Phase 6A.2: Debit safety + certificate event balanced-leg hardening ───

  /// Mechanism: DB-level non-negative balance enforcement (SQLite trigger).
  ///
  /// Combined with Drift's default `BEGIN IMMEDIATE` writer transactions, every
  /// debit path's balance decision shares the same write lock as the ledger
  /// insert across two connections to one SQLite file. The trigger is the
  /// last-line guarantee that no account balance can go negative after insert.
  Future<void> _applyPhase6A2DebitSafetyAndCertEventHardening() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS prevent_negative_account_balance
      AFTER INSERT ON ledger_entries
      FOR EACH ROW
      WHEN NEW.direction = 'debit'
      BEGIN
        SELECT RAISE(ABORT, 'account balance cannot go negative')
        WHERE (
          SELECT COALESCE(SUM(
            CASE WHEN direction = 'credit' THEN amount_minor_units
                 ELSE -amount_minor_units END
          ), 0)
          FROM ledger_entries
          WHERE account_id = NEW.account_id
        ) < 0;
      END
    ''');

    // Replace Phase 6A event validators with balanced-leg enforcement.
    await customStatement(
      'DROP TRIGGER IF EXISTS validate_certificate_purchase_event',
    );
    await customStatement(
      'DROP TRIGGER IF EXISTS validate_certificate_redemption_event',
    );
    await customStatement(
      'DROP TRIGGER IF EXISTS validate_certificate_profit_event',
    );
    await _applyCertificateEventFinancialTriggers();
  }
}
