# Phase 6A Report — Savings Certificates / Fixed-Term Deposits

**Gate HEAD (Phase 5B):** `86736ca7ecd19dea3ea93568a3aecc226faf870c`  
**Feature commit:** `25347f429f0388ef5abb87fc6a15f50887cef482`  
**Phase 6A docs pin:** `4f81df5b88ebf1afa93455fbd738b3f03f81595b`  
**Phase 6A.1 correction:** see `docs/PHASE_6A_1_REPORT.md` (workflow + verification closure)  
**Branch:** `main`  
**Schema:** 16 → **17**  
**Tests at Phase 6A feature gate:** **1322 → 1410** (+88 exact file reconciliation)  
**Tests after Phase 6A.1:** **1410 → 1483** (+73)

---

## 1. Phase 5B integrity gate

| Check | Result |
|-------|--------|
| `git rev-parse HEAD` at gate | `86736ca7ecd19dea3ea93568a3aecc226faf870c` |
| Working tree before Phase 6A | Clean |
| `GoalStatus` | `active` / `completed` / `archived` only |
| Schema version | 16 |
| Certificate production code | None (`find lib -iname '*certificate*'` empty) |
| No `targetReached` persistence | OK |
| Full suite | **1322 passed** |

Goals were not reopened except for unavoidable schema-version expectation updates in migration tests (`phase_5b8`, `goal_true_migration_v12_to_latest`) so they assert latest = **17**.

---

## 2. Domain model

Flutter-independent types in `lib/features/certificates/domain/certificate.dart`:

- `CertificateId`, `SavingsCertificate`, `CertificateRevision`
- `CertificateLifecycle` — **persisted only:** `active`, `redeemed`, `archived`
- `CertificateTermState` — **derived only:** `notStarted`, `activeTerm`, `matured`, `fullyRedeemed`, `overdueRedemption`
- `CertificateEvent` / `CertificateEventType`
- `CertificateProfitReceipt`, `CertificateRedemptionSummary`, `CertificateProgress`
- `CertificatePurchaseFunding`, `CertificateProfitFrequency`

Stable codes (enum `.name` / explicit category codes), never translated labels.

Each certificate stores: client id, householdId, certificateAccountId, currency, originalPrincipalMinorUnits, institution (via revision), optional reference/note/rate/frequency, start/maturity dates, lifecycle, timestamps, idempotency key + payload fingerprint, schema version.

---

## 3. Lifecycle vs derived term state

| Layer | Values |
|-------|--------|
| Persisted `lifecycle` | `active`, `redeemed`, `archived` |
| Derived `CertificateTermState` | from **Clock local `yyyy-MM-dd`** + ledger principal balance + start/maturity |

Timezone policy matches dashboard/reports: device-local calendar dates; no household timezone.

---

## 4. Account model

- `FinancialAccountType.certificate` + `FundPurpose.certificate` (pre-existing enums)
- 1:1 with certificate (`idx_savings_certificates_account`)
- Same household + currency
- Non-spendable, not protected, household-owned
- `includeInNetWorth: true`, `includeInZakat: false`
- Starts at zero; principal enters **only** via purchase transfer
- Excluded from ordinary income/expense/transfer forms and use cases
- Excluded from opening balance and adjustment in ledger repository

**Authoritative principal** = derived ledger balance of the linked certificate account (`Σ credit − Σ debit`).

Does **not** claim full household net worth.

---

## 5. Atomic purchase (`CreateCertificateUseCase`)

Single `db.transaction()` covering:

1. Idempotency lookup  
2. Payload conflict check  
3. Source account validation  
4. Balance check  
5. Certificate account insert  
6. Certificate row  
7. Initial revision  
8. `certificateFunding` operation  
9–10. Debit/credit transfer legs  
11. Operation context  
12. `created` + `purchased` events  
13. Commit  

Requires **positive** principal + funding source (no unfunded certificates). Failure rolls back everything. Fail-after hooks support rollback matrix tests.

---

## 6. Profit receipts (`RecordCertificateProfitUseCase`)

- Not archived  
- Destination: standard, active, same HH/currency (not certificate/goalReserve)  
- Positive amount  
- Ordinary **income** op with category `certificate_profit` (`TransactionCategory.certificateProfit`)  
- Append-only `profitReceived` event  
- Included in income reports; not a transfer; not budget consumption  
- Does **not** change certificate principal  

---

## 7. Maturity redemption (`RedeemCertificateUseCase`)

- Maturity reached/passed (local clock)  
- Lifecycle `active`  
- Destination valid standard account  
- **Full remaining balance only** (request > balance → `AppInsufficientFunds`; ≠ balance → validation)  
- Internal `certificateMaturity` transfer — **not income**  
- Optional maturity profit income in same transaction  
- Lifecycle → `redeemed` + redemption event  
- After: certificate account = 0; destination += principal; total assets unchanged for principal move  
- UI distinguishes principal / profit / combined cash  

**Phase 6A.1:** Redeem screen no longer offers profit-only mode. Profit-only receipts use `RecordCertificateProfitUseCase` / Record Profit screen exclusively.

Redemption reversal: **explicitly rejected** (`errorCertificateRedemptionReversalNotSupported`).

---

## 8. Idempotency & concurrency

Payload fingerprint:

`hh|inst|ref|cur|prin|start|mat|rate|freq|src`

- Equivalent key+payload → original certificate  
- Conflict → `AppDuplicateConflict`  
- Cross-household isolated (scoped unique index)  
- Concurrent equivalent creates → one certificate (tested)

Profit/redeem use event-scoped idempotency keys + payload fingerprints.

---

## 9. Schema & migration (v17)

Tables:

- `savings_certificates`
- `certificate_revisions`
- `certificate_events`

Indexes: listing/maturity, unique account, scoped idempotency, revisions, events, related-op uniqueness.

Triggers enforce: 1:1 account linkage (type/HH/currency/spendable/protected/owner), classification locks, immutability of contractual fields, append-only revisions/events, event HH match, purchase INTO / redemption OUT / profit INCOME validators, balanced purchase/redemption legs, no cascade financial delete, lifecycle CHECK + transitions.

Evidence:

- Fresh schema v17 (DB test 45)  
- True physical **v16→v17** (`certificate_true_migration_v16_to_v17_test.dart`)  
- True physical **v12→latest (=17)** updated (`goal_true_migration_v12_to_latest_test.dart`)

---

## 10. Ordinary restrictions & reversal

Ordinary paths reject certificate accounts:

- `RecordIncomeUseCase`, `RecordExpenseUseCase`, `ExecuteTransferUseCase`
- Opening balance / adjustment in `DriftLedgerRepository`
- Account pickers on income/expense/transfer forms

Controlled:

- Purchase / profit / redeem workflows  
- Purchase reversal: only while active and no later profit/redemption; reverse transfer; archive  
- Profit reversal: reverse income + `profitReversed` event  
- Redemption reversal: deferred / rejected  

---

## 11. Dashboard / reports / budgets

- Certificate principal excluded from spendable & protected (non-spendable account)  
- Purchase/redemption principal excluded from income/expense (`certificateFunding` / `certificateMaturity` not in period-flow `IN ('income','expense')`)  
- Profit included as ordinary income  
- No budget consumption from certificate transfers or profit-as-income vs expense budgets  
- Account-flow can reconcile certificate accounts via ledger  
- No mixed-currency totals  
- Dashboard AppBar entry to `/certificates`  
- Optional separate principal section: **deferred** (accounts already non-spendable; not labeled net worth)

---

## 12. Screens & routes

| Route | Screen |
|-------|--------|
| `/certificates` | List |
| `/certificates/new` | Create + review |
| `/certificates/:id` | Detail |
| `/certificates/:id/profit` | Record profit + review |
| `/certificates/:id/redeem` | Redeem + review |

Unique FAB heroTags; idempotency key created in `initState`; Arabic RTL / English LTR via app locale; money via shared minor-unit formatter (not `double` for ledger).

Providers: `certificate_providers.dart` (widgets never import Drift / never sum currencies).

---

## 13. Localization

Keys added to `app_en.arb` / `app_ar.arb` (+ `flutter gen-l10n`), including `certificatesTitle`, lifecycle/term labels, validation errors, `catCertificateProfit`. Category label helper updated.

---

## 14. Test traceability (classifications)

| Area | Classification | Coverage notes |
|------|----------------|----------------|
| Domain derivation / eligibility / payload | **Unit** | `certificate_domain_test.dart` |
| Atomic create, idempotency, concurrency, linkage, profit, redeem+profit, reversals, ordinary guards, schema | **Database** | `certificate_repository_test.dart` |
| True v16→v17 migration | **Database** | `certificate_true_migration_v16_to_v17_test.dart` |
| List AR/EN, empty/error, FAB, multi-currency | **Widget** | `certificates_list_screen_test.dart` |
| Partial/early redemption UX depth, accrued interest, YTM, tax | **Documented only** | Deferred product |
| Device emulator / App Bundle | **Unverified** | Hard constraint — not run |

Approx **+88** tests vs gate baseline (exact file table in `PHASE_6A_1_REPORT.md` §2).  
Phase 6A.1 adds **+73** rollback/idempotency/event/concurrency/classification/workflow proofs → **1483**.

---

## 15. Files created / changed (high level)

**Created**

- `lib/features/certificates/**` (domain, data, application, presentation)
- `lib/core/database/tables/certificates_table.dart`
- `test/unit|database|widget/.../certificates/**`
- `docs/PHASE_6A_REPORT.md`

**Changed**

- `lib/core/database/app_database.dart` (+ `.g.dart`) — schema 17 + Phase 6A triggers
- `lib/core/financial/ledger_enums.dart` — exclude `certificateMaturity` (+ `goalWithdrawal`) from I/E reports
- `lib/features/transactions/**` — category, guards, form filters, labels
- `lib/features/ledger/data/drift_ledger_repository.dart` — opening/adjustment guards
- `lib/app/app_router.dart`, dashboard AppBar
- Localization ARB + generated l10n
- Migration helper / Phase 5B.8 version expectations updated to latest=17

---

## 16. Validation (Phase 6A feature gate)

```text
dart format --output=none --set-exit-if-changed .   # pass
flutter analyze                                       # Phase 6A had remaining Radio/info warnings
flutter test                                          # 1410 passed
```

**Phase 6A.1 correction:** `flutter analyze` → **No issues found!**; suite **1483** passed. See `PHASE_6A_1_REPORT.md`.

---

## 17. Scope scan

Within `lib/features/certificates/`:

- Hits only for existing account flags `includeInZakat: false` (required column; Zakat **not** implemented)
- No gold / sadaqah / Firebase / biometrics product / OpenAI / CSV export introductions

Broader generated Drift diff may mention pre-existing `biometricConfirmed` columns — not new Phase 6A product surface.

---

## 18. Deferred encryption risk

Unchanged from Phase 2+: sqlite3mc-ready binary; key injection still deferred (PO-2). Certificates inherit the same at-rest plaintext risk until security hardening.

---

## 19. Deferred product decisions

- Partial redemption  
- Early redemption (before maturity)  
- Accrued interest / auto accrual / auto payout / compounding  
- Market valuation, bonds, equities, YTM, tax  
- FX conversion  
- Institution APIs  
- Redemption reversal  
- Dedicated dashboard “certificate principal by currency” section (optional)

---

## 20. Remaining risks

1. ~~UI redeem `profitOnly` mode still routes through redeem API~~ — **fixed in Phase 6A.1** (removed; profit-only uses Record Profit).  
2. Purchase reversal archives immediately; restore-after-redeem edge paths are V1-simple.  
3. Certificate account appears in net-worth flag but there is **no** full net-worth product — messaging must stay careful.  
4. Concurrent purchase under heavy WAL contention — MC-CERT classifies busy locks honestly (`AppPersistenceFailure` possible).  
5. ~~Analyzer infos (deprecated Radio APIs on redeem screen)~~ — **cleared in Phase 6A.1**.

Overstated Phase 6A atomicity/idempotency claims for profit/redeem mid-failure matrices are closed by Phase 6A.1 CREATE/PROFIT/REDEEM-ROLL suites (previously only happy-path + limited concurrent create).

---

## 21. Exact branch / commit / clean status

- **Branch:** `main`
- **Feature commit:** `25347f429f0388ef5abb87fc6a15f50887cef482`
- **Docs pin:** `4f81df5b88ebf1afa93455fbd738b3f03f81595b`
- **Phase 6A.1:** `35602d9e9761de46a2f33afff268cbef28395e41` — `fix: Phase 6A.1 – certificate workflow correction and verification`
- **Message (6A):** `feat: Phase 6A – savings certificates and fixed-term deposit assets`