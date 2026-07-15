# Open and Closed Decisions

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## Format

Each decision lists:

- **Status:** Open | Accepted | Rejected
- **Context:** Why this decision needs to be made
- **Options considered**
- **Decision:** What was chosen (or what remains open)
- **Consequences:** Impact of the decision

---

## DECISION-001 — PIN Hashing Algorithm

**Status:** Accepted

**Context:** PIN values must never be stored raw. A hashing algorithm must be chosen that is available in Flutter without native plugins and provides adequate security for a 4–8 digit PIN.

**Options considered:**

1. **bcrypt** — Best-practice for password hashing; not natively available in pure Dart without a C library.
2. **PBKDF2 (SHA-256)** — Available via `pointycastle` package; widely used; iterations configurable.
3. **Argon2** — Memory-hard; considered strongest; not available in pure Dart for mobile.
4. **SHA-256 with random salt** — Simple; fast; acceptable for a PIN if paired with backoff.

**Decision:** PBKDF2-SHA256 with:

- 200,000 iterations
- 16-byte random salt stored in `flutter_secure_storage`
- Result stored in `flutter_secure_storage` (not SQLite)

Rationale: PBKDF2 is available via `pointycastle` without native dependencies. 200,000 iterations on modern hardware takes ~100–300ms, which is acceptable for PIN unlock. Combined with exponential backoff, brute-force is not practical.

**Consequences:** PIN unlock takes slightly longer than instant. Acceptable UX tradeoff.

---

## DECISION-002 — State Management

**Status:** Accepted

**Context:** Flutter has many state management solutions. The choice affects testability, code organization, and team conventions.

**Options considered:**

1. **Riverpod (v2 with code gen)** — Compile-time safety, testable without Flutter context, no global state, streams integration.
2. **BLoC/Cubit** — Mature, well-tested, but more boilerplate.
3. **Provider** — Simpler; less type safety.
4. **GetX** — Anti-pattern risks; global state.

**Decision:** Riverpod with `riverpod_annotation` code generation.

**Consequences:** All application logic must be in Riverpod Notifiers. Widget tests use `ProviderContainer` for isolation. No BuildContext-level DI.

---

## DECISION-003 — Local Database

**Status:** Accepted

**Context:** Financial data requires a relational database with ACID transactions, not a key-value store.

**Options considered:**

1. **Drift (Moor)** — Type-safe Dart API, SQLite backend, migration support, stream support, code generation.
2. **sqflite** — Raw SQLite; less type safety; requires manual query construction.
3. **Isar** — Fast NoSQL; does not support SQL queries needed for ledger calculations.
4. **Hive** — Key-value; unsuitable for relational financial data.
5. **SQLCipher (via drift_sqflite)** — Encrypted SQLite; adds at-rest encryption.

**Decision:** Drift (with standard unencrypted SQLite for v1).

SQLCipher is deferred to v2. The OS provides full-disk encryption on modern Android/iOS which is considered sufficient for v1.

**Consequences:** Database files are not application-level encrypted in v1. Risk rated as Medium (see SECURITY_THREAT_MODEL.md T-02).

---

## DECISION-004 — Local Database At-Rest Encryption

**Status:** Evidence collected (Phase 1.5). Four product-owner decisions (PO-1 through PO-4) required before Phase 2 begins. See `docs/DECISION_004_ASSESSMENT.md` for full evidence.

**Deadline:** Before Phase 2 database implementation.

**Correction (Phase 1.5):** Earlier versions of this entry incorrectly stated that
encrypted databases were unavailable because `sqlite3_flutter_libs` and
`sqlcipher_flutter_libs` were EOL. That was wrong. Those packages are obsolete
compatibility stubs under the old `sqlite3` 2.x scheme. Under `sqlite3` 3.x, the
encryption library is selected via pub build hooks and those stubs are no-op
transitive dependencies that do not affect the encryption outcome.

**Terminology correction:** The recommended implementation is **SQLite3MultipleCiphers**
(sqlite3mc), not SQLCipher. They are distinct implementations. Do not use the term
"SQLCipher" to describe the sqlite3mc build.

**Context:** Should the local SQLite database be encrypted at the application level?

**Recommended option (Phase 1.5 evidence supports this):**

Use `drift 2.34.2` + `drift_flutter 0.3.1` + `sqlite3 3.4.0` with:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc   # SQLite3MultipleCiphers
```

The database key is a cryptographically random 256-bit value protected by
Android Keystore / iOS Keychain. The PIN gates access to the key rather than
serving as the key. See `docs/LOCAL_ENCRYPTION_KEY_MANAGEMENT.md`.

**Verified in Phase 1.5 spike:**
- Compilation: Android debug/release/aab ✓, iOS debug/release ✓
- Runtime (macOS host): all 11 checks pass ✓
- Runtime (iOS simulator, iPhone 17 Pro): all 5 integration checks pass ✓
- Android emulator runtime: unverified (sandbox instability during spike)

**Fallback option (not recommended for V1 per product-owner security policy):**

OS-level FDE only (no application-level encryption).

**Impact of deferring (Option A):**

- Android devices without guaranteed FDE (API < 26, or devices with FDE disabled, or rooted devices) have an unencrypted database containing all household financial data.
- Risk rated Medium in the Security Threat Model (T-02).
- Post-Phase-2 adoption of SQLCipher requires a database migration path that opens the plaintext file, re-encrypts it, and replaces it — requiring careful implementation and testing.

**Impact of adopting from Phase 2 (Option B):**

| Concern | Details |
|---|---|
| **Driver selection** | Replace `NativeDatabase.createInBackground` with the SQLCipher-backed equivalent from `sqlcipher_flutter_libs`. This must be decided before any table is defined. |
| **Secure key storage** | The database encryption key must be stored in `flutter_secure_storage`. Key derivation from PIN or biometric must be designed. |
| **PIN and biometric integration** | If the database key is wrapped with the PIN-derived key, a PIN change requires re-encrypting the key wrapper (not the whole database). This integration must be designed before Phase 2 begins. |
| **Migration** | V1 has no prior database. Migration from plaintext to encrypted is not needed if SQLCipher is adopted from Phase 2. If Option A is chosen and later changed, a migration path must be written and tested. |
| **Backup and restore** | Backup export must read from the encrypted database (normal Drift API works transparently with SQLCipher once opened with the key). Restore must open an encrypted database with the correct key before applying imported data. |
| **Key rotation** | If the user changes their PIN, the key wrapper is re-derived. Key rotation plan must be documented. |
| **Lost-key recovery** | If the encryption key is lost (e.g., device wipe clears secure storage), the database cannot be opened. The only recovery path is restore from backup. This must be disclosed to users. |
| **Testing** | Integration tests that use `NativeDatabase.memory()` (in-memory SQLite) do not use SQLCipher. This is acceptable for unit and integration tests. On-device tests are required to verify the encrypted database opens correctly. |
| **Android configuration** | `sqlcipher_flutter_libs` requires adding the SQLCipher AAR to the Android build. ProGuard rules may need updating. |
| **iOS configuration** | SQLCipher for iOS is included as a CocoaPod. The Podfile must be updated. |

**Recommendation:** Option B (SQLCipher from Phase 2) is preferred for a financial application. The integration effort is well-understood and the `sqlcipher_flutter_libs` package is production-tested with Drift. A platform spike (create a minimal test project with encrypted Drift on both Android and iOS) should be performed as the first task of Phase 1 to confirm the dependency works in the target environment before committing.

**Required decision from product owner:**
1. Which option (A or B)?
2. If B: what is the key derivation strategy (PIN-derived, device key only, or both)?
3. What is the lost-key recovery disclosure policy for users?

---

## DECISION-005 — Multi-Currency Support

**Status:** Accepted (deferred to v2)

**Context:** Should the app support multiple currencies within a single household?

**Decision:** v1 supports one base currency per household (EGP by default). The data model is designed with `currencyCode` on every account and ledger entry to support future multi-currency. Cross-currency transfers will require an explicit exchange rate record.

**Consequences:** No currency conversion logic in v1. All operations assume the same currency.

---

## DECISION-006 — Spouse Separate Login

**Status:** Accepted (deferred to v2)

**Context:** Should the spouse have a separate app login?

**Decision:** v1 is single-user only. The primary user manages all records on behalf of the household. Spouse login is explicitly deferred to v2.

**Consequences:** All spouse operations are recorded by the primary user. Spouse cannot independently add her own expenses in v1.

---

## DECISION-007 — Gold Price API

**Status:** Accepted (deferred to v2)

**Context:** Should the app automatically fetch live gold prices?

**Decision:** v1 requires manual gold price updates by the user. No external API dependency.

**Consequences:** Gold unrealized gain/loss is only as accurate as the user's last manual price update.

---

## DECISION-008 — AI Provider

**Status:** Open — requires product decision

**Context:** Which AI provider should be used for the voice-assisted transaction entry feature?

**Options:**

1. **Google Gemini** — Good Arabic support; Google ecosystem.
2. **OpenAI GPT-4o** — Excellent Arabic; most widely supported.
3. **Anthropic Claude** — Strong instruction following; Arabic support improving.
4. **On-device model (e.g., Gemma)** — Privacy-first; no network required; limited Arabic capability.

**Constraints:**

- API key must never be in the mobile app.
- All calls must go through a server-side proxy (Firebase Cloud Function).
- Arabic language quality is critical.
- Response latency < 3 seconds is preferred.

**Required decision:** Which AI provider to use for the v1 prototype. Recommendation: OpenAI GPT-4o for best Arabic quality, with Google Gemini as fallback if Google ecosystem is preferred.

---

## DECISION-009 — Navigation Library

**Status:** Accepted

**Decision:** GoRouter with `go_router_builder` for typed routes.

**Rejected:** Navigator 2.0 (too complex without a library); `auto_route` (additional complexity not needed).

---

## DECISION-010 — Chart Library

**Status:** Accepted

**Decision:** `fl_chart` for all charts (net worth trend, spending breakdown, cash flow).

**Rationale:** Actively maintained, supports RTL via axis configuration, no complex licensing, pure Dart.

**Consequences:** Charts require manual RTL axis configuration. Chart accessibility labels must be added manually.

---

## DECISION-011 — Backup File Format

**Status:** Accepted (approach decided, format details open)

**Decision:** Backup files are encrypted JSON (AES-256-GCM) with a PBKDF2-derived key from the user's backup password.

**Format:**

```
fmm_backup_YYYYMMDD.fmmbak
├── Header (plaintext): { version, createdAt, sha256OfEncryptedContent }
└── Encrypted body: { manifest, households, accounts, ledgerEntries, operations, ... }
```

**Open:** Should backups be signed with a device-specific key in addition to the user password? This would prevent backup files from being imported on other devices without the device key. Deferred to v2.

---

## DECISION-012 — Firebase App Check

**Status:** Open — requires environment decision

**Context:** Firebase App Check prevents unauthorized apps from accessing Firestore.

**Options:**

1. **Enable in v1:** Requires Play Integrity API (Android) and App Attest (iOS). Adds complexity.
2. **Defer to v2:** Security rules alone provide access control. App Check adds a second layer.

**Recommendation:** Enable in Phase 12 (Hardening). Without App Check, Firestore rules alone are the security gate.

---

## DECISION-013 — Notification Strategy

**Status:** Accepted

**Decision:** Local notifications only for v1. Push notifications (Firebase Cloud Messaging) deferred to v2.

**Capabilities in v1:**

- Budget warning notifications (local)
- Recurring transaction reminders (local)
- Upcoming bill reminders (local)
- Sync conflict notifications (local)

**Consequences:** Notifications only work when the app is installed and the scheduled notification fires on-device.

---

## DECISION-014 — Zakat Nisab Value Source

**Status:** Open — requires product decision

**Context:** The nisab value (threshold for zakat obligation) changes with gold/silver prices. Should the app:

**Options:**

1. **Manual entry:** User enters the nisab value manually each calculation.
2. **Hardcoded default:** App provides a suggested nisab value that the user can override.
3. **External API:** Fetch current nisab from an Islamic finance API (v2 option).

**Decision for v1:** User manually enters the nisab value. The app provides guidance text explaining what nisab is and where to find the current value (e.g., "consult your local fatwa authority or Islamic bank").

**Rationale:** Religious values should not be automatically applied without the user's deliberate choice.

---

## DECISION-015 — Receipt Storage

**Status:** Open — requires product decision

**Context:** Should receipt photos be:

**Options:**

1. **Local device only:** Stored in the app's private directory. Not synced to cloud. Lost on device wipe.
2. **Firebase Storage:** Uploaded to Firebase Storage. Synced across devices. Cost per GB.
3. **Omit in v1:** Receipt field is for future use.

**Recommendation:** Local device storage in v1. Path recorded in `operations.receipt_path`. Firebase Storage sync deferred to v2.

**Required decision:** Confirm v1 approach.

---

## Summary of Open Decisions Requiring Confirmation

| #            | Decision                  | Impact                  | Urgency         |
| ------------ | ------------------------- | ----------------------- | --------------- |
| DECISION-004 | SQLCipher: include in v1? | Security/driver/backup | **Before Phase 2** (blocker) |
| DECISION-008 | AI provider               | Phase 10 implementation | Before Phase 10 |
| DECISION-012 | Firebase App Check in v1? | Security                | Before Phase 12 |
| DECISION-014 | Nisab value source        | Zakat UX                | Before Phase 9  |
| DECISION-015 | Receipt storage strategy  | Data/cost               | Before Phase 4  |
