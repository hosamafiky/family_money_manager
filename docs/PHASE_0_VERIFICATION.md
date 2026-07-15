# Phase 0 Verification

**Version:** 0.1.1-phase0-verification  
**Date:** 2026-07-15  
**Purpose:** Requirements traceability, gap analysis, and correction record for Phase 0

---

## 1. Repository State Evidence

### Project root

```
/Users/hussam/Desktop/hussam/family_money_manager/
```

### Directory tree (as of verification)

```
family_money_manager/
└── docs/
    ├── ARCHITECTURE.md
    ├── DATA_MODEL.md
    ├── DECISIONS.md
    ├── FINANCIAL_INVARIANTS.md
    ├── FINANCIAL_MODEL.md
    ├── FIRESTORE_RULES_PLAN.md
    ├── FIRESTORE_SCHEMA.md
    ├── LOCALIZATION_GUIDE.md
    ├── LOCAL_DATABASE_SCHEMA.md
    ├── OFFLINE_SYNC_STRATEGY.md
    ├── PHASE_0_VERIFICATION.md   ← this document
    ├── PRODUCT_SPEC.md
    ├── RELEASE_CHECKLIST.md
    ├── SECURITY_THREAT_MODEL.md
    ├── TEST_STRATEGY.md
    ├── USER_JOURNEYS.md
    └── USER_PERSONAS.md
```

### Flutter project status

No Flutter project exists. No `.dart` files, no `pubspec.yaml`, no `android/`, no `ios/`, no `lib/`, no generated platform code, no database files, no Firestore rules file, and no feature implementation files are present.

Status: **Documentation-only. Correct.**

### Git status

The `family_money_manager/` directory is **not a Git repository**. No `.git` directory exists. `git status` returns `fatal: not a git repository`.

Git status: **Not a Git repo. No commits. No tracked files.**

This is acceptable for Phase 0. Phase 1 will initialize the repository.

---

## 2. Reference Project Evidence

Two projects at the workspace root are considered reference projects:

### money_tracker

```
Path:   /Users/hussam/Desktop/hussam/money_tracker/
Branch: main
HEAD:   f1d7e78 feat(transfers): implement transfer reversal functionality...
git diff HEAD: (empty — no modifications)
git diff --name-status HEAD: (no output)
```

**Status: Unmodified. Verified via git diff.**

### money_tracker_next

```
Path:   /Users/hussam/Desktop/hussam/money_tracker_next/
Branch: main
HEAD:   4271241 fix: close certificate lifecycle application audit gaps

git status --short:
 M lib/core/financial/application/use_cases/record_certificate_funding_use_case.dart
 M lib/core/financial/application/use_cases/record_certificate_maturity_use_case.dart
 M test/helpers/financial_application_test_support.dart

git diff --name-status HEAD:
M  lib/core/financial/application/use_cases/record_certificate_funding_use_case.dart
M  lib/core/financial/application/use_cases/record_certificate_maturity_use_case.dart
M  test/helpers/financial_application_test_support.dart

SHA-256 hashes (recorded at Phase 0 verification time, 2026-07-15):
  875ab96d...  record_certificate_funding_use_case.dart
  460fe863...  record_certificate_maturity_use_case.dart
  adb0ca09...  financial_application_test_support.dart
```

**Status: 3 uncommitted local modifications exist in money_tracker_next.**

These modifications were present in the working tree at the time Phase 0 verification was performed. The cause of these modifications is **unknown and cannot be attributed from the available evidence**. Phase 0 work wrote only to `/Users/hussam/Desktop/hussam/family_money_manager/docs/`. No write, format, generate, stage, commit, revert, or cleanup tool call was made against any file in either reference repository during Phase 0 or Phase 0 verification.

money_tracker: **Unmodified.** Verified via clean `git diff HEAD` output.  
money_tracker_next: **3 local modifications of unknown cause.** SHA-256 hashes recorded above for Phase 1 comparison.

---

## 3. Requirements Traceability Table

Each Phase 0 deliverable is mapped to the document and section that covers it.

| Required Deliverable | Covered By | Section / Heading | Coverage Assessment |
|---|---|---|---|
| Product specification | `PRODUCT_SPEC.md` | All sections | Complete |
| Feature inventory | `PRODUCT_SPEC.md` | Section 6 (Feature Inventory) | Complete |
| User journeys | `USER_JOURNEYS.md` | Journeys 1–12 | Complete |
| Financial model | `FINANCIAL_MODEL.md` | All sections | Gaps identified — see Section 4 below |
| Financial invariants | `FINANCIAL_INVARIANTS.md` | INV-001 through INV-018 | Complete; language corrections required |
| Data model | `DATA_MODEL.md` | Sections 2–6 | Complete |
| Architecture | `ARCHITECTURE.md` | Sections 1–13 | Phase plan requires correction |
| Local database design | `LOCAL_DATABASE_SCHEMA.md` | Sections 2–6 | Complete |
| Offline synchronization | `OFFLINE_SYNC_STRATEGY.md` | Sections 1–13 | Idempotency precision gaps; protected-child sync path missing |
| Security threat model | `SECURITY_THREAT_MODEL.md` | T-01 through T-14 | Language overstatements; otherwise complete |
| Firestore schema | `FIRESTORE_SCHEMA.md` | Sections 3–7 | Complete |
| Firestore-rules strategy | `FIRESTORE_RULES_PLAN.md` | Sections 2–8 | Complete |
| Test strategy | `TEST_STRATEGY.md` | Sections 1–11 | Complete |
| Dependency shortlist | `ARCHITECTURE.md` | Section 10 (Key Packages) | Present; not a standalone document but adequately covered |
| Implementation plan | `ARCHITECTURE.md` | Section 13 (CI/CD) + implied by phase descriptions | Weak: no standalone implementation-phases plan document; phase descriptions exist in the original spec. Phase plan requires correction. |
| Open product decisions | `DECISIONS.md` | DECISION-001 through DECISION-015 | SQLCipher deadline requires correction |

### Gaps identified

| Gap | Severity | Document | Action |
|---|---|---|---|
| Cross-currency policy not formally documented | High | `FINANCIAL_MODEL.md` | Add dedicated section |
| External money-flow boundary not defined | High | `FINANCIAL_MODEL.md` | Add section |
| Historical account-metadata change policy absent | High | `FINANCIAL_MODEL.md` | Add section |
| Reversal specification incomplete | High | `FINANCIAL_MODEL.md` | Add section |
| Gold: quantity vs. monetary account distinction unclear | Medium | `FINANCIAL_MODEL.md` | Clarify |
| Liability: ledger account vs. position record not specified | Medium | `FINANCIAL_MODEL.md` | Clarify |
| Idempotency key scope and multi-device shape not precise | High | `OFFLINE_SYNC_STRATEGY.md` | Add section |
| Protected-child enforcement not listed for all write paths | High | `FINANCIAL_INVARIANTS.md` | Add section |
| Phase 1 scope includes `Money` type (should be Phase 2) | High | `ARCHITECTURE.md` | Correct |
| SQLCipher decision deadline is "Before Phase 11" (too late) | High | `DECISIONS.md` | Move to "Before Phase 2" |
| Implementation plan has no explicit phased delivery table | Medium | New section in `ARCHITECTURE.md` | Add |
| No standalone `IMPLEMENTATION_PLAN.md` | Low | — | Acceptable in `ARCHITECTURE.md` |

### Duplicated or contradictory coverage

| Issue | Documents | Resolution |
|---|---|---|
| SQLCipher "effort is small" asserted without spike | `ARCHITECTURE.md` sec 3, `DECISIONS.md` DECISION-004 | Remove assertion; defer to spike |
| "Structurally impossible" and similar language overstates current state | Multiple | Corrected in Section 5 of this document; all occurrences replaced in source docs |
| Phase 1 scope in the original specification mentions `Money type` under foundation; ARCHITECTURE.md's structure lists `money.dart` under `core/financial/` without phase assignment | `ARCHITECTURE.md` | Phase 2 boundary clarified in ARCHITECTURE.md |

---

## 4. Financial Model Gap Analysis

### 4.1 Cross-currency policy — Status before correction

The financial model stated only: *"Future multi-currency: exchange rate records will be added; cross-currency transfers will require an explicit rate."*

This is insufficient. The transfer-neutrality invariant (INV-003) was expressed using a proof (`debit(source) + credit(destination)`) that silently assumes equal minor units in the same currency. The proof breaks if accounts hold different currencies.

**Correction:** A formal V1 cross-currency prohibition has been added to `FINANCIAL_MODEL.md`. See Section 19.

### 4.2 External money flows — Status before correction

The original text mentioned "system equity account (not user-visible)" for opening balances and income, but did not formally define the household financial boundary, how income enters the system, how expenses leave it, or how gifts and sadaqah are classified.

**Correction:** A dedicated external-flows section added to `FINANCIAL_MODEL.md`. See Section 20.

### 4.3 Historical ownership and metadata changes — Status before correction

No policy was defined for what happens to historical reports when an account's `ownerType`, `fundPurpose`, `isProtected`, `includeInNetWorth`, or `includeInZakat` is changed after transactions have been recorded.

**Correction:** Section 21 added to `FINANCIAL_MODEL.md`. Policy: account metadata changes are effective forward-only; historical ledger entries retain the account ID they were recorded against; reports use account metadata as it exists at query time, except for zakat and net-worth historical snapshots which must snapshot the relevant flags at calculation time.

### 4.4 Reversals — Status before correction

Only one sentence addressed reversals: *"Corrections are made through reversal entries."* No policy existed for duplicate reversal prevention, partial reversals, reversal of multi-leg operations, or treatment of reversed operations in reports.

**Correction:** Section 22 added to `FINANCIAL_MODEL.md`.

### 4.5 Gold model — Status before correction

The model used a `goldHolding` account whose balance equals the purchase price. This is correct but was not clearly distinguished from a physical-quantity tracking model, creating a risk of confusion between:
- The monetary balance of the gold account (cost basis in EGP)
- The physical quantity (grams / milligrams)
- The current market value
- Realized and unrealized gains

**Correction:** Section 23 added to `FINANCIAL_MODEL.md` clarifying the dual representation.

### 4.6 Liability model — Status before correction

The model did not clarify whether liabilities use ledger accounts (with debit/credit entries) or only position records (a separate `liabilities` table with an outstanding amount field). Both patterns exist in financial software and they have different implications for the net-worth formula.

**Correction:** Section 24 added to `FINANCIAL_MODEL.md`.

---

## 5. Language Correction Record

The following specific overstatements were found and corrected in source documents. Each entry lists the file, original text, and replacement.

All corrections replace present-tense implementation claims with planning language using one of:
- **"Proposed design:"** — architectural choice not yet implemented
- **"Planned:"** — intended behavior of future code
- **"Requirement:"** — a rule the implementation must satisfy
- **"Planned test:"** — a test case that will verify this

### FINANCIAL_INVARIANTS.md

| Original | Corrected |
|---|---|
| `trigger-enforced in SQLite` | `proposed to be enforced via a SQLite trigger (planned)` |
| `Firestore rules enforce the same check` | `Firestore rules are designed to enforce the same check (planned)` |
| `The constraint is enforced at the repository contract level` | `The constraint is designed to be enforced at the repository contract level` |
| `Audit history is always visible` | `The design requires that audit history remains visible` |

### FINANCIAL_MODEL.md

| Original | Corrected |
|---|---|
| `Idempotency is enforced:` | `Idempotency is planned to be enforced:` |
| `Transfers do not change net worth. This is enforced by design:` | `Transfers are designed not to change net worth. The mechanism is:` |
| `Can only be created once per account (enforced by the ledger).` | `Required to be created only once per account. The ledger implementation must enforce this.` |
| `This balance must always equal the actual cash Hana holds.` | `This balance is required to equal the actual cash held, as a design invariant to be enforced by the implementation.` |

### LOCAL_DATABASE_SCHEMA.md

| Original | Corrected |
|---|---|
| `No UPDATE or DELETE is permitted on... tables (enforced via trigger).` | `No UPDATE or DELETE is to be permitted on... tables. A planned SQLite trigger will enforce this.` |
| `must always be 1; enforced by CHECK constraint` | `required to always be 1; a planned CHECK constraint will enforce this` |

### SECURITY_THREAT_MODEL.md

| Original | Corrected |
|---|---|
| `Idempotency is enforced at every layer.` | `Idempotency is designed to be enforced at every layer.` |
| `production flag enforced by build configuration` | `production flag is intended to be enforced by build configuration` |
| `Rate limiting is enforced server-side per user.` | `Rate limiting is planned server-side per user.` |
| `This method enforces audit creation as part of the same SQLite transaction.` | `This method is designed to enforce audit creation as part of the same SQLite transaction.` |
| `The constraint is enforced at the repository contract level, not just in the UI.` | `The constraint is designed to be enforced at the repository contract level, not just in the UI.` |

### OFFLINE_SYNC_STRATEGY.md

| Original | Corrected |
|---|---|
| `The server's Firestore rules already enforced validation at write time.` | `The server's Firestore rules are designed to enforce validation at write time.` |

### DATA_MODEL.md

| Original | Corrected |
|---|---|
| `must be true; app enforces this` | `required to be true; the planned implementation must enforce this` |

### ARCHITECTURE.md

| Original | Corrected |
|---|---|
| `## 2. Dependency Graph (enforced)` | `## 2. Dependency Graph (planned; to be enforced by code review and linter rules)` |

---

## 6. Protected-Child Write Path Inventory

See the updated `FINANCIAL_INVARIANTS.md` INV-006 for the complete list of write paths that must enforce protected-child withdrawal requirements.

The following paths were **missing** from the original INV-006 and have been added:

| Write Path | Was Documented | Added |
|---|---|---|
| Normal withdrawal via repository | Yes | — |
| Adjustment (adjustmentDebit) on child account | No | Added |
| Reversal of a child-fund deposit | No | Added |
| Sync download applying remote child-account debit | No | Added |
| Backup import containing child-account debit | No | Added |
| Schema migration that modifies account type | No | Added |
| Repair or administrative ledger tool | No | Added |
| Asset purchase funded from child account | No | Added |
| Certificate funding from child account | No | Added |
| Liability repayment from child account | No | Added |
| Goal funding from child account | No | Added |
| Transfer out of child account (including to non-child account) | No | Added |

---

## 7. Idempotency and Sync Precision Gaps

The original `OFFLINE_SYNC_STRATEGY.md` described the sync queue and Firestore existence checks but did not document:

- Exact idempotency key scope (operation ID vs. ledger entry ID)
- How partially uploaded multi-leg operations are detected
- Deterministic conflict resolution procedure
- Interaction between backdated entries and sync ordering
- Interaction between backup import and sync queue

These gaps are corrected in `OFFLINE_SYNC_STRATEGY.md` Section 14 (new).

---

## 8. Phase Plan Corrections

### Phase 1 boundary (before correction)

The ARCHITECTURE.md project structure listed `money.dart` (Money value type) under `core/financial/` without phase assignment. The original Phase 0 specification included "Money type" explicitly in Phase 1 (foundation). This creates ambiguity.

### Phase 1 boundary (after correction)

Phase 1 contains **no financial domain code**. Specifically deferred to Phase 2:

- `Money` value type
- All `core/financial/` implementations
- All Drift table definitions for financial entities
- All ledger entry types
- Balancing logic
- Transfers
- Opening balances
- Adjustments
- Reversals
- Audit events
- Historical balance calculations
- Financial invariant tests

Phase 1 may include the Drift database package configuration (driver, connection, WAL pragma) but no financial table definitions.

### Project creation safety note

The `family_money_manager/` root directory already exists and contains Phase 0 documents in `docs/`. The Phase 1 implementation must NOT run `flutter create family_money_manager` from the parent directory, as this would either fail (directory exists) or overwrite docs. The correct approach is to run `flutter create .` from inside the existing root, or use `flutter create --project-name family_money_manager .` from within the existing directory. This must be verified before execution.

---

## 9. SQLCipher Decision Timeline (before correction)

The original `DECISIONS.md` listed the SQLCipher deadline as "Before Phase 11." This is incorrect. The database driver selection and encryption approach must be decided before any financial Drift table is defined — which occurs in Phase 2. Changing from an unencrypted SQLite driver to SQLCipher after tables are created requires:

- Migrating an existing plaintext database to encrypted format (complex)
- Changing the Flutter dependency and native platform configuration
- Updating backup and restore to handle both encrypted and plaintext databases

**Corrected deadline: Before Phase 2 begins.**

The corrected `DECISIONS.md` DECISION-004 also documents the full impact of the SQLCipher choice (driver, key storage, PIN integration, migration, backup, key rotation, recovery, testing, platform configuration).

---

## 10. Claim Classification

Every major claim in the Phase 0 documents is classified as:

| Claim category | Status |
|---|---|
| Financial model design | **Documented only** |
| Financial invariants | **Documented only** |
| Firestore rules | **Documented only** |
| Local database schema | **Documented only** |
| Security mitigations | **Documented only** |
| Sync strategy | **Documented only** |
| Test plan | **Documented only** |
| Architecture | **Documented only** |
| Any actual code | **None exists** |
| Any test execution | **None executed** |
| Any build verification | **Not run** |
| Any device testing | **Not run** |
| Any Firebase emulator test | **Not run** |
| Any Firestore rule enforcement | **Not implemented** |
| Any SQLite trigger | **Not implemented** |
| Any PIN hashing | **Not implemented** |
| Any financial invariant check | **Not implemented** |

Phase 0 is complete as a documentation phase only. No behavioral guarantees exist until Phase 2 tests are written and pass.

---

## 11. Commands Executed During Verification

```bash
find /Users/hussam/Desktop/hussam/family_money_manager -type f | sort
find /Users/hussam/Desktop/hussam/family_money_manager -name "*.dart"
git -C /Users/hussam/Desktop/hussam/family_money_manager status --short
git -C /Users/hussam/Desktop/hussam/money_tracker diff --name-status HEAD
git -C /Users/hussam/Desktop/hussam/money_tracker_next diff --name-status HEAD
git -C /Users/hussam/Desktop/hussam/money_tracker log --oneline -3
git -C /Users/hussam/Desktop/hussam/money_tracker_next log --oneline -3
grep -rn [overstatement patterns] /docs/*.md
```

## 12. Commands Not Executed

```bash
dart format ...
flutter analyze
flutter test
flutter build apk
flutter build ios
firebase emulators:exec
```

These are not applicable in Phase 0 (no code exists).
