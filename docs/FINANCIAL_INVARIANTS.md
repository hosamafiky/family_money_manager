# Financial Invariants

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15  
**Status:** Non-negotiable — tests must enforce every invariant listed here

---

## Overview

These invariants must hold at all times, in all circumstances, including during offline operation, sync conflicts, schema migrations, data import, and concurrent operations. Any code path that could violate an invariant must be treated as a critical bug.

---

## INV-001 — Single Location of Money

**Statement:** Every unit of money exists in exactly one financial account at any point in time.

**Enforcement:**
- Every transfer creates a debit on the source and a credit on the destination of equal amount.
- No credit is created without a corresponding debit (except income/opening balance, which are balanced against the external equity entry).
- No debit is created without a corresponding credit (except expense, which is balanced against the external expense entry).

**Test coverage required:**
- Transfer sum: `balance(source) + balance(destination)` is unchanged after transfer.
- Income: `total_assets` increases by income amount.
- Expense: `total_assets` decreases by expense amount.

---

## INV-002 — Immutable Ledger

**Statement:** No ledger entry may ever be modified or deleted after it is written.

**Enforcement:**
- **Planned:** Local database: no UPDATE or DELETE on ledger_entries table. A SQLite trigger is planned to enforce this at the database level.
- **Planned:** Firestore: security rules are designed to deny all updates and deletes on ledger entry documents.
- **Requirement:** Application layer: no `update` or `delete` method shall exist on LedgerRepository.
- **Requirement:** Corrections must use reversal entries only.

**Test coverage required:**
- Attempt to update a ledger entry via the repository → rejected.
- Attempt to delete a ledger entry via the repository → rejected.
- Firestore emulator: attempt to update/delete ledger entry document → rejected by rules.

---

## INV-003 — Transfer Neutrality

**Statement:** A transfer between two accounts does not change total net worth (excluding fees).

**Mathematical form:**
```
NetWorth(before) = NetWorth(after transfer, excluding fee)
NetWorth(before) − fee_amount = NetWorth(after transfer + fee expense)
```

**Enforcement:**
- Transfer operation always creates exactly two ledger entries: debit source, credit destination, equal amounts.
- Fee (if any) is a third, separate expense entry.
- Reporter must exclude transferOut/transferIn from income/expense totals.

**Test coverage required:**
- Net worth before and after a transfer with no fee: equal.
- Net worth before and after a transfer with fee: reduced by fee only.
- Transfers do not appear in income or expense reports.

---

## INV-004 — Certificate Principal Exclusivity

**Statement:** The principal of an active certificate is not counted in both the funding bank account and the certificate account simultaneously.

**Mathematical form:**
```
bank_available_balance = bank_opening_balance + Σ(incomes) − Σ(expenses) − certificate_principal
certificate_balance = certificate_principal
bank_balance + certificate_balance ≠ bank_balance_before_funding + certificate_balance_before_funding + certificate_principal
(The last line should be EQUAL, not greater — i.e. no duplication)
```

**Enforcement:**
- Certificate creation atomically debits the bank account and credits the certificate account.
- These two operations share the same operationId and are committed in a single transaction.
- If one fails, both fail (rollback).

**Test coverage required:**
- Create certificate: bank balance decreases by principal; certificate balance increases by principal; sum unchanged.
- Interest payout: does not affect certificate principal, only destination account.
- Certificate maturity: certificate balance returns to bank; sum unchanged; certificate marked matured.

---

## INV-004A — Certificate Account Workflow Ownership (Phase 6B.1.1)

**Statement:** A certificate account may receive or release principal **only** via approved certificate-owned workflows (purchase, redemption, controlled purchase reversal, and other explicitly approved cert-owned operations). Certificate accounts must not be usable as goal funding sources, goal release destinations, ordinary income/expense/transfer endpoints, opening balances, adjustments, or unrelated reversals.

**Enforcement:**
- Shared `AccountEligibility` (type + fund purpose).
- Goal application / use-case validation (typed `AppValidationFailure`).
- Goal repository validation (including `savings_certificates` linkage).
- Presentation account filtering (convenience only).
- Database triggers `validate_funding_source_eligibility` and `validate_release_destination_eligibility` (schema 19) — last-line authority.
- Ordinary I/E/transfer use cases already reject certificate endpoints.

**Exceptions retained:** Certificate purchase credits the certificate account; redemption debits it; profit receipt credits a standard spendable account without altering certificate principal.

**Test coverage required:**
- Direct SQL bypass attempts rejected by triggers.
- FundGoal / ReleaseGoal use cases return typed validation failures for certificate endpoints.
- Selectors exclude certificate accounts (presentation class).
- Positive controls: eligible standard fund/release; cert purchase/redemption still work.

---

## INV-005 — No Negative Balance Without Overdraft

**Statement:** No account may have a negative balance unless it is explicitly configured with overdraft support.

**Enforcement:**
- **Requirement:** Before writing any debit, the implementation must check: `currentBalance(account) >= debitAmount` for non-overdraft accounts.
- **Planned:** This check is to be performed inside the local database transaction.
- **Planned:** Firestore rules are designed to enforce the same check on cloud operations via Firestore transactions that read and verify before writing.

**Test coverage required:**
- Attempt to spend more than available: rejected with InsufficientFundsError.
- Overdraft account: negative balance allowed.
- Concurrent transfers that would both succeed individually but together cause negative balance: one is rejected.

---

## INV-006 — Protected Fund Withdrawal Requires Audit

**Statement (requirement):** Any debit on a `childProtectedFund` account — regardless of the code path that creates it — must be accompanied by a mandatory audit event containing: reason, beneficiary, confirmation timestamp, and operator ID. This applies to every write path without exception.

**Planned enforcement mechanisms:**
- **Requirement:** A single repository method `withdrawFromProtectedFund(amount, audit)` must be the only code path that can debit a `childProtectedFund` account.
- **Planned:** The audit event is designed to be written atomically in the same SQLite transaction as the ledger entry.
- **Requirement:** No `childFundWithdrawal` ledger entry may exist without a linked `ChildWithdrawalAudit` record.
- **Requirement:** Application UI must not provide a way to bypass the warning screen before calling this method.
- **Planned:** A database-level trigger or foreign key constraint will enforce the audit link at the persistence layer.
- **Planned:** Firestore rules are designed to reject `childFundWithdrawal` ledger entry documents without a linked audit document in the same batch write.

### Complete protected-child write path inventory

Every path that could produce a debit on a `childProtectedFund` account is listed below, along with the planned domain validation, planned persistence validation, required audit record, and required test category.

| Write Path | Domain Validation | Persistence Validation | Audit Record Required | Test Category |
|---|---|---|---|---|
| **Normal withdrawal** via `withdrawFromProtectedFund` | Warning shown, reason required, explicit confirmation | Audit in same SQLite transaction | Yes — full audit | Unit + Widget |
| **Adjustment** (adjustmentDebit on child account) | Adjustment path must check account type; if `childProtectedFund`, require audit | Same audit transaction requirement | Yes — audit with reason = "adjustment: [admin reason]" | Unit |
| **Reversal of a child-fund deposit** | Reversing a deposit reduces the child account balance; the reversal is also a protected debit | Reversal operation must trigger audit creation for child accounts | Yes — audit with reason = "reversal of deposit [operationId]" | Unit |
| **Transfer out of child account** (e.g., moving child funds to another account) | Any transfer where sourceAccountId belongs to a `childProtectedFund` account type must require audit | Repository transfer method must check source account type | Yes — audit with reason describing the transfer destination | Unit + Widget |
| **Sync download** applying a remote debit on a child account | Downloaded child debits must check for a linked audit document before applying locally | If audit is missing in downloaded batch, reject the entire batch | Yes — must be present in downloaded batch | Integration |
| **Backup import** containing a child-account debit | Import validator must check that every `childFundWithdrawal` entry has a linked audit record | Reject import if audit link is missing for any child debit | Audit records in backup must be present and linked | Data/Integration |
| **Schema migration** that reclassifies an account to/from `childProtectedFund` | Account type is immutable after creation (see FINANCIAL_MODEL.md Section 21). Migration may not change account types. | Migration test must verify type immutability | N/A — this path is prohibited | Unit (migration test) |
| **Repair / administrative ledger tool** | No such tool is permitted in V1. Any future administrative tool must require the same audit. | Must check account type before writing any debit | Yes — if any future tool exists | Future |
| **Asset purchase** funded from child account | An asset purchase debits the source account; if that account is `childProtectedFund`, the audit path must be triggered | Same repository-level type check | Yes | Unit |
| **Certificate funding** from child account | Certificate creation debits the source account; same check applies | Same type check | Yes | Unit |
| **Liability repayment** from child account | Repayment debits the payment account; same check applies | Same type check | Yes | Unit |
| **Goal funding** from child account | Goal funding transfers from the source account; same check applies | Same type check | Yes | Unit |
| **Zakat payment** from child account | Zakat recording debits the payment account; same check applies | Same type check | Yes | Unit |

**Requirement:** The domain layer must implement a central `isProtectedFundAccount(accountId)` check that all debit-producing operations invoke before proceeding. This check must not be optional.

**Test coverage required:**
- Withdrawal without audit event: rejected by repository.
- Withdrawal with audit event: succeeds.
- Audit event is immutable: update rejected.
- **Requirement:** The design requires that audit history remains visible even after account archive. No archive or delete operation may remove audit records.
- Adjustment on child account without audit: rejected.
- Reversal of deposit on child account: audit created.
- Transfer out of child account: audit required.
- Backup import missing child audit: import rejected.
- Asset purchase from child account: audit required.

---

## INV-007 — Atomic Operations

**Statement:** Every financial operation that touches more than one account is atomic. Either all entries are written or none are.

**Enforcement:**
- Local: SQLite transactions wrap all related ledger entries.
- Cloud: Firestore batch writes or transactions for multi-document operations.
- Sync queue: operations queued as complete units; partial upload is not possible.

**Test coverage required:**
- Simulate failure mid-transfer → neither entry is persisted.
- After crash recovery, no orphaned single-sided entries exist.

---

## INV-008 — Idempotency

**Statement:** Applying the same financial operation twice has no additional effect beyond the first application.

**Mathematical form:**
```
apply(op, apply(op, state)) = apply(op, state)
```

**Enforcement:**
- **Requirement:** Every operation must have a stable client-generated UUID (operationId).
- **Planned:** Local database: a UNIQUE constraint on operationId is planned for the ledger_entries table.
- **Planned:** Cloud: a Firestore transaction is designed to check for an existing document with the same operationId before writing.
- **Planned:** Sync queue: the sync service must mark operations as synced by operationId and must never re-upload a synced ID.

**Test coverage required:**
- Submit same operation twice locally: second is a no-op, balance unchanged.
- Submit same operation from two devices simultaneously: one succeeds, one is rejected.
- Retry after network failure: idempotent.

---

## INV-009 — Net Worth Equation

**Statement (requirement):** Net worth must always equal total assets minus total liabilities. This is a design invariant; the implementation must uphold it. It is not yet verified.

**Mathematical form:**
```
NetWorth = Σ balance(a) for a in all_asset_accounts where includeInNetWorth = true
         − Σ outstanding(l) for l in all_active_liabilities
```

**Enforcement:**
- Net worth is computed fresh from the ledger on every read.
- No cached net-worth value is stored as canonical.
- Liabilities maintain their outstanding balance via repayment ledger entries.

**Test coverage required:**
- After income: net worth increases by income amount.
- After expense: net worth decreases by expense amount.
- After transfer: net worth unchanged.
- After creating liability: net worth decreases by liability amount.
- After repaying principal: net worth unchanged (asset decreases, liability decreases equally).
- After repaying interest/fees: net worth decreases by interest/fee.
- After gold purchase (no fee): net worth unchanged.
- After gold sale at gain: net worth increases by realized gain.

---

## INV-010 — Spouse Wallet Balance Consistency

**Statement (requirement):** The spouse wallet balance must equal the sum of transfers in minus expenses paid from it minus transfers out. This is a design invariant to be upheld by the implementation.

**Mathematical form:**
```
balance(spouseWallet) = Σ(transferIn) − Σ(expensesPaid) − Σ(transferOut)
```

**Planned enforcement:**
- Balance is derived from the ledger, not stored directly.
- **Requirement:** Spouse spending must be recorded as an expense from the spouse wallet account, not from any other account.
- **Requirement:** Money returned from the spouse must be recorded as a transfer out of the spouse wallet, not as a negative expense.

**Test coverage required:**
- Transfer 2000 to wife wallet → balance 2000.
- Record 1300 grocery expense from wife wallet → balance 700.
- Record 500 healthcare expense from wife wallet → balance 200.
- Transfer 200 back → balance 0.
- At each step: verify balance formula.

---

## INV-011 — Transfer Does Not Appear in Income or Expense Reports

**Statement:** No transfer entry (type: transferOut, transferIn) appears as income or expense in any report.

**Enforcement:**
- **Requirement:** Report queries must filter: `WHERE entry_type NOT IN (transferOut, transferIn)` for all income/expense reports.
- **Requirement:** Transfer fee entries (type: transferFee) ARE expenses and must appear in expense reports.
- **Requirement:** Budget spending calculations must exclude transferOut and transferIn entries.

**Test coverage required:**
- Monthly expense report: transfers not included.
- Monthly income report: transfers not included.
- Budget utilization: transfer amount not deducted from budget.
- Transfer fee IS counted in expense report and budget.

---

## INV-012 — Historical Balance Correctness

**Statement (requirement):** The design requires that the balance of any account at any historical date can be computed from the ledger alone. The implementation must uphold this.

**Mathematical form:**
```
historicalBalance(accountId, date) =
    Σ credit entries where effectiveDate ≤ date
  − Σ debit entries where effectiveDate ≤ date
```

**Enforcement:**
- Ledger entries always record `effectiveDate` (user-chosen date) separately from `recordedAt` (system timestamp).
- Queries for historical balance use `effectiveDate`.
- Backdated entries are allowed but must be clearly marked with both dates.

**Test coverage required:**
- Record income on day 1, expense on day 5. Query balance on day 3 → only income reflected.
- Query balance on day 10 → both reflected.
- Backdated entry entered on day 10 but effective day 2: historical query on day 3 includes it.

---

## INV-013 — Certificate Interest Does Not Double-Count with Principal

**Statement:** Interest income from a certificate is a separate credit on the destination account. It does not increase the certificate principal balance.

**Enforcement:**
- Interest payout creates: `interestIncome` credit on destination account.
- Certificate account balance remains at original principal.
- No credit entry is created on the certificate account for interest.

**Test coverage required:**
- Certificate balance after interest payout: unchanged (still equals principal).
- Destination bank account balance after interest payout: increased by interest amount.
- Net worth: increased by interest amount.

---

## INV-014 — Gold Weight Stored as Integer

**Statement:** Gold weight is stored as integer milligrams (1 gram = 1000 milligrams) to avoid floating-point issues.

**Enforcement:**
- `GoldHolding.weightMilligrams: int` — never `double`.
- Display: `(weightMilligrams / 1000.0).toStringAsFixed(2)` — only in the display layer.
- Calculations: integer arithmetic on milligrams.

**Test coverage required:**
- 10.5 grams stored as 10500 milligrams.
- Split sale of 5 grams: 5000 milligrams deducted, 5500 remaining.

---

## INV-015 — Archived Accounts Preserve History

**Statement:** Archiving an account does not delete its ledger history. The account's historical balance remains queryable. The account is excluded from active totals but its history is preserved.

**Enforcement:**
- Archive sets `isArchived = true` on the account record only.
- No ledger entries are deleted.
- Active balance queries: `WHERE isArchived = false`.
- Historical queries: `WHERE true` (include archived).
- Net worth: excludes archived accounts.

**Test coverage required:**
- Archive account with balance 5000 → net worth decreases by 5000.
- Query history of archived account → returns all historical entries.
- Restore archived account → net worth increases by 5000.

---

## INV-016 — Concurrent Transfer Safety

**Statement:** Two concurrent transfers that would together cause a negative balance must not both succeed.

**Enforcement:**
- Local: SQLite SERIALIZABLE transactions with balance check inside the transaction.
- Cloud: Firestore transactions with optimistic locking on balance snapshot.
- Sync: operations processed in order; conflict detected and surfaced to user.

**Test coverage required:**
- Account with balance 1000. Two concurrent transfers of 700 each. Only one succeeds.
- After conflict: total deducted = 700, balance = 300.

---

## INV-017 — No Sensitive Data in Logs

**Statement:** Financial amounts, account balances, transaction details, authentication tokens, child-fund details, and AI request bodies must never appear in logs.

**Enforcement:**
- Custom logger with `RedactedLogger` wrapper.
- Money.toString() returns `[REDACTED_AMOUNT]` in production builds.
- Account IDs are logged but not balances.
- Logger level set to WARNING or above in production.

**Test coverage required:**
- Log output scan: no amount in minor units appears in log strings.
- Log output scan: no authentication token appears.

---

## INV-018 — Backup Restore Does Not Overwrite Without Confirmation

**Statement:** Importing a backup that replaces existing data requires: explicit user confirmation, prior automatic backup, and schema validation.

**Enforcement:**
- Import flow: validate → preview → auto-backup current state → confirm → replace.
- Schema validation rejects files with unsupported future version numbers.
- Partial import is not allowed: all-or-nothing.

**Test coverage required:**
- Import invalid schema: rejected before confirmation.
- Import with replace: auto-backup created before replacement.
- Import cancelled: original data unchanged.

---

## Summary Table

| ID | Invariant | Critical Path |
|---|---|---|
| INV-001 | Single location of money | Transfer, income, expense |
| INV-002 | Immutable ledger | All writes |
| INV-003 | Transfer neutrality | Net worth, reports |
| INV-004 | Certificate exclusivity | Certificate creation, maturity |
| INV-005 | No negative balance | All debits |
| INV-006 | Protected fund audit | Child withdrawals |
| INV-007 | Atomic operations | All multi-entry ops |
| INV-008 | Idempotency | Retry, sync |
| INV-009 | Net worth equation | All operations |
| INV-010 | Spouse wallet consistency | Spouse operations |
| INV-011 | Transfers not in reports | All reports |
| INV-012 | Historical balance | Reports, export |
| INV-013 | Interest does not inflate principal | Certificates |
| INV-014 | Gold weight as integer | Gold operations |
| INV-015 | Archived accounts preserve history | Archive |
| INV-016 | Concurrent transfer safety | Concurrent writes |
| INV-017 | No sensitive logs | Logging layer |
| INV-018 | Backup confirmation | Backup/restore |
