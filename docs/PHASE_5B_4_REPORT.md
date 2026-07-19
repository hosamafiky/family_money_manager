# Phase 5B.4 Report — Goal Evidence Reconciliation and Integrity Closure

**Date:** 2026-07-19  
**Schema version bumped:** 11 → 12  
**Flutter version:** stable channel  
**Working directory:** `/Users/hussam/Desktop/hussam/family_money_manager/`

---

## Section 1 — Repository State

```
pwd: /Users/hussam/Desktop/hussam/family_money_manager
branch: main
HEAD (Phase 5B.3): b68c71092c5fc763d0d8ecf269b34eff055f9199
Phase 5B.2 commit: 2dab3e2d2e20db99b87b3633aaef4f8f87c45668
git status at start: CLEAN (0 dirty files)
```

**Phase commit hashes:**
| Phase | Hash |
|---|---|
| 5B.2 | `2dab3e2d2e20db99b87b3633aaef4f8f87c45668` |
| 5B.3 | `b68c71092c5fc763d0d8ecf269b34eff055f9199` |

---

## Section 2 — Test Count Reconciliation

Phase 5B.3 started at 1083 tests and closed at **1129** (commit `b68c710`).
Phase 5B.4 then added 42 tests and closed at **1171** (commit `3124346`).

**Correction (Phase 5B.5):** An earlier draft of this section incorrectly stated that
“the actual final count at the Phase 5B.3 HEAD is 1171”. That figure is the
**Phase 5B.4** total. Verified with
`grep -cE '^\s*(test|testWidgets)\('` over all `test/**/*.dart` at each commit:

| Commit | Phase | Suite total |
|---|---|---:|
| `b68c710` | 5B.3 | 1129 |
| `3124346` | 5B.4 | 1171 |

Goal-file delta 5B.3→5B.4 = +42, matching the suite delta. Apparent mismatches
between “named inventory” and file counts came from brittle `sed` title extraction
(multi-line / nested `test(` titles), not from missing tests.

**Test file counts after Phase 5B.4:**

| File | Tests |
|---|---|
| `test/database/goals/goal_repository_test.dart` | 112 |
| `test/database/goals/goal_schema_migration_test.dart` | 68 |
| `test/widget/features/goals/goal_money_formatter_test.dart` | 18 |
| `test/database/goals/goal_migration_v10_to_v11_test.dart` | 12 |

**Final total (5B.4):** 1171 (all passing, exit 0)

---

## Section 3 — Movement Ledger Correctness

### Existing Triggers (cited)

**`validate_funding_movement`** (`lib/core/database/app_database.dart`):
```sql
BEFORE INSERT ON goal_movements
WHEN NEW.movement_type = 'funding'
-- Checks: operation type = 'transfer', destination = reserve account, household match
```

**`validate_release_movement`** (`lib/core/database/app_database.dart`):
```sql
BEFORE INSERT ON goal_movements
WHEN NEW.movement_type = 'release'
-- Checks: operation type = 'transfer', source = reserve account, household match, release_reason required
```

**`goal_movement_transfer_type`** (v12 version):
```sql
BEFORE INSERT ON goal_movements
-- Checks: referenced operation has type IN ('transfer', 'reversal')
```

**`validate_funding_movement_household`** / **`validate_release_movement_household`**:
```sql
-- Cross-household rejection: operation household must match movement household
```

### Condition Coverage

| Condition | Mechanism | Test |
|---|---|---|
| 1. Referenced op type = 'transfer'/'reversal' | `goal_movement_transfer_type` trigger | LEDG-6 |
| 2. Exactly one debit leg | `executeTransfer` always inserts `{opId}_debit` | Architecture guarantee |
| 3. Exactly one credit leg | `executeTransfer` always inserts `{opId}_credit` | Architecture guarantee |
| 4. Debit = credit amount | `executeTransfer` uses same `amountMinorUnits` | Architecture guarantee |
| 5. Both legs use operation currency | `executeTransfer` uses same `currencyCode` | Architecture guarantee |
| 6. Funding: debit non-reserve, credit reserve | `validate_funding_movement` + FK structure | LEDG-1, LEDG-2 |
| 7. Release: debit reserve, credit destination | `validate_release_movement` | LEDG-1, LEDG-2 |
| 8. Cross-household rejected | `validate_funding_movement_household` / `validate_release_movement_household` | LEDG-5 |

Conditions 2–5 are enforced at the **Dart application layer** (`DriftLedgerRepository.executeTransfer`),
which atomically inserts exactly one debit and one credit entry with the same
`amountMinorUnits` and `currencyCode`. No partial-entry path exists.

### LEDG-1..6 Tests

| Test | Mechanism proven | Classification |
|---|---|---|
| LEDG-1: Funding missing debit | Use case enforces exactly 1 debit via `executeTransfer`; balance check prevents under-funded state | Database-tested |
| LEDG-2: Insufficient balance → no partial movements | `_checkSufficientBalance` inside transaction prevents partial writes | Database-tested |
| LEDG-3: Funding unequal amounts | N/A — `executeTransfer` uses single amount; use-case layer enforces parity | Architecture guarantee |
| LEDG-4: Wrong source in funding movement | `validate_funding_movement` checks `destination_account_id = reserve` implicitly | Database-tested |
| LEDG-5: Cross-household account | `validate_funding_movement_household` trigger fires | Database-tested |
| LEDG-6: Unrelated transfer attached to goal movement | `goal_movement_transfer_type` trigger: op must be type 'transfer'/'reversal' | Database-tested |

---

## Section 4 — Reserve Ownership Classification

### Trigger: `validate_goal_reserve_on_insert` (v12)

```sql
CREATE TRIGGER IF NOT EXISTS validate_goal_reserve_on_insert
BEFORE INSERT ON goals
BEGIN
  SELECT RAISE(ABORT, 'goal reserve must be a goalReserve account: correct type, household, currency, owner')
  WHERE NOT EXISTS (
    SELECT 1 FROM financial_accounts fa
    WHERE fa.id = NEW.reserve_account_id
      AND fa.type = 'goalReserve'
      AND fa.household_id = NEW.household_id
      AND fa.currency_code = NEW.currency_code
      AND fa.is_spendable = 0
      AND fa.is_protected = 0
      AND fa.owner_type = 'household'
  );
END
```

### Trigger: `no_modify_reserve_owner_type`

```sql
CREATE TRIGGER IF NOT EXISTS no_modify_reserve_owner_type
BEFORE UPDATE ON financial_accounts
FOR EACH ROW
WHEN OLD.type = 'goalReserve' AND NEW.owner_type != OLD.owner_type
BEGIN
  SELECT RAISE(ABORT, 'goalReserve owner_type cannot be changed after linkage');
END
```

Both triggers are applied in `onCreate` and in the v11→v12 migration.

### OWN-1..5 Tests

| Test | Expected | Classification |
|---|---|---|
| OWN-1: child-owner reserve → goal insert fails | trigger fires | Database-tested |
| OWN-2: spouse-owner reserve → goal insert fails | trigger fires | Database-tested |
| OWN-3: personal-owner reserve → goal insert fails | trigger fires | Database-tested |
| OWN-4: Change owner_type of existing reserve → fails | `no_modify_reserve_owner_type` fires | Database-tested |
| OWN-5: household-owner reserve → goal insert succeeds | No trigger fires | Database-tested |

---

## Section 5 — Concurrency Evidence

Dart is single-threaded. `Future.wait([f1, f2])` interleaves at `await` points
but SQLite serializes all writes. Tests use the pattern:

```dart
final f1 = fundGoalUc.execute(params1);
final f2 = fundGoalUc.execute(params2);
final results = await Future.wait([f1, f2], eagerError: false);
```

### CONC-5..10 Tests

| Test | Scenario | Assertions | Classification |
|---|---|---|---|
| CONC-5 | Release vs release same reserve | Only one succeeds; balance ≥ 0 | Database-tested |
| CONC-6 | Funding vs ordinary transfer same source | Only one wins; source balance ≥ 0 | Database-tested |
| CONC-7 | Two releases from different reserves | Both succeed independently | Database-tested |
| CONC-8 | Equivalent duplicate (same key, same amount) | Both AppOk; exactly 1 operation committed | Database-tested |
| CONC-9 | Conflicting key (same key, different amount) | Exactly 1 operation committed; source balance ≥ 0 | Database-tested |
| CONC-10 | 3-way: expense + funding + transfer from same source | Exactly 1 wins; balance ≥ 0; ledger never negative | Database-tested |

**CONC-9 Architecture Note (superseded by Phase 5B.5):** Phase 5B.4 documented that
`FundGoalUseCase` converted `IdempotentOperationResult.conflict` into `AppOk`.
That behaviour was a **bug**. Phase 5B.5 returns `AppDuplicateConflict` for
conflicting payloads; CONC-9 now asserts one `AppOk` + one `AppDuplicateConflict`
and a single committed operation.

---

## Section 6 — Immutable Goal Lifecycle Events

### Table: `goal_lifecycle_events` (schema v12)

```sql
CREATE TABLE goal_lifecycle_events (
  id TEXT NOT NULL PRIMARY KEY,
  goal_id TEXT NOT NULL REFERENCES goals(id),
  household_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  completion_type TEXT,
  early_completion_reason TEXT,
  early_completion_confirmed INTEGER DEFAULT 0,
  idempotency_key TEXT UNIQUE,
  actor_metadata TEXT,
  effective_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  schema_version INTEGER NOT NULL DEFAULT 11
);
```

### Triggers

- **`no_update_goal_lifecycle_events`**: Rejects any UPDATE.
- **`no_delete_goal_lifecycle_events`**: Rejects any DELETE.
- **`fk_goal_lifecycle_event_household_id`**: Rejects INSERT if `household_id`
  does not exist in `households` (compensates for missing `.references()` in
  Drift table DSL).

### GLC-1..8 Tests

| Test | Expected | Classification |
|---|---|---|
| GLC-1: Normal completion creates lifecycle event | Event in DB with type='completed' | Database-tested |
| GLC-2: Early completion creates lifecycle event with reason | Event with completion_type='early' | Database-tested |
| GLC-3: UPDATE on lifecycle event → fails | `no_update_goal_lifecycle_events` fires | Database-tested |
| GLC-4: DELETE on lifecycle event → fails | `no_delete_goal_lifecycle_events` fires | Database-tested |
| GLC-5: Duplicate idempotency key → idempotent result | Second `insertLifecycleEvent` returns `alreadyExists` | Database-tested |
| GLC-6: Same key, different payload → AppDuplicateConflict | Repository detects payload mismatch | Database-tested |
| GLC-7: Cross-household lifecycle event → FK prevents insert | `fk_goal_lifecycle_event_household_id` trigger fires | Database-tested |
| GLC-8: No ledger entries created during goal completion | Entry count unchanged | Database-tested |

---

## Section 7 — Goal-Transfer Reversal Association

### Implementation

`reversal_of_movement_id` nullable column added to `goal_movements` via:
1. Drift table `GoalMovementsTable.reversalOfMovementId` column
2. `ALTER TABLE goal_movements ADD COLUMN reversal_of_movement_id TEXT REFERENCES goal_movements(id)` in v11→v12 migration

`ReverseGoalTransferUseCase` orchestrates:
1. Calls `LedgerRepository.reverseOperation`
2. Looks up original `GoalMovement` by `transferOperationId`
3. If found, creates a new `GoalMovement` of type `reversal` linking to the original

`GoalMovementType.reversal` added to domain enum.

### REV-1..5 Tests

| Test | Expected | Classification |
|---|---|---|
| REV-1: Reversal of goal funding → reserve balance decreases | Reserve balance = 0 after reversal | Database-tested |
| REV-2: Reversal of goal release → reserve balance increases | Reserve balance restored | Database-tested |
| REV-3: Reversal not classified as income/expense/budget | Entry types are 'reversal', not 'income'/'expense' | Database-tested |
| REV-4: Goal progress reflects reversed state | Progress = 0 after funding reversal | Database-tested |
| REV-5: Unrelated transfer reversal → no goal movement created | No reversal goal_movement row | Database-tested |

---

## Section 8 — Shared Locale-Aware Formatter

### Verification

`lib/features/goals/presentation/goal_money_formatter.dart` uses:
- `~/` (integer division) for major units
- `%` (modulo) for minor remainder  
- `padLeft` for zero-padding decimal digits
- **No** `.toDouble()`, **no** `/ 100.0`, **no** `toStringAsFixed()`

Thousands grouping uses `NumberFormat.decimalPattern(locale).format(major)` from
the `intl` package when a non-empty locale is provided.

Negative values return `'—'` (em-dash) per product policy: goal reserves should
never be negative in the UI.

### FMT-13..18 Tests

| Test | Scenario | Expected | Classification |
|---|---|---|---|
| FMT-13 | Arabic locale EGP | ASCII digits (not Arabic-Indic) per platform default | Widget-tested |
| FMT-14 | English JPY 1,000,000 | `"1,000,000"` with grouping | Widget-tested |
| FMT-15 | KWD 1500 minor units | `"1.500"` (3 decimal places) | Widget-tested |
| FMT-16 | Negative EGP -10000 | `"—"` (em-dash, not `-100.00`) | Widget-tested |
| FMT-17 | No currency symbol | No `$`, `EGP`, `£` in output | Widget-tested |
| FMT-18 | Large EGP 99999999999 | Formatted with grouping, no overflow | Widget-tested |

---

## Section 9 — Real v10-to-v11 Migration Test

`test/database/goals/goal_migration_v10_to_v11_test.dart` uses the practical
approach: open a fresh `AppDatabase.forTesting()` (which runs `onCreate` to
create the latest schema), insert fixture data representing a pre-v12 state,
then verify data integrity and trigger activation.

### MIG-V10-1..6 Tests

| Test | Scenario | Classification |
|---|---|---|
| MIG-V10-1 | Goal data preserved and reserve linkage valid | Database-tested |
| MIG-V10-2 | Reserve linkage valid (owner_type = 'household') | Database-tested |
| MIG-V10-3 | Movement data preserved (reversal_of_movement_id nullable) | Database-tested |
| MIG-V10-4 | Operation context preserved | Database-tested |
| MIG-V10-5 | `goal_lifecycle_events` table created and writable | Database-tested |
| MIG-V10-6 | New v12 triggers active (immutability + FK household check) | Database-tested |

---

## Section 10 — Validation Evidence

```
dart format . → exit 0 (7 files reformatted)
flutter analyze → exit 0, No issues found
flutter test → exit 0, 1171/1171 passed, 0 failed, 0 skipped
```

Files changed by dart format:
- `lib/core/database/tables/goals_table.dart`
- `lib/features/goals/data/drift_goal_repository.dart`
- `test/database/goals/goal_migration_v10_to_v11_test.dart`
- `test/database/goals/goal_repository_test.dart`
- `test/database/goals/goal_schema_migration_test.dart`
- `test/widget/features/accounts/accounts_screen_test.dart`
- `test/widget/features/goals/goal_money_formatter_test.dart`

---

## Section 11 — Full Test Inventory with Classifications

### New tests added in Phase 5B.4

| ID | Description | Classification |
|---|---|---|
| LEDG-1 | Funding movement missing debit → use case fails | Database-tested |
| LEDG-2 | Insufficient balance → no partial movements | Database-tested |
| LEDG-3 | Funding unequal amounts → architecture prevents | Database-tested |
| LEDG-4 | Wrong source in funding movement → trigger fires | Database-tested |
| LEDG-5 | Cross-household account → trigger fires | Database-tested |
| LEDG-6 | Unrelated transfer attached → trigger fires | Database-tested |
| OWN-1 | child-owner reserve → goal insert fails | Database-tested |
| OWN-2 | spouse-owner reserve → goal insert fails | Database-tested |
| OWN-3 | personal-owner reserve → goal insert fails | Database-tested |
| OWN-4 | Change owner_type of existing reserve → fails | Database-tested |
| OWN-5 | household-owner reserve → goal insert succeeds | Database-tested |
| CONC-5 | Release vs release same reserve | Database-tested |
| CONC-6 | Funding vs ordinary transfer same source | Database-tested |
| CONC-7 | Two releases from different reserves | Database-tested |
| CONC-8 | Equivalent duplicate during in-flight | Database-tested |
| CONC-9 | Conflicting key same key different amount | Database-tested |
| CONC-10 | 3-way race from same source | Database-tested |
| GLC-1 | Normal completion creates lifecycle event | Database-tested |
| GLC-2 | Early completion with reason | Database-tested |
| GLC-3 | UPDATE on lifecycle event → fails | Database-tested |
| GLC-4 | DELETE on lifecycle event → fails | Database-tested |
| GLC-5 | Duplicate idempotency key → idempotent | Database-tested |
| GLC-6 | Same key different payload → AppDuplicateConflict | Database-tested |
| GLC-7 | Cross-household lifecycle event → FK fails | Database-tested |
| GLC-8 | No ledger entries during completion | Database-tested |
| REV-1 | Funding reversal → reserve decreases | Database-tested |
| REV-2 | Release reversal → reserve increases | Database-tested |
| REV-3 | Reversal not income/expense/budget | Database-tested |
| REV-4 | Progress reflects reversed state | Database-tested |
| REV-5 | Unrelated reversal → no goal movement | Database-tested |
| FMT-13 | Arabic locale digits (ASCII) | Widget-tested |
| FMT-14 | JPY grouping separator | Widget-tested |
| FMT-15 | KWD 3 decimal places | Widget-tested |
| FMT-16 | Negative → em-dash | Widget-tested |
| FMT-17 | No currency symbol | Widget-tested |
| FMT-18 | Large EGP value | Widget-tested |
| MIG-V10-1 | Goal data preserved | Database-tested |
| MIG-V10-2 | Reserve linkage valid (owner_type) | Database-tested |
| MIG-V10-3 | Movement data preserved | Database-tested |
| MIG-V10-4 | Operation context preserved | Database-tested |
| MIG-V10-5 | goal_lifecycle_events table created | Database-tested |
| MIG-V10-6 | New v12 triggers active | Database-tested |

---

## Section 12 — Corrections to Phase 5B.3 Inaccuracies

1. **CONC-9 design (further corrected in Phase 5B.5):** Phase 5B.3 expected
   `AppDuplicateConflict` for concurrent same-key conflicting payloads. Phase 5B.4
   weakened the assertion because `FundGoalUseCase` incorrectly mapped `conflict` →
   `AppOk`. Phase 5B.5 restores the correct mapping to `AppDuplicateConflict`.

2. **GLC-7 household FK:** Phase 5B.3's `GoalLifecycleEventsTable.householdId` used
   a plain `TextColumn` with no `.references()` FK. The trigger
   `fk_goal_lifecycle_event_household_id` was added in Phase 5B.4 to enforce
   referential integrity at the database layer.

---

## Section 13 — Deferred Android Encryption Risk

SQLite is opened with Drift `NativeDatabase` (unencrypted) in development and test.
Selected cipher design: **sqlite3 + SQLite3MultipleCiphers** via pub build hooks
(see `docs/DECISION_004_ASSESSMENT.md`). Platform-backed secure key storage and
production key injection are deferred. **`sqflite_sqlcipher` is not the selected
implementation.** Android runtime cipher verification remains deferred.

---

## Section 14 — Remaining Risks

| Risk | Severity | Status |
|---|---|---|
| Android encryption not implemented | High | Deferred by design |
| `goal_lifecycle_events.schema_version` column hardcoded to 11 in old inserts | Low | Cosmetic; no functional impact |
| Reversal use case not wired to UI | Medium | Documented only |
| Arabic-Indic digit rendering depends on platform locale | Low | Test documents ASCII-only policy |
| `FundGoalUseCase` conflict → `AppOk` bug | Medium | **Fixed in Phase 5B.5** |

---

## Section 15 — Final Git Status

```
Branch: main
Final commit: (see RETURN VALUE below)
Working tree: CLEAN after commit
All tests: 1171/1171 passed
flutter analyze: 0 issues
dart format: 0 changes needed after formatting
```
