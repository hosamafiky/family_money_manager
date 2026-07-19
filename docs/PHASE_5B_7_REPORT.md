# Phase 5B.7 Report — Atomic Goal Lifecycle and Reversal Structural Validation

**Date:** 2026-07-19  
**Schema version:** 14 → **15**  
**Working directory:** `/Users/hussam/Desktop/hussam/family_money_manager/`

---

## 1. Exact Commit History

| Phase | Commit | Note |
|---|---|---|
| 5B.5 | `b53cef5` | Goal idempotency, reversal atomicity, evidence closure (schema 13) |
| 5B.6 | `5f92e2e` | Unified goal-transfer boundary + evidence closure (schema 14) |
| 5B.7 | `1de1083` | Atomic goal lifecycle + reversal balanced validation (schema 15) |

Working tree at Phase 5B.7 start: **CLEAN** at `5f92e2eabb295963016c097b92c7f1bbd24236f5`.

---

## 2. Atomic Completion Boundary

**Classification:** Database-tested  
**Bug corrected:** best-effort lifecycle insert after `completeGoal`  
**Files:** `lib/features/goals/data/drift_goal_repository.dart`, `lib/features/goals/application/goal_use_cases.dart`, `lib/features/goals/data/goal_repository.dart`

One repository `db.transaction()` covers:

1. Completion idempotency lookup  
2. Payload-equivalence or conflict decision  
3. Goal lookup  
4. Household validation  
5. Current lifecycle validation  
6. Reserve-balance calculation  
7. Target-reached validation (normal) / early confirmation+reason (early)  
8. Goal status update  
9. Completion timestamp update  
10. Immutable lifecycle-event insertion  
11. Final pre-commit boundary  

On any failure: neither goal status nor lifecycle event remains changed.  
`CompleteGoalUseCase` is a thin wrapper — **no** post-commit best-effort event insert.

---

## 3. Completion Rollback Matrix

**Classification:** Database-tested

Test-only `GoalLifecycleFailAfter` (`debugLifecycleFailAfter` on `DriftGoalRepository`).

| Test | Fail-after |
|---|---|
| COMP-ROLL-1 | afterGoalValidation |
| COMP-ROLL-2 | afterBalanceCalculation |
| COMP-ROLL-3 | afterGoalStatusUpdate |
| COMP-ROLL-4 | afterCompletionTimestampUpdate |
| COMP-ROLL-5 | afterLifecycleEventInsertion |
| COMP-ROLL-6 | preCommit |

After every injected failure: status remains non-completed (`active`/`targetReached`), `completed_at` null, no completed lifecycle event, no extra ledger ops/entries/movements, identity safely retryable → retry yields exactly one completed goal + one lifecycle event.

---

## 4. Completion Idempotency

**Classification:** Database-tested

Household-scoped key `complete-${idempotencyKey}` with normalised payload:

- Goal ID, Household ID, Completion type, Early-completion confirmation, Normalised early-completion reason, Actor metadata where present

| Test | Expected |
|---|---|
| COMP-IDMP-1 | Same key + equivalent → original result |
| COMP-IDMP-2 | Same key + conflicting → `AppDuplicateConflict` |
| COMP-IDMP-3 | Same key, other household → isolated |
| COMP-IDMP-4 | Already-completed + exact → idempotent |
| COMP-IDMP-5 | Already-completed + different type → conflict |
| COMP-IDMP-6 | Already-completed + different reason → conflict |

---

## 5. Lifecycle Workflow Restrictions

**Classification:** Database-tested

Material transitions go **only** through typed workflows:

| Transition | Workflow |
|---|---|
| active/targetReached → completed | `CompleteGoalUseCase` → `completeGoal` |
| active/targetReached/completed → archived | `ArchiveGoalUseCase` → `archiveGoal` |
| archived → active | `RestoreGoalUseCase` → `restoreGoal` |
| completed → active | **FORBIDDEN** |
| archived → completed | **FORBIDDEN** |

`updateGoalStatus` rejects `completed` / `archived` / `active` (messageKey `errorGoalLifecycleRequiresTypedWorkflow`). Only `targetReached` remains for FundGoal progress persistence.

DB: `reject_unsupported_goal_status_transition` (plus existing `goal_status_valid_transition`).

Archive and restore insert immutable lifecycle events in the **same** transaction (LIFE-7/8 fail-injection proves rollback).

| Test | Focus |
|---|---|
| LIFE-1..4 | Repository bypass rejected |
| LIFE-5..6 | Raw SQL forbidden transitions rejected |
| LIFE-7..8 | Atomic archive / restore |

---

## 6. Reversal Balanced-Ledger Enforcement (schema v15)

**Classification:** Database-tested

Trigger `validate_goal_reversal_balanced_legs` BEFORE INSERT on `goal_movements` when `movement_type = 'reversal'` requires:

- Operation type `reversal`
- Exactly two mirror ledger entries (one debit, one credit)
- Equal positive amounts matching operation / original totals
- Currencies and households match
- Entry accounts inverse of original transfer accounts
- Reversal op linked via `reversed_by` on original
- Movement references original via `reversal_of_movement_id`
- Same goal and household
- At most one reversal per original (unique index + trigger)

Evidence: REV-BAL-1..10 + REV-BAL-11 positive control.

---

## 7. Concurrency Classification Correction

**Classification:** Documented only (doc update)

Updated `docs/PHASE_5B_6_REPORT.md`:

- Balance check + write in one transaction → **Database-tested**
- Two-connection contention / SQLite locking → **Database-tested**
- Deterministic both-at-boundary barrier → **Unverified**

Existing MC-CONC-1..6 retained; no false claim of controlled simultaneous-boundary concurrency.

---

## 8. Exact Test Reconciliation

Verified Phase 5B.6 total: **1258**

### Phase 5B.7 additions (`test/database/goals/phase_5b7_integrity_test.dart`)

| Name | Classification |
|---|---|
| COMP-IDMP-1..6 | Database-tested |
| COMP-ROLL-1..6 | Database-tested |
| LIFE-1..8 | Database-tested |
| REV-BAL-1..11 (10 + positive control) | Database-tested |

| Change | Count |
|---|---:|
| Added | **+31** |
| Removed | **0** |
| Renamed / moved | **0** (MIG-TRUE-1 assertion updated in place: 14→15) |

```
1258 + 31 - 0 = 1289
```

---

## 9. Exact Validation

```
dart format .                                              → exit 0
dart format --output=none --set-exit-if-changed .          → exit 0
flutter analyze                                            → No issues found (exit 0)
flutter test --reporter=expanded                           → exit 0, **1289/1289** passed
```

Suite equation:

```
1258 (5B.6 HEAD 5f92e2e)
+ 31 (phase_5b7_integrity_test.dart — COMP-IDMP×6, COMP-ROLL×6, LIFE×8, REV-BAL×11)
= 1289
```

Files changed during `dart format .` validation pass: `drift_goal_repository.dart`, `phase_5b7_integrity_test.dart` (already included in commit).

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
| Deterministic dual-connection Completer barrier | Medium | Unverified |
| Mid-migration abort injection | Low | Not fail-injected |
| `targetReached` persists as status (may be derived later) | Low | Documented earlier |

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
Schema: 15
Tests: 1289/1289 passed
HEAD: `1de108390a379f5e56b7da8b88c105188cacf169`
Working tree: CLEAN
```
