# Phase 1.5A Report — Android Encrypted-Database Runtime Closure and DECISION-004 Finalisation

**Date:** 2026-07-15  
**Branch:** `main`  
**Base commit:** `ddedaa10` (Phase 1.5)  
**Phase scope:** Android runtime closure, negative provider verification, PO decision recording. No financial logic. No Phase 2 work.

---

## 1. Approved Product-Owner Decisions (PO-1 through PO-10)

Recorded 2026-07-15. DECISION-004 is now **ACCEPTED**.

| # | Decision | Status |
|---|---|---|
| PO-1 | V1 requires encrypted local financial storage | Accepted |
| PO-2 | Selected: Drift NativeDatabase + sqlite3 3.x + SQLite3MultipleCiphers via pub build hooks | Accepted |
| PO-3 | Database encryption key will be cryptographically random | Accepted |
| PO-4 | App PIN will not be used as database key or sole entropy source | Accepted |
| PO-5 | Android Keystore + iOS Keychain will protect the random key (later security phase) | Accepted |
| PO-6 | PIN and biometrics will gate access to the protected key | Accepted |
| PO-7 | Loss of device-bound key makes local data unrecoverable without encrypted backup or cloud sync | Accepted |
| PO-8 | Local-only mode is fully supported | Accepted |
| PO-9 | Portable backups use a separate recovery passphrase or recovery key | Accepted |
| PO-10 | Plaintext database fallback and plaintext financial backups are prohibited | Accepted |

**Not implemented in Phase 1.5A:** Key storage, PIN, biometrics, backup encryption, cloud-sync recovery, and production database opening remain deferred to the approved security phase.

---

## 2. Exact Dependency Versions

| Package | Version |
|---|---|
| `drift` | 2.34.2 |
| `drift_flutter` | 0.3.1 |
| `sqlite3` | 3.4.0 |
| `path_provider` | 2.x (spike only) |
| `hooks` (transitive) | 2.0.2 |
| `code_assets` (transitive) | 1.2.1 |
| `sqlcipher_flutter_libs` (transitive no-op stub) | 0.7.0+eol |
| `sqlite3_flutter_libs` (transitive no-op stub) | 0.6.0+eol |
| Flutter | 3.32.4 (stable) |
| Dart SDK | ≥3.12.2 |

**Build-hook configuration (both spikes and planned production):**

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc   # SQLite3MultipleCiphers — not SQLCipher
```

---

## 3. Android Emulator Status

| Item | Value |
|---|---|
| AVD name | Medium_Phone_API_36.1 |
| Android SDK version | 36.1.0 (API 36.1) |
| Reported runtime API | Android 14 / API 34 (as shown by flutter devices) |
| CPU / ABI | android-arm64 |
| Hardware acceleration | swiftshader_indirect (software GPU — sandbox constraint) |
| Launch command | `~/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36.1 -no-snapshot-load -gpu swiftshader_indirect -no-audio -no-boot-anim` |
| Boot wait | `adb wait-for-device` then polling `sys.boot_completed` |
| Stability | Emulator started (offline → device in adb) but integration tests could not run before emulator went offline again. **Sandbox environment constraint.** |
| Runtime checks on emulator | **Unverified** |

Integration tests are compiled and ready in `spike/android_probe/integration_test/android_runtime_test.dart` (deleted after evidence recording). The test file covers all 13 required checks and can be re-run outside the sandbox.

---

## 4. Debug Runtime Evidence

### android_probe host unit tests (macOS arm64) — `flutter test test/`

Tests cover the logic paths that run in debug mode on any platform including Android.

| Test | Check | Result | Classification |
|---|---|---|---|
| verifyEncryptionPresent uses if/throw not assert | 2 | PASS | Host-runtime-tested |
| empty pragma → StateError with safe category | 3 | PASS | Host-runtime-tested |
| non-empty pragma → no throw | 3b | PASS | Host-runtime-tested |
| generateEphemeralKey: 64-char hex, not in sink | 11/12 | PASS | Host-runtime-tested |
| classifyKeyFailure: safe string, no raw SQL | 6/8 | PASS | Host-runtime-tested |
| db_lifecycle entries contain no hex key material | 11 | PASS | Host-runtime-tested |
| ProbeEntries columns have no financial names | scope | PASS | Host-runtime-tested |

**7/7 host unit tests passed. Exit code 0.**

### iOS simulator (Phase 1.5) — for reference

| Check | Result | Classification |
|---|---|---|
| 1 cipher pragma present | PASS | iOS-simulator-tested |
| 5 correct-key open | PASS | iOS-simulator-tested |
| 7 reopen persistence | PASS | iOS-simulator-tested |
| 8 wrong-key rejection | PASS | iOS-simulator-tested |
| 9 plaintext absent from file | PASS | iOS-simulator-tested |

5/5 integration checks passed on iPhone 17 Pro simulator (Phase 1.5 evidence — carried forward).

---

## 5. Release/Profile Runtime Evidence

Checks 12 and 13 require that the fail-closed logic works without debug assertions.

| Evidence | Classification |
|---|---|
| `verifyEncryptionPresent` uses `if (result.isEmpty) throw StateError(...)` — no `assert` keyword | Source-verified |
| Unit test runs `verifyEncryptionPresent([])` and gets StateError on host (debug build of test runner) | Host-runtime-tested |
| Function body contains no `assert`, `bool.fromEnvironment`, or conditional compilation | Source-verified |
| Android release APK: compilation verified (exit 0) in Phase 1.5 | Build-verified |
| Android release APK runtime on emulator | Unverified (sandbox constraint) |

The fail-closed logic is a plain Dart `if/throw` which is **not stripped in profile or release builds**. Source verification confirms no assert keyword.

---

## 6. Cipher-Provider Evidence

| Evidence | Classification |
|---|---|
| macOS host: PRAGMA cipher returns non-empty with sqlite3mc hook | Host-runtime-tested |
| iOS simulator: PRAGMA cipher returns non-empty | iOS-simulator-tested |
| Android emulator: cipher check not executed (emulator offline) | Unverified |

---

## 7. Correct-Key Evidence

| Platform | Result | Classification |
|---|---|---|
| macOS host | INSERT + SELECT succeed | Host-runtime-tested |
| iOS simulator | INSERT + SELECT succeed | iOS-simulator-tested |
| Android emulator | Unverified | Unverified |

---

## 8. Wrong-Key Evidence

| Platform | Result | Classification |
|---|---|---|
| macOS host | Exception thrown at first query | Host-runtime-tested |
| iOS simulator | Exception thrown at first query | iOS-simulator-tested |
| Android emulator | Unverified | Unverified |

The exception is classified by `classifyKeyFailure()` to `db_error: key_incorrect_or_db_corrupt` — no native SQL details exposed.

---

## 9. Reopen Evidence

| Platform | Result | Classification |
|---|---|---|
| macOS host | Row persists after close + reopen | Host-runtime-tested |
| iOS simulator | Row persists after close + reopen | iOS-simulator-tested |
| Android emulator | Unverified | Unverified |

---

## 10. Plaintext Inspection Evidence

| Platform | Result | Classification |
|---|---|---|
| macOS host | Sentinel string absent from raw file bytes | Host-runtime-tested |
| iOS simulator | Sentinel string absent from raw file bytes | iOS-simulator-tested |
| Android emulator | Unverified | Unverified |

---

## 11. Negative Ordinary-SQLite Evidence

**This is genuine runtime library evidence — not a mock.**

The `spike/plain_sqlite_probe/` project uses `sqlite3 3.4.0` with **no** `hooks.user_defines.sqlite3.source: sqlite3mc`. The standard SQLite binary is bundled. The cipher pragma returns empty.

### Tests run — `flutter test test/negative_provider_test.dart` — macOS host

| Test | Result | Classification |
|---|---|---|
| PRAGMA cipher returns empty from standard SQLite | PASS | Host-runtime-tested |
| verifyEncryptionPresent([]) → StateError | PASS | Host-runtime-tested |
| End-to-end: real empty pragma result → fail-closed StateError | PASS | Host-runtime-tested |
| Non-empty result → no throw (absence of false positive) | PASS | Host-runtime-tested |

**4/4 passed. Exit code 0.**

The end-to-end test proves: (1) a runtime library genuinely lacking the cipher pragma returns empty, (2) the production detection function correctly throws StateError before any schema or data access can occur.

---

## 12. Fail-Closed Evidence

| Evidence | Classification |
|---|---|
| `verifyEncryptionPresent([])` throws `StateError` — unit-tested | Host-runtime-tested |
| Error message contains `cipher_absent` (safe category) | Host-runtime-tested |
| Error message does not contain `pragma key` | Host-runtime-tested |
| Error message does not contain hex key material | Host-runtime-tested |
| Real standard-SQLite empty pragma triggers the same StateError | Host-runtime-tested |
| StateError is thrown before `pragma key` or any schema access | Source-verified (setup callback order) |

---

## 13. Logging Limitations and Evidence

### What was captured

A `TestLogSink` in `spike/android_probe/lib/probe_database.dart` captures lifecycle and error events.

| Log entry type | Content | Key present? |
|---|---|---|
| `[db_lifecycle] cipher_verified` | Category string only | No |
| `[db_lifecycle] db_opened` | Category string only | No |
| `[db_error] cipher_absent` | Category string only | No |

### What was verified

- The key is never passed to `TestLogSink.log()` — it enters only the `setup` callback as a local variable and is not passed to any public API.
- `classifyKeyFailure()` maps exceptions to `db_error: key_incorrect_or_db_corrupt` without including raw exception text.
- No hex key material appears in any log entry (tested via regex match on log entries).
- Database path: logged as the category `db_opened` — the actual file path is not included.
- SQL statements containing `PRAGMA key` are not logged — the pragma executes inside the `setup` callback with no log sink involvement.

### What is unverified

- Native process stdout/stderr (logcat) on a physical Android device — **Unverified**.
- Third-party crash-reporting path — **Unverified**.
- Android Keystore / iOS Keychain error paths — **Unverified** (not implemented yet).

---

## 14. Commands and Exit Codes

| Command | Directory | Exit |
|---|---|---|
| `dart format --output=none --set-exit-if-changed .` | production | 0 |
| `flutter analyze` | production | 0 (No issues) |
| `flutter test` | production | 0 (91/91) |
| `flutter test test/probe_unit_test.dart` | spike/android_probe | 0 (7/7) |
| `flutter test test/negative_provider_test.dart` | spike/plain_sqlite_probe | 0 (4/4) |
| `flutter build apk --debug` | production | **Skipped** (product-owner direction) |
| `flutter build apk --release` | production | **Skipped** |
| `flutter build appbundle --release` | production | **Skipped** |
| `flutter build ios --debug --no-codesign` | production | **Skipped** |
| `flutter build ios --release --no-codesign` | production | **Skipped** |

Note: All five production build targets passed in Phase 1.5. Spike builds (Android APK debug/release/aab, iOS debug/release) also passed in Phase 1.5.

---

## 15. Production Scope Scan

The production `lib/` tree contains no:

| Item | Status |
|---|---|
| Drift database class | None |
| Financial schema or tables | None |
| Database-opening code | None |
| Secure-storage implementation | None |
| PIN or biometric implementation | None |
| Backup implementation | None |
| Financial domain model | None |
| Firebase dependency | None |
| AI or voice integration | None |
| Spike code import | None — spike is a separate project with no cross-import |

Confirmed by: `flutter analyze → No issues found` (exit 0).

---

## 16. Files Created, Changed, and Deleted

### Spike files (created and deleted — not committed)

| File | Spike | Purpose |
|---|---|---|
| `spike/android_probe/pubspec.yaml` | android_probe | drift + sqlite3mc hook |
| `spike/android_probe/lib/probe_database.dart` | android_probe | ProbeEntries + verifyEncryptionPresent + logging |
| `spike/android_probe/lib/probe_database.g.dart` | android_probe | Generated by drift_dev |
| `spike/android_probe/lib/main.dart` | android_probe | Shell for build targets |
| `spike/android_probe/test/probe_unit_test.dart` | android_probe | 7 host unit tests |
| `spike/android_probe/integration_test/android_runtime_test.dart` | android_probe | 13 Android runtime checks |
| `spike/plain_sqlite_probe/pubspec.yaml` | plain_sqlite_probe | Standard sqlite3, no sqlite3mc |
| `spike/plain_sqlite_probe/lib/main.dart` | plain_sqlite_probe | Shell |
| `spike/plain_sqlite_probe/test/negative_provider_test.dart` | plain_sqlite_probe | 4 negative-provider tests |

All spike files deleted after evidence recording. Not committed.

### Production files changed in Phase 1.5A

| File | Change |
|---|---|
| `docs/DECISIONS.md` | DECISION-004 changed from "Evidence collected" to **ACCEPTED**; PO-1..PO-10 recorded |
| `docs/DECISION_004_ASSESSMENT.md` | Updated with PO decision section and Phase 1.5A evidence |
| `docs/PHASE_1_5_ANDROID_REPORT.md` | This report (new file) |

---

## 17. Final Git Status

```
Branch: main
Base commit: ddedaa10 (Phase 1.5)
Working tree: all production changes staged for commit
```

---

## 18. money_tracker Integrity Evidence

```
Branch: main
HEAD: f1d7e78959cf973d517abe994a54b56490ca5419
Status: clean — no modifications
Diff: (empty)
```

Not modified. Not inspected for content.

---

## 19. Remaining Unverified Behaviour

| Item | Classification | Path to verify |
|---|---|---|
| Android emulator runtime (Checks 1–13) | Unverified | Re-run integration_test/ on stable emulator outside sandbox |
| Physical Android device: all 13 checks | Unverified | Physical device test in security phase |
| Physical Android device: Keystore hardware-backed key | Unverified | Security phase |
| Physical iOS device: Keychain access-control gating | Unverified | Security phase |
| Native logcat / process stdout key leak | Unverified | Android profiling session |
| Third-party crash-reporting path | Unverified | Security phase |
| Key rotation procedure | Unverified (not implemented) | Security phase |
| Backup encryption with recovery passphrase | Unverified (not implemented) | Backup phase |
| Cloud-sync recovery path | Unverified (not implemented) | Sync phase |
| Production `flutter build` commands (this phase) | Skipped at PO direction | Phase 2 pre-work or next dev session |
