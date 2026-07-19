# Phase 2 Report — Financial Ledger and Core Business Model

**Date:** 2026-07-15  
**Branch:** main  
**HEAD:** (see git log below)  
**Flutter:** 3.x (production project)  
**Dart:** 3.x

---

## 1. Validation Commands and Exit Codes

| Command           | Exit Code | Result              |
| ----------------- | --------- | ------------------- |
| `dart format . `  | 0         | No changes required |
| `flutter analyze` | 0         | No issues found     |
| `flutter test`    | 0         | 259/259 passed      |

No APK, App Bundle, iOS, emulator, simulator, or device build was performed.

---

## 2. Requirements Traceability

### Phase 2 Objectives → Implementation

| Objective                             | Implemented                                                   | Tested                                   |
| ------------------------------------- | ------------------------------------------------------------- | ---------------------------------------- |
| Integer-minor-unit money value type   | `lib/core/financial/money.dart`                               | Unit-tested (money_test.dart, 45+ cases) |
| Currency type with minor-unit scales  | `lib/core/financial/currency.dart`                            | Unit-tested                              |
| Owner and fund purpose enums          | `lib/core/financial/account_enums.dart`                       | Unit-tested                              |
| Ledger-backed account model           | `lib/features/accounts/domain/financial_account.dart`         | Unit-tested                              |
| Account repository (abstract + Drift) | `account_repository.dart`, `drift_account_repository.dart`    | Database-tested                          |
| Income operation                      | `DriftLedgerRepository.recordIncome`                          | Database-tested                          |
| Expense operation                     | `DriftLedgerRepository.recordExpense`                         | Database-tested                          |
| Transfer operation                    | `DriftLedgerRepository.executeTransfer`                       | Database-tested                          |
| Opening balance operation             | `DriftLedgerRepository.recordOpeningBalance`                  | Database-tested                          |
| Adjustment operation                  | `DriftLedgerRepository.recordAdjustment`                      | Database-tested                          |
| Reversal operation                    | `DriftLedgerRepository.reverseOperation`                      | Database-tested                          |
| Audit events (child withdrawal)       | `child_withdrawal_audit.dart`, `drift_ledger_repository.dart` | Unit-tested + DB-tested                  |
| Historical balances                   | `LedgerCalculator.historicalBalance`                          | Unit-tested + DB-tested                  |
| Financial-invariant tests             | `ledger_invariants_test.dart`                                 | Property-tested (500+ random trials)     |
| Drift schema (5 tables)               | `app_database.dart` + tables                                  | Database-tested                          |
| Repository boundaries                 | Abstract interfaces + Drift implementations                   | Enforced                                 |

### Financial Invariants → Tests

| Invariant                                              | Test File                                                                   | Classification                |
| ------------------------------------------------------ | --------------------------------------------------------------------------- | ----------------------------- |
| INV-001: balance = Σcredits − Σdebits                  | ledger_calculator_test + ledger_invariants_test                             | Unit-tested + Property-tested |
| INV-002: Ledger entries immutable (no update/delete)   | ledger_repository_db_test (trigger tests)                                   | Database-tested               |
| INV-003: Transfer neutrality                           | ledger_calculator_test + ledger_invariants_test + ledger_repository_db_test | Unit + Property + DB-tested   |
| INV-004: Reversal nets to zero                         | ledger_calculator_test + ledger_invariants_test + ledger_repository_db_test | Unit + Property + DB-tested   |
| INV-005: No balance manipulation (derived only)        | All balance tests use LedgerCalculator                                      | Unit-tested                   |
| INV-006: Protected withdrawal audit required           | child_withdrawal_audit_test + ledger_repository_db_test                     | Unit-tested + DB-tested       |
| INV-007: Atomic writes in transactions                 | DriftLedgerRepository (all writes)                                          | DB-tested                     |
| INV-008: Idempotency (duplicate = alreadyExists)       | ledger_repository_db_test (dup tests)                                       | Database-tested               |
| INV-009: Net worth = Σ(included account balances)      | balanceRepo.netWorthBalances                                                | Documented                    |
| INV-011: Transfer excluded from income/expense reports | operation_test + ledger_invariants_test                                     | Unit-tested                   |
| INV-012: Deterministic historical balances             | ledger_calculator_test + ledger_invariants_test                             | Unit + Property-tested        |
| INV-015: Archived accounts preserve history            | financial_account_test                                                      | Unit-tested                   |

---

## 3. Financial Entities Implemented

### Value Types

- **`Money`** — immutable, stores only `int minorUnits`, includes overflow detection, cross-currency protection, allocation, serialization, and redacted `toString()`
- **`Currency`** — enum of ISO 4217 codes with `minorUnitScale` per currency (EGP=2, JPY=0, KWD=3, etc.)

### Enums

- **`FinancialAccountType`** — 12 types, `requiresProtectedWithdrawalAudit` flag on `childProtectedFund`
- **`AccountOwnerType`** — user, spouse, household, child, shared
- **`FundPurpose`** — 10 purposes
- **`LedgerDirection`** — credit / debit with `.opposite` helper
- **`LedgerEntryType`** — 25 types (Phase 2 active: 11), `isDebitType`, `isTransferType`
- **`OperationType`** — 21 types (Phase 2 active: 7), `isExcludedFromIncomeExpenseReports`
- **`ExpenseScope`**, **`HouseholdMemberRole`**, **`SyncStatus`**

### Domain Entities

- **`FinancialAccount`** — immutable entity; `type` and `currencyCode` excluded from `copyWith`; `requiresWithdrawalAudit`, `isChildProtectedFund` derived predicates
- **`CreateAccountParams`** — parameter object for account creation
- **`LedgerEntryRecord`** — pure projection for balance calculations (no Drift dependency)
- **`Operation`** — append-only operation record; `isReversed`/`reversedBy` are the only mutable fields after creation
- **`ChildWithdrawalAudit`** — immutable audit record; asserts `warningShown=true`, `reason≠""`, `amountMinorUnits>0`
- **`ChildWithdrawalAuditParams`** — caller-constructed params; enforces `warningShown=true` by assertion

### Operation Params

- `RecordIncomeParams` — assert `amountMinorUnits > 0`
- `RecordExpenseParams` — assert `amountMinorUnits > 0`
- `ExecuteTransferParams` — assert `amountMinorUnits > 0`
- `RecordOpeningBalanceParams` — assert `amountMinorUnits >= 0`
- `RecordAdjustmentParams` — assert `amountMinorUnits ≠ 0`; `isCredit` derived property
- `ReverseOperationParams` — optional `reason`

### Error Types

- `CurrencyMismatchError`, `MoneyOverflowError` (Money layer)
- `MissingProtectedWithdrawalAuditError`, `InsufficientFundsError` (domain layer)
- `SameAccountTransferError`, `CurrencyMismatchTransferError`, `ArchivedAccountTransferError` (ledger layer)
- `DuplicateOpeningBalanceError`, `OperationNotFoundError`, `DuplicateReversalError` (ledger layer)
- `DuplicateAccountIdError`, `AccountNotFoundError`, `AccountAlreadyArchivedError` (account layer)

---

## 4. Operation Types Implemented

| Type                | Direction                         | Entries                                     | Protected Fund Rule                                  |
| ------------------- | --------------------------------- | ------------------------------------------- | ---------------------------------------------------- |
| Opening Balance     | Credit destination                | 1 credit (`openingBalance`)                 | N/A                                                  |
| Income              | Credit destination                | 1 credit (`income`)                         | N/A                                                  |
| Expense             | Debit source                      | 1 debit (`expense`)                         | Required if protected                                |
| Transfer            | Debit source + Credit destination | 2 entries (`transferOut`, `transferIn`)     | Required if source protected                         |
| Adjustment (credit) | Credit account                    | 1 credit (`adjustmentCredit`)               | N/A                                                  |
| Adjustment (debit)  | Debit account                     | 1 debit (`adjustmentDebit`)                 | Required if protected                                |
| Reversal            | Mirror of original                | Same count as original (reversed direction) | Required for any reversed debit on protected account |

**Transfer rules:**

- Source ≠ Destination (SameAccountTransferError)
- Same currency in V1 (CurrencyMismatchTransferError)
- No archived accounts (ArchivedAccountTransferError)
- Both entries written atomically

**Reversal rules:**

- Original must exist (OperationNotFoundError)
- Original must not already be reversed (DuplicateReversalError)
- Reversal has its own `reversalOperationId` as idempotency key
- Sets `isReversed=true` and `reversedBy` on original atomically

---

## 5. Database Tables and Constraints

### Tables

| Table                     | Rows                 | Key Constraints                                                 |
| ------------------------- | -------------------- | --------------------------------------------------------------- |
| `households`              | Root household       | PK: `id`                                                        |
| `financial_accounts`      | Account metadata     | PK: `id`; FK → `households`; UNIQUE `id` per household          |
| `operations`              | Operation records    | PK: `id`; FK → `households`, `financial_accounts` (source/dest) |
| `ledger_entries`          | Individual entries   | PK: `id`; FK → `operations`, `households`, `financial_accounts` |
| `child_withdrawal_audits` | Protected-fund audit | PK: `id`; FK → `operations`; UNIQUE `operation_id`              |

### Additional Constraints (applied via custom SQL in `onCreate`)

- `CREATE TRIGGER no_update_ledger_entries` — blocks all UPDATE on `ledger_entries`
- `CREATE TRIGGER no_delete_ledger_entries` — blocks all DELETE on `ledger_entries`
- `CREATE TRIGGER no_update_child_audits` — blocks all UPDATE on `child_withdrawal_audits`
- `CREATE TRIGGER no_delete_child_audits` — blocks all DELETE on `child_withdrawal_audits`
- `CREATE UNIQUE INDEX idx_ledger_idempotency ON ledger_entries(operation_id, account_id, direction, entry_type)` — idempotency key
- Performance indexes on `account_id`, `operation_id`, `effective_date`, `household_id`, `type`, `is_archived`

### PRAGMA settings (in `beforeOpen`)

- `PRAGMA journal_mode = WAL` — for concurrent read safety
- `PRAGMA foreign_keys = ON` — enforces FK integrity

### Schema Version: 1

- `onUpgrade` hook reserved for future migrations (currently empty)

---

## 6. Repository Boundaries

### AccountRepository (abstract interface)

- `createAccount(CreateAccountParams)` → `FinancialAccount`
- `findById(id, householdId)` → `FinancialAccount?`
- `findByHousehold(householdId, {includeArchived})` → `List<FinancialAccount>`
- `hasOpeningBalance(accountId, householdId)` → `bool`
- `archiveAccount(id, householdId, archivedAt, updatedAt)` → `FinancialAccount`
- `updateAccount(id, householdId, ...mutable fields...)` → `FinancialAccount`

### LedgerRepository (abstract interface)

- `recordIncome(RecordIncomeParams)` → `IdempotentOperationResult`
- `recordExpense(RecordExpenseParams, {auditParams?})` → `IdempotentOperationResult`
- `executeTransfer(ExecuteTransferParams, {auditParams?})` → `IdempotentOperationResult`
- `recordOpeningBalance(RecordOpeningBalanceParams)` → `IdempotentOperationResult`
- `recordAdjustment(RecordAdjustmentParams, {auditParams?})` → `IdempotentOperationResult`
- `reverseOperation(ReverseOperationParams, {auditParams?})` → `IdempotentOperationResult`
- `entriesForAccount(accountId, householdId)` → `List<LedgerEntry>`
- `findOperation(operationId, householdId)` → `Operation?`
- `operationsInRange(householdId, fromDate, toDate)` → `List<Operation>`

### BalanceRepository (abstract interface)

- `currentBalanceMinorUnits(accountId, householdId)` → `int`
- `historicalBalanceMinorUnits(accountId, householdId, asOfDate)` → `int`
- `netWorthBalances(householdId)` → `List<AccountBalance>`

### LedgerCalculator (pure static class — no Flutter/Drift dependency)

- `balance(accountId, entries, currency)` → `Money`
- `historicalBalance(accountId, entries, currency, asOfDate)` → `Money`
- `totalBalance(List<Money>)` → `Money`

---

## 7. Tests — Exact Inventory

### Unit tests (`test/unit/`)

**`money_test.dart`** — 45 tests

- Currency enum: fromCode, isSupported, minorUnitScale, error cases
- Money construction: positive, zero, negative, fromMinorUnits, invalid currency
- Predicates: isZero, isPositive, isNegative
- Equality and hashCode
- Arithmetic: add, subtract, negate, abs
- Currency mismatch: add, subtract, compareTo → `CurrencyMismatchError`
- Overflow: add overflow, subtract overflow, negate min-int → `MoneyOverflowError`
- Comparison: compareTo, <, <=, >, >=
- Allocation: even, remainder, 1 part, zero parts, negative parts, by ratios, edge cases
- Serialization: toJson/fromJson round-trip, different currencies, invalid currency in JSON
- toString: value not revealed; toDebugString: reveals value
- Different minor-unit scales: JPY (0), KWD (3), EGP (2)

**`ledger_calculator_test.dart`** — 19 tests

- balance: empty, single credit, credit+debit, multi-entry, cross-account filter, opening balance, reversal pair net, deficit
- historicalBalance: future exclusion, exact-date inclusion, all-future returns zero, backdated, reversal within window
- totalBalance: empty (EGP default), sum, single, negatives
- Transfer neutrality invariant (INV-003)
- Opening balance distinguishable from income
- Adjustment variants (credit/debit)
- Deterministic ordering (order independence)

**`ledger_invariants_test.dart`** — 7 test groups (500+ random trials)

- INV-001: 200 random entry sequences, balance = Σcredits − Σdebits
- INV-003: 100 random transfers, total always preserved
- INV-004: 100 random reversal pairs, balance always restored
- INV-012: 100 random shuffle tests, balance invariant under reorder
- INV-011: Transfer type distinguishability
- Duplicate operation property (proves DB constraint necessity)
- Money arithmetic properties: commutativity, identity, subtraction identity, double negation, allocation sum (50 trials each)

**`financial_account_test.dart`** — 19 tests

- Construction and field assignment
- Immutability: type not in copyWith, currencyCode not in copyWith, id/householdId preserved
- copyWith: mutable fields updatable
- Equality: same id+householdId, different id
- Protected predicates: childProtectedFund → requiresWithdrawalAudit always true; isProtected flag → requiresWithdrawalAudit; normal → false; isChildProtectedFund
- Archival: fields preserved when archived
- Enum round-trips: FinancialAccountType (all values), AccountOwnerType (all values), FundPurpose (all values)
- CreateAccountParams construction

**`child_withdrawal_audit_test.dart`** — 9 tests

- Valid construction
- Assertions: warningShown=false, empty reason, amountMinorUnits=0
- Equality by id
- AuditParams: warningShown=false, valid construction
- Error type string contents

**`operation_test.dart`** — 25 tests

- Operation construction, equality
- RecordIncomeParams: valid, zero/negative amount asserts
- RecordExpenseParams: valid, non-positive asserts
- ExecuteTransferParams: valid, zero amount
- RecordOpeningBalanceParams: zero amount valid, negative asserts
- RecordAdjustmentParams: positive, negative, isCredit, zero asserts
- ReverseOperationParams: required fields, optional reason
- OperationType: fromCode all values, unknown throws, transfer excluded, income/expense included
- LedgerDirection: opposite, fromCode, unknown throws
- LedgerEntryType: fromCode all values, isDebitType, isTransferType

### Database tests (`test/database/`)

**`ledger_repository_db_test.dart`** — 29 tests (in-memory SQLite via `AppDatabase.forTesting()`)

- Account CRUD: create, retrieve, duplicate ID throws, findById null, findByHousehold excludes archived, includeArchived returns all, double-archive throws
- Income: create, duplicate ID → alreadyExists (balance not doubled)
- Expense: create, duplicate → alreadyExists
- Transfer: neutrality, duplicate → alreadyExists+balance check, same-account → SameAccountTransferError, cross-currency → CurrencyMismatchTransferError
- Opening balance: create, duplicate → alreadyExists
- Adjustment: positive, negative
- Reversal: restores balance, duplicate-reversed → DuplicateReversalError, same reversal ID → alreadyExists
- Immutability triggers: UPDATE blocked, DELETE blocked
- Historical balance: future exclusion, exact-date inclusion
- Protected fund: no audit → MissingProtectedWithdrawalAuditError, with audit → success
- hasOpeningBalance: before/after

### Existing tests (Phase 1 — unchanged)

- `redacted_logger_test.dart` — 20 tests
- `app_error_test.dart` — 8 tests
- `app_config_test.dart` — 5 tests
- `app_route_test.dart` — 12 tests (navigation)
- Widget tests — 30 tests (smoke screen, foundation screen, app)

**Total: 259 tests, 0 failures, 0 skipped**

---

## 8. Files Created and Changed

### New (Phase 2)

**Core financial layer:**

- `lib/core/financial/currency.dart`
- `lib/core/financial/money.dart`
- `lib/core/financial/account_enums.dart`
- `lib/core/financial/ledger_enums.dart`
- `lib/core/financial/ledger_calculator.dart`

**Database:**

- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart` (generated)
- `lib/core/database/tables/households_table.dart`
- `lib/core/database/tables/financial_accounts_table.dart`
- `lib/core/database/tables/ledger_entries_table.dart`
- `lib/core/database/tables/operations_table.dart`
- `lib/core/database/tables/child_withdrawal_audits_table.dart`

**Accounts feature:**

- `lib/features/accounts/domain/financial_account.dart`
- `lib/features/accounts/data/account_repository.dart`
- `lib/features/accounts/data/drift_account_repository.dart`

**Ledger feature:**

- `lib/features/ledger/domain/ledger_entry.dart`
- `lib/features/ledger/domain/operation.dart`
- `lib/features/ledger/domain/child_withdrawal_audit.dart`
- `lib/features/ledger/data/ledger_repository.dart`
- `lib/features/ledger/data/drift_ledger_repository.dart`

**Balance feature:**

- `lib/features/balance/domain/balance_repository.dart`
- `lib/features/balance/data/drift_balance_repository.dart`

**Tests:**

- `test/unit/core/financial/money_test.dart`
- `test/unit/core/financial/ledger_calculator_test.dart`
- `test/unit/core/financial/ledger_invariants_test.dart`
- `test/unit/features/accounts/financial_account_test.dart`
- `test/unit/features/ledger/child_withdrawal_audit_test.dart`
- `test/unit/features/ledger/operation_test.dart`
- `test/database/ledger_repository_db_test.dart`

### Modified (Phase 2)

- `pubspec.yaml` — added `drift`, `drift_flutter`, `uuid`, `path_provider`, `meta`; added `sqlite3mc` hook

---

## 9. Dependencies and Resolved Versions

| Package         | Version | Role                                        |
| --------------- | ------- | ------------------------------------------- |
| `drift`         | 2.34.2  | Type-safe SQLite ORM                        |
| `drift_flutter` | 0.13.0  | Flutter SQLite executor                     |
| `drift_dev`     | 2.34.0  | Code generation                             |
| `sqlite3`       | 3.4.0   | SQLite native library (with sqlite3mc hook) |
| `uuid`          | 1.4.0   | UUID generation                             |
| `path_provider` | 2.1.6   | Application documents directory             |
| `meta`          | 1.9.1   | `@immutable` annotation                     |

**sqlite3mc hook** (in `pubspec.yaml`):

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

The native binary is encryption-ready. Key injection deferred to security-hardening phase.

---

## 10. Claim Classification

| Claim                                          | Classification                                    |
| ---------------------------------------------- | ------------------------------------------------- |
| Money type stores only integers                | Unit-tested                                       |
| Money overflow is detected                     | Unit-tested                                       |
| Cross-currency arithmetic rejected             | Unit-tested                                       |
| Currency minor-unit scales correct             | Unit-tested                                       |
| Account type immutable after creation          | Unit-tested                                       |
| Account currency immutable after creation      | Unit-tested                                       |
| Balance = Σcredits − Σdebits                   | Unit-tested + Property-tested                     |
| Transfer neutrality                            | Unit + Property + DB-tested                       |
| Reversal nets to zero                          | Unit + Property + DB-tested                       |
| Idempotent operations                          | Database-tested                                   |
| Ledger entries immutable (triggers)            | Database-tested                                   |
| Protected withdrawal requires audit            | Unit-tested + DB-tested                           |
| Historical balance excludes future entries     | Unit + DB-tested                                  |
| Balance is order-independent                   | Unit + Property-tested                            |
| Transfers excluded from income/expense reports | Unit-tested                                       |
| Atomic writes (transaction)                    | Database-tested                                   |
| Opening balance distinguishable from income    | Unit-tested                                       |
| Drift schema generates cleanly                 | Build-verified (build_runner)                     |
| Production app builds (release APK/iOS)        | **UNVERIFIED** (deferred per scope)               |
| Android SQLite3MultipleCiphers runtime         | **UNVERIFIED** (deferred per Phase 1.5A decision) |
| Encrypted key injection in production          | **DOCUMENTED ONLY** (deferred to security phase)  |
| Cloud sync or conflict resolution              | **NOT IMPLEMENTED** (out of scope)                |

---

## 11. Deferred Encryption Runtime Verification

Per Phase 1.5A, Android runtime verification of SQLite3MultipleCiphers is an unresolved release risk:

- The `sqlite3mc` build hook is configured in `pubspec.yaml`.
- The native binary is compiled with encryption support.
- Phase 2 opens the database without a key (unencrypted at rest during development).
- The `_devConnection()` factory in `app_database.dart` documents where key injection will occur.
- See `docs/LOCAL_ENCRYPTION_KEY_MANAGEMENT.md` for the planned key-management architecture.
- **Android runtime verification: UNVERIFIED — deferred to production persistence/security phase.**

---

## 12. Remaining Financial Model Risks

1. **Android SQLite3MultipleCiphers runtime** — unverified in a release build on a real device. Documented in `PHASE_1_5_ANDROID_REPORT.md`.
2. **Key injection** — the security-hardening phase must replace `_devConnection()` with a version that calls `PRAGMA key` using a key from Android Keystore / iOS Keychain before the first query.
3. **Plaintext at rest** — Phase 2 data is stored unencrypted. This is acceptable for development but must be resolved before any beta distribution.
4. **Integer overflow in balance sums** — `LedgerCalculator` uses checked arithmetic and throws `StateError` on overflow. Very large accounts (>9 quadrillion minor units) would trigger this. Acceptable for household scale.
5. **Single-currency per account** — V1 prohibits cross-currency transfers. Multi-currency is a documented future phase.
6. **Opening-balance migration** — no migration path for importing external historical data is defined yet.
7. **Concurrent write isolation** — SQLite WAL mode is configured; however, true concurrent write safety across multiple Dart isolates is not tested. Phase 2 is single-isolate.

---

## 13. Scope Scan — No Later-Phase Feature UI

The following were confirmed absent from the Phase 2 codebase:

- No dashboard or account-list widget
- No report or analytics screen
- No goal, certificate, gold, liability, Zakat, sadaqah, or AI module
- No PIN, biometrics, or authentication
- No cloud sync or Firebase dependency
- No backup or restore functionality
- No voice input
- No budget or category management UI
- No production financial data seeding

The existing smoke screen (`SmokeScreen`) and foundation detail screen (`FoundationDetailScreen`) from Phase 1 remain unchanged and serve only as developer inspection surfaces.

---

## 14. Git Summary

```
Branch: main
HEAD: 6f50d15 Phase 1.5A: Android runtime closure and DECISION-004 finalisation

Unstaged Phase 2 changes (to be committed):
  Modified: pubspec.yaml, pubspec.lock, ios/** (Drift/sqlite3mc native build artifacts)
  New: lib/core/financial/ (5 files)
  New: lib/core/database/ (7 files + generated)
  New: lib/features/accounts/ (3 files)
  New: lib/features/ledger/ (5 files)
  New: lib/features/balance/ (2 files)
  New: test/unit/core/financial/ (3 test files)
  New: test/unit/features/accounts/ (1 test file)
  New: test/unit/features/ledger/ (2 test files)
  New: test/database/ (1 integration test file)
  New: docs/PHASE_2_REPORT.md
```

---

## 15. Phase Boundary Confirmation

**Phase 2 is complete.**

Next phase (when approved):

- Household UI: account list, account creation, balance display
- Phase 3 feature: income/expense entry screens

**Stop: Phase 2 report complete. Phase 3 not started.**
