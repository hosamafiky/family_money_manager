# Phase 3B.1 Report — Account-Classification Integrity & Transaction-Layer Cleanup

## 1. Repository Preflight

| Item               | Value                                            |
| ------------------ | ------------------------------------------------ |
| Branch             | `main`                                           |
| HEAD before commit | `ebdbcce7a51c9ebaffc0584bba4784e8d2b34ee2`       |
| git status         | clean (no uncommitted changes before this phase) |

**git log --oneline -5:**

```
ebdbcce verify: Phase 3B verification and correction pass
ada7c9d feat: Phase 3B – income, expense, transfer, spouse-wallet, protected-child withdrawal
90d58b4 fix: move Phase 3A localization strings into ARB source files
d83e5a1 phase 3A.1: household and account management hardening
8a1473b fix: add missing Phase 3A localization keys to AppLocalizations
```

---

## 2. Final Account-Field Policy Table

| Field                  | Policy                                                                                     | Enforcement Layer                                                                                                                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                   | Always immutable (PK)                                                                      | SQLite PK constraint                                                                                                                                                                                      |
| `household_id`         | Always immutable (FK)                                                                      | SQLite FK constraint (PRAGMA foreign_keys = ON)                                                                                                                                                           |
| `type`                 | Always immutable                                                                           | `immutable_account_type_currency` DB trigger (always) + `restrict_account_classification_update` DB trigger (post-history)                                                                                |
| `currency_code`        | Always immutable                                                                           | `immutable_account_type_currency` DB trigger (always) + `restrict_account_classification_update` DB trigger (post-history)                                                                                |
| `owner_type`           | Immutable after financial history                                                          | `restrict_account_classification_update` DB trigger (post-history)                                                                                                                                        |
| `fund_purpose`         | Immutable after financial history                                                          | `restrict_account_classification_update` DB trigger (post-history)                                                                                                                                        |
| `is_protected`         | Immutable after financial history; `childProtectedFund` cannot disable even before history | `restrict_account_classification_update` DB trigger (post-history) + `restrict_child_fund_unprotect` DB trigger (always for childProtectedFund) + `DriftAccountRepository.updateAccount` repo-level check |
| `is_spendable`         | Immutable after financial history                                                          | `restrict_account_classification_update` DB trigger (post-history)                                                                                                                                        |
| `include_in_net_worth` | Immutable after financial history                                                          | `restrict_account_classification_update` DB trigger (post-history) + `DriftAccountRepository.updateAccount` repo-level `ClassificationImmutabilityError` check                                            |
| `include_in_zakat`     | Immutable after financial history                                                          | `restrict_account_classification_update` DB trigger (post-history) + `DriftAccountRepository.updateAccount` repo-level `ClassificationImmutabilityError` check                                            |
| `name`                 | Always editable                                                                            | No restriction                                                                                                                                                                                            |
| `notes`                | Always editable                                                                            | No restriction                                                                                                                                                                                            |
| `is_archived`          | Only via `archiveAccount` workflow                                                         | Not exposed in generic `updateAccount` call from `UpdateAccountMetadataUseCase`                                                                                                                           |

**"Financial history"** = at least one row in `ledger_entries` WHERE `account_id = OLD.id`.

---

## 3. DB Trigger Listing

### New in Schema v6

#### `restrict_account_classification_update`

- **File:** `lib/core/database/app_database.dart`, method `_applyAccountClassificationImmutabilityTrigger()`
- **When:** `BEFORE UPDATE ON financial_accounts` when `(SELECT COUNT(*) FROM ledger_entries WHERE account_id = OLD.id) > 0`
- **Blocks:** Changes to `type`, `currency_code`, `owner_type`, `fund_purpose`, `is_protected`, `is_spendable`, `include_in_net_worth`, `include_in_zakat`
- **Error:** `RAISE(ABORT, 'Account <field> is immutable once financial history exists')`

#### `restrict_child_fund_unprotect`

- **File:** `lib/core/database/app_database.dart`, method `_applyChildFundProtectionTrigger()`
- **When:** `BEFORE UPDATE ON financial_accounts` when `NEW.type = 'childProtectedFund' AND NEW.is_protected = 0`
- **Blocks:** Clearing `is_protected` on any child-protected fund account, regardless of history
- **Error:** `RAISE(ABORT, 'Child protected fund cannot have is_protected disabled')`

### Pre-existing (unchanged)

| Trigger                             | Scope  | Purpose                                                   |
| ----------------------------------- | ------ | --------------------------------------------------------- |
| `immutable_account_type_currency`   | Always | Blocks `type` and `currency_code` changes unconditionally |
| `no_update_ledger_entries`          | Always | Ledger entries are immutable                              |
| `no_delete_ledger_entries`          | Always | Ledger entries cannot be deleted                          |
| `no_update_child_audits`            | Always | Child withdrawal audits immutable                         |
| `no_delete_child_audits`            | Always | Child withdrawal audits cannot be deleted                 |
| `restrict_operations_update`        | Always | Operations append-only (only reversal fields mutable)     |
| `no_delete_operations`              | Always | Operations cannot be deleted                              |
| `check_ledger_entry_amount`         | INSERT | `amount_minor_units > 0`                                  |
| `check_audit_amount`                | INSERT | Audit `amount_minor_units > 0`                            |
| `check_audit_warning_shown`         | INSERT | `warning_shown = 1`                                       |
| `check_audit_reason`                | INSERT | `reason` non-empty                                        |
| `check_operation_amount`            | INSERT | `total_amount_minor_units >= 0`                           |
| `fk_ledger_entry_operation_id`      | INSERT | FK from ledger → operations                               |
| `fk_audit_operation_household`      | INSERT | FK from audit → operations                                |
| `one_primary_user_per_household`    | INSERT | One active primary_user per household                     |
| `one_spouse_per_household`          | INSERT | One active spouse per household                           |
| `no_cross_household_member`         | INSERT | member.household_id must exist                            |
| `fk_operation_context_operation_id` | INSERT | FK from context → operations                              |
| `no_update_operation_contexts`      | Always | Operation contexts immutable                              |
| `no_delete_operation_contexts`      | Always | Operation contexts cannot be deleted                      |

---

## 4. Schema v6 Migration Details

**Schema version bump:** 5 → 6

**`onUpgrade` block added:**

```dart
if (from <= 5) {
  // v5 → v6: stronger account-classification immutability triggers.
  await _applyAccountClassificationImmutabilityTrigger();
  await _applyChildFundProtectionTrigger();
}
```

**`onCreate` additions:**

```dart
await _applyAccountClassificationImmutabilityTrigger();
await _applyChildFundProtectionTrigger();
```

Both trigger methods use `CREATE TRIGGER IF NOT EXISTS` making them safe to re-apply idempotently during migration.

---

## 5. UpdateAccountMetadataUseCase Final Interface

**File:** `lib/features/accounts/application/account_use_cases.dart`

```dart
Future<AppResult<FinancialAccount>> execute({
  required String accountId,
  required String householdId,
  String? name,
  String? notes,
}) async
```

**Accepted inputs:** Only `name` and `notes`. Classification fields (`isSpendable`, `isProtected`, `includeInNetWorth`, `includeInZakat`, `ownerType`, `fundPurpose`) and `isArchived` are NOT accepted.

**Error mappings:**
| Condition | Result |
|---|---|
| `name` after trim is empty string | `AppValidationFailure(field: 'name', messageKey: 'error_account_name_empty')` |
| Account not found (wrong id or wrong household) | `AppNotFound` |
| `ClassificationImmutabilityError` from repo layer | `AppClassificationImmutabilityViolation(field: e.field)` |
| DB trigger `RAISE(ABORT, '...immutable...')` | `AppClassificationImmutabilityViolation(field: 'classification')` |
| Any other exception | `AppPersistenceFailure` |

---

## 6. Display-Name Semantics — V1 Policy

Documented in `UpdateAccountMetadataUseCase` doc comment:

> **V1 Display-Name Policy**: Transaction lists, ledger entries, and audit records reference accounts by their stable `account_id`. The displayed name is always resolved at query time from the current `financial_accounts.name`. No historical name snapshot is stored. This means if an account is renamed, all historical displays show the new name. This is explicitly documented and acceptable for V1. Audit correctness depends on stable IDs, not names.

---

## 7. Dead-Code Cleanup — ArchivedAccountTransferError

**Disposition:** **NOT removed** — class is actively used.

`ArchivedAccountTransferError` is thrown in `DriftLedgerRepository.executeTransfer` (lines 276 and 279) when either the source or destination account is archived. It is therefore live code.

**Change made:** Converted from an independent `Error` subclass to a subclass of `ArchivedAccountError`:

```dart
// Before:
final class ArchivedAccountTransferError extends Error { ... }

// After:
final class ArchivedAccountTransferError extends ArchivedAccountError {
  ArchivedAccountTransferError(super.accountId, this.role);
  final String role;
}
```

Additionally, `ArchivedAccountError` was changed from `final class` to `class` to allow cross-library extension.

**Benefit:** The existing `on ArchivedAccountError` catch in `ExecuteTransferUseCase` automatically covers `ArchivedAccountTransferError` via inheritance, consolidating error handling without code duplication.

---

## 8. Tests Added

### New Files

| File                                                             | Group                               | Tests              | Count  |
| ---------------------------------------------------------------- | ----------------------------------- | ------------------ | ------ |
| `test/database/account_classification_immutability_db_test.dart` | owner_type immutability             | 1, 2               | 2      |
|                                                                  | fund_purpose immutability           | 3, 4               | 2      |
|                                                                  | is_protected immutability           | 5, 6, 7            | 3      |
|                                                                  | is_spendable immutability           | 8, 9               | 2      |
|                                                                  | include_in_net_worth immutability   | 10                 | 1      |
|                                                                  | include_in_zakat immutability       | 11                 | 1      |
|                                                                  | type immutability (always)          | 12, 13             | 2      |
|                                                                  | currency_code immutability (always) | 14, 15             | 2      |
|                                                                  | name mutability (always editable)   | 16, 17             | 2      |
|                                                                  | cross-household reassignment        | 18                 | 1      |
|                                                                  | use-case mapping                    | 19, 20, 21, 22, 23 | 5      |
| **Subtotal**                                                     |                                     |                    | **23** |
| `test/database/account_classification_migration_db_test.dart`    | (top-level)                         | 1, 2, 3            | 3      |
| **Subtotal**                                                     |                                     |                    | **3**  |
| **Grand Total New Tests**                                        |                                     |                    | **26** |

### Updated Files

No existing test files were modified in Phase 3B.1. The new triggers are additive and do not affect existing test behavior.

---

## 9. Test Classification Table

| Behavior Under Test                                               | Test(s)                               | Classification  |
| ----------------------------------------------------------------- | ------------------------------------- | --------------- |
| `owner_type` mutable before history                               | Test 1                                | Database-tested |
| `owner_type` immutable after history (DB trigger)                 | Test 2                                | Database-tested |
| `fund_purpose` mutable before history                             | Test 3                                | Database-tested |
| `fund_purpose` immutable after history (DB trigger)               | Test 4                                | Database-tested |
| `is_protected` mutable before history (non-child fund)            | Test 5                                | Database-tested |
| `is_protected` immutable after history (DB trigger)               | Test 6                                | Database-tested |
| `childProtectedFund` cannot disable `is_protected` ever           | Test 7                                | Database-tested |
| `is_spendable` mutable before history                             | Test 8                                | Database-tested |
| `is_spendable` immutable after history (DB trigger)               | Test 9                                | Database-tested |
| `include_in_net_worth` immutable after history                    | Test 10                               | Database-tested |
| `include_in_zakat` immutable after history                        | Test 11                               | Database-tested |
| `type` always immutable (pre-history)                             | Test 12                               | Database-tested |
| `type` always immutable (post-history)                            | Test 13                               | Database-tested |
| `currency_code` always immutable (pre-history)                    | Test 14                               | Database-tested |
| `currency_code` always immutable (post-history)                   | Test 15                               | Database-tested |
| `name` mutable before history                                     | Test 16                               | Database-tested |
| `name` mutable after history                                      | Test 17                               | Database-tested |
| `household_id` FK constraint blocks reassignment                  | Test 18                               | Database-tested |
| `UpdateAccountMetadataUseCase` name update → AppOk                | Test 19                               | Database-tested |
| `UpdateAccountMetadataUseCase` blank name → AppValidationFailure  | Test 20                               | Database-tested |
| `UpdateAccountMetadataUseCase` missing account → AppNotFound      | Test 21                               | Database-tested |
| Name edit preserves ledger balance                                | Test 22                               | Database-tested |
| Name edit preserves spendable flag and balance                    | Test 23                               | Database-tested |
| Fresh v6 DB has `restrict_account_classification_update` trigger  | Migration Test 1                      | Database-tested |
| Fresh v6 DB has `restrict_child_fund_unprotect` trigger           | Migration Test 2                      | Database-tested |
| Existing accounts preserved; triggers work after creation         | Migration Test 3                      | Database-tested |
| `ArchivedAccountTransferError` extends `ArchivedAccountError`     | Covered by existing transfer tests    | Unit-tested     |
| `ClassificationImmutabilityError` (repo layer, isProtected)       | `classification_immutability_db_test` | Database-tested |
| `ClassificationImmutabilityError` (repo layer, includeInNetWorth) | `classification_immutability_db_test` | Database-tested |
| `ClassificationImmutabilityError` (repo layer, includeInZakat)    | `classification_immutability_db_test` | Database-tested |

---

## 10. Historical-Query Integrity Evidence

- **Account references by stable ID**: All ledger entries, operations, and audit records reference `financial_accounts.id` (UUID). The ID is the PK, set on creation and never mutable.
- **Name resolved at query time**: `DriftLedgerRepository` does not store or snapshot `name`. The `financial_account.dart` domain object's `name` field is always loaded fresh.
- **V1 policy**: Renaming an account changes the name for all historical queries. This is documented and accepted. Audit correctness depends on IDs.
- **Test 22** confirms that renaming does not affect ledger balance.
- **Test 23** confirms that renaming does not affect spendable totals.

---

## 11. Scope Scan Results

| Keyword       | Matches                                                                                                                                                          | Disposition                                                                                               |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `dashboard`   | 1 match in `smoke_screen.dart` (doc comment)                                                                                                                     | **Permitted** — comment references future Phase 4 dashboard                                               |
| `budget`      | 0 matches                                                                                                                                                        | **Clean**                                                                                                 |
| `goal`        | 0 matches (after filtering GoRoute/GoRouter)                                                                                                                     | **Clean**                                                                                                 |
| `certificate` | Enum values (`FinancialAccountType.certificate`, `FundPurpose.certificate`, `LedgerEntryType.certificateFunding`, `certificateMaturityReturn`), metadata comment | **Permitted** — enum placeholders and schema comments, no UI/feature implementation                       |
| `zakat`       | `includeInZakat` field, `includeInZakat` trigger reference, `zakatExpense` enum value                                                                            | **Permitted** — account classification flag and enum value, no Zakat calculation feature                  |
| `sadaqah`     | `LedgerEntryType.sadaqahExpense`, `OperationType.sadaqah` enum values                                                                                            | **Permitted** — enum placeholders, no sadaqah feature implementation                                      |
| `firebase`    | 3 comments: "NO Firebase", "e.g. Firebase Crashlytics", "Firebase credentials"                                                                                   | **Permitted** — constraint comments and negative examples                                                 |
| `biometric`   | `biometricConfirmed` column in `child_withdrawal_audits_table.dart` and domain                                                                                   | **Permitted** — audit confirmation flag for child withdrawal audit workflow, not a biometric auth feature |
| `backup`      | 1 comment in `redacted_logger.dart` about excluded content                                                                                                       | **Permitted** — negative constraint comment                                                               |

**Verdict:** No forbidden feature implementations found in `lib/`.

---

## 12. Validation Commands and Exit Codes

| Command                                                           | Exit Code | Result                                      |
| ----------------------------------------------------------------- | --------- | ------------------------------------------- |
| `flutter pub run build_runner build --delete-conflicting-outputs` | 0         | No schema table changes; build runner no-op |
| `dart format --output=none --set-exit-if-changed .`               | 0         | 0 files changed (138 files formatted)       |
| `flutter analyze`                                                 | 0         | No issues found                             |
| `flutter test`                                                    | 0         | **614/614 tests pass**                      |

**Test count:** Before Phase 3B.1: **588**. After: **614** (+26).

---

## 13. Deferred Android Encryption Risk

The database opens without a key in Phase 2 development. The `_devConnection()` factory opens a plain `NativeDatabase` file. Key injection via Android Keystore / iOS Keychain is deferred to the security-hardening phase (see `docs/LOCAL_ENCRYPTION_KEY_MANAGEMENT.md` and `DECISION_004_ASSESSMENT.md`).

**Risk level:** Low for development; medium for production. Mitigated by the fact that the schema and repository design do not require plaintext fallback — the encryption-ready `sqlite3mc` binary is already configured via the Pub build hook.

---

## 14. Files Created or Modified

### Source Files Modified

| File                                                                | Change                                                                                                                                                                                      |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/core/database/app_database.dart`                               | Schema v6; added `_applyAccountClassificationImmutabilityTrigger()` and `_applyChildFundProtectionTrigger()` methods; added `from <= 5` migration block; updated schema version doc comment |
| `lib/features/accounts/data/account_repository.dart`                | Changed `final class ArchivedAccountError` → `class ArchivedAccountError` (removed `final` to enable cross-library extension)                                                               |
| `lib/features/ledger/data/ledger_repository.dart`                   | Added import for `account_repository.dart`; changed `ArchivedAccountTransferError extends Error` → `ArchivedAccountTransferError extends ArchivedAccountError`; updated doc comment         |
| `lib/features/accounts/application/account_use_cases.dart`          | Added V1 display-name semantics doc comment to `UpdateAccountMetadataUseCase`; added DB-trigger exception catch mapping to `AppClassificationImmutabilityViolation`                         |
| `lib/features/accounts/domain/financial_account.dart`               | Updated IMMUTABILITY RULES doc comment with complete policy table                                                                                                                           |
| `lib/features/household/presentation/household_members_screen.dart` | `dart format` only (pre-existing formatting issue)                                                                                                                                          |

### New Files Created

| File                                                             | Purpose                                              | Tests |
| ---------------------------------------------------------------- | ---------------------------------------------------- | ----- |
| `test/database/account_classification_immutability_db_test.dart` | DB trigger immutability + use-case integration tests | 23    |
| `test/database/account_classification_migration_db_test.dart`    | Schema v6 trigger presence + migration correctness   | 3     |
| `docs/PHASE_3B_1_REPORT.md`                                      | This report                                          | —     |

---

## 15. Remaining Risks

| Risk                                                                                                                                                              | Severity | Mitigation                                                                                                                   |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------- |
| DB trigger cannot be tested at the exact v5→v6 migration boundary (Drift test harness always creates fresh schemas at latest version)                             | Low      | The `IF NOT EXISTS` clause ensures safe re-application; migration test 3 validates trigger function on pre-existing accounts |
| `household_id` FK constraint blocks changing to non-existent household but allows changing to an existing household (no dedicated household reassignment trigger) | Low      | Production code path never exposes household_id as a mutable field; no use-case method accepts it                            |
| `UpdateAccountMetadataUseCase` AppIsolationViolation path: currently maps wrong-household to AppNotFound (findById uses AND household_id filter)                  | Info     | Documented; consistent with other use cases; not a security gap (data is not accessible)                                     |
| Android database unencrypted at rest (deferred from Phase 2)                                                                                                      | Medium   | See Section 13 and docs/LOCAL_ENCRYPTION_KEY_MANAGEMENT.md                                                                   |
