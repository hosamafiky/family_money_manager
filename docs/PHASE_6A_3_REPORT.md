# Phase 6A.3 Report — Deterministic Typed Outcomes after SQLite Contention

**Branch:** `main`  
**Feature commit:** `ef733acce8b939245581f63820e0b46e4ccf8a68`  
**Analyzer-clean follow-up:** `8daca6a624a2d2a35ea14670d70915f267b007c3`  
**Prior HEAD:** `de9eacd376b0de262bca757abcdb40353659c134` (Phase 6A.2 docs pin)  
**Phase 6A feature:** `25347f4`  
**Phase 6A.1 feature:** `35602d9` · docs `4264b3f` · finalize `d032977`  
**Phase 6A.2 feature:** `d12887718024a2d87d05c63b9c7041136d0542c5` · docs pin `de9eacd`  
**Schema:** **18** (unchanged)  
**Tests:** **1507 → 1525** (`1507 + 18 − 0 = 1525`)

---

## 1. Exact repository evidence (pre-commit)

| Item | Value |
|------|-------|
| `pwd` | `/Users/hussam/Desktop/hussam/family_money_manager` |
| Branch | `main` |
| HEAD before 6A.3 | `de9eacd376b0de262bca757abcdb40353659c134` |
| Working tree | Clean at start |
| Baseline tests | **1507** |
| Schema | **18** |

---

## 2. Shared bounded SQLite contention policy

**File:** `lib/core/database/sqlite_contention_policy.dart`

| Setting | Value |
|---------|-------|
| Retryable codes | `SQLITE_BUSY` (5), `SQLITE_LOCKED` (6) |
| Max attempts | **10** (default) |
| Backoff | 25ms × attempt, capped at 200ms |
| Optional deadline | Supported |
| Exhaustion | `SqliteContentionExhausted` (never raw SQLite to callers) |

**Contract:** each retry opens a **new** writer transaction; balances and scoped idempotency are re-read **inside** the lock. Does **not** retry: validation, `AppDuplicateConflict`, FK/UNIQUE constraint (19), negative-balance trigger abort, injected failures, insufficient-funds domain errors.

**Wired into:** certificate create / profit / redeem / purchase-reversal / profit-reversal; ledger expense & transfer; goal funding/release associated transfer.

**Classification:** Unit-tested (POL-1..8) + Database-tested (XDEB / CIDMP / MC-CERT).

---

## 3. Typed outcomes after debit contention

Two Drift connections → one physical SQLite file. After contention handling:

| Test | Scenario | Exact outcomes |
|------|----------|----------------|
| XDEB-1 | Cert vs cert | 1 `AppOk` + 1 `AppInsufficientFunds`; bal=20000; one cert/op/events |
| XDEB-2 | Cert vs expense | 1 success + 1 insufficient; no persistence |
| XDEB-3 | Cert vs transfer | same |
| XDEB-4 | Cert vs goal funding | same |
| XDEB-5 | Expense vs transfer | same |
| XDEB-6 | Goal funding vs transfer | same; source bal=20000 |
| MC-CERT-3..5 | Insufficient races | exact typed counts; no `AppPersistenceFailure` |

**Classification:** Database-tested.

**Test fixture fix:** expense races now stub `listMembers` with member `u1` so expense reaches the ledger (prior noop returned `AppNotFound` and masked debit contention).

---

## 4–7. Deterministic idempotency

| Area | Behaviour |
|------|-----------|
| Create equiv concurrent | Both `AppOk`, same cert id, one workflow (CIDMP-1 / MC-CERT-1) |
| Create conflict concurrent | One `AppOk` + one `AppDuplicateConflict` (CIDMP-2) |
| Create seq equiv/conflict | CIDMP-10 / CIDMP-11 |
| Profit equiv/conflict concurrent | CIDMP-5 / CIDMP-6; no persistence |
| Profit failure+retry | CIDMP-14 |
| Redeem equiv concurrent | **Both `AppOk`** (CIDMP-7 residual closed) |
| Redeem conflict concurrent | One ok + conflict (CIDMP-12) |
| Purchase reverse concurrent equiv | Both `AppOk` or ok+conflict; one reversal op (CIDMP-8 / CIDMP-13) |
| Profit reverse concurrent | CIDMP-9 / CIDMP-15; redemption reverse still unsupported |

**Classification:** Database-tested.

---

## 8. Debit DB enforcement retained

| Mechanism | Status |
|-----------|--------|
| `prevent_negative_account_balance` | Retained; DET-DEB-1 raw SQL overdraft rejected |
| In-tx sufficient-funds calc | Retained; DET-DEB-3 |
| Certificate event structural triggers | Retained (BAL-EVT suite) |
| Goal reserve / certificate account restrictions | Retained |
| Transfer balancing | Retained |
| Failed debit → no committed op/context/event | DET-DEB-2 |

**Classification:** Database-tested.

---

## 9. Migration restart safety (schema 16→18)

**Documented mechanism:** **Idempotent migration statements** (`CREATE … IF NOT EXISTS`, `DROP TRIGGER IF EXISTS` + recreate). Drift does **not** wrap `onUpgrade` in one SQLite transaction that rolls back all DDL; `user_version` is bumped only after a successful upgrade pass.

**Do not claim rollback** — MIG-6A3-1 proves fail-inject stuck state → reopen recovers:

- Immediate post-failure: `user_version=16`, partial table present, triggers missing, financial rows intact  
- Reopen → `user_version=18`  
- Every schema-17 and schema-18 object exists **exactly once**  
- `prevent_negative_account_balance` operates after recovery  

**Classification:** Database-tested (MIG-6A3-1). Documented only for “not a single rollback transaction.”

---

## 10. Test reconciliation

| File | Tests | Classification | Notes |
|------|-------|----------------|-------|
| `sqlite_contention_policy_test.dart` | POL-1..8 (8) | Unit-tested | **added** |
| `phase_6a3_debit_enforcement_test.dart` | DET-DEB-1..3 (3) | Database-tested | **added** |
| `phase_6a3_migration_restart_test.dart` | MIG-6A3-1 (1) | Database-tested | **added** |
| `phase_6a3_idempotency_test.dart` | CIDMP-10..15 (6) | Database-tested | **added** |
| `phase_6a2_cross_debit_race_test.dart` | XDEB-1..6 | Database-tested | strengthened exact typed counts |
| `phase_6a2_concurrent_idempotency_test.dart` | CIDMP-1..9 | Database-tested | CIDMP-7 both AppOk |
| `phase_6a1_multi_connection_test.dart` | MC-CERT-1..5 | Database-tested | exact insufficient; no persistence |

**Equation:** `1507 + 18 − 0 = 1525`

---

## 11. Validation

```text
dart format --output=none --set-exit-if-changed .   # exit 0
flutter analyze                                       # No issues found!
flutter test --reporter=expanded                      # 1525 passed; 0 failed
```

Validated against committed feature `ef733acce8b939245581f63820e0b46e4ccf8a68` and analyzer-clean follow-up `8daca6a624a2d2a35ea14670d70915f267b007c3`.

---

## 12. Claim classifications

| Claim | Classification |
|-------|----------------|
| Shared contention policy (BUSY/LOCKED, bounded retry) | Unit-tested + Database-tested |
| Debit race losers → `AppInsufficientFunds` not persistence | Database-tested |
| Equivalent concurrent create/profit/redeem → both `AppOk` | Database-tested |
| Conflicting concurrent → `AppOk` + `AppDuplicateConflict` | Database-tested |
| Raw overdraft trigger reject | Database-tested |
| Failed debit txn leaves no committed workflow | Database-tested |
| Migration restart = idempotent statements (not rollback) | Database-tested + Documented only |
| Emulator / App Bundle / encrypted DB | Unverified |
| Phase 6B.1 | Documented only (not started) |

---

## 13. Gaps / residual risks

1. Goal funding still persists operation `type='transfer'` (pre-existing); XDEB-6 excludes goal-linked ops when counting ordinary transfers.
2. Device / App Bundle / emulator builds not run (hard constraint).
3. Phase 6B.1 not begun.
4. Contention exhaustion still maps to `AppPersistenceFailure` only when the DB is truly unhealthy / deadline exceeded — not acceptable as a healthy-race outcome (covered by retries in tests).

---

## 14. Scope scan

No architecture refactoring, UI redesign, gold, investments, liabilities, net worth, Zakat, sync, security, backup, notifications, voice, AI, or exports. No Android/iOS/App Bundle/emulator builds. `money_tracker_next` / `money_tracker` untouched. Phase 6B.1 not begun.

---

## 15. Files changed (summary)

**Lib:** `sqlite_contention_policy.dart` (new); `drift_certificate_repository.dart`; `drift_ledger_repository.dart`; `drift_goal_repository.dart`  
**Tests:** POL / DET-DEB / MIG-6A3 / CIDMP-10..15; XDEB / CIDMP / MC-CERT strengthened  
**Docs:** this report; corrections in `PHASE_6A_REPORT.md`, `PHASE_6A_1_REPORT.md`, `PHASE_6A_2_REPORT.md`
