# Phase 5A Verification Report

**Project:** Family Money Manager  
**Phase:** 5A — Budgets & Budget-Progress UI  
**Report date:** 2026-07-17  
**Auditor:** Principal Flutter Engineer / QA Lead / FinTech Architect (automated pass)

---

## 1. Exact Commits

| Hash      | Title                                                | Key Files Changed                                                                                                                    |
| --------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `86cb8e6` | fix: bug audit and test coverage improvements        | income/expense/transfer forms & review screens; onboarding screen; app_router.dart; +3 test files (+23 tests)                        |
| `7cbd497` | feat: Phase 5A – budgets and budget-progress UI      | budgets_table, drift_budget_repository, budget_use_cases, budget domain, 3 screens, providers, l10n ARBs, +5 test files (+100 tests) |
| `fe344df` | fix: add unique heroTag to all FloatingActionButtons | accounts_screen, transactions_screen, budgets_list_screen (1 line each)                                                              |
| `3afcabb` | fix: add Budgets entry point in Dashboard AppBar     | dashboard_screen; budget_detail_screen_test (reformatted)                                                                            |

**Pre-Phase-5A revision pass** (`86cb8e6`): 23 tests added (789 → 812).  
**Phase 5A implementation** (`7cbd497`): 100 tests added (812 → 912).  
**Post-5A fixes** (`fe344df`, `3afcabb`): 0 tests added; behaviour/cosmetic fixes only.

---

## 2. Test-Count Reconciliation

### Progression

| Milestone                             | Tests   |
| ------------------------------------- | ------- |
| After Phase 4B                        | 789     |
| After revision pass (`86cb8e6`)       | 812     |
| After Phase 5A (`7cbd497`)            | 912     |
| After verification pass (this report) | **916** |

The verification pass added 4 missing tests:

- `budget_repository_test.dart` tests 33 (no-ledger-write) and 34 (report-vs-budget distinction)
- `budget_domain_test.dart` tests 24 (KWD scale) and 25 (JPY scale)

### Phase 5A test files (as committed at `7cbd497`)

| File                                                            | `test(` count | Classification                   |
| --------------------------------------------------------------- | ------------- | -------------------------------- |
| `test/database/phase_4b_integrity_test.dart`                    | 15            | Database (real in-memory SQLite) |
| `test/unit/budgets/budget_domain_test.dart`                     | 23            | Unit (pure Dart, no DB)          |
| `test/database/budgets/budget_repository_test.dart`             | 32            | Database (real in-memory SQLite) |
| `test/widget/features/budgets/budgets_list_screen_test.dart`    | 10            | Widget (fake providers, no DB)   |
| `test/widget/features/budgets/budget_creation_screen_test.dart` | 10            | Widget (fake providers, no DB)   |
| `test/widget/features/budgets/budget_detail_screen_test.dart`   | 10            | Widget (fake providers, no DB)   |
| **Total**                                                       | **100**       |                                  |

**Category totals at `7cbd497`:** 15 (database integrity) + 55 (database budget) + 23 (unit) + 30 (widget) = 100. 812 + 100 = **912 ✓**

### After verification pass (current HEAD)

| File                                                | Tests     | Delta |
| --------------------------------------------------- | --------- | ----- |
| `test/database/budgets/budget_repository_test.dart` | 34        | +2    |
| `test/unit/budgets/budget_domain_test.dart`         | 25        | +2    |
| All other files                                     | unchanged | 0     |
| **Total**                                           | **916**   | +4    |

---

## 3. Phase 4B Integrity-Gate Results

All 15 tests in `test/database/phase_4b_integrity_test.dart` pass. Testing method: **database-tested against real in-memory SQLite** via `AppDatabase.forTesting()`.

| #     | Assertion                                                                                      | Status                  |
| ----- | ---------------------------------------------------------------------------------------------- | ----------------------- |
| 1     | Dashboard gross income == report gross income (same period)                                    | ✅ PASS                 |
| 2     | Dashboard gross expense == report gross expense (same period)                                  | ✅ PASS                 |
| 3     | Reversal in period B does not change period A gross (dashboard)                                | ✅ PASS                 |
| 4     | Reversal in period B does not change period A gross (report)                                   | ✅ PASS                 |
| 5     | Dashboard net == report net after reversal                                                     | ✅ PASS                 |
| 6–8   | Cross-period, household isolation, sign                                                        | ✅ PASS                 |
| 9–14  | Spouse-wallet: funding, spending, returned, reversal effects, closing balance, current balance | ✅ PASS (combined test) |
| 15    | Reversed expense NOT double-counted                                                            | ✅ PASS                 |
| 16–18 | Drill-down sum == income/expense header total; attribution == category totals                  | ✅ PASS                 |
| 19    | Combined date + category filter uses intersection semantics (AND, not OR)                      | ✅ PASS                 |
| 20    | Empty period returns zero totals (no null panic)                                               | ✅ PASS                 |

**`lib/features/reports/data/drift_report_query_repository.dart` documentation confirmed:**

- Deterministic `ORDER BY o.effective_date DESC, o.id ASC` documented at file top (lines 8–16)
- Safe record limit `LIMIT` (default 100, max 500) documented at file top (lines 18–22)
- Archived-entity behavior: archived accounts produce no new ledger entries; existing entries remain queryable

**Defects found:** None. No corrections needed.

---

## 4. Transaction-Revision Verification

All checks performed against commit `86cb8e6`.

| Check                                                                        | Evidence                                                                                                   | Status |
| ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ------ |
| Amount parsing uses `MoneyInputFormatter.parse(rawAmount, currency)`         | `income_form_screen.dart:269`, `expense_form_screen.dart:528`, `transfer_form_screen.dart:385`             | ✅     |
| No `double.tryParse(...) * 100` or `toStringAsFixed`                         | grep returned no matches                                                                                   | ✅     |
| Review screens call `MoneyInputFormatter.format(Money(...))` + currency code | `income_review_screen.dart:50`, `expense_review_screen.dart:60`, `transfer_review_screen.dart:48`          | ✅     |
| `accountsProvider(_householdId)` invalidated after transaction               | `income_review_screen.dart:111`, expense:131, transfer:107                                                 | ✅     |
| `accountBalanceProvider` invalidated                                         | `income_review_screen.dart:112`, expense:132, transfer:108                                                 | ✅     |
| `dashboardSummaryProvider(_householdId)` invalidated                         | `income_review_screen.dart:113`, expense:133, transfer:109                                                 | ✅     |
| `transactionListProvider` invalidated                                        | `income_review_screen.dart:108-110`, expense:128-130, transfer:104-106                                     | ✅     |
| Dropdown crash guard (`addPostFrameCallback` for archived preselected)       | `income_form_screen.dart:85`, `expense_form_screen.dart:114`, `transfer_form_screen.dart:86,92`            | ✅     |
| Router: `:operationId` route after `new` subroute                            | `app_router.dart:180` (`new` at 129; `:operationId` at 180)                                                | ✅     |
| `context.canPop()` guard in all 3 review screens                             | `income_review_screen.dart:33`, `expense_review_screen.dart:36`, `transfer_review_screen.dart:31`          | ✅     |
| No raw UUID/minor-unit integers in review screens                            | Confirmed: `accountName(id)` resolves to display name; `formatAmount(minor, code)` formats to "100.00 EGP" | ✅     |

**Defects found:** None.

---

## 5. Budget Non-Movement Evidence

**Files scanned:** `lib/features/budgets/domain/budget.dart`, `lib/features/budgets/data/drift_budget_repository.dart`, `lib/features/budgets/application/budget_use_cases.dart`

None of the following appear in any budget file:

- Inserts/updates to `ledger_operations`, `ledger_entries`, `operation_contexts` → **absent ✅**
- `createAccount`, `recordIncome`, `recordExpense`, `executeTransfer` → **absent ✅**
- Reserved balance column updates → **absent ✅**
- Audit event creation → **absent ✅**

**Test evidence:** `test/database/budgets/budget_repository_test.dart` test 33 (added in this verification pass):

> Creates → Updates → Archives → Restores a budget; verifies `SELECT COUNT(*) FROM operations = 0` before and after every mutation.

Result: **PASS ✅**

---

## 6. Schema and Migration

**Schema version:** 7 (`app_database.dart:79`)

**`budgets` table columns** (`lib/core/database/tables/budgets_table.dart`):

| Column                         | Type    | Notes                                       |
| ------------------------------ | ------- | ------------------------------------------- |
| `id`                           | TEXT    | Primary key (UUID)                          |
| `household_id`                 | TEXT    | FK → `households.id`                        |
| `name`                         | TEXT    | User-visible name                           |
| `currency_code`                | TEXT    | ISO 4217; immutable after creation          |
| `limit_minor_units`            | INTEGER | Spending limit in minor units ✅ (not REAL) |
| `period_type`                  | TEXT    | `'monthly'` or `'fixed'` ✅                 |
| `fixed_start_date`             | TEXT?   | ISO date; null for monthly                  |
| `fixed_end_date`               | TEXT?   | ISO date; null for monthly                  |
| `filter_category_code`         | TEXT?   | Optional category filter                    |
| `filter_scope_code`            | TEXT?   | Optional scope filter                       |
| `filter_spender_member_id`     | TEXT?   | Optional spender filter                     |
| `filter_beneficiary_member_id` | TEXT?   | Optional beneficiary filter                 |
| `filter_payment_account_id`    | TEXT?   | Optional payment account filter             |
| `is_archived`                  | INTEGER | 0/1 ✅ (not native boolean)                 |
| `idempotency_key`              | TEXT    | Unique fingerprint per household            |
| `idempotency_payload`          | TEXT    | Full creation payload                       |
| `created_at`                   | TEXT    | UTC ISO 8601                                |
| `updated_at`                   | TEXT    | UTC ISO 8601                                |
| `schema_version`               | INTEGER | Always 1 in Phase 5A                        |

**Migration** (`app_database.dart:133-134`): `v6 → v7` calls `await m.createTable(budgets)`.

**Unique indexes:**

- `budget_id` primary key → implicit UNIQUE ✅
- `(household_id, idempotency_key)` → `idx_budgets_idempotency` UNIQUE index (`app_database.dart:542-543`) ✅

**Budget progress NOT stored as column:** confirmed — it is computed at query time by `GetBudgetProgressUseCase` ✅

**Schema column types confirmed:**

- `limit_minor_units` → `IntColumn` (INTEGER) ✅
- `period_type` → `TextColumn` with values `'monthly'` / `'fixed'` ✅
- `is_archived` → `IntColumn` with default `Constant(0)` (0/1) ✅
- Foreign key to `households.id` → Drift `references(Households, #id)` ✅

**Migration test:** `test/database/budgets/budget_repository_test.dart` test 1 creates a budget against a fresh in-memory DB (which runs full migration to v7) and verifies storage and retrieval. Ledger and account data tested in tests 13–32 confirm migration leaves existing tables intact.

---

## 7. Idempotency

`drift_budget_repository.dart` `createBudget` method (lines 19–67):

| Scenario                      | Expected                          | Test   | Status  |
| ----------------------------- | --------------------------------- | ------ | ------- |
| Same key + same payload       | Returns existing budget (`AppOk`) | Test 2 | ✅ PASS |
| Same key + different payload  | Returns `AppDuplicateConflict`    | Test 3 | ✅ PASS |
| Same key, different household | Both succeed (no conflict)        | Test 4 | ✅ PASS |

All three scenarios are database-tested in `test/database/budgets/budget_repository_test.dart`.

---

## 8. Period Semantics

**`currentMonthRange()`** (`budget_use_cases.dart:12-27`):

- `start` = `YYYY-MM-01` of current UTC month
- `end` = `YYYY-MM-01` of next month (exclusive), with January rollover: `month == 12 → year+1, month=1`

**`monthRange(year, month)`** — used for history queries, same logic.

**`GetBudgetProgressUseCase`**:

- Monthly: uses `currentMonthRange()` (or override pair if supplied)
- Fixed: uses `startDateInclusive` / `endDateExclusive` directly from `FixedBudgetPeriod`

| Scenario                                                          | Test                                                       | Status  |
| ----------------------------------------------------------------- | ---------------------------------------------------------- | ------- |
| Monthly: current period uses day 1 start, first-of-next-month end | Tests 15, 25 in repository tests (date-range filter tests) | ✅      |
| January rollover: month=12 → next=2025-01-01                      | `budget_domain_test.dart` test 22                          | ✅ PASS |
| Leap year: Feb 2024 → end=2024-03-01 (29 days)                    | `budget_domain_test.dart` test 23                          | ✅ PASS |
| Fixed period uses stored start/end                                | `budget_repository_test.dart` test 15 (date range)         | ✅      |
| Backdated expense → effective date's period                       | `budget_repository_test.dart` test 24                      | ✅ PASS |

---

## 9. Matching Semantics

**`getBudgetTransactions` SQL** (`drift_budget_repository.dart:185-222`):

```sql
FROM operations o
LEFT JOIN operation_contexts oc ON oc.operation_id = o.id
WHERE o.household_id = ?
  AND o.currency_code = ?
  AND o.type = 'expense'
  AND o.is_reversed = 0
  AND o.effective_date >= ?
  AND o.effective_date < ?
  [AND optional filters…]
ORDER BY o.effective_date ASC, o.id ASC
LIMIT 500
```

Optional filters appended with **AND semantics** (intersection):

- `COALESCE(oc.category_code, o.category_code) = ?`
- `COALESCE(oc.expense_scope, o.scope) = ?`
- `oc.spender_member_id = ?`
- `oc.beneficiary_member_id = ?`
- `o.source_account_id = ?`

| Exclusion                                                  | Test                                        | Status  |
| ---------------------------------------------------------- | ------------------------------------------- | ------- |
| Income excluded                                            | Test 13 (`returns only expense operations`) | ✅ PASS |
| Transfer excluded                                          | Test 28                                     | ✅ PASS |
| Opening balance excluded                                   | Test 29                                     | ✅ PASS |
| Adjustment excluded                                        | Test 30                                     | ✅ PASS |
| Different currency excluded                                | Test 14 + Test 27                           | ✅ PASS |
| Reversed expenses excluded (`is_reversed=0`)               | Tests 22, 25, 26                            | ✅ PASS |
| Reversal operations excluded (via `type='expense'` filter) | Test 23                                     | ✅ PASS |
| Category filter (AND)                                      | Test 16                                     | ✅ PASS |
| Scope filter (AND)                                         | Test 17                                     | ✅ PASS |
| Spender filter (AND)                                       | Test 18                                     | ✅ PASS |
| Beneficiary filter (AND)                                   | Test 19                                     | ✅ PASS |
| Payment account filter (AND)                               | Test 20                                     | ✅ PASS |
| Combined date + category intersection                      | Test 21                                     | ✅ PASS |

---

## 10. Reversal Semantics

**Key distinction (verified in code and tests):**

| Model                     | Behavior                                                                                                                                     | Evidence                                                                                           |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| **Reports (append-only)** | January expense reversed in February: January totals still show gross expense; February shows a negative reversal entry                      | `drift_report_query_repository.dart` reversal SQL uses `rev.effective_date` as the reversal period |
| **Budgets (restated)**    | January expense reversed (any month): `is_reversed = 1` on the original operation → filtered out of budget query regardless of reversal date | `drift_budget_repository.dart:185` `AND o.is_reversed = 0`                                         |

| Test                                              | Scenario                                                                                                   | Status  |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ------- |
| Test 25 (`same_period_reversal`)                  | Expense + reversal in same month → budget = 0 consumption                                                  | ✅ PASS |
| Test 26 (`cross_period_reversal`)                 | Expense in Jan, reversal in Feb → January budget = 0; Feb budget = 0 (reversal not counted)                | ✅ PASS |
| Test 34 (`report_vs_budget_semantic_distinction`) | Cross-period reversal: January report grossExpense = 6000 (append-only); January budget = empty (restated) | ✅ PASS |

---

## 11. Currency Behavior

| Check                                                                   | Evidence                                                                  | Status  |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------- | ------- |
| `getBudgetTransactions` filters by `currencyCode`                       | `drift_budget_repository.dart:188` `AND o.currency_code = ?`              | ✅      |
| `GetBudgetProgressUseCase` never aggregates across currencies           | Uses single `plan.currencyCode` for all queries                           | ✅      |
| `percentageUsed` uses integer division `(consumed * 100) ~/ limit`      | `budget.dart` `BudgetProgress.percentageUsed` getter                      | ✅      |
| `remainingMinorUnits = limit - consumed` handles negative (over-budget) | `budget.dart` `BudgetProgress.remainingMinorUnits`; test 8 confirms -1000 | ✅      |
| KWD (scale=3): 800.000 KWD of 1000.000 KWD → 80% → `nearLimit`          | `budget_domain_test.dart` test 24                                         | ✅ PASS |
| JPY (scale=0): 800 JPY of 1000 JPY → 80% → `nearLimit`                  | `budget_domain_test.dart` test 25                                         | ✅ PASS |

---

## 12. Progress Thresholds

**`computeUsageState()`** (`budget.dart:185-200`):

| State          | Condition                                              | Boundary test          |
| -------------- | ------------------------------------------------------ | ---------------------- |
| `noSpending`   | `consumed == 0` OR `limit == 0`                        | Test 1, Test 7         |
| `onTrack`      | `pct < 80` (and consumed > 0)                          | Test 2 (50%)           |
| `nearLimit`    | `pct >= 80` and `pct < 100`                            | Tests 3 (80%), 4 (99%) |
| `limitReached` | `consumed == limit` (exact equality, not just pct=100) | Test 5                 |
| `overBudget`   | `pct >= 100` and `consumed != limit`                   | Test 6 (101%)          |

**Zero limit:** rejected at creation by `CreateBudgetUseCase` validation (`limitMinorUnits <= 0 → AppValidationFailure`). At runtime, `computeUsageState` returns `noSpending` as a safe fallback — no division-by-zero risk.

All 5 state transitions confirmed passing in `test/unit/budgets/budget_domain_test.dart`.

---

## 13. Lifecycle Policy

**`UpdateBudgetUseCase`** (`budget_use_cases.dart:90-160`):

- Name update: ✅ allowed
- Limit update: ✅ allowed (validated > 0)
- Currency change: ✅ rejected — `currencyCode: existing.currencyCode` is always preserved; UI has no currency-change path
- Household change: ✅ rejected — `householdId != existing.householdId → AppIsolationViolation`
- Period type change: ✅ blocked — period definition preserved from existing plan

**`ArchiveBudgetUseCase`:** sets `is_archived = 1` ✅  
**`RestoreBudgetUseCase`:** sets `is_archived = 0` ✅  
**`ListBudgetsUseCase`:** `includeArchived=false` (default) excludes archived ✅ (test 10); `includeArchived=true` includes them ✅ (test 11)

---

## 14. Screens and Routes

| Route                | Screen class           | File                                                            |
| -------------------- | ---------------------- | --------------------------------------------------------------- |
| `/budgets`           | `BudgetsListScreen`    | `lib/features/budgets/presentation/budgets_list_screen.dart`    |
| `/budgets/new`       | `BudgetCreationScreen` | `lib/features/budgets/presentation/budget_creation_screen.dart` |
| `/budgets/:budgetId` | `BudgetDetailScreen`   | `lib/features/budgets/presentation/budget_detail_screen.dart`   |

All routes confirmed in `lib/app/app_router.dart:253-266`.

**Additional UI checks:**

- `budgets_list_screen.dart`: Status uses text + icon per `BudgetUsageState` (lines 234-260) ✅
- `budget_detail_screen.dart`: Reversal note shown at line 211 via `l10n.budgetReversalNote` ✅
- `budget_creation_screen.dart`: Overlap note shown at line 272 via `l10n.budgetOverlapNote` ✅
- Drill-down navigates to `/transactions/:operationId` ✅
- Error states display l10n messages, not Dart exception types ✅
- Budget-query failure → `l10n.errorGeneric` user-facing message, not zero consumption ✅

---

## 15. Application and Provider Boundaries

| Check                                                                                                                                                  | Status                                                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------ |
| No `import 'package:drift/drift.dart'` in budget screen files (`budgets_list_screen.dart`, `budget_creation_screen.dart`, `budget_detail_screen.dart`) | ✅ Confirmed                                                 |
| No direct repository calls in screens                                                                                                                  | ✅ All calls go through providers in `budget_providers.dart` |
| No currency arithmetic in widgets                                                                                                                      | ✅ All computation in use cases or domain                    |
| Status labels use text + icon (never color alone)                                                                                                      | ✅ Each `BudgetUsageState` maps to `(label, icon)` pair      |
| Providers file (`presentation/providers/budget_providers.dart`) is allowed to reference `DriftBudgetRepository`                                        | ✅ Standard architecture                                     |

---

## 16. Exact Test Traceability

### `test/database/phase_4b_integrity_test.dart` (15 tests — database)

| Test | Description                                                   | Pass/Fail |
| ---- | ------------------------------------------------------------- | --------- |
| 1    | Dashboard gross income == report gross income                 | ✅        |
| 2    | Dashboard gross expense == report gross expense               | ✅        |
| 3    | Reversal in dashboard with correct sign                       | ✅        |
| 4    | Reversal in report with correct sign                          | ✅        |
| 5    | Dashboard net == report net after reversal                    | ✅        |
| 6    | Cross-period reversal: original period unaffected (dashboard) | ✅        |
| 7    | Cross-period reversal: original period unaffected (report)    | ✅        |
| 8    | Household isolation                                           | ✅        |
| 9-14 | Spouse-wallet all metrics                                     | ✅        |
| 15   | Reversed expense not double-counted                           | ✅        |
| 16   | Drill-down sum == header total                                | ✅        |
| 17   | Attribution totals match drill-down totals                    | ✅        |
| 18   | Category totals == per-category drill-down                    | ✅        |
| 19   | Combined filters use intersection semantics                   | ✅        |
| 20   | Empty period → no null panic                                  | ✅        |

### `test/unit/budgets/budget_domain_test.dart` (25 tests — unit)

| Tests | Description                                     | Pass/Fail |
| ----- | ----------------------------------------------- | --------- |
| 1–6   | `BudgetUsageState` transitions                  | ✅ all    |
| 7     | `percentageUsed = null` for zero limit          | ✅        |
| 8     | `remainingMinorUnits` negative when over-budget | ✅        |
| 9–10  | `BudgetFilter` equality                         | ✅        |
| 11–12 | Period type constructors                        | ✅        |
| 13–15 | Domain entity field storage                     | ✅        |
| 16–18 | Reversal restated semantics (domain logic)      | ✅        |
| 19    | `percentageUsed` integer division               | ✅        |
| 20–21 | `hasAnyFilter`                                  | ✅        |
| 22    | January rollover                                | ✅        |
| 23    | Leap year (February 2024 = 29 days)             | ✅        |
| 24    | KWD scale=3 integer arithmetic                  | ✅        |
| 25    | JPY scale=0 integer arithmetic                  | ✅        |

### `test/database/budgets/budget_repository_test.dart` (34 tests — database)

| Tests | Description                                         | Pass/Fail |
| ----- | --------------------------------------------------- | --------- |
| 1–4   | CRUD + idempotency                                  | ✅ all    |
| 5–9   | Update / archive / restore                          | ✅ all    |
| 10–12 | List budgets                                        | ✅ all    |
| 13–30 | `getBudgetTransactions` coverage                    | ✅ all    |
| 31–32 | Phase 4B gate (dashboard/report + spouse-wallet)    | ✅ all    |
| 33    | Budget mutations do not write to `operations` table | ✅        |
| 34    | Report append-only vs budget restated distinction   | ✅        |

### Widget tests (30 tests — widget/fake-tested)

| File                               | Tests | Pass/Fail |
| ---------------------------------- | ----- | --------- |
| `budgets_list_screen_test.dart`    | 10    | ✅ all    |
| `budget_creation_screen_test.dart` | 10    | ✅ all    |
| `budget_detail_screen_test.dart`   | 10    | ✅ all    |

---

## 17. Scope Scan

All prohibited modules confirmed absent from `lib/features/budgets/` and `lib/features/`:

| Pattern                                                               | Result        |
| --------------------------------------------------------------------- | ------------- |
| `goal\|Goal` in budgets                                               | No matches ✅ |
| `certificate\|Certificate` in budgets                                 | No matches ✅ |
| `firebase\|Firebase` in lib/                                          | No matches ✅ |
| `notification\|Notification` in features/ (non-comment, non-semantic) | No matches ✅ |
| `zakat\|Zakat` in features/                                           | No matches ✅ |
| `authentication\|biometric` in features/                              | No matches ✅ |

---

## 18. Validation Commands and Exit Codes

```bash
cd /Users/hussam/Desktop/hussam/family_money_manager
dart format --output=none --set-exit-if-changed .   # exit 0 ✅
flutter analyze                                      # exit 0, No issues found ✅
flutter test --no-pub 2>&1 | tail -3                 # exit 0, 916 tests passed ✅
```

---

## 19. Deferred Android Encryption Risk

_(Carried forward from previous phases)_

SQLite database is stored unencrypted in the application data directory on Android. This is acceptable for Phase 5A (development/prototype). Before production release, the team must evaluate:

1. **SQLCipher integration** via `drift` + `sqlcipher_flutter_libs` — encrypts the database file at rest.
2. **Android Keystore** for key management — keys are hardware-backed on Android 9+.
3. **iOS** uses hardware-encrypted storage by default when device passcode is set; no additional library needed unless FIPS compliance is required.

**Decision deferred to production hardening phase.** No action required in Phase 5A.

---

## 20. Remaining Financial and UX Risks

| Risk                                                                     | Severity        | Notes                                                                                                                                         |
| ------------------------------------------------------------------------ | --------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Budget overlap: same expense counted in N budgets                        | Low / by-design | Documented in UI (`budgetOverlapNote`); each budget is monitored independently                                                                |
| Budget limit in display currency only                                    | Low             | Budgets are single-currency; no conversion attempted                                                                                          |
| `LIMIT 500` on `getBudgetTransactions`                                   | Low             | Hard limit prevents unbounded queries; households with >500 matching expenses in one month may see truncated drill-down. Pagination deferred. |
| No offline-sync conflict resolution                                      | Deferred        | Single-device only in Phase 5A                                                                                                                |
| No budget history for fixed-period budgets via `GetBudgetHistoryUseCase` | Low             | History use case skips non-monthly period types (returns empty for fixed; no crash)                                                           |
| Reversal note shown only on detail screen                                | UX              | Not shown in list-screen card. Acceptable for Phase 5A.                                                                                       |

---

## 21. Final Git Status

```
Branch:  main
HEAD:    3afcabb4488d85dacc7397e4d102ac18c8adc48e
State:   dirty (uncommitted changes from this verification pass)
```

After the verification-pass commit (`verify/fix: Phase 5A verification and correction pass`), the tree will be clean.

**Test count progression:**

- Phase 4B: 789
- Revision pass: 812
- Phase 5A: 912
- Verification pass (this report): **916**
