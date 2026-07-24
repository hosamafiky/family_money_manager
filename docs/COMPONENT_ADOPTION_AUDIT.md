# Component Adoption Audit — Phase 6B.3

Inventory of production screens vs Phase 6B.2 design-system components
(`lib/core/presentation/components/`).

Classifications:

- **Fully migrated** — uses shared scaffold/states/form/review/actions as the primary chrome
- **Partially migrated** — shared states and/or notices adopted; residual ad hoc Material remain
- **Not migrated** — still pre–design-system presentation
- **Intentionally exempt** — out of presentation redesign scope or already acceptable

| Screen | Classification | Notes |
|--------|----------------|-------|
| Dashboard | Fully migrated (6B.2) | Hierarchy + shared components |
| Accounts list | Fully migrated (6B.2) | Restriction badges, no mixed totals |
| Account detail | Partially migrated | Detail chrome not fully restyled in 6B.3 |
| Transactions list | Fully migrated (6B.2) | Unified tiles |
| Transaction detail | Partially migrated | Not deep-redesigned this phase |
| Income form | Fully migrated | Amount-first, `AppFormSection`, expandable details, bottom bar |
| Income review | Fully migrated | `AppReviewSection`, notices, `PrimaryActionButton` |
| Expense form | Fully migrated | Amount-first + attribution + protected notices |
| Expense review | Fully migrated | Shared review + protected notice |
| Transfer form | Fully migrated | Internal-transfer notice + amount-first |
| Transfer review | Fully migrated | Shared review + transfer explanation |
| Members | Intentionally exempt | More-hub surface; light touch only in 6B.2 |
| Settings | Intentionally exempt | More-hub surface |
| Budgets list | Partially migrated | Shared loading/empty/error + accessible progress semantics |
| Budget creation | Partially migrated | Educational `AppInlineNotice`s added; form layout still mostly Material |
| Budget detail | Partially migrated | Behavior preserved; full sectioned chrome deferred residual |
| Goals list | Partially migrated | Shared loading/empty/error |
| Goal creation | Partially migrated | Reserve/currency notices; structure residual |
| Goal detail | Partially migrated | Lifecycle vs progress already present; DS chrome residual |
| Fund / release goal | Partially migrated | Existing transfer notes; full review-pattern residual |
| Certificates list | Partially migrated | Shared loading/empty/error |
| Certificate creation | Partially migrated | Principal classification notices |
| Certificate detail / redeem / profit | Partially migrated | Calculations unchanged; deep DS residual |
| Reports landing | Fully migrated | `AppScreenScaffold` + responsive container |
| Report detail screens | Partially migrated | Existing `report_widgets` + currency isolation retained; period/filter DS residual |
| Report drill-down | Partially migrated | Same as report details |
| Onboarding | Intentionally exempt | One-time flow; not in 6B.3 deferred list as deep redesign |
| Planning hub / More hub | Fully migrated (6B.2) | Navigation hubs |

## Why partial remains

Phase 6B.3 prioritized **transaction forms and reviews** (highest daily friction) and
**educational notices + shared empty/loading/error** across planning/report lists.
Full progressive-disclosure restyles of every budget/goal/certificate/report detail
row remain accurate residual work rather than claimed complete migration.

## Golden tests

**Deferred** — repository has no stable golden infrastructure (`matchesGoldenFile` unused).
Decision: do not introduce brittle platform-dependent goldens in this phase.
