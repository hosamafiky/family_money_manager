# Phase 4A Report — Arabic-First Dashboard and Core Financial Summaries

**Date:** 2026-07-16  
**Branch:** main  
**Commit:** 17fb3d2  
**Base commit (Phase 3B.1):** 004cbbe  
**Test count before:** 614  
**Test count after:** 685 (+71)  
**dart format exit:** 0  
**flutter analyze exit:** 0  
**flutter test exit:** 0  

---

## Exact Test-Count Reconciliation

### Per-file test declarations (`grep -c "^\s*test\b\|^\s*testWidgets\b"`)

#### Database tests — 256 declared tests across 25 files

| File | Count |
|------|------:|
| `account_atomicity_db_test.dart` | 5 |
| `account_classification_immutability_db_test.dart` | 23 |
| `account_classification_migration_db_test.dart` | 3 |
| `account_creation_idempotency_db_test.dart` | 6 |
| `append_only_db_test.dart` | 18 |
| `archive_rules_db_test.dart` | 9 |
| `balance_semantics_db_test.dart` | 5 |
| `classification_immutability_db_test.dart` | 8 |
| `dashboard_balance_db_test.dart` *(Phase 4A)* | 34 |
| `dashboard_period_db_test.dart` *(Phase 4A)* | 7 |
| `expense_persistence_db_test.dart` | 11 |
| `historical_metadata_db_test.dart` | 4 |
| `household_cardinality_db_test.dart` | 7 |
| `idempotency_db_test.dart` | 8 |
| `income_persistence_db_test.dart` | 10 |
| `ledger_repository_db_test.dart` | 29 |
| `migration_db_test.dart` | 8 |
| `operation_context_db_test.dart` | 8 |
| `operation_context_migration_db_test.dart` | 6 |
| `ordering_determinism_db_test.dart` | 7 |
| `profile_isolation_db_test.dart` | 5 |
| `protected_account_db_test.dart` | 10 |
| `transaction_boundary_db_test.dart` | 6 |
| `transaction_history_db_test.dart` | 8 |
| `transfer_persistence_db_test.dart` | 11 |
| **Subtotal** | **256** |

#### Unit tests — 370 declared tests across 22 files

| File | Count |
|------|------:|
| `app_config_test.dart` | 15 |
| `app_result_test.dart` | 17 |
| `app_error_test.dart` | 7 |
| `ledger_calculator_test.dart` | 22 |
| `ledger_invariants_test.dart` | 12 |
| `money_boundary_test.dart` | 21 |
| `money_test.dart` | 48 |
| `validation_release_safe_test.dart` | 29 |
| `redacted_logger_test.dart` | 26 |
| `app_route_test.dart` | 8 |
| `money_input_formatter_test.dart` | 26 |
| `account_totals_service_test.dart` | 10 |
| `create_account_use_case_test.dart` | 7 |
| `financial_account_test.dart` | 19 |
| `dashboard_period_test.dart` *(Phase 4A)* | 6 |
| `dashboard_summary_test.dart` *(Phase 4A)* | 6 |
| `household_member_test.dart` | 19 |
| `household_use_cases_test.dart` | 10 |
| `initialize_household_use_case_test.dart` | 5 |
| `child_withdrawal_audit_test.dart` | 15 |
| `ledger_invariants_randomized_test.dart` | 7 |
| `operation_test.dart` | 35 |
| **Subtotal** | **370** |

#### Widget tests — 59 declared tests across 5 files

| File | Count |
|------|------:|
| `app_test.dart` | 14 |
| `accounts_screen_test.dart` | 6 |
| `dashboard_screen_test.dart` *(Phase 4A)* | 18 |
| `foundation_detail_screen_test.dart` | 6 |
| `smoke_screen_test.dart` | 15 |
| **Subtotal** | **59** |

**Grand total: 256 + 370 + 59 = 685 ✓**

### Phase 4A additions since commit 004cbbe (+71 tests)

| File | Tests added |
|------|------------:|
| `test/database/dashboard_balance_db_test.dart` (new) | +34 |
| `test/database/dashboard_period_db_test.dart` (new) | +7 |
| `test/unit/features/dashboard/dashboard_period_test.dart` (new) | +6 |
| `test/unit/features/dashboard/dashboard_summary_test.dart` (new) | +6 |
| `test/widget/features/dashboard/dashboard_screen_test.dart` (new) | +18 |
| **Total added** | **+71** |

No tests were removed or renamed. No parameterized loops inflate the count. 614 + 71 = **685 ✓**

### Assertion quality inspection (manual)

The "meaningful assertion" check was **manual**: each Phase 4A test file was read in full before running. No `expect(true, true)` stubs or empty `test('…', () {})` bodies exist. Every DB test inserts real data, calls real repository methods, and asserts financial outcomes (amounts, currency codes, inclusion/exclusion). Widget tests assert `find.text(...)`, `find.byIcon(...)`, and Semantics node presence.

---

## Date and Timezone Policy (exact)

From `lib/core/financial/dashboard_period.dart`:

```dart
/// TIMEZONE POLICY (V1):
/// All effective dates are stored as 'YYYY-MM-DD' strings without timezone offset.
/// Period calculations use the device's local timezone for UI display, but persisted
/// effectiveDate strings are compared lexicographically in SQL.
/// Household-specific timezone selection is deferred.
///
/// BACKDATING POLICY:
/// Period inclusion is determined by effectiveDate (user-chosen date),
/// NOT by recordedAt (system UTC timestamp).
```

### Period boundaries (tested in `dashboard_period_test.dart`)

| Period | startDate (inclusive) | endDate (exclusive) |
|--------|----------------------|---------------------|
| Current month (June 2025) | `2025-06-01` | `2025-07-01` |
| Previous month — **January 2025** | `2024-12-01` | `2025-01-01` |
| Current year (2025) | `2025-01-01` | `2026-01-01` |

**January→December rollover** tested: `previousMonth` from January 2025 uses `DateTime(2025, 0, 1)` which Dart normalizes to `2024-12-01`. Confirmed by test 2 in `dashboard_period_test.dart`.

**Inclusive start, exclusive end** confirmed: `contains('2025-03-01')` → true, `contains('2025-04-01')` → false (test 4).

**Backdated operations** appear in their `effectiveDate` period regardless of `recordedAt` — confirmed by DB test 18 in `dashboard_balance_db_test.dart`.

---

## 1. Classification-Integrity Gate (STEP 1)

**Status:** VERIFIED — no corrections needed.

### 1a. Schema v6 triggers
[CONFIRMED] All required triggers exist in `lib/core/database/app_database.dart`:
- `restrict_account_classification_update` — rejects changes to `type`, `currency_code`, `owner_type`, `fund_purpose`, `is_protected`, `is_spendable`, `include_in_net_worth`, `include_in_zakat` after any ledger entry exists.
- `restrict_child_fund_unprotect` — always rejects disabling `is_protected` on `childProtectedFund` regardless of history.
- `no_update_ledger_entries` — blocks all UPDATEs on `ledger_entries` (Phase 2).
- `restrict_operations_update` — blocks all UPDATEs on `operations` (Phase 2A).
- All account idempotency indexes present.

### 1b. Always-immutable fields
[CONFIRMED] The trigger `_applyAccountMetadataImmutabilityTrigger` additionally prevents `type` and `currency_code` from being changed even before any ledger entries. The `restrict_account_classification_update` trigger fires on the first ledger entry.

Cross-household changes are prevented by FK constraints on `household_id`.

### 1c. UpdateAccountMetadataUseCase policy
[CONFIRMED] The use case only accepts `name` and `notes` parameters. Classification fields (`type`, `currency_code`, `isProtected`, `isSpendable`, `includeInNetWorth`, `includeInZakat`) are not accepted. This is the complete V1 policy.

### 1d. ArchivedAccountTransferError
[CONFIRMED] `ArchivedAccountTransferError` subclasses `ArchivedAccountError`. The use case catch clause uses the base class. Done in Phase 3B.1.

---

## 2. New Files Created

### Core Domain
| File | Description |
|------|-------------|
| `lib/core/financial/dashboard_period.dart` | `Clock` abstraction, `SystemClock`, `DashboardPeriod` closed-open period, `DashboardPeriodLabel` enum |

### Dashboard Feature
| File | Description |
|------|-------------|
| `lib/features/dashboard/domain/dashboard_summary.dart` | `DashboardSummary`, `CurrencyAmountSummary`, `PeriodFlowSummary`, `ExpenseScopeSummary`, `SpouseWalletDashboardSummary` |
| `lib/features/dashboard/data/dashboard_query_repository.dart` | Abstract interface `DashboardQueryRepository` |
| `lib/features/dashboard/data/drift_dashboard_query_repository.dart` | Drift implementation with custom SQL |
| `lib/features/dashboard/application/get_dashboard_summary_use_case.dart` | `Future.wait` fan-out, typed `AppResult<DashboardSummary>` |
| `lib/features/dashboard/presentation/providers/dashboard_providers.dart` | `clockProvider`, `dashboardQueryRepositoryProvider`, `getDashboardSummaryUseCaseProvider`, `dashboardPeriodProvider`, `dashboardSummaryProvider` |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | Full Arabic-first dashboard UI |

### Tests
| File | Tests |
|------|-------|
| `test/database/dashboard_balance_db_test.dart` | 34 |
| `test/database/dashboard_period_db_test.dart` | 6 |
| `test/unit/features/dashboard/dashboard_period_test.dart` | 6 |
| `test/unit/features/dashboard/dashboard_summary_test.dart` | 5 |
| `test/widget/features/dashboard/dashboard_screen_test.dart` | 18 |
| `test/helpers/fake_dashboard_query_repository.dart` | (helper) |

---

## 3. Modified Files

| File | Change |
|------|--------|
| `lib/features/shell/app_shell.dart` | Added Dashboard tab (index 0); shifted Accounts→1, Transactions→2, Family→3, Settings→4 |
| `lib/app/app_router.dart` | Added `/dashboard` branch as first `StatefulShellBranch`; changed `initialLocation` to `/dashboard` |
| `lib/core/localization/l10n/app_en.arb` | Added 35 new Phase 4A keys |
| `lib/core/localization/l10n/app_ar.arb` | Added 35 new Phase 4A Arabic keys |
| `test/helpers/test_helpers.dart` | Added `appDatabaseProvider` + `dashboardSummaryProvider` overrides to prevent `CircularProgressIndicator` from timing out `pumpAndSettle` in integration-style app widget tests |

---

## 4. Architecture Decisions

### 4.1 Clock Abstraction
`Clock` is an abstract interface injected via Riverpod's `clockProvider`. Domain code never calls `DateTime.now()` directly. `SystemClock` is the production implementation. Tests override `clockProvider` with a fixed time.

### 4.2 DashboardPeriod — Closed-Open Interval
Period comparisons use `effectiveDate >= startDate AND effectiveDate < endDate` on `'YYYY-MM-DD'` string lexicographic ordering. This matches Drift SQL comparisons and avoids off-by-one errors with month boundaries.

### 4.3 Reversal Policy
- **Gross expense** (`expenseMinorUnits`): sum of ALL `expense` operations (including reversed ones).
- **Net expense** (`netExpenseMinorUnits`): sum of `expense` operations where `is_reversed = false`.
- The reversal operation itself (`type = 'reversal'`) is excluded from both income and expense totals.
- A fully reversed expense in period T has gross=N, net=0.

### 4.4 FutureProvider.autoDispose.family
`dashboardSummaryProvider` is `autoDispose.family<AppResult<DashboardSummary>, String>`. It re-executes whenever `dashboardPeriodProvider` changes. The `autoDispose` prevents memory leaks when navigating away from the dashboard.

### 4.5 NotifierProvider for Period State
`DashboardPeriodNotifier` exposes `setPeriod(DashboardPeriod)` as a public method to update state from widgets, avoiding the `invalid_use_of_protected_member` lint error that would arise from direct `.state = ` assignment from outside the notifier.

### 4.6 No Mixed-Currency Totals
No summation across currencies is performed anywhere. Each `CurrencyAmountSummary`, `PeriodFlowSummary`, and `ExpenseScopeSummary` is strictly per-currency. The UI renders one row per currency.

---

## 5. SQL Query Summary

### spendableBalances
```sql
SELECT currency_code, SUM(amount) FROM (
  SELECT le.currency_code,
    CASE WHEN le.direction = 'credit' THEN le.amount_minor_units
         ELSE -le.amount_minor_units END AS amount
  FROM ledger_entries le
  JOIN financial_accounts fa ON fa.id = le.account_id
  WHERE fa.household_id = ? AND le.household_id = ?
    AND fa.is_archived = 0 AND fa.is_spendable = 1 AND fa.is_protected = 0
) GROUP BY currency_code
```

### protectedBalances
Same but `fa.is_protected = 1`.

### periodFlow
```sql
SELECT o.currency_code, o.type, o.total_amount_minor_units, o.is_reversed
FROM operations o
WHERE o.household_id = ? AND o.type IN ('income','expense')
  AND o.effective_date >= ? AND o.effective_date < ?
```
Grouped in Dart by currency code.

### expensesByScope
Joins `operations` with `operation_contexts` via `COALESCE` for scope fallback. Filters by `type = 'expense'` and period.

### spouseWalletSummaries
Finds `type = 'spouseCashWallet'` accounts, then queries `ledger_entries` for funded/spent/returned components.

### recentActivity
Delegates to `DriftTransactionQueryRepository.recentOperations` (reuses Phase 3B implementation).

---

## 6. Localization

35 new ARB keys added to both `app_en.arb` and `app_ar.arb`. `flutter gen-l10n` run successfully. No generated files edited directly.

Key pairs (sample):
| Key | English | Arabic |
|-----|---------|--------|
| `dashboardTitle` | Dashboard | الرئيسية |
| `dashboardSpendableBalances` | Spendable Balances | الأرصدة المتاحة |
| `dashboardProtectedBalances` | Protected Balances | الأرصدة المحمية |
| `dashboardPeriodIncome` | Income | الدخل |
| `dashboardPeriodExpenses` | Expenses | المصروفات |
| `dashboardPeriodNet` | Net | الصافي |
| `dashboardNegativeBalanceWarning` | Negative balance — data integrity issue | رصيد سالب — مشكلة في سلامة البيانات |

---

## 7. Scope Scan Results

All grep commands run. Results:

| Pattern | Matches in lib/ | Verdict |
|---------|----------------|---------|
| `budget\|Budget` | 0 | ✅ Clean |
| `goal\|Goal` (excl. GoRoute/GoRouter) | 0 | ✅ Clean |
| `net.worth\|netWorth\|NetWorth` | Only pre-existing schema/domain fields | ✅ Not introduced in Phase 4A |
| `zakat\|Zakat` (excl. existing fields) | Only pre-existing `zakatExpense`, `includeInZakat` | ✅ Clean |
| `firebase\|Firebase` | Only in comments | ✅ Clean |
| `biometric\|Biometric` | Only in `child_withdrawal_audits` schema (Phase 2) | ✅ Clean |
| `chart\|Chart\|pie\|fl_chart` | Only "NO charts" comment in `dashboard_screen.dart:22` | ✅ Clean |
| `net worth` text in dashboard | `dashboard_screen.dart:22` comment confirms prohibition | ✅ Never displayed |

---

## 8. Test Coverage Summary

### Database Tests (40 new)
| Group | Tests | Covers |
|-------|-------|--------|
| spendable balances | 8 | archived exclusion, cross-household isolation, negative balance |
| protected balances | 3 | archived exclusion, child fund |
| period income/expense | 8 | transfer/opening-balance exclusion, reversal policy, backdating |
| expense scopes | 5 | personal/household/spouse/child scopes, reversed exclusion |
| spouse wallet | 6 | funded/spent/returned, period filter, multiple wallets |
| recent activity | 4 | ordering, reversal visibility, type variety, isolation |
| DashboardPeriod date boundaries | 6 | month/year boundaries, contains() |

### Unit Tests (11 new)
| Suite | Tests | Covers |
|-------|-------|--------|
| `dashboard_period_test.dart` | 6 | factories, January rollback, contains() |
| `dashboard_summary_test.dart` | 5 | hasSpendableBalance, hasProtectedBalance, hasPeriodActivity, isNegative |

### Widget Tests (18 new)
| Suite | Tests |
|-------|-------|
| `dashboard_screen_test.dart` | 18 |

Coverage: loading state, error+retry, empty state, per-currency balances, no net-worth text, no mixed-currency total, income/expense display, transfer label, reversed "معكوسة" badge, RTL/LTR layout, period selector, refresh, protected indicator, negative balance warning, large text overflow.

---

## 9. Constraints Compliance

| Constraint | Status |
|-----------|--------|
| No charts | ✅ Text cards only |
| No net worth display | ✅ Not displayed anywhere (only schema field for future use) |
| No mixed-currency totals | ✅ Strict per-currency separation |
| No budgets / goals | ✅ Absent |
| No Firebase / sync / auth | ✅ Absent |
| No biometrics (new) | ✅ Absent (only pre-existing `biometric_confirmed` audit field) |
| No mobile build | ✅ Compliant |
| No generated file edits | ✅ Only ARB and source Dart edited |
| Arabic-first UI | ✅ All text uses `AppLocalizations` with AR priority |

---

## 10. Invariant Summary

| ID | Description | Status |
|----|-------------|--------|
| INV-001 | Household isolation | ✅ All queries filter by `household_id` |
| INV-009 | No mixed-currency totals | ✅ Enforced at query and UI level |
| INV-011 | Transfers excluded from income/expense | ✅ `periodFlow` query uses `type IN ('income','expense')` |
| INV-017 | Classification immutability | ✅ DB triggers + Dart repo layer confirmed |
| REV-001 | Reversal policy | ✅ gross includes reversed, net excludes; documented and tested |

---

## 11. Validation Exit Codes

```
dart format --output=none --set-exit-if-changed . → exit 0 (0 changed after format applied)
flutter analyze --no-pub                          → exit 0 (No issues found)
flutter test                                      → exit 0 (685/685 passed)
```
