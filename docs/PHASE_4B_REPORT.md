# Phase 4B — Financial Reports & Analytical Drill-Down

**Date:** 2026-07-16  
**Baseline commit:** `3dc83b5` (685 tests)  
**Final test count:** 789/789  
**dart format:** exit 0 (0 files changed)  
**flutter analyze:** exit 0 (18 info-level hints, 0 warnings, 0 errors)  
**flutter test:** exit 0 (789/789 pass)

---

## 1. Reversal-Reporting Gate (Step 1)

### Problem
The Phase 4A dashboard `periodFlow` query filtered income/expense operations with `is_reversed = false`,
silently erasing reversed operations from period totals. This violated the **period-activity model**:
every operation must appear in the period containing its `effectiveDate`, regardless of later reversal.

### Period-Activity Model (mandatory)
| Operation | When it appears | Where it appears |
|---|---|---|
| Original income/expense | `effectiveDate` in period T | T gross income/expense |
| Reversal (`type = 'reversal'`) | `effectiveDate` in period T or T+1 | Reversal effect for that period |

### Fix Applied
`lib/features/dashboard/data/drift_dashboard_query_repository.dart` — `periodFlow` method rewrote to two SQL queries:

1. **Gross query** (no `is_reversed` filter): `SUM` of all `income`/`expense` operations in the period.
2. **Reversal query**: `SUM` of `reversal` operations in the period joined to their originals to classify as income-reversal or expense-reversal.

`lib/features/dashboard/domain/dashboard_summary.dart` — `PeriodFlowSummary` expanded:
- `grossIncomeMinorUnits`, `grossExpenseMinorUnits` (stored)
- `incomeReversalMinorUnits`, `expenseReversalMinorUnits` (stored)
- `netIncomeMinorUnits`, `netExpenseMinorUnits`, `netCashFlowMinorUnits` (derived getters)
- Backward-compatible aliases `incomeMinorUnits = grossIncomeMinorUnits`, `expenseMinorUnits = grossExpenseMinorUnits`

Dashboard UI (`dashboard_screen.dart`) updated to show gross + reversal effect rows when reversals are non-zero.

---

## 2. Files Created / Modified

### Domain Models
| File | Status | Description |
|---|---|---|
| `lib/features/reports/domain/report_filter.dart` | **CREATED** | `ReportFilter` — immutable filter criteria |
| `lib/features/reports/domain/report_models.dart` | **CREATED** | 11 immutable report models + `FinancialReportRequest` |

### Data Layer
| File | Status | Description |
|---|---|---|
| `lib/features/reports/data/report_query_repository.dart` | **CREATED** | Interface — 11 focused methods |
| `lib/features/reports/data/drift_report_query_repository.dart` | **CREATED** | Drift/SQLite implementation with raw SQL |

### Application (Use Cases)
| File | Status | Description |
|---|---|---|
| `lib/features/reports/application/get_income_expense_report_use_case.dart` | **CREATED** | `AppResult<List<CurrencyFlowSummary>>` |
| `lib/features/reports/application/get_spending_attribution_report_use_case.dart` | **CREATED** | Spender / beneficiary / scope |
| `lib/features/reports/application/get_category_report_use_case.dart` | **CREATED** | Category breakdown |
| `lib/features/reports/application/get_account_flow_report_use_case.dart` | **CREATED** | Account flows |
| `lib/features/reports/application/get_home_savings_report_use_case.dart` | **CREATED** | Home savings flows |
| `lib/features/reports/application/get_spouse_wallet_report_use_case.dart` | **CREATED** | Spouse wallet |
| `lib/features/reports/application/get_protected_funds_report_use_case.dart` | **CREATED** | Protected funds |
| `lib/features/reports/application/get_report_transactions_use_case.dart` | **CREATED** | Drill-down transaction list |

### Presentation Layer
| File | Status | Description |
|---|---|---|
| `lib/features/reports/presentation/providers/report_providers.dart` | **CREATED** | Repository + use case + 8 data providers |
| `lib/features/reports/presentation/report_widgets.dart` | **CREATED** | Shared widgets (loading, error, empty, amount, period selector) |
| `lib/features/reports/presentation/reports_landing_screen.dart` | **CREATED** | Landing — 7 report tiles |
| `lib/features/reports/presentation/income_expense_report_screen.dart` | **CREATED** | Gross/net income & expense per currency |
| `lib/features/reports/presentation/spending_attribution_report_screen.dart` | **CREATED** | Spender / beneficiary / scope |
| `lib/features/reports/presentation/category_report_screen.dart` | **CREATED** | Income & expense by category |
| `lib/features/reports/presentation/account_flow_report_screen.dart` | **CREATED** | Per-account flows (opening/closing balance) |
| `lib/features/reports/presentation/home_savings_report_screen.dart` | **CREATED** | Home savings flows |
| `lib/features/reports/presentation/spouse_wallet_report_screen.dart` | **CREATED** | Spouse wallet funded/spent/returned |
| `lib/features/reports/presentation/protected_funds_report_screen.dart` | **CREATED** | Protected funds + withdrawal audit |
| `lib/features/reports/presentation/report_transaction_list_screen.dart` | **CREATED** | Generic drill-down transaction list |

### Modified Existing Files
| File | Change |
|---|---|
| `lib/features/dashboard/domain/dashboard_summary.dart` | Expanded `PeriodFlowSummary` |
| `lib/features/dashboard/data/drift_dashboard_query_repository.dart` | Fixed `periodFlow` query |
| `lib/features/dashboard/data/dashboard_query_repository.dart` | Updated doc comment |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | Show gross/reversal; Reports AppBar button |
| `lib/core/financial/dashboard_period.dart` | Added `==` / `hashCode` |
| `lib/app/app_router.dart` | 8 new report routes |
| `lib/core/localization/l10n/app_en.arb` | ~35 new Phase 4B keys |
| `lib/core/localization/l10n/app_ar.arb` | ~35 new Phase 4B keys (Arabic) |
| `lib/core/localization/l10n/app_localizations_en.dart` | Regenerated |
| `lib/core/localization/l10n/app_localizations_ar.dart` | Regenerated |

### Tests
| File | Tests | Status |
|---|---|---|
| `test/database/reversal_reporting_db_test.dart` | 8 | **CREATED** |
| `test/database/report_income_expense_db_test.dart` | 12 | **CREATED** |
| `test/database/report_attribution_db_test.dart` | 10 | **CREATED** |
| `test/database/report_category_db_test.dart` | 8 | **CREATED** |
| `test/database/report_account_flow_db_test.dart` | 10 | **CREATED** |
| `test/database/report_home_savings_db_test.dart` | 8 | **CREATED** |
| `test/database/report_spouse_wallet_db_test.dart` | 10 | **CREATED** |
| `test/database/report_protected_funds_db_test.dart` | 8 | **CREATED** |
| `test/widget/features/reports/reports_landing_screen_test.dart` | 8 | **CREATED** |
| `test/widget/features/reports/income_expense_report_screen_test.dart` | 10 | **CREATED** |
| `test/widget/features/reports/attribution_report_screen_test.dart` | 6 | **CREATED** |
| `test/widget/features/reports/spouse_wallet_report_screen_test.dart` | 6 | **CREATED** |
| `test/helpers/fake_report_query_repository.dart` | helper | **CREATED** |

**DB tests added:** 74 (8+12+10+8+10+8+10+8)  
**Widget tests added:** 30 (8+10+6+6)  
**Total new tests:** 104  
**Total: 685 (baseline) + 104 = 789**

---

## 3. Key Design Decisions

### No New Drift Tables
All report queries read from existing tables: `operations`, `ledger_entries`, `operation_contexts`,
`financial_accounts`, `household_members`, `child_withdrawal_audits`. No `build_runner` re-run required.

### Riverpod v3 Notifier Pattern
`reportRequestProvider` uses `NotifierProvider<ReportRequestNotifier, FinancialReportRequest>` (not
the deprecated `StateProvider`) matching the existing `dashboardPeriodProvider` pattern.

### Navigation — No 6th Tab
Report entry point is an `IconButton` (bar_chart icon) in the Dashboard AppBar. Routes are pushed on
top of the shell: `/reports`, `/reports/income-expense`, `/reports/attribution`, etc.

### Per-Currency, No Mixed Totals
Every report screen shows data grouped by `currencyCode`. No cross-currency summation is ever shown.

### Account Flow Reconciliation Invariant
Tested in `report_account_flow_db_test.dart` test 8:
```
opening + income - expense + transfersIn - transfersOut + adjustments + reversalEffect = closing
```

### Spouse Wallet Standard Scenario
`report_spouse_wallet_db_test.dart` test 1 asserts:
```
funded=2000, spent=1300, returned=200, closing=500
```

---

## 4. Scope Scan Results

| Pattern | Result |
|---|---|
| `budget\|Budget` | **NONE** — clean |
| `goal\|Goal` (excl. GoRoute) | `goalFunding/goalWithdrawal` in `ledger_enums.dart` — pre-existing enum values, no new feature |
| `certificate` | Pre-existing enum value + doc comment only |
| `net.worth\|netWorth` | Pre-existing schema column + trigger only |
| `zakat.*calc` | Pre-existing doc comment only |
| `export\|csv\|pdf` | **NONE** — clean |
| `chart\|fl_chart` | `Icons.bar_chart` (navigation icon) + doc comments only — no chart library |
| `firebase` | Doc comments only — no import/usage |
| `notification` | **NONE** — clean |

---

## 5. Bug Fixed

**`report_spouse_wallet_db_test.dart` test 6** initially failed because `spouseWalletReports`
`periodSql` had `AND le.is_reversal = 0` in the WHERE clause but used `is_reversal = 1` in CASE
expressions — a logical contradiction. Fixed by moving the `is_reversal` discriminator into each
CASE condition and removing it from the WHERE clause, allowing reversal entries to contribute to
`reversal_effect` correctly.

---

## 6. Validation

```
dart format --output=none --set-exit-if-changed .  → exit 0 (0 files changed)
flutter analyze                                     → exit 0 (18 info hints, 0 warnings, 0 errors)
flutter test                                        → exit 0 (789/789 pass)
```
