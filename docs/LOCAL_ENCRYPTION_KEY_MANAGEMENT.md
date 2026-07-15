# Local Encryption Key Management — Architecture Plan

**Phase:** Planning only (Phase 1.5)  
**Status:** Proposed architecture. Nothing described here is implemented.  
Full implementation is deferred to the approved key-management phase.  
**Date:** 2026-07-15

---

## Purpose

This document describes the proposed production architecture for managing the
local database encryption key in Family Money Manager. It is a planning document,
not a specification of implemented controls.

---

## Core Distinctions

These five controls are **not interchangeable**. Each serves a different purpose
and operates at a different layer. Confusing them leads to design defects.

| Control | What it protects | Who holds it | When it applies |
|---|---|---|---|
| **Database encryption** | Financial data at rest (SQLite file) | sqlite3mc (C library) | Whenever the file is opened |
| **Secure key storage** | The random database key itself | Android Keystore / iOS Keychain | Key load/save |
| **App lock** | Active session access | App UI layer | After inactivity timeout |
| **Biometric/PIN authentication** | Gating access to the stored key | Device OS | On app unlock |
| **Backup encryption** | Exported backup files | User-chosen recovery passphrase | On export/import |

---

## 1. Random Database Data-Encryption Key (DEK)

The local SQLite database is encrypted using **SQLite3MultipleCiphers** (sqlite3mc).
The database key is a cryptographically random 256-bit value.

- Generated using the platform's cryptographic random source (e.g., `SecureRandom` on Android, `SecRandomCopyBytes` on iOS) via Dart's `dart:typed_data` + `Random.secure()`.
- Never derived from the app PIN, package name, device identifier, or any user-visible value.
- Never stored in shared preferences, application files, or any unprotected location.
- The PIN is not the database key. The PIN gates access to the key.

---

## 2. Android Keystore-Backed Protection

On Android, the DEK is wrapped using a key stored in the **Android Keystore System**.

### Key creation
1. On first launch after installation, a 256-bit AES key (`KEYSTORE_ALIAS_DATABASE_DEK_WRAP`) is generated inside the Android Keystore. The key never leaves the Keystore (hardware-backed on supported devices).
2. A random 256-bit DEK is generated in Dart using `Random.secure()`.
3. The DEK is encrypted (AES-GCM) using the Keystore-backed wrap key.
4. The encrypted DEK blob is stored in `flutter_secure_storage` (which uses the Android Keystore internally).

### Key loading
1. The app retrieves the encrypted DEK blob from secure storage.
2. The Keystore-backed wrap key decrypts the blob.
3. The plaintext DEK is passed to the database `setup` callback and immediately cleared from memory after use.

### Key accessibility policy
- `KeyProperties.PURPOSE_ENCRYPT | PURPOSE_DECRYPT`
- `setUserAuthenticationRequired(true)` — requires biometric or device credential to use the key after the screen lock.
- `setInvalidatedByBiometricEnrollment(true)` — key is invalidated when new biometrics are enrolled.

---

## 3. iOS Keychain-Backed Protection

On iOS, the DEK is stored directly in the **iOS Keychain** using the `kSecAttrAccessible` attribute.

### Key creation
1. On first launch, a random 256-bit DEK is generated using `SecRandomCopyBytes`.
2. The DEK is stored as a Keychain item with:
   - `kSecAttrService`: `com.familymoney.manager.db_dek`
   - `kSecAttrAccessible`: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
   - `kSecAttrAccessControl`: `SecAccessControlCreateWithFlags` with `.biometryCurrentSet` or `.userPresence`
3. The Keychain item is not exported in iCloud Keychain backups.

### Key loading
1. The app performs a Keychain query for the DEK item.
2. iOS presents the biometric / device-credential prompt if required.
3. The DEK is returned to the app and passed to the database `setup` callback.
4. Memory holding the plaintext DEK is zeroed after use.

---

## 4. Biometric and PIN Gating

**Biometric authentication (Face ID / Touch ID / Android BiometricPrompt)** gates access to the database key.

- The app presents a biometric prompt on first database open after launch.
- Successful authentication allows the OS to release the key from the Keystore / Keychain.
- The DEK is passed to the database and the plaintext value is discarded.
- Biometric authentication does not generate or derive the key — it unlocks the OS-level protection over the pre-existing key.

**Why the PIN is not the database key:**

If the PIN were used as the database key (or to derive it via PBKDF2 / Argon2), then:
- Changing the PIN would require re-encrypting the entire database (expensive, failure-prone).
- A short PIN (4–6 digits) provides very low entropy (~13–20 bits) compared to a random 256-bit key.
- A PIN change could leave the database locked if the operation is interrupted mid-flight.

Instead, the PIN unlocks an app-lock screen that gates access to the UI. The database key is protected by Keystore / Keychain hardware authentication, not by the PIN value.

---

## 5. App Lock

App lock is a **UI-layer control** separate from database encryption.

- After a configurable inactivity timeout, the app overlays a lock screen.
- The lock screen accepts biometric or PIN input.
- On success, the app resumes; the database is already open in the same process.
- App lock does not close and reopen the database — it hides and shows the UI.
- App lock does not protect against an OS-level memory dump (the database is open in process). Database encryption protects the at-rest file.

---

## 6. Key Creation Flow (Planned)

```
First launch
│
├─ Generate random DEK (256-bit, Random.secure())
│
├─ Android: generate Keystore wrap key → encrypt DEK → store blob in SecureStorage
│   iOS: store DEK directly in Keychain (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
│
└─ Open database with DEK → clear DEK from Dart memory
```

---

## 7. Key Loading Flow (Planned)

```
App launch / database open
│
├─ Retrieve encrypted DEK blob from SecureStorage / Keychain
│
├─ OS presents biometric/credential prompt (if required by Keystore/Keychain policy)
│
├─ OS releases DEK (Android: wrap key decrypts blob; iOS: Keychain returns item)
│
├─ Pass DEK to NativeDatabase setup callback
│   └─ PRAGMA key = '<DEK>'
│   └─ SELECT count(*) FROM sqlite_master  ← verifies key correctness
│
└─ Clear DEK from Dart memory
```

---

## 8. Key Rotation

Key rotation replaces the DEK without changing the database content.

Planned procedure (to be implemented in the approved key-management phase):
1. Open the current database with the current DEK.
2. Generate a new random DEK.
3. Execute `PRAGMA rekey = '<new_DEK>'` — sqlite3mc re-encrypts the database in place.
4. Store the new DEK in secure storage (Keystore / Keychain).
5. Delete the old DEK reference.
6. Verify the database opens with the new DEK.

If step 3 or 4 fails, the old DEK must still be valid. A failure at step 5 results in both keys being present — the old one is then removed. A failure mid-rekey leaves the database corrupt; the user must restore from backup.

---

## 9. Sign-Out and Profile Isolation

- On sign-out, the database is **closed** but not deleted by default.
- The DEK remains in secure storage so the user can sign back in.
- If the user explicitly requests "delete local data," the database file and the DEK are both deleted.
- Each user profile has its own DEK and its own database file. Keys are never shared between profiles.

---

## 10. App Reinstall Behavior

| Platform | DEK after reinstall |
|---|---|
| Android | **Deleted** — the Keystore key and SecureStorage entries are cleared on uninstall. The database file is also deleted with app data. |
| iOS | **Retained by default** — Keychain items persist across reinstalls on iOS unless explicitly deleted with `kSecAttrSynchronizable: false` and `SecItemDelete`. The database file is deleted with app data. |

On iOS, a reinstalled app that finds a Keychain item but no database file must:
1. Attempt to load the DEK from Keychain.
2. Find no database file.
3. Generate a new database (first launch).
4. Optionally: delete the stale Keychain item and create a new DEK.

---

## 11. Device Migration

Device migration (e.g., transferring to a new phone) requires encrypted backup:

1. User exports an encrypted backup using a **recovery passphrase** (see Section 14).
2. User imports the backup on the new device.
3. The app generates a new device-bound DEK on the new device.
4. The recovery passphrase decrypts the backup and the data is written to the new encrypted database.

The old device's DEK cannot be transferred — it is device-bound by Keystore / Keychain.

---

## 12. Lost-Key Behavior

If the device-bound DEK is lost (factory reset, OS corruption, Keystore wipe):
- The local database **cannot be opened**.
- Recovery is possible only via an encrypted backup or Firestore cloud sync.
- Users must be informed of this during onboarding (acceptance of the key-loss risk).

If both the DEK and backups are lost, **all local financial data is unrecoverable**. This is a deliberate security trade-off: the data is protected against unauthorized access even if the device is physically seized.

---

## 13. Backup Recovery-Key Separation

Backup files use a **separate recovery passphrase** (or generated recovery key), not the device-bound DEK.

- The backup file is encrypted with a key derived from the recovery passphrase using Argon2id.
- The recovery passphrase is chosen by the user and must be stored securely outside the app.
- Unencrypted backups are not allowed.
- The recovery passphrase does not provide access to the device-bound DEK and cannot be used to open the local database directly.

---

## 14. Local-Only Mode

When Firestore cloud sync is disabled:
- The only recovery path is the encrypted backup file.
- There is no server-side copy of the data or the DEK.
- The user bears full responsibility for backup management.

---

## 15. Optional Cloud-Sync Recovery

When Firestore cloud sync is enabled:
- Financial records are replicated to Firestore (details in `FIRESTORE_SCHEMA.md`).
- A device migration can restore data from Firestore rather than a backup file.
- The DEK is still device-bound; Firestore does not store or transmit the DEK.
- On a new device, the app generates a new DEK and syncs data down from Firestore.

---

## 16. Failure States

| Scenario | Behavior |
|---|---|
| sqlite3mc library absent from build | `StateError` at database open (fail-closed, release-safe) |
| DEK not found in Keystore/Keychain | Force re-authentication or show recovery prompt |
| Wrong DEK applied to database | Exception from `select count(*) from sqlite_master` in setup callback |
| Keystore key invalidated by new biometric enrollment | Prompt user to re-authenticate with device credential; re-wrap DEK |
| Database file corrupt | Offer restore from backup |
| Backup recovery passphrase lost | Data unrecoverable (disclose during onboarding) |

---

## 17. Redacted Error Handling

All database-open errors must be logged without emitting:
- The DEK value (or any bytes of it)
- The recovery passphrase
- Any key material in any form

The `RedactedLogger` in `lib/core/logging/redacted_logger.dart` is the only permitted
log sink. Error messages reference the failure category (e.g., `db_open_failed`,
`cipher_absent`, `key_load_failed`) but not the key value.

---

## 18. Test Strategy

| Test category | What it covers |
|---|---|
| Host unit tests | sqlite3mc presence, key-correct open, key-wrong rejection, plaintext absence, reopen persistence |
| Widget tests | App-lock UI (show/hide, biometric prompt placeholder) |
| Integration tests (iOS simulator) | Runtime cipher check, end-to-end key flow |
| Integration tests (Android emulator) | Runtime cipher check, end-to-end key flow |
| Physical device tests | Keystore hardware-backed key, BiometricPrompt, Keychain access control |
| Backup/restore tests | Encrypted export, passphrase-based import |

Host unit tests classify as **Host-runtime-tested**.  
Physical Keystore and Keychain behavior is **Unverified** until physical-device tests run.  
A macOS host test does not prove Android Keystore or iOS Keychain behavior.
