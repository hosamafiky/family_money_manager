# Data Model

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## 1. Design Principles

- All identifiers are client-generated UUIDs (version 4).
- All timestamps are stored in UTC (ISO 8601).
- All money amounts are stored as integer `minorUnits`.
- All weights (gold) are stored as integer milligrams.
- Enums are stored as stable string codes, never translated text.
- No entity has a mutable primary balance field; balances are always derived.
- Audit fields (`createdAt`, `updatedAt`, `createdBy`, `syncedAt`) are on every entity.
- Deleted or archived entities are soft-deleted; hard deletes are not supported.

---

## 2. Core Entities

### 2.1 Household

The root container for all financial data. One household per user account.

```
Household {
  id: UUID                        // stable
  name: String                    // "Ahmad Family"
  ownerUserId: String             // Firebase UID of primary user
  currencyCode: String            // "EGP"
  primaryLanguage: String         // "ar"
  memberNames: {                  // display names only
    user: String                  // "Ahmad"
    spouse: String?               // "Hana"
    child: String?                // "Yousuf"
  }
  createdAt: DateTime
  updatedAt: DateTime
  schemaVersion: int              // for migration
}
```

---

### 2.2 FinancialAccount

```
FinancialAccount {
  id: UUID
  householdId: UUID
  name: String                    // user-facing label
  type: FinancialAccountType      // enum string code
  ownerType: AccountOwnerType     // enum string code
  fundPurpose: FundPurpose        // enum string code
  currencyCode: String            // "EGP"
  isSpendable: bool               // included in available cash?
  isProtected: bool               // requires extra confirmation to debit?
  includeInNetWorth: bool         // counted in net worth?
  includeInZakat: bool            // counted in zakat calculation?
  isArchived: bool
  archivedAt: DateTime?
  notes: String?
  displayOrder: int               // user-set display order
  metadata: Map<String, dynamic>? // type-specific extra fields (JSON)
  createdAt: DateTime
  updatedAt: DateTime
  createdBy: String               // userId
  syncStatus: SyncStatus
}
```

Type-specific metadata examples (stored in `metadata` JSON):

- bankAccount: `{ bankName, lastFourDigits, hasInterest, interestRate }`
- certificate: `{ bankAccountId, principal, startDate, maturityDate, rateType, rate, payoutFrequency, payoutAccountId, status }`
- goldHolding: `{ goldType, karat, weightMilligrams, purchasePriceMinorUnits, currentPricePerGram }`

---

### 2.3 LedgerEntry

Immutable. Append-only. Never updated or deleted.

```
LedgerEntry {
  id: UUID                        // entry-level ID
  operationId: UUID               // groups entries belonging to same operation
  householdId: UUID
  accountId: UUID
  direction: LedgerDirection      // credit | debit
  amountMinorUnits: int           // always positive
  currencyCode: String
  entryType: LedgerEntryType      // enum string code
  effectiveDate: String           // "YYYY-MM-DD" (user-chosen date)
  recordedAt: DateTime            // system timestamp when written
  notes: String?
  createdBy: String               // userId
  isReversal: bool
  reversalOfEntryId: UUID?        // if reversal, links to original entry
  syncStatus: SyncStatus
  metadata: Map<String, dynamic>? // operation-specific data (JSON)
}
```

---

### 2.4 Operation

A logical wrapper grouping related ledger entries into a single financial event. Used for display and reporting.

```
Operation {
  id: UUID                        // = operationId on LedgerEntry
  householdId: UUID
  type: OperationType             // income | expense | transfer | openingBalance | ...
  effectiveDate: String
  recordedAt: DateTime
  description: String?            // user notes
  categoryCode: String?           // expense/income category
  scope: ExpenseScope?            // personal | household | spouse | child | shared
  spenderRole: HouseholdMemberRole?
  beneficiaryRole: HouseholdMemberRole?
  sourceAccountId: UUID?
  destinationAccountId: UUID?
  totalAmountMinorUnits: int
  currencyCode: String
  isRecurring: bool
  recurringRuleId: UUID?
  tags: List<String>
  receiptPath: String?            // local file path (encrypted)
  isReversed: bool
  reversedBy: UUID?               // operationId of the reversal operation
  createdBy: String
  createdAt: DateTime
  updatedAt: DateTime
  syncStatus: SyncStatus
}
```

---

### 2.5 ChildWithdrawalAudit

Immutable. Written atomically with every childFundWithdrawal ledger entry.

```
ChildWithdrawalAudit {
  id: UUID
  operationId: UUID               // linked to the withdrawal operation
  householdId: UUID
  accountId: UUID                 // the childProtectedFund account
  amountMinorUnits: int
  reason: String                  // mandatory, non-empty
  beneficiary: HouseholdMemberRole
  confirmedAt: DateTime           // when user confirmed the warning
  confirmedBy: String             // userId
  warningShown: bool              // required to be true; the planned implementation must enforce this before creating the record
  biometricConfirmed: bool
  createdAt: DateTime
  syncStatus: SyncStatus
}
```

---

### 2.6 Liability

```
Liability {
  id: UUID
  householdId: UUID
  name: String
  type: LiabilityType            // enum: personalLoan | creditCard | borrowedFromPerson | ...
  originalAmountMinorUnits: int
  outstandingAmountMinorUnits: int // maintained by repayment operations
  currencyCode: String
  dueDate: String?               // "YYYY-MM-DD"
  paymentAccountId: UUID?        // default payment account
  interestRatePercent: int?      // stored as basis points (e.g. 2000 = 20.00%)
  notes: String?
  isSettled: bool
  settledAt: DateTime?
  createdAt: DateTime
  updatedAt: DateTime
  createdBy: String
  syncStatus: SyncStatus
}
```

---

### 2.7 Goal

```
Goal {
  id: UUID
  householdId: UUID
  name: String
  description: String?
  targetAmountMinorUnits: int
  currencyCode: String
  deadline: String?              // "YYYY-MM-DD"
  reserveAccountId: UUID         // the linked goalReserve account
  status: GoalStatus             // active | completed | cancelled
  completedAt: DateTime?
  cancelledAt: DateTime?
  cancellationDestinationAccountId: UUID?
  reminderEnabled: bool
  reminderFrequency: String?     // "monthly"
  createdAt: DateTime
  updatedAt: DateTime
  createdBy: String
  syncStatus: SyncStatus
}
```

---

### 2.8 Budget

```
Budget {
  id: UUID
  householdId: UUID
  name: String
  scope: ExpenseScope            // personal | household | spouse | child | shared
  type: BudgetType               // overall | category | account
  categoryCode: String?          // if type = category
  accountId: UUID?               // if type = account
  periodType: BudgetPeriodType   // monthly | custom
  customStartDate: String?
  customEndDate: String?
  targetAmountMinorUnits: int
  warningThresholdPercent: int   // e.g. 80 means warn at 80%
  currencyCode: String
  isActive: bool
  createdAt: DateTime
  updatedAt: DateTime
  createdBy: String
  syncStatus: SyncStatus
}
```

---

### 2.9 RecurringRule

```
RecurringRule {
  id: UUID
  householdId: UUID
  operationType: OperationType
  frequency: RecurringFrequency  // daily | weekly | monthly | yearly
  dayOfMonth: int?               // 1–31
  nextDueDate: String
  endDate: String?
  isActive: bool
  templateOperationId: UUID      // the model operation to clone
  createdAt: DateTime
  updatedAt: DateTime
  syncStatus: SyncStatus
}
```

---

### 2.10 ZakatCalculation

```
ZakatCalculation {
  id: UUID
  householdId: UUID
  calculationDate: String        // "YYYY-MM-DD"
  hawlStartDate: String
  hawlEndDate: String
  nisabBasis: NisabBasis         // gold | silver
  nisabAmountMinorUnits: int
  includedAccounts: List<ZakatAccountEntry>
  excludedAccounts: List<UUID>
  deductedLiabilities: List<ZakatLiabilityEntry>
  totalZakatableAmountMinorUnits: int
  zakatDueMinorUnits: int        // 2.5% of zakatable amount if above nisab
  isPaidViaApp: bool
  paymentOperationId: UUID?
  notes: String?
  createdAt: DateTime
  createdBy: String
  syncStatus: SyncStatus
}

ZakatAccountEntry {
  accountId: UUID
  includedAmountMinorUnits: int  // may be partial (e.g. for gold jewelry exemption)
  notes: String?
}

ZakatLiabilityEntry {
  liabilityId: UUID
  deductedAmountMinorUnits: int
}
```

---

### 2.11 SadaqahRecord

```
SadaqahRecord {
  id: UUID
  householdId: UUID
  amountMinorUnits: int
  currencyCode: String
  date: String
  notes: String?
  linkedOperationId: UUID?       // if linked to an existing expense operation
  isLinked: bool                 // true if linkedOperationId is set
  createdAt: DateTime
  createdBy: String
  syncStatus: SyncStatus
}
```

---

### 2.12 BackupRecord

```
BackupRecord {
  id: UUID
  createdAt: DateTime
  schemaVersion: int
  operationCount: int
  accountCount: int
  filePath: String               // local path to encrypted backup file
  isEncrypted: bool
  sha256Hash: String             // integrity check
  notes: String?
}
```

---

### 2.13 SyncQueueEntry

```
SyncQueueEntry {
  id: UUID                       // = operationId of the pending entity
  entityType: String             // "LedgerEntry" | "Operation" | "FinancialAccount" | ...
  entityId: UUID
  changeType: SyncChangeType     // create | update (account metadata only)
  payload: String                // JSON serialized entity
  status: SyncStatus             // pending | uploading | synced | failed
  retryCount: int
  lastAttemptAt: DateTime?
  failureReason: String?
  createdAt: DateTime
}
```

---

## 3. Enum Definitions

### FinancialAccountType
```
personalCashWallet | spouseCashWallet | householdCash | homeSavingsCash |
bankAccount | mobileWallet | childProtectedFund | goalReserve |
certificate | goldHolding | investment | otherAsset
```

### AccountOwnerType
```
user | spouse | household | child | shared
```

### FundPurpose
```
available | householdSpending | personalSpending | emergencySavings |
longTermSavings | childProtected | investment | certificate | gold | custom
```

### LedgerEntryType
```
openingBalance | income | expense | transferOut | transferIn | transferFee |
adjustmentDebit | adjustmentCredit | assetPurchase | assetSale |
liabilityCreation | liabilityRepayment | certificateFunding |
certificateMaturityReturn | interestIncome | goldPurchase | goldSale |
goalFunding | goalWithdrawal | childFundDeposit | childFundWithdrawal |
reversalDebit | reversalCredit | sadaqahExpense | zakatExpense
```

### LedgerDirection
```
credit | debit
```

### OperationType
```
income | expense | transfer | openingBalance | adjustment | assetPurchase |
assetSale | liabilityCreation | liabilityRepayment | certificateFunding |
certificateMaturity | interestIncome | goldPurchase | goldSale |
goalFunding | goalWithdrawal | childFundDeposit | childFundWithdrawal |
reversal | sadaqah | zakat
```

### ExpenseScope
```
personal | household | spouse | child | shared
```

### HouseholdMemberRole
```
user | spouse | child | other
```

### LiabilityType
```
personalLoan | creditCard | borrowedFromPerson | owedToSupplier |
installment | lentToPerson
```

### GoalStatus
```
active | completed | cancelled
```

### BudgetType
```
overall | category | account
```

### BudgetPeriodType
```
monthly | custom
```

### RecurringFrequency
```
daily | weekly | biweekly | monthly | quarterly | yearly
```

### NisabBasis
```
gold | silver
```

### SyncStatus
```
local | pending | uploading | synced | conflict | failed
```

### SyncChangeType
```
create | update
```

### GoldType
```
coin | bar | jewelry | other
```

### GoldKarat
```
k18 | k21 | k22 | k24
```

### CertificateStatus
```
active | matured | redeemedEarly | cancelled
```

### CertificateRateType
```
fixedAnnualPercentage | fixedReturn | variableRate
```

### CertificatePayoutFrequency
```
monthly | quarterly | atMaturity
```

---

## 4. Category Codes

Categories are stored as stable English codes. Display uses localization keys.

### Income Category Codes
```
salary | business | gift | certificateInterest | investmentReturn |
refund | childGift | other
```

### Expense Category Codes
```
groceries | rent | utilities | transportation | healthcare | education |
childExpenses | personalExpenses | spouseExpenses | clothing |
homeMaintenance | entertainment | charity | zakat | debtPayment |
fees | other
```

User-defined custom categories are stored with a `custom_` prefix: `custom_school_supplies`.

---

## 5. Relationships

```
Household 1──* FinancialAccount
Household 1──* LedgerEntry
Household 1──* Operation
Household 1──* Liability
Household 1──* Goal
Household 1──* Budget
Household 1──* ZakatCalculation
Household 1──* SadaqahRecord

Operation 1──* LedgerEntry        (via operationId)
Goal 1──1 FinancialAccount        (the goalReserve account)
Certificate 1──1 FinancialAccount  (the certificate account)
CertificateMetadata 1──1 FinancialAccount (via metadata.bankAccountId)
ChildWithdrawalAudit 1──1 LedgerEntry    (via operationId)
SadaqahRecord 0..1──1 Operation   (via linkedOperationId)
ZakatCalculation 0..1──1 Operation (via paymentOperationId)
```

---

## 6. Versioning

The data model uses a `schemaVersion` integer. Current version: **1**.

- Each migration increments `schemaVersion`.
- Migrations are applied in sequence.
- Backup files embed the schema version.
- Imports reject files with schema version > current app schema version.
- Forward-compatible reads: unknown enum values are stored as-is and not rejected (to support rollback).
