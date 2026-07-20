# Phase 6B.1.1 Report — Certificate-account eligibility closure

**Date:** 2026-07-20  
**Phase:** 6B.1.1  
**Stop condition:** Complete 6B.1.1 only — do **not** begin 6B.2 UI redesign.

---

## 1. Repository state reconciliation (pre-work)

| Item | Value |
|------|-------|
| Branch | `main` |
| Clean HEAD at start | `47fd59676d5a9a06ac6d4ea6f9b6ae3c256e4729` |
| Working tree | **clean** |
| Schema | **18** → target **19** |
| Baseline tests | **1566** |

### Discrepancy: reported clean HEAD `47fd596` vs docs-pin `5216dab`

Both are valid commits on `main`. `5216dabc905a4569735ddb524cfd01f80fe5479a` finalized Phase 6B.1 evidence pointers; subsequent docs-only commits advanced Final HEAD pins until tip `47fd596…`. **No feature/work commits after `08b2439`** — only documentation pins.

### Full hashes after `08b24397f70920a0126a9932736f759dff38f5cf`

| Hash | Subject | Class |
|------|---------|-------|
| `a7b167b5a4a46f07555ab696efb87c2c8912959c` | docs: Phase 6B.1 report and validation evidence | Report |
| `4dd019d78f9d1c1259385d412cad6ed268ed5b54` | docs: pin Phase 6B.1 report commit hash | Doc-pin |
| `acee573a3f3db116385f61226c2fc9c7d1cf2d66` | docs: correct Phase 6B.1 report commit hash table | Doc-pin |
| `8f83cc2f701302b8790e6d2c9351ef934077673e` | docs: pin Phase 6B.1 final HEAD in report | Doc-pin |
| `5216dabc905a4569735ddb524cfd01f80fe5479a` | docs: finalize Phase 6B.1 evidence pointers | Doc-pin |
| `47fd59676d5a9a06ac6d4ea6f9b6ae3c256e4729` | docs: set Phase 6B.1 report Final HEAD to tip | Doc-pin |

### Phase 6B.1 feature/work commits (before report commits)

| Hash | Subject |
|------|---------|
| `83bc7c64222c6d2d3f65b4372b81b04cdc6794e6` | docs: Phase 6B.1 refactor audit and as-built architecture |
| `4bfca577af4fd8c4355444e0441dac093081d29d` | refactor: extract AppDatabase schema helpers into focused mixins |
| `06e2ce2d97d0cc1e4e9a43c7bb99b747629980c8` | refactor: extract ledger write support and shared idempotency helpers |
| `6adf8d97c1d4c55c4a4650bfb7283757991b38c6` | refactor: standardize goal/certificate idempotency fingerprint decisions |
| `0cfe675927cc5e875a966f553e4735fb43dd17f4` | refactor: consolidate eligibility, money formatting, and tx invalidation |
| `06eaee1177050d91e409698b3ce61ce762650fb0` | test: add architecture boundary guards and refactor unit coverage |
| `08b24397f70920a0126a9932736f759dff38f5cf` | style: dart format AppDatabase schema helper parts |

---

## 2. Problem closed

Phase 6B.1 documented (and deferred) that goal funding UI / use-case gates still allowed certificate sources. That was **incorrect as a product stance**: certificate-account workflow ownership is a **financial invariant** (INV-004A), not optional UI polish.

Certificate accounts must be usable **only** by approved certificate workflows (purchase, redemption, controlled purchase reversal, other explicitly approved cert-owned ops). They must **not** be usable as:

- Goal funding source / goal release destination
- Ordinary income / expense / transfer endpoints
- Opening balance / adjustment / unrelated reversal destinations
- Generic account selection for non-cert workflows

**Retained:** Profit receipt still credits a standard spendable account and does not alter certificate principal.

---

## 3. Eligibility layers fixed

| Layer | Change |
|-------|--------|
| 1. Shared `AccountEligibility` | `isGoalFundingSource` / `isGoalReleaseDestination` exclude certificate type+purpose; require spendable; rejection helpers added |
| 2. Goal use cases | `FundGoalUseCase` / `CreateGoalUseCase` / `ReleaseGoalFundsUseCase` use typed `goalFundingSourceFailure` / `goalReleaseDestinationFailure` |
| 3. Goal repository | `_validateGoalTransferEndpoints` rejects type/purpose/linkage/non-spendable; maps trigger aborts to typed `AppValidationFailure` |
| 4. Presentation filters | Fund / release / creation screens use `AccountEligibility` (convenience only) |
| 5. Database (schema **19**) | Triggers `validate_funding_source_eligibility` + `validate_release_destination_eligibility` |

Goal funding source must be: same HH, active, same currency as reserve, spendable, not protected, not goal reserve, not certificate-owned.

Goal release destination must be: same HH, active, spendable, same currency, not goal reserve, not certificate-owned.

---

## 4. Schema 19

- `schemaVersion => 19`
- Authentic physical **18→19** migration test preserves fixture IDs/history and installs the two eligibility triggers
- Fresh installs apply triggers on `onCreate`

---

## 5. Test reconciliation

**Equation:** `1566 + 24 − 0 = 1590`

| Change | Count | Classification |
|--------|------:|----------------|
| Added (new 6B.1.1 tests / expanded eligibility) | **24** | mixed |
| Removed | **0** | — |
| Renamed | MIG-5B8-4 / cert fresh-schema / DB-G-5 labels (18→19) | migration assertion update |
| Moved | **0** | — |

**Final:** **1590** — all passed.

---

## 6. Phase 6B.1.1 tests by file

### `test/unit/features/accounts/account_eligibility_test.dart`

| Name | Classification | Change |
|------|----------------|--------|
| ordinary endpoints exclude reserve and certificate | unit | retained |
| goal funding source excludes protected, reserve, certificate, non-spendable | unit | **updated** (expanded) |
| goal release destination excludes reserve, certificate, non-spendable | unit | **added** |
| ordinaryEndpointRejection maps reserved types | unit | retained |
| goalFundingSourceRejection maps certificate | unit | **added** |

### `test/database/goals/phase_6b11_certificate_goal_eligibility_test.dart` (**new**)

| Name | Classification | Change |
|------|----------------|--------|
| SQL-1. Cert account funding a goal is rejected by trigger | database / SQL-bypass | added |
| SQL-2. Goal release into cert account is rejected by trigger | database / SQL-bypass | added |
| SQL-3. Account marked certificate by type rejected as funding source | database / SQL-bypass | added |
| SQL-4. Account marked certificate by purpose rejected as funding source | database / SQL-bypass | added |
| SQL-5. Account linked to existing certificate rejected as funding source | database / SQL-bypass | added |
| SQL-6. Non-spendable ordinary source rejected | database / SQL-bypass | added |
| SQL-7. Non-spendable ordinary destination rejected on release | database / SQL-bypass | added |
| SQL-8. Cross-household funding rejected | database / SQL-bypass | added |
| SQL-9. Currency mismatch funding rejected | database / SQL-bypass | added |
| SQL-P1. Eligible standard can fund goal | database / positive | added |
| SQL-P2. Goal release to eligible standard succeeds | database / positive | added |
| SQL-P3. Cert purchase still credits cert account | database / positive | added |
| SQL-P4. Cert redemption still debits cert account | database / positive | added |

### `test/database/goals/phase_6b11_goal_certificate_use_case_test.dart` (**new**)

| Name | Classification | Change |
|------|----------------|--------|
| UC-1. FundGoalUseCase typed rejection for certificate source | database + application | added |
| UC-2. ReleaseGoalFundsUseCase typed rejection for certificate destination | database + application | added |
| UC-3. Direct repository fundGoalTransfer cannot bypass certificate source gate | database / repository | added |
| UC-4. Direct repository releaseGoalTransfer cannot bypass certificate dest gate | database / repository | added |

### `test/widget/features/goals/phase_6b11_goal_selector_filter_test.dart` (**new**)

| Name | Classification | Change |
|------|----------------|--------|
| SEL-F1. Excludes certificate accounts; keeps eligible bank | widget / presentation filter (**not** DB authority) | added |
| SEL-F2. AR locale still excludes certificate accounts | widget / presentation filter | added |
| SEL-R1. Excludes certificate accounts; keeps eligible bank | widget / presentation filter | added |
| SEL-R2. AR locale still excludes certificate accounts | widget / presentation filter | added |

### `test/database/goals/phase_6b11_migration_v18_to_v19_test.dart` (**new**)

| Name | Classification | Change |
|------|----------------|--------|
| MIG-6B11-1. Authentic physical v18→19 preserves IDs and installs eligibility triggers | database / authentic migration | added |

### Assertion updates (not new behaviors)

| File | Change |
|------|--------|
| `architecture_boundaries_test.dart` | schemaVersion **19** |
| `certificate_true_migration_v16_to_latest_test.dart` | latest = **19** |
| `goal_true_migration_v12_to_latest_test.dart` | latest = **19** |
| `phase_5b8_progress_separation_test.dart` | fresh schema **19** |
| `certificate_repository_test.dart` | fresh schema label **v19** |

**Honest classification note:** Selector widget tests prove UX filtering only. Authoritative rejection is proven by SQL-bypass + repository + use-case suites.

---

## 7. Gaps / non-goals retained

- Phase **6B.2** UI/UX redesign — not started
- Gold, investments, liabilities, net worth, Zakat, sync, security, backup, notifications, voice, AI, exports, recurring financial execution — not implemented
- Redemption reversal remains unsupported (pre-existing)
- Ordinary I/E/transfer certificate exclusion was already present; unchanged semantically

---

## 8. Validation

| Step | Exit code | Notes |
|------|----------:|-------|
| `dart format .` | **0** | |
| Feature commit | — | `e6bde6105bb2a329b6e799f137c7475c036294ab` — `fix: Phase 6B.1.1 – close certificate-account eligibility bypasses` |
| Validation fix commit | — | `df1e8721517c770dbfd745ba5d2cc6b1ad4752f3` — schema 19 assertions + prefer_const |
| `dart format --output=none --set-exit-if-changed .` | **0** | |
| `flutter analyze` | **0** | No issues found |
| `flutter test` | **0** | **1590** passed; equation `1566 + 24 − 0 = 1590` |
| Docs pin commit | — |  |
| Final HEAD | — |  |
| Working tree | **clean** (after pin) | |
| Schema | **19** | `int get schemaVersion => 19;` |

---

## 9. Paths

| Doc | Path |
|-----|------|
| This report | `docs/PHASE_6B_1_1_REPORT.md` |
| Architecture | `docs/ARCHITECTURE.md` |
| Refactor audit | `docs/REFACTOR_AUDIT.md` |
| Phase 6B.1 report | `docs/PHASE_6B_1_REPORT.md` |
| Financial invariants | `docs/FINANCIAL_INVARIANTS.md` (INV-004A) |
