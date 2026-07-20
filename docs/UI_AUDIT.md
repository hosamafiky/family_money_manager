# UI Audit — Phase 6B.2 (pre-redesign)

**Baseline HEAD:** `857b1e4c1f083faeff9b9859b8e275d5cbb09673`  
**Validated code tip (6B.1.2):** `4022d988674aaa832f36a9d787416042627f3517`  
**Schema:** 19 · **Tests:** 1594 · **Branch:** `main` (clean)

Arabic-first Flutter app. Routes: `lib/app/app_router.dart`. Shell: `lib/features/shell/app_shell.dart`.

---

## 1. Navigation structure (as-built before 6B.2)

| Index | Path | Label (en) | Notes |
|------:|------|------------|-------|
| 0 | `/dashboard` | Dashboard | AppBar pushes certificates/goals/budgets/reports |
| 1 | `/accounts` | Accounts | Nested `/new`, `/:accountId` |
| 2 | `/transactions` | Transactions | Nested create/review/detail |
| 3 | `/members` | Family | |
| 4 | `/settings` | Settings | Locale + theme |

**Outside shell (pushed):** `/reports/*`, `/budgets/*`, `/goals/*`, `/certificates/*`, `/onboarding`  
**Legacy:** `/`, `/detail/:probeId`

### Recommended IA (adopt in 6B.2)

| Index | Path | Role |
|------:|------|------|
| 0 | `/dashboard` | Home |
| 1 | `/transactions` | Transactions |
| 2 | `/planning` | Hub → budgets, goals, certificates |
| 3 | `/reports` | Reports (paths preserved) |
| 4 | `/more` | Hub → accounts, members, settings |

Existing paths remain reachable; hubs are additive.

---

## 2. Cross-cutting findings

| Issue | Evidence | Redesign action |
|-------|----------|-----------------|
| Excessive AppBar icon row | Dashboard 4–5 icon buttons | Move planning/reports into tabs; keep refresh secondary |
| Card-heavy dashboard | Multiple `_SectionCard`s equal weight | Hierarchy: spendable → actions → period → attention → quieter metrics |
| No shared scaffold/empty/error | Private widgets per screen | Shared `App*` components |
| Duplicated amount/review rows | Transactions, certs, goals, reports | `FinancialAmountText`, `AppReviewSection` |
| Long forms equal weight | Expense ~575 lines | Amount-first + progressive disclosure |
| Bottom nav overcrowded with accounts/members | 5 tabs mix ops + setup | Planning + More hubs |
| Color-only risk | Income/expense greens/reds | Badges with text + icon |
| Report kit isolated | `report_widgets.dart` only | Align with design tokens / shared states |
| Thin typography roles | Partial TextTheme | Semantic financial text roles |
| Desktop/tablet | Bottom nav only | Adaptive NavigationRail |

---

## 3. Screen inventory

Legend for states: L=loading E=empty Err=error S=success.  
RTL/LTR: Material locale-driven unless noted. Large text / keyboard / SR = needs verification in 6B.2 tests.

### Onboarding — `/onboarding`

| Field | Value |
|-------|-------|
| Purpose | Bootstrap household |
| Primary task | Complete first-run setup |
| Primary action | Continue / finish |
| Secondary | None |
| Hierarchy | Title → explanation → action |
| Layout | Centered column |
| Entry | Redirect when household missing |
| L/E/Err/S | Basic progress; empty N/A |
| Issues | Generic Material feel |
| Action | Apply `AppScreenScaffold`, calm copy, RTL-safe |

### Dashboard — `/dashboard` (~905 lines)

| Field | Value |
|-------|-------|
| Purpose | Household financial snapshot |
| Primary task | See spendable + period flow + recent activity |
| Primary action | Quick add transaction (indirect via nav) |
| Secondary | Refresh; push planning/reports |
| Hierarchy | Period → balances → flows → activity (flat cards) |
| Layout | Scroll + section cards |
| Entry | Tab 0 / initialLocation |
| L/E/Err/S | Custom private widgets |
| Issues | Equal card weight; AppBar overcrowding; density |
| Action | Reorder per §9 brief; shared components; quieter secondary metrics |

### Transactions list — `/transactions`

| Field | Value |
|-------|-------|
| Purpose | Browse operations |
| Primary task | Find / open a transaction |
| Primary action | FAB / create |
| Hierarchy | List rows (inconsistent type cues) |
| Issues | Need unified row model |
| Action | `TransactionListTile`; shared filters/period |

### Create picker — `/transactions/new`

| Field | Value |
|-------|-------|
| Purpose | Choose income/expense/transfer |
| Action | Clear type tiles with badges (not icon-only) |

### Income / Expense / Transfer forms + reviews

| Field | Value |
|-------|-------|
| Routes | `.../income`, `.../expense`, `.../transfer` + `/review` |
| Issues | Long single-page forms; review rows duplicated |
| Action | Amount → account → category → member → date → optional → review; shared review pattern; keep idempotency |

### Transaction detail — `/transactions/:operationId`

| Field | Value |
|-------|-------|
| Purpose | Inspect one operation; reverse if allowed |
| Action | Review-style layout; specific reverse wording |

### Accounts list / create / detail

| Field | Value |
|-------|-------|
| Routes | `/accounts`, `/accounts/new`, `/accounts/:accountId` |
| Issues | Weak visual distinction for protected/goal/certificate/archived |
| Action | Type badges; no mixed-currency total; cert/goal messaging |

### Household members — `/members`

| Field | Value |
|-------|-------|
| Purpose | Manage members |
| Action | Move under More; keep path; tighten list density |

### Settings — `/settings`

| Field | Value |
|-------|-------|
| Purpose | Locale + theme |
| Action | Under More; keep path; System theme if already supported |

### Reports landing + drill-downs

| Field | Value |
|-------|-------|
| Routes | `/reports`, income-expense, attribution, categories, accounts, home-savings, spouse-wallet, protected-funds, transactions |
| Issues | Outside nav; charts/text alternatives uneven |
| Action | Shell Reports tab; shared period/currency; text alternatives; no net-worth labeling |

### Budgets list / create / detail

| Field | Value |
|-------|-------|
| Routes | `/budgets`, `/budgets/new`, `/budgets/:budgetId` |
| Issues | Progress may be color-forward |
| Action | Period/category/planned/consumed/remaining + non-color progress |

### Goals list / create / detail / fund / release

| Field | Value |
|-------|-------|
| Routes | `/goals`, `/new`, `/:goalId`, `/fund`, `/release` |
| Issues | Lifecycle vs derived progress can confuse |
| Action | Separate lifecycle vs progress; cert accounts excluded (already enforced) |

### Certificates list / create / detail / profit / redeem

| Field | Value |
|-------|-------|
| Routes | `/certificates`, `/new`, `/:id`, `/profit`, `/redeem` |
| Issues | Principal vs profit must stay visually distinct |
| Action | Clear purchase/redeem reviews; no implied accrual |

### Planning hub — `/planning` (new)

| Field | Value |
|-------|-------|
| Purpose | Single entry to budgets/goals/certificates |
| Action | Section list with natural Arabic labels |

### More hub — `/more` (new)

| Field | Value |
|-------|-------|
| Purpose | Accounts, members, settings |
| Action | Secondary destinations without overcrowding bottom nav |

### Legacy smoke / foundation

| Field | Value |
|-------|-------|
| Routes | `/`, `/detail/:probeId` |
| Action | Leave functional; do not feature in primary IA |

---

## 4. Reusable widget duplication

| Pattern | Locations | Target |
|---------|-----------|--------|
| Empty / error / loading | Dashboard, reports, lists | `AppEmptyState`, `AppErrorState`, `AppLoadingState` |
| Amount text | Dashboard, reports, forms | `FinancialAmountText` |
| Review row | I/E/T reviews, cert screens | `AppReviewSection` |
| Section card | Dashboard, smoke | Prefer surfaces + `SectionHeader`, not card-everywhere |
| Period chips | Dashboard, reports | `PeriodSelector` |

---

## 5. Arabic-first notes

- Default locale `ar_EG`; RTL automatic via Material.
- Verify: mirrored directional icons, amount alignment, long Arabic labels, dialog action order, chart legends.
- Do not merely mirror English layout — terminology and reading order first.

---

## 6. Accessibility gaps (pre-6B.2)

- Touch targets generally 48 via theme; verify custom ink wells.
- Screen-reader labels uneven (dashboard icons good; list rows uneven).
- Color-only income/expense risk.
- Large-text overflow on dense cards.
- No systematic keyboard/focus tests.

---

## 7. Redesign sequence (after this audit)

1. Design tokens + theme extensions  
2. Shared components  
3. Navigation hubs + shell  
4. Dashboard hierarchy  
5. Transaction list + entry/review  
6. Accounts / budgets / goals / certificates / reports  
7. State patterns + a11y/responsive widget tests  
8. Validation + `PHASE_6B_2_REPORT.md`

**Stop condition for audit:** common patterns established — redesign proceeds from this document.
