# Phase 5A Report — Budgets and Budget-Progress UI

**Date**: 2026-07-17
**Branch**: main
**HEAD**: a78e77d (prior commit; Phase 5A uncommitted)
**Flutter test exit code**: 0 (all 912 tests pass)
**dart format exit code**: 0
**flutter analyze exit code**: 0 (no issues)

---

## Phase 4B Report-Integrity Gate — Findings

### Gate Scope

Before starting any budget code, the following were inspected:
- `docs/PHASE_4B_REPORT.md` and `docs/PHASE_4A_REPORT.md`
- `lib/features/reports/data/drift_report_query_repository.dart`
- `lib/features/dashboard/data/drift_dashboard_query_repository.dart`
- `lib/features/dashboard/application/get_dashboard_summary_use_case.dart`
- All report application use cases in `lib/features/reports/application/`
- Existing test files in `test/database/`

### Reversal Semantic Consistency — Confirmed

The **period-activity model** is implemented consistently in both the dashboard and report queries:

| Invariant | Dashboard | Reports |
|-----------|-----------|---------|
| Original expense stays in its effective period | ✓ | ✓ |
| Reversal contributes inverse effect in its own effective period | ✓ | ✓ |
| Cumulative totals reconcile naturally across periods | ✓ | ✓ |
| Reversal does NOT silently remove earlier period activity | ✓ | ✓ |

Both queries use `is_reversed` and the reversal operation type to determine which rows to include, but neither removes the original row from the time period it occurred in.

### Query Safety Comment Added

A `/// DETERMINISTIC ORDER POLICY` comment block was added at the top of `drift_report_query_repository.dart` documenting:
- All queries use `ORDER BY effective_date DESC, operation_id ASC` for stable pagination
- A `LIMIT 500` safe record cap on drill-down queries

### Tests Created in `test/database/phase_4b_integrity_test.dart` (20 tests)

**Classification**: Database-tested

1. Dashboard gross income == report gross income for same period
2. Dashboard gross expense == report gross expense for same period
3. Reversal appears in both dashboard and report with correct net effect
4. Income reversal reduces dashboard income total
5. Expense reversal reduces dashboard expense total
6. Income reversal reduces report income total
7. Expense reversal reduces report expense total
8. Reversal in different period does not affect original period totals
9–14. Spouse-wallet: funding, spending, returned, reversal effects, closing balance, current balance all correct
15. Spouse-wallet: multiple reversals handled cumulatively
16. Report-to-drill-down: income report total == sum of drill-down income rows
17. Report-to-drill-down: expense report total == sum of drill-down expense rows
18. Attribution: spending attribution total per scope == sum of attributed rows
19. Category totals: sum of category drill-down == category total
20. Combined filters: date + category intersection semantics verified

---

## Phase 5A: Budgets and Budget-Progress UI

### Scope Scan — Confirmed No Out-of-Scope Items

The following were **not** introduced:
- Goals, goal reserve accounts, certificates, gold, investments, liabilities
- Firebase, synchronization, authentication, PIN, biometrics, backup
- Notifications, voice, AI, automatic recurring transactions
- Android/iOS/emulator builds
- True net worth, Zakat, sadaqah

---

## Budget Domain Model

### File: `lib/features/budgets/domain/budget.dart`

**Classification**: Unit-tested

#### Entities

| Type | Description |
|------|-------------|
| `BudgetId` | `typedef String` — stable client-generated UUID |
| `BudgetPeriodType` | `enum { monthly, fixed }` |
| `BudgetUsageState` | `enum { noSpending, onTrack, nearLimit, limitReached, overBudget }` |
| `BudgetPeriodDefinition` | `sealed class` with `MonthlyBudgetPeriod` and `FixedBudgetPeriod` |
| `BudgetFilter` | 5 optional filter fields; has `copyWith`, `==`, `hashCode` |
| `BudgetPlan` | Core immutable budget entity (no money, no accounts) |
| `BudgetTransactionRow` | Single expense row contributing to budget consumption |
| `BudgetProgress` | Computed progress for a period; includes `percentageUsed`, `remainingMinorUnits` |

#### `computeUsageState` Thresholds

| Threshold | State |
|-----------|-------|
| consumed == 0 | `noSpending` |
| 0 < pct < 80 | `onTrack` |
| 80 ≤ pct < 100 | `nearLimit` |
| pct == 100 | `limitReached` |
| pct > 100 | `overBudget` |

---

## Period Model

- **Monthly**: Rolling current calendar month (UTC). Historical queries accept `periodStart`/`periodEnd` overrides.
- **Fixed**: Immutable `startDateInclusive` / `endDateExclusive` pair stored at creation. No drift. No re-anchoring.
- Periods are **exclusive-end** (ISO 8601 half-open interval convention).

---

## Matching and Overlap Behavior

Budgets are **independent monitors**. Multiple budgets may cover overlapping date ranges and/or overlapping filter dimensions. Each budget is evaluated independently. There is no conflict detection, allocation, or deduction between budgets.

Overlap explanation is shown in the creation UI: "Budgets may overlap — each is monitored independently."

---

## Restated Budget-Reversal Policy

**Budget consumption uses restated semantics**, distinct from report period-activity semantics:

| Model | Reversed Expense Treatment |
|-------|---------------------------|
| Report (period-activity) | Original expense stays in its period; reversal appears with inverse effect in its own period. Both rows visible. |
| Budget (restated V1) | Reversed expense is excluded entirely (`is_reversed = 0` filter). The reversal row is also excluded (`type != 'reversal'`). Net effect: zero consumption. |

This is a deliberate design decision for budgets: if you bought groceries and returned them, your groceries budget should not count that purchase. The period-activity model is preserved for reports because it gives an accurate audit trail.

The SQL filter is in `DriftBudgetRepository.getBudgetTransactions`:
```sql
AND o.is_reversed = 0
AND o.type = 'expense'
-- (reversal operations are excluded by type filter)
```

UI disclosure: "Fully reversed expenses count as zero toward this budget" shown in `BudgetDetailScreen`.

---

## Currency Behavior

- Each `BudgetPlan` is fixed to a single `currencyCode` at creation.
- `getBudgetTransactions` filters by `currency_code` in SQL.
- The list screen does **not** show any mixed-currency grand total.
- `currencyCode` is immutable after creation (`updateBudget` ignores currency changes).

---

## Idempotency

- Each `BudgetPlan` carries an `idempotencyKey` (UUID v4, client-generated) and an `idempotencyPayload` (JSON-normalized definition string).
- A unique index on `(household_id, idempotency_key)` is enforced in the database.
- `createBudget` behavior:
  - Same key + same payload → returns existing plan (safe retry)
  - Same key + different payload → `AppDuplicateConflict`
  - Different key → new budget (even if definition is identical; allowed per V1 spec)

---

## Schema and Migration

### New Table: `budgets`

| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT PK | Client UUID |
| `household_id` | TEXT NOT NULL | FK to households |
| `name` | TEXT NOT NULL | |
| `currency_code` | TEXT NOT NULL | |
| `limit_minor_units` | INTEGER NOT NULL | |
| `period_type` | TEXT NOT NULL | `'monthly'` or `'fixed'` |
| `fixed_start_date` | TEXT nullable | ISO date |
| `fixed_end_date` | TEXT nullable | ISO date (exclusive) |
| `filter_category_code` | TEXT nullable | |
| `filter_scope_code` | TEXT nullable | |
| `filter_spender_member_id` | TEXT nullable | |
| `filter_beneficiary_member_id` | TEXT nullable | |
| `filter_payment_account_id` | TEXT nullable | |
| `is_archived` | INTEGER NOT NULL DEFAULT 0 | 0/1 |
| `idempotency_key` | TEXT NOT NULL UNIQUE | |
| `idempotency_payload` | TEXT NOT NULL | |
| `created_at` | TEXT NOT NULL | UTC ISO 8601 |
| `updated_at` | TEXT NOT NULL | UTC ISO 8601 |
| `schema_version` | INTEGER NOT NULL DEFAULT 1 | |

**Schema version**: `6 → 7`

**Migration step** (in `app_database.dart`):
```dart
from6To7: (m, schema) async {
  await m.createTable(budgets);
  await _applyBudgetIdempotencyIndex();
}
```

The unique index `budgets_idempotency_idx` on `(household_id, idempotency_key)` enforces scoped idempotency.

---

## Progress Queries

`GetBudgetProgressUseCase.execute(budgetId)`:
1. Loads `BudgetPlan` from repository
2. Computes effective period:
   - Monthly: first day of current UTC month to first day of next month
   - Fixed: plan's `startDateInclusive` / `endDateExclusive`
   - Override: if `periodStart`/`periodEnd` provided (for historical queries)
3. Calls `getBudgetTransactions(householdId, currencyCode, periodStart, periodEnd, filter)`
4. Computes `consumedMinorUnits = sum(row.amountMinorUnits)`
5. Computes `usageState` from thresholds
6. Returns `BudgetProgress`

`GetBudgetHistoryUseCase.execute(budgetId, numberOfMonths: 6)`:
- For monthly budgets only
- Calls `getBudgetProgress` for each of the last N calendar months
- Returns `List<BudgetProgress>` ordered newest-first

---

## Screens and Routes

### Routes Added to `app_router.dart`

| Route | Screen |
|-------|--------|
| `/budgets` | `BudgetsListScreen` |
| `/budgets/new` | `BudgetCreationScreen` |
| `/budgets/:budgetId` | `BudgetDetailScreen` |

Routes are pushed (not tabs) to avoid disrupting the existing 5-tab bottom navigation layout.

### `BudgetsListScreen`

- Watches `budgetsProvider(householdId)`
- Shows: loading, error, empty state (with create button), populated list
- Each card: name, currency, progress bar, consumed/limit, status badge (text + icon)
- No mixed-currency total
- Archive filter toggle in AppBar
- FAB → `/budgets/new`
- Tap card → `/budgets/:budgetId`

### `BudgetCreationScreen`

- Fields: name, currency dropdown, limit amount, period type (SegmentedButton: Monthly / Fixed)
- Fixed period: start/end date pickers
- Optional filters: category, scope, spender, beneficiary, payment account (all dropdown, nullable)
- Overlap note displayed
- Validation: name not empty, limit > 0, if fixed then end > start
- On success: navigates to `/budgets/:newBudgetId`

### `BudgetDetailScreen`

- Watches `budgetProgressProvider(budgetId)`
- Shows: name, period dates, progress bar, consumed/limit/remaining, percentage, status (text + icon)
- Reversal note: "Fully reversed expenses count as zero toward this budget"
- Drill-down transaction list (date, amount, category, note)
- Archive/Restore button in AppBar
- Monthly budgets: Previous periods section (last 5 entries from `budgetHistoryProvider`)

---

## Application and Provider Boundaries

```
UI Screen
  └─ FutureProvider.family (budgetsProvider / budgetProgressProvider / etc.)
       └─ Use Case (e.g. GetBudgetProgressUseCase)
            └─ BudgetRepository (interface)
                 └─ DriftBudgetRepository (Drift + AppDatabase)
```

Use cases contain all business logic (validation, period calculation, usage state computation).
Drift repository contains all SQL and handles `AppResult` wrapping.
Providers are thin wires; no business logic.

---

## Localization

All strings are in both `app_en.arb` and `app_ar.arb`. No hardcoded strings in UI code.

**Keys added** (36 total):
`budgetsTitle`, `budgetNew`, `budgetName`, `budgetCurrency`, `budgetLimit`, `budgetLimitFixed`,
`budgetPeriodMonthly`, `budgetPeriodFixed`, `budgetStartDate`, `budgetEndDate`,
`budgetCategoryFilter`, `budgetScopeFilter`, `budgetSpenderFilter`, `budgetBeneficiaryFilter`,
`budgetAccountFilter`, `budgetOverlapNote`, `budgetStatusNoSpending`, `budgetStatusOnTrack`,
`budgetStatusNearLimit`, `budgetStatusLimitReached`, `budgetStatusOverBudget`,
`budgetConsumed`, `budgetRemaining`, `budgetPercent`, `budgetReversalNote`,
`budgetEmpty`, `budgetArchived`, `budgetArchive`, `budgetRestore`,
`budgetPreviousPeriods`, `budgetNoMatching`,
`errorBudgetNameEmpty`, `errorBudgetLimitZero`, `errorBudgetEndBeforeStart`, `errorBudgetCurrencyRequired`

---

## Test Traceability

### `test/unit/budgets/budget_domain_test.dart` — 23 tests

**Classification**: Unit-tested

| # | Test | Classification |
|---|------|----------------|
| 1 | BudgetUsageState.noSpending when consumed == 0 | Unit-tested |
| 2 | BudgetUsageState.onTrack at 50% | Unit-tested |
| 3 | nearLimit at 80% | Unit-tested |
| 4 | nearLimit at 99% | Unit-tested |
| 5 | limitReached at 100% | Unit-tested |
| 6 | overBudget at 101% | Unit-tested |
| 7 | percentageUsed == null when limitMinorUnits == 0 | Unit-tested |
| 8 | remainingMinorUnits negative when over budget | Unit-tested |
| 9 | BudgetFilter equality (same fields) | Unit-tested |
| 10 | BudgetFilter inequality (different fields) | Unit-tested |
| 11 | MonthlyBudgetPeriod has no date fields | Unit-tested |
| 12 | FixedBudgetPeriod holds start and end | Unit-tested |
| 13 | BudgetPlan stores all fields | Unit-tested |
| 14 | BudgetTransactionRow stores isReversed | Unit-tested |
| 15 | BudgetProgress.matchingTransactionCount | Unit-tested |
| 16 | Reversed expense contributes 0 (restated semantics) | Unit-tested |
| 17 | Multiple reversed: all contribute 0 | Unit-tested |
| 18 | Mixed: 2 normal + 1 reversed = sum of 2 normal | Unit-tested |
| 19 | percentageUsed rounds down (integer division) | Unit-tested |
| 20 | BudgetFilter.hasAnyFilter false when all null | Unit-tested |
| 21 | BudgetFilter.hasAnyFilter true when category set | Unit-tested |
| 22 | January rollover: month 12 → month 1 next year | Unit-tested |
| 23 | Leap year: February 2024 has 29 days | Unit-tested |

### `test/database/budgets/budget_repository_test.dart` — 32 tests

**Classification**: Database-tested

| # | Test | Classification |
|---|------|----------------|
| 1 | Create budget — stored and retrieved | Database-tested |
| 2 | Idempotency: same key + payload → existing | Database-tested |
| 3 | Idempotency conflict: same key + different payload | Database-tested |
| 4 | Cross-household isolation | Database-tested |
| 5 | Update name | Database-tested |
| 6 | Update limit | Database-tested |
| 7 | Update filter | Database-tested |
| 8 | Archive | Database-tested |
| 9 | Restore | Database-tested |
| 10 | List — excludes archived by default | Database-tested |
| 11 | List — includes archived when flagged | Database-tested |
| 12 | List — isolated per household | Database-tested |
| 13 | getBudgetTransactions — expense only (not income) | Database-tested |
| 14 | getBudgetTransactions — matching currency | Database-tested |
| 15 | getBudgetTransactions — date range (inclusive start, exclusive end) | Database-tested |
| 16 | getBudgetTransactions — category filter (AND semantics) | Database-tested |
| 17 | getBudgetTransactions — scope filter | Database-tested |
| 18 | getBudgetTransactions — spender filter | Database-tested |
| 19 | getBudgetTransactions — beneficiary filter | Database-tested |
| 20 | getBudgetTransactions — payment account filter | Database-tested |
| 21 | Combined filters (date + category) intersection | Database-tested |
| 22 | Excludes reversed expenses (restated semantics) | Database-tested |
| 23 | Excludes reversal operations | Database-tested |
| 24 | Backdated expense in correct period | Database-tested |
| 25 | Same-period reversal: expense excluded | Database-tested |
| 26 | Cross-period reversal: original period consumption = 0 | Database-tested |
| 27 | Multiple currencies: EGP budget sees only EGP | Database-tested |
| 28 | Transfer excluded | Database-tested |
| 29 | Opening balance excluded | Database-tested |
| 30 | Adjustment excluded | Database-tested |
| 31 | Phase 4B gate: dashboard == report total | Database-tested |
| 32 | Phase 4B gate: spouse-wallet reversal metrics | Database-tested |

### `test/database/phase_4b_integrity_test.dart` — 20 tests

**Classification**: Database-tested (see Phase 4B section above)

### `test/widget/features/budgets/budgets_list_screen_test.dart` — 10 tests

**Classification**: Widget-tested

| # | Test |
|---|------|
| 1 | Loading state (CircularProgressIndicator) |
| 2 | Empty state + create button |
| 3 | Error state |
| 4 | Budget card shows name and currency |
| 5 | No mixed-currency total |
| 6 | Status badge shows text (not color-only) |
| 7 | Arabic RTL layout |
| 8 | English LTR layout |
| 9 | Tap card navigates |
| 10 | FAB present |

### `test/widget/features/budgets/budget_creation_screen_test.dart` — 10 tests

**Classification**: Widget-tested

| # | Test |
|---|------|
| 1 | Name field present |
| 2 | Currency dropdown present |
| 3 | Limit field present |
| 4 | Monthly period option visible |
| 5 | Fixed period shows date pickers |
| 6 | Overlap explanation text |
| 7 | Empty name → validation error |
| 8 | Zero limit → validation error |
| 9 | Fixed period changes limit label |
| 10 | Arabic RTL layout |

### `test/widget/features/budgets/budget_detail_screen_test.dart` — 10 tests

**Classification**: Widget-tested

| # | Test |
|---|------|
| 1 | Budget name shown |
| 2 | Consumed and limit formatted amounts |
| 3 | Remaining label present |
| 4 | Status text (not color-only) |
| 5 | Progress bar |
| 6 | Reversal note shown |
| 7 | Drill-down transactions listed |
| 8 | Archive button present |
| 9 | Monthly budget shows previous periods |
| 10 | Arabic RTL layout |

---

## Database-Tested vs Fake-Tested Behavior

| Behavior | How Tested |
|----------|-----------|
| SQL query correctness (joins, filters, ordering) | Database-tested (in-memory Drift DB) |
| Idempotency key enforcement | Database-tested |
| Unique index constraint | Database-tested |
| Restated semantics (reversal exclusion) | Database-tested |
| Cross-period reversal | Database-tested |
| Multi-currency isolation | Database-tested |
| Budget progress computation (use case layer) | Unit-tested (via domain model assertions) |
| UI rendering (loading / empty / error / data) | Widget-tested (provider overrides) |
| Form validation | Widget-tested |

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/features/budgets/domain/budget.dart` | Domain entities |
| `lib/core/database/tables/budgets_table.dart` | Drift table definition |
| `lib/features/budgets/data/budget_repository.dart` | Repository interface |
| `lib/features/budgets/data/drift_budget_repository.dart` | Drift implementation |
| `lib/features/budgets/application/budget_use_cases.dart` | All use cases |
| `lib/features/budgets/presentation/providers/budget_providers.dart` | Riverpod providers |
| `lib/features/budgets/presentation/budgets_list_screen.dart` | List UI |
| `lib/features/budgets/presentation/budget_creation_screen.dart` | Creation UI |
| `lib/features/budgets/presentation/budget_detail_screen.dart` | Detail UI |
| `test/unit/budgets/budget_domain_test.dart` | 23 unit tests |
| `test/database/budgets/budget_repository_test.dart` | 32 DB tests |
| `test/database/phase_4b_integrity_test.dart` | 20 integrity gate tests |
| `test/widget/features/budgets/budgets_list_screen_test.dart` | 10 widget tests |
| `test/widget/features/budgets/budget_creation_screen_test.dart` | 10 widget tests |
| `test/widget/features/budgets/budget_detail_screen_test.dart` | 10 widget tests |

## Files Modified

| File | Change |
|------|--------|
| `lib/core/database/app_database.dart` | Added `Budgets` table, `schemaVersion` 6→7, migration |
| `lib/core/database/app_database.g.dart` | Regenerated by build_runner |
| `lib/app/app_router.dart` | Added `/budgets`, `/budgets/new`, `/budgets/:budgetId` routes |
| `lib/core/localization/l10n/app_en.arb` | Added 35 budget keys |
| `lib/core/localization/l10n/app_ar.arb` | Added 35 Arabic translations |
| `lib/core/localization/app_localizations*.dart` | Regenerated by flutter gen-l10n |
| `lib/features/reports/data/drift_report_query_repository.dart` | Added deterministic order policy comment |

---

## Dependencies and Resolved Versions

No new dependencies were added. All budget features use existing packages:
- `drift` (already present) for database
- `flutter_riverpod ^3.3.2` for state management
- `go_router` for navigation
- `intl` for date formatting in creation screen

---

## Commands and Exit Codes

| Command | Exit Code |
|---------|-----------|
| `dart run build_runner build --delete-conflicting-outputs` | 0 |
| `flutter gen-l10n` | 0 |
| `dart format .` | 0 |
| `flutter analyze` | 0 (no issues) |
| `flutter test --no-pub` | 0 (912 tests passed) |

---

## Deferred Android Encryption Release Risk

The `AppDatabase` uses SQLite via Drift without SQLCipher encryption. This was an acknowledged risk in prior phases. Phase 5A does not change this posture. When encryption is introduced in a future phase, the `budgets` table will be included in the migration path automatically.

---

## Remaining Business and UX Risks

| Risk | Severity | Notes |
|------|----------|-------|
| No budget overlap detection | Medium | V1 design decision; documented in UI |
| Fixed period budgets have no "re-open" concept | Low | Archive/restore handles it |
| No budget duplication / template feature | Low | Out of scope V1 |
| No real-time progress recalculation | Low | Riverpod `invalidate` on nav; acceptable for now |
| Currency list is static | Low | `Currency.values` enum; expandable |
| `GetBudgetProgressUseCase` uses UTC for month boundaries | Medium | May not match user's local timezone; flagged for V2 |
| 500-row LIMIT on drill-down | Low | Acceptable for household scale |
| No pagination in `listBudgets` | Low | Acceptable for household scale (< 100 budgets) |

---

## Git Status Summary

```
Modified files: 10
New files: 15
Schema version: 7
Total tests: 912 (all passing)
```

Commit pending (see next step).
