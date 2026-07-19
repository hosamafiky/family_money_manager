# Phase 5B.5 Report — Goal Idempotency, Reversal Atomicity, and Evidence Closure

**Date:** 2026-07-19  
**Schema version:** 12 → **13**  
**Working directory:** `/Users/hussam/Desktop/hussam/family_money_manager/`

---

## 1. Exact Commit History

| Phase | Commit | Note |
|---|---|---|
| 5B.2 | `2dab3e2` | Goal ledger integrity and lifecycle hardening |
| 5B.3 | `b68c710` | Concurrency, audit, lifecycle, evidence |
| 5B.4 | `3124346` | Evidence reconciliation and integrity closure |
| 5B.5 | *(this commit)* | Idempotency fix, atomic reversal, evidence closure |

Working tree at Phase 5B.5 start: **CLEAN** at `3124346`.

---

## 2. Exact Test Reconciliation (5B.3 → 5B.4 → 5B.5)

### Suite totals (grep `^\s*(test\|testWidgets)\(`)

| Commit | Suite total |
|---|---|
| 5B.3 (`b68c710`) | **1129** |
| 5B.4 (`3124346`) | **1171** |
| 5B.5 (after this phase) | **1222** (= 1171 + 51 − 0) |

### Goal-file counts

| File | Count at 5B.3 | Count at 5B.4 | Current (5B.5) | Added (5B.4→5B.5) |
|---|---:|---:|---:|---:|
| `goal_repository_test.dart` | 93 | 112 | 112 | 0 (CONC-9 renamed/updated) |
| `goal_schema_migration_test.dart` | 57 | 68 | 68 | 0 |
| `goal_migration_v10_to_v11_test.dart` | 6 | 12 | 12 | 0 |
| `goal_money_formatter_test.dart` | 12 | 18 | 18 | 0 |
| `phase_5b5_integrity_test.dart` | — | — | **49** | +49 |
| `goal_true_migration_v12_to_v13_test.dart` | — | — | **1** | +1 |
| Other goal files (domain/widget) | 47 | 47 | 47 | 0 |

### Why Phase 5B.4 incorrectly called 1171 the “Phase 5B.3 HEAD”

Phase 5B.4 Section 2 claimed:

> “The actual final count at the Phase 5B.3 HEAD is 1171”

That is **false**. At commit `b68c710` (Phase 5B.3 HEAD) the suite is **1129**. The count **1171** is the Phase **5B.4** HEAD (`3124346`). The discrepancy was Phase 5B.4 work counted against 5B.3.

### Why file-level deltas (42) vs named inventory may look like “72”

5B.3 → 5B.4 goal-file delta = **42**, which exactly equals suite delta (1129 → 1171). There is **no** 72-test gap in named inventories when counts are taken per commit with `grep -cE '^\s*(test|testWidgets)\('`. Prior report wording that implied a 72↔42 mismatch mixed:

- line-oriented `grep` of sed-broken names (many tests render as `test(` placeholders),
- versus real suite totals.

**Correction:** file-level additions in 5B.4 **do** equal the suite delta (+42). Named-inventory sed extraction undercounts when titles span lines.

### Phase 5B.5 equation

```
1171 (5B.4 HEAD)
+ 49 (phase_5b5_integrity_test.dart)
+  1 (goal_true_migration_v12_to_v13_test.dart)
+  1 (idempotency_db_test.dart — conflicting-payload case)
±  0 net renames in persistence suites (updated expectations)
= 1222
```

Note: income/expense/transfer persistence suites renamed assertions for
payload-aware idempotency (equivalent → `alreadyExists`; amount mismatch →
`conflict`) without changing their test counts.
---

## 3. Correct Idempotency Semantics (conflict → AppDuplicateConflict)

**Bug corrected (Phase 5B.4 documented as known, left unfixed):**

`FundGoalUseCase` / `ReleaseGoalFundsUseCase` treated `IdempotentOperationResult.conflict` like a no-op and returned `AppOk(goal)`.

**Fix:**

| Layer | Behaviour |
|---|---|
| `DriftLedgerRepository._checkIdempotency` | Same scoped key + equivalent normalised payload → `alreadyExists`; conflicting payload → `conflict` |
| `FundGoalUseCase` / `ReleaseGoalFundsUseCase` | `conflict` → `AppDuplicateConflict` (not `AppOk`) |
| Goal create / lifecycle | Already returned `AppDuplicateConflict`; lifecycle now household-scoped + payload fingerprint |

Evidence: IDMP-1..IDMP-10 (Unit/Database-tested), CONC-9 updated, CONC-BAR-5/6.

**Classification:** Database-tested + Unit-tested (application mapping).

---

## 4. Atomic Reversal Transaction + Failure Matrix

`GoalRepository.reverseGoalTransfer` (implemented in `DriftGoalRepository`) runs **one** `_db.transaction()` covering:

1. Reversal idempotency lookup  
2. Validation of original operation  
3. Validation of original goal movement (when present)  
4. Reversal operation insertion  
5. Mirror ledger entries (debit/credit swapped)  
6. Mark original `is_reversed`  
7. Operation context  
8. Reversal goal movement + `reversal_of_movement_id`

`ReverseGoalTransferUseCase` is now a thin delegate (no multi-tx gap).

| Test | Injection point | Outcome |
|---|---|---|
| REV-ATOM-1 | First mirror entry PK occupied | `AppPersistenceFailure`; zero partial rows |
| REV-ATOM-2 | Second-order entry PK | Full rollback |
| REV-ATOM-3 | Pre-occupied reversal op id + context | Early `AppOk`; original unreversed |
| REV-ATOM-4 | Last mirror entry PK | Full rollback |
| REV-ATOM-5 | Reversal movement PK; then clean retry | Rollback then success; conflicting second reverse → `AppDuplicateConflict` |

**Classification:** Database-tested.

---

## 5. Reversal Database Constraints (schema v13)

Added in `_applyPhase5B5ReversalAndLifecycleHardening()`:

- Trigger `validate_reversal_movement_link`
- Unique index `idx_goal_movements_one_reversal_per_original`

Evidence: REV-DB-1..REV-DB-6 (Database-tested).

---

## 6. Honest Ledger-Linkage Classifications

| Condition | Classification | Mechanism |
|---|---|---|
| Exactly one source debit | Architecture-only | `executeTransfer` inserts one debit |
| Exactly one destination credit | Architecture-only | Single credit insert |
| Equal amounts | Architecture-only | Single `amountMinorUnits` param |
| Same currency | Architecture-only | Pre-tx `CurrencyMismatchTransferError` |
| No additional legs | Architecture-only | Finalization = transaction commit/rollback |
| Accounts match op source/dest (goals) | Database-tested | `validate_funding/release_movement` |
| Household consistency | Database-tested | `*_household` triggers |
| Goal direction consistency | Database-tested | funding vs release triggers |

Evidence: LEDG-HONEST-1..8. Incomplete ops cannot commit: all legs share one Drift transaction.

---

## 7. Lifecycle Household Isolation

| Constraint | Status |
|---|---|
| Event goal FK | Existing Drift `.references` |
| Event household = goal household | Trigger `goal_lifecycle_household_matches_goal` (v13) |
| Actor member same household | **N/A** — no `actor_member_id` column (only free-form `actor_metadata`) |
| Household-scoped idempotency | Index `idx_goal_lifecycle_hh_idem` |
| Payload fingerprint conflicts | Application fingerprint in `insertLifecycleEvent` |
| UPDATE/DELETE prohibited | Existing triggers |
| Completed→active blocked | `goal_status_valid_transition` |
| Restore dedicated + audit | `RestoreGoalUseCase` inserts `restored` lifecycle event |

Evidence: GLC-X-1..GLC-X-6 (Database-tested).

---

## 8. Controlled Concurrency Evidence

Test-only hook: `DriftLedgerRepository(..., debugTransactionBarrier:)` — optional constructor param, **not** on the public `LedgerRepository` interface, never wired in production DI.

**Honest limit:** single-connection Drift/SQLite serializes writers; a Completer “both entered before commit” barrier would deadlock. CONC-BAR-1..6 use a best-effort `Duration.zero` yield inside the transaction after idempotency check.

Evidence: CONC-BAR-1..6 (Database-tested; barrier strategy documented).

---

## 9. Shared Formatter Integration

`GoalMoneyFormatter` is a thin wrapper over `MoneyInputFormatter.format(Money(...))` with the goal-reserve negative display policy (`—`). No `.toDouble()`, no `/ 100.0`.

Evidence: SHARED-FMT-1..8 + existing FMT-1..18.

**Classification:** Unit-tested / Widget-tested.

---

## 10. True (N−1)→N Migration Evidence

Schema **N = 13**. Test `MIG-TRUE-1` in
`test/database/goals/goal_true_migration_v12_to_v13_test.dart`:

1. Physical temp file opened via `AppDatabase`  
2. v13-only objects stripped; `PRAGMA user_version = 12`  
3. Fixtures inserted (household, member, accounts, goal, revision, funding op, ledger legs, context, movement, budget)  
4. Close / reopen → `onUpgrade` 12→13  
5. Assert version 13, IDs preserved, v13 triggers/indexes present, linkage enforcement active, progress reconciles  

**Not** fresh-onCreate evidence. Mid-migration abort rollback remains architecture-dependent (Drift/SQLite); documented, not injected.

Prior `goal_migration_v10_to_v11_test.dart` remains a fresh-schema smoke suite; naming is historical (also covers later objects via current `AppDatabase`).

**Classification:** Database-tested.

---

## 11. Correct Encryption Decision

Selected design (unchanged):

- Drift `NativeDatabase`
- `sqlite3` with **SQLite3MultipleCiphers** via pub build hooks (`hooks.user_defines.sqlite3.source: sqlite3mc`)
- Platform-backed secure key storage deferred to a later security phase
- **No** production encryption or key management implemented
- Android runtime cipher verification remains deferred

`sqflite_sqlcipher` is **not** the selected implementation.

Corrections applied to `docs/PHASE_5B_4_REPORT.md` Section 13 (removed `sqflite_sqlcipher` implication). `docs/DECISION_004_ASSESSMENT.md` Section 8 already correct as of 5B.3.

---

## 12. Exact Validation

```
dart format .
dart format --output=none --set-exit-if-changed .   → exit 0
flutter analyze                                       → No issues found
flutter test --reporter=expanded                        → exit 0, 1222/1222 passed
```

(See commit message / CI log for exact terminal timestamps.)

---

## 13. Remaining Risks

| Risk | Severity | Status |
|---|---|---|
| Production DB encryption not implemented | High | Deferred by design |
| Android SQLite3MultipleCiphers runtime unverified | High | Deferred |
| Dual-connection Completer concurrency barrier not used | Medium | Documented; yield barrier only |
| Actor-member FK on lifecycle events | Low | No column; metadata only |
| Mid-migration abort injection | Low | Drift transactional migrate; not fail-injected |
| Goal funding still two steps (ledger tx + movement) outside createGoal | Medium | Conflict/alreadyExists fixed; fully single-tx fund+movement is future hardening |

---

## 14. Final Clean Status

```
Branch: main
Schema: 13
Tests: 1222/1222 passed
Working tree: CLEAN after commit
```

### Claim Classification Legend

| Label | Meaning |
|---|---|
| Documented only | Spec / report only |
| Unit-tested | Pure Dart tests |
| Database-tested | Against SQLite/Drift |
| Fake-tested | Fake repositories |
| Widget-tested | Flutter widget tests |
| Unverified | Not proven |
