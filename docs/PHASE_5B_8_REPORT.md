# Phase 5B.8 Report — Remove Persisted Target-Reached; Ledger-Derived Progress Only

**Date:** 2026-07-20  
**Feature commit:** `04ef81fd450c1b5ada8b6d3da7efca4735a0efc3`  
**Base HEAD before work:** `45b89c22565634962b3177a37b1d2d008303412b`  
**Phase 5B.7 feature commit:** `1aaadca8af4970a2a679a3b8396167f356e8dfde`  
**Working tree before work:** CLEAN

---

## 1. Exact repository state (pre-work)

```
pwd: /Users/hussam/Desktop/hussam/family_money_manager
branch: main
HEAD: 45b89c22565634962b3177a37b1d2d008303412b
status: clean
recent:
  45b89c2 docs: pin Phase 5B.7 feature commit hash in report
  1aaadca feat: Phase 5B.7 – atomic goal lifecycle and reversal structural validation
```

Confirmed Phase 5B.7 feature at `1aaadca`; docs pin `45b89c2` after it. No unreported changes.

---

## 2. Lifecycle / progress separation

**Classification:** Unit-tested | Database-tested | Widget-tested

| Concern | Values | Persistence |
|---|---|---|
| Lifecycle (`GoalStatus`) | `active`, `completed`, `archived` | Persisted on `goals.status` |
| Progress (`GoalProgressState`) | `notStarted`, `inProgress`, `targetReached`, `overfunded` | **Never persisted** — derived via `GoalProgressState.fromBalance(balance, target)` |

Removed:
- `GoalStatus.targetReached` enum value
- FundGoal post-funding `updateGoalStatus(targetReached)` write
- Repository allowance of non-lifecycle status writes (`updateGoalStatus` always rejects)
- UI treating “target reached” as a lifecycle badge

`GoalProgress.isTargetReached` remains a **derived** getter on the progress snapshot (balance ≥ target), not a DB column.

---

## 3. Schema migration (v15 → v16)

**Classification:** Database-tested

`AppDatabase.schemaVersion` = **16**.

Migration `_applyPhase5B8LifecycleProgressSeparation`:

1. DROP status-transition + lifecycle CHECK triggers (legacy transition set forbade `targetReached→active`)
2. `UPDATE goals SET status = 'active' WHERE status = 'targetReached'`
3. Recreate transition triggers **without** `targetReached`
4. CREATE `check_goal_lifecycle_status` / `check_goal_lifecycle_status_update` — only `active` / `completed` / `archived`

Preserved on migrate: goal IDs, reserves, revisions, movements, lifecycle events, completion/archive rows, all ledger data.  
No completion lifecycle event is inserted solely because status was `targetReached`.

Direct SQL INSERT/UPDATE of `targetReached` fails (**MIG-5B8-2/3**).

---

## 4. Derived progress behavior

**Classification:** Database-tested | Unit-tested

Sole derivation path: `GoalProgressState.fromBalance` used by `GetGoalProgressUseCase`.

| Scenario | Progress | `goals.status` after money op |
|---|---|---|
| Zero funding | notStarted | unchanged (active) |
| Partial | inProgress | unchanged |
| Exact target | targetReached | unchanged |
| Overfund | overfunded | unchanged |
| Release below target | inProgress | unchanged |
| Full release | notStarted | unchanged |
| Funding reversal | decreases | unchanged |
| Release reversal | increases | unchanged |
| Target increase after exact | may → inProgress | unchanged |
| Target decrease | may → overfunded/targetReached | unchanged |
| Archive / restore | derived independently | lifecycle only |
| Completed + release | progress can leave targetReached | stays `completed` |

Evidence: **PROG-1..PROG-15**.

---

## 5. Completion validation

**Classification:** Database-tested

Normal completion requires **derived** `reserve balance >= current target revision`, not a persisted progress status.

| Test | Result |
|---|---|
| COMP-DERIV-1 Exact target | permits |
| COMP-DERIV-2 Overfunded | permits |
| COMP-DERIV-3 Below target | rejects |
| COMP-DERIV-4 Release below then complete | rejects |
| COMP-DERIV-5 Funding reversal then complete | rejects |
| COMP-DERIV-6 Early completion | confirmation + reason policy |

Completion remains one atomic goal-row + lifecycle-event transaction (Phase 5B.7).

---

## 6. UI changes

**Classification:** Widget-tested

- Lifecycle badges: Active / Completed / Archived only
- Progress badges: Not started / In progress / Target reached / Overfunded (text + icon)
- Completed goals may still show derived funding level
- Release from completed does not rewrite lifecycle status
- Progress never communicated by color alone

Evidence: **UI-PROG-1..UI-PROG-6** (EN + AR).

l10n: existing `goalProgress*` keys used; `goalStatusTargetReached` retained unused for now (not shown as lifecycle).

---

## 7. Provider invalidation

**Classification:** Documented only (code-reviewed; no dedicated provider-invalidation widget test)

Helpers in `goal_providers.dart`:

- `invalidateGoalMoneyProviders` — fund / release / create-with-funding: progress, detail, list, accounts, balances, dashboard, account-flow report, transaction list
- `invalidateGoalLifecycleProviders` — complete / archive / restore: progress, detail, list

Does **not** rely on lifecycle status mutation to trigger refresh.

---

## 8. Exact test reconciliation

Starting total: **1289**

| Change | Count |
|---|---|
| **Added** PROG-1..15 | +15 |
| **Added** COMP-DERIV-1..6 | +6 |
| **Added** MIG-5B8-1..4 | +4 |
| **Added** UNIT-5B8-1 | +1 |
| **Added** UI-PROG-1..6 | +6 |
| **Added** domain `13b` (`fromBalance`) | +1 |
| **Removed** | 0 |
| **Renamed / updated in place** | enum test 13; MIG-TRUE-1 expects v16; LIFE pre-status; LP-1 asserts status stays active |

**Equation:** `1289 + 33 - 0 = 1322`

Final: **1322** passed, **0** failed, **0** skipped.

---

## 9. Exact validation

| Step | Exit code |
|---|---|
| `dart format .` | 0 |
| `dart format --output=none --set-exit-if-changed .` | 0 |
| `flutter analyze` | 0 (No issues found) |
| `flutter test --reporter=expanded` | 0 — **1322** All tests passed |

---

## 10. Corrections to earlier Phase 5B reports

| Doc | Correction |
|---|---|
| PHASE_5B_7_REPORT | `targetReached` is **not** a persisted lifecycle status as of 5B.8; FundGoal no longer writes it; remaining-risk row closed |
| PHASE_5B_REPORT | Status column values are `active`/`completed`/`archived`; fund eligibility is `active` only |
| PHASE_5B_1_REPORT | Clarify `targetReached` wording refers to **derived** progress (was ambiguous with persisted status) |

---

## 11. Deferred SQLite3MultipleCiphers runtime risk

**Classification:** Documented only / Unverified (runtime)

Production encryption via SQLite3MultipleCiphers / Keystore-Keychain key injection remains deferred (same as prior phases). Schema/repository design does not require plaintext fallback.

---

## 12. Remaining risks

| Risk | Severity | Status |
|---|---|---|
| Production DB encryption not implemented | High | Deferred |
| Android SQLite3MultipleCiphers runtime unverified | High | Deferred |
| Provider invalidation not covered by dedicated widget tests | Low | Documented; covered by code path review |
| Unused `goalStatusTargetReached` l10n key | Low | Harmless; may remove in cleanup |

---

## 13. Claim classification legend

| Label | Meaning |
|---|---|
| Documented only | Spec / report only |
| Unit-tested | Pure Dart tests |
| Database-tested | Against SQLite/Drift |
| Fake-tested | Fake repositories |
| Widget-tested | Flutter widget tests |
| Unverified | Not proven |

---

## 14. Final clean status

Feature commit (primary):

`04ef81fd450c1b5ada8b6d3da7efca4735a0efc3` — `feat: Phase 5B.8 – remove persisted target-reached; ledger-derived progress only`

Docs pin commit follows on `main` immediately after the feature commit.

Post-feature-commit validation: clean working tree; schema **16**; tests **1322**.
