# Phase 6A.1 Report — Certificate Workflow Correction and Verification

**Branch:** `main`  
**Feature commit:** `35602d9e9761de46a2f33afff268cbef28395e41`  
**Docs pin:** `4264b3fd4b1e4fca219af9bfd4cb4d7f88e3ac7a`  
**Prior HEAD (Phase 6A docs pin):** `4f81df5b88ebf1afa93455fbd738b3f03f81595b`  
**Phase 6A feature:** `25347f429f0388ef5abb87fc6a15f50887cef482`  
**Phase 5B.8 feature:** `04ef81fd450c1b5ada8b6d3da7efca4735a0efc3`  
**Phase 5B.8 docs pin:** `86736ca7ecd19dea3ea93568a3aecc226faf870c`  
**Schema:** **17** (unchanged)  
**Tests:** **1410 → 1483** (+73)

---

## 1. Exact repository evidence (pre-commit)

| Item | Value |
|------|-------|
| `pwd` | `/Users/hussam/Desktop/hussam/family_money_manager` |
| Branch | `main` |
| HEAD before 6A.1 commit | `4f81df5b88ebf1afa93455fbd738b3f03f81595b` |
| Working tree | Dirty (lint fixes + 6A.1 work, then cleaned by this commit) |
| Phase 5B.8 feature | `04ef81fd450c1b5ada8b6d3da7efca4735a0efc3` |
| Phase 5B.8 docs pin | `86736ca7ecd19dea3ea93568a3aecc226faf870c` |
| Phase 6A feature | `25347f429f0388ef5abb87fc6a15f50887cef482` |
| Phase 6A docs pin | `4f81df5b88ebf1afa93455fbd738b3f03f81595b` (verified) |

### Files changed after `25347f4` (included in this phase)

**Modified**

- `lib/app/app_router.dart` — import order
- `lib/core/database/app_database.dart` — strengthened certificate event triggers
- `lib/features/certificates/data/certificate_write_boundary.dart` — expanded fail-after enum
- `lib/features/certificates/data/drift_certificate_repository.dart` — granular fail hooks + reverse hooks
- `lib/features/certificates/presentation/certificate_creation_screen.dart` — brace lint
- `lib/features/certificates/presentation/certificate_detail_screen.dart` — brace lint
- `lib/features/certificates/presentation/providers/certificate_providers.dart` — import order
- `lib/features/certificates/presentation/record_certificate_profit_screen.dart` — camelCase getters
- `lib/features/certificates/presentation/redeem_certificate_screen.dart` — remove profit-only; RadioGroup; locked principal
- `test/database/certificates/certificate_true_migration_v16_to_v17_test.dart` — data survival evidence
- `test/unit/features/certificates/certificate_domain_test.dart` — camelCase lint

**Added**

- `test/database/certificates/phase_6a1_rollback_matrix_test.dart`
- `test/database/certificates/phase_6a1_event_integrity_test.dart`
- `test/database/certificates/phase_6a1_reversal_test.dart`
- `test/database/certificates/phase_6a1_multi_connection_test.dart`
- `test/database/certificates/phase_6a1_classification_test.dart`
- `test/unit/features/certificates/certificate_workflow_routing_test.dart`
- `test/widget/features/certificates/certificate_redeem_workflow_test.dart`
- `docs/PHASE_6A_1_REPORT.md`
- Updated `docs/PHASE_6A_REPORT.md`

---

## 2. Exact test reconciliation

### Phase 6A gate (1322 → 1410)

Static `test(` / `testWidgets(` counts by file (86736ca → 25347f4):

| File | Before | After | Added | Removed | Renamed | Classification |
|------|--------|-------|-------|---------|---------|----------------|
| `test/database/certificates/certificate_repository_test.dart` | 0 | 51 | 51 | 0 | — | Database-tested |
| `test/database/certificates/certificate_true_migration_v16_to_v17_test.dart` | 0 | 1 | 1 | 0 | — | Database-tested |
| `test/unit/features/certificates/certificate_domain_test.dart` | 0 | 26 | 26 | 0 | — | Unit-tested |
| `test/widget/features/certificates/certificates_list_screen_test.dart` | 0 | 10 | 10 | 0 | — | Widget-tested |
| `test/database/goals/goal_true_migration_v12_to_latest_test.dart` | 1 | 1 | 0 | 0 | — | touched (schema expect 17) |
| `test/database/goals/phase_5b8_progress_separation_test.dart` | 26 | 26 | 0 | 0 | — | touched |
| `test/helpers/true_schema_v12.dart` | 0 | 0 | 0 | 0 | — | helper only |

**Equation:** `1322 + 88 − 0 = 1410`

Note: static grep of the tree at gate commits undercounts absolute totals (1307 / 1395) vs recorded flutter-run totals (1322 / 1410) by a constant +15; the **delta of +88** is exact and file-reconciled.

### Phase 6A.1 (1410 → 1483)

Runtime expansions include `for`-loop generated tests (CREATE-ROLL-1..11, etc.).

| Area | Runtime tests added | Classification |
|------|---------------------|----------------|
| CREATE-ROLL / PROFIT-ROLL / REDEEM-ROLL / IDMP | 34 | Database-tested |
| REV-PUR / REV-PROF / REV-REDEEM-REJECT | 14 | Database-tested |
| CERT-EVT-1..8 | 8 | Database-tested |
| MC-CERT-1..5 | 5 | Database-tested |
| CLS-1..8 reports/budgets/dashboard | 8 | Database-tested / Unit-tested (CLS-7) |
| APP-WF use-case routing | 3 | Fake-tested |
| WF-UI redeem screen | 1 | Widget-tested |

**Equation:** `1410 + 73 − 0 = 1483`

---

## 3. Profit-only workflow correction

**Bug:** Redeem screen exposed `_RedeemMode.profitOnly` and called `RedeemCertificateUseCase` with `principalMinorUnits: 0`, which fails maturity/full-principal validation and is the wrong use case.

**Fix (preferred path):**

- Removed `_RedeemMode.profitOnly` from `RedeemCertificateScreen`
- Modes remaining: `principalOnly` | `combined`
- Principal field is **read-only / locked** to full remaining balance (no partial redemption)
- Optional maturity profit only in `combined` mode
- Explicit `Record Profit` button navigates to `/certificates/:id/profit` → `RecordCertificateProfitUseCase` only
- Detail screen already had a profit FAB (retained)

**Evidence:**

- Widget: `WF-UI-1` — no “Profit only” radio; Record Profit navigates
- Application fakes: `APP-WF-1` / `APP-WF-2` — profit UC calls `recordProfit` only; redeem UC calls `redeem` only

---

## 4. Analyzer

`flutter analyze` → **No issues found!**

Included RadioGroup migration, camelCase getters, brace lint, prefer_const / unused_shown_name cleanup in 6A.1 tests.

---

## 5–7. Rollback matrices & idempotency

### Fail-after hooks (`CertificateFailAfter`)

Expanded test-only hooks on create / profit / redeem / reverse paths:

`idempotencyLookup`, `accountInsert`, `certificateInsert`, `revisionInsert`, `operationInsert`, ledger legs, `operationContext`, `createdEvent`, `purchasedEvent`, `eventInsert`, `lifecycleUpdate`, profit mid-points, `preCommit`.

### Purchase — CREATE-ROLL-1..11

Fail after each boundary → assert complete absence (no cert/account/revision/ops/ledger/events; source balance unchanged) → retry same key succeeds once.

### Profit — PROFIT-ROLL / PROFIT-IDMP

Mid-failure rollback; equivalent retry; conflicting retry; cross-household key isolation. No orphan income without event (or vice versa).

### Redemption — REDEEM-ROLL / REDEEM-IDMP

Principal-only and principal+profit mid-failure cases; after failure certificate remains **active** with original principal and `redeemedAt` unset; lifecycle/timestamp only on success; equivalent/conflicting idempotency.

**Classification:** Database-tested (injected failure).

---

## 8. Certificate-event DB integrity

Strengthened triggers in `app_database.dart`:

- Purchase: source ≠ certificate account
- Redemption: destination ≠ certificate account
- Profit: destination ≠ certificate account; exactly one credit ledger entry; category `certificate_profit`

SQL bypass tests CERT-EVT-1..8: wrong op type, self-destination, wrong category, cross-HH, append-only update/delete, revision immutability.

**Classification:** Database-tested.

---

## 9. Controlled reversal atomicity

- **Purchase reversal:** success + mid-failure rollback matrix; reject when profit history exists
- **Profit reversal:** success + mid-failure rollback
- **Redemption reversal:** explicitly rejected at use-case **and** repository (`REV-REDEEM-REJECT-1/2`)

**Classification:** Database-tested / Fake-tested (APP-WF-3).

---

## 10. Creation concurrency (MC-CERT-1..5)

Two Drift connections → one physical temp SQLite file (Phase 5B.6 pattern).

| Test | Result classification |
|------|------------------------|
| MC-CERT-1 equivalent concurrent create | ≥1 `AppOk`; exactly one certificate; WAL busy may yield `AppPersistenceFailure` on loser — **honest nondeterministic locking** |
| MC-CERT-2 conflicting concurrent create | One winner; conflict or persistence on loser |
| MC-CERT-3 insufficient source race | One certificate; non-negative balance |
| MC-CERT-4 purchase vs expense | At least one succeeds; balance ≥ 0; race possible |
| MC-CERT-5 purchase vs transfer | Same |

**Classification:** Database-tested (nondeterministic outcomes documented).

---

## 11. Ordinary-operation restrictions

Regressed in Phase 6A repository tests 39–44 (income/expense/transfer/opening/adjustment). Goal-reserve restrictions unchanged (no shared-ledger regression observed). Widget filters remain non-authoritative.

**Classification:** Database-tested (existing + retained).

---

## 12. Reports / budgets / classification

CLS-1..8:

- Purchase/redemption principal excluded from I/E gross expense
- Profit included as ordinary income
- No expense-budget consumption from cert flows
- Certificate principal excluded from spendable/protected dashboard totals
- Currencies never combined
- Account-flow reconciles certificate account open→close
- `goalWithdrawal` / `certificateMaturity` / `certificateFunding` excluded via enum helper

**Classification:** Database-tested / Unit-tested (CLS-7).

---

## 13. `goalWithdrawal` report change — **KEPT**

**Previous:** `OperationType.isExcludedFromIncomeExpenseReports` excluded `transfer`, `goalFunding`, `certificateFunding`, … but **not** `goalWithdrawal`.

**Correct:** Also exclude `goalWithdrawal` (and `certificateMaturity`).

**Rationale:** Goal withdrawal is an internal fund movement like goal funding — not household income/expense. Aligns enum helper with INV-011 semantics. Period I/E SQL already filters `type IN ('income','expense')`, so **historical SQL report totals do not change**; only callers of the helper are corrected.

**Tests:** CLS-7.  
**Decision:** Not accidental → **kept** (not reverted).

---

## 14. True v16→v17 migration

`certificate_true_migration_v16_to_v17_test.dart` (MIG-6A-1):

1. Open current schema, strip Phase 6A tables/triggers/indexes, set `user_version = 16`
2. Populate pre-6A household + account rows
3. Reopen via `AppDatabase` → `onUpgrade` to 17
4. Assert certificate tables + triggers exist; pre-6A rows survive

Not classified as `onCreate` evidence.

**Classification:** Database-tested.

---

## 15. Scope scan

Within `lib/features/certificates/` and Phase 6A.1 diffs: no gold, tradable securities, liabilities product, net-worth product, Zakat calculation, Firebase, sync, backup, auth/PIN/biometrics, notifications, voice, AI, export, or automatic profit accrual implementations. Enum placeholders / `includeInZakat: false` columns remain non-product.

---

## 16. Validation

```text
dart format --output=none --set-exit-if-changed .   # exit 0
flutter analyze                                       # No issues found!
flutter test --reporter=expanded                      # 1483 passed; 0 failed
```

Exact final commit hash recorded after commit in §21 / git log.

---

## 17. Deferred SQLite3MultipleCiphers risk

Unchanged (PO-2): certificate data inherits plaintext-at-rest risk until security hardening.

---

## 18. Remaining risks / gaps

1. Multi-connection equivalent create may return `AppPersistenceFailure` on the loser under WAL busy (documented; not silent corruption).
2. Purchase reversal still archives immediately (V1-simple).
3. Partial / early redemption still deferred.
4. Accrued interest / auto payout deferred.
5. Device / App Bundle builds not run (hard constraint).
6. Concurrent purchase vs expense/transfer can theoretically both succeed under read races if checks are non-atomic across connections — balance ≥ 0 asserted; stronger serialization deferred.

---

## 19. Claim classifications summary

| Claim | Classification |
|-------|----------------|
| Profit-only removed from redeem UI | Widget-tested |
| Correct use-case routing | Fake-tested |
| CREATE/PROFIT/REDEEM rollback matrices | Database-tested |
| Event trigger integrity | Database-tested |
| Reversal atomicity / redeem reject | Database-tested |
| MC-CERT concurrency | Database-tested (nondeterministic noted) |
| Reports/budgets classification | Database-tested |
| goalWithdrawal exclusion helper | Unit-tested |
| True v16→v17 migration | Database-tested |
| Emulator / encrypted DB | Unverified |
| Auto-accrual / partial redeem | Documented only (deferred) |


---

---

## 21. Exact final commit evidence

| Role | Hash | Message |
|------|------|---------|
| Phase 6A.1 feature | `35602d9e9761de46a2f33afff268cbef28395e41` | `fix: Phase 6A.1 – certificate workflow correction and verification` |
| Phase 6A.1 docs pin | `4264b3fd4b1e4fca219af9bfd4cb4d7f88e3ac7a` | `docs: pin Phase 6A.1 feature commit hash in reports` |

Validation on feature commit: `flutter analyze` → **No issues found!**; `flutter test` → **1483** passed; format clean.

