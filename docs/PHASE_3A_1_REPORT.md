# Phase 3A.1 Implementation Report — Household and Account Management Hardening

**Commit**: phase 3A.1: household and account management hardening  
**Date**: 2026-07-16  
**Branch**: main  
**Base**: Phase 3A (458 tests)

---

## Summary

Phase 3A.1 hardens the data-integrity guarantees introduced in Phase 3A.  
All ten sections address gaps that existed between application-layer constraints and actual database enforcement, idempotency coverage, and typed error contracts.

---

## Validation Results

| Command                                             | Exit Code | Result               |
| --------------------------------------------------- | --------- | -------------------- |
| `dart format --output=none --set-exit-if-changed .` | 0         | 0 files changed      |
| `flutter analyze`                                   | 0         | No issues found      |
| `flutter test`                                      | 0         | 532/532 tests passed |

**Test count: 458 → 532 (+74 tests)**

---

## Section-by-Section Changes

### §1 — Result Model Consolidation

**Policy:** `AppResult<T>` is the single application-layer contract for all use cases. `Result<T>` (`Ok`/`Err`) remains available for domain-layer utilities but use cases MUST return `AppResult<T>`.

**Added:**

- `test/unit/core/application/app_result_test.dart` — 16 tests covering every variant and pattern-matching exhaustiveness.

### §2 — Balance Query Semantics

`BalanceQueryResult` and `balanceForAccount` were already implemented in Phase 3A. This section adds tests proving the contract holds in all edge cases.

**Added:**

- `test/database/balance_semantics_db_test.dart` — 5 tests:
  - No ledger entries → `BalanceFound(minorUnits: 0)`
  - Income entry → `BalanceFound(minorUnits: N)`
  - Unknown account → `BalanceAccountNotFound`
  - Account in different household → `BalanceAccountNotFound` (non-disclosing)
  - Archived account → `BalanceFound` (history preserved)

### §3 — Household Cardinality Constraints

**Added DB triggers via `AppDatabase._applyHouseholdConstraintTriggers()`:**

- `one_primary_user_per_household` — BEFORE INSERT trigger; prevents a second active primary_user per household.
- `one_spouse_per_household` — BEFORE INSERT trigger; prevents a second active spouse per household (V1 constraint).
- `no_cross_household_member` — BEFORE INSERT trigger; requires household_id to reference an existing household row.

**Added:**

- `test/database/household_cardinality_db_test.dart` — 7 tests validating all trigger conditions.

### §4 — Account-Creation Idempotency

**Schema change:** Added `idempotency_key TEXT` and `idempotency_payload TEXT` (both nullable) to `financial_accounts`.

**Added unique partial index:** `idx_financial_accounts_idempotency ON financial_accounts(household_id, idempotency_key) WHERE idempotency_key IS NOT NULL`

**Updated `CreateAccountUseCase.execute`:**

1. If `idempotencyKey` provided → query `financial_accounts` for matching `(householdId, idempotencyKey)`.
2. Found + payload matches → `AppOk(existingAccount)` (idempotent).
3. Found + payload differs → `AppDuplicateConflict`.
4. Not found → create with `idempotency_key` + `idempotency_payload` stored.

**Payload fingerprint fields** (stable non-localized codes): `name|type|ownerType|fundPurpose|currencyCode|isSpendable|isProtected|includeInNetWorth|includeInZakat|openingBalanceMinorUnits`

**Updated:**

- `lib/core/database/tables/financial_accounts_table.dart` — added two nullable columns.
- `lib/features/accounts/domain/financial_account.dart` — added `idempotencyKey` + `idempotencyPayload` to `CreateAccountParams`.
- `lib/features/accounts/data/account_repository.dart` — added `findByIdempotencyKey` to interface.
- `lib/features/accounts/data/drift_account_repository.dart` — implemented `findByIdempotencyKey`; `createAccount` stores both fields.
- `lib/features/accounts/application/create_account_use_case.dart` — full idempotency check logic.

**Added:**

- `test/database/account_creation_idempotency_db_test.dart` — 6 tests.

### §5 — Account + Opening Balance Atomicity

`CreateAccountUseCase` already used `AppDatabase.transaction()`. Tests prove the atomic guarantee.

**Added:**

- `test/database/account_atomicity_db_test.dart` — 5 tests:
  - Zero opening balance → account only, no operations, no ledger entries.
  - Null opening balance → same.
  - Non-zero opening balance → account + exactly 1 operation + ≥1 ledger entry.
  - Idempotency key retry → existing account returned, no extra rows.
  - Invalid params (empty name) → `AppValidationFailure`, no DB write.

### §6 — Cross-Currency Totals

**Added `AccountTotalsService`** — pure computation class, no Flutter or Drift dependencies.

- Never aggregates across currencies.
- Returns one `CurrencyTotal` per distinct non-archived currency code.
- Archived accounts are excluded.
- Separate `spendableMinorUnits` and `protectedMinorUnits` totals per currency.

**Added:**

- `lib/features/accounts/application/account_totals_service.dart`
- `test/unit/features/accounts/account_totals_service_test.dart` — 10 tests including JPY (scale 0) and KWD (scale 3).

### §7 — Historical Metadata Enforcement

**Added DB trigger `immutable_account_type_currency`:**

```sql
CREATE TRIGGER IF NOT EXISTS immutable_account_type_currency
BEFORE UPDATE ON financial_accounts
WHEN OLD.type != NEW.type OR OLD.currency_code != NEW.currency_code
BEGIN
  SELECT RAISE(ABORT, 'Account type and currency are immutable after creation');
END
```

**Added:**

- `test/database/historical_metadata_db_test.dart` — 4 tests:
  - Direct SQL UPDATE of `type` → `SqliteException`.
  - Direct SQL UPDATE of `currency_code` → `SqliteException`.
  - UPDATE of `name` → succeeds (mutable field).
  - UPDATE of `is_protected` after ledger entries → `ClassificationImmutabilityError` (repo layer).

### §8 — Archive Rules

**Added `ArchivedAccountError`** to `lib/features/accounts/data/account_repository.dart`.

**Updated `DriftLedgerRepository._requireAccount`:** Throws `ArchivedAccountError` when the account row has `is_archived = 1`. This prevents new income, expense, opening balance, adjustment, and transfer operations on archived accounts.

**Updated `CreateAccountUseCase`:** Catches `ArchivedAccountError` and returns `AppValidationFailure`.

**Known gap (documented):** Member-account linkage for Phase 3A uses `ownerType` enum, not a foreign key to `household_members`. The check that archived members cannot own new accounts is deferred to when a members FK is added.

**Added:**

- `test/database/archive_rules_db_test.dart` — 8 tests covering all required scenarios.

### §9 — Migration Verification

**Schema bumped: v3 → v4.** Migration `onUpgrade` adds:

- `idempotency_key` and `idempotency_payload` columns to `financial_accounts`.
- Household cardinality triggers.
- Immutable type/currency trigger.
- Account idempotency partial index.

**Added:**

- `test/database/migration_db_test.dart` — 5 tests (fresh schema, data preservation, nullable columns, null key non-conflict).

### §10 — Onboarding Initialization

**Added `InitializeHouseholdUseCase`** to `lib/features/household/application/household_use_cases.dart`.

- Fixed IDs: `household-v1` and `member-primary-v1`.
- Idempotent: second call returns existing household.
- Validates `householdName` and `primaryMemberName` before any DB write.

**Added:**

- `test/unit/features/household/initialize_household_use_case_test.dart` — 4 tests.

---

## Schema Version History

| Version | Phase      | Changes                                                                                                                                                  |
| ------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1       | Phase 2    | Initial schema (5 tables, immutability triggers, indexes)                                                                                                |
| 2       | Phase 2A   | `operations.idempotency_key`; restricted-update trigger; FK-enforcement triggers; CHECK-enforcement triggers; scoped idempotency index                   |
| 3       | Phase 3A   | `household_members` table                                                                                                                                |
| 4       | Phase 3A.1 | `financial_accounts.idempotency_key` + `idempotency_payload`; household cardinality triggers; immutable type/currency trigger; account idempotency index |

---

## Files Modified

| File                                                             | Change                                                                                                                                                     |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/core/database/app_database.dart`                            | Schema v3→v4; added `_applyHouseholdConstraintTriggers`, `_applyAccountMetadataImmutabilityTrigger`, `_applyAccountIdempotencyIndex`; v3→v4 migration path |
| `lib/core/database/app_database.g.dart`                          | Regenerated by `build_runner`                                                                                                                              |
| `lib/core/database/tables/financial_accounts_table.dart`         | Added `idempotencyKey` and `idempotencyPayload` columns                                                                                                    |
| `lib/features/accounts/data/account_repository.dart`             | Added `findByIdempotencyKey` to interface; added `ArchivedAccountError`                                                                                    |
| `lib/features/accounts/data/drift_account_repository.dart`       | Implemented `findByIdempotencyKey`; `createAccount` stores idempotency fields                                                                              |
| `lib/features/accounts/domain/financial_account.dart`            | Added `idempotencyKey` + `idempotencyPayload` to `CreateAccountParams`                                                                                     |
| `lib/features/accounts/application/create_account_use_case.dart` | Full idempotency check; `ArchivedAccountError` catch; `_buildIdempotencyPayload` helper                                                                    |
| `lib/features/household/application/household_use_cases.dart`    | Added `InitializeHouseholdUseCase`                                                                                                                         |
| `lib/features/ledger/data/drift_ledger_repository.dart`          | `_requireAccount` now throws `ArchivedAccountError` for archived accounts                                                                                  |
| `test/helpers/fake_account_repository.dart`                      | Added `findByIdempotencyKey` + idempotency key map; `createAccount` stores key                                                                             |
| `docs/PHASE_3A_REPORT.md`                                        | Added correction note documenting overstated claims                                                                                                        |

## Files Created

| File                                                                   | Purpose                                             |
| ---------------------------------------------------------------------- | --------------------------------------------------- |
| `lib/features/accounts/application/account_totals_service.dart`        | Per-currency spendable/protected totals computation |
| `test/unit/core/application/app_result_test.dart`                      | §1 AppResult variant tests                          |
| `test/database/balance_semantics_db_test.dart`                         | §2 Balance query semantics                          |
| `test/database/household_cardinality_db_test.dart`                     | §3 Household cardinality DB triggers                |
| `test/database/account_creation_idempotency_db_test.dart`              | §4 Account idempotency                              |
| `test/database/account_atomicity_db_test.dart`                         | §5 Account+opening balance atomicity                |
| `test/unit/features/accounts/account_totals_service_test.dart`         | §6 Cross-currency totals service                    |
| `test/database/historical_metadata_db_test.dart`                       | §7 Immutable type/currency trigger                  |
| `test/database/archive_rules_db_test.dart`                             | §8 Archive rules                                    |
| `test/database/migration_db_test.dart`                                 | §9 Schema migration verification                    |
| `test/unit/features/household/initialize_household_use_case_test.dart` | §10 Onboarding use case                             |

---

## Defects Found and Fixed

| Defect                                                            | Location                                | Fix                                                                       |
| ----------------------------------------------------------------- | --------------------------------------- | ------------------------------------------------------------------------- |
| Household cardinality constraints existed only at app layer       | `DriftHouseholdRepository.addMember`    | Added DB triggers in `AppDatabase._applyHouseholdConstraintTriggers()`    |
| Account `type` and `currency_code` had no DB immutability trigger | `FinancialAccountsTable`                | Added `immutable_account_type_currency` BEFORE UPDATE trigger             |
| Account creation had no idempotency payload tracking              | `CreateAccountUseCase`                  | Added `idempotency_key`/`idempotency_payload` columns + use-case checking |
| Archived accounts could receive new ledger entries                | `DriftLedgerRepository._requireAccount` | Added `isArchived` check; throws `ArchivedAccountError`                   |
| Localization files had Phase 3A keys stripped from working tree   | `app_localizations*.dart`               | Restored to committed state via `git checkout HEAD`                       |

---

## Test Count History

| Phase          | Tests   |
| -------------- | ------- |
| Phase 1 end    | 106     |
| Phase 2        | 259     |
| Phase 2A       | 390     |
| Phase 3A       | 458     |
| **Phase 3A.1** | **532** |
