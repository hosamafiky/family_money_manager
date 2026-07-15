# Local Database Schema

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15  
**Engine:** SQLite via Drift  
**Schema Version:** 1

---

## 1. Design Decisions

- All primary keys are TEXT UUID (client-generated, v4).
- All timestamps are stored as TEXT in ISO 8601 UTC format.
- All money amounts are stored as INTEGER (minor units).
- All gold weights are stored as INTEGER (milligrams).
- All enum values are stored as TEXT (stable English codes).
- All boolean values are stored as INTEGER (0 = false, 1 = true).
- No UPDATE or DELETE is to be permitted on `ledger_entries` or `child_withdrawal_audits` tables. A planned SQLite BEFORE UPDATE and BEFORE DELETE trigger will enforce this at the database engine level.
- `sync_status` is an enum TEXT: `local | pending | uploading | synced | conflict | failed`.
- Journal mode: WAL (Write-Ahead Logging) for crash safety.
- Drift enables type-safe access to all tables.

---

## 2. Tables

### 2.1 households

```sql
CREATE TABLE households (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  owner_user_id TEXT NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'EGP',
  primary_language TEXT NOT NULL DEFAULT 'ar',
  member_user_name TEXT NOT NULL DEFAULT '',
  member_spouse_name TEXT,
  member_child_name TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  schema_version INTEGER NOT NULL DEFAULT 1
);
```

---

### 2.2 financial_accounts

```sql
CREATE TABLE financial_accounts (
  id TEXT PRIMARY KEY NOT NULL,
  household_id TEXT NOT NULL REFERENCES households(id),
  name TEXT NOT NULL,
  type TEXT NOT NULL,
    -- personalCashWallet | spouseCashWallet | householdCash | homeSavingsCash
    -- bankAccount | mobileWallet | childProtectedFund | goalReserve
    -- certificate | goldHolding | investment | otherAsset
  owner_type TEXT NOT NULL,
    -- user | spouse | household | child | shared
  fund_purpose TEXT NOT NULL DEFAULT 'available',
    -- available | householdSpending | personalSpending | emergencySavings
    -- longTermSavings | childProtected | investment | certificate | gold | custom
  currency_code TEXT NOT NULL DEFAULT 'EGP',
  is_spendable INTEGER NOT NULL DEFAULT 1,
  is_protected INTEGER NOT NULL DEFAULT 0,
  include_in_net_worth INTEGER NOT NULL DEFAULT 1,
  include_in_zakat INTEGER NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0,
  archived_at TEXT,
  notes TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  metadata TEXT,
    -- JSON: type-specific fields (bank name, certificate data, gold data, etc.)
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  created_by TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
);

CREATE INDEX idx_financial_accounts_household ON financial_accounts(household_id);
CREATE INDEX idx_financial_accounts_type ON financial_accounts(type);
CREATE INDEX idx_financial_accounts_owner ON financial_accounts(owner_type);
CREATE INDEX idx_financial_accounts_archived ON financial_accounts(is_archived);
```

---

### 2.3 ledger_entries

The core immutable financial ledger. No UPDATE or DELETE allowed.

```sql
CREATE TABLE ledger_entries (
  id TEXT PRIMARY KEY NOT NULL,
  operation_id TEXT NOT NULL,
  household_id TEXT NOT NULL REFERENCES households(id),
  account_id TEXT NOT NULL REFERENCES financial_accounts(id),
  direction TEXT NOT NULL,
    -- credit | debit
  amount_minor_units INTEGER NOT NULL CHECK(amount_minor_units > 0),
  currency_code TEXT NOT NULL DEFAULT 'EGP',
  entry_type TEXT NOT NULL,
    -- openingBalance | income | expense | transferOut | transferIn | transferFee
    -- adjustmentDebit | adjustmentCredit | assetPurchase | assetSale
    -- liabilityCreation | liabilityRepayment | certificateFunding
    -- certificateMaturityReturn | interestIncome | goldPurchase | goldSale
    -- goalFunding | goalWithdrawal | childFundDeposit | childFundWithdrawal
    -- reversalDebit | reversalCredit | sadaqahExpense | zakatExpense
  effective_date TEXT NOT NULL,
    -- YYYY-MM-DD (user-chosen date)
  recorded_at TEXT NOT NULL,
    -- ISO 8601 UTC (system timestamp)
  notes TEXT,
  created_by TEXT NOT NULL,
  is_reversal INTEGER NOT NULL DEFAULT 0,
  reversal_of_entry_id TEXT,
  sync_status TEXT NOT NULL DEFAULT 'local',
  metadata TEXT
    -- JSON: operation-specific extra data
);

CREATE INDEX idx_ledger_entries_operation ON ledger_entries(operation_id);
CREATE INDEX idx_ledger_entries_account ON ledger_entries(account_id);
CREATE INDEX idx_ledger_entries_household ON ledger_entries(household_id);
CREATE INDEX idx_ledger_entries_effective_date ON ledger_entries(effective_date);
CREATE INDEX idx_ledger_entries_entry_type ON ledger_entries(entry_type);
CREATE INDEX idx_ledger_entries_sync ON ledger_entries(sync_status);

-- Immutability enforcement
CREATE TRIGGER no_update_ledger
BEFORE UPDATE ON ledger_entries
BEGIN
  SELECT RAISE(ABORT, 'Ledger entries are immutable');
END;

CREATE TRIGGER no_delete_ledger
BEFORE DELETE ON ledger_entries
BEGIN
  SELECT RAISE(ABORT, 'Ledger entries cannot be deleted');
END;

-- Idempotency: one entry per (operation_id, account_id, direction)
CREATE UNIQUE INDEX idx_ledger_idempotency
  ON ledger_entries(operation_id, account_id, direction, entry_type);
```

---

### 2.4 operations

Logical grouping of related ledger entries.

```sql
CREATE TABLE operations (
  id TEXT PRIMARY KEY NOT NULL,
    -- = operation_id from ledger_entries
  household_id TEXT NOT NULL REFERENCES households(id),
  type TEXT NOT NULL,
    -- income | expense | transfer | openingBalance | adjustment
    -- assetPurchase | assetSale | liabilityCreation | liabilityRepayment
    -- certificateFunding | certificateMaturity | interestIncome
    -- goldPurchase | goldSale | goalFunding | goalWithdrawal
    -- childFundDeposit | childFundWithdrawal | reversal | sadaqah | zakat
  effective_date TEXT NOT NULL,
  recorded_at TEXT NOT NULL,
  description TEXT,
  category_code TEXT,
  scope TEXT,
    -- personal | household | spouse | child | shared
  spender_role TEXT,
    -- user | spouse | child | other
  beneficiary_role TEXT,
    -- user | spouse | child | other
  source_account_id TEXT REFERENCES financial_accounts(id),
  destination_account_id TEXT REFERENCES financial_accounts(id),
  total_amount_minor_units INTEGER NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'EGP',
  is_recurring INTEGER NOT NULL DEFAULT 0,
  recurring_rule_id TEXT,
  tags TEXT,
    -- JSON array of strings
  receipt_path TEXT,
  is_reversed INTEGER NOT NULL DEFAULT 0,
  reversed_by TEXT,
    -- operation_id of the reversal
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
);

CREATE INDEX idx_operations_household ON operations(household_id);
CREATE INDEX idx_operations_type ON operations(type);
CREATE INDEX idx_operations_date ON operations(effective_date);
CREATE INDEX idx_operations_scope ON operations(scope);
CREATE INDEX idx_operations_source_account ON operations(source_account_id);
CREATE INDEX idx_operations_destination_account ON operations(destination_account_id);
CREATE INDEX idx_operations_category ON operations(category_code);
CREATE INDEX idx_operations_sync ON operations(sync_status);
```

---

### 2.5 child_withdrawal_audits

Immutable. Written atomically with childFundWithdrawal ledger entries.

```sql
CREATE TABLE child_withdrawal_audits (
  id TEXT PRIMARY KEY NOT NULL,
  operation_id TEXT NOT NULL REFERENCES operations(id),
  household_id TEXT NOT NULL REFERENCES households(id),
  account_id TEXT NOT NULL REFERENCES financial_accounts(id),
  amount_minor_units INTEGER NOT NULL CHECK(amount_minor_units > 0),
  reason TEXT NOT NULL CHECK(length(reason) > 0),
    -- mandatory non-empty reason
  beneficiary TEXT NOT NULL,
    -- user | spouse | child | other
  confirmed_at TEXT NOT NULL,
  confirmed_by TEXT NOT NULL,
  warning_shown INTEGER NOT NULL DEFAULT 1 CHECK(warning_shown = 1),
    -- required to always be 1; the planned CHECK constraint will enforce this at the database level
  biometric_confirmed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
);

CREATE UNIQUE INDEX idx_child_audit_operation ON child_withdrawal_audits(operation_id);

-- Immutability enforcement
CREATE TRIGGER no_update_child_audit
BEFORE UPDATE ON child_withdrawal_audits
BEGIN
  SELECT RAISE(ABORT, 'Child withdrawal audits are immutable');
END;

CREATE TRIGGER no_delete_child_audit
BEFORE DELETE ON child_withdrawal_audits
BEGIN
  SELECT RAISE(ABORT, 'Child withdrawal audits cannot be deleted');
END;
```

---

### 2.6 liabilities

```sql
CREATE TABLE liabilities (
  id TEXT PRIMARY KEY NOT NULL,
  household_id TEXT NOT NULL REFERENCES households(id),
  name TEXT NOT NULL,
  type TEXT NOT NULL,
    -- personalLoan | creditCard | borrowedFromPerson | owedToSupplier
    -- installment | lentToPerson
  original_amount_minor_units INTEGER NOT NULL CHECK(original_amount_minor_units > 0),
  outstanding_amount_minor_units INTEGER NOT NULL,
    -- decremented by repayment operations
  currency_code TEXT NOT NULL DEFAULT 'EGP',
  due_date TEXT,
  payment_account_id TEXT REFERENCES financial_accounts(id),
  interest_rate_basis_points INTEGER,
    -- 2000 = 20.00%
  notes TEXT,
  is_settled INTEGER NOT NULL DEFAULT 0,
  settled_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  created_by TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
);

CREATE INDEX idx_liabilities_household ON liabilities(household_id);
CREATE INDEX idx_liabilities_settled ON liabilities(is_settled);
```

---

### 2.7 goals

```sql
CREATE TABLE goals (
  id TEXT PRIMARY KEY NOT NULL,
  household_id TEXT NOT NULL REFERENCES households(id),
  name TEXT NOT NULL,
  description TEXT,
  target_amount_minor_units INTEGER NOT NULL CHECK(target_amount_minor_units > 0),
  currency_code TEXT NOT NULL DEFAULT 'EGP',
  deadline TEXT,
  reserve_account_id TEXT NOT NULL REFERENCES financial_accounts(id),
  status TEXT NOT NULL DEFAULT 'active',
    -- active | completed | cancelled
  completed_at TEXT,
  cancelled_at TEXT,
  cancellation_destination_account_id TEXT REFERENCES financial_accounts(id),
  reminder_enabled INTEGER NOT NULL DEFAULT 0,
  reminder_frequency TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  created_by TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
);

CREATE INDEX idx_goals_household ON goals(household_id);
CREATE INDEX idx_goals_status ON goals(status);
```

---

### 2.8 budgets

```sql
CREATE TABLE budgets (
  id TEXT PRIMARY KEY NOT NULL,
  household_id TEXT NOT NULL REFERENCES households(id),
  name TEXT NOT NULL,
  scope TEXT NOT NULL,
    -- personal | household | spouse | child | shared
  type TEXT NOT NULL,
    -- overall | category | account
  category_code TEXT,
  account_id TEXT REFERENCES financial_accounts(id),
  period_type TEXT NOT NULL DEFAULT 'monthly',
    -- monthly | custom
  custom_start_date TEXT,
  custom_end_date TEXT,
  target_amount_minor_units INTEGER NOT NULL CHECK(target_amount_minor_units > 0),
  warning_threshold_percent INTEGER NOT NULL DEFAULT 80
    CHECK(warning_threshold_percent BETWEEN 1 AND 100),
  currency_code TEXT NOT NULL DEFAULT 'EGP',
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  created_by TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
);

CREATE INDEX idx_budgets_household ON budgets(household_id);
CREATE INDEX idx_budgets_scope ON budgets(scope);
CREATE INDEX idx_budgets_active ON budgets(is_active);
```

---

### 2.9 recurring_rules

```sql
CREATE TABLE recurring_rules (
  id TEXT PRIMARY KEY NOT NULL,
  household_id TEXT NOT NULL REFERENCES households(id),
  operation_type TEXT NOT NULL,
  frequency TEXT NOT NULL,
    -- daily | weekly | biweekly | monthly | quarterly | yearly
  day_of_month INTEGER,
  next_due_date TEXT NOT NULL,
  end_date TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  template_operation_id TEXT NOT NULL REFERENCES operations(id),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
);

CREATE INDEX idx_recurring_household ON recurring_rules(household_id);
CREATE INDEX idx_recurring_next_due ON recurring_rules(next_due_date);
CREATE INDEX idx_recurring_active ON recurring_rules(is_active);
```

---

### 2.10 zakat_calculations

```sql
CREATE TABLE zakat_calculations (
  id TEXT PRIMARY KEY NOT NULL,
  household_id TEXT NOT NULL REFERENCES households(id),
  calculation_date TEXT NOT NULL,
  hawl_start_date TEXT NOT NULL,
  hawl_end_date TEXT NOT NULL,
  nisab_basis TEXT NOT NULL,
    -- gold | silver
  nisab_amount_minor_units INTEGER NOT NULL,
  included_accounts TEXT NOT NULL DEFAULT '[]',
    -- JSON array of { accountId, includedAmountMinorUnits, notes }
  excluded_accounts TEXT NOT NULL DEFAULT '[]',
    -- JSON array of account IDs
  deducted_liabilities TEXT NOT NULL DEFAULT '[]',
    -- JSON array of { liabilityId, deductedAmountMinorUnits }
  total_zakatable_amount_minor_units INTEGER NOT NULL,
  zakat_due_minor_units INTEGER NOT NULL,
  is_paid_via_app INTEGER NOT NULL DEFAULT 0,
  payment_operation_id TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  created_by TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
);

CREATE INDEX idx_zakat_household ON zakat_calculations(household_id);
CREATE INDEX idx_zakat_date ON zakat_calculations(calculation_date);
```

---

### 2.11 sadaqah_records

```sql
CREATE TABLE sadaqah_records (
  id TEXT PRIMARY KEY NOT NULL,
  household_id TEXT NOT NULL REFERENCES households(id),
  amount_minor_units INTEGER NOT NULL CHECK(amount_minor_units > 0),
  currency_code TEXT NOT NULL DEFAULT 'EGP',
  date TEXT NOT NULL,
  notes TEXT,
  linked_operation_id TEXT REFERENCES operations(id),
  is_linked INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  created_by TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'local'
);

CREATE INDEX idx_sadaqah_household ON sadaqah_records(household_id);
CREATE INDEX idx_sadaqah_date ON sadaqah_records(date);
```

---

### 2.12 sync_queue

```sql
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY NOT NULL,
    -- = entity ID being synced
  entity_type TEXT NOT NULL,
    -- LedgerEntry | Operation | FinancialAccount | Liability | Goal | Budget
    -- ChildWithdrawalAudit | ZakatCalculation | SadaqahRecord | RecurringRule
  entity_id TEXT NOT NULL,
  change_type TEXT NOT NULL,
    -- create | update
  payload TEXT NOT NULL,
    -- JSON serialized entity
  status TEXT NOT NULL DEFAULT 'pending',
    -- pending | uploading | synced | failed
  retry_count INTEGER NOT NULL DEFAULT 0,
  last_attempt_at TEXT,
  failure_reason TEXT,
  created_at TEXT NOT NULL
);

CREATE UNIQUE INDEX idx_sync_queue_entity ON sync_queue(entity_id, change_type);
CREATE INDEX idx_sync_queue_status ON sync_queue(status);
CREATE INDEX idx_sync_queue_created ON sync_queue(created_at);
```

---

### 2.13 app_settings (device-local only, not synced)

```sql
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
-- Keys: pin_hash, pin_salt, auto_lock_seconds, privacy_mode_enabled,
--       biometric_enabled, screenshot_protection, last_backup_at,
--       local_only_mode, sync_user_id, current_household_id
```

---

## 3. Key Queries

### Account balance

```sql
SELECT
  SUM(CASE WHEN direction = 'credit' THEN amount_minor_units ELSE 0 END) -
  SUM(CASE WHEN direction = 'debit' THEN amount_minor_units ELSE 0 END) AS balance_minor_units
FROM ledger_entries
WHERE account_id = ?
  AND household_id = ?;
```

### Account balance as of a date

```sql
SELECT
  SUM(CASE WHEN direction = 'credit' THEN amount_minor_units ELSE 0 END) -
  SUM(CASE WHEN direction = 'debit' THEN amount_minor_units ELSE 0 END) AS balance_minor_units
FROM ledger_entries
WHERE account_id = ?
  AND household_id = ?
  AND effective_date <= ?;
```

### Total expenses by scope for current month

```sql
SELECT scope, SUM(total_amount_minor_units) AS total
FROM operations
WHERE household_id = ?
  AND type = 'expense'
  AND effective_date >= ?  -- first day of month
  AND effective_date <= ?  -- last day of month
  AND is_reversed = 0
GROUP BY scope;
```

### Net worth

```sql
-- Assets
SELECT SUM(balance) AS total_assets
FROM (
  SELECT
    a.id,
    SUM(CASE WHEN l.direction = 'credit' THEN l.amount_minor_units ELSE 0 END) -
    SUM(CASE WHEN l.direction = 'debit' THEN l.amount_minor_units ELSE 0 END) AS balance
  FROM financial_accounts a
  JOIN ledger_entries l ON l.account_id = a.id
  WHERE a.household_id = ?
    AND a.include_in_net_worth = 1
    AND a.is_archived = 0
  GROUP BY a.id
);

-- Liabilities
SELECT SUM(outstanding_amount_minor_units) AS total_liabilities
FROM liabilities
WHERE household_id = ?
  AND is_settled = 0;
```

### Child fund summary

```sql
SELECT
  SUM(CASE WHEN entry_type = 'childFundDeposit' THEN amount_minor_units ELSE 0 END) AS total_deposits,
  SUM(CASE WHEN entry_type = 'childFundWithdrawal' THEN amount_minor_units ELSE 0 END) AS total_withdrawals
FROM ledger_entries
WHERE account_id = ?
  AND household_id = ?;
```

---

## 4. Migration Strategy

```dart
// In AppDatabase (Drift)
@DriftDatabase(tables: [...], daos: [...])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _applyImmutabilityTriggers(m);
    },
    onUpgrade: (m, from, to) async {
      // Each migration step defined here
      if (from < 2) {
        // Migration to v2 when needed
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

Drift migrations are sequential. Skipping versions is not supported. Each upgrade function handles the exact version range.

---

## 5. Performance Considerations

- Balance queries run over all ledger entries for an account. For accounts with many entries (e.g., 5+ years of daily transactions), consider a periodic snapshot table.
- Snapshot table: `account_balance_snapshots` with `(account_id, as_of_date, balance_minor_units)`. Query: `snapshot + delta from ledger entries after snapshot date`.
- This optimization is deferred to Phase 6+ when performance measurement can guide the decision.
- All tables have appropriate indexes on household_id, effective_date, type, and account_id.

---

## 6. Security

- Database file is stored in the app's private data directory.
- Android: full-disk encryption (Android 9+).
- iOS: data protection (NSFileProtectionComplete).
- For enhanced at-rest encryption, SQLCipher integration is a deferred v2 option (see DECISIONS.md).
- PIN hash and auth tokens are NOT stored in this SQLite database — they go into `flutter_secure_storage` (Android Keystore / iOS Keychain).
