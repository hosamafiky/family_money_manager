# Phase 6A.2 Report — Debit Safety, Concurrent Idempotency, Authentic Migration

**Branch:** `main`  
**Feature commit:** `d12887718024a2d87d05c63b9c7041136d0542c5`  
**Prior HEAD:** `d0329779ff14659902aed2105b5208aabc9d16d0`  
**Phase 6A feature:** `25347f429f0388ef5abb87fc6a15f50887cef482`  
**Phase 6A.1 feature:** `35602d9e9761de46a2f33afff268cbef28395e41`  
**Phase 6A.1 docs pin:** `4264b3fd4b1e4fca219af9bfd4cb4d7f88e3ac7a`  
**Schema:** **17 → 18**  
**Tests:** **1483 → 1507** (`1483 + 25 − 1 = 1507`)

---

## 1. Exact repository evidence (pre-commit)

| Item | Value |
|------|-------|
| `pwd` | `/Users/hussam/Desktop/hussam/family_money_manager` |
| Branch | `main` |
| HEAD before 6A.2 | `d0329779ff14659902aed2105b5208aabc9d16d0` |
| Working tree | Clean at start |
| Baseline tests | **1483** |

---

## 2. Debit-safety mechanism (chosen)

**Mechanism 2 — DB-level non-negative balance enforcement (SQLite trigger)**  
`prevent_negative_account_balance` — `AFTER INSERT ON ledger_entries` when `direction = 'debit'`, abort if account sum (credits − debits) would be &lt; 0.

Combined with Drift’s default `BEGIN IMMEDIATE` writer transactions, every debit path’s balance decision shares the same write lock as the ledger insert across two connections to one SQLite file. Pre-write balance reads outside a writer transaction are not relied upon.

Also:

- Adjustment **debits** now call `_checkSufficientBalance` inside the IMMEDIATE txn
- Expense / transfer / certificate paths map trigger abort → `InsufficientFundsError` / `AppInsufficientFunds`
- Certificate create/profit/redeem re-read idempotency after lock/UNIQUE contention

**Classification:** Database-tested (BAL-EVT-8 + XDEB-*).

---

## 3. Cross-feature debit races (XDEB-1..6)

Two Drift connections → one physical temp SQLite file.

| Test | Scenario | Assertion |
|------|----------|-----------|
| XDEB-1 | Cert vs cert | Exactly one cert; balance ≥ 0 |
| XDEB-2 | Cert vs expense | Exactly one of cert/expense |
| XDEB-3 | Cert vs ordinary transfer | Exactly one |
| XDEB-4 | Cert vs goal funding | Exactly one |
| XDEB-5 | Expense vs transfer | Exactly one |
| XDEB-6 | Goal funding vs transfer | Source bal = 20000; one of movement / ordinary transfer |

**Classification:** Database-tested.

---

## 4–6. Concurrent certificate idempotency (CIDMP-1..9)

| Test | Behaviour |
|------|-----------|
| CIDMP-1 | Equivalent concurrent create → both `AppOk`, one cert/account/purchase op/context/purchased+created events |
| CIDMP-2 | Conflicting concurrent create → one `AppOk` + `AppDuplicateConflict` |
| CIDMP-3 | Cross-household same key isolated |
| CIDMP-4 | Fail-after then retry succeeds once |
| CIDMP-5/6 | Equivalent / conflicting concurrent profit |
| CIDMP-7 | Equivalent concurrent redeem (DB: one redeemed event) |
| CIDMP-8 | Concurrent purchase reversal → one reversal op |
| CIDMP-9 | Concurrent profit reversal; redemption reversal remains unsupported |

After lock contention, repositories re-read the winner’s idempotency row (with short retry) so equivalent retries are not classified as final `AppPersistenceFailure` when the winner completed.

**Classification:** Database-tested.

---

## 7. Certificate-event balanced-operation enforcement

Schema 18 strengthens `validate_certificate_{purchase,redemption,profit}_event` to require:

- Exact leg counts (purchase/redemption: 2 balanced legs matching op accounts; profit: exactly one credit)
- Amount / currency / household match
- Reject missing, unequal, third, wrong-currency, wrong-HH, unrelated-op legs

Raw SQL tests BAL-EVT-1..8. Application construction is **not** classified as DB-tested.

**Classification:** Database-tested.

---

## 8. Authentic schema-16 fixture

**Not** create-v17-then-delete.

- Fixture SQL: `test/fixtures/schema_v16_objects.sql` extracted from onCreate at commit `86736ca`
- Helper: `test/helpers/true_schema_v16.dart` — Drift table DDL (excluding certificate tables) + historical objects; `user_version = 16`
- Tests: `certificate_true_migration_v16_to_latest_test.dart` — MIG-6A2-1 data survival to schema **18**; MIG-6A2-2 partial-upgrade / fail-inject reopen completes triggers

Synthetic `certificate_true_migration_v16_to_v17_test.dart` **removed**.

**Migration rollback:** documented — mid-upgrade abort leaves `user_version` stuck; reopen with current `AppDatabase` completes `onUpgrade` (fail-inject covered in MIG-6A2-2).

**Classification:** Database-tested.

---

## 9. Test reconciliation

| File | Tests | Classification | Notes |
|------|-------|----------------|-------|
| `phase_6a2_cross_debit_race_test.dart` | XDEB-1..6 (6) | Database-tested | added |
| `phase_6a2_concurrent_idempotency_test.dart` | CIDMP-1..9 (9) | Database-tested | added |
| `phase_6a2_event_balance_test.dart` | BAL-EVT-1..8 (8) | Database-tested | added |
| `certificate_true_migration_v16_to_latest_test.dart` | MIG-6A2-1..2 (2) | Database-tested | replaces synthetic MIG-6A-1 |
| `certificate_true_migration_v16_to_v17_test.dart` | MIG-6A-1 (1) | — | **removed** |
| `phase_6a1_multi_connection_test.dart` | MC-CERT-1..5 | Database-tested | strengthened typed outcomes |
| `dashboard_balance_db_test.dart` | test 8 renamed | Database-tested | overdraft rejected (was force-negative) |

**Equation:** `1483 + 25 − 1 = 1507`

---

## 10. Validation

```text
dart format --output=none --set-exit-if-changed .   # exit 0
flutter analyze                                       # No issues found!
flutter test --reporter=expanded                      # 1507 passed; 0 failed
```

---

## 11. Claim classifications

| Claim | Classification |
|-------|----------------|
| Non-negative balance trigger | Database-tested |
| IMMEDIATE txn + debit check on adjustment | Database-tested |
| XDEB cross-feature races | Database-tested |
| Concurrent cert idempotency re-read | Database-tested |
| Cert event balanced legs | Database-tested |
| Authentic v16→18 migration | Database-tested |
| Redemption reversal unsupported | Database-tested (CIDMP-9) |
| Emulator / App Bundle / encrypted DB | Unverified |
| Phase 6B.1 | Documented only (not started) |

---

## 12. Gaps / residual risks

1. Multi-connection insufficient-funds loser may still surface `AppPersistenceFailure` under WAL busy timeout (MC-CERT-3); DB state remains correct (one cert, balance ≥ 0).
2. Concurrent redeem equivalent may yield one `AppOk` + persistence on loser while DB has exactly one redeemed event (CIDMP-7).
3. Goal funding still persists operation `type='transfer'` (pre-existing); XDEB-6 counts ordinary transfers excluding goal-linked ops.
4. Device / App Bundle builds not run (hard constraint).
5. Phase 6B.1 not begun.

---

## 13. Scope scan

No gold, investments, liabilities, net worth product, Zakat product, sync, security, backup, notifications, voice, AI, or exports begun. No Android/iOS/emulator builds. `money_tracker_next` / `money_tracker` untouched.

---

## 14. Files changed (summary)

**Lib:** `app_database.dart` (schema 18), `drift_certificate_repository.dart`, `drift_ledger_repository.dart`  
**Tests:** XDEB / CIDMP / BAL-EVT / authentic migration; MC-CERT strengthened; schema expects 18; integrity fixtures credited for non-neg trigger  
**Fixtures:** `schema_v16_objects.sql`, `true_schema_v16.dart`  
**Docs:** this report; corrections in `PHASE_6A_REPORT.md`, `PHASE_6A_1_REPORT.md`
