# Phase 6A.4 Report — Reversal Idempotency & Complete Debit-Workflow Coverage

**Branch:** `main`  
**Feature commit:** *(pinned after commit)*  
**Prior HEAD:** `2e70ae937753f8c888fce3a931116c9dfd4c8f98` (Phase 6A.3 docs pin)  
**Phase 6A.3 feature:** `ef733acce8b939245581f63820e0b46e4ccf8a68`  
**Analyzer follow-up:** `8daca6a624a2d2a35ea14670d70915f267b007c3`  
**Docs pins after 8daca6a:** `441b753` / `2e70ae9` (docs-only on `PHASE_6A_3_REPORT.md`)  
**Schema:** **18** (unchanged)  
**Tests:** **1525 → 1547** (`1525 + 22 − 0 = 1547`)

---

## 1. Exact repository evidence (pre-commit)

| Item | Value |
|------|-------|
| `pwd` | `/Users/hussam/Desktop/hussam/family_money_manager` |
| Branch | `main` |
| HEAD before 6A.4 | `2e70ae937753f8c888fce3a931116c9dfd4c8f98` |
| Working tree | Clean at start |
| Baseline tests | **1525** |
| Files after `8daca6a` | docs-only (`PHASE_6A_3_REPORT.md`) |

---

## 2–3. Purchase & profit reversal idempotency

Normalized fingerprints (stored on `certificate_events.payload_fingerprint`):

### Purchase reversal fingerprint fields

| Field | Included |
|-------|----------|
| Household ID | yes |
| Certificate ID | yes |
| Original operation ID | yes (purchase op) |
| Reversal type | `purchaseReverse` |
| Effective date | yes |
| Amount / currency | yes |
| Destination / source account | yes (cert acct debit / cash credit) |
| Reason / note | yes (authoritative; trimmed; empty when null) |
| Actor metadata | yes (`createdBy`) |

Builder: `buildPurchaseReversalIdempotencyPayload` in `certificate_write_boundary.dart`.

### Profit reversal fingerprint fields

| Field | Included |
|-------|----------|
| Household ID | yes |
| Certificate ID | yes |
| Original operation ID | yes (profit income op) |
| Reversal type | `profitReverse` |
| Effective date | yes |
| Amount / currency | yes |
| Destination account | yes (debited cash destination) |
| Reason / note | yes |
| Actor metadata | yes (`createdBy`) |

Builder: `buildProfitReversalIdempotencyPayload`.

**Contract:** same key + matching fingerprint → `AppOk` (replay). Same key + mismatched fingerprint → `AppDuplicateConflict` (no second financial write). Already-reversed original under a different key → `AppOk` (equivalent). Equivalent requests never return `AppDuplicateConflict`.

### Purchase reversal exact rows

| Test | Scenario | Exact outcomes |
|------|----------|----------------|
| REV-PUR-SEQ-EQ | Sequential equivalent | Both `AppOk`; one reversal op + one `purchaseReversed` event |
| REV-PUR-SEQ-CF | Sequential conflicting | `AppOk` then `AppDuplicateConflict`; one reversal |
| REV-PUR-CONC-EQ | Concurrent equivalent | Both `AppOk`; one mirror ledger (1 debit + 1 credit); one reversal event; lifecycle archived once |
| REV-PUR-CONC-CF | Concurrent conflicting | Exactly one `AppOk` + one `AppDuplicateConflict`; one financial reversal |
| REV-PUR-NEVER-CF-EQ | Equivalent never conflict | Both `AppOk`; never `AppDuplicateConflict` |
| REV-PUR-FAIL-RETRY | Failure then retry | Persistence failure → retry `AppOk`; one reversal |

### Profit reversal exact rows

| Test | Scenario | Exact outcomes |
|------|----------|----------------|
| REV-PROF-SEQ-EQ | Sequential equivalent | Both `AppOk`; one op, ledger debit, context, `profitReversed` event |
| REV-PROF-SEQ-CF | Sequential conflicting | `AppOk` then `AppDuplicateConflict`; no second reversal |
| REV-PROF-CONC-EQ | Concurrent equivalent | Both `AppOk`; one financial reversal |
| REV-PROF-CONC-CF | Concurrent conflicting | Exactly one `AppOk` + one `AppDuplicateConflict`; one reversal |
| REV-PROF-FAIL-RETRY | Failure then retry | Persistence failure → retry `AppOk`; one reversal |

**Classification:** Unit-tested (FP-*) + Database-tested (REV-*).

---

## 4. Debit workflow inventory

Every production path that inserts a **debit** ledger entry:

| Workflow | Repository method | Tx boundary | SqliteContentionPolicy | Balance recalc in writer tx | Typed insufficient | DB negative-balance trigger | Test evidence |
|----------|-------------------|-------------|------------------------|-----------------------------|--------------------|-----------------------------|---------------|
| Expense | `DriftLedgerRepository.recordExpense` | Drift `transaction` | **Yes** (6A.3) | Yes `_checkSufficientBalance` | `InsufficientFundsError` | Yes | XDEB / MC-CERT / DET-DEB |
| Ordinary transfer (debit leg) | `executeTransfer` | Drift `transaction` | **Yes** (6A.3) | Yes | `InsufficientFundsError` | Yes | XDEB-3/5/6 |
| Goal funding (source debit) | `fundGoalTransfer` → `_executeGoalAssociatedTransfer` | Drift `transaction` | **Yes** (6A.3) | Yes | `AppInsufficientFunds` | Yes | XDEB-4/6 |
| Goal release (reserve debit when releasing to standard acct) | `releaseGoalTransfer` | same | **Yes** (6A.3) | Yes | `AppInsufficientFunds` | Yes | goal repo suites |
| Certificate purchase (source cash debit) | `createCertificate` | Drift `transaction` | **Yes** (6A.3) | Yes | `AppInsufficientFunds` | Yes | XDEB / CIDMP |
| Certificate redemption (cert-account debit) | `redeemCertificate` | Drift `transaction` | **Yes** (6A.3) | Yes (principal path) | typed / trigger | Yes | CIDMP-7/12 |
| Purchase reversal (cert-account debit) | `reversePurchase` | Drift `transaction` | **Yes** | amounts from original | `AppInsufficientFunds` on trigger | Yes | REV-PUR-* / CIDMP-8/13 |
| Profit reversal (destination debit) | `reverseProfit` | Drift `transaction` | **Yes** | amounts from original | `AppInsufficientFunds` on trigger | Yes | REV-PROF-* / CIDMP-9 |
| Debit adjustment | `recordAdjustment` (`isCredit==false`) | Drift `transaction` | **Yes (wired 6A.4)** | Yes | `InsufficientFundsError` | Yes | DEB-CONT-1 / DB-G-3 |
| Protected-money withdrawal | via `recordExpense` / `executeTransfer` + audit | same as expense/transfer | **Yes** (inherits) | Yes | `InsufficientFundsError` | Yes | protected_account_db_test |
| Opening balance | `recordOpeningBalance` | Drift `transaction` | N/A — **credit-only** (no debit insert) | N/A | N/A | N/A | ledger opening-balance tests |
| Opening-balance **correction** | `reverseOperation` on opening/income (debit mirror) | Drift `transaction` | **Yes (wired 6A.4)** | Yes (debit legs checked) | `InsufficientFundsError` | Yes | DEB-CONT-2 |
| Controlled ledger reversal | `reverseOperation` | Drift `transaction` | **Yes (wired 6A.4)** | Yes | `InsufficientFundsError` | Yes | DEB-CONT-2 / ledger reversal tests |
| Goal transfer reversal | `reverseGoalTransfer` | Drift `transaction` | **Yes (wired 6A.4)** | mirror legs; trigger backstop | `AppInsufficientFunds` | Yes | goal reversal suites |

### Intentionally without contention retry

| Path | Reason |
|------|--------|
| Raw maintenance / fixture SQL | Not user-facing; used in migration & DET-DEB trigger proofs |
| Credit-only opening balance | No debit insert |
| Query / report repositories | Read-only |

**Debit workflows fixed for contention in 6A.4:**  
1. `recordAdjustment` (debit)  
2. `reverseOperation`  
3. `reverseGoalTransfer`

---

## 5. DB guarantees retained (schema 18)

| Mechanism | Status | Evidence |
|-----------|--------|----------|
| `prevent_negative_account_balance` | Retained | DB-G-1 / DET-DEB-1 |
| Balanced transfer legs | Retained | DB-G-2 |
| Cert-event / goal-movement structural validation | Retained | BAL-EVT / goal suites |
| Goal-reserve & certificate-account restrictions | Retained | DB-G-4 |
| Atomic rollback after rejected debit | Retained | DB-G-3 / DET-DEB-2 |
| Schema version | **18** | DB-G-5 |

**Classification:** Database-tested.

---

## 6. Test reconciliation

**Start:** 1525  
**Equation:** `1525 + 22 − 0 = 1547`

| File | Tests | Classification | Change |
|------|-------|----------------|--------|
| `reversal_fingerprint_test.dart` | FP-PUR-1, FP-PUR-2, FP-PROF-1, FP-PROF-2 (4) | Unit-tested | **added** |
| `phase_6a4_reversal_idempotency_test.dart` | REV-PUR-SEQ-EQ, SEQ-CF, CONC-EQ, CONC-CF, NEVER-CF-EQ, FAIL-RETRY; REV-PROF-SEQ-EQ, SEQ-CF, CONC-EQ, CONC-CF, FAIL-RETRY (11) | Database-tested | **added** |
| `phase_6a4_debit_contention_test.dart` | DEB-CONT-1, DEB-CONT-2 (2) | Database-tested | **added** |
| `phase_6a4_db_guarantees_test.dart` | DB-G-1..5 (5) | Database-tested | **added** |

No tests removed/renamed/moved.

---

## 7. Validation

```text
dart format --output=none --set-exit-if-changed .   # exit 0
flutter analyze                                       # No issues found!
flutter test --reporter=expanded                      # 1547 passed; 0 failed
```

*(Filled after committed validation.)*

---

## 8. Claim classifications

| Claim | Classification |
|-------|----------------|
| Purchase/profit reversal fingerprint fields + deterministic normalization | Unit-tested + Database-tested |
| Equivalent sequential/concurrent reversal → both `AppOk` | Database-tested |
| Conflicting sequential/concurrent → `AppOk` + `AppDuplicateConflict` | Database-tested |
| Failure + retry equivalent reversal | Database-tested |
| Debit adjustment / reverseOperation / reverseGoalTransfer contention | Database-tested |
| Negative-balance trigger / transfer balance / cert-account restriction | Database-tested |
| Emulator / App Bundle / encrypted DB | Unverified |
| Phase 6B.1 | Documented only (not started) |

---

## 9. Gaps / residual risks

1. Goal funding still persists operation `type='transfer'` (pre-existing; unchanged).
2. Device / App Bundle / emulator builds not run (hard constraint).
3. Phase 6B.1 not begun.
4. CIDMP-15 historically named “conflicting” but used same key + same payload; true conflicting coverage is REV-PROF-CONC-CF.
5. Contention exhaustion still maps to `AppPersistenceFailure` only when unhealthy / deadline exceeded.

---

## 10. Scope scan

No architecture refactoring, UI redesign, gold, investments, liabilities, net worth, Zakat, sync, security, backup, notifications, voice, AI, or exports. No Android/iOS/App Bundle/emulator builds. `money_tracker_next` / `money_tracker` untouched. Phase 6B.1 not begun.

---

## 11. Files changed (summary)

**Lib:** `certificate_write_boundary.dart` (fingerprint builders); `drift_certificate_repository.dart` (reversal fingerprints); `drift_ledger_repository.dart` (adjustment + reverseOperation contention); `drift_goal_repository.dart` (reverseGoalTransfer contention)  
**Tests:** FP / REV-PUR / REV-PROF / DEB-CONT / DB-G  
**Docs:** this report; `PHASE_6A_3_REPORT.md` corrected with separate purchase/profit reversal rows
