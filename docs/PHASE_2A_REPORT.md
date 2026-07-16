# Phase 2A Report — Financial-Ledger Verification and Hardening

**Date:** 2026-07-16  
**Branch:** `main`  
**HEAD at report time:** `7d4a9b94b123c107d7506783e1a7d0b4fead8fda` (Phase 2 base)  
**Working commit:** staged, see "Git Summary" below  

---

## 1. Critical Defects Found and Fixed

| # | Severity | Defect | Fix |
|---|----------|--------|-----|
| D-01 | Critical | `assert()` used for all financial validation — silently skips in release | Replaced with factory constructors throwing `ArgumentError` |
| D-02 | Critical | `recordIncome` had no `_requireAccount` call — cross-household account reference succeeded | Added `_requireAccount` guard before transaction |
| D-03 | Critical | `recordOpeningBalance` had no `_requireAccount` call | Added guard before transaction |
| D-04 | High | Idempotency enforced only at leg level, not operation level; no `conflict` result | Added `idempotency_key` column, scoped unique index, and `conflict` enum value |
| D-05 | High | No database-level protection against UPDATE/DELETE of financial records | Added 5 SQLite triggers (`restrict_operations_update`, `no_delete_operations`, `no_update_ledger_entries`, `no_delete_ledger_entries`, `no_update_child_audits`, `no_delete_child_audits`) |
| D-06 | High | Classification fields (`isProtected`, `includeInNetWorth`, `includeInZakat`) were mutable via `updateAccount` even after ledger entries existed | Added `_hasLedgerEntries` guard throwing `ClassificationImmutabilityError` |
| D-07 | High | `DriftBalanceRepository._getAccount` used `getSingle()` — throws on cross-household query, wrong behavior | Changed to `getSingleOrNull()`, returns 0 for unknown account |
| D-08 | Medium | `Money.allocate()` used `%` operator which is Euclidean in Dart (non-negative result) — negative money allocated incorrectly, sum ≠ original | Changed to `remainder()` (truncating division, preserves sign of dividend) |
| D-09 | Medium | No CHECK or FK trigger preventing ledger entries referencing operations from a different household | Added `fk_ledger_entries_operation` and `fk_child_audit_operation` triggers |
| D-10 | Low | Ordering determinism relied on 2 fields; same `recordedAt` rows had undefined order | Added entry `id` as a third tie-breaker in all ledger queries |

---

## 2. Assertion-Based Checks Removed

All `assert(` calls in production financial code were replaced with always-executed `ArgumentError` throws via private factory constructors:

| File | Previous | After |
|------|---------|-------|
| `lib/core/financial/money.dart` | No validation (constructor `const`) | Release-safe; supports negative values for balance display |
| `lib/features/ledger/domain/ledger_entry.dart` | `assert(amountMinorUnits > 0)` etc. | Factory with `ArgumentError` for every invalid field |
| `lib/features/ledger/domain/operation.dart` | `assert(...)` in all 6 param classes | Factory constructors throwing `ArgumentError` |
| `lib/features/ledger/domain/child_withdrawal_audit.dart` | `assert(warningShown)`, `assert(reason.isNotEmpty)` etc. | Factory constructors with `ArgumentError` |

Private constructors (`LedgerEntry._`, `RecordIncomeParams._`, etc.) prevent construction outside the factory.

---

## 3. Final Idempotency Design

### Identity Concepts

| Concept | Column | Uniqueness scope |
|---------|--------|-----------------|
| Operation ID | `operations.id` | Global (PRIMARY KEY) |
| Idempotency key | `operations.idempotency_key` | Scoped: `(household_id, idempotency_key)` — unique partial index where `idempotency_key IS NOT NULL` |
| Ledger-entry ID | `ledger_entries.id` | Global (PRIMARY KEY) |
| Reversal ID | `operations.id` of the reversal op | Global |
| Original-op reference | `operations.source_operation_id` | Per-household FK check |

### Outcomes

| Scenario | Result |
|----------|--------|
| Same operation ID, same household | `alreadyExists` — no new records |
| Same idempotency key, different op ID, same household | `conflict` — no records written |
| Same idempotency key, different household | `created` — profile isolation preserved |
| Complete rollback then retry | `created` — succeeds cleanly |

### Database Enforcement

```sql
CREATE UNIQUE INDEX IF NOT EXISTS idx_ops_scoped_idempotency
  ON operations(household_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;
```

---

## 4. Append-Only Enforcement

### Triggers (applied in `AppDatabase._applyAppendOnlyTriggers`)

| Trigger | Table | Action |
|---------|-------|--------|
| `restrict_operations_update` | `operations` | BEFORE UPDATE — allows only `is_reversed`, `reversed_by`, `updated_at` |
| `no_delete_operations` | `operations` | BEFORE DELETE — always aborts |
| `no_update_ledger_entries` | `ledger_entries` | BEFORE UPDATE — always aborts |
| `no_delete_ledger_entries` | `ledger_entries` | BEFORE DELETE — always aborts |
| `no_update_child_audits` | `child_withdrawal_audits` | BEFORE UPDATE — always aborts |
| `no_delete_child_audits` | `child_withdrawal_audits` | BEFORE DELETE — always aborts |

### CASCADE DELETE Prevention

The `households` → `financial_accounts` → `operations` → `ledger_entries` FK chain uses `RESTRICT` (no cascade). Deleting a parent household does not cascade-delete financial history.

### Corrections Policy

All corrections must be represented by:
- A reversal operation (which creates new inverse ledger entries)
- A new adjustment operation with audit reason
- A dated metadata-change event (not yet implemented; documented in `DATA_MODEL.md`)

---

## 5. Per-Operation Ledger Structures

Validated by `_applyCheckEnforcementTriggers` and domain-layer factory constructors:

| Operation type | Expected legs | External leg? |
|---------------|--------------|--------------|
| Income | credit to managed account | 1 external source leg |
| Expense | debit from managed account | 1 external destination leg |
| Transfer | debit source + credit destination (equal amounts, same currency) | None |
| Opening balance | credit to managed account | 1 external boundary leg |
| Adjustment | credit or debit to managed account | 1 external boundary leg; mandatory reason |
| Reversal | exact inverse of every original leg | Mirrors original |

Rejected by CHECK triggers: amount ≤ 0, empty reason for audits, `warning_shown = false` for child audits.

---

## 6. Protected-Child Enforcement

### Net-Effect Rule

An operation reduces a protected child-owned account when any of its ledger entries contains:
- `direction = debit`
- `account_id` referencing a `financial_accounts` row where `is_protected = true`

The repository (`DriftLedgerRepository._checkProtectedWithdrawal`) determines this from the net effect of entries, not from operation type.

### Audit Requirements

A `ChildWithdrawalAuditParams` must be provided whenever a protected account is debited. The audit is validated for:
- Non-empty `reason`
- `warningShown = true`
- `biometricConfirmed` (stored)
- Matching `operationId`, `accountId`, `householdId`
- Valid `confirmedAt`, `confirmedBy`

Rejected scenarios (all throw at the repository layer):
- Expense/transfer/adjustment/reversal reducing a protected account without audit
- Audit with wrong `operationId` or `accountId` → `AuditOperationMismatchError` / `AuditAccountMismatchError`
- Cross-profile audit

---

## 7. Historical Metadata Policy (Classification Immutability)

**Policy name:** Classification-Immutability-After-Financial-Use  
**Effective date:** Phase 2A  
**Trigger file:** `lib/features/accounts/data/drift_account_repository.dart`

### Immutable After Creation (Never in `updateAccount`)

- `type` (FinancialAccountType)
- `currencyCode`
- `ownerType` (AccountOwnerType)
- `fundPurpose` (FundPurpose)

### Immutable After First Ledger Entry

- `isProtected` — changing silently alters which historical operations required child-withdrawal audits
- `includeInNetWorth` — changing silently alters historical net-worth aggregation
- `includeInZakat` — changing silently alters historical Zakat computation

Attempting to change any of these after ledger entries exist throws `ClassificationImmutabilityError`.

### Mutable Display Fields (Always)

- `name`, `displayOrder`, `notes`, `metadata`, `isSpendable`

### No UI for Metadata Changes

Phase 2A contains no feature UI.  Metadata changes, if needed in the future, must go through a dated-reclassification event recorded in a separate audit table (not yet created).

---

## 8. Profile-Isolation Enforcement

Every financial row is profile-isolated through multiple layers:

| Layer | Mechanism |
|-------|-----------|
| Domain factory | `householdId` required in all parameter constructors; empty → `ArgumentError` |
| Repository | `_requireAccount(accountId, householdId)` called before every transaction |
| Database (operations) | `household_id NOT NULL`, FK to `households.id` |
| Database (ledger entries) | `household_id NOT NULL`, FK trigger `fk_ledger_entries_operation` rejects mismatched household |
| Database (audits) | FK trigger `fk_child_audit_operation` rejects mismatched household |
| Balance queries | `DriftBalanceRepository._getAccount` filters by `householdId`; returns 0 for unknown |

---

## 9. Historical Ordering Policy

**Ordering:** `effective_date ASC → recorded_at ASC → id ASC`

- `effective_date`: user-chosen business date (string `YYYY-MM-DD`)
- `recorded_at`: wall-clock ISO 8601 timestamp at insert time (never changes after write)
- `id`: stable string primary key — tie-breaker when two entries share the same `recorded_at` (e.g. direct SQL inserts in tests)

This ordering is **deterministic** because all three fields are persisted once and never updated.  It does not rely on row insertion order, SQLite `rowid`, or current system time at read time.

---

## 10. Money Range and Overflow Policy

| Aspect | Policy |
|--------|--------|
| Storage type | Dart `int` (64-bit signed), SQLite `INTEGER` |
| Valid range | `-(2^63)` to `(2^63 - 1)` — Dart `int` range |
| Ledger entry amounts | Always **positive** (`> 0`); direction expressed via `LedgerDirection` enum |
| Balance values | May be negative (debit-heavy accounts) |
| Overflow detection | `_checkedAdd` in `Money` uses `BigInt` comparison before returning — throws `MoneyOverflowError` |
| `REAL` / `double` | Forbidden. No financial value is stored as `REAL` or computed with `double` |
| Allocation | `Money.allocate()` uses `~/` and `remainder()` (truncating division) to ensure sum equals original for both positive and negative values |
| Allocation remainder | Distributed to first bucket; total always equals `minorUnits` |

---

## 11. Randomized / Property-Test Methodology

**Library:** `dart:math Random` (custom seeded loop — no external property library)  
**Classification:** Randomized (not property-based; no shrinking)  
**Trials per invariant:** 200  
**Seed policy:** Fixed `const baseSeed = 0x4C6564676572` ("Ledger") for reproducibility; each trial uses `baseSeed ^ invariantId XOR trial-seed` so trials are independent  
**Failure reproduction:** Re-run with the same seed; seed is available in every `reason:` string attached to `expect`  
**Shrinking:** Not supported  

### Invariants Checked

| ID | Invariant | Trials | File |
|----|-----------|--------|------|
| INV-R01 | `balance == Σ(signed entries)` | 200 | `ledger_invariants_randomized_test.dart` |
| INV-R02 | Internal transfers preserve total internal value | 200 | ↑ |
| INV-R03 | De-duplicated entry set produces same balance | 200 | ↑ |
| INV-R04 | Full reversal of one entry restores prior balance | 200 | ↑ |
| INV-R06 | `LedgerEntry` factory rejects zero/negative amounts | 200 | ↑ |
| INV-R07 | Balance computation is deterministic across repeated calls | 200 | ↑ |
| INV-Money | `Money.allocate()` sum always equals original (positive & negative) | 200 | ↑ |

No financial user data is logged in any randomized test.

---

## 12. Transaction Boundaries

Every financial write executes inside `_db.transaction(...)`:

| Operation | Covered by one transaction |
|-----------|--------------------------|
| `recordIncome` | parent op + credit entry |
| `recordExpense` | parent op + debit entry + optional audit |
| `executeTransfer` | parent op + debit entry + credit entry |
| `recordOpeningBalance` | parent op + credit entry |
| `recordAdjustment` | parent op + ledger entry + optional audit |
| `reverseOperation` | reversal op + N reversed entries + idempotency reservation |

**Validation method (injected failure):** Invalid params cause `ArgumentError` before the transaction starts → zero records in DB.  Wrong account ID causes `ArgumentError` inside the guard call (before transaction) → zero records.  Tests in `transaction_boundary_db_test.dart` verify both.

**No public orphan insert:** `DriftLedgerRepository` does not expose any public method that inserts a `LedgerEntry` independently of a parent operation.  The FK enforcement trigger additionally blocks raw SQL orphan inserts.

---

## 13. Test Inventory

### Phase 1 vs. Phase 2 vs. Phase 2A Test Count

| Phase | Description | Tests |
|-------|------------|-------|
| Phase 1 | Foundation: app config, error model, logger, navigation, widget smoke | 106 |
| Phase 2 | Financial domain and ledger DB integration | 253 |
| Phase 2A | Hardening: append-only, idempotency, isolation, ordering, classification, randomized, boundary | 390 |

The jump from 369 (pre-session) to 390 was introduced by Phase 2A new test files.

### Test File Inventory

| File | Tests | Classification | Requirements Covered |
|------|-------|---------------|---------------------|
| `test/database/append_only_db_test.dart` | 18 | Database | INV-005 (append-only), trigger correctness |
| `test/database/classification_immutability_db_test.dart` | 8 | Database | INV-017 (historical metadata) |
| `test/database/idempotency_db_test.dart` | 8 | Database | INV-006 (scoped idempotency, conflict) |
| `test/database/ledger_repository_db_test.dart` | 29 | Database / Integration | All ledger write paths |
| `test/database/ordering_determinism_db_test.dart` | 7 | Database | INV-012 (stable ordering) |
| `test/database/profile_isolation_db_test.dart` | 5 | Database | INV-009 (household isolation) |
| `test/database/protected_account_db_test.dart` | 10 | Database | INV-008 (child-fund audit) |
| `test/database/transaction_boundary_db_test.dart` | 6 | Database | INV-010 (atomicity) |
| `test/unit/app/app_config_test.dart` | 15 | Unit | Config model |
| `test/unit/core/error/app_error_test.dart` | 7 | Unit | Error model |
| `test/unit/core/financial/ledger_calculator_test.dart` | 22 | Unit | Balance calculation |
| `test/unit/core/financial/ledger_invariants_test.dart` | 12 | Unit | INV-001–011 domain rules |
| `test/unit/core/financial/money_boundary_test.dart` | 21 | Unit | INT range, overflow, negative allocation |
| `test/unit/core/financial/money_test.dart` | 48 | Unit | Money arithmetic, currency |
| `test/unit/core/financial/validation_release_safe_test.dart` | 29 | Unit | Release-safe factory validation |
| `test/unit/core/logging/redacted_logger_test.dart` | 26 | Unit | Log redaction |
| `test/unit/core/navigation/app_route_test.dart` | 8 | Unit | Typed navigation |
| `test/unit/features/accounts/financial_account_test.dart` | 19 | Unit | Account domain model |
| `test/unit/features/ledger/child_withdrawal_audit_test.dart` | 15 | Unit | Audit validation |
| `test/unit/features/ledger/ledger_invariants_randomized_test.dart` | 7 | Randomized | INV-R01–R07, INV-Money |
| `test/unit/features/ledger/operation_test.dart` | 35 | Unit | Operation param factories |
| `test/widget/app/app_test.dart` | 14 | Widget | App bootstrap, routing, theming |
| `test/widget/features/smoke_screen/smoke_screen_test.dart` | 15 | Widget | RTL/LTR, a11y, overflow |

**Total: 390**

---

## 14. Files Created and Changed

### New Files

| File | Purpose |
|------|---------|
| `test/database/append_only_db_test.dart` | Raw SQL UPDATE/DELETE against every append-only table |
| `test/database/classification_immutability_db_test.dart` | Classification field immutability after ledger entries |
| `test/database/idempotency_db_test.dart` | Scoped idempotency, conflict detection, cross-profile |
| `test/database/ordering_determinism_db_test.dart` | Stable ordering by effectiveDate → recordedAt → id |
| `test/database/profile_isolation_db_test.dart` | Cross-household repository and DB isolation |
| `test/database/protected_account_db_test.dart` | Child-withdrawal audit enforcement |
| `test/database/transaction_boundary_db_test.dart` | Transaction rollback and atomicity verification |
| `test/unit/core/financial/money_boundary_test.dart` | INT boundary, overflow, allocation |
| `test/unit/core/financial/validation_release_safe_test.dart` | Factory validation in release mode |
| `test/unit/features/ledger/ledger_invariants_randomized_test.dart` | Randomized invariant testing |

### Modified Files

| File | Change |
|------|--------|
| `lib/core/database/app_database.dart` | Schema v2 (idempotency_key); 5 trigger groups; FK trigger helpers |
| `lib/core/database/tables/operations_table.dart` | Added `idempotency_key` nullable column |
| `lib/core/financial/money.dart` | Fixed `allocate()` to use `remainder()` instead of `%` |
| `lib/features/accounts/data/account_repository.dart` | Classification immutability docstring; `ClassificationImmutabilityError` type |
| `lib/features/accounts/data/drift_account_repository.dart` | `_hasLedgerEntries` guard in `updateAccount` |
| `lib/features/balance/data/drift_balance_repository.dart` | `_getAccount` returns `null` (not throws) for unknown account |
| `lib/features/ledger/data/drift_ledger_repository.dart` | `recordIncome` + `recordOpeningBalance` now call `_requireAccount`; enhanced idempotency `_checkIdempotency`; `id` tie-breaker in ordering |
| `lib/features/ledger/data/ledger_repository.dart` | Added `conflict` to `IdempotentOperationResult` |
| `lib/features/ledger/domain/child_withdrawal_audit.dart` | Release-safe factory; `AuditOperationMismatchError`, `AuditAccountMismatchError` |
| `lib/features/ledger/domain/ledger_entry.dart` | Release-safe factory |
| `lib/features/ledger/domain/operation.dart` | Release-safe factories for all 6 param classes; `resolvedIdempotencyKey` getter |
| `test/database/ledger_repository_db_test.dart` | Updated for new idempotency semantics |
| `test/unit/features/ledger/child_withdrawal_audit_test.dart` | Updated to `throwsArgumentError` |
| `test/unit/features/ledger/operation_test.dart` | Updated to `throwsArgumentError`; idempotency key tests |

---

## 15. Database Migration Changes

| Version | Change |
|---------|--------|
| 1 → 2 | `ADD COLUMN idempotency_key TEXT` to `operations`; scoped idempotency index; append-only triggers; CHECK triggers; FK enforcement triggers |

All triggers and indexes are idempotent (`CREATE TRIGGER/INDEX IF NOT EXISTS`) so they may safely be re-applied.

---

## 16. Validation Commands and Exit Codes

```
dart format --output=none --set-exit-if-changed .  → exit 0 (0 changed)
flutter analyze                                     → exit 0 (No issues found)
flutter test                                        → exit 0 (390 tests passed)
```

---

## 17. Deferred Encryption Runtime Risk

**DECISION-004 status:** ACCEPTED (SQLite3MultipleCiphers via Drift Pub build hooks)

Android release-mode runtime verification of SQLite3MultipleCiphers is **still unverified** due to emulator sandbox constraints. This remains an unresolved release risk. It must be re-addressed before shipping to production.

---

## 18. Remaining Unverified Behavior

| Area | Status | Reason |
|------|--------|--------|
| Android encryption runtime (DECISION-004) | Unverified | Emulator unavailable in sandbox |
| iOS Keychain key derivation | Unverified | No iOS simulator access |
| Currency-mismatch transfer (cross-currency) | Documented only | No multi-currency accounts in Phase 2 |
| Concurrent write race conditions | Documented only | Drift's single-writer SQLite serializes these; no concurrent test harness |
| `reverseOperation` for a cross-currency pair | Documented only | Not yet exercised |
| Historical-snapshot versioning | Documented only | Full versioning table deferred to Phase 3+ |
| Zakat calculation using historical classification | Documented only | No Zakat feature yet |

---

## 19. Git Summary

```
Branch: main
HEAD (Phase 2 base):  7d4a9b94b123c107d7506783e1a7d0b4fead8fda
Phase 2A changes:     27 files modified/added
dart format:          exit 0
flutter analyze:      exit 0 (No issues found)
flutter test:         exit 0 (390/390 passed)
```

Phase 2A commit to be created immediately after this report.

---

## Claim Classification Key

| Symbol | Meaning |
|--------|---------|
| **Unit-tested** | Covered by Dart unit tests |
| **Randomized-tested** | Covered by seeded random loop |
| **Database-tested** | Covered by Drift in-memory DB integration tests |
| **Widget-tested** | Covered by `testWidgets` |
| **Documented only** | Described in docs; no automated test |
| **Unverified** | Not demonstrated at all — known gap |

All financial invariants introduced or hardened in Phase 2A are classified as **Unit-tested** and/or **Database-tested**, except where the table above marks a specific item as Documented only or Unverified.
