# DECISION-004 Assessment — Local Database Encryption

**Date:** 2026-07-15  
**Flutter:** 3.44.4 · **Dart:** 3.12.2 · **Platform:** macOS arm64  
**Status:** Open — product-owner decision required before Phase 2 begins  
**Evidence basis:** `flutter pub add --dry-run` resolution checks + disposable spike compilation  

---

## 1. What this decision controls

Every piece of local financial data — account balances, ledger entries, transfer records, gold positions, certificate timelines, and child-fund histories — will be stored in a SQLite database on the device. This decision determines whether and how that database file is encrypted at rest.

The choice affects:

- Which ORM or database driver is used (`drift_flutter` vs `sqflite_sqlcipher`)
- Whether a PIN / biometric credential is required to derive the encryption key
- What happens when the user loses their device PIN
- Whether automated tests can run against a real database or require a special testing key
- Build complexity on Android and iOS
- CI pipeline requirements

---

## 2. Package landscape (as of 2026-07-15)

### 2.1 What is end-of-life

Both previously popular native-library packages are explicitly marked end-of-life on pub.dev:

| Package | Latest version | Note |
|---|---|---|
| `sqlite3_flutter_libs` | `0.6.0+eol` | Replaced by `drift_flutter` native assets approach |
| `sqlcipher_flutter_libs` | `0.7.0+eol` | No maintained replacement on pub.dev |

The `+eol` suffix is a publishing convention used by the Drift team to signal the package has been superseded. These packages **must not** be used in new projects.

### 2.2 Current maintained options

| Package | Version | Description |
|---|---|---|
| `drift` | `2.34.2` | ORM / query builder (maintained) |
| `drift_flutter` | `0.3.1` | Flutter-specific SQLite provider via Dart native assets (replaces `sqlite3_flutter_libs`) |
| `drift_dev` | `2.34.4` | Code generation for Drift |
| `sqflite_sqlcipher` | `3.4.0` | SQLCipher-backed sqflite fork (SQLCipher 4.x) |
| `sqflite` | (transitive) | Standard unencrypted sqflite |

---

## 3. Options evaluated

### Option A — Unencrypted SQLite via `drift_flutter`

**Architecture:** `drift 2.34.2` + `drift_flutter 0.3.1`

**How it works:** `drift_flutter` uses Dart's native assets system (introduced in Dart 3.x) to compile and link the standard SQLite amalgamation directly into the application. It replaces both `sqlite3_flutter_libs` (EOL) and `sqflite`. No native build script is required.

**Evaluation:**

| Criterion | Result |
|---|---|
| Flutter 3.44.4 compatibility | Confirmed — resolves and compiles |
| Drift compatibility | Native — `drift_flutter` is the Drift team's own package |
| Android support | Confirmed |
| iOS support | Confirmed |
| Native build requirements | None — handled by Dart native assets |
| Maintenance status | Actively maintained by Drift author (simolus3) |
| Encryption | None |
| Secure key storage | Not applicable |
| PIN / biometric relationship | Not applicable |
| Key rotation | Not applicable |
| Lost-key behaviour | Not applicable |
| Backup and restore | Standard file copy; data readable if device is not locked |
| Migration (plain → encrypted) | N/A |
| Automated test support | Full — in-memory database via `NativeDatabase.memory()` |
| CI implications | No special native toolchain required |
| License | SQLite is public domain; drift is MIT |
| Operational risk | Low |

**Spike result:** `drift_flutter 0.3.1` + `drift 2.34.2` + `drift_dev 2.34.4` resolve, code-generate, and analyze clean. See `spike/db_options/`.

**Security note:** Without encryption, anyone with physical access to a rooted Android device or a jailbroken iOS device can extract the database file and read all financial data in plain text. On non-rooted/non-jailbroken devices, the OS sandbox protects the file.

---

### Option B — SQLCipher via `sqflite_sqlcipher`

**Architecture:** `sqflite_sqlcipher 3.4.0` (wraps SQLCipher 4.x)

**How it works:** `sqflite_sqlcipher` is a drop-in replacement for `sqflite` that links SQLCipher instead of standard SQLite. All databases are transparently encrypted with AES-256. A passphrase (key) is required to open the database.

**Evaluation:**

| Criterion | Result |
|---|---|
| Flutter 3.44.4 compatibility | Resolves — `flutter pub add --dry-run` succeeds |
| Drift compatibility | **Uncertain** — drift 2.x dropped the `sqflite` backend in favour of native `sqlite3`. Using `sqflite_sqlcipher` as a Drift backend requires either (a) the older `drift_sqflite` adapter (removed from drift 2.x) or (b) a custom `QueryExecutor` wrapping sqflite_sqlcipher. This requires a non-trivial spike before the path can be confirmed. |
| Android support | Confirmed — native `.so` bundled by package |
| iOS support | Confirmed — SQLCipher compiled into `.framework` |
| Native build requirements | Pre-built binaries are included. Android NDK not required by the package itself, but the binaries are compiled with specific ABIs. |
| Maintenance status | Moderate — last published 2024; no governance statement |
| Encryption | AES-256-CBC (SQLCipher 4 default) |
| Secure key storage | Key must be derived from a source. Options: (1) `flutter_secure_storage` (device keychain / keystore), (2) user PIN (key = PBKDF2(PIN, salt)), (3) both combined |
| PIN / biometric relationship | If key = PIN-derived, biometric can protect the PIN but does not eliminate it |
| Key rotation | Supported by SQLCipher `rekey` pragma, but requires re-encrypting the entire database |
| Lost-key behaviour | **Unrecoverable** unless backup is encrypted separately with an escrow key. No built-in recovery path. If the PIN is forgotten and no backup exists, all data is lost. |
| Backup and restore | Backup file must also be encrypted. A second key (backup key) or the same device key can be used — policy must be chosen before implementation |
| Migration (plain → encrypted) | SQLCipher provides `sqlcipher_export` / `ATTACH` to migrate, but requires device downtime and careful rollback planning |
| Automated test support | Tests require a key to open the database. CI must inject a test key (e.g., `--dart-define=TEST_DB_KEY=testkey`). In-memory databases do not use SQLCipher by default — tests must explicitly open named databases. |
| CI implications | CI pipeline must pass a non-secret test key. The test key must differ from the device key. Test isolation requires careful teardown. |
| License | SQLCipher is BSD-licensed (open source edition); no royalties for mobile use |
| Operational risk | Medium — Drift + sqflite_sqlcipher path unconfirmed; key management adds complexity |

**Compilation spike:** NOT completed for this option because the Drift + sqflite_sqlcipher path requires additional investigation. If this option is chosen, a Phase 1.5 spike must:

1. Confirm whether drift 2.34.2 can use sqflite_sqlcipher as a backend
2. If not, evaluate: (a) use sqflite_sqlcipher without Drift (raw SQL), or (b) compile SQLCipher natively and provide it to drift's `NativeDatabase`
3. Measure the APK size impact of SQLCipher binaries on Android and iOS

---

### Option C — `drift_flutter` with custom SQLCipher binary (native assets)

**Architecture:** Custom SQLCipher amalgamation compiled via Dart native assets, provided to `drift`'s `NativeDatabase`

**How it works:** Drift's native assets approach allows substituting a custom SQLite implementation. SQLCipher is a drop-in replacement for the SQLite amalgamation. Building it as a native asset would give encrypted storage with full Drift compatibility.

**Evaluation:**

| Criterion | Result |
|---|---|
| Flutter / Drift compatibility | Theoretically compatible; no pub.dev package exists for this approach |
| Native build requirements | Must write a `build.dart` hook that downloads and compiles SQLCipher source for each ABI (arm64-v8a, armeabi-v7a, x86_64, arm64 iOS). High build complexity. |
| Maintenance status | Self-maintained; team owns the SQLCipher compilation script |
| Operational risk | High — native toolchain dependency, per-platform build, no community support |

**Recommendation:** Do not pursue Option C in V1. The build complexity and maintenance burden are disproportionate for a V1 product.

---

## 4. Comparison matrix

| Criterion | A: Unencrypted (`drift_flutter`) | B: SQLCipher (`sqflite_sqlcipher`) | C: Custom native SQLCipher |
|---|---|---|---|
| Compilation verified | Yes (spike) | Resolution only | No |
| Drift 2.x native support | Yes | Uncertain | Theoretical |
| EOL risk | None | Low–Medium | N/A |
| Encryption at rest | No | AES-256 | AES-256 |
| Test complexity | Low | Medium | High |
| CI complexity | Low | Medium | High |
| Lost-key recovery | N/A | None built-in | None built-in |
| Key storage design required | No | Yes | Yes |
| Build complexity | Low | Low–Medium | High |
| Time to Phase 2 confidence | 0 | 1–2 days spike | 1+ week |
| Recommended | If encryption deferred | If encryption required V1 | Do not use |

---

## 5. Recommendation

**Use Option A (`drift_flutter`) for V1** unless the product owner explicitly requires encryption at rest before the first production release.

Rationale:
1. `drift_flutter` is compilation-verified and maintained.
2. The SQLCipher path (Option B) has an **unconfirmed Drift 2.x integration path** that requires a separate spike before Phase 2 can begin.
3. Encryption can be added in a later phase by migrating the database via `ATTACH` + `sqlcipher_export`. This is a known SQLCipher pattern.
4. iOS and Android OS-level sandbox protection provides meaningful protection against casual access on non-jailbroken/non-rooted devices.
5. Lost-key recovery (a real household risk) is unsolvable without a backup encryption policy — which also needs to be decided regardless of Option A or B.

**If the product owner requires encryption in V1,** a follow-up spike must be completed before Phase 2 begins:
1. Confirm whether drift 2.34.2 can use `sqflite_sqlcipher` as its backend (or determine the correct adapter)
2. Design key derivation (device keychain only vs PIN-derived)
3. Define lost-key and backup encryption policies

---

## 6. Product-owner choices required

The following decisions block Phase 2. They cannot be defaulted by the development team.

---

### PO-1: Encryption required in V1?

> **Yes** — database file must be encrypted before the first production build  
> **No** — unencrypted SQLite is acceptable for V1; encryption added in a later phase

*Impact:* If **Yes**, a Drift + SQLCipher integration spike (estimated 1–2 days) is required before Phase 2. If **No**, Phase 2 can begin immediately with `drift_flutter`.

---

### PO-2: Key protection model (if encryption required)

> **Device keychain only** — the encryption key is stored in Android Keystore / iOS Keychain. Accessible when the device is unlocked. No user PIN required to open the app.
>
> **PIN-derived + device keychain** — the encryption key is derived from the user's app-level PIN using PBKDF2. Biometric can unlock the PIN. Losing the PIN with no backup means losing all data.

*Impact:* If PIN-derived, PIN reset and biometric UX must be designed before Phase 3 (authentication). The key management code is Phase 3 scope, but the database engine choice must be compatible.

---

### PO-3: Lost-key policy (if encryption required)

> **Accept full data loss** — if the encryption key is lost (device wiped, PIN forgotten, keychain corrupted), all local data is irrecoverable.
>
> **Require cloud backup with separate encryption key** — a copy of the database (or ledger state) is encrypted with a backup key and stored in cloud backup. Lost-device recovery restores from backup.

*Impact:* If cloud backup is required, Firestore sync design (Phase 3) must accommodate the backup key separately from the local database key.

---

### PO-4: Backup file encryption policy

> **Same key as local database** — backup files use the same encryption key. Convenient but loses any separation between device and backup.
>
> **Separate backup passphrase** — backup files encrypted with a user-provided passphrase separate from the device key. Allows restoring to a new device without sharing device credentials.
>
> **Unencrypted backup** — backup file is plain text. Acceptable only if transport encryption (e.g., cloud provider TLS + server-side encryption) is considered sufficient.

*Impact:* Determines the backup-restore implementation in Phase 5+.

---

## 7. Spike artefact

The disposable spike is at `spike/db_options/`. It contains:

- `pubspec.yaml` — `drift 2.34.2` + `drift_flutter 0.3.1` + `drift_dev 2.34.4`
- `lib/main.dart` + `lib/main.g.dart` — empty-schema database, no financial data
- Evidence: `flutter pub get` succeeds, `build_runner build` succeeds, `flutter analyze` reports zero issues

**This spike determines the production architecture by confirming compilation only.** The architecture decisions above (Option A vs B vs C) remain the product owner's choice.

**Delete `spike/` after DECISION-004 is resolved.** It must not be imported into `lib/` under any circumstances.
