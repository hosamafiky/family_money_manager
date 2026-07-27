# Handoff — Family Money Manager redesign · build guide

**Target repo:** `hosamafiky/family_money_manager` (Flutter, branch `main`)
**Locale:** Arabic (Egypt) `ar_EG`, RTL primary. English LTR secondary.
**Read order:** this file → `../09 — D6 handoff & migration.dc.html` §04 (phase table) → the screen documents.

This supersedes the original `uploads/README.md` where the two disagree. That document was written
before the source was read screen by screen; **everything below was verified against the repo.**

---

## 0. What this is

A full redesign delivered as **19 HTML specification documents, 85 annotated artboards**. The designs
are references, not code to port: change the existing Flutter app to match them using its own
patterns — `ThemeExtension` tokens, the shared kit under `lib/core/presentation/components/`, ARB for
every string, Riverpod providers for data.

Every Arabic string in an artboard is either **quoted verbatim from the ARB** or **marked ◂ as
proposed**. Each document closes with its own provenance rule. Read it before typing any Arabic.

---

## 1. Corrections to the original handoff — do not build from the old numbers

| Old claim | Verified |
| --- | --- |
| "The nine reports" | **Seven** report screens + one shared drill-down. Phase 9 is smaller than costed. |
| `GoalPurpose` has no localisation | **Fully localised** — seven `purpose*` keys. New-ARB-key count drops 23 → 16. |
| Goal creation never moves money | It takes **optional initial funding** (`initialFundingSourceAccountId`, `initialFundingMinorUnits`). |
| Purchase reversal is the certificate escape hatch | It **expires on the first profit receipt** (`errorCertificateReversalNotAllowedAfterHistory`). After that there is no exit until maturity. |
| Certificate maturity + bank reconciliation unbuilt | Both drawn — `10 · T1–T2` and `17 · AI1–AI4`. |

---

## 2. Defects found in source — ordered by risk

**Data integrity**

1. **Archiving a member is not balance-guarded.** `archiveMember` checks only: exists, not primary
   user, not already archived. A child can be archived while their protected fund holds money, on an
   account whose withdrawal flow requires an acknowledgement naming them. Goals and certificates both
   refuse in the same situation. *One use-case check + one key.*
2. **The guarded early-completion flow is bypassed.** `goal_detail_screen.dart` calls the use case
   with `earlyCompletion: true`, `earlyCompletionConfirmed: true` and
   `earlyCompletionReason: 'Completed from goal detail screen'` — a hardcoded English string that
   becomes the household's recorded reason. Every completion is recorded as *early*, including ones
   that reached target.
3. **`AccountFlowBreakdown.reconciles` is never called**, and the card omits zero-valued rows, so the
   visible column does not add up even when the arithmetic does.
4. **The home-savings card prints two subsets and omits their parents** (`transfersIn`/`transfersOut`
   are never rendered), so its column is off by their difference whenever either exists.

**Localisation**

5. **Hardcoded English in three places:** the completion reason above; `'Certificate not found'` /
   `'Error'` in the certificate detail; `'Required'` ×2 and `'Must be > 0'` in the release screen.
6. **`errorGoalInsufficientReserve` is misused in three flows** — goal creation, certificate creation
   and certificate redemption. Its only correct home is the goal release screen. Replace with one
   parameterised message naming the account actually short.
7. **A UUID where a child's name belongs:** the protected-funds audit row prints
   `audit.beneficiaryMemberId` raw. `createdBy` is dropped entirely.
8. **Two orphaned keys to delete:** `goalStatusTargetReached` (no matching enum member, value
   identical to `goalProgressTargetReached`) and `certificateRedeemProfitOnly` (no matching
   `_RedeemMode`).
9. **Missing key:** `AccountIneligibilityReason.currencyMismatch` has no string.
10. **`archivedLabel` has one gender, `memberChild` one number** — both rendered about named people
    and repeatable sections. Needs ARB `select` / `plural`.
11. **Keys doing two jobs:** `reportGrossExpense` / `reportGrossIncome` are row labels in one report
    and section headings in another; `certificatesTitle` heads an event list; `goalMovementFunding`
    heads a movements list; `goalPercent` is used as a *label* with the state as its value; the
    certificate detail labels its lifecycle row with `certificateLifecycleActive`.
12. **Labels assembled in code:** `'${transactionTypeTransfer} (+)'`, `'${reportSpouseWalletTitle}
    (${reportFunded})'`. Not translatable; the parentheses reorder in RTL.
13. **Noun-as-action:** the goal and certificate submit buttons reuse `goalNew` / `certificateNew`.

**Presentation**

14. **`ReportAmountText.formatMinorUnits`** returns `'$currencyCode $sign$major.$minor'` — leading
    currency code, ASCII hyphen, no tabular figures, no bidi isolation. Renders `EGP 382.50-` in RTL.
    Its `Semantics` label repeats the currency code. **Every report amount goes through it.**
15. **`Colors.green/red/orange/blue/grey` hardcoded** across the report widgets and screens.
    `AppFinancialColors` is never consulted, and blue is not in the system at all.
16. **`row.isProtectedWithdrawal` is never read** — a protected withdrawal renders as an ordinary
    expense in the drill-down.
17. **Failures are delivered by `SnackBar`** in goal creation, certificate creation and household —
    a component that auto-dismisses.
18. **Material defaults contradicting §2:** `showDatePicker` / `showDateRangePicker` (four call
    sites, rounded + elevated + centred, month names from Flutter not the ARB, `firstDate: 2000`
    with no past/future distinction) and three `AlertDialog`s in household.
19. **UI/DB disagreement:** the spouse "add" button is hidden whenever *any* spouse row exists
    including archived, while the DB uniqueness check counts active spouses only — so after
    archiving a spouse the affordance never returns.
20. **`ReportFilter`'s eight dimensions are unreachable** — no screen offers a control, and no report
    row sets a filter, so the drill-down screen is unreachable from any report.

---

## 3. Not presentation work

| What | Layer | Blocks |
| --- | --- | --- |
| `heldByReason` + `excludedFromAvailable` on `DashboardSummary` | Query | Dashboard |
| `reversal_reason` on the reversal row | Schema | Reversal |
| Windowed running balance in the account-ledger query | Query | Account detail |
| `statement_balances` table (account, observed balance, observed date, note, optional adjustment link) | Schema | Reconciliation |
| Member + account **name** joins on transaction and audit models | Query | Lists, protected audit |
| Balance guard on `ArchiveMemberUseCase` | Domain | Members |
| `hasSpouse` computed from active spouses only | Presentation → domain parity | Members |
| Member restore use case, or an explicit decision that archiving is permanent | Domain | Members |
| Wire `ReportFilter` to breakdown rows | Presentation + query | All reports |
| Reversal awareness on `CategoryBreakdown` / `MemberSpendingBreakdown`, or label them gross everywhere | Query | Categories, attribution |
| Gold holdings table: quantity, karat, manual gram price + entry date | Schema | Tier 3 |
| Liabilities: six debt types, principal / interest / fee split per repayment | Schema | Tier 3, and «صافي الثروة» |
| Month-end asset and liability snapshot | Query | Net worth over time |
| Speech-to-text returning **per-field confidence** | Service | Voice entry |
| Lock settings + privacy flag | Settings | Lock, privacy mode |
| **16 new ARB keys × 2 locales + 3 helper functions** (`FundPurpose` 11, `AccountOwnerType` 5) | L10n | Account creation |

`OperationType` already ships **21 localised values** including `zakat`, `sadaqah`,
`goldPurchase/Sale`, `liabilityCreation/Repayment`, `adjustment`. **No new operation type is needed
for any Tier 3 feature.**

---

## 4. Binding rules the designs encode

1. Balances are derived, never stored or edited. No delete anywhere, ever.
2. Currencies never combine. Gold is a **quantity** row, never a currency row, and its money value is
   a user-entered estimate shown with its entry date — never in a total.
3. Transfers are not income and not expense; only a transfer *fee* is an expense.
4. Three states of money: spendable, protected, and **neither** (certificate principal, goal
   reserves). The third is why `heldByReason` exists.
5. Every chart is preceded by the figure table it draws. Charts are ink; colour enters only as a
   hatch carrying an exception. No pie. Line charts get points, not curves.
6. `ProgressMeter` consumption is **always ink**; the hatch carries the role.
7. Percentages **truncate**, like `percentageUsed` and `goalPercent`.
8. **No arrows in an arithmetic panel** — bidi-neutral glyphs do not mirror inside an isolated
   numeric run. Use labelled before/after rows.
9. Privacy mode: one ink bar **per digit group**; region, rule, hatch, lock and label all survive.
   Ratios stay visible, derived amounts mask, dates never mask, and the verdict of a comparison is
   not an amount.
10. Snackbars confirm successful writes only. Failures render at their cause and persist.
11. Dialog vs sheet: a dialog is allowed only for a yes/no question with nothing to read and nothing
    to fill.
12. Five bottom tabs is a hard ceiling — «الحركات» renames `navTransactions`, «الديون» needs
    `navDebts`, Reports moves into «المزيد».
13. MSA for labels, Egyptian for explanation. *(Client decision, 26 July.)*

---

## 5. Document index

| # | Document | Covers |
| --- | --- | --- |
| 01 | Design language & components | D1 + D2 · tokens, type, greyscale proof, component states |
| 02 | Directions | Rejected/accepted explorations |
| 03–05 | Tier 1 | Dashboard, expense, transactions, reversal, transfer, accounts, protected |
| 06–07 | Tier 2 | Accounts, income, setup · planning, budgets, goal detail/fund/release |
| 08 | D4 IA & route map | 42 routes, six router defects |
| 09 | D6 handoff & migration | Token tables, 10 phases |
| 10 | Certificates | List, creation, detail, record profit, redemption **and maturity** |
| 11 | Goals | List, creation, early completion · **guard-bypass correction panel** |
| 12 | Household members | List, add, rename, archive refusal |
| 13–15 | Reports | Landing, income/expense, categories, attribution, account flows, protected funds, drill-down, home savings, spouse wallet |
| 16 | Tier 3 patterns | Gold, debts, net worth, zakat, voice entry, lock & privacy |
| 17 | Bank reconciliation | Statement record → adjustment |
| 18 | D2 gaps | Charts, date picker, category picker, tabs, dialog/sheet, snackbar |
| 19 | D5 adaptive | Four widths, rail, two panes, iOS vs Android, the invariants |

---

## 6. The fixture — one household, one set of numbers

Members: **أحمد** (primary) · **هناء** (spouse) · **يوسف أحمد** (child).

| Account | Balance |
| --- | --- |
| حساب بنك مصر — الراتب | 24,300.00 → **24,255.00** after 17 · AI2's reconciliation |
| مدخرات المنزل | 8,000.00 |
| محفظة الزوجة — هناء | 250.00 |
| احتياطي «مصاريف مدرسة يوسف» | 13,600.00 of 13,000.00 · overfunded 600.00 · 104٪ |
| احتياطي «تجديد المطبخ» | 0.00 of 40,000.00 |
| شهادة استثمار 12 شهرًا | 47,900.00 · 2026/03/14 → 2027/03/14 · 19.00% display-only · 2,394.50 collected |
| أموال يوسف المحمية | 6,950.00 from 14 entries |

**إجمالي الأصول 101,000.00** → 100,955.00 after the reconciliation. July: gross income 18,400.00,
gross expense 10,959.25, expense reversal 1,275.00 (04 · D3's electricity bill), net expense
9,684.25, net cash flow +8,715.75.

---

## 7. Still open

- **`fund_goal_screen.dart` has not been read.** Everything else in `lib/features/` that the designs
  touch has been. `07 · L3`'s fund half is the only board not checked against its screen.
- **Are there golden or screenshot tests among the ~1,594?** Asked twelve times, unanswered. If not,
  migration phases 1 and 2 ship together and typography is the only expensive phase. This is the last
  input D6's phase table needs.
- Literals vs a new seed for the eight derived colour roles — D6 is written for literals.
