# Architecture — Family Money Manager

**Version:** 6B.1  
**Date:** 2026-07-20  
**Schema version:** **18**  
**Companion:** `docs/REFACTOR_AUDIT.md`, `docs/FINANCIAL_INVARIANTS.md`, `docs/LOCAL_DATABASE_SCHEMA.md`

This document describes the **as-built** architecture after Phases 0–6A.4. Planned-but-unimplemented modules (auth, sync, encryption key injection, gold/Zakat calculators, net worth, etc.) are noted as deferred — not present in `lib/`.

---

## 1. Goals

1. **Financial correctness first** — append-only ledger, DB triggers as last-line defense, typed insufficient-funds / idempotency outcomes.
2. **Feature-first layout** — each feature owns domain / application / data / presentation as needed.
3. **Domain purity** — domain is Flutter-free and Drift-free.
4. **Offline-local authority** — SQLite via Drift is the system of record; cloud sync is deferred.
5. **Localization** — user-visible strings via generated `AppLocalizations` (ARB).
6. **Integer money** — amounts are minor units (`int`); no `double` ledger math; no `/100` in features.

---

## 2. Dependency direction

```
presentation  →  application  →  domain
                              ↓
                    repository interfaces (often under features/*/data)

data / infrastructure  →  domain + repository interfaces
                       →  Drift / AppDatabase (implementation only)
```

**Forbidden:**

| From | Must not depend on |
|------|-------------------|
| `domain/` | Flutter, Riverpod, Drift, `AppDatabase` |
| `presentation/` | Drift, `AppDatabase`, constructing ledger rows / SQL |
| `application/` | Drift companions / table types (prefer repository interfaces) |
| Widgets | Business balance math, raw SQLite errors, translated persistence IDs |

**Allowed:**

- Presentation → application use cases + Riverpod providers + domain view models
- Application → repository interfaces + domain + `AppResult`
- Data (`Drift*Repository`) → `AppDatabase` + domain mapping
- Core database / financial utilities shared across features

---

## 3. Layers

### 3.1 Presentation

- Screens, form widgets, Riverpod `Provider` / `FutureProvider` wiring
- Formats money for display via integer-safe formatters
- Filters account pickers for UX convenience only — **not** sole enforcement
- Feature-owned invalidation helpers (e.g. goal/certificate money vs lifecycle)
- No Drift imports; no direct ledger inserts

### 3.2 Application

- Use cases orchestrate validation + repository calls
- Map domain/repo outcomes to `AppResult` / UI message keys
- Own eligibility checks that reject restricted accounts even if UI is bypassed
- Must not import Drift table companions

### 3.3 Domain

- Pure Dart entities, enums, value rules (goals, certificates, accounts, operations)
- Financial enums and money types live under `lib/core/financial/` (shared domain-adjacent)
- No Flutter / Drift / Riverpod

### 3.4 Data / infrastructure

- `AppDatabase` (schema 18) owns migrations, triggers, indexes
- `Drift*Repository` implementations are the write/query boundary
- `SqliteContentionPolicy` standardizes SQLITE_BUSY/LOCKED retry for authoritative writers
- Ledger repository is the authority for ordinary I/E/transfer/opening/adjustment/reversal

---

## 4. Features (as-built)

| Feature | Role |
|---------|------|
| **ledger** | Authoritative financial operations + ledger entries + protected withdrawal audits |
| **accounts** | Financial account CRUD/classification; opening balance via ledger |
| **balance** | Derived balances from ledger |
| **transactions** | Income/expense/transfer UX + history queries |
| **goals** | Savings goals with `goalReserve` accounts + goal-associated transfers |
| **certificates** | Savings certificates with dedicated certificate accounts |
| **budgets** | Budget plans and progress |
| **dashboard** | Period summary queries |
| **reports** | Read-only analytical reports |
| **household** | Members / roles |
| **shell / onboarding / settings / smoke** | App chrome and scaffolding |

Deferred product areas (not implemented): gold, investments, liabilities, net worth UI, Zakat/sadaqah, sync, auth, encryption-at-rest activation, backup, PIN/biometrics, notifications, voice, AI, exports, automatic recurring execution.

---

## 5. Shared core

| Path | Responsibility |
|------|----------------|
| `core/database/` | `AppDatabase`, tables, contention policy, providers |
| `core/financial/` | `Money`, `Currency`, ledger/account enums, ledger calculator |
| `core/application/app_result.dart` | Typed app outcomes |
| `core/error/` | App errors |
| `core/presentation/money_input_formatter.dart` | Parse/format without doubles |
| `core/localization/` | Generated l10n |
| `core/logging/` | Redacted logging |
| `core/navigation/` | Route helpers |
| `app/` | Router, theme, config, root providers |

---

## 6. Database ownership

- **Single schema owner:** `AppDatabase` (`schemaVersion => 18`).
- **Generated code:** `app_database.g.dart` — never hand-edited; regenerate via `build_runner` when tables change (not expected in 6B.1).
- **Triggers/indexes:** Applied in `onCreate` / `onUpgrade`; names are stable contracts for tests.
- **Migrations:** Additive version chain 1→18; do not collapse or renumber in refactor phases.
- **WAL + foreign_keys:** Enabled in `beforeOpen`.

Schema-helper extraction (6B.1) may move `_apply*` methods into part/collaborator files **without** changing SQL text, trigger names, or version.

---

## 7. Ledger authority

- Ordinary income, expense, transfer, opening balance, adjustment, and reverse go through `LedgerRepository` / `DriftLedgerRepository`.
- Goal funding/release/reversal write operations + legs inside the goal repository’s transactional boundary (associated transfer), still subject to the same non-negative balance trigger.
- Certificate purchase/profit/redeem/reversal write inside the certificate repository’s transactional boundary.
- **Balances** are derived from ledger entries; DB trigger `prevent_negative_account_balance` is last-line debit safety (Phase 6A.2).

### Operation-type note (goals)

Goal funding/release persist `operations.type = 'transfer'` with transfer-in/out legs. Goal association is via `goal_movements`, not a separate operation type. See `REFACTOR_AUDIT.md` §5 — **document only** in 6B.1.

---

## 8. Use cases & repositories

- Interfaces typically live beside Drift impls under `features/*/data/` (e.g. `ledger_repository.dart`).
- Use cases depend on interfaces, not Drift helpers.
- Collaborators extracted from Drift repos are **internal** to the data layer and share the same transaction / contention context as the façade.

---

## 9. Riverpod

- Feature `*_providers.dart` wire repositories, use cases, and `FutureProvider`s.
- Invalidation is **feature-scoped** (money vs lifecycle for goals/certificates). Avoid a global “invalidate everything” default.
- Household id is currently a known bootstrap constant in several providers (`household-v1`) — product constraint until multi-household auth lands (deferred).

---

## 10. Routing & localization

- `app/app_router.dart` — GoRouter routes; preserve paths/visible navigation in 6B.1.
- ARB → `AppLocalizations`; persistence stores **codes**, never translated labels.
- Do not change visible wording substantially during structural cleanup.

---

## 11. Errors, idempotency, transactions, contention

| Topic | Rule |
|-------|------|
| Errors | Map to typed domain/`AppResult` outcomes; never leak raw SQLite to UI callers |
| Idempotency | Scoped `(household_id, idempotency_key)` + payload fingerprint / field equivalence |
| Replay | Same key + equivalent payload → success / already-exists style `AppOk` |
| Conflict | Same key + mismatched payload → `AppDuplicateConflict` (or ledger `conflict`) |
| Tx boundaries | Authoritative multi-row writes in one Drift `transaction` (`BEGIN IMMEDIATE`) |
| Contention | `runAuthoritativeWriteWithContentionRetry`; on exhaustion re-read idempotency where applicable |
| Invalidation | Feature coordinators after successful mutations |

Feature-owned fingerprint **builders** remain in feature modules; shared infrastructure handles compare / replay / conflict / contention re-read patterns.

---

## 12. Money formatting

- Ledger and persistence: integer minor units only.
- Display: `MoneyInputFormatter` (+ thin feature policies for non-negative → em-dash).
- Parsing: integer arithmetic; Arabic-Indic digits supported.
- Forbidden in features: `double` for money, `/100` scaling hacks.

---

## 13. Account eligibility

- **DB / repository / use case** enforce that goal-reserve and certificate accounts are not ordinary I/E/transfer endpoints.
- **UI filters** are convenience only.
- Shared eligibility policies (6B.1) live in domain or application so widgets do not become the sole gate.

---

## 14. Test classifications

| Class | Meaning |
|-------|---------|
| **Unit-tested** | Pure Dart, no DB |
| **Database-tested** | Real/in-memory SQLite via Drift |
| **Fake-tested** | Fake repository / in-memory doubles |
| **Widget-tested** | Flutter widget tests |
| **Documented only** | Spec/audit without automated proof |
| **Unverified** | Claim without evidence — avoid in reports |

Financial integrity coverage must not be reduced by refactors. Splitting test files preserves intent; moves/renames are recorded in the phase report.

Architecture enforcement tests (6B.1) guard import/boundary rules listed above.

---

## 15. Explicit non-goals for Phase 6B.1

- UI redesign / design system restyle (→ 6B.2)
- Schema version bump
- Changing ledger/goal/certificate/idempotency/contention/currency/report/reversal/lifecycle **semantics**
- Implementing deferred product modules listed in §4
