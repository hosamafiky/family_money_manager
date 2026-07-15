# Firestore Schema

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## 1. Design Principles

- Firestore is the **optional cloud sync layer**, not the primary database.
- The local SQLite database is always the source of truth for the mobile app.
- Firestore documents mirror the local database schema, with minor adaptations for Firestore's document model.
- All documents are nested under `/households/{householdId}/` for security rule simplicity.
- Firestore timestamps use `Timestamp` type (not string).
- Money amounts are stored as integers (Firestore supports 64-bit integers).
- Enum values are stored as strings (stable English codes).
- No computed or derived values (like balances) are stored in Firestore — those are always computed from ledger entries.

---

## 2. Collection Hierarchy

```
/households/{householdId}
  → Household document

/households/{householdId}/accounts/{accountId}
  → FinancialAccount documents

/households/{householdId}/ledgerEntries/{entryId}
  → LedgerEntry documents (immutable, append-only)

/households/{householdId}/operations/{operationId}
  → Operation documents

/households/{householdId}/childWithdrawalAudits/{auditId}
  → ChildWithdrawalAudit documents (immutable)

/households/{householdId}/liabilities/{liabilityId}
  → Liability documents

/households/{householdId}/goals/{goalId}
  → Goal documents

/households/{householdId}/budgets/{budgetId}
  → Budget documents

/households/{householdId}/recurringRules/{ruleId}
  → RecurringRule documents

/households/{householdId}/zakatCalculations/{calcId}
  → ZakatCalculation documents

/households/{householdId}/sadaqahRecords/{recordId}
  → SadaqahRecord documents
```

---

## 3. Document Schemas

### 3.1 /households/{householdId}

```javascript
{
  id: string,                    // UUID
  ownerUserId: string,           // Firebase UID
  name: string,
  currencyCode: string,          // "EGP"
  primaryLanguage: string,       // "ar"
  memberUserName: string,
  memberSpouseName: string | null,
  memberChildName: string | null,
  createdAt: Timestamp,
  updatedAt: Timestamp,
  schemaVersion: number          // integer, current = 1
}
```

---

### 3.2 /households/{householdId}/accounts/{accountId}

```javascript
{
  id: string,
  householdId: string,
  name: string,
  type: string,                  // FinancialAccountType enum code
  ownerType: string,             // AccountOwnerType enum code
  fundPurpose: string,           // FundPurpose enum code
  currencyCode: string,
  isSpendable: boolean,
  isProtected: boolean,
  includeInNetWorth: boolean,
  includeInZakat: boolean,
  isArchived: boolean,
  archivedAt: Timestamp | null,
  notes: string | null,
  displayOrder: number,
  metadata: object | null,       // type-specific extra fields
  createdAt: Timestamp,
  updatedAt: Timestamp,
  createdBy: string              // Firebase UID
}
```

**metadata examples:**

Bank account:

```javascript
metadata: {
  bankName: "Banque Misr",
  lastFourDigits: "1234",
  hasInterest: false,
  interestRate: null
}
```

Certificate:

```javascript
metadata: {
  bankAccountId: "uuid-of-source-bank",
  principalMinorUnits: 5000000,  // 50,000.00 EGP
  startDate: "2026-01-01",
  maturityDate: "2027-01-01",
  rateType: "fixedAnnualPercentage",
  ratePercent: 2200,             // basis points, 22.00%
  payoutFrequency: "monthly",
  payoutAccountId: "uuid-of-destination",
  status: "active"               // active | matured | redeemedEarly | cancelled
}
```

Gold holding:

```javascript
metadata: {
  goldType: "jewelry",           // coin | bar | jewelry | other
  karat: "k21",                  // k18 | k21 | k22 | k24
  weightMilligrams: 10000,       // 10.000 grams
  purchasePriceMinorUnits: 3200000,  // 32,000.00 EGP
  currentPricePerGramMinorUnits: 350000  // 3,500.00 EGP/g
}
```

---

### 3.3 /households/{householdId}/ledgerEntries/{entryId}

Immutable. Created once, never updated or deleted.

```javascript
{
  id: string,                    // UUID (same as entryId in document path)
  operationId: string,           // groups entries in same operation
  householdId: string,
  accountId: string,
  direction: string,             // "credit" | "debit"
  amountMinorUnits: number,      // always positive integer
  currencyCode: string,
  entryType: string,             // LedgerEntryType enum code
  effectiveDate: string,         // "YYYY-MM-DD"
  recordedAt: Timestamp,
  notes: string | null,
  createdBy: string,             // Firebase UID
  isReversal: boolean,
  reversalOfEntryId: string | null,
  metadata: object | null        // entry-specific extra data
}
```

---

### 3.4 /households/{householdId}/operations/{operationId}

```javascript
{
  id: string,
  householdId: string,
  type: string,                  // OperationType enum code
  effectiveDate: string,         // "YYYY-MM-DD"
  recordedAt: Timestamp,
  description: string | null,
  categoryCode: string | null,
  scope: string | null,          // ExpenseScope enum code
  spenderRole: string | null,    // HouseholdMemberRole enum code
  beneficiaryRole: string | null,
  sourceAccountId: string | null,
  destinationAccountId: string | null,
  totalAmountMinorUnits: number,
  currencyCode: string,
  isRecurring: boolean,
  recurringRuleId: string | null,
  tags: string[],                // array of string tags
  receiptStoragePath: string | null,  // Firebase Storage path
  isReversed: boolean,
  reversedBy: string | null,     // operationId of reversal
  createdBy: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

### 3.5 /households/{householdId}/childWithdrawalAudits/{auditId}

Immutable. Created once, never updated or deleted.

```javascript
{
  id: string,
  operationId: string,
  householdId: string,
  accountId: string,
  amountMinorUnits: number,
  reason: string,                // non-empty, mandatory
  beneficiary: string,           // HouseholdMemberRole enum code
  confirmedAt: Timestamp,
  confirmedBy: string,           // Firebase UID
  warningShown: boolean,         // always true
  biometricConfirmed: boolean,
  createdAt: Timestamp
}
```

---

### 3.6 /households/{householdId}/liabilities/{liabilityId}

```javascript
{
  id: string,
  householdId: string,
  name: string,
  type: string,                  // LiabilityType enum code
  originalAmountMinorUnits: number,
  outstandingAmountMinorUnits: number,
  currencyCode: string,
  dueDate: string | null,        // "YYYY-MM-DD"
  paymentAccountId: string | null,
  interestRateBasisPoints: number | null,
  notes: string | null,
  isSettled: boolean,
  settledAt: Timestamp | null,
  createdAt: Timestamp,
  updatedAt: Timestamp,
  createdBy: string
}
```

---

### 3.7 /households/{householdId}/goals/{goalId}

```javascript
{
  id: string,
  householdId: string,
  name: string,
  description: string | null,
  targetAmountMinorUnits: number,
  currencyCode: string,
  deadline: string | null,       // "YYYY-MM-DD"
  reserveAccountId: string,
  status: string,                // "active" | "completed" | "cancelled"
  completedAt: Timestamp | null,
  cancelledAt: Timestamp | null,
  cancellationDestinationAccountId: string | null,
  reminderEnabled: boolean,
  reminderFrequency: string | null,
  createdAt: Timestamp,
  updatedAt: Timestamp,
  createdBy: string
}
```

---

### 3.8 /households/{householdId}/budgets/{budgetId}

```javascript
{
  id: string,
  householdId: string,
  name: string,
  scope: string,                 // ExpenseScope enum code
  type: string,                  // "overall" | "category" | "account"
  categoryCode: string | null,
  accountId: string | null,
  periodType: string,            // "monthly" | "custom"
  customStartDate: string | null,
  customEndDate: string | null,
  targetAmountMinorUnits: number,
  warningThresholdPercent: number,
  currencyCode: string,
  isActive: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp,
  createdBy: string
}
```

---

### 3.9 /households/{householdId}/zakatCalculations/{calcId}

```javascript
{
  id: string,
  householdId: string,
  calculationDate: string,
  hawlStartDate: string,
  hawlEndDate: string,
  nisabBasis: string,            // "gold" | "silver"
  nisabAmountMinorUnits: number,
  includedAccounts: Array<{
    accountId: string,
    includedAmountMinorUnits: number,
    notes: string | null
  }>,
  excludedAccounts: string[],    // array of account IDs
  deductedLiabilities: Array<{
    liabilityId: string,
    deductedAmountMinorUnits: number
  }>,
  totalZakatableAmountMinorUnits: number,
  zakatDueMinorUnits: number,
  isPaidViaApp: boolean,
  paymentOperationId: string | null,
  notes: string | null,
  createdAt: Timestamp,
  createdBy: string
}
```

---

### 3.10 /households/{householdId}/sadaqahRecords/{recordId}

```javascript
{
  id: string,
  householdId: string,
  amountMinorUnits: number,
  currencyCode: string,
  date: string,                  // "YYYY-MM-DD"
  notes: string | null,
  linkedOperationId: string | null,
  isLinked: boolean,
  createdAt: Timestamp,
  createdBy: string
}
```

---

## 4. Firestore Indexes

Compound indexes required (in addition to Firestore's automatic single-field indexes):

```javascript
// Collection: ledgerEntries
// Index: (accountId ASC, effectiveDate ASC)
// Used for: historical balance queries

// Collection: operations
// Index: (scope ASC, effectiveDate ASC)
// Used for: spending by scope reports

// Collection: operations
// Index: (categoryCode ASC, effectiveDate ASC)
// Used for: spending by category reports

// Collection: operations
// Index: (type ASC, effectiveDate ASC)
// Used for: operation type filtering

// Collection: operations
// Index: (sourceAccountId ASC, effectiveDate ASC)
// Used for: account-specific transaction list

// Collection: liabilities
// Index: (isSettled ASC, dueDate ASC)
// Used for: upcoming due date alerts
```

These are declared in `firestore.indexes.json`.

---

## 5. Data Volume Estimates

| Collection        | Growth rate       | 5-year estimate        |
| ----------------- | ----------------- | ---------------------- |
| ledgerEntries     | ~5–15 entries/day | ~20,000–27,000 entries |
| operations        | ~3–10 ops/day     | ~5,000–18,000 ops      |
| accounts          | ~10–20 total      | ~10–20 docs            |
| liabilities       | ~0–5 total        | ~0–20 docs             |
| goals             | ~2–5 total        | ~10–20 docs            |
| budgets           | ~3–10 total       | ~10–30 docs            |
| zakatCalculations | ~1/year           | ~5–10 docs             |
| sadaqahRecords    | ~0–10/month       | ~0–600 docs            |

All collections are within Firestore's practical limits.

---

## 6. Firestore Cost Considerations

- Reads: dashboard and reports query ledger entries. Implement client-side caching (Firestore offline persistence) to avoid repeated reads.
- Writes: each financial operation writes 2–4 documents (operation + 1–2 ledger entries + optional audit).
- Estimate: ~15,000–30,000 reads/month, ~5,000–15,000 writes/month for a single active household.
- Free tier (Spark): 50,000 reads/day, 20,000 writes/day — sufficient for a single household.

---

## 7. Firestore Offline Persistence

Firebase SDK's built-in offline persistence is enabled for the read path. However:

- The app does NOT depend on Firestore offline for its primary financial operations.
- All primary operations go through the local SQLite database.
- Firestore offline persistence is a secondary benefit, not a requirement.
- Firestore offline persistence is configured with a reasonable disk cache size (e.g., 10 MB).

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```
