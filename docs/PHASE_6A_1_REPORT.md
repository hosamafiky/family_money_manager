# Phase 6A.1 Report — Certificate Workflow Correction and Verification

**Branch:** `main`  
**Phase 5B.8 feature:** `04ef81fd450c1b5ada8b6d3da7efca4735a0efc3`  
**Phase 5B.8 docs pin:** `86736ca7ecd19dea3ea93568a3aecc226faf870c`  
**Phase 6A feature:** `25347f429f0388ef5abb87fc6a15f50887cef482`  
**Phase 6A docs pin (pre-6A.1 HEAD):** `4f81df5b88ebf1afa93455fbd738b3f03f81595b`  
**Schema:** **17** (unchanged)  
**Tests:** **1410 → 1483** (+73)

---

## 1. Exact repository evidence (start of Phase 6A.1)

| Item | Value |
|------|--------|
| Branch | `main` |
| HEAD at start | `4f81df5b88ebf1afa93455fbd738b3f03f81595b` |
| Working tree | Dirty (parent-agent lint/RadioGroup fixes) |
| Files dirty after `25347f4` | `app_router.dart`, certificate creation/detail/providers/profit/redeem screens, `certificate_domain_test.dart`, plus docs pin only in `PHASE_6A_REPORT.md` between feature and pin |

---

## 2. Exact test reconciliation (Phase 6A baseline)

Static `test(` / `testWidgets(` counts by file for certificate / modified Phase 6A paths:

| File | Before (`86736ca`) | After (`25347f4`) | Added | Removed | Renamed/Moved | Classification |
|------|-------------------:|------------------:|------:|--------:|---------------|----------------|
| `test/database/certificates/certificate_repository_test.dart` | 0 | 51 | 51 | 0 | — | Database-tested |
| `test/database/certificates/certificate_true_migration_v16_to_v17_test.dart` | 0 | 1 | 1 | 0 | — | Database-tested |
| `test/unit/features/certificates/certificate_domain_test.dart` | 0 | 26 | 26 | 0 | — | Unit-tested |
| `test/widget/features/certificates/certificates_list_screen_test.dart` | 0 | 10 | 10 | 0 | — | Widget-tested |
| `test/database/goals/goal_true_migration_v12_to_latest_test.dart` | 1 | 1 | 0 | 0 | — | (version expectation only) |
| `test/database/goals/phase_5b8_progress_separation_test.dart` | 26 | 26 | 0 | 0 | — | (version expectation only) |
| `test/helpers/true_schema_v12.dart` | 0 | 0 | 0 | 0 | — | helper |

**Equation:** `1322 + 88 − 0 = 1410` (matches `flutter test` gate).

Note: a naïve whole-tree static grep under-counts vs `flutter test` (~15) because of non-`test(` patterns; file-level Phase 6A delta of **+88** reconciles exactly.

### Phase 6A.1 additions

Runtime-registered tests (including `for`-loop matrices):

| Area | Added | Classification |
|------|------:|----------------|
| CREATE-ROLL-1..11 | 11 | Database-tested |
| PROFIT-ROLL / PROFIT-IDMP | 9 | Database-tested |
| REDEEM-ROLL / REDEEM-IDMP | 14 | Database-tested |
| CERT-EVT-1..8 | 8 | Database-tested |
| REV-PUR / REV-PROF / REV-REDEEM-REJECT (+ rolls) | 14 | Database-tested / Fake-tested (use-case reject) |
| MC-CERT-1..5 | 5 | Database-tested (locking classified honestly) |
| CLS-1..8 reports/budgets/dashboard | 8 | Database-tested / Unit-tested (enum helper) |
| APP-WF routing fakes | 3 | Fake-tested |
| WF-UI redeem/profit split | 1 | Widget-tested |

**Equation:** `1410 + 73 − 0 = 1483`.

---

## 3. Profit-only path resolution

**Bug:** Redeem UI offered `_RedeemMode.profitOnly`, which called `RedeemCertificateUseCase` with `principalMinorUnits: 0`, colliding with full-principal / maturity validation.

**Fix (preferred):**
- Removed `profitOnly` from `RedeemCertificateScreen`
- Modes remaining: `principalOnly` | `combined`
- Principal field locked to full remaining balance (read-only)
- Explicit **Record Profit** navigation to `/certificates/:id/profit`
- Detail FAB already routes profit-only to `RecordCertificateProfitUseCase`

**Proof:**
- Widget: `WF-UI-1` — no “Profit only”; Record Profit navigates to profit route
- Application fakes: `APP-WF-1..3` — profit UC → `recordProfit` only; redeem UC → `redeem` only

---

## 4. Analyzer

`flutter analyze` → **No issues found!**

Included RadioGroup migration, camelCase localization accessors, brace style, and const/import cleanup from Phase 6A.1 tests.

---

## 5–7. Rollback / idempotency matrices

Fail-after hooks expanded on `CertificateFailAfter` and applied on create / profit / redeem / reverse paths (`@visibleForTesting`).

| Matrix | Coverage | Classification |
|--------|----------|----------------|
| CREATE-ROLL-1..11 | Complete absence after each boundary; same key retries once | Database-tested |
| PROFIT-ROLL / IDMP | Atomic income+event; equivalent/conflict/cross-HH; mid-fail | Database-tested |
| REDEEM-ROLL / IDMP | Principal-only and principal+profit; active+balance preserved on fail; lifecycle/`redeemedAt` only on success | Database-tested |

---

## 8. Certificate-event DB integrity

Triggers in `app_database.dart` strengthened:
- Purchase: source ≠ certificate account
- Redemption: destination ≠ certificate account
- Profit: destination ≠ certificate account + exactly one credit ledger row

SQL bypass suite **CERT-EVT-1..8** — **Database-tested**.

---

## 9. Controlled reversal atomicity

| Case | Result | Classification |
|------|--------|----------------|
| Purchase reversal | Single txn; reject after profit/redemption history; fail-after rolls | Database-tested |
| Profit reversal | Single txn; fail-after rolls | Database-tested |
| Redemption reversal | Explicit reject at use case **and** repository | Database-tested / Fake-tested |

---

## 10. Creation concurrency (MC-CERT-1..5)

Two Drift connections → one physical temp SQLite file (Phase 5B.6 pattern).

| Test | Observation |
|------|-------------|
| MC-CERT-1 equivalent | ≥1 `AppOk`; exactly one certificate/funding op; peer may be `AppPersistenceFailure` under WAL busy |
| MC-CERT-2 conflict | One winner; conflict or persistence on loser |
| MC-CERT-3 insufficient dual purchase | One success; one funds/persistence failure; non-negative balance |
| MC-CERT-4/5 vs expense/transfer | At least one succeeds; source balance ≥ 0; dual success under read races classified **nondeterministic** |

---

## 11. Ordinary-operation restrictions

Pre-existing repository tests 39–44 retained (income/expense/transfer/opening/adjustment). Goal-reserve ordinary guards unchanged. **Database-tested** (regressed via full suite).

---

## 12. Reports / budgets classification

CLS-1..8 cover purchase/redemption exclusion from I/E, profit-as-income, budget non-consumption, spendable/protected exclusion, no FX mix, account-flow close, and enum helper alignment. **Database-tested** / **Unit-tested**.

---

## 13. `goalWithdrawal` report change — **KEPT**

| | |
|--|--|
| **Previous** | `isExcludedFromIncomeExpenseReports` omitted `goalWithdrawal` (and `certificateMaturity`) |
| **Correct** | Exclude both, alongside `goalFunding` / `certificateFunding` |
| **Rationale** | Internal fund movements, not period income/expense |
| **SQL reports** | Already `type IN ('income','expense')` — historical SQL report totals **unchanged** |
| **Helper callers** | Align with financial meaning; tested in CLS-7 |
| **Accidental?** | No — intentional companion fix with certificate maturity exclusion |

---

## 14. True v16→v17 migration

`certificate_true_migration_v16_to_v17_test.dart` (**MIG-6A-1**):
- Physical file at `user_version = 16` without certificate tables
- Pre-6A household + account rows inserted
- Reopen via `AppDatabase` → schema **17**, certificate tables/triggers present, prior rows survive

Evidence is **onUpgrade**, not onCreate. **Database-tested**.

---

## 15. Scope scan

Within `lib/features/certificates/` and Phase 6A.1 diffs: no gold/securities/liabilities/net-worth product/Zakat calc/Firebase/sync/backup/auth/PIN/biometrics/notifications/voice/AI/export/auto-accrual implementations. Enum / column placeholders only. **Documented only** (scan).

---

## 16. Validation

```text
dart format --output=none --set-exit-if-changed .   # exit 0
flutter analyze                                       # No issues found!
flutter test --reporter=expanded                      # 1483 passed; 0 failed; 0 skipped
```

---

## 17. Deferred SQLite3MultipleCiphers risk

Unchanged (PO-2): sqlite3mc-ready binary; key injection deferred. Certificates still inherit at-rest plaintext risk until security hardening. **Documented only / Unverified** on device.

---

## 18. Remaining risks / gaps

1. Multi-connection WAL busy may surface as `AppPersistenceFailure` rather than typed conflict/funds — classified honestly in MC-CERT.
2. Concurrent purchase vs expense/transfer can race on read-then-write (same class of risk as goals).
3. Purchase reversal archives immediately (V1-simple) — unchanged.
4. Partial / early redemption / accrued interest / YTM / tax — still deferred product.
5. Emulator / App Bundle — not run (hard constraint). **Unverified**.

---

## 19. Claim classification legend

| Label | Meaning |
|-------|---------|
| Documented only | Spec/report text without automated proof |
| Unit-tested | Pure domain / enum tests |
| Database-tested | Drift/SQLite integration |
| Fake-tested | In-memory fake repositories / call counters |
| Widget-tested | Flutter widget tests |
| Unverified | Explicitly not executed |

---

## 20. Final commit

Feature commit message:

`fix: Phase 6A.1 – certificate workflow correction and verification`

Exact hash recorded after commit in §21 of this file / `PHASE_6A_REPORT.md` pin update.

---

## 21. Final commit hashes

- **Phase 6A.1 feature:** `35602d9e9761de46a2f33afff268cbef28395e41`
- Working tree: clean after this commit (docs pin may follow)
- Message: `fix: Phase 6A.1 – certificate workflow correction and verification`
- Schema version: **17**
- Final suite: **1483** passed; `flutter analyze` → No issues found!
