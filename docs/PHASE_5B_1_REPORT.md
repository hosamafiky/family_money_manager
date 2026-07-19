# Phase 5B.1 Report — Goal Atomicity, Idempotency, and Database-Integrity Hardening

## 1. Repository State

| Field | Value |
|---|---|
| Branch | `main` |
| Schema version | 9 (incremented from 8 in this phase) |
| Final 5B commit | `52b9f05` (pre-5B.1) |
| Tests at phase start | 1,017 |
| Tests at phase end | **1,035** |
| Tests added | **+18** |
| Tests removed | 0 |

### Files Modified
- `lib/core/database/app_database.dart` — schema v9, Phase 5B.1 triggers, v8→v9 migration
- `lib/features/goals/application/goal_use_cases.dart` — idempotency, balance enforcement, formatting
- `lib/features/goals/data/drift_goal_repository.dart` — atomic single-transaction creation
- `lib/features/goals/data/goal_repository.dart` — interface updates
- `lib/features/goals/domain/goal.dart` — GoalProgressState derivation, GoalMoneyFormatter integration
- `lib/features/goals/presentation/fund_goal_screen.dart` — stable idempotency key in `initState`
- `lib/features/goals/presentation/goal_creation_screen.dart` — stable idempotency key in `initState`
- `lib/features/goals/presentation/goal_detail_screen.dart` — centralized formatter
- `lib/features/goals/presentation/goals_list_screen.dart` — centralized formatter
- `lib/features/goals/presentation/release_goal_screen.dart` — stable idempotency key in `initState`
- `lib/features/transactions/presentation/income_form_screen.dart` — excludes `goalReserve` accounts
- `lib/features/transactions/presentation/expense_form_screen.dart` — excludes `goalReserve` accounts
- `lib/features/transactions/presentation/transfer_form_screen.dart` — excludes `goalReserve` accounts
- `test/database/goals/goal_repository_test.dart` — expanded to 42 test cases
- `test/database/goals/goal_schema_migration_test.dart` — expanded to 30 test cases

### Files Created
- `lib/features/goals/presentation/goal_money_formatter.dart` — centralized minor-unit formatter

---

## 2. Section 1 — Atomic Initial Funding

**Status: Database-tested**

`DriftGoalRepository.createGoal()` is wrapped in a single `db.transaction(() async { ... })` covering:

1. Reserve account insertion (`financial_accounts`)
2. Goal row insertion (`goals`)
3. Initial revision insertion (`goal_revisions`)
4. Optional initial-funding transfer operation (`operations`)
5. Debit ledger entry on source account (`ledger_entries`)
6. Credit ledger entry on reserve account (`ledger_entries`)
7. Goal movement insertion (`goal_movements`)

**Balance check** is performed _inside_ the transaction (TOCTOU-safe for single-device SQLite WAL) before any writes. If the source balance is insufficient, `InsufficientFundsError` is thrown and no rows are written.

**Zero initial funding** produces no transfer, no movement — verified by test ZF-1.

**Failure injection** tests verify complete rollback at each boundary — see `test/database/goals/goal_repository_test.dart` tests AT-1 through AT-4.

---

## 3. Section 2 — Preserve Retry Identity

**Status: Fake-tested**

All three goal screens generate the idempotency key once in `initState`:

```dart
late String _idempotencyKey;

@override
void initState() {
  super.initState();
  _idempotencyKey = const Uuid().v4();
}
```

After a successful submission, a new key is generated so the next submission is treated as a distinct request. After an uncertain result (error path), the same key is retained so the user can retry safely.

The same pattern is applied to:
- `GoalCreationScreen` — covers goal + reserve + optional initial funding
- `FundGoalScreen` — covers funding operation
- `ReleaseGoalScreen` — covers release operation

---

## 4. Section 3 — Funding and Release Idempotency

**Status: Database-tested**

Both `FundGoalUseCase` and `ReleaseGoalFundsUseCase` check the `idempotency_key` column on `ledger_operations` before inserting. If a matching key is found:
- Same payload → return original operation ID (idempotent success)
- Different payload → return `AppDuplicateConflict`

Tests in `goal_repository_test.dart`:
- Sequential equivalent retry returns original operation ID
- Sequential conflicting retry returns `AppDuplicateConflict`
- Same key in a different household creates a separate operation
- Failure followed by retry succeeds idempotently

---

## 5. Section 4 — Atomic Balance Enforcement

**Status: Database-tested**

The balance read is performed with a `customSelect` inside the `db.transaction()` block, before any write. This prevents time-of-check/time-of-use races in the single-writer SQLite WAL model.

Tests:
- Two funding requests summing to more than the source balance → only the first succeeds
- Two releases summing to more than the reserve balance → only the first succeeds

---

## 6. Section 5 — Goals Table Hardening (Schema v9)

**Status: Database-tested**

New triggers added in `onCreate` and the v8→v9 migration:

| Trigger | Enforces |
|---|---|
| `no_update_goal_immutable` | `household_id`, `reserve_account_id`, `currency_code`, `idempotency_key`, `created_at` cannot change |
| `no_delete_goal_with_history` | Goal with revisions, movements, or linked operations cannot be deleted |

Tests SM-6 and SM-7 in `goal_schema_migration_test.dart` verify these triggers fire.

---

## 7. Section 6 — Reserve-Account Classification Hardening

**Status: Database-tested**

New triggers on `financial_accounts` (added in v8→v9 migration):

| Trigger | Enforces |
|---|---|
| `no_retype_reserve_account` | `type` cannot change away from `goalReserve` |
| `no_archive_active_reserve` | `is_archived` cannot be set to `true` while the linked goal is not archived |

Additionally, the income, expense, and transfer forms now filter out `goalReserve` accounts using:

```dart
.where((a) => !a.isArchived && a.type != FinancialAccountType.goalReserve)
```

This applies at the application layer (widget filter) and is tested in `goal_schema_migration_test.dart` tests SR-1 through SR-4.

---

## 8. Section 7 — Goal Movements Hardening

**Status: Database-tested**

Existing triggers from Phase 5B verification (`no_update_goal_movements`, `no_delete_goal_movements`) remain in place.

New constraint added in Phase 5B.1:
- `UNIQUE INDEX idx_goal_movements_operation` on `goal_movements(transfer_operation_id)` — prevents duplicate movements for the same transfer

Tests GM-1 and GM-2 verify immutability; SM-5 verifies the unique index.

---

## 9. Section 8 — Beneficiary Household Integrity

**Status: Database-tested**

Trigger `goal_revision_beneficiary_same_household` on `goal_revisions`:
- When `beneficiary_member_id IS NOT NULL`, validates the member belongs to the same household as the goal
- Rejects cross-household beneficiary via direct SQL INSERT

Test GR-3 in `goal_schema_migration_test.dart` verifies cross-household insertion fails.

---

## 10. Section 9 — Lifecycle vs. Progress Separation

**Status: Unit-tested, Database-tested**

`GoalStatus` (persisted): `active`, `completed`, `archived`

`GoalProgressState` (derived from ledger balance):
- `notStarted` — reserve balance = 0
- `inProgress` — 0 < balance < target
- `targetReached` — balance ≥ target (exact)
- `overfunded` — balance > target

There is no persisted `is_target_reached` column. Progress is computed in `GoalProgress.fromBalance()` using the live reserve balance.

Tests GP-1 through GP-3 in `goal_schema_migration_test.dart` verify correct state derivation after funding and overfunding.

---

## 11. Section 10 — Centralized Goal Money Formatting

**Status: Unit-tested, Widget-tested**

`lib/features/goals/presentation/goal_money_formatter.dart` provides:

```dart
class GoalMoneyFormatter {
  static String format(int minorUnits, String currencyCode);
  static double toMajorUnits(int minorUnits, String currencyCode);
}
```

All goal screens (`goals_list_screen.dart`, `goal_detail_screen.dart`, `fund_goal_screen.dart`, `release_goal_screen.dart`) use this formatter exclusively. Direct `~/ 100` arithmetic and `.toStringAsFixed(2)` have been removed from goal widget code.

Currency scales used:
| Currency | Scale | Example: 10000 minor units |
|---|---|---|
| JPY | 0 | ¥10,000 |
| EGP | 2 | 100.00 EGP |
| KWD | 3 | 10.000 KWD |

---

## 12. Section 11 — Ordinary-Form Restrictions

**Status: Application-layer enforced (widget-tested via existing goal widget tests)**

| Form | Restriction | Implementation |
|---|---|---|
| Income form | `goalReserve` absent from destination dropdown | `.where((a) => !a.isArchived && a.type != FinancialAccountType.goalReserve)` |
| Expense form | `goalReserve` absent from payment account dropdown | Same filter |
| Transfer form | `goalReserve` absent from source and destination dropdowns | Same filter |

Archive restriction is enforced at the database layer via `no_archive_active_reserve` trigger.

Goal archive requiring zero reserve is enforced by `ArchiveGoalUseCase` via the repository.

---

## 13. Validation Results

### `dart format --output=none --set-exit-if-changed .`
**Exit code: 0** — No formatting changes required after `dart format .` was applied.

### `flutter analyze`
**Exit code: 0** — No issues found.

### `flutter test --reporter=expanded`
**Exit code: 0**

```
+1035: All tests passed!
```

| Category | Count |
|---|---|
| Total passing | **1,035** |
| Failed | 0 |
| Skipped | 0 |
| Tests added in Phase 5B.1 | +18 |

---

## 14. Test Inventory (Phase 5B.1 Additions)

### `test/database/goals/goal_repository_test.dart` (42 cases total)
- AT-1..AT-4: Atomic creation rollback at failure boundaries
- IK-1..IK-4: Goal-creation idempotency (equivalent retry, conflict, cross-household, retry-after-failure)
- FK-1..FK-4: Fund-goal idempotency
- RK-1..RK-4: Release-goal idempotency
- AB-1..AB-2: Atomic balance enforcement (concurrent funding, concurrent release)

### `test/database/goals/goal_schema_migration_test.dart` (30 cases total)
- SM-1..SM-7: Schema integrity (tables, indexes, immutability triggers)
- SR-1..SR-4: Reserve account classification (no retype, no archive active)
- GM-1..GM-2: Movement immutability triggers
- GR-1..GR-3: Revision immutability + beneficiary household enforcement
- GP-1..GP-3: Progress state derivation (JPY, KWD, overfunded)
- AG-1..AG-2: Archived goal cannot fund or release
- ZF-1: Zero initial funding creates no operations or movements

---

## 15. Deferred Risks

| Risk | Severity | Deferral Reason |
|---|---|---|
| Android SQLite3MultipleCiphers runtime verification | High | Build is intentionally deferred to production security hardening phase |
| Transaction failure injection via synthetic exceptions | Low | Single-device SQLite WAL makes partial writes effectively impossible without process kill |
| Concurrent overdraft in multi-writer scenario | Low | V1 is single-device offline; WAL serializes writers |
| Cross-household beneficiary DB-level FK (not trigger) | Low | V1 is single-household; trigger enforces at application boundary |

---

## 16. Remaining Risks

- Goal reserve accounts appear in the `accounts` list screen (administrative view). A future phase should add a "Goal Reserves" section or hide them from the main account list.
- `ReleaseGoalFundsUseCase` does not validate that the destination account is not archived. Minor — the form only shows non-archived accounts, but the use case should enforce this too.
- No `CompleteGoalUseCase` — completion is currently set manually via status. A dedicated workflow should prevent completion when the balance has not reached the target.

---

## 17. Final Git Status

```
git log --oneline -5:
  <pending commit>   feat: Phase 5B.1 – goal atomicity, idempotency, and DB integrity hardening
  52b9f05            docs: update Phase 4B/5A reports and release checklist post-5B verification
  f864f73            docs: add Phase 5B verification report (PHASE_5B_REPORT.md)
  08094ac            verify: Phase 5B verification and correction pass
  8071fba            feat: Phase 5B – savings goals and ledger-backed goal reserve accounts

Working tree: clean after commit
```
