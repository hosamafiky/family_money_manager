# Design System — Family Money Manager (Phase 6B.2)

**Audience:** Presentation layer only.  
**Language priority:** Arabic-first (RTL), English LTR secondary.  
**Financial authority:** Design never invents balances, mixes currencies, or reclassifies operations.

---

## 1. Visual direction

The app should feel **calm, trustworthy, modern, and financially precise** — warm without playful, professional without corporate. Optimized for daily household use.

| Do | Don’t |
|----|-------|
| Quiet surfaces, clear hierarchy | Generic Material defaults everywhere |
| One dominant balance region | Equal card grids |
| Semantic color + text + icon | Color-only status |
| Moderate radii | Pill-everything / heavy rounding |
| Restrained motion | Decorative animation, glass, heavy elevation |
| Progressive disclosure on forms | Every field at once |
| Currency-separated presentation | Mixed-currency totals |

**Palette character:** Deep trustworthy green as primary action (existing seed `0xFF1A6B3C` lineage). Muted teal/emerald for income, warm muted rose for expense, slate for transfer/neutral. Protected / goal / certificate use distinct but quiet accents — never neon.

---

## 2. Spacing

Scale (dp):

| Token | Value |
|-------|------:|
| `space4` | 4 |
| `space8` | 8 |
| `space12` | 12 |
| `space16` | 16 |
| `space20` | 20 |
| `space24` | 24 |
| `space32` | 32 |
| `space40` | 40 |

Feature screens must not invent arbitrary paddings (e.g. 7, 13, 18).

---

## 3. Shape

| Role | Radius guidance |
|------|-----------------|
| Input | Medium (~8–10) |
| Button | Medium (~8–10) |
| Card / surface | Medium (~8–12) — use sparingly |
| Sheet | Large top (~16–20) |
| Dialog | Medium–large (~12–16) |
| Chip | Small–medium (~6–8) |
| Badge | Small (~4–6) |

Do **not** make every surface heavily rounded.

---

## 4. Typography (semantic roles)

| Role | Use |
|------|-----|
| `displayBalance` | Primary spendable / hero amounts |
| `screenTitle` | AppBar / page titles |
| `sectionTitle` | Section headers |
| `cardTitle` | Compact block titles |
| `body` | Primary reading text (comfortable Arabic line height) |
| `financialAmount` | List/row amounts (highly legible numerals) |
| `supportingMeta` | Dates, secondary labels |
| `formLabel` | Field labels |
| `buttonLabel` | Actions |
| `statusLabel` | Badges / lifecycle |
| `reportValue` | Tables and report figures |

Arabic: prefer slightly open line height on body/titles. Numbers and currency codes stay tabular/legible.

---

## 5. Color (semantic)

| Role | Meaning |
|------|---------|
| Primary action | Confirm / continue |
| Income | Credits classified as income |
| Expense | Debits classified as expense |
| Transfer | Internal movements |
| Protected money | Withdrawal-restricted |
| Goal-reserved | Goal reserve balances |
| Certificate principal | Locked certificate principal (not spendable) |
| Warning / Error / Success | System feedback |
| Neutral information | Informational notices |
| Main / secondary surface | Background hierarchy |
| Divider | Hairline separation |
| Primary / secondary text | Reading hierarchy |
| Disabled | Non-interactive |

Every state also uses **text, shape, or icon** — never color alone.

---

## 6. Motion

Short, purposeful only:

- Navigation transitions  
- Expansion / collapse  
- Confirmation feedback  
- Loading → content  
- List insert/remove when it clarifies change  

No decorative loops, parallax, or glass shimmer.

Suggested durations: 150–250ms standard; ≤350ms for page-level.

---

## 7. Theme architecture

- Single app theme factories: light + existing dark (when testable).  
- Material 3 compatible.  
- RTL/LTR via locale.  
- Large text and high-contrast aware (scheme + text scaling).  
- Semantic styling via `ThemeExtension`s — features must not hard-code brand colors/radii/elevations except rare local semantics.

No per-feature theme implementations.

---

## 8. Components (presentation-only)

Shared kit under `lib/core/presentation/components/`:

Scaffold / chrome: `AppScreenScaffold`, `AppTopBar`, `ResponsiveContentContainer`, `AppBottomActionBar`  
Structure: `SectionHeader`, `AppFormSection`, `AppReviewSection`  
Money: `FinancialAmountText`, `CurrencyAmountRow`, `FinancialSummary`, `FinancialMetric`, `AmountEntryField`  
Lists: `AccountListTile`, `TransactionListTile`  
Status: `StatusBadge`, `FinancialTypeBadge`  
States: `AppEmptyState`, `AppErrorState`, `AppLoadingState`, `AppInlineNotice`  
Actions: `PrimaryActionButton`, `SecondaryActionButton`, `DestructiveActionButton`  
Inputs: `AccountSelectorField`, `PeriodSelector`, `FilterChipGroup`

**Forbidden in components:** Drift queries, ledger writes, authoritative balance math, currency combining, persistence IDs, financial classification decisions.

---

## 9. Information architecture

Primary destinations: **Home · Transactions · Planning · Reports · More**

- Planning → Budgets, Goals, Certificates  
- More → Accounts, Members, Settings  

Bottom navigation: readable labels at large text; clear selected state; Arabic-natural wording. Adaptive rail on wide layouts.

---

## 10. Screen pattern notes

| Area | Pattern |
|------|---------|
| Dashboard | Spendable first; quiet secondary metrics; never mix currencies |
| Transactions | One row model; direction without color-only |
| Entry forms | Amount priority; progressive disclosure; stable idempotency |
| Accounts | Visual class for spendable / protected / goal / certificate / archived |
| Budgets | Planned / consumed / remaining + non-color progress |
| Goals | Lifecycle ≠ derived progress |
| Certificates | Principal ≠ profit; purchase not expense |
| Reports | Unchanged calculations; clearer hierarchy and text alternatives |
| Reviews | Shared effect summary; specific destructive copy |

---

## 11. Accessibility

- Min touch target 48  
- Screen-reader labels with currency context on money  
- Logical focus; visible focus states  
- Contrast meeting readable financial UI  
- Error announcements; accessible loading  
- Charts require text alternatives  

---

## 12. Responsive

Width classes: compact phone · large phone · tablet · desktop/web test surfaces.  
Forms/details: constrained content width (≈720). Lists may widen (≈960).  
Widget tests use explicit surface sizes — no device builds required.

---

## 13. Out of scope for this system

Gold, investments, liabilities, net worth, Zakat, sadaqah, sync, auth, encryption activation, backup, PIN, biometrics, notifications, voice, AI, exports, automatic recurring execution, automatic certificate accrual.
