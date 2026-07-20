# Phase 6B.1.2 Report — INV-004A Evidence Closure

**Branch:** `main`  
**Baseline HEAD (pre-6B.1.2):** `1e741dad6ebb55abecd46b17e583e7075922d61c`  
**Code/test commit:** `223b21bab4faa3482094a40fab14164e3882ceb1`  
**Analyzer fix commit:** `4022d988674aaa832f36a9d787416042627f3517`  
**Schema:** **19** (unchanged in this phase)  
**Baseline tests:** **1590**  
**Final tests:** **1594**  
**Equation:** `1590 + 4 − 0 = 1594`

---

## 1. Exact Git history reconciliation

| Item | Value |
|------|-------|
| `pwd` | `/Users/hussam/Desktop/hussam/family_money_manager` |
| Branch | `main` |
| Pre-work HEAD | `1e741dad6ebb55abecd46b17e583e7075922d61c` |
| Working tree (pre-work) | **Clean** |
| Schema | `schemaVersion => 19` |

### Named commit roles

| Full hash | Role | Subject |
|-----------|------|---------|
| `e6bde6105bb2a329b6e799f137c7475c036294ab` | **Feature / work** | `fix: Phase 6B.1.1 – close certificate-account eligibility bypasses` |
| `df1e8721517c770dbfd745ba5d2cc6b1ad4752f3` | **Validation fix** | `fix: Phase 6B.1.1 – schema 19 assertions and prefer_const cleanup` |
| `60516578565b2c98e530f849a770accea3282d83` | **Docs pin (6B.1.1 evidence)** | `docs: pin Phase 6B.1.1 validation evidence and commit hashes` |
| `d690136d215336b3510ffb6ad26cf922744800b0` | **Docs correction** | `docs: correct Phase 6B.1 deferred certificate×goal gap` |

### Why Final HEAD differs from a named documentation-pin commit

A commit that *contains* a “Final HEAD = …” line cannot be the hash written in that same line: writing the tip into the file creates a *new* tip one commit ahead. Phase 6B.1.1 therefore accumulated docs-only pins after `d690136…` (`117eb2b…`, `1e741da…`). That lag is expected; it is not a missing feature commit.

Evidence closure for INV-004A is this phase (6B.1.2). Feature semantics remain those of `e6bde610…` / `df1e872…`.

---

## 2. Release-side database enforcement

### Added in Phase 6B.1.2

File: `test/database/goals/phase_6b11_certificate_goal_eligibility_test.dart`

| Test name | Proves |
|-----------|--------|
| `SQL-R1. Cross-household release destination rejected by trigger` | Other-household destination |
| `SQL-R2. Currency-mismatch release destination rejected by trigger` | Different currency destination |
| `SQL-R3. Certificate-by-type release destination rejected by trigger` | `type = certificate` |
| `SQL-R4. Certificate-by-purpose release destination rejected by trigger` | `fund_purpose = certificate` |

### Cited earlier coverage (not duplicated)

| Requirement | Exact file | Exact test name |
|-------------|------------|-----------------|
| Linked certificate destination | `phase_6b11_certificate_goal_eligibility_test.dart` | `SQL-2. Goal release into cert account is rejected by trigger` |
| Non-spendable destination | same | `SQL-7. Non-spendable ordinary destination rejected on release` |
| Positive control — eligible standard | same | `SQL-P2. Goal release to eligible standard succeeds` |

---

## 3. Authentic migration provenance (18→19)

| Item | Detail |
|------|--------|
| Historical schema-18 tip | `47fd59676d5a9a06ac6d4ea6f9b6ae3c256e4729` (last `schemaVersion => 18` before 6B.1.1) |
| Fixture file | `test/fixtures/schema_v18_objects.sql` (100 trigger/index objects dumped from onCreate at that commit) |
| Helper | `test/helpers/true_schema_v18.dart` → `materializeTrueSchemaV18File()` |
| How physical v18 is created | Drift **table** DDL from a current probe (table shapes unchanged 18→19) + **objects** from the historical fixture; `user_version = 18`; eligibility triggers **never** created on the file |
| Schema 19 not opened before migration | Pre-open asserts via raw `sqlite3`: `user_version == 18` and both eligibility triggers absent; only then `AppDatabase.forFile(path)` |
| Fixture rows | Household `hh-6b11`, accounts `bank-6b11` / `reserve-6b11`, goal `goal-6b11`, revision `rev-6b11`, ops/ledger `op-open-6b11*` / `op-fund-6b11*`, movement `mov-6b11` |
| Post-migration assertions | IDs preserved; `user_version == 19`; triggers `validate_funding_source_eligibility` + `validate_release_destination_eligibility` installed |
| Post-migration behavior | Certificate-type funding **and** release rejected; eligible standard release succeeds (`mov-rel-post`) |
| Test | `MIG-6B11-1. Authentic physical v18→19 preserves IDs and installs eligibility triggers` in `phase_6b11_migration_v18_to_v19_test.dart` (**expanded in place**, not a new test count) |

This is **not** “open schema 19 then delete triggers.”

---

## 4. Exact test reconciliation

**Start:** **1590**

| Change | Count | Notes |
|--------|------:|-------|
| Added | **4** | SQL-R1 … SQL-R4 |
| Removed | **0** | |
| Renamed | **0** | |
| Moved | **0** | |
| Expanded in place | MIG-6B11-1 | provenance + post-migration behavior (same test name) |

**Equation:** `1590 + 4 − 0 = 1594`  
**Passed:** **1594**  
**Failed:** **0**  
**Skipped:** **0**

---

## 5. Exact validation (against committed code/test tip)

Validated on committed tip `4022d988674aaa832f36a9d787416042627f3517` (after feature commit `223b21ba…` + analyzer fix).

| Exact command | Exit code | Result |
|---------------|----------:|--------|
| `dart format --output=none --set-exit-if-changed .` | **0** | 290 files, 0 changed |
| `flutter analyze` | **0** | No issues found (analyzer issue count **0**) |
| `flutter test --reporter=expanded` | **0** | **1594** passed, **0** failed, **0** skipped |

---

## 6. Final committed evidence

| Item | Full hash / value |
|------|-------------------|
| Code/test commit | `223b21bab4faa3482094a40fab14164e3882ceb1` — `test: Phase 6B.1.2 – release eligibility evidence and authentic v18 fixture` |
| Analyzer fix | `4022d988674aaa832f36a9d787416042627f3517` — `fix: Phase 6B.1.2 – clear analyzer underscore lint on local helper` |
| Documentation commit | *(this report commit — filled at pin)* |
| Final HEAD | *(filled at pin)* |
| `git status --short` | *(clean after pin)* |

---

## 7. Scope

- No UI redesign
- Phase 6B.2 **not** started
- No gold / investments / liabilities / net worth / Zakat / sync / security / backup / notifications / voice / AI / exports / recurring execution
- No mobile builds or device tests

---

## 8. Paths

| Doc | Path |
|-----|------|
| This report | `docs/PHASE_6B_1_2_REPORT.md` |
| Prior phase | `docs/PHASE_6B_1_1_REPORT.md` |
| Phase 6B.1 | `docs/PHASE_6B_1_REPORT.md` |
| Invariant | `docs/FINANCIAL_INVARIANTS.md` (INV-004A) |
