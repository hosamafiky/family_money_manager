# Phase 5B.6 Report — Unified Atomic Goal-Transfer Boundary and Evidence Closure

**Date:** 2026-07-19  
**Schema version:** 13 → **14**  
**Working directory:** `/Users/hussam/Desktop/hussam/family_money_manager/`

---

## 1. Exact Commit History

| Phase | Commit | Note |
|---|---|---|
| 5B.4 | `3124346` | Evidence reconciliation and integrity closure (schema 12) |
| 5B.5 | `b53cef5` | Goal idempotency, reversal atomicity, evidence closure (schema 13) |
| 5B.6 | `5f92e2e` | Unified goal-transfer boundary + evidence closure (schema 14) |


Working tree at Phase 5B.6 start: **CLEAN** at `b53cef5`.

---

## 2. Unified Goal-Transfer Transaction

**Classification:** Database-tested

One internal write path — `_executeGoalAssociatedTransfer` / `_runGoalAssociatedTransferSteps` (plus `_runGoalReversalSteps` for reversal mode under the same fail-after / transaction envelope) — covers:

| Workflow | Entry |
|---|---|
| Initial goal funding | `createGoal` → `_runGoalAssociatedTransferSteps` (nested savepoint in same tx) |
| Later funding | `FundGoalUseCase` → `fundGoalTransfer` |
| Release | `ReleaseGoalFundsUseCase` → `releaseGoalTransfer` |
| Reversal of funding/release | `ReverseGoalTransferUseCase` → `reverseGoalTransfer` |

A **single** `db.transaction()` covers scoped idempotency, payload conflict decision, goal/account validation, in-tx balance calc, sufficient-funds check, operation insert, debit + credit legs, operation context, goal movement, and (for reversal) original mark + linkage.

Use cases are thin wrappers — **no** committed ledger transfer followed by a separate movement insert.

Files:

- `lib/features/goals/data/goal_transfer_write_boundary.dart`
- `lib/features/goals/data/drift_goal_repository.dart`
- `lib/features/goals/data/goal_repository.dart`
- `lib/features/goals/application/goal_use_cases.dart`

---

## 3. Funding and Release Rollback Matrix

**Classification:** Database-tested

Test-only `GoalTransferFailAfter` hooks (`debugFailAfter` on `DriftGoalRepository`) throw after each named step. Production default is `none`.

| Test | Fail-after | Retry |
|---|---|---|
| FUND-ROLL-1..6 | operationInsert → preCommit | Full rollback; same key retries to exactly one complete workflow |
| REL-ROLL-1..6 | operationInsert → preCommit | Full rollback; same key retries to exactly one complete workflow |

After every injected failure: no operation, no ledger entries, no context, no movement, balances unchanged, idempotency identity safely retryable.

---

## 4. Reversal Collision Handling (REV-ATOM-3 false-success fixed)

**Classification:** Database-tested  
**Bug corrected:** `lib/features/goals/data/drift_goal_repository.dart` (`_validateCompleteReversalReplay`)

Idempotent `AppOk` only when **all** are true:

- Existing op is type `reversal`
- It reverses the requested original (`reversed_by`)
- Household matches
- Normalised payload equivalent
- Original marked `is_reversed`
- Operation context exists
- When original had a goal movement: reversal movement exists and `reversal_of_movement_id` links correctly

Otherwise: `AppDuplicateConflict` or `AppPersistenceFailure` — **never** `AppOk` for incomplete/unrelated collisions.

| Test | Expected |
|---|---|
| REV-COL-1 Unrelated op ID | PersistenceFailure |
| REV-COL-2 Context/inject fail | PersistenceFailure |
| REV-COL-3 Equivalent retry | AppOk |
| REV-COL-4 Conflicting retry | AppDuplicateConflict |
| REV-COL-5 Partial malformed | PersistenceFailure |
| REV-COL-6 Original unreversed | PersistenceFailure |

`docs/PHASE_5B_5_REPORT.md` REV-ATOM-3 and remaining-risk rows updated.

---

## 5. Database-Balanced Movement Validation (schema v14)

**Classification:** Database-tested (not application-only)

Trigger `validate_goal_transfer_balanced_legs` BEFORE INSERT on `goal_movements` for `funding`/`release` requires:

- Exactly two ledger entries
- Exactly one debit and one credit
- Debit account = operation source; credit = destination
- Equal positive amounts matching operation total
- Entry currencies = operation currency
- Entry households = operation household

Evidence: BAL-MV-1..BAL-MV-11.

---

## 6. Multi-Connection Concurrency (MC-CONC-1..6)

**Classification (corrected Phase 5B.7):**

| Claim | Classification |
|---|---|
| Balance check + write in one transaction | Database-tested |
| Two-connection contention / SQLite locking | Database-tested |
| Deterministic both-at-boundary barrier | **Unverified** |

Two `AppDatabase.forFile` connections on one temp SQLite file; `Future.wait` launches overlapping requests. These prove serialization / busy-timeout behaviour under contention — **not** a controlled simultaneous-boundary race with a deterministic Completer barrier.

| Test | Scenario |
|---|---|
| MC-CONC-1 | Funding vs funding |
| MC-CONC-2 | Release vs release |
| MC-CONC-3 | Funding vs ordinary expense |
| MC-CONC-4 | Funding vs ordinary transfer |
| MC-CONC-5 | Equivalent duplicate |
| MC-CONC-6 | Conflicting duplicate |

**Observed SQLite behaviour:** WAL + `PRAGMA busy_timeout = 3000` on both connections; under contention writers serialize or surface busy/lock mapped to typed failures / catch blocks. Invariant: non-negative balances; at most one complete conflicting workflow; op/movement counts remain consistent (no incomplete workflows retained).

Do **not** claim controlled simultaneous-boundary concurrency without a deterministic barrier.

---

## 7. True Schema-12 → Latest Migration

**Classification:** Database-tested

- Fixture objects: `test/fixtures/schema_v12_objects.sql` extracted from Phase 5B.4 commit `3124346` onCreate
- Tables: Drift CREATE TABLE DDL (unchanged columns across v12→v14)
- Helper: `test/helpers/true_schema_v12.dart` — **never** opens current schema then deletes v13+ objects
- Test file **renamed**: `goal_true_migration_v12_to_v13_test.dart` → `goal_true_migration_v12_to_latest_test.dart` (MIG-TRUE-1 now asserts user_version **14** and v13+v14 objects)

---

## 8. Exact Test Reconciliation

### Phase 5B.5 equation (confirmed)

```
1171 (5B.4 HEAD 3124346)
+ 49 (phase_5b5_integrity_test.dart)
+  1 (goal_true_migration_v12_to_v13_test.dart)
+  1 (idempotency_db_test.dart — `conflicting payload → conflict`)
= 1222
```

Single idempotency addition at 5B.5: `conflicting payload → conflict` in `test/database/idempotency_db_test.dart` (sibling of `equivalent payload → alreadyExists (Phase 5B.5)`).

### Phase 5B.6 deltas

| Change | Count | Classification |
|---|---:|---|
| + `phase_5b6_integrity_test.dart` | FUND-ROLL×6, REL-ROLL×6, REV-COL×6, BAL-MV×11, helper smoke | Database-tested |
| + `phase_5b6_multi_connection_test.dart` | MC-CONC-1..6 | Database-tested |
| Renamed migration test (v12→latest) | 0 net (1 removed, 1 added) | Database-tested |
| Updated REV-ATOM-3 expectation in `phase_5b5_integrity_test.dart` | 0 | Database-tested |

Exact suite total after 5B.6 validation is recorded in §9.

---

## 9. Validation

```
dart format .                                              → exit 0
dart format --output=none --set-exit-if-changed .          → exit 0
flutter analyze                                            → No issues found (exit 0)
flutter test --reporter=expanded                           → exit 0, **1258/1258** passed
```

Suite equation:

```
1222 (5B.5 HEAD b53cef5)
+ 30 (phase_5b6_integrity_test.dart — FUND-ROLL×6, REL-ROLL×6, REV-COL×6, BAL-MV×11, helper)
+  6 (phase_5b6_multi_connection_test.dart — MC-CONC-1..6)
+  1 (goal_true_migration_v12_to_latest_test.dart)
−  1 (removed goal_true_migration_v12_to_v13_test.dart)
= 1258
```

---

## 10. Deferred SQLite3MultipleCiphers Runtime Risk

Unchanged: encryption-ready sqlite3mc binary via pub hooks; production key injection and Android runtime cipher verification remain **deferred**.  
**Classification:** Documented only / Unverified (runtime).

---

## 11. Remaining Risks

| Risk | Severity | Status |
|---|---|---|
| Production DB encryption not implemented | High | Deferred |
| Android SQLite3MultipleCiphers runtime unverified | High | Deferred |
| Dual-connection Completer barrier still unused | Medium | Documented; busy_timeout + Future.wait used; deterministic both-at-boundary **Unverified** |
| Mid-migration abort injection | Low | Not fail-injected |
| Goal lifecycle event insert after completeGoal was best-effort | Low | **Corrected in Phase 5B.7** — completion/archive/restore are atomic |

---

## 12. Claim Classification Legend

| Label | Meaning |
|---|---|
| Documented only | Spec / report only |
| Unit-tested | Pure Dart tests |
| Database-tested | Against SQLite/Drift |
| Fake-tested | Fake repositories |
| Widget-tested | Flutter widget tests |
| Unverified | Not proven |

---

## 13. Final Clean Status

```
Branch: main
Schema: 14
Tests: 1258/1258 passed
HEAD: `5f92e2eabb295963016c097b92c7f1bbd24236f5`
Working tree: CLEAN
```
