# Firestore Security Rules Plan

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## 1. Rule Philosophy

- **Deny by default.** No document is readable or writable unless a rule explicitly permits it.
- **Owner-only access.** Users can only read and write their own household's data.
- **Append-only for financial records.** Ledger entries and child withdrawal audits can be created but never updated or deleted.
- **Schema validation.** Rules validate the structure of incoming documents to prevent malformed writes.
- **No computed values stored.** Balances are never stored in Firestore, so there is no risk of a rule failure allowing a fake balance override.
- **No client-side household ID spoofing.** The householdId accessible to each user is derived from the authenticated UID, not from client-supplied data in request params.

---

## 2. Authentication Requirements

All reads and writes require `request.auth != null`.

Unauthenticated requests are denied for all documents.

---

## 3. Household Membership Model (v1)

In v1, each household has exactly one owner (the primary user's Firebase UID). The household document's `ownerUserId` field is compared against `request.auth.uid`.

```javascript
function isHouseholdOwner(householdId) {
  let household = get(/databases/$(database)/documents/households/$(householdId));
  return request.auth != null
      && household != null
      && household.data.ownerUserId == request.auth.uid;
}
```

This function is used as the gating check on all sub-collection access.

---

## 4. Rules File

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ─── Helper functions ────────────────────────────────────────────────

    function isAuthenticated() {
      return request.auth != null;
    }

    function isHouseholdOwner(householdId) {
      let hh = get(/databases/$(database)/documents/households/$(householdId));
      return isAuthenticated()
          && hh != null
          && hh.data.ownerUserId == request.auth.uid;
    }

    function isValidString(val) {
      return val is string && val.size() > 0;
    }

    function isValidTimestamp(val) {
      return val is timestamp;
    }

    function isPositiveInt(val) {
      return val is int && val > 0;
    }

    function isNonNegativeInt(val) {
      return val is int && val >= 0;
    }

    function isValidDirection(val) {
      return val == 'credit' || val == 'debit';
    }

    function incomingData() {
      return request.resource.data;
    }

    // ─── Households ──────────────────────────────────────────────────────

    match /households/{householdId} {
      // A user can read their own household
      allow read: if isAuthenticated()
                  && resource != null
                  && resource.data.ownerUserId == request.auth.uid;

      // A user can create a household where they are the owner
      allow create: if isAuthenticated()
                    && incomingData().ownerUserId == request.auth.uid
                    && isValidString(incomingData().name)
                    && isValidString(incomingData().currencyCode)
                    && incomingData().schemaVersion is int;

      // A user can update their own household's metadata fields
      // ownerUserId and id are immutable after creation
      allow update: if isAuthenticated()
                    && resource.data.ownerUserId == request.auth.uid
                    && incomingData().ownerUserId == resource.data.ownerUserId
                    && incomingData().id == resource.data.id;

      // No hard deletes
      allow delete: if false;

      // ─── Financial Accounts ──────────────────────────────────────────

      match /accounts/{accountId} {
        allow read: if isHouseholdOwner(householdId);

        allow create: if isHouseholdOwner(householdId)
                      && isValidString(incomingData().name)
                      && isValidString(incomingData().type)
                      && isValidString(incomingData().ownerType)
                      && isValidString(incomingData().currencyCode)
                      && incomingData().householdId == householdId
                      && incomingData().id == accountId;

        allow update: if isHouseholdOwner(householdId)
                      // Immutable fields: id, householdId, type, createdBy, createdAt
                      && incomingData().id == resource.data.id
                      && incomingData().householdId == resource.data.householdId
                      && incomingData().type == resource.data.type
                      && incomingData().createdBy == resource.data.createdBy;

        allow delete: if false;
      }

      // ─── Ledger Entries (APPEND-ONLY) ────────────────────────────────

      match /ledgerEntries/{entryId} {
        allow read: if isHouseholdOwner(householdId);

        allow create: if isHouseholdOwner(householdId)
                      && isValidString(incomingData().operationId)
                      && isValidString(incomingData().accountId)
                      && isValidDirection(incomingData().direction)
                      && isPositiveInt(incomingData().amountMinorUnits)
                      && isValidString(incomingData().entryType)
                      && isValidString(incomingData().effectiveDate)
                      && incomingData().householdId == householdId
                      && incomingData().id == entryId
                      // Idempotency: document must not already exist
                      && !exists(/databases/$(database)/documents/households/$(householdId)/ledgerEntries/$(entryId));

        // Ledger entries are IMMUTABLE — no updates or deletes
        allow update: if false;
        allow delete: if false;
      }

      // ─── Operations ──────────────────────────────────────────────────

      match /operations/{operationId} {
        allow read: if isHouseholdOwner(householdId);

        allow create: if isHouseholdOwner(householdId)
                      && isValidString(incomingData().type)
                      && isValidString(incomingData().effectiveDate)
                      && isNonNegativeInt(incomingData().totalAmountMinorUnits)
                      && incomingData().householdId == householdId
                      && incomingData().id == operationId
                      && !exists(/databases/$(database)/documents/households/$(householdId)/operations/$(operationId));

        // Operations can be updated only for reversal tracking
        // Core financial fields are immutable after creation
        allow update: if isHouseholdOwner(householdId)
                      && incomingData().id == resource.data.id
                      && incomingData().householdId == resource.data.householdId
                      && incomingData().type == resource.data.type
                      && incomingData().totalAmountMinorUnits == resource.data.totalAmountMinorUnits
                      && incomingData().effectiveDate == resource.data.effectiveDate
                      && incomingData().createdBy == resource.data.createdBy;

        allow delete: if false;
      }

      // ─── Child Withdrawal Audits (APPEND-ONLY) ───────────────────────

      match /childWithdrawalAudits/{auditId} {
        allow read: if isHouseholdOwner(householdId);

        allow create: if isHouseholdOwner(householdId)
                      && isValidString(incomingData().operationId)
                      && isValidString(incomingData().reason)
                      && incomingData().reason.size() > 0
                      && incomingData().warningShown == true
                      && isPositiveInt(incomingData().amountMinorUnits)
                      && incomingData().householdId == householdId;

        // Audit records are IMMUTABLE — no updates or deletes
        allow update: if false;
        allow delete: if false;
      }

      // ─── Liabilities ─────────────────────────────────────────────────

      match /liabilities/{liabilityId} {
        allow read: if isHouseholdOwner(householdId);

        allow create: if isHouseholdOwner(householdId)
                      && isValidString(incomingData().name)
                      && isValidString(incomingData().type)
                      && isPositiveInt(incomingData().originalAmountMinorUnits)
                      && isNonNegativeInt(incomingData().outstandingAmountMinorUnits)
                      && incomingData().householdId == householdId;

        allow update: if isHouseholdOwner(householdId)
                      && incomingData().id == resource.data.id
                      && incomingData().householdId == resource.data.householdId
                      // originalAmountMinorUnits is immutable
                      && incomingData().originalAmountMinorUnits == resource.data.originalAmountMinorUnits;

        allow delete: if false;
      }

      // ─── Goals ───────────────────────────────────────────────────────

      match /goals/{goalId} {
        allow read: if isHouseholdOwner(householdId);
        allow create, update: if isHouseholdOwner(householdId)
                              && isValidString(incomingData().name)
                              && isPositiveInt(incomingData().targetAmountMinorUnits)
                              && incomingData().householdId == householdId;
        allow delete: if false;
      }

      // ─── Budgets ─────────────────────────────────────────────────────

      match /budgets/{budgetId} {
        allow read: if isHouseholdOwner(householdId);
        allow create, update: if isHouseholdOwner(householdId)
                              && isValidString(incomingData().name)
                              && isPositiveInt(incomingData().targetAmountMinorUnits)
                              && incomingData().householdId == householdId;
        allow delete: if false;
      }

      // ─── Recurring Rules ─────────────────────────────────────────────

      match /recurringRules/{ruleId} {
        allow read: if isHouseholdOwner(householdId);
        allow create, update: if isHouseholdOwner(householdId)
                              && incomingData().householdId == householdId;
        allow delete: if false;
      }

      // ─── Zakat Calculations ──────────────────────────────────────────

      match /zakatCalculations/{calcId} {
        allow read: if isHouseholdOwner(householdId);
        allow create: if isHouseholdOwner(householdId)
                      && isValidString(incomingData().calculationDate)
                      && isNonNegativeInt(incomingData().zakatDueMinorUnits)
                      && incomingData().householdId == householdId;
        // Zakat calculations are effectively immutable (create a new one to correct)
        allow update: if false;
        allow delete: if false;
      }

      // ─── Sadaqah Records ─────────────────────────────────────────────

      match /sadaqahRecords/{recordId} {
        allow read: if isHouseholdOwner(householdId);
        allow create: if isHouseholdOwner(householdId)
                      && isPositiveInt(incomingData().amountMinorUnits)
                      && isValidString(incomingData().date)
                      && incomingData().householdId == householdId;
        allow update: if isHouseholdOwner(householdId)
                      && incomingData().id == resource.data.id
                      && incomingData().amountMinorUnits == resource.data.amountMinorUnits;
        allow delete: if false;
      }

    } // end /households/{householdId}

    // ─── Deny all other paths ─────────────────────────────────────────────
    match /{document=**} {
      allow read, write: if false;
    }

  }
}
```

---

## 5. Rules Testing Plan

All rules must be tested using **Firebase Emulator Suite** with the `@firebase/rules-unit-testing` package.

### Test cases required

#### Household access

- ✅ Owner can read own household
- ✅ Owner can create household
- ✅ Owner can update household metadata
- ❌ Non-owner cannot read household
- ❌ Unauthenticated user cannot read household
- ❌ Update that changes ownerUserId is rejected
- ❌ Hard delete is rejected

#### Ledger entries

- ✅ Owner can create ledger entry with valid fields
- ❌ Owner cannot update any ledger entry
- ❌ Owner cannot delete any ledger entry
- ❌ Non-owner cannot create ledger entry
- ❌ Entry with amountMinorUnits = 0 is rejected
- ❌ Entry with amountMinorUnits negative is rejected
- ❌ Entry with invalid direction is rejected
- ❌ Duplicate entryId is rejected (document already exists check)
- ❌ Entry with wrong householdId is rejected

#### Operations

- ✅ Owner can create operation
- ✅ Owner can update reversal tracking fields
- ❌ Owner cannot change type, amount, or effectiveDate in update
- ❌ Duplicate operationId is rejected
- ❌ Non-owner cannot create or read

#### Child withdrawal audits

- ✅ Owner can create audit with non-empty reason
- ✅ Audit with warningShown = true is accepted
- ❌ Audit with warningShown = false is rejected
- ❌ Audit with empty reason is rejected
- ❌ Any update to audit is rejected
- ❌ Any delete of audit is rejected

#### Liabilities

- ✅ Owner can create liability
- ✅ Owner can update outstanding amount
- ❌ Owner cannot change originalAmountMinorUnits in update
- ❌ Non-owner cannot read or write

#### Cross-user tests

- ❌ User A cannot read User B's household
- ❌ User A cannot create documents in User B's household sub-collections
- ❌ User A cannot read User B's ledger entries
- ❌ Forged householdId in document body (body.householdId ≠ path householdId) is rejected

---

## 6. Rules File Location

```
firestore_rules/
  firestore.rules        // production rules
  firestore.test.js      // emulator test suite (Node.js + @firebase/rules-unit-testing)
  firestore.indexes.json // compound index definitions
```

---

## 7. Deployment

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

Rules and indexes are deployed separately from the app. Rules changes should be tested with the emulator before deployment.

---

## 8. Known Limitations

- **Firestore does not enforce referential integrity.** The accountId referenced in a ledger entry is not validated against the accounts collection by Firestore rules. This is validated by the application layer and local database constraints.
- **`isHouseholdOwner` performs a document read.** This counts toward Firestore read quota. Each security rule evaluation on a sub-collection document costs one additional read. This is acceptable at household scale.
- **No field-level encryption in Firestore.** Data is encrypted in transit (TLS) and at rest (Firestore server-side encryption), but individual fields are not client-side encrypted before upload. This is acceptable for v1; field-level encryption is a v2 option.
