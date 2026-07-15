# Financial Model

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15  
**Status:** Authoritative — do not implement features that contradict this model

---

## 1. Fundamental Principle

Every unit of money exists in exactly one financial location at a time.

Money is never silently duplicated. Money is never silently destroyed. Money moves between locations only through explicit, permanently recorded operations.

The system maintains a strict double-entry style ledger where every credit has an equal and opposite debit in a different account, or against a special equity/income/expense category. Balances are always derived from the ledger — never stored as editable numbers.

---

## 2. Money Type

```dart
final class Money {
  final int minorUnits;   // e.g. 100 = 1.00 EGP, 150 = 1.50 EGP
  final String currencyCode; // e.g. "EGP"

  const Money({required this.minorUnits, required this.currencyCode});

  Money operator +(Money other) {
    assert(currencyCode == other.currencyCode, 'Currency mismatch');
    return Money(minorUnits: minorUnits + other.minorUnits, currencyCode: currencyCode);
  }

  Money operator -(Money other) {
    assert(currencyCode == other.currencyCode, 'Currency mismatch');
    return Money(minorUnits: minorUnits - other.minorUnits, currencyCode: currencyCode);
  }

  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;
  bool get isNegative => minorUnits < 0;
}
```

**Invariants:**

- `minorUnits` is always an integer. Never `double`.
- Currency codes follow ISO 4217 (EGP = Egyptian Pound, 2 decimal places, so 1 EGP = 100 minor units).
- v1 supports single household currency. All accounts default to EGP.
- Future multi-currency: exchange rate records will be added; cross-currency transfers will require an explicit rate.

---

## 3. Financial Account

A financial account is a named location that holds money. It is not a number — it is a container whose balance is derived from the sum of all ledger entries that reference it.

```
Account balance = Σ(credit entries) − Σ(debit entries)
```

All account balances are computed on read. They are cached for display performance but never stored as the canonical source of truth.

### Account types and their semantics

| Type               | Owner          | Spendable    | Protected    | Net Worth    | Zakat        |
| ------------------ | -------------- | ------------ | ------------ | ------------ | ------------ |
| personalCashWallet | user           | Yes          | No           | Yes          | Configurable |
| spouseCashWallet   | spouse         | Yes          | No           | Yes          | Configurable |
| householdCash      | household      | Yes          | No           | Yes          | Configurable |
| homeSavingsCash    | household      | Configurable | Configurable | Yes          | Configurable |
| bankAccount        | user/household | Yes          | No           | Yes          | Configurable |
| mobileWallet       | user/spouse    | Yes          | No           | Yes          | Configurable |
| childProtectedFund | child          | No\*         | Yes          | Configurable | Configurable |
| goalReserve        | household      | No\*         | Configurable | Yes          | No           |
| certificate        | user           | No\*         | No           | Yes          | Configurable |
| goldHolding        | user/household | No\*         | No           | Yes          | Configurable |
| investment         | user/household | No\*         | No           | Yes          | Configurable |
| otherAsset         | configurable   | Configurable | Configurable | Configurable | Configurable |

\*Money in these accounts can be withdrawn but requires explicit operation, not treated as freely spendable in budget calculations.

---

## 4. Ledger Entry

A ledger entry is an immutable record of a single debit or credit against one account.

```
LedgerEntry {
  id: UUID                        // stable, client-generated
  operationId: UUID               // groups entries that belong to the same operation
  accountId: UUID
  direction: debit | credit
  amount: Money                   // always positive minor units
  entryType: LedgerEntryType
  effectiveDate: LocalDate
  recordedAt: Instant
  notes: String?
  createdBy: String               // userId
  isReversal: bool
  reversalOfId: UUID?             // if this entry reverses another
}
```

Ledger entries are append-only. Once written, they cannot be modified or deleted. Corrections are made through reversal entries.

### Ledger entry types

```dart
enum LedgerEntryType {
  openingBalance,
  income,
  expense,
  transferOut,
  transferIn,
  transferFee,
  adjustmentDebit,
  adjustmentCredit,
  assetPurchase,
  assetSale,
  liabilityCreation,
  liabilityRepayment,
  certificateFunding,
  certificateMaturityReturn,
  interestIncome,
  goldPurchase,
  goldSale,
  goalFunding,
  goalWithdrawal,
  childFundDeposit,
  childFundWithdrawal,
  reversalDebit,
  reversalCredit,
  sadaqahExpense,
  zakatExpense,
}
```

---

## 5. Financial Operations

A financial operation is a group of one or more ledger entries that together form one complete, atomic financial event.

### 5.1 Opening Balance

- Creates one credit entry on the target account.
- Balanced against the system equity account (not user-visible).
- Does not count as income.
- **Requirement:** Must be created only once per account. The ledger implementation must enforce this (e.g., via a UNIQUE constraint on account_id + entry_type=openingBalance in the database, or a domain-layer pre-check).
- **Requirement:** Subsequent balance corrections must use the Adjustment type, not a second opening balance.

### 5.2 Income

- Creates one credit entry on the destination account.
- Represents an external inflow of money into the household financial system.
- Increases net worth.
- Income categories: Salary, Business, Gift, CertificateInterest, InvestmentReturn, Refund, ChildGift, Other.

### 5.3 Expense

- Creates one debit entry on the source account.
- Represents an external outflow of money from the household financial system.
- Decreases net worth.
- Must record: spender, beneficiary, scope, category.

### 5.4 Transfer

- Creates exactly two ledger entries: one debit (source) and one credit (destination).
- Source and destination must differ.
- Amount must be positive.
- Source must have sufficient balance (unless overdraft is supported).
- Does not change net worth.
- Does not count as income or expense in any report.
- A transfer fee is recorded as a separate expense.

### 5.5 Adjustment

- Created when the derived balance differs from the real-world balance.
- Creates one debit or one credit entry with type adjustmentDebit/adjustmentCredit.
- Is auditable: must include reason and operator.
- Does affect net worth.

### 5.6 Certificate Funding

- Creates: transferOut on source bank account + certificateFunding credit on certificate account.
- Principal moves from bank account to certificate. Not counted in both.
- Does not affect net worth.

### 5.7 Certificate Maturity

- Creates: certificateMaturityReturn credit on destination bank account + debit closing the certificate.
- Final interest recorded as separate interestIncome.
- Certificate marked as matured.

### 5.8 Interest Income

- Creates one credit on the destination account.
- Type: interestIncome.
- Increases net worth.

### 5.9 Gold Purchase

- Creates: debit on source account (goldPurchase) + credit on gold holding account.
- Making charges/fees: separate expense entry.
- Net worth unchanged (purchase value moves from liquid to gold asset).

### 5.10 Gold Sale

- Creates: debit on gold holding (goldSale) + credit on destination account.
- Realized gain/loss recorded.
- If sale proceeds > purchase value → realized gain → increases net worth.
- If sale proceeds < purchase value → realized loss → decreases net worth.

### 5.11 Child Fund Deposit

- Creates one credit on childProtectedFund account.
- Type: childFundDeposit.
- Protected from budget spending calculations.

### 5.12 Child Fund Withdrawal

- Creates one debit on childProtectedFund account.
- Type: childFundWithdrawal.
- Requires: warning confirmation, reason, beneficiary, audit event.
- Permanent audit record cannot be deleted.

### 5.13 Goal Funding

- Creates: debit on source account + credit on goalReserve account.
- Does not affect net worth.
- Does not count as expense.

### 5.14 Liability Creation

- Records a new debt owed.
- A liability reduces net worth by its outstanding amount.
- Does not create a debit on a real account (the money was already received or spent).
- When money is borrowed: income entry records the receipt; liability records the obligation.

### 5.15 Liability Repayment

- Creates: debit on payment account.
- Reduces outstanding liability amount.
- Separates principal, interest, and fees.
- Principal repayment: decreases asset AND liability equally (no net worth change).
- Interest/fee payment: decreases asset only → net worth decreases.

---

## 6. Account Balance Formula

```
balance(accountId) = Σ credit entries for accountId
                   − Σ debit entries for accountId
                   (all entries where isReversal = false OR isReversal = true)
```

Note: Reversal entries are included in the sum. A reversal credit + reversal debit pair nets to zero, effectively cancelling the original entries.

Historical balance:

```
balance(accountId, asOf: date) = Σ credit entries where effectiveDate ≤ date
                                − Σ debit entries where effectiveDate ≤ date
```

---

## 7. Net Worth

```
Net Worth = Total Assets − Total Liabilities

Total Assets = Σ balance(account) for all accounts where:
    includeInNetWorth = true
    AND account is not archived

Total Liabilities = Σ outstanding(liability) for all liabilities where:
    isSettled = false
```

### What counts as an asset account for net worth

- All personalCashWallet, spouseCashWallet, householdCash, homeSavingsCash
- All bankAccount and mobileWallet
- All certificate accounts (principal only, interest not double-counted if paid to bank)
- Gold holdings (at purchase value; unrealized gain shown separately)
- goalReserve accounts (yes, funded goals are still your money)
- childProtectedFund (configurable; defaults to included but flagged separately)
- investment, otherAsset (configurable)

### Net worth categories for display

| Category          | Accounts                                            | Notes                    |
| ----------------- | --------------------------------------------------- | ------------------------ |
| Available Cash    | personalCashWallet, spouseCashWallet, householdCash | Freely spendable         |
| Savings           | homeSavingsCash, goalReserve                        | Earmarked but accessible |
| Bank              | bankAccount, mobileWallet                           | Liquid                   |
| Certificates      | certificate                                         | Semi-liquid              |
| Gold              | goldHolding                                         | Illiquid                 |
| Investments       | investment                                          | Illiquid                 |
| Child Funds       | childProtectedFund                                  | Protected                |
| Other             | otherAsset                                          | Configurable             |
| Total Assets      | All above                                           | Sum                      |
| Total Liabilities | All active liabilities                              | Subtract                 |
| **Net Worth**     |                                                     | Assets − Liabilities     |

---

## 8. Available Money

Available money is the subset of net worth that can be spent today without penalty.

```
Available = Σ balance(account) for all accounts where:
    isSpendable = true
    AND isProtected = false
    AND account is not archived
```

This excludes:

- Certificates (locked until maturity)
- Gold (would need sale)
- Goal reserves (earmarked)
- Child-protected funds (protected)
- Investment accounts (illiquid)

---

## 9. Protected Money

Protected money is money that exists in the household financial system but is not available for regular spending.

Protected accounts:

- childProtectedFund (always protected)
- Any account where isProtected = true (user-configured)
- Goal reserves (partially protected: can withdraw but should not count as available)

Protected money IS included in net worth by default, but is shown separately on the dashboard.

---

## 10. Personal vs. Household Money

Money is classified by owner at the account level and by scope at the transaction level.

**Personal money:** Balances in accounts owned by `user`. Spending from these accounts with scope `personal` is personal spending.

**Household money:** Balances in accounts owned by `household` or `shared`. Spending from any account with scope `household` is household spending.

**Spouse money:** Balances in accounts owned by `spouse`. Spending from these accounts with scope `spouse` or `household` is tracked as spouse spending.

**Child money:** Balances in accounts owned by `child`. Child-protected; scope `child` for all child expenses.

Reports separate all four categories. A single expense must have exactly one scope.

---

## 11. Savings

Home savings are modeled as one or more `homeSavingsCash` accounts. They have ledger-backed balances. Possible named savings accounts:

- Emergency Cash (isProtected: true)
- Family Savings
- Long-Term Savings
- House Deposit Goal → goalReserve type

Savings are not freely spendable (isSpendable: configurable). Spending from savings is allowed but should be intentional and visible on the dashboard.

---

## 12. Certificates

A certificate is a financial account of type `certificate`.

- Principal is removed from the source bank account at creation.
- The certificate account holds the principal balance.
- Interest is recorded as income (separate from principal).
- At maturity, principal returns to selected account; interest recorded separately.
- At no point is principal counted in both the bank account and the certificate.

**Key invariant:** For any certificate with status = active:

```
bank_account_balance = bank_balance_before_funding − certificate_principal
certificate_balance = certificate_principal
```

---

## 13. Gold

Gold is a financial account of type `goldHolding`.

- Balance = purchase price of all unsold gold.
- Current value = current price per gram × remaining grams.
- Unrealized gain/loss = current value − balance (purchase value).
- Unrealized gain/loss is shown for information but does NOT affect the core ledger balance until a sale event.
- On sale: realized gain/loss IS recorded and changes net worth.

Gold properties tracked:

- Type (coin, bar, jewelry)
- Karat (18k, 21k, 24k)
- Weight in grams (stored as integer milligrams to avoid decimal)
- Purchase price (minorUnits)
- Current price (minorUnits per gram)

---

## 14. Spouse Wallet Model

Spouse wallet invariant:

```
wife_wallet_balance = Σ transfers_in − Σ expenses_paid_from_wallet − Σ transfers_out
```

**Invariant (requirement):** This balance is required to equal the actual cash held. The implementation must ensure all spouse cash flows pass through this account's ledger.

Spouse spending report:

- Total received from home savings (transfers in)
- Total spent (expenses paid by spouse)
- Total returned (transfers out)
- Current balance

Household expenses paid by user but benefiting household are tracked separately via scope and beneficiary.

---

## 15. Zakat Model

Zakat is a calculation aid. The application:

1. Aggregates balances of user-selected asset accounts on the calculation date.
2. Deducts user-selected liabilities.
3. Computes net zakatable amount.
4. Compares against nisab (user selects gold or silver basis).
5. If net zakatable amount ≥ nisab, zakat due = 2.5% × net zakatable amount.

Gold zakat rule: Only a portion of gold used as jewelry (above a certain threshold) is zakatable. User must confirm classification.

The application shows calculation history. Zakat payment is recorded as a sadaqah/zakat expense.

**Disclaimer always displayed:**

> هذه الأداة للمساعدة في الحساب فقط. لا تُغني عن استشارة عالم متخصص في فقه الزكاة لحالتك الخاصة.

---

## 16. Transfers and Net Worth

Transfers are designed not to change net worth. The mechanism that achieves this:

- Transfer creates debit(source) + credit(destination) of equal amount.
- Both accounts are included in the net-worth sum.
- Therefore the sum is unchanged.

**Note:** This proof assumes both accounts hold the same currency. Cross-currency transfers require a separate policy (see Section 19).

Transfer fee creates an expense debit on the source account and does reduce net worth (money left the system as fee).

---

## 17. Currency Representation

EGP uses 2 decimal places. 1 EGP = 100 piasters = 100 minor units.

Storage: All amounts stored as integer `minorUnits`.

Display:

- EGP amounts formatted as: `1,500.00 ج.م` (Arabic) or `EGP 1,500.00` (English).
- Never display raw `minorUnits` to the user.
- Formatter is centralized in `core/financial/money_formatter.dart`.

Arithmetic:

- All additions, subtractions use integer arithmetic.
- Division (for interest, percentage calculations) uses integer division with explicit rounding rules (always round toward zero for splits, banker's rounding for display).

---

## 18. Idempotency

**Requirement:** Every operation must have a stable client-generated UUID. If the same operation is submitted twice (e.g., on network retry), the second submission must be rejected and the operation applied exactly once.

Idempotency is planned to be enforced at three levels (not yet implemented):

- **Planned — local:** A UNIQUE constraint on operationId in the ledger_entries table prevents the same operation from being recorded twice locally.
- **Planned — cloud:** A Firestore transaction with an existence check on the operation document prevents duplicate cloud writes.
- **Planned — sync queue:** The sync service will detect already-synced operation IDs and will not re-submit them.

None of these mechanisms are implemented. They are design requirements for Phase 2 and later.

---

## 19. Cross-Currency Policy (V1)

**V1 policy: Cross-currency operations are prohibited.**

All accounts in a household must share the same currency code (EGP by default). The application must reject any operation that would create a ledger entry with a currency code different from the household's base currency.

This prohibition is a requirement for Phase 2 validation logic. It is not yet implemented.

**Consequences for the transfer-neutrality proof:**

The transfer-neutrality proof in Section 16 (debit(source) + credit(destination) = 0 change in net worth) is valid only because both entries are in the same currency. The proof must not be applied across currencies with equal minor units, since 100 EGP ≠ 100 USD.

**Future multi-currency (V2 planned, not designed in detail):**

When V2 introduces multi-currency, each cross-currency transfer must record:
- Source account ID, source currency, source amount in minor units
- Destination account ID, destination currency, destination amount in minor units
- Exchange rate (as a rational number: numerator/denominator, both integers — never a float)
- Rate source (user-entered; no live API in V2 scope)
- Rate timestamp
- Realized foreign-exchange gain or loss (destination amount at current rate minus destination amount at rate used at transaction time, converted to reporting currency)
- Rounding policy (truncate toward zero for the destination credit)
- Transfer fee currency and amount

Until V2 is designed, no cross-currency transfer logic is in scope.

---

## 20. External Money Flows and the Household Boundary

The household financial system has a defined boundary. Money inside the boundary is tracked in financial accounts. Money outside the boundary (employer, shops, government, nature, other people) is not tracked as accounts.

### How money enters the boundary (income)

An income operation creates a credit on a destination account. The source is external (outside the boundary) and is represented only as a label (e.g., "employer name," "gift from grandparent"), never as a debit on an internal account.

The double-entry balance is maintained via a notional external-equity position that is never displayed to the user. For accounting purposes: credit(destination account) is balanced by debit(equity, external income). The user sees only the destination account balance increasing.

### How money leaves the boundary (expense)

An expense operation creates a debit on a source account. The destination is external and is represented as a label (category, notes). The double-entry balance: debit(source account) is balanced by credit(equity, external expense). The user sees the source account balance decreasing.

### Gifts and sadaqah

- Gifts received: recorded as income to the appropriate account. The gift source is a label.
- Sadaqah paid: recorded as an expense from the source account. The sadaqah category is used. If linked to an existing expense operation, the sadaqah record references that operation's ID and must not create a second expense debit.
- Child gifts received: recorded as `childFundDeposit` income to the child-protected account.

### Asset gains and losses

- Unrealized gain/loss (gold price change): changes the display value of the asset but does NOT create a ledger entry. No money enters or leaves any account.
- Realized gain/loss (gold sale at a price different from cost basis): the difference between sale proceeds and cost basis is recorded as a realized gain (net-worth-increasing income event) or realized loss (net-worth-decreasing expense event) within the sale operation. It does not leave the household boundary — it is an adjustment to the net worth within the boundary.

### Liability interest

When interest is charged on a liability, the interest amount leaves the boundary as an expense. The repayment operation separates:
- Principal repayment: internal (asset decreases, liability decreases equally — net worth unchanged)
- Interest payment: external (asset decreases, money leaves the boundary — net worth decreases)

### Fees

Fees (transfer fees, making charges, certificate setup fees) are external outflows. They are recorded as expense entries and reduce net worth. They are never modeled as transfers.

---

## 21. Historical Accuracy When Account Metadata Changes

### Problem

An account's owner, purpose, protection status, net-worth inclusion flag, and zakat inclusion flag may change over the life of the application. Historical reports that query these flags at query time will produce incorrect results for periods before the change.

### Policy (V1)

**Metadata changes are forward-only in their effect on live totals. Historical ledger amounts are not affected.**

Specifically:

- The ledger stores immutable entries with `accountId`. The amount and date of every transaction are permanently fixed.
- Account metadata (`ownerType`, `fundPurpose`, `isProtected`, `includeInNetWorth`, `includeInZakat`) is mutable on the account record.
- Live balance, net-worth, and available-money calculations use the account's current metadata.
- **Historical period reports** (e.g., "net worth in January 2026") use the account's current metadata, **except** for the two cases below.

### Exceptions requiring point-in-time snapshots

**1. Zakat calculations.** When the user records a zakat calculation for a past hawl date, the system must record a snapshot of the inclusion flags at the time of the calculation. The `ZakatCalculation` entity already stores `includedAccounts` as an explicit list, which serves as the snapshot.

**2. Net-worth historical trend.** When displaying a net-worth chart over time, the chart must use the current metadata for all historical points. If a user changes an account from `includeInNetWorth = true` to `false`, the historical chart will retroactively exclude it. This is a **known limitation accepted for V1**. It is documented here and must be disclosed in the UI as: "Historical net worth reflects your current account configuration."

### Account replacement (for significant reclassification)

If a user needs to change an account's type (e.g., reclassify a personal cash wallet as a spouse wallet), they should:
1. Archive the existing account.
2. Create a new account with the correct type.
3. Record an explicit transfer (or opening balance) to establish the new account's balance.

The implementation must not allow changing `FinancialAccountType` on an existing account after creation. This prevents silent reclassification of historical ledger entries.

**Requirement:** `FinancialAccountType` must be immutable after account creation. All other metadata fields (`name`, `ownerType`, `fundPurpose`, flags) may be updated.

---

## 22. Reversal Specification

### What a reversal is

A reversal is an append-only operation that creates new ledger entries that exactly cancel the entries of a previous operation. Reversals never modify or delete original entries.

### Reversal structure

```
Reversal operation:
  type: reversal
  reversalOfOperationId: UUID    // links to original operation
  
Reversal ledger entries:
  For each original ledger entry E:
    Create a new entry with:
      direction: opposite of E.direction (credit ↔ debit)
      amount: same as E.amount
      entry_type: reversalDebit or reversalCredit
      is_reversal: true
      reversal_of_entry_id: E.id
      operation_id: reversal_operation_id
```

### Preventing duplicate reversals

**Requirement:** An operation may be reversed at most once. The implementation must enforce this by checking: `SELECT COUNT(*) FROM operations WHERE reversal_of_operation_id = ? AND is_reversed_operation = true`. If a reversal already exists, the reversal request must be rejected with a DuplicateReversalError.

This check must occur inside the local database transaction, not merely at the application layer.

### Partial reversals

**V1 policy: Partial reversals are not supported.** A reversal must cancel the entire original operation.

If the user needs to partially correct a transaction (e.g., wrong amount), the workflow is:
1. Reverse the entire original operation.
2. Record a new correct operation.

Partial reversal support may be added in V2 if user research identifies a strong need.

### Reversal of multi-leg operations (transfers)

A transfer consists of two ledger entries (debit source, credit destination). Its reversal creates two opposite entries (credit source, debit destination). Both legs must be reversed atomically. A reversal of a transfer with a fee must also reverse the fee entry.

### Treatment of reversed operations in reports

**Requirement:** Reversed operations and their reversals must both appear in the audit log (for traceability) but must not appear in income/expense/balance calculations. Specifically:

- Income/expense report queries: `WHERE is_reversed = false AND (type != 'reversal')`
- Balance calculations: reversal entries are included — the reversal credit and reversal debit net to zero together with the original entries, so the balance is correct without any special filter.
- Transfers: reversed transfers disappear from the running balance because the reversal entries cancel the original entries.

### Reversal idempotency

A reversal operation has its own operationId. Submitting the same reversal twice produces a DuplicateOperationError (same mechanism as for all operations). The reversal is applied exactly once.

### Preservation of original records

Original ledger entries are never modified. Original operation records have their `is_reversed = true` flag updated to indicate they have been reversed. This update is the only permitted mutation of an operation record after creation.

---

## 23. Gold: Dual Representation

Gold is represented in two distinct ways that must not be confused:

### 23.1 Monetary ledger representation

The `goldHolding` account has a monetary balance in EGP (or the household currency). This balance equals the **total cost basis** of all unsold gold currently held:

```
gold_account_balance = Σ (purchase price of each unsold lot)
```

This balance participates in net-worth calculations and is stored in the ledger via goldPurchase (credit on gold account) and goldSale (debit on gold account) entries.

### 23.2 Physical quantity representation

Gold quantity is stored separately in the `metadata` JSON of the `goldHolding` account:

```
metadata.weightMilligrams: int      // total weight of unsold gold
metadata.karat: string             // k18 | k21 | k22 | k24
metadata.goldType: string          // coin | bar | jewelry | other
```

When gold is partially sold, both the monetary ledger (sale debit) and the physical quantity (weightMilligrams reduction) are updated. These two representations must stay synchronized.

**Requirement:** No separate gold-position table is used in V1. Physical quantity is stored in the account's `metadata` JSON. If a household has multiple gold lots with different karats, each lot must have a separate `goldHolding` account.

### 23.3 Current market value (not in ledger)

```
current_market_value = (metadata.weightMilligrams / 1000) × current_price_per_gram
```

`current_price_per_gram` is also stored in `metadata.currentPricePerGramMinorUnits` as an integer. This value is never stored in the ledger. It is a display annotation only.

### 23.4 Unrealized gain/loss (not in ledger)

```
unrealized_gain_or_loss = current_market_value - gold_account_balance
```

This is a display-only calculation. It does not create ledger entries and does not affect net worth in the ledger. Net worth uses the cost basis (ledger balance), not the market value.

**Display note:** Net worth shown in the dashboard may optionally show two lines:
- "Net worth at cost basis: X EGP"
- "Net worth at current gold market value: Y EGP (estimated)"

### 23.5 Realized gain/loss on sale (in ledger)

On a partial or full sale, the realized gain/loss is:
```
realized = sale_proceeds - (cost_basis_of_sold_portion)

cost_basis_of_sold_portion = gold_account_balance × (sold_weight / total_weight)
```

All values use integer arithmetic on minor units and milligrams. The realized gain is recorded as income; the realized loss is recorded as an expense.

---

## 24. Liability Model

### 24.1 Design choice: position records only (V1)

**V1 uses position records for liabilities, not ledger accounts.**

A `Liability` entity has an `outstandingAmountMinorUnits` field that is updated (decremented) as repayments are made. This field is the canonical outstanding balance for the liability.

The net-worth formula deducts outstanding liability balances:
```
Net Worth = Σ asset_account_balances − Σ liability.outstandingAmountMinorUnits
```

### 24.2 Why not a liability ledger account?

A full double-entry system would model liabilities as accounts with their own ledger entries (negative equity). This is more rigorous but significantly more complex to explain and query. For V1's household scale, the position-record approach is adequate and easier to audit.

**Trade-off accepted:** The `outstandingAmountMinorUnits` field on the Liability record is the one mutable field that does not derive from ledger entries. It is reduced by repayment operations. This field must be updated atomically with the corresponding ledger entry (debit on the payment account).

### 24.3 Repayment operation structure

A repayment creates:
1. A debit ledger entry on the payment account (type: liabilityRepayment), for the total payment amount.
2. A record in the operation's metadata specifying: principal_paid, interest_paid, fees_paid.
3. An atomic update to `liability.outstandingAmountMinorUnits` reduced by `principal_paid`.

Net-worth effect:
- Principal paid: asset decreases, liability decreases → net worth unchanged.
- Interest paid: asset decreases, liability unchanged → net worth decreases.
- Fees paid: asset decreases, liability unchanged → net worth decreases.

### 24.4 Liability creation

When money is borrowed and received into a bank account:
1. Income entry: credit on the receiving bank account (income type: borrowed).
2. Liability record created: `outstandingAmountMinorUnits = originalAmount`.
3. Net-worth effect: asset increases by borrowed amount; liability increases by same amount → net worth unchanged (the new liability offsets the new asset).

### 24.5 Historical liability balance

The outstanding amount at any historical date cannot be reconstructed from the ledger alone (since it is a mutable field). To support historical liability queries, repayment operations store their `effectiveDate`. The outstanding amount at a past date can be computed as:

```
outstanding(date) = originalAmount − Σ principal_paid for repayments where effectiveDate ≤ date
```

The `metadata` JSON on repayment operations must include `principalPaidMinorUnits` to support this query.

### 24.6 Write-off

If a liability is forgiven or written off:
1. An adjustment operation sets `outstandingAmountMinorUnits = 0`.
2. `isSettled = true`.
3. The written-off amount is recorded as income (debt forgiveness) in the operation metadata.
4. Net-worth effect: liability disappears → net worth increases by the written-off amount.

