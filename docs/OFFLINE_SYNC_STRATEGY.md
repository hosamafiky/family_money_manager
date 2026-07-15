# Offline Sync Strategy

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## 1. Core Principle

The local SQLite database (Drift) is the **single source of truth** for all financial data on the device. The app operates identically with or without internet connectivity. Firestore is an optional, additive sync layer — not a dependency.

---

## 2. Architecture Overview

```
User action
    │
    ▼
Application layer (Riverpod Notifier)
    │
    ▼
Domain validation (financial invariants checked)
    │
    ▼
Repository
    │
    ├── Write to local SQLite (atomic transaction)
    │       └── Mark sync_status = 'pending'
    │
    └── Add to sync_queue table
    
   ← UI updated immediately from local data

Background:
    SyncService (periodic + connectivity-triggered)
        │
        ├── Read pending items from sync_queue
        │
        ├── For each item:
        │       ├── Mark status = 'uploading'
        │       ├── Write to Firestore (with idempotency check)
        │       ├── On success: mark status = 'synced', update sync_status on entity
        │       └── On failure: increment retry_count, set status = 'failed'
        │
        └── Detect and surface conflicts
```

---

## 3. Sync Queue Design

The `sync_queue` table tracks every entity change that needs to be uploaded to Firestore.

### Queue entry lifecycle

```
pending → uploading → synced
              └──────→ failed (→ retry → pending)
```

### Conflict state

```
synced + server-side rejection → conflict (surfaced to user)
```

### What goes into the queue

| Entity | Change type | Notes |
|---|---|---|
| LedgerEntry | create | Append-only; never update/delete |
| Operation | create | Core creation only |
| Operation | update | Only for reversal flag updates |
| FinancialAccount | create | New account |
| FinancialAccount | update | Metadata changes only |
| Liability | create, update | Outstanding amount changes |
| Goal | create, update | Status changes |
| Budget | create, update | |
| ChildWithdrawalAudit | create | Append-only |
| ZakatCalculation | create | Effectively immutable |
| SadaqahRecord | create, update | |
| RecurringRule | create, update | |
| Household | update | Name, member names |

### What does NOT go into the queue

- `app_settings` — device-local preferences, not synced
- `sync_queue` itself — internal state
- Computed balance snapshots — derived on read

---

## 4. Sync Service

```dart
class SyncService {
  // Triggers
  void onConnectivityRestored();
  void onAppForeground();
  Future<void> runManualSync();
  
  // Internal
  Future<void> _processPendingQueue();
  Future<void> _uploadItem(SyncQueueEntry entry);
  Future<SyncResult> _writeToFirestore(SyncQueueEntry entry);
  
  // Conflict handling
  void _handleConflict(SyncQueueEntry entry, FirestoreConflict conflict);
  
  // Status
  Stream<SyncState> get syncStateStream;
}

enum SyncState {
  idle,
  syncing,
  allSynced,
  pendingItems,
  conflict,
  error,
}
```

### Trigger conditions

1. App comes to foreground (connectivity check first)
2. Connectivity restored (NetworkInfo callback)
3. User manually triggers sync
4. Periodic background sync (every 15 minutes when in foreground)
5. Immediately after each local write (optimistic push for reliability)

### Batch processing

Items are processed in batches of 25 (configurable). Within a batch, items are processed in creation order (FIFO). A failed item does not block subsequent items.

---

## 5. Idempotency Enforcement

Every entity has a stable client-generated UUID. On upload:

1. Client sends the entity with its UUID as the Firestore document ID.
2. Firestore transaction checks: `if (document exists AND content matches) → no-op (success)`
3. Firestore transaction checks: `if (document exists AND content differs) → conflict`
4. Firestore transaction: `if (document does not exist) → create`

For ledger entries specifically, the Firestore rule uses:
```javascript
!exists(/databases/.../ledgerEntries/$(entryId))
```

This means the second attempt to write the same entry ID returns a "permission denied" from Firestore, which the sync service treats as "already synced" (idempotent success) if the local record's data matches.

### Sync service idempotency logic

```dart
Future<SyncResult> _uploadItem(SyncQueueEntry item) async {
  try {
    final docRef = _firestoreRef(item);
    
    // For append-only entities (ledger entries, audits)
    if (item.entityType == 'LedgerEntry' || item.entityType == 'ChildWithdrawalAudit') {
      await docRef.set(item.payloadAsMap());
      // If permission denied because it already exists, treat as success
      return SyncResult.success();
    }
    
    // For other entities: use set with merge for update, or create for new
    if (item.changeType == SyncChangeType.create) {
      await docRef.set(item.payloadAsMap());
    } else {
      await docRef.update(item.updatedFieldsAsMap());
    }
    return SyncResult.success();
    
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      // Check if the document already exists with our content
      final existing = await docRef.get();
      if (existing.exists && _contentMatches(existing, item)) {
        return SyncResult.success(); // Already synced
      }
      return SyncResult.conflict(e.message);
    }
    return SyncResult.failure(e.message);
  }
}
```

---

## 6. Conflict Resolution

### What creates a conflict

In v1, the primary user is the only writer to their household data. Multi-device conflicts can occur when:

- The same user uses two devices simultaneously (phone + tablet).
- Device A creates a transfer while offline; Device B also creates a transfer from the same account offline; Device A then syncs; Device B then syncs. The second transfer may cause a negative balance violation.

### Conflict detection

When uploading a financial operation to Firestore, a Firestore transaction reads the current state to check:
1. Does the source account have sufficient balance (accounting for all already-synced operations)?
2. Does the operation already exist?

If the balance check fails (because another device already drained the account), the operation is marked as `conflict` in the sync queue.

### Conflict resolution (v1)

**Policy: Explicit, user-visible conflict resolution. No silent last-write-wins.**

When a conflict is detected:
1. The item is marked `conflict` in the sync queue.
2. A conflict notification is shown to the user (banner + notification center).
3. The user is presented with options:
   - View the conflicting operation
   - Override (if balance permits): adds a reversal of the cloud state and re-applies local state
   - Discard local: removes the local operation and accepts the cloud state
   - Keep both as pending: leaves the conflict for later review

This is conservative but correct. Financial data integrity is more important than automatic resolution.

### Conflict types (priority order)

| Conflict | Auto-resolvable | User action |
|---|---|---|
| Duplicate operation ID (already synced) | Yes — treat as synced | None |
| Amount mismatch for same ID | No | User reviews |
| Balance insufficient at sync time | No | User reviews |
| Schema version mismatch | No | App update required |
| Account deleted on server | No | User reviews |

---

## 7. Local-Only Mode

Users can opt into local-only mode:
- No Firebase account required.
- No cloud sync.
- Sync queue remains empty.
- Backup/restore is the only data safety mechanism.
- Mode selection: onboarding screen → "Use without cloud account."
- Users can switch from local-only to cloud-synced at any time (full initial sync triggered).

---

## 8. Multi-Device Behavior

In v1, multi-device support is best-effort:

- Device A operations sync up to Firestore.
- Device B reads from Firestore when online.
- Device B applies downloaded operations to local database (as `synced` entries, not re-processed through invariant checks — the server already validated them).
- Conflict detection occurs at sync time (see above).

Download sync (Firestore → local):
- Firestore real-time listener on the household's sub-collections.
- New documents are applied to local database in the order of `recordedAt`.
- Already-existing local records are not overwritten (idempotent by document ID).

---

## 9. Sign-Out Isolation

When a user signs out:
1. All pending sync items are flushed (attempted to sync before sign-out, if connected).
2. The local SQLite database is **cleared** (all tables truncated, or database file deleted).
3. All in-memory state (Riverpod providers) is reset.
4. Secure storage entries for the signed-out user are removed.

A different user signing in receives a fresh, empty local database. Their data is then downloaded from Firestore if they have previously synced.

**The critical rule:** No data from User A must be readable after User B signs in.

---

## 10. Sync Status UI

The dashboard shows a sync status indicator:

| State | Display |
|---|---|
| All synced | Small green dot, no text |
| Syncing | Animated spinner, "جاري المزامنة..." |
| Pending items | Orange dot, count of pending items |
| Conflict | Red dot, "تعارض — يحتاج مراجعة" |
| Error | Red dot, "خطأ في المزامنة" |
| Local-only mode | Cloud-off icon, "وضع محلي" |
| Offline | Grey dot, "غير متصل" |

Tapping the indicator opens the sync detail screen showing:
- Last successful sync time
- Number of pending items
- Any conflicts with details
- Manual sync button

---

## 11. Retry Policy

| Retry # | Delay |
|---|---|
| 1 | 30 seconds |
| 2 | 2 minutes |
| 3 | 10 minutes |
| 4 | 30 minutes |
| 5+ | 1 hour (maximum) |

After 10 consecutive failures, the item is marked `failed` and a notification is shown to the user.

---

## 12. Initial Sync (First Cloud Login)

When a user first logs in with a Firebase account (after using local-only mode, or on a new device):

**Upload scenario (local data → cloud, new account):**
1. All local entities are added to the sync queue in dependency order.
2. Household is uploaded first.
3. Accounts are uploaded next.
4. Operations and ledger entries are uploaded in creation order.
5. Other entities follow.

**Download scenario (existing cloud data → new device):**
1. App authenticates with Firebase.
2. App reads the household document for the authenticated UID.
3. All sub-collections are downloaded in batches.
4. Downloaded documents are inserted into local SQLite with `sync_status = 'synced'`.
5. Application layer rebuilds all derived views (balances, budgets, etc.) from the downloaded ledger.

---

## 13. Data Integrity on Sync

Downloaded ledger entries are NOT re-validated against financial invariants during the download-sync process. The assumption is:

- The server's Firestore rules are designed to enforce validation at write time (planned — rules not yet deployed or tested).
- The client that originally uploaded the data is designed to have validated it against local invariants before upload.

However, after a full download sync, the application is designed to run a consistency check:
1. Verifies all `operationId` references are complete (no orphaned half-transfers).
2. Verifies all `accountId` references exist.
3. Reports any inconsistencies in the sync log (not shown to user unless they open the sync diagnostics screen).

This consistency check is a planned behavior, not yet implemented.

---

## 14. Idempotency: Precise Specification

### 14.1 Idempotency key scope

Each financial operation produces one or more ledger entries. The idempotency key operates at **two levels**:

- **Operation level:** The `operationId` (UUID) uniquely identifies the complete logical operation (e.g., a transfer). A UNIQUE constraint on `operationId` in the `operations` table prevents the same logical operation from being stored twice.
- **Entry level:** Each ledger entry has its own `id` (UUID) and shares the `operationId`. A UNIQUE constraint on `(operationId, accountId, direction, entry_type)` in the `ledger_entries` table prevents the same entry from being inserted twice even if the entry-level ID differs between retries.

**Planned constraint:** The combination `(operationId, accountId, direction, entry_type)` must be UNIQUE in `ledger_entries`. This prevents partial-duplicate states where only one leg of a transfer is re-inserted.

### 14.2 Firestore document identifiers

In Firestore:
- `operations/{operationId}`: the operation document ID equals the operationId.
- `ledgerEntries/{entryId}`: each ledger entry document ID equals the entry's `id` (not the operationId).

The idempotency check for ledger entries in Firestore uses the **document existence check**:
```javascript
!exists(/databases/.../ledgerEntries/$(entryId))
```

If the same entry is uploaded again with the same `entryId`, the Firestore rule rejects it as already existing. The sync service treats this rejection as a success (already synced).

### 14.3 Atomic local write boundary

A complete financial operation is written to local SQLite inside a single database transaction. This transaction includes:
- All ledger entries for the operation
- The operation record itself
- Any associated audit record (e.g., ChildWithdrawalAudit)
- The sync queue entries for each written record

If any part of this transaction fails, the entire transaction rolls back. No partial state is persisted.

### 14.4 Cloud write boundary

In Firestore, each operation's upload consists of multiple document writes (operation + ledger entries). These are uploaded as a **Firestore batch write** (not a transaction) for efficiency, with the following ordering requirement:

- Ledger entry documents are written first, then the operation document.
- Rationale: if the batch is interrupted after entries but before the operation, the sync service will re-upload the operation document on retry (idempotent). If the operation document is written first and entries fail, the operation appears complete but is missing entries — a more dangerous inconsistency.

For operations requiring balance checks (e.g., transfers that must verify sufficient funds), a **Firestore transaction** (not batch) is used so the balance check and the write are atomic.

### 14.5 Preventing partially synchronized operation legs

A transfer has two ledger entries. If network failure occurs after uploading the first entry but before the second, the Firestore database would contain an orphaned debit without a credit.

**Mitigation (planned):** Transfer entries are uploaded as a Firestore batch write. Firestore batch writes are atomic — either all succeed or all fail. A partial transfer cannot be created via a batch write.

**Detection:** The consistency check (Section 13) verifies that every `operationId` appearing in ledger entries also appears in the `operations` collection, and that transfer operations have exactly two ledger entries.

### 14.6 Retry behavior

When a sync queue item fails:
1. The `retry_count` is incremented.
2. The next retry is scheduled after the backoff delay (Section 11).
3. On retry, the item is re-submitted with the same `entryId` and `operationId`.
4. If the Firestore rule rejects it as already existing, the sync service checks local state: if the local record matches what was uploaded, it marks the item as `synced`. If the content differs, it marks the item as `conflict`.

### 14.7 Duplicate execution from multiple devices

If Device A and Device B both create a transfer from the same account while offline:
- Both create their own `operationId` (different UUIDs).
- Both upload on sync.
- Both may succeed if the account has sufficient balance for each individually.
- The second sync may fail the balance check if the first sync already drained the account.
- Conflict detection: the second device's sync service receives a balance-insufficient error from the Firestore transaction. It marks the operation as `conflict` and surfaces it to the user.

If both devices somehow use the **same operationId** (impossible with UUID v4, but worth specifying): the second write is rejected as already existing. The sync service checks content equality. If equal: success. If different: conflict.

### 14.8 Reversal idempotency

A reversal is itself an operation with its own `operationId`. It follows the same idempotency rules as any other operation. The original operation's `is_reversed = true` flag update is a separate document write. This flag update is idempotent (setting true twice has no additional effect).

### 14.9 Deterministic conflict resolution

When a conflict is detected, the resolution is **explicit and user-driven** (not automatic):

1. The conflicting item is marked `conflict` in the sync queue.
2. The conflict notification is surfaced to the user.
3. The user chooses one of:
   - **Accept server state:** The local operation is reversed. The server state is downloaded and applied.
   - **Override with local:** A new operation is submitted that undoes the server state and applies the local state (requires balance check).
   - **Keep conflict pending:** The item remains in the conflict queue for later review.

**There is no silent last-write-wins resolution for any financial operation.**

### 14.10 Backdated operations and sync ordering

A backdated operation has `effectiveDate` in the past but `recordedAt` equal to the current time.

Backdated operations are uploaded in `recordedAt` order (FIFO in the sync queue). They are applied to the local database on download in `recordedAt` order as well.

**Impact on historical balance reports:** A backdated entry changes the historical balance for all dates from its `effectiveDate` forward. Reports are recomputed from the ledger on every query and automatically reflect backdated entries once they are downloaded.

**Impact on sync ordering:** Two devices may upload entries with the same `effectiveDate` but different `recordedAt`. Both are stored in the ledger. Historical balance at the `effectiveDate` reflects both. No ordering ambiguity exists because both entries are preserved.

### 14.11 Effective timestamp vs. creation timestamp

| Field | Meaning | Mutable? |
|---|---|---|
| `effectiveDate` | User-chosen date of the financial event (YYYY-MM-DD) | No (immutable after creation) |
| `recordedAt` | System timestamp when the entry was written (UTC instant) | No (immutable after creation) |
| `syncedAt` | Timestamp when the entry was confirmed synced to Firestore | Updated by sync service |

Historical balance queries use `effectiveDate`. Sync ordering uses `recordedAt`. The sync status uses `syncedAt`.

### 14.12 Sign-out data isolation

On sign-out, the local database is fully cleared (all tables, in dependency order: sync_queue → ledger_entries → operations → child_withdrawal_audits → financial_accounts → household). The clearing happens after a final sync attempt (if connected).

**Requirement:** No data from the signed-out user must be accessible after sign-in by a different user. This is achieved by clearing the database, not by namespace filtering.

The new user's sign-in triggers a fresh download from Firestore into the empty local database.

### 14.13 Backup import interaction with sync

When a backup is imported with Replace mode:
1. All sync queue entries are discarded (they would reference old entity IDs).
2. The local database is replaced with the backup content.
3. All imported entities are marked `sync_status = 'pending'`.
4. The sync service uploads all pending items to Firestore after import.
5. Items that already exist in Firestore (same ID, same content) are treated as already synced.
6. Items that conflict with existing Firestore content are marked `conflict`.

When a backup is imported with Merge mode (add-only, no replace):
1. Only entities with IDs not already in the local database are inserted.
2. Entities already present are skipped (idempotent).
3. No sync queue entries are created for already-synced items.
