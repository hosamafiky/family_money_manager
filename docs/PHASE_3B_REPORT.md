# Phase 3B Verification & Correction Report

## Commit Evidence

| Item | Value |
|---|---|
| Base commit (Phase 3B) | `ada7c9d6608df48b650b6faaa54f72dfda875ca3` |
| Branch | `main` |
| Verification commit | see Step 19 in git log |

**`git status --short` (before verification commit):**
```
 M lib/features/transactions/application/record_expense_use_case.dart
```

---

## Files Created / Changed

### New test files (created by this verification pass)
| File | Tests |
|---|---|
| `test/database/operation_context_db_test.dart` | 8 |
| `test/database/operation_context_migration_db_test.dart` | 6 |
| `test/database/income_persistence_db_test.dart` | 10 |
| `test/database/expense_persistence_db_test.dart` | 11 |
| `test/database/transfer_persistence_db_test.dart` | 11 (10 transfer + 1 spouse-wallet) |
| `test/database/transaction_history_db_test.dart` | 8 |

### Modified test files
| File | Change |
|---|---|
| `test/database/archive_rules_db_test.dart` | +1 test: reversal on archived account permitted |

### Modified source files
| File | Change |
|---|---|
| `lib/features/transactions/application/record_expense_use_case.dart` | dart format only (pre-existing uncommitted change) |

---

## Test Count Reconciliation

| Category | Before | After | Delta |
|---|---|---|---|
| Total `test(` / `testWidgets(` declarations | 533 | 588 | +55 |

**Per-file breakdown (DB tests):**

| File | Count |
|---|---|
| `ledger_repository_db_test.dart` | 29 |
| `append_only_db_test.dart` | 18 |
| `transfer_persistence_db_test.dart` | 11 (NEW) |
| `expense_persistence_db_test.dart` | 11 (NEW) |
| `protected_account_db_test.dart` | 10 |
| `income_persistence_db_test.dart` | 10 (NEW) |
| `archive_rules_db_test.dart` | 9 (+1) |
| `transaction_history_db_test.dart` | 8 (NEW) |
| `operation_context_db_test.dart` | 8 (NEW) |
| `migration_db_test.dart` | 8 |
| `idempotency_db_test.dart` | 8 |
| `classification_immutability_db_test.dart` | 8 |
| `ordering_determinism_db_test.dart` | 7 |
| `household_cardinality_db_test.dart` | 7 |
| `transaction_boundary_db_test.dart` | 6 |
| `operation_context_migration_db_test.dart` | 6 (NEW) |
| `account_creation_idempotency_db_test.dart` | 6 |
| `profile_isolation_db_test.dart` | 5 |
| `balance_semantics_db_test.dart` | 5 |
| `account_atomicity_db_test.dart` | 5 |
| `historical_metadata_db_test.dart` | 4 |

---

## Step 3: Account-Creation Idempotency

**UNIQUE index confirmed** in `app_database.dart` (`_applyAccountIdempotencyIndex`):
```sql
CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_accounts_idempotency
ON financial_accounts(household_id, idempotency_key)
WHERE idempotency_key IS NOT NULL
```

**Test coverage** (`account_creation_idempotency_db_test.dart`, 6 tests):
- First creation → AppOk ✓ **Database-tested**
- Same key + same payload → AppOk (same ID, no new row) ✓ **Database-tested**
- Same key + different name → AppDuplicateConflict ✓ **Database-tested**
- Same key + different currency → AppDuplicateConflict ✓ **Database-tested**
- Same key in different household → both succeed (key is scoped) ✓ **Database-tested**
- No key provided → each call creates a new account ✓ **Database-tested**

---

## Step 4: Household Initialization

`InitializeHouseholdUseCase.execute()` verified in `initialize_household_use_case_test.dart` (5 tests):
- Empty household name → AppValidationFailure ✓ **Unit-tested**
- Empty primary member name → AppValidationFailure ✓ **Unit-tested**
- Valid inputs → AppOk ✓ **Unit-tested**
- Equivalent retry (same names) → AppOk with existing ✓ **Unit-tested**
- Conflicting retry (different names) → AppDuplicateConflict ✓ **Unit-tested**

Second primary user blocked: DB trigger `one_primary_user_per_household` ✓ **Database-tested** (`household_cardinality_db_test.dart`)

Archiving only active primary user blocked: `ArchiveMemberUseCase` returns `AppValidationFailure` with `error_cannot_archive_primary_user` ✓ **Unit-tested** (`household_use_cases_test.dart`)

---

## Step 5: Historical Classification Policy

| Field | After-creation mutable? | Enforcement | Test |
|---|---|---|---|
| `type` | Never | DB trigger `immutable_account_type_currency` + repo layer | Database-tested |
| `currencyCode` | Never (V1) | DB trigger `immutable_account_type_currency` + repo layer | Database-tested |
| `ownerType` | Yes (no ledger history) | Use-case / repo | Unverified (V1 assumption) |
| `fundPurpose` | Yes (no ledger history) | Use-case / repo | Unverified (V1 assumption) |
| `isProtected` | After ledger history: No | Repo (`ClassificationImmutabilityError`) | Database-tested (`classification_immutability_db_test.dart`) |
| `isSpendable` | Yes | None currently | Unverified |
| `includeInNetWorth` | After ledger history: No | Repo | Database-tested |
| `includeInZakat` | After ledger history: No | Repo | Database-tested |
| `name` | Yes | None | Unverified |
| `isArchived` | Archive-only (one-way) | Repo (`AccountAlreadyArchivedError`) | Database-tested (`archive_rules_db_test.dart`) |

DB trigger evidence:
```dart
'CREATE TRIGGER IF NOT EXISTS immutable_account_type_currency '
'BEFORE UPDATE ON financial_accounts '
'WHEN OLD.type != NEW.type OR OLD.currency_code != NEW.currency_code '
'BEGIN '
"  SELECT RAISE(ABORT, 'Account type and currency are immutable after creation'); "
'END',
```

---

## Step 6: Archived-Account Behavior

`_requireAccount` in `DriftLedgerRepository` throws `ArchivedAccountError` when account is archived:
```dart
if (row.isArchived) throw ArchivedAccountError(accountId);
```

Called in: `recordIncome` ✓, `recordExpense` ✓, `executeTransfer` (source + destination) ✓,
`recordOpeningBalance` ✓, `recordAdjustment` ✓.

**REVERSAL EXCEPTION:** `reverseOperation` uses `_loadAccount` (NOT `_requireAccount`) to load
entries from archived accounts. This is intentional — the append-only correction principle allows
reversals to write opposing entries even when an account is archived.

```dart
/// Loads an account without checking whether it is archived.
///
/// Used for reversal operations only — reversals may correct entries on
/// archived accounts (append-only correction principle).
Future<FinancialAccount> _loadAccount(String accountId, String householdId)
```

**Reversal-on-archived test** added (`archive_rules_db_test.dart`, test 9):
- Archives an account via raw SQL after income
- Calls `reverseOperation` — succeeds (returns `IdempotentOperationResult.created`)
- Balance confirmed 0 after reversal ✓ **Database-tested**

---

## Step 7: operation_contexts Schema

**Table definition** (`operation_contexts_table.dart`):
- Primary key: `operationId` ✓
- Columns: `operation_id`, `household_id`, `spender_member_id`, `beneficiary_member_id`,
  `expense_scope`, `is_recurring`, `recurring_note`, `category_code`, `note`, `created_at` ✓
- `is_recurring` stored as boolean (integer 0/1 in SQLite) ✓
- `category_code` is a stable string code (not localized) ✓

**Triggers in** `app_database.dart` (`_applyOperationContextTriggers`):
```sql
-- FK enforcement:
CREATE TRIGGER IF NOT EXISTS fk_operation_context_operation_id
BEFORE INSERT ON operation_contexts
WHEN NOT EXISTS (SELECT 1 FROM operations WHERE id = NEW.operation_id)
BEGIN SELECT RAISE(ABORT, '...'); END

-- Append-only (no update):
CREATE TRIGGER IF NOT EXISTS no_update_operation_contexts
BEFORE UPDATE ON operation_contexts
BEGIN SELECT RAISE(ABORT, '...'); END

-- Append-only (no delete):
CREATE TRIGGER IF NOT EXISTS no_delete_operation_contexts
BEFORE DELETE ON operation_contexts
BEGIN SELECT RAISE(ABORT, '...'); END
```

**Schema version:** `schemaVersion => 5` ✓

**DB tests** (`operation_context_db_test.dart`, 8 tests):
1. Context written atomically with income ✓ **Database-tested**
2. Context written atomically with expense ✓ **Database-tested**
3. Context written atomically with transfer ✓ **Database-tested**
4. UPDATE rejected by trigger ✓ **Database-tested**
5. DELETE rejected by trigger ✓ **Database-tested**
6. Insert for non-existent operation rejected (FK) ✓ **Database-tested**
7. Insert with mismatched household_id rejected ✓ **Database-tested**
8. Duplicate operation_id rejected (UNIQUE PK) ✓ **Database-tested**

---

## Step 8: Schema Migration

`app_database.dart` migration logic:
```dart
if (from <= 4) {
  // v4 → v5: operation_contexts table for rich transaction metadata.
  await m.createTable(operationContexts);
  await _applyOperationContextTriggers();
}
```

**Migration DB tests** (`operation_context_migration_db_test.dart`, 6 tests):
1. Fresh v5 schema includes `operation_contexts` table ✓ **Database-tested**
2. `operation_contexts` columns match expected schema ✓ **Database-tested**
3. FK + immutability triggers exist in v5 db ✓ **Database-tested**
4. Existing households/accounts/operations/entries preserved ✓ **Database-tested**
5. UPDATE trigger fires on v5 db ✓ **Database-tested**
6. FK trigger fires for orphan context insert ✓ **Database-tested**

---

## Step 9: Income Workflow Evidence

**`income_persistence_db_test.dart`** (10 tests, all **Database-tested**):

1. Valid income → operation row (type=`income`), credit entry (direction=`credit`), context row ✓
2. Amount 0 rejected at `RecordIncomeParams` factory level (`ArgumentError`) ✓
3. Amount negative rejected at `RecordIncomeParams` factory level ✓
4. Archived destination rejected (`ArchivedAccountError`) ✓
5. Account in wrong household rejected (`ArgumentError`) ✓
6. Same idempotency key + same operation ID → `alreadyExists`, no duplicate rows ✓
7. Same idempotency key + different operation ID → `conflict` ✓
8. Income excluded from transfer totals (only `income` type in operations table) ✓
9. Opening-balance analytics unaffected by income (1 `openingBalance` entry remains) ✓
10. Income context row is append-only (UPDATE rejected by trigger) ✓

---

## Step 10: Expense Workflow Evidence

**`expense_persistence_db_test.dart`** (11 tests, all **Database-tested**):

1. Valid expense → debit entry (direction=`debit`), operation (type=`expense`), context ✓
2. Amount 0 rejected at `RecordExpenseParams` factory ✓
3. Archived account rejected (`ArchivedAccountError`) ✓
4. Insufficient funds rejected (`InsufficientFundsError`) ✓
5. Cross-household account rejected (`ArgumentError`) ✓
6. `is_recurring=true` stored; `recurring_note='recurring_marker_not_scheduled'` ✓
7. Protected account requires audit (`MissingProtectedWithdrawalAuditError`) ✓
8. Protected audit written atomically with operation ✓
9. Concurrent overspending: only first expense succeeds after balance drained ✓
10. Idempotent retry → `alreadyExists`, no duplicate debit ✓
11. Conflicting retry (same idem key, different ID) → `conflict` ✓

---

## Step 11: Transfer Workflow Evidence

**`transfer_persistence_db_test.dart`** (11 tests, all **Database-tested**):

1. Valid transfer → debit on source, credit on destination, transfer neutrality, context ✓
2. Same account rejected (`SameAccountTransferError`) ✓
3. Currency mismatch rejected (`CurrencyMismatchTransferError`) ✓
4. Insufficient source balance rejected (`InsufficientFundsError`) ✓
5. Archived source rejected (`ArchivedAccountError` from `_requireAccount`) ✓
6. Archived destination rejected (`ArchivedAccountError` from `_requireAccount`) ✓
   > **Note:** The `if (source.isArchived) throw ArchivedAccountTransferError(...)` checks
   > in `executeTransfer` are dead code — `_requireAccount` throws `ArchivedAccountError`
   > first. The actual rejection behavior is correct but uses a different exception class.
7. Transfer type = `transfer` (not income or expense) ✓
8. Idempotent retry → `alreadyExists` ✓
9. Conflicting retry → `conflict` ✓
10. Concurrent competing transfers: only first succeeds after balance drained ✓

---

## Step 12: Protected-Child Withdrawal Evidence

**`protected_account_db_test.dart`** (10 tests, all **Database-tested**):

- Expense without audit → `MissingProtectedWithdrawalAuditError` ✓
- Expense with valid audit → succeeds ✓
- Audit with wrong `operationId` → `AuditOperationMismatchError` ✓
- Audit with wrong `accountId` → `AuditAccountMismatchError` ✓
- Transfer from protected without audit → `MissingProtectedWithdrawalAuditError` ✓
- Transfer from protected with valid audit → succeeds ✓
- Reversal of income into protected without audit → `MissingProtectedWithdrawalAuditError` ✓
- Reversal of income into protected with valid audit → succeeds ✓
- Reversal audit wrong `operationId` → `AuditOperationMismatchError` ✓
- Non-protected account expense without audit → succeeds ✓

DB-level CHECK enforcement triggers (from `_applyCheckEnforcementTriggers`):
- `check_audit_reason`: `length(trim(NEW.reason)) = 0` → ABORT ✓
- `check_audit_warning_shown`: `NEW.warning_shown != 1` → ABORT ✓
- `check_audit_amount`: `NEW.amount_minor_units <= 0` → ABORT ✓

---

## Step 13: Spouse-Wallet Scenario

**Test** in `transfer_persistence_db_test.dart`, group "Spouse-wallet scenario (7-step DB test)":

```
1. Create mainWallet + spouseWallet
2. Fund mainWallet with 300000 minor units (EGP 3000.00)
3. Transfer 200000 → spouseWallet
4. Record expense 130000 from spouseWallet
5. Query balance = 70000 (EGP 700.00) ✓
6. Transfer 20000 from spouseWallet → mainWallet (return)
7. Query balance = 50000 (EGP 500.00) ✓
8. SpouseWalletSummary query:
   funded=200000, spent=130000, returned=20000, derivedBalance=50000 ✓
```

**Status:** ✓ **Database-tested**

---

## Step 14: Transaction Query Evidence

**`transaction_history_db_test.dart`** (8 tests, all **Database-tested**):

- Date range filter (`fromDate`/`toDate`) restricts results ✓
- Account filter (`operationsForAccount`) restricts to that account ✓
- Operation type filter — income/expense/transfer are distinct ✓
- Transfers excluded from income totals ✓
- Reversed indicator visible (`isReversed=true`, `reversedBy` set) ✓
- Original and reversal both visible in unfiltered list ✓
- Opening balance distinct from income (`type=openingBalance`) ✓
- Deterministic ordering: DESC by `effective_date`, `recorded_at`, `id`; same result on re-run ✓

---

## Step 15: UI Boundary Inspection

Grep for direct DB/repository imports in `lib/features/transactions/presentation/`:
```
lib/features/transactions/presentation/providers/transaction_providers.dart:10:
  import 'package:family_money_manager/features/transactions/data/drift_transaction_query_repository.dart';
```

**Analysis:** `transaction_providers.dart` is the Riverpod provider file, which is the CORRECT
layer to instantiate the concrete repository implementation. Widgets use `ref.watch(...)` to
access providers — no Drift types in widget files.

All other `ref.watch(...)` calls in presentation files access providers only:
```
expense_form_screen.dart: ref.watch(accountsProvider(...))
income_form_screen.dart: ref.watch(accountsProvider(...))
transfer_form_screen.dart: ref.watch(accountsProvider(...))
transactions_screen.dart: ref.watch(...)
transaction_detail_screen.dart: ref.watch(...)
```

No widgets directly import Drift or call repository methods. ✓

---

## Step 16: Scope Scan

| Term | Result |
|---|---|
| `dashboard` / `Dashboard` | No matches |
| `budget` / `Budget` | No matches |
| `goal` / `Goal` | No matches |
| `certificate` / `Certificate` | No matches |
| `zakat` / `Zakat` | Only `includeInZakat` column in schema (permitted: data model field, not Zakat calculation) |
| `sadaqah` / `Sadaqah` | No matches |
| `firebase` / `Firebase` | No matches |
| `biometric` / `Biometric` | Only `biometricConfirmed` field in `child_withdrawal_audits` schema (permitted: audit field, not biometric auth implementation) |

**Verdict:** No forbidden implementations present. ✓

---

## Validation Exit Codes

| Command | Exit Code | Result |
|---|---|---|
| `dart format --output=none --set-exit-if-changed .` | 0 | No formatting issues |
| `flutter analyze` | 0 | No issues found |
| `flutter test` | 0 | 588/588 tests passed |

---

## Full Test Traceability Table

| Behavior | Test File | Test Name | Classification |
|---|---|---|---|
| Account idempotency – same key same payload | `account_creation_idempotency_db_test.dart` | same key, same payload → AppOk | Database-tested |
| Account idempotency – conflict | `account_creation_idempotency_db_test.dart` | same key, different name → conflict | Database-tested |
| Account idempotency – cross-household | `account_creation_idempotency_db_test.dart` | same key, different household → both succeed | Database-tested |
| Household initialization – idempotent retry | `initialize_household_use_case_test.dart` | second call same names → AppOk | Fake-tested |
| Household initialization – conflicting retry | `initialize_household_use_case_test.dart` | second call different names → conflict | Fake-tested |
| Second primary user blocked | `household_cardinality_db_test.dart` | one_primary_user_per_household trigger | Database-tested |
| Archive primary user blocked | `household_use_cases_test.dart` | archive primary user → AppValidationFailure | Fake-tested |
| Account type immutable after creation | `classification_immutability_db_test.dart` | type immutable trigger | Database-tested |
| Currency immutable after creation | `classification_immutability_db_test.dart` | currency immutable trigger | Database-tested |
| isProtected immutable after ledger history | `classification_immutability_db_test.dart` | isProtected immutable | Database-tested |
| Archived account hidden by default | `archive_rules_db_test.dart` | archived hidden in findByHousehold | Database-tested |
| Archive with balance rejected | `archive_rules_db_test.dart` | non-zero balance → AppValidationFailure | Database-tested |
| Reversal on archived account permitted | `archive_rules_db_test.dart` | reversal of income on archived → created | Database-tested |
| Income on archived rejected | `archive_rules_db_test.dart` | income to archived → ArchivedAccountError | Database-tested |
| Expense on archived rejected | `archive_rules_db_test.dart` | expense to archived → ArchivedAccountError | Database-tested |
| operation_contexts atomic with income | `operation_context_db_test.dart` | test 1 | Database-tested |
| operation_contexts atomic with expense | `operation_context_db_test.dart` | test 2 | Database-tested |
| operation_contexts atomic with transfer | `operation_context_db_test.dart` | test 3 | Database-tested |
| operation_contexts UPDATE rejected | `operation_context_db_test.dart` | test 4 | Database-tested |
| operation_contexts DELETE rejected | `operation_context_db_test.dart` | test 5 | Database-tested |
| operation_contexts FK for non-existent op | `operation_context_db_test.dart` | test 6 | Database-tested |
| operation_contexts duplicate PK rejected | `operation_context_db_test.dart` | test 8 | Database-tested |
| v5 schema has operation_contexts table | `operation_context_migration_db_test.dart` | test 1 | Database-tested |
| v5 migration triggers exist | `operation_context_migration_db_test.dart` | test 3 | Database-tested |
| Data preserved through v5 migration | `operation_context_migration_db_test.dart` | test 4 | Database-tested |
| Income creates op + entry + context | `income_persistence_db_test.dart` | test 1 | Database-tested |
| Income amount 0 rejected | `income_persistence_db_test.dart` | test 2 | Database-tested |
| Income archived destination rejected | `income_persistence_db_test.dart` | test 4 | Database-tested |
| Income cross-household rejected | `income_persistence_db_test.dart` | test 5 | Database-tested |
| Income idempotent retry | `income_persistence_db_test.dart` | test 6 | Database-tested |
| Income conflicting idem key | `income_persistence_db_test.dart` | test 7 | Database-tested |
| Income excluded from transfer totals | `income_persistence_db_test.dart` | test 8 | Database-tested |
| Expense creates op + entry + context | `expense_persistence_db_test.dart` | test 1 | Database-tested |
| Expense amount 0 rejected | `expense_persistence_db_test.dart` | test 2 | Database-tested |
| Expense archived account rejected | `expense_persistence_db_test.dart` | test 3 | Database-tested |
| Expense insufficient funds rejected | `expense_persistence_db_test.dart` | test 4 | Database-tested |
| Expense protected requires audit | `expense_persistence_db_test.dart` | test 7 | Database-tested |
| Expense audit atomic with operation | `expense_persistence_db_test.dart` | test 8 | Database-tested |
| Expense concurrent overspending blocked | `expense_persistence_db_test.dart` | test 9 | Database-tested |
| Expense is_recurring stored | `expense_persistence_db_test.dart` | test 6 | Database-tested |
| Transfer neutral (debit + credit) | `transfer_persistence_db_test.dart` | test 1 | Database-tested |
| Transfer same account rejected | `transfer_persistence_db_test.dart` | test 2 | Database-tested |
| Transfer currency mismatch rejected | `transfer_persistence_db_test.dart` | test 3 | Database-tested |
| Transfer insufficient funds rejected | `transfer_persistence_db_test.dart` | test 4 | Database-tested |
| Transfer archived source rejected | `transfer_persistence_db_test.dart` | test 5 | Database-tested |
| Transfer archived destination rejected | `transfer_persistence_db_test.dart` | test 6 | Database-tested |
| Transfer type ≠ income or expense | `transfer_persistence_db_test.dart` | test 7 | Database-tested |
| Transfer concurrent overspending blocked | `transfer_persistence_db_test.dart` | test 10 | Database-tested |
| Spouse-wallet 7-step scenario | `transfer_persistence_db_test.dart` | test 11 | Database-tested |
| Protected withdrawal requires audit | `protected_account_db_test.dart` | expense without audit | Database-tested |
| Protected reversal requires audit | `protected_account_db_test.dart` | reversal without audit | Database-tested |
| Transaction date range filter | `transaction_history_db_test.dart` | date range restricts | Database-tested |
| Transaction account filter | `transaction_history_db_test.dart` | account filter | Database-tested |
| Transaction type filter | `transaction_history_db_test.dart` | type filter | Database-tested |
| Transfer excluded from income totals | `transaction_history_db_test.dart` | transfer excluded | Database-tested |
| Reversed flag visible | `transaction_history_db_test.dart` | reversed indicator visible | Database-tested |
| Original + reversal both visible | `transaction_history_db_test.dart` | both visible | Database-tested |
| Opening balance distinct from income | `transaction_history_db_test.dart` | opening balance distinct | Database-tested |
| Deterministic ordering | `transaction_history_db_test.dart` | deterministic ordering | Database-tested |
| UI widgets don't import Drift | grep result | no Drift in presentation/*.dart | Unverified (grep evidence) |

---

## Schema v5 Complete Schema

```sql
-- Table: households
CREATE TABLE households (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  owner_user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Table: household_members
CREATE TABLE household_members (
  id TEXT NOT NULL PRIMARY KEY,
  household_id TEXT NOT NULL REFERENCES households(id),
  display_name TEXT NOT NULL,
  role TEXT NOT NULL,
  is_archived INTEGER NOT NULL DEFAULT 0,
  archived_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Table: financial_accounts
CREATE TABLE financial_accounts (
  id TEXT NOT NULL PRIMARY KEY,
  household_id TEXT NOT NULL REFERENCES households(id),
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  owner_type TEXT NOT NULL,
  fund_purpose TEXT NOT NULL DEFAULT 'available',
  currency_code TEXT NOT NULL DEFAULT 'EGP',
  is_spendable INTEGER NOT NULL DEFAULT 1,
  is_protected INTEGER NOT NULL DEFAULT 0,
  include_in_net_worth INTEGER NOT NULL DEFAULT 1,
  include_in_zakat INTEGER NOT NULL DEFAULT 0,
  is_archived INTEGER NOT NULL DEFAULT 0,
  archived_at TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  idempotency_key TEXT,
  idempotency_payload TEXT,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Table: operations
CREATE TABLE operations (
  id TEXT NOT NULL PRIMARY KEY,
  household_id TEXT NOT NULL,
  type TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  recorded_at TEXT NOT NULL,
  total_amount_minor_units INTEGER NOT NULL,
  currency_code TEXT,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  description TEXT,
  category_code TEXT,
  scope TEXT,
  spender_role TEXT,
  beneficiary_role TEXT,
  source_account_id TEXT,
  destination_account_id TEXT,
  is_recurring INTEGER NOT NULL DEFAULT 0,
  recurring_rule_id TEXT,
  tags TEXT,
  receipt_path TEXT,
  is_reversed INTEGER NOT NULL DEFAULT 0,
  reversed_by TEXT,
  sync_status TEXT,
  idempotency_key TEXT
);

-- Table: ledger_entries
CREATE TABLE ledger_entries (
  id TEXT NOT NULL PRIMARY KEY,
  operation_id TEXT NOT NULL,
  household_id TEXT NOT NULL,
  account_id TEXT NOT NULL REFERENCES financial_accounts(id),
  direction TEXT NOT NULL,
  amount_minor_units INTEGER NOT NULL,
  currency_code TEXT,
  entry_type TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  recorded_at TEXT NOT NULL,
  notes TEXT,
  created_by TEXT NOT NULL,
  is_reversal INTEGER NOT NULL DEFAULT 0,
  reversal_of_entry_id TEXT
);

-- Table: child_withdrawal_audits
CREATE TABLE child_withdrawal_audits (
  id TEXT NOT NULL PRIMARY KEY,
  operation_id TEXT NOT NULL,
  household_id TEXT NOT NULL,
  account_id TEXT NOT NULL,
  amount_minor_units INTEGER NOT NULL,
  reason TEXT NOT NULL,
  beneficiary TEXT NOT NULL,
  confirmed_at TEXT NOT NULL,
  confirmed_by TEXT NOT NULL,
  warning_shown INTEGER NOT NULL DEFAULT 0,
  biometric_confirmed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

-- Table: operation_contexts  (v5 new)
CREATE TABLE operation_contexts (
  operation_id TEXT NOT NULL PRIMARY KEY,
  household_id TEXT NOT NULL,
  spender_member_id TEXT,
  beneficiary_member_id TEXT,
  expense_scope TEXT,
  is_recurring INTEGER NOT NULL DEFAULT 0,
  recurring_note TEXT,
  category_code TEXT,
  note TEXT,
  created_at TEXT NOT NULL
);
```

---

## Deferred Android Encryption Runtime Risk

- The database binary is sqlite3mc (encryption-ready) via Pub build hook.
- Key injection is deferred to the security-hardening phase.
- Phase 3B opens the database without a key; schema and repository design do not require plaintext fallback.
- See `docs/LOCAL_ENCRYPTION_KEY_MANAGEMENT.md` for the planned injection path.
- **Risk:** Until key injection is implemented, the SQLite file on Android is unencrypted at rest.

---

## Remaining Business / Financial / UX Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Android DB unencrypted at rest | High | Deferred to security-hardening phase |
| `ArchivedAccountTransferError` dead code | Low | `_requireAccount` throws `ArchivedAccountError` first; rejection is correct, class is misleading. Cosmetic fix deferred. |
| `ownerType` / `fundPurpose` updatable without ledger history check | Medium | V1 assumption: these fields are set once at creation. Enforce in a future phase. |
| Automatic recurring-transaction generation | Deferred | `is_recurring=true` is stored as a marker only; scheduling is out of scope for Phase 3B. |
| No cross-currency transfer support | Known limitation | V1 business rule: same-currency transfers only. |
| Audit `warningShown=false` blocked by DB trigger | Low | `check_audit_warning_shown` trigger enforces `warning_shown = 1`. Tested indirectly in `append_only_db_test.dart`. |
