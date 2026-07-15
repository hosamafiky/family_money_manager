# Phase 1 Report — Project Foundation (Verification Pass)

**Date:** 2026-07-15  
**Branch:** `main`  
**HEAD after verification pass:** `e3c3f82`  
**Flutter:** 3.44.4 (stable) · **Dart:** 3.12.2 (stable, macos\_arm64)  
**Validation commands run against:** working tree as of `e3c3f82` (clean after commit)

---

## Part A — Repository State

### A.1 Target project

```
pwd:    /Users/hussam/Desktop/hussam/family_money_manager
branch: main
HEAD:   e3c3f82  Phase 1 verification corrections
status: clean (no uncommitted changes after verification commit)
```

**git log (last 5):**
```
e3c3f82 Phase 1 verification corrections
699e77d docs: add Phase 1 report
915f2d4 Phase 1: project foundation
aeb5d43 Phase 0: planning documents
e7bc47b docs: add Phase 0 planning documents
```

**All Dart source files (committed at HEAD):**
```
lib/app/app.dart
lib/app/app_config.dart
lib/app/app_providers.dart
lib/app/app_router.dart
lib/app/app_theme.dart
lib/core/error/app_error.dart
lib/core/localization/app_localizations.dart          ← generated
lib/core/localization/app_localizations_ar.dart       ← generated
lib/core/localization/app_localizations_en.dart       ← generated
lib/core/localization/l10n/app_ar.arb
lib/core/localization/l10n/app_en.arb
lib/core/logging/log_level.dart
lib/core/logging/log_sink.dart
lib/core/logging/redacted_logger.dart
lib/core/navigation/app_route.dart
lib/core/utils/result.dart
lib/features/smoke_screen/smoke_screen.dart
lib/main.dart
test/helpers/test_helpers.dart
test/unit/app/app_config_test.dart
test/unit/core/error/app_error_test.dart
test/unit/core/logging/redacted_logger_test.dart
test/unit/core/navigation/app_route_test.dart
test/widget/app/app_test.dart
test/widget/features/smoke_screen/smoke_screen_test.dart
```

**Generated files:** `app_localizations.dart`, `app_localizations_ar.dart`, `app_localizations_en.dart`  
Status: committed. Regenerated during CI via `flutter gen-l10n`; the committed copies are identical to generated output. Excluding from analysis via `analysis_options.yaml` (`exclude: ["lib/core/localization/app_localizations*.dart"]`).

### A.2 Reference-project state

| Repository | Branch | HEAD | Status |
|---|---|---|---|
| `money_tracker` | `main` | `f1d7e789` | Clean — no uncommitted changes |
| `money_tracker_next` | — | — | Ignored per product-owner instruction |

Neither reference project was read, modified, staged, committed, or built during this pass.

---

## Part B — Scope Compliance Scan

Exact commands run:

```bash
rg -l "Account|Transaction|Transfer|LedgerEntry|Balance|minorUnit|minor_unit" lib/ test/ pubspec.yaml
rg -l "drift|sqlite|sqlcipher|sqflite" lib/ test/ pubspec.yaml
rg -l "firebase|firestore|cloud_firestore|firebase_auth" lib/ test/ pubspec.yaml
rg -l "local_auth|pin_code|biometric|flutter_secure_storage" lib/ test/ pubspec.yaml
rg -l "speech_to_text|gemini|openai|langchain|voice" lib/ test/ pubspec.yaml
rg "dashboard|accounts|ledger|wallet|transaction" lib/ test/
```

**All commands produced zero results.** No prohibited Phase 2 content exists in `lib/`, `test/`, or `pubspec.yaml`.

| Category | Search terms | Result |
|---|---|---|
| Money / minor-unit arithmetic | Account, Transaction, Transfer, LedgerEntry, Balance, minorUnit | Not found |
| Database packages | drift, sqlite, sqlcipher, sqflite | Not found |
| Firebase / Firestore | firebase, firestore, cloud_firestore, firebase_auth | Not found |
| Auth / PIN / biometrics | local_auth, pin_code, biometric, flutter_secure_storage | Not found |
| AI / voice | speech_to_text, gemini, openai, langchain, voice | Not found |
| Financial routes | dashboard, accounts, ledger, wallet, transaction | Not found |

---

## Part C — Foundation Implementation

### C.1 Dependencies

**Direct dependencies (`pubspec.yaml`):**

| Package | Constraint | Resolved | Role |
|---|---|---|---|
| `flutter` (SDK) | — | 3.44.4 | Application framework |
| `flutter_localizations` (SDK) | — | SDK | Localisation delegates |
| `flutter_riverpod` | `^3.3.2` | 3.3.2 | State management and dependency injection |
| `go_router` | `^17.3.0` | 17.3.0 | Typed navigation |
| `intl` | `any` | 0.20.2 | Constrained by `flutter_localizations` |

**Dev dependencies:**

| Package | Constraint | Resolved | Role |
|---|---|---|---|
| `flutter_test` (SDK) | — | SDK | Test framework |
| `flutter_lints` | `^6.0.0` | 6.0.0 | Lint rules |

**No redundant packages.** No second state-management, DI, navigation, database, or logging library is present.

### C.2 Typed Navigation

**Package:** `go_router 17.3.0`

**Route declaration** (`lib/core/navigation/app_route.dart`):

```dart
sealed class AppRoute {
  const AppRoute();
  String get path;
  void go(BuildContext context) => GoRouter.of(context).go(path);
  void push(BuildContext context) => GoRouter.of(context).push<void>(path);
}

final class SmokeRoute extends AppRoute {
  const SmokeRoute();
  @override
  String get path => '/';
}
```

**Router wiring** (`lib/app/app_router.dart`):

```dart
GoRouter(
  initialLocation: const SmokeRoute().path,
  errorBuilder: (context, state) => AppErrorScreen(error: state.error),
  routes: [
    GoRoute(
      path: const SmokeRoute().path,
      builder: (context, state) => const SmokeScreen(),
    ),
  ],
)
```

**Compile-time typed navigation call:** `const SmokeRoute().go(context)` — adding a string to this call site does not compile; a new `AppRoute` subclass is required.

**No generated typed route files** — GoRouter's `@TypedGoRoute` generator is not used in Phase 1. The sealed class approach provides compile-time type safety without `build_runner`. Code generation is appropriate when route parameters exist (Phase 2+).

**Unknown-route behaviour:** `AppErrorScreen` shown by `errorBuilder`. Widget-tested.

**Correction applied:** `route_paths.dart` (string constants only — did not satisfy typed navigation) deleted and replaced by `app_route.dart`.

### C.3 Environment Configuration

Three compile-time constants exist in `lib/app/app_config.dart`:

| Constant | `isProduction` | Identifies as |
|---|---|---|
| `AppConfig.production` | `true` | App Store / Play Store builds |
| `AppConfig.staging` | `false` | UAT / internal builds |
| `AppConfig.development` | `false` | Developer machines |

All three are `const` (compile-time). `main.dart` selects `AppConfig.development`. Switching to `production` or `staging` requires changing one line — or a `--dart-define`-based wrapper can be added in Phase 2+ without changing the `AppConfig` class.

`validate()` throws `StateError` on blank `appName`, `appNameAr`, `packageName`, `currencyCode`. Called at startup before `runApp`.

**No embedded secrets.** Only display name, currency code, locale, and package name are stored.

**Test overrides:** `appConfigProvider.overrideWithValue(AppConfig.development)` used in all widget tests.

### C.4 Riverpod and DI

| Provider | Type | Initial state | Change API |
|---|---|---|---|
| `appConfigProvider` | `Provider<AppConfig>` | Must be overridden (throws `UnimplementedError` if not) | Overridden at `ProviderScope` root |
| `appLocaleProvider` | `NotifierProvider<LocaleNotifier, Locale>` | `AppConfig.defaultLocale` (`ar_EG`) | `ref.read(appLocaleProvider.notifier).setLocale(locale)` |
| `appThemeModeProvider` | `NotifierProvider<ThemeModeNotifier, ThemeMode>` | `ThemeMode.system` | `ref.read(appThemeModeProvider.notifier).setThemeMode(mode)` |

**Root container:** `ProviderScope` wraps `App` in `main.dart` and in every widget test via `buildTestApp()`.

**No second DI framework.** `get_it`, `injectable`, `provider`, `bloc`, `service_locator` are absent from `pubspec.yaml` and from all source files.

**Test override mechanism:** `_FixedLocaleNotifier` and `_FixedThemeModeNotifier` subclass the real notifiers, overriding `build()` to return a fixed value. Tested in `app_test.dart`.

### C.5 Error Hierarchy

`lib/core/error/app_error.dart`:

- `sealed class AppError` — no `BuildContext`, no Flutter widget import
- Variants: `NetworkError` (optional HTTP code), `AuthError`, `StorageError`, `UnknownError`
- Each variant exposes `localizationKey` (opaque string, e.g. `'errorNetwork'`) — never rendered raw
- `resolveErrorMessage(error, localizedMessage: (key) => ...)` — no Flutter import, maps key to translated string via injected function
- No Firebase-specific, database-specific, or financial behaviour in any variant

**Unit-tested:** 7 tests in `app_error_test.dart`.

### C.6 Logging

**Call path:**  
`RedactedLogger` (public API) → `_sanitize` / `_redact` (internal) → `LogSink.write` → `DebugPrintSink.debugPrint` (default) or `TestLogSink.records` (tests)

**Typed API (Phase 1 operations accepted):**

| Method | Parameters | Level | Notes |
|---|---|---|---|
| `logOperation` | `operationType: String`, `operationId: String` | INFO | No amounts, account names, balances |
| `logNavigation` | `routeName: String` | DEBUG | Route name only |
| `logLifecycle` | `event: String` | INFO | Lifecycle event names only |
| `warning` | `message: String` | WARNING | Passive redaction applied |
| `error` | `errorCode: String` | ERROR | Opaque code only — no exception object |

**No Map, Object, or payload parameter exists in the API.** Nested maps, lists, exception objects, stack traces, backup bodies, and AI response bodies cannot enter `RedactedLogger` by design. No regex pattern is required for those cases.

**Passive scanner patterns (applied in `warning()` only):**

| Pattern | Replacement |
|---|---|
| `[\d,]+\.?\d* EGP`, `EGP [\d,]+`, Arabic currency | `[AMOUNT_REDACTED]` |
| `Bearer <token>` | `Bearer [TOKEN_REDACTED]` |
| `balance: <number>` | `balance:[BALANCE_REDACTED]` |
| `transaction: <number>` | `transaction:[AMOUNT_REDACTED]` |
| `child_fund: <number>`, `child fund <number>` | `child_fund:[AMOUNT_REDACTED]` |
| `\n`, `\r` | ` ` (log injection prevention) |

**Scope note:** This class only protects data that flows through it. `print`, `debugPrint`, and direct crash-reporter calls receive no protection. See `SECURITY_THREAT_MODEL.md` T-07.

**Direct sink access:** `LogSink` is an interface. `DebugPrintSink` is the default. Nothing prevents a caller from constructing a `DebugPrintSink` directly and writing unredacted content. This is a caller discipline constraint, not a technical impossibility — documented, not claimed to be prevented.

### C.7 Localization, Theme, and Accessibility

| Requirement | Implementation | Test status |
|---|---|---|
| Arabic availability | `app_ar.arb` + generated delegate | Widget-tested |
| English availability | `app_en.arb` + generated delegate | Widget-tested |
| Arabic as default | `AppConfig.defaultLocale = Locale('ar', 'EG')` | Unit-tested |
| Arabic RTL | `MaterialApp` delegates set `textDirection: rtl` for `ar` | Widget-tested |
| English LTR | `MaterialApp` delegates set `textDirection: ltr` for `en` | Widget-tested |
| Locale switching | `appLocaleProvider.notifier.setLocale()` | Widget-tested (toggle buttons) |
| Light theme | `AppTheme.light()` — Material 3, seed `#1A6B3C` | Widget-tested |
| Dark theme | `AppTheme.dark()` — inverted brightness | Widget-tested |
| Large text scaling (1.5×) | `SmokeScreen` scrollable, no overflow | Widget-tested |
| Minimum touch targets (48pt) | `ElevatedButton` and `OutlinedButton` `minimumSize: Size(0, 48)` | Widget-tested |
| Semantics — language toggles | `OutlinedButton` derives label from `Text` child | Widget-tested |
| Semantics — theme toggles | `OutlinedButton` derives label from `Text` child | Widget-tested |
| Reduced motion | No custom animations in Phase 1 — Flutter respects system setting via `AccessibilityFeatures` | Unverified (N/A for Phase 1) |
| No translated text as identifiers | `foundationDirectionRtl` / `foundationDirectionLtr` used only for display; route paths use `SmokeRoute().path = '/'` | Code review |

**Smoke screen financial-content check:** widget test scans all `Text` widgets and asserts no `EGP` and no numeric strings ≥ 3 digits.

### C.8 CI Workflow

File: `.github/workflows/ci.yml`

| Step | Configuration | Notes |
|---|---|---|
| Trigger | `push`/`pull_request` to `main`, `develop` | — |
| Runner | `ubuntu-latest` | iOS build not possible on ubuntu; documented below |
| Flutter version | `flutter-version: "3.44.4"` | Explicit pin — build is reproducible |
| Pub cache | `actions/cache@v4` on `~/.pub-cache` keyed to `pubspec.lock` hash | — |
| Dependency restore | `flutter pub get` | — |
| Code generation | `flutter gen-l10n` | Regenerates localizations; CI fails if ARB changes are not reflected |
| Format | `dart format --output=none --set-exit-if-changed .` | Exact required command |
| Analyze | `flutter analyze --fatal-infos` | Stricter than required (`--fatal-infos` fails on infos, not just warnings) |
| Tests | `flutter test --coverage` | Coverage report produced |
| Android debug | `flutter build apk --debug` | Validates Android toolchain |
| Android release | `flutter build apk --release` | Validates R8/ProGuard |

**iOS build:** Not present in the workflow. `ubuntu-latest` cannot build for iOS. A macOS runner step (`flutter build ios --no-codesign`) should be added when a macOS GitHub Actions runner is provisioned. Currently verified only on developer machine.

**Remote CI execution:** The workflow has not executed remotely. This project has no GitHub remote. All CI steps are documented/configured. The workflow file is a locally-verified specification only until a remote run succeeds.

---

## Part D — Validation Commands

All commands run against working tree HEAD `e3c3f82` (clean).

| Command | Exit code | Relevant output |
|---|---|---|
| `dart format --output=none --set-exit-if-changed .` | **0** | `23 files (0 changed)` |
| `flutter analyze` | **0** | `No issues found! (ran in 1.3s)` |
| `flutter test` | **0** | `81 tests passed` |
| `flutter build apk --debug` | **0** | `✓ Built build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build apk --release` | **0** | `✓ Built build/app/outputs/flutter-apk/app-release.apk (47.3MB)` |
| `flutter build appbundle --release` | **0** | `✓ Built build/app/outputs/bundle/release/app-release.aab (46.9MB)` |
| `flutter build ios --debug --no-codesign` | **0** | `✓ Built build/ios/iphoneos/Runner.app` |
| `flutter build ios --release --no-codesign` | **0** | `✓ Built build/ios/iphoneos/Runner.app (15.5MB)` |

**Source files changed during any command:** `dart format` changed 4 files during the auto-format pass before verification; the subsequent `--set-exit-if-changed` run produced 0 changes. No other command modified source files.

**Warning in release APK build:**
```
Expected to find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons),
but found (MaterialIcons).
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 1524 bytes.
```
This is a tree-shaking info message, not an error. `cupertino_icons` is not declared as a dependency, so its font is absent — expected for a Material-only UI.

---

## Part E — Test Traceability Matrix

### E.1 Test files and groups

| File | Group | Tests | Classification |
|---|---|---|---|
| `app_config_test.dart` | `production config` | 5 | Unit-tested |
| | `staging config` | 4 | Unit-tested |
| | `development config` | 2 | Unit-tested |
| | `validate() rejects invalid configs` | 4 | Unit-tested |
| `app_error_test.dart` | `localizationKey` | 5 | Unit-tested |
| | `resolveErrorMessage` | 2 | Unit-tested |
| `redacted_logger_test.dart` | `allowlisting` | 7 | Unit-tested |
| | `sensitive-pattern masking` | 6 | Unit-tested |
| | `log injection prevention` | 2 | Unit-tested |
| | `logLifecycle` | 4 | Unit-tested |
| | `financial keyword masking` | 4 | Unit-tested |
| | `typed API prevents unstructured metadata` | 3 | Unit-tested |
| `app_route_test.dart` | `SmokeRoute` | 4 | Unit-tested |
| `app_test.dart` | `startup smoke test` | 3 | Widget-tested |
| | `locale and directionality` | 2 | Widget-tested |
| | `localization availability` | 2 | Widget-tested |
| | `theme` | 2 | Widget-tested |
| | `unknown route (AppErrorScreen)` | 3 | Widget-tested |
| | `Riverpod overrides` | 2 | Widget-tested |
| `smoke_screen_test.dart` | `SmokeScreen — English` | 10 | Widget-tested |
| | `SmokeScreen — Arabic RTL` | 3 | Widget-tested |
| | `SmokeScreen — touch targets` | 1 | Widget-tested |

**Total: 81 tests**

### E.2 Behavior coverage

| Required behaviour | Test(s) | Classification |
|---|---|---|
| Configuration validation | `AppConfig validate() rejects invalid configs` (4 tests) | Unit-tested |
| Arabic localization | `Arabic localization is available`, `displays Arabic app title`, `SmokeScreen — Arabic RTL shows Arabic app title` | Widget-tested |
| English localization | `English localization is available`, `displays English app title`, `SmokeScreen — English shows English app title` | Widget-tested |
| RTL | `Arabic locale produces RTL directionality`, `SmokeScreen — Arabic RTL shows RTL direction label` | Widget-tested |
| LTR | `English locale produces LTR directionality`, `SmokeScreen — English shows LTR direction label` | Widget-tested |
| Initial typed route | `SmokeRoute path is the application root`, `AppRouter.create() initialises without error` | Unit + Widget-tested |
| Known route behaviour | `renders without error with development config` (smoke screen loads at `/`) | Widget-tested |
| Unknown route behaviour | `AppErrorScreen renders error icon and back button`, `displays error message when exception provided` | Widget-tested |
| Riverpod overrides | `appConfigProvider override is respected`, `locale override drives displayed language` | Widget-tested |
| Theme availability | `light theme is applied when ThemeMode.light`, `dark theme is applied when ThemeMode.dark` | Widget-tested |
| Text scaling | `does not overflow at default text scale`, `does not overflow at 1.5x text scale` | Widget-tested |
| Touch targets | `language toggle buttons meet 48-pt minimum touch target` | Widget-tested |
| Semantics | `language toggle buttons have non-empty semantics labels`, `theme toggle buttons have non-empty semantics labels` | Widget-tested |
| Reduced motion | No custom animations in Phase 1 — not applicable | Unverified (N/A) |
| Logger allowlisting | `logOperation emits a record` + level/content checks (7 tests) | Unit-tested |
| Logger prohibited-field handling | `transaction keyword with number is masked`, `child_fund keyword`, `balance keyword`, `EGP amounts`, `Bearer token`, `typed API prevents unstructured metadata` (13 tests) | Unit-tested |
| Safe error localization | `resolveErrorMessage` tests; `localizationKey` returns non-empty key for all variants | Unit-tested |
| Startup smoke behaviour | `renders without error with development config`, `Arabic/English title`, `no financial amounts` | Widget-tested |

---

## Part F — DECISION-004 Assessment Summary

Full assessment: `docs/DECISION_004_ASSESSMENT.md`

### Key findings

1. **`sqlite3_flutter_libs 0.6.0+eol`** — the previously standard Flutter SQLite native library is explicitly end-of-life.
2. **`sqlcipher_flutter_libs 0.7.0+eol`** — the previously recommended SQLCipher package is explicitly end-of-life.
3. **`drift_flutter 0.3.1`** — the maintained replacement for both EOL packages. Compilation-verified: `drift 2.34.2` + `drift_flutter 0.3.1` + `drift_dev 2.34.4` resolve, code-generate cleanly, and `flutter analyze` reports zero issues.
4. **`sqflite_sqlcipher 3.4.0`** — resolves alongside `drift 2.34.2` but the integration path (using it as a Drift QueryExecutor backend) is **unconfirmed** and requires a Phase 1.5 spike.
5. **Custom SQLCipher native asset** (Option C) — not recommended for V1 due to high build complexity.

### Product-owner decisions required

| ID | Decision | Options |
|---|---|---|
| PO-1 | Encryption required in V1? | Yes / No |
| PO-2 | Key protection model | Device keychain only / PIN-derived + device keychain |
| PO-3 | Lost-key policy | Accept full data loss / Require cloud backup with backup key |
| PO-4 | Backup file encryption policy | Same key / Separate passphrase / Unencrypted |

**Phase 2 must not begin until PO-1 through PO-4 are answered.**

---

## Part G — Reference-Project Evidence (Postflight)

Checked at end of verification pass:

| Repository | Branch | HEAD | Status |
|---|---|---|---|
| `money_tracker` | `main` | `f1d7e789` | Unchanged from preflight |

No files were modified in `money_tracker` during this pass.

---

## Part H — Corrections Applied in This Pass

| Area | Correction | Commit |
|---|---|---|
| Typed navigation | Deleted `route_paths.dart` (string constants); created `app_route.dart` (sealed `AppRoute` hierarchy, `SmokeRoute`) | `e3c3f82` |
| Environment config | Added `AppConfig.staging`, `appNameAr` field, validation for both new fields | `e3c3f82` |
| Logger | Added `logLifecycle()` method; added `transaction` and `child_fund` passive masking patterns; documented backup/AI scope | `e3c3f82` |
| Tests — AppConfig | Added staging config tests (4), validate()-rejection tests for `appNameAr` and `packageName` | `e3c3f82` |
| Tests — logger | Added `logLifecycle` (4), financial keyword masking (4), typed API constraint + backup doc (3) | `e3c3f82` |
| Tests — navigation | New `app_route_test.dart`: path value, subtype assertion, no financial segments | `e3c3f82` |
| Tests — App widget | Added unknown-route / `AppErrorScreen` tests (3), Riverpod overrides test | `e3c3f82` |
| Tests — SmokeScreen | Added 1.5× text scale, semantics (language + theme), touch target (48pt) | `e3c3f82` |
| CI | Pinned `flutter-version: 3.44.4`; added release APK step; added `flutter gen-l10n` step | `e3c3f82` |
| DECISION-004 | Created `docs/DECISION_004_ASSESSMENT.md` with full option analysis and product-owner choices | — |
| Spike | `spike/db_options/`: `drift_flutter` compilation verified, `build_runner` generates code cleanly | — |

---

## Part I — Claim Classification

| Claim | Classification |
|---|---|
| `dart format` — 0 changes | Build-verified |
| `flutter analyze` — 0 issues | Build-verified |
| 81/81 tests pass | Unit-tested + Widget-tested |
| Android debug APK builds | Build-verified |
| Android release APK builds (47.3 MB) | Build-verified |
| Android App Bundle builds (46.9 MB) | Build-verified |
| iOS debug app builds | Build-verified |
| iOS release app builds (15.5 MB) | Build-verified |
| Scope scan — no Phase 2 content | Build-verified (rg search, 0 results) |
| `drift_flutter 0.3.1` resolves and compiles | Build-verified (spike) |
| `sqlite3_flutter_libs` EOL | Documented only (pub.dev version string) |
| `sqlcipher_flutter_libs` EOL | Documented only (pub.dev version string) |
| `sqflite_sqlcipher` + Drift integration | Unverified — resolution only, not compilation-tested |
| CI remote execution | Unverified — no GitHub remote exists |
| iOS on CI (ubuntu) | Unverified — macOS runner not provisioned |
| Device or emulator runtime test | Unverified |

---

## Remaining Risks

| Risk | Severity | Mitigation |
|---|---|---|
| DECISION-004 unresolved | High | Product owner answers PO-1..PO-4 before Phase 2 |
| `sqflite_sqlcipher` + Drift 2.x integration unconfirmed | Medium | Phase 1.5 spike if PO-1 = Yes |
| CI not executed remotely | Low | Add GitHub remote; first push triggers workflow |
| iOS build not in CI | Low | Add macOS runner to CI after first working remote run |
| `DebugPrintSink` active in release | Low | Replace with null sink or crash reporter in Phase 3 |
| `main.dart` hardcodes `AppConfig.development` | Low | Add `--dart-define=ENV` wrapper in Phase 2 |

---

## Stop

Phase 1 is verified and corrected. DECISION-004 assessment is documented.  
**Phase 2 must not begin until the product owner resolves DECISION-004 (PO-1 through PO-4).**
