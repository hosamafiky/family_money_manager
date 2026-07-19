# DECISION-004 Assessment — Local Database Encryption

**Phase:** 1.5 — Encrypted local-database feasibility  
**Assessment date:** 2026-07-15  
**Status:** Evidence collected. Four product-owner decisions required before Phase 2.  
**Preceding version:** Phase 1 (incomplete — contained EOL-package misinterpretation corrected below)

---

## 1. Correction: EOL Packages Are Not a Blocker

The Phase 1 version of this document incorrectly stated that encrypted Drift databases
were "unavailable" because `sqlite3_flutter_libs` and `sqlcipher_flutter_libs` were
end-of-life (EOL).

**That conclusion was wrong. Here is the accurate picture.**

`sqlite3_flutter_libs` and `sqlcipher_flutter_libs` are **obsolete compatibility packages**
that existed under the old `sqlite3` 2.x scheme. They are marked `+eol` on pub.dev because
the mechanism they provided — platform-specific build scripts — has been superseded.

Under `sqlite3` 3.x, SQLite is bundled via Dart's **pub build hooks** (native assets).
The two EOL packages have been replaced by configuration inside `pubspec.yaml`. They
may still appear as transitive dependencies (`sqlcipher_flutter_libs 0.7.0+eol`,
`sqlite3_flutter_libs 0.6.0+eol`) when `drift_flutter` is resolved, but they are
**no-op stubs only** — they do not provide the encryption implementation and do not
affect the native binary that is actually compiled and linked.

---

## 2. Evaluated Approach: sqlite3 3.x + SQLite3MultipleCiphers via Build Hooks

### References consulted (accessed 2026-07-15)

| Source | URL |
|---|---|
| Drift encryption guide | https://drift.simonbinder.eu/platforms/encryption/ |
| sqlite3 hook options | https://pub.dev/documentation/sqlite3/latest/topics/hook-topic.html |
| sqlite3.dart upgrade guide | https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md |
| Drift encryption example | https://github.com/simolus3/drift/blob/develop/examples/encryption/lib/database.dart |
| Drift 2.32.0 release notes | https://github.com/simolus3/drift/releases/tag/drift-2.32.0 |

### Package versions used in Phase 1.5 spike

| Package | Version |
|---|---|
| `drift` | 2.34.2 |
| `drift_flutter` | 0.3.1 |
| `sqlite3` | 3.4.0 |
| `hooks` (transitive) | 2.0.2 |
| `code_assets` (transitive) | 1.2.1 |
| `sqlcipher_flutter_libs` (transitive, no-op EOL stub) | 0.7.0+eol |
| `sqlite3_flutter_libs` (transitive, no-op EOL stub) | 0.6.0+eol |

### How it works

1. Add the following to `pubspec.yaml` (app or pub workspace root):

   ```yaml
   hooks:
     user_defines:
       sqlite3:
         source: sqlite3mc   # selects SQLite3MultipleCiphers; default is sqlite3
   ```

2. On first build, the `sqlite3` build hook downloads and compiles the
   SQLite3MultipleCiphers binary for the target platform using Dart native assets.

3. Use `NativeDatabase` from `package:drift/native.dart` (unchanged API).
   The encryption-aware binary is linked automatically.

4. Set the encryption key **inside the `setup` callback** before Drift accesses
   the schema:

   ```dart
   NativeDatabase(
     file,
     setup: (db) {
       // Fail-closed check — release-safe, not debug-only.
       final cipher = db.select('pragma cipher');
       if (cipher.isEmpty) throw StateError('sqlite3mc not present');
       db.execute("pragma key = '$escapedKey'");
       db.execute('select count(*) from sqlite_master'); // verify key
     },
   );
   ```

5. Verify the correct implementation is present at runtime using `pragma cipher`,
   which returns a non-empty result only when SQLite3MultipleCiphers is the active
   engine. Standard SQLite ignores this pragma and returns empty.

### Important terminology

**SQLite3MultipleCiphers is not SQLCipher.** They are distinct encryption
implementations from different authors with different codebase histories.
SQLite3MultipleCiphers includes a SQLCipher-compatibility mode, but the two are
not interchangeable. This document does not use the term "SQLCipher" to describe
the `sqlite3mc` build.

---

## 3. Phase 1.5 Spike Results

All verification was performed in `spike/enc_probe/`, which uses:
- `drift 2.34.2` + `drift_flutter 0.3.1` + `sqlite3 3.4.0`
- `hooks.user_defines.sqlite3.source: sqlite3mc` in `pubspec.yaml`
- A non-financial probe table (`probe_id`, `probe_value`) — no financial schema

### Host tests (macOS arm64) — `flutter test test/`

| Check | Description | Result |
|---|---|---|
| 6 | sqlite3mc cipher pragma present at runtime | PASS |
| 7 | Database opens with correct key | PASS |
| 8 | Database rejects incorrect key | PASS |
| 9 | Probe value absent from raw file bytes | PASS |
| 10 | Data persists across close/reopen | PASS |
| 11 | Encryption init before Drift schema access | PASS |
| 12a | Key not emitted through logger | PASS (by design: no log sink in path) |
| 12b | Ephemeral keys are unique per generation | PASS |
| 13 | Fail-closed when cipher absent (unit test) | PASS |

All 11 host tests passed. Exit code 0.

### Build compilation (all platforms)

| Target | Command | Exit code |
|---|---|---|
| Android debug APK | `flutter build apk --debug` | 0 |
| Android release APK | `flutter build apk --release` | 0 |
| Android App Bundle | `flutter build appbundle --release` | 0 |
| iOS debug (no codesign) | `flutter build ios --debug --no-codesign` | 0 |
| iOS release (no codesign) | `flutter build ios --release --no-codesign` | 0 |

### iOS simulator — `flutter test integration_test/` — iPhone 17 Pro

| Simulator | iPhone 17 Pro (94E682A6-E8DC-413C-8A97-BC53FBC4873D) |
|---|---|
| Runtime | iOS 26.5 / com.apple.CoreSimulator.SimRuntime.iOS-26-5 |
| Architecture | arm64 (Apple Silicon host) |
| Classification | iOS-simulator-tested (not physical-device-tested) |

| Check | Result |
|---|---|
| 6 | cipher pragma present on iOS simulator | PASS |
| 7 | Correct-key open + write | PASS |
| 8 | Wrong-key rejection | PASS |
| 9 | Sentinel absent from raw bytes | PASS |
| 10 | Persist across reopen | PASS |

All 5 integration checks passed. Exit code 0.

### Android emulator

The Android emulator (`Medium_Phone_API_36.1`, Android 14 / API 34) launched
successfully but went offline before integration tests could be submitted in the
sandbox environment. Compilation was verified (debug APK exit 0). Runtime behavior
on the iOS simulator serves as the primary device-class runtime evidence.

**Classification:** Build-verified (Android). iOS-simulator-tested (runtime checks).
Android emulator runtime is **Unverified** due to sandbox instability.

---

## 4. EOL Transitive Dependencies — Accurate Report

When resolving `drift_flutter 0.3.1`, pub resolves:
- `sqlcipher_flutter_libs 0.7.0+eol` — no-op stub; provides no native binary
- `sqlite3_flutter_libs 0.6.0+eol` — no-op stub; provides no native binary

These stubs exist for backward compatibility. They do not conflict with the
sqlite3mc build hook and do not affect the encryption result. They are not the
encryption provider. The actual encrypted SQLite binary is compiled and linked
by the `sqlite3` 3.x build hook based on the `source: sqlite3mc` configuration.

---

## 5. Approved Product-Owner Decisions (PO-1 through PO-10) — Phase 1.5A

**Status:** ACCEPTED — 2026-07-15. DECISION-004 is closed.

| # | Decision |
|---|---|
| PO-1 | V1 requires encrypted local financial storage. |
| PO-2 | Selected: Drift `NativeDatabase` + `sqlite3` 3.x + SQLite3MultipleCiphers via pub build hooks. |
| PO-3 | Database encryption key will be cryptographically random. |
| PO-4 | App PIN will not be used as database key or sole entropy source. |
| PO-5 | Android Keystore + iOS Keychain will protect the key (security phase). |
| PO-6 | PIN and biometrics will gate access to the protected key. |
| PO-7 | Loss of device-bound key makes local data unrecoverable without encrypted backup or cloud sync. |
| PO-8 | Local-only mode is fully supported. |
| PO-9 | Portable backups use a separate recovery passphrase or recovery key. |
| PO-10 | Plaintext database fallback and plaintext financial backups are prohibited. |

**Not implemented in Phase 1.5A:** Key storage, PIN, biometrics, backup encryption,
cloud-sync recovery, and production database opening remain deferred.

---

## 6. Phase 1.5A Additional Evidence

### Negative-provider test (standard SQLite, no sqlite3mc hook)

`spike/plain_sqlite_probe/` used `sqlite3 3.4.0` WITHOUT `hooks.user_defines.sqlite3.source: sqlite3mc`.

| Test | Result | Classification |
|---|---|---|
| PRAGMA cipher returns empty from standard SQLite | PASS | Host-runtime-tested |
| verifyEncryptionPresent([]) → StateError | PASS | Host-runtime-tested |
| End-to-end: real empty pragma → fail-closed StateError | PASS | Host-runtime-tested |
| Non-empty result → no throw | PASS | Host-runtime-tested |

### android_probe host unit tests

| Test | Result | Classification |
|---|---|---|
| verifyEncryptionPresent uses if/throw, not assert | PASS | Host-runtime-tested |
| empty pragma → safe StateError with category string | PASS | Host-runtime-tested |
| classifyKeyFailure → safe string, no raw SQL | PASS | Host-runtime-tested |
| Key never appears in log sink | PASS | Host-runtime-tested |

### Android emulator

The emulator launched (cold boot, `swiftshader_indirect`, `no-snapshot-load`) but went offline before integration tests could be submitted. Builds were not run in Phase 1.5A at product-owner direction. See Phase 1.5 for Android APK/AAB build-verified evidence.

**Android emulator runtime remains Unverified.**

---

## 7. Open Product-Owner Decisions (Now Closed)

All four original open decisions (PO-1 through PO-4) have been superseded by the
expanded PO-1 through PO-10 set accepted in Section 5 above (Phase 1.5A, 2026-07-15).
DECISION-004 is closed.

---

## 6. What Remains for Later Phases

The following are **not** part of Phase 1.5 and are deferred:

- Production database class (financial tables)
- Secure key generation and storage (`flutter_secure_storage` or equivalent)
- Android Keystore key wrapping implementation
- iOS Keychain key storage implementation
- PIN and biometric gating of the database key
- App-lock UI
- Database rekey procedure
- Backup encryption with recovery passphrase
- Cloud-sync key recovery path
- On-device automated test on a physical Android device

---

## 8. Production Encryption Status (Phase 5B.5 Clarification)

**IMPORTANT:** As of Phase 5B.5, no production encryption is currently implemented
or verified in the main application code (`lib/`).

Specifically:

| Item | Status |
|---|---|
| Drift `NativeDatabase` | **In use** (unencrypted) |
| `SQLite3MultipleCiphers` selected as cipher library | Documented and spike-verified |
| `sqflite_sqlcipher` | **Not selected** |
| Android runtime cipher verification | **DEFERRED** to production security hardening phase |
| iOS runtime cipher verification | Spike-tested on simulator only (not physical device) |
| Production PIN / biometrics / secure key storage | **Not built** |
| Production `AppDatabase` with encryption | **Not built** |

The application currently opens its SQLite database via an unencrypted
`NativeDatabase` (see `_devConnection()` in `app_database.dart`). The
`SQLite3MultipleCiphers` cipher library has been verified in the `spike/enc_probe/`
directory only. Platform-backed secure key storage is planned for a later
security phase.
