# Phase 6B.1 Report — Structural Refactor (No UI Redesign)

**Branch:** `main`  
**Final HEAD (docs pin):** `5216dabc905a4569735ddb524cfd01f80fe5479a`  
**Baseline HEAD:** `9c2ac0b04864cf49fa25af9737640671255792d1` (Phase 6A.4 docs pin)  
**Phase 6A.4 feature:** `f3d4a159805a720c4689de5be113ef12aa06f470`  
**Analyzer follow-up (6A.4):** `07d92103944035ce5a903adb8c0c2c888c265263`  
**Schema:** **18** (unchanged)  
**Baseline tests:** **1547**  
**Final tests:** **1566**  
**Equation:** `1547 + 19 − 0 = 1566`

---

## 1. Exact baseline (pre-work)

| Item | Value |
|------|-------|
| `pwd` | `/Users/hussam/Desktop/hussam/family_money_manager` |
| Branch | `main` |
| HEAD | `9c2ac0b04864cf49fa25af9737640671255792d1` |
| Working tree | **Clean** |
| Schema | `schemaVersion => 18` |
| Tests | **1547** |

---

## 2. Commits (reviewable by concern)

| Hash | Message |
|------|---------|
| `83bc7c6` | docs: Phase 6B.1 refactor audit and as-built architecture |
| `4bfca57` | refactor: extract AppDatabase schema helpers into focused mixins |
| `06e2ce2` | refactor: extract ledger write support and shared idempotency helpers |
| `6adf8d9` | refactor: standardize goal/certificate idempotency fingerprint decisions |
| `0cfe675` | refactor: consolidate eligibility, money formatting, and tx invalidation |
| `06eaee1` | test: add architecture boundary guards and refactor unit coverage |
| `08b2439` | style: dart format AppDatabase schema helper parts |
| `a7b167b` | docs: Phase 6B.1 report and validation evidence |
| `4dd019d` / `acee573` / `8f83cc2` / `5216dab` | docs: pin / correct / finalize Phase 6B.1 report evidence |

**Feature/work HEAD (pre-report):** `08b24397f70920a0126a9932736f759dff38f5cf`  
**Report body:** `a7b167b5a4a46f07555ab696efb87c2c8912959c`  
**Docs pin HEAD:** `5216dabc905a4569735ddb524cfd01f80fe5479a`

---

## 3. Top P1 / P2 items fixed

| Pri | Item | Status |
|-----|------|--------|
| P1 | Oversized `AppDatabase` (1923 LOC) owning all triggers | **Fixed** — library-private mixins in `lib/core/database/schema/` |
| P1 | Ledger repo mixed idempotency/balance/writers | **Fixed** — `LedgerWriteSupport` collaborator; public `LedgerRepository` unchanged |
| P1 | Account eligibility only scattered in UI/use cases | **Fixed** — `AccountEligibility` + `ordinaryEndpointFailure`; DB remains authoritative |
| P2 | Idempotency fingerprint compare duplication | **Fixed** — `scoped_idempotency.dart`; feature payload builders remain feature-owned |
| P2 | Dual non-negative money formatters | **Fixed** — `NonNegativeMoneyFormatter`; thin goal/cert wrappers preserved |
| P2 | Transaction review invalidation ad-hoc | **Fixed** — `invalidateTransactionMoneyProviders` (feature-owned; not global invalidate-all) |
| P2 | No architecture import guards | **Fixed** — `test/unit/architecture/architecture_boundaries_test.dart` |

**Not expanded into mega-managers:** no “financial operation manager”; collaborators stay internal to data layer.

---

## 4. Files split / moved / added / removed

### Added
- `docs/REFACTOR_AUDIT.md`
- `lib/core/database/schema/app_database_core_schema.dart`
- `lib/core/database/schema/app_database_goal_schema.dart`
- `lib/core/database/schema/app_database_certificate_schema.dart`
- `lib/core/database/scoped_idempotency.dart`
- `lib/features/ledger/data/ledger_write_support.dart`
- `lib/core/presentation/non_negative_money_formatter.dart`
- `lib/features/accounts/domain/account_eligibility.dart`
- `lib/features/accounts/application/account_eligibility_results.dart`
- `test/unit/architecture/architecture_boundaries_test.dart`
- `test/unit/core/database/scoped_idempotency_test.dart`
- `test/unit/features/accounts/account_eligibility_test.dart`
- `test/unit/core/presentation/non_negative_money_formatter_test.dart`
- `docs/PHASE_6B_1_REPORT.md` (this file)

### Modified (high-signal)
- `docs/ARCHITECTURE.md` — rewritten as-built (6B.1)
- `lib/core/database/app_database.dart` — entry + MigrationStrategy; mixins via `with`
- `lib/features/ledger/data/drift_ledger_repository.dart` — façade over `LedgerWriteSupport`
- Goal/certificate Drift repos — shared fingerprint decisions; goal transfer type documented
- Transaction use cases / forms / review screens — eligibility + invalidation
- Goal/certificate money formatters — delegate to shared formatter
- `sqlite_contention_policy.dart` — `mapNegativeBalanceAbortOrNull`

### Removed public APIs
- **None.** Thin wrappers (`GoalMoneyFormatter`, `CertificateMoneyFormatter`) retained for call-site stability.

### Test file splits
- **None** in this phase (oversized suites deferred; coverage not reduced). New unit/arch tests only.

---

## 5. Operation-type audit — goal funding

| Question | Conclusion |
|----------|------------|
| Current persisted type | `operations.type = 'transfer'` for funding/release |
| Legs | `transferOut` / `transferIn` |
| Association | `goal_movements` (+ contexts), not a distinct op type |
| Corrupt? | **No** |
| Action in 6B.1 | **Document only** (see `goal_transfer_write_boundary.dart` + `REFACTOR_AUDIT.md` §5) |
| Persisted-type change | **Not done** (would need separate approval + migration) |

**Classification:** Documented only (characterization via existing DB suites remains Database-tested for transfer behavior).

---

## 6. Schema / triggers / semantics

| Constraint | Result |
|------------|--------|
| Schema version 18 | **Preserved** |
| Trigger/index names | **Preserved** (SQL moved, not rewritten) |
| Generated Drift | Untouched (`app_database.g.dart`) |
| Ledger / goal / certificate / idempotency / contention / currency / report / reversal / lifecycle semantics | **Intentionally unchanged** |
| Routes / visible l10n wording | **Unchanged** (no redesign) |

---

## 7. Test reconciliation

| Change | Count | Notes |
|--------|------:|-------|
| Baseline | 1547 | Phase 6A.4 |
| Added | +19 | Arch (8) + scoped idempotency (5) + eligibility (3) + formatter (3) |
| Removed | 0 | — |
| Renamed/moved/split | 0 | — |
| Classification changes | 0 | New tests are Unit-tested (arch = static Unit-tested) |
| **Final** | **1566** | `1547 + 19 − 0 = 1566` |

Financial integrity suites (ledger, goals, certificates, contention, reversals) retained.

---

## 8. Validation evidence

```text
dart format --output=none --set-exit-if-changed .   # exit 0
flutter analyze                                       # exit 0; No issues found
flutter test --reporter=expanded                      # 1566 passed; 0 failed
```

Schema grep: `int get schemaVersion => 18;`

---

## 9. Claim classification matrix (representative)

| Claim | Classification |
|-------|----------------|
| Schema remains 18 after helper extraction | Unit-tested (arch) + Database-tested (existing migration suites exercised earlier) |
| Ledger write support preserves expense/transfer/idempotency | Database-tested (ledger + idempotency suites in full run) |
| Scoped fingerprint decide(replay/conflict) | Unit-tested |
| Goal funding type=`transfer` documented only | Documented only |
| Account eligibility shared policy | Unit-tested; application wiring Fake/Database via existing suites |
| Domain Flutter/Drift-free; presentation no Drift | Unit-tested (architecture scan) |
| Debit writers use contention retry | Unit-tested (architecture scan) + Database-tested (existing 6A suites) |
| Non-negative money formatting integer-safe | Unit-tested |
| No UI redesign / no prohibited Phase 6B.2+ features | Documented only (scope scan) |

---

## 10. Scope scan — prohibited / deferred work

**Not implemented in 6B.1 (correctly deferred):**
- UI redesign / design system restyle → **6B.2**
- Gold, investments, liabilities, net worth, Zakat, sadaqah
- Sync, auth, encryption activation, backup, PIN, biometrics
- Notifications, voice, AI, exports
- Automatic recurring financial execution
- Schema bump beyond 18
- Intentional ledger/goal/certificate semantic changes

**Gaps deferred to 6B.2 / later:**
- Large presentation screens (dashboard ~905, expense form ~579) — structure only when redesigning
- Further splitting `drift_goal_repository` / `drift_certificate_repository` into more collaborators (idempotency standardized; full file split optional)
- Splitting oversized DB test files (`goal_repository_test.dart` etc.) by behavior
- Report query repo (~1101) size — query-only, low priority

**Corrected after 6B.1 (not deferred UI):** Certificate accounts as goal funding sources / release destinations are forbidden as a **financial invariant** (INV-004A). Phase **6B.1.1** closed the bypass across eligibility, use cases, repository, UI filters, and schema-19 DB triggers — see `docs/PHASE_6B_1_1_REPORT.md`. Do not treat certificate×goal endpoint ownership as optional presentation polish.

---

## 11. Paths

| Doc | Path |
|-----|------|
| Refactor audit | `docs/REFACTOR_AUDIT.md` |
| Architecture | `docs/ARCHITECTURE.md` |
| This report | `docs/PHASE_6B_1_REPORT.md` |
| Phase 6B.1.1 follow-up | `docs/PHASE_6B_1_1_REPORT.md` |

---

## 12. Stop condition

Phase **6B.1 complete** (refactor). Certificate×goal endpoint ownership closed in **Phase 6B.1.1** — see `PHASE_6B_1_1_REPORT.md`. Do **not** begin Phase 6B.2 UI redesign in this phase.