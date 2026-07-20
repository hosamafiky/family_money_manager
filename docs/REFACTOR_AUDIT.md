# Refactor Audit — Phase 6B.1

**Date:** 2026-07-20  
**Baseline HEAD:** `9c2ac0b04864cf49fa25af9737640671255792d1` (docs pin Phase 6A.4)  
**Phase 6A.4 feature:** `f3d4a159805a720c4689de5be113ef12aa06f470`  
**Analyzer follow-up:** `07d92103944035ce5a903adb8c0c2c888c265263`  
**Schema at 6B.1 close:** **18**  
**Schema after 6B.1.1:** **19** (goal endpoint eligibility triggers)  
**Baseline tests (6B.1):** **1547** → **1566** at 6B.1 tip  
**Working tree at audit start:** clean  

**Follow-up:** Phase **6B.1.1** closes certificate-account goal eligibility bypasses — see `docs/PHASE_6B_1_1_REPORT.md`. Certificate workflow ownership is a **financial invariant** (INV-004A), not deferred UI behavior.

**Scope:** Structure, boundaries, duplication, and maintainability.  
**Out of scope:** UI redesign (6B.2), gold/investments/liabilities/net worth/Zakat/sadaqah, sync/auth/encryption/backup/PIN/biometrics/notifications/voice/AI/exports, automatic recurring financial transactions.

---

## 1. Priority summary

| Pri | Theme | Evidence | Recommended action |
|-----|-------|----------|-------------------|
| **P0** | Financial correctness risk | No intentional ledger/idempotency/contention defects found that require behavior change in 6B.1 | Document only; characterization first if unclear |
| **P1** | Boundary / ownership | Oversized Drift repos own too many collaborators; schema helpers live in one 1923-line file; eligibility filters duplicated in UI+use cases | Extract collaborators; shared eligibility policies; keep DB authoritative |
| **P2** | Major duplication | Idempotency re-read / contention wrappers; dual money formatters; transfer fingerprint compare; invalidate patterns | Shared idempotency + debit helpers; consolidate formatters; feature-owned invalidators |
| **P3** | Naming / cleanup | Near-identical Goal/Certificate money formatters; large test files | Thin aliases or shared non-negative formatter; split tests by behavior |
| **Deferred → 6B.2** | Presentation size / UX | Large screens (`dashboard_screen` ~905, expense form ~579) | UI redesign phase only |

---

## 2. Layer inventory (production)

Dependency direction (target / enforced):

```
presentation → application → domain
                       ↓
                 repository interfaces

data/infrastructure → domain + repository interfaces
```

| Area | Approx LOC (hand-written) | Notes |
|------|---------------------------|-------|
| `lib/core/database/app_database.dart` | 1923 | Schema 18 entry + all migration/trigger SQL |
| `lib/core/database/app_database.g.dart` | 22870 | Generated — do not hand-edit |
| `lib/core/localization/*` | ~5000 | Generated ARB outputs |
| Ledger feature | ~2566 | Authority for I/E/transfer/opening/adjustment/reversal |
| Goals feature | ~4819 | Reserve-backed savings goals |
| Certificates feature | ~5171 | Fixed-term deposit assets |
| Transactions UI + use cases | ~3969 | Presentation-heavy |
| Reports | ~3938 | Query-only |
| Accounts / budgets / dashboard / household | smaller | See feature sections |

**Domain Flutter/Drift imports:** none observed under `**/domain/**`.  
**Presentation Drift / `AppDatabase`:** none observed.  
**Presentation constructs ledger writes:** no — writes go through use cases → repositories.

---

## 3. Major production files

### 3.1 `lib/core/database/app_database.dart` (~1923)

| Field | Value |
|-------|-------|
| Responsibility | Drift `@DriftDatabase` entry, `schemaVersion => 19`, `MigrationStrategy`, all trigger/index SQL helpers, `_devConnection` |
| Layer | infrastructure / data |
| Deps | Drift, path_provider, table definitions |
| Public types | `AppDatabase` |
| Major methods | `migration` onCreate/onUpgrade; ~35 `_apply*` helpers; constructors |
| Mixed responsibilities | Schema definition + every historical migration trigger pack in one file |
| Forbidden imports | N/A (infrastructure may use Drift) |
| Duplication | Trigger SQL evolved via DROP+recreate across versions (intentional, not copy-paste debt) |
| Testing | Migration / integrity DB suites under `test/database/` |
| Action | **P1** Split helpers into focused part/collaborator files; keep entry point + trigger names + schema 18 |

### 3.2 `lib/features/ledger/data/drift_ledger_repository.dart` (~1285)

| Field | Value |
|-------|-------|
| Responsibility | Authoritative ledger writes + reads; idempotency; balance checks; protected audits |
| Layer | data |
| Deps | `AppDatabase`, `SqliteContentionPolicy`, domain ledger/account types |
| Public types | `DriftLedgerRepository` implements `LedgerRepository` |
| Major methods | `recordIncome/Expense`, `executeTransfer`, `recordOpeningBalance`, `recordAdjustment`, `reverseOperation`, queries, `_checkIdempotency`, `_checkSufficientBalance` |
| Mixed | Idempotency, balance, inserts, mappers, debit contention |
| Duplication | Contention + negative-balance mapping mirrored in goals/certificates |
| Testing | `ledger_repository_db_test`, expense/income/transfer/idempotency/contention suites |
| Action | **P1/P2** Internal collaborators (idempotency, balance, writers); public API unchanged |

### 3.3 `lib/features/goals/data/drift_goal_repository.dart` (~1927)

| Field | Value |
|-------|-------|
| Responsibility | Goal CRUD/lifecycle + goal-associated transfers + reversals |
| Layer | data |
| Deps | Drift DB, contention policy, goal write-boundary types, ledger enums |
| Public types | `DriftGoalRepository` |
| Major methods | `createGoal`, complete/archive/restore, `fundGoalTransfer` / `releaseGoalTransfer` / `reverseGoalTransfer`, lifecycle events |
| Mixed | Lifecycle + financial transfer writer + idempotency |
| Notable | Funding/release persist `operations.type = 'transfer'` (see §10) |
| Testing | Large `goal_repository_test` + phase 5B* integrity suites |
| Action | **P1** Split internal collaborators; preserve tx nesting + contention |

### 3.4 `lib/features/certificates/data/drift_certificate_repository.dart` (~2175)

| Field | Value |
|-------|-------|
| Responsibility | Certificate create/profit/redeem/lifecycle/reversals |
| Layer | data |
| Deps | Drift, contention, `certificate_write_boundary` fingerprints |
| Public types | `DriftCertificateRepository` |
| Major methods | `createCertificate`, `recordProfit`, `redeem`, archive/restore, reverse purchase/profit |
| Mixed | Account insert + ledger ops + events + idempotency recovery |
| Testing | certificate_repository + 6A* suites |
| Action | **P1** Focused internal collaborators; keep fingerprint builders feature-owned |

### 3.5 `lib/features/reports/data/drift_report_query_repository.dart` (~1101)

| Field | Value |
|-------|-------|
| Responsibility | Read-only report queries |
| Layer | data (query) |
| Action | **P3 / defer** — large but query-only; split only if blocking review |

### 3.6 Presentation screens (selected)

| Path | ~LOC | Notes | Action |
|------|------|-------|--------|
| `dashboard/presentation/dashboard_screen.dart` | 905 | Navigation hub + summary | Defer 6B.2 |
| `transactions/.../expense_form_screen.dart` | 579 | Form + eligibility filter | Light P1 eligibility extract only |
| Goal/cert creation/fund/redeem screens | 200–430 | Duplicate eligibility `.where` | P1 policy helper |
| Money formatters (goal + cert) | ~50 each | Identical non-negative policy | P2/P3 consolidate |

---

## 4. Duplication map

| Theme | Locations | Risk | Action |
|-------|-----------|------|--------|
| Scoped op idempotency | Ledger `_checkIdempotency`; goal transfer customSelect; certificate event re-read | Drift of replay/conflict semantics | Shared helper for compare + contention re-read; feature payloads stay feature-owned |
| Debit + contention | Ledger expense/transfer/adjustment/reverse; goal fund/release/reverse; cert create/profit/redeem/reverse | Already uses `runAuthoritativeWriteWithContentionRetry` | Reduce wrapper boilerplate; optional arch test against raw busy bypass |
| Negative-balance → typed insufficient | Ledger / goals / certificates catch blocks | Semantic drift | Shared mapper beside contention policy |
| Account eligibility | Tx use cases + forms; goal fund/create; cert create/profit/redeem | UI-only filter if use case skips | Domain/app policy; DB remains authoritative for restricted types |
| Money format (non-negative → em-dash) | `GoalMoneyFormatter`, `CertificateMoneyFormatter` | Drift | Shared integer-safe formatter |
| Provider invalidation | Goal/cert money vs lifecycle; tx review screens ad-hoc | Over/under invalidate | Feature-owned coordinators (already partly done); txs can adopt similar |
| Payload fingerprint builders | Certificate boundary; goal `_buildIdempotencyPayload` | OK as feature-owned | Keep feature-owned; document |

---

## 5. Operation-type audit (goal funding)

**Current behavior (document only — do not change in 6B.1):**

- Goal funding and release insert `operations.type = 'transfer'`.
- Ledger legs use `transferOut` / `transferIn` entry types.
- Idempotency fingerprints for goal transfers expect `expectedType: 'transfer'`.
- Ordinary household transfers also use `type='transfer'`.
- Goal association is via `goal_movements` (+ contexts), not a distinct operation type.

**Implications:**

- Reports that classify by `operations.type` treat goal funding as transfers (not expense/income) — intentional for cash movement neutrality.
- Distinguishing goal-associated transfers requires joining movements/context, not op type alone.
- Changing persisted type would be a schema/semantics change requiring separate approval and migration — **out of scope**.

**Conclusion:** Not corrupt; **document only**. No persisted-type change in Phase 6B.1.

---

## 6. Idempotency / contention / invalidation

| Concern | Status |
|---------|--------|
| SQLite contention policy | Centralized in `sqlite_contention_policy.dart` |
| Debit paths | Covered by Phase 6A.3/6A.4; use contention retry |
| Certificate event fingerprints | Feature builders in `certificate_write_boundary.dart` |
| Invalidation | Feature money vs lifecycle split for goals/certs; no global invalidate-all |
| Gap | Transaction review screens still inline invalidate lists (P2 cleanup) |

---

## 7. Testing observations

| Item | Observation |
|------|-------------|
| Baseline count | **1547** (Phase 6A.4 equation `1525 + 22 − 0`) |
| Oversized suites | `goal_repository_test.dart` (~5222 LOC / ~112 tests); schema migration suites large |
| Coupling | Some tests use fail-after hooks / barriers on Drift repos (intentional for rollback matrix) |
| Gap | No dedicated architecture-import enforcement tests yet → add in 6B.1 |
| Classification | Prefer Database-tested for financial writers; Unit for pure domain; Widget for screens |

---

## 8. Dead code / obsolete APIs

| Candidate | Verdict |
|-----------|---------|
| Migrations / triggers / enum codes / schema fields | **Keep** — never delete for “unused” appearance |
| Generated l10n keys | **Keep** while present in ARB/generated |
| Smoke / foundation screens | Product scaffolding — leave unless proven unused and approved |
| Near-duplicate formatters | Consolidate carefully; keep thin wrappers if tests import types |

Deleted public APIs in 6B.1 must be listed in `PHASE_6B_1_REPORT.md`.

---

## 9. Recommended 6B.1 execution order

1. This audit + `ARCHITECTURE.md` update  
2. `AppDatabase` schema-helper extraction (schema 18 preserved)  
3. Ledger collaborators + debit/contention standardization  
4. Goal repository collaborators  
5. Certificate repository collaborators  
6. Shared idempotency infrastructure (feature payloads remain)  
7. Account eligibility policies  
8. Provider invalidation cleanup (feature-owned)  
9. Formatting consolidation (integer-safe)  
10. Architecture enforcement tests + selective test splits  
11. `PHASE_6B_1_REPORT.md` + evidence pin  

**Do not:** change financial semantics, redesign UI, expand schema, or begin 6B.2.
