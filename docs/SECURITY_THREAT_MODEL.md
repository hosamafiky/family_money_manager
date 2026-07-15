# Security Threat Model

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## Disclaimer

No application can be guaranteed free of all vulnerabilities. This document identifies the primary threats relevant to a household financial application and describes the architectural mitigations selected. Security is a process, not a single implementation step.

---

## 1. Asset Inventory

| Asset | Sensitivity | Notes |
|---|---|---|
| Account balances and ledger entries | High | Primary financial records |
| Child-fund withdrawal audit records | High | Legal-grade audit trail |
| Authentication credentials (PIN, biometric) | Critical | App lock bypass |
| Firebase auth tokens | Critical | Full account access |
| Backup files (encrypted) | High | Contains all financial history |
| Backup encryption key / password | Critical | Decrypts all history |
| Personal and family member names | Medium | Privacy |
| Receipt images | Medium | May contain personal information |
| AI API keys | High | Financial assistant access |
| Sync queue contents | Medium | Transaction data in transit |

---

## 2. Threat Categories and Mitigations

### T-01 — Unauthorized Physical Access to Unlocked Phone

**Threat:** Someone physically picks up the user's phone while the app is open.

**Mitigations:**
- App lock with PIN and biometric.
- Auto-lock after configurable timeout (default: 2 minutes).
- Lock immediately when app moves to background.
- App-switcher blur overlay prevents seeing financial data in the task switcher.
- Lock screen does not show previous screen content.

**Residual risk:** Low. Attacker must defeat biometric or guess PIN before the auto-lock timeout.

---

### T-02 — Unauthorized Physical Access to Locked Phone

**Threat:** Phone falls into wrong hands. Attacker attempts to read database directly from phone storage.

**Mitigations:**
- Drift SQLite database is stored in the app's private data directory (not accessible without root on Android, protected by iOS sandbox).
- On Android 9+, the database file is encrypted by the OS full-disk encryption.
- Sensitive values (PIN hash, tokens) stored in Android Keystore / iOS Keychain via `flutter_secure_storage`.
- Backup files are AES-256 encrypted before writing to external storage.

**Residual risk:** Low on patched modern OS. Risk increases on rooted devices (considered out of scope for v1; add detection in v2).

---

### T-03 — PIN Brute Force

**Threat:** Attacker attempts all possible PINs.

**Mitigations:**
- Exponential backoff after failed attempts: 3 fails → 30 second lockout, 5 fails → 5 minute lockout, 10 fails → full app wipe option.
- Lockout persists across app restarts (stored in secure storage, not SharedPreferences).
- PIN is never stored raw. Stored as SHA-256(pin + salt) where salt is random and stored in secure storage.

**Alternative considered:** bcrypt for PIN hashing. Accepted as an open decision because bcrypt is not natively available in Flutter without a native plugin. PBKDF2 via `pointycastle` is the v1 choice. See DECISIONS.md.

**Residual risk:** Low. 6-digit PIN has 1,000,000 combinations. With exponential backoff, exhaustive search is impractical.

---

### T-04 — Replay Attack (Duplicate Financial Operations)

**Threat:** A malicious actor or a network retry mechanism submits the same financial operation twice, duplicating a transfer or creating phantom income.

**Mitigations:**
- Every operation has a client-generated UUID (operationId).
- Local database: UNIQUE constraint on operationId → second write is rejected with a duplicate error.
- Cloud Firestore: transaction reads the existing document before writing → rejects if already exists.
- Sync queue: marks operations by ID; never re-queues a synced ID.

**Residual risk (planned):** Low when implemented. Idempotency is designed to be enforced at every layer. Until Phase 2 implements the UNIQUE constraints and Firestore transactions, this mitigation is a design intent only, not an active control.

---

### T-05 — Cross-User Data Access (Cloud)

**Threat:** User A reads or writes User B's financial records in Firestore.

**Mitigations:**
- Firestore security rules: deny-by-default.
- Every document in Firestore is nested under `/households/{householdId}/`.
- Rules verify: `request.auth.uid == resource.data.ownerUserId` for all reads and writes.
- No batch operations permitted that cross household boundaries.
- Server-side: householdId is derived from the authenticated UID, not from client-supplied data.

**Residual risk:** Low. Firestore rules are tested with Firebase Emulator. Rules enforce that only the owning UID can access household data.

---

### T-06 — Malicious Backup Import

**Threat:** Attacker provides a crafted backup file to inject transactions, create phantom balances, or corrupt data.

**Mitigations:**
- Backup import validates schema version: rejects future versions unknown to this app.
- All enum values are validated against known codes.
- All amounts must be positive integers within configured limits.
- All IDs must be valid UUID v4 format.
- All dates must be parseable.
- Import is rejected as a whole if any record fails validation.
- Import requires explicit user confirmation and creates an automatic backup first.
- Cross-user IDs in imported data are rejected (householdId must match current user's household).

**Residual risk:** Medium. Schema validation is comprehensive but not exhaustive. A highly crafted backup from a malicious source could potentially exploit edge cases. Full cryptographic signing of backups is deferred to v2 (see DECISIONS.md).

---

### T-07 — Sensitive Data Exposure in Logs

**Threat:** Financial amounts, account balances, or authentication tokens appear in device logs, which may be accessible to other apps or developers.

**Mitigations:**
- `RedactedLogger` wraps all log output.
- `Money.toString()` returns `[REDACTED_AMOUNT]` in non-debug builds.
- Auth tokens are never logged.
- AI request/response bodies are never logged.
- Production log level: WARNING and above.
- Lint rule (custom) to detect direct `print()` calls → CI failure.

**Residual risk (planned):** Low when implemented. Debug builds will intentionally log more for development purposes. The production log level is intended to be enforced by the build configuration. This is a planned control; no code exists yet.

---

### T-08 — Screenshot and Screen Capture

**Threat:** Malicious app or screenshot during task-switch exposes financial data.

**Mitigations:**
- Android: `FLAG_SECURE` set on the Activity, preventing screenshots and screen recording.
- iOS: `ignoresScreenshots` equivalent via UIScreen protection.
- App-switcher: a blur overlay is placed on top of all content immediately on `AppLifecycleState.inactive`.
- Privacy mode: user can enable a mode that replaces all amounts with `****` in the UI.

**Residual risk:** Low. Users who explicitly grant screen recording permissions to another app cannot be protected by the app itself.

---

### T-09 — AI API Key Exposure

**Threat:** An embedded AI API key in the mobile app is extracted and used by an attacker to make unauthorized AI calls.

**Mitigations:**
- AI API keys are NEVER embedded in the mobile app.
- All AI requests are proxied through a server-side function (Firebase Cloud Function or similar).
- The mobile app sends the user's Firebase auth token; the server validates it and calls the AI API.
- **Planned:** Rate limiting is to be enforced server-side per user (in the AI proxy Cloud Function).
- AI is optional: if the proxy is unavailable, the app degrades gracefully to manual entry.

**Residual risk:** Low. Server-side key storage is standard practice. Server key exposure is a separate server security concern.

---

### T-10 — Protected Fund Bypass

**Threat:** User circumvents the child-fund withdrawal warning and reason requirement via a direct API call, database edit, or code path.

**Mitigations:**
- **Requirement:** The only write path to child-fund accounts must go through `ProtectedFundRepository.withdrawWithAudit(...)`. No other withdrawal code path may exist.
- **Planned:** This method is designed to enforce audit creation inside the same SQLite transaction. Not yet implemented.
- **Requirement:** No `LedgerRepository.rawDebit(...)` method may be exposed to application code.
- **Planned:** Firestore rules are designed to reject writes to childFundWithdrawal ledger entries without a linked audit document.
- **Requirement:** Audit events must be immutable (no update/delete) once created.

**Residual risk (planned):** Low when implemented. The constraint is designed to be enforced at the repository contract level. Until Phase 2 and Phase 3 code is written and tested, this is a design intent only.

---

### T-11 — Unauthorized Destructive Restore

**Threat:** Someone with brief physical access restores a backup that wipes the user's financial history.

**Mitigations:**
- Restore requires: re-authentication (PIN or biometric) before proceeding.
- Restore with replace mode: automatic encrypted backup of current state before any replacement.
- Restore preview: user sees account count, transaction count, and date range before confirming.
- Cannot restore without explicit confirmation dialog.

**Residual risk:** Low. Requires physical access AND successful authentication.

---

### T-12 — Account Enumeration via Error Messages

**Threat:** Error messages reveal whether an email address is registered, enabling user enumeration.

**Mitigations:**
- Login and password reset return generic error messages ("Invalid credentials" rather than "Email not found").
- Error codes are mapped to localized display strings in a central error mapper.
- Raw Firebase error codes are never displayed to the user.

**Residual risk:** Low.

---

### T-13 — Insecure Local Authentication Bypass

**Threat:** Attacker disables biometric check through OS-level manipulation or Flutter plugin vulnerability.

**Mitigations:**
- PIN fallback is always required; biometric alone cannot be the only authentication method.
- App lock state is tracked in secure storage, not in memory only.
- On app restart, if the last lock state was "locked," the app starts in the locked state.
- Biometric result is not trusted for destructive operations (account delete, restore) — PIN required.

**Residual risk:** Medium. Biometric security ultimately depends on the OS and hardware implementation. Root access can defeat OS-level protections.

---

### T-14 — Denial of Service via Corrupt Database

**Threat:** Database becomes corrupt and the app cannot open, locking the user out of their financial data.

**Mitigations:**
- Drift supports WAL (Write-Ahead Logging) mode, which reduces corruption risk on crash.
- Scheduled automatic backups provide a recovery path.
- Migration system includes integrity check on startup.
- If database fails to open, app enters a recovery mode offering backup restore.
- Cloud sync provides an independent recovery path.

**Residual risk:** Medium. On-device data loss is always possible. Cloud sync mitigates but does not eliminate this risk.

---

## 3. Firestore Security Rules Summary

```
// All documents are under /households/{householdId}/

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Households: only the owner can read or write
    match /households/{householdId} {
      allow read, create: if request.auth != null
                         && request.auth.uid == request.resource.data.ownerUserId;
      allow update: if request.auth != null
                   && request.auth.uid == resource.data.ownerUserId
                   && request.auth.uid == request.resource.data.ownerUserId;
      allow delete: if false; // soft-delete only
      
      // Ledger entries: create only, no update or delete
      match /ledgerEntries/{entryId} {
        allow read: if isHouseholdMember(householdId);
        allow create: if isHouseholdMember(householdId)
                     && isValidLedgerEntry(request.resource.data);
        allow update, delete: if false;
      }
      
      // Financial accounts: read + create + update (metadata only, no balance)
      match /accounts/{accountId} {
        allow read, create, update: if isHouseholdMember(householdId)
                                   && isValidAccount(request.resource.data);
        allow delete: if false;
      }
      
      // Child withdrawal audits: create only
      match /childWithdrawalAudits/{auditId} {
        allow read: if isHouseholdMember(householdId);
        allow create: if isHouseholdMember(householdId);
        allow update, delete: if false;
      }
    }
    
    function isHouseholdMember(householdId) {
      return request.auth != null
          && get(/databases/$(database)/documents/households/$(householdId)).data.ownerUserId == request.auth.uid;
    }
    
    function isValidLedgerEntry(data) {
      return data.amountMinorUnits is int
          && data.amountMinorUnits > 0
          && data.direction in ['credit', 'debit']
          && data.entryType is string
          && data.operationId is string;
    }
    
    function isValidAccount(data) {
      return data.type is string
          && data.ownerType is string
          && data.currencyCode is string;
    }
  }
}
```

Full rules are in `firestore_rules/firestore.rules`. This is a summary for threat-model documentation.

---

## 4. Open Security Risks (v1 Deferred)

| Risk | Severity | Mitigation Planned |
|---|---|---|
| No rooted device detection | Medium | v2: detect and warn |
| No backup file cryptographic signing | Medium | v2: HMAC or digital signature |
| No certificate pinning for Firebase | Low–Medium | v2: evaluate necessity |
| No rate limiting on local operations | Low | Unlikely to be exploited offline |
| No anomaly detection (sudden large transfer) | Low | v2: configurable alerts |
| No multi-device session management | Low | v2: device list in Firestore |
