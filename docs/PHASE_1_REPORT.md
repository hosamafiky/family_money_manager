# Phase 1 Report — Project Foundation

**Date:** 2026-07-15  
**Branch:** `main`  
**Commit:** `915f2d4`  
**Flutter:** 3.44.4 (stable, channel stable)  
**Dart SDK:** 3.12.2 (stable, macos_arm64)  

---

## 1. Scope Compliance

Phase 1 was limited to project foundation only. The following table confirms scope compliance.

| Category | Allowed | Implemented | Compliant |
|---|---|---|---|
| Flutter project scaffolding | Yes | Yes | Yes |
| Arabic-first localization (ARB + gen) | Yes | Yes | Yes |
| RTL / LTR directionality | Yes | Yes | Yes |
| Theme foundations (light/dark, Material 3) | Yes | Yes | Yes |
| Riverpod providers (locale, theme, config) | Yes | Yes | Yes |
| GoRouter typed navigation | Yes | Yes | Yes |
| Domain-neutral error model | Yes | Yes | Yes |
| Redacted logger | Yes | Yes | Yes |
| Result<T> type | Yes | Yes | Yes |
| Smoke screen (no financial data) | Yes | Yes | Yes |
| CI workflow (GitHub Actions) | Yes | Yes | Yes |
| Financial logic | Forbidden | Not present | Yes |
| Authentication | Forbidden | Not present | Yes |
| Firestore sync | Forbidden | Not present | Yes |
| Database driver / SQLite / SQLCipher | Forbidden | Not present | Yes |
| PIN / biometrics | Forbidden | Not present | Yes |
| AI / voice | Forbidden | Not present | Yes |
| Feature dashboards | Forbidden | Not present | Yes |
| Seed financial data | Forbidden | Not present | Yes |

---

## 2. Project Identifiers

| Field | Value |
|---|---|
| Dart package name | `family_money_manager` |
| Android application ID | `com.familymoney.manager` |
| iOS bundle identifier | `com.familymoney.manager` |
| Display name | `Family Money Manager` |
| Default locale | `ar_EG` |
| Currency code | `EGP` |
| Supported locales | `ar`, `en` |

---

## 3. Files Created

### Application Source (`lib/`)

| File | Purpose |
|---|---|
| `lib/main.dart` | Entry point; bootstraps `AppConfig`, initialises `RedactedLogger`, mounts `ProviderScope` |
| `lib/app/app_config.dart` | Immutable config carrier (package name, display name, locale, currency, env flag); `validate()` throws `StateError` on blank values |
| `lib/app/app.dart` | Root `MaterialApp.router` widget; wires locale, theme, GoRouter |
| `lib/app/app_router.dart` | GoRouter with `RouteObserver`, single `/smoke-screen` route |
| `lib/app/app_theme.dart` | `ThemeData` for light and dark; IBM Plex Sans Arabic, Material 3 seed colour `0xFF1A5276` |
| `lib/app/app_providers.dart` | Riverpod providers: `appConfigProvider`, `localeProvider`, `themeModeProvider` |
| `lib/core/error/app_error.dart` | Sealed `AppError` hierarchy: `NetworkError`, `AuthError`, `StorageError`, `UnknownError`; `localizationKey` and `resolveErrorMessage` |
| `lib/core/utils/result.dart` | Generic `Result<T>` with `Ok` / `Err` variants |
| `lib/core/logging/log_level.dart` | `LogLevel` enum: `debug`, `info`, `warning`, `error` |
| `lib/core/logging/log_sink.dart` | `LogSink` abstract interface |
| `lib/core/logging/redacted_logger.dart` | `RedactedLogger` — allowlist operations, masks EGP amounts / Bearer tokens / balance keywords, sanitises log injection (CRLF replacement) |
| `lib/core/navigation/route_paths.dart` | `RoutePaths` constants |
| `lib/core/localization/l10n/app_en.arb` | English ARB resource file |
| `lib/core/localization/l10n/app_ar.arb` | Arabic ARB resource file |
| `lib/core/localization/app_localizations.dart` | Generated `AppLocalizations` base class |
| `lib/core/localization/app_localizations_en.dart` | Generated English delegate |
| `lib/core/localization/app_localizations_ar.dart` | Generated Arabic delegate |
| `lib/features/smoke_screen/smoke_screen.dart` | Foundation screen with locale/theme toggles; asserts no financial content at test time |

### Tests (`test/`)

| File | Coverage |
|---|---|
| `test/helpers/test_helpers.dart` | Shared `buildTestApp` / `buildLocalizedWidget` helpers |
| `test/unit/app/app_config_test.dart` | Production config, development config, `validate()` rejection |
| `test/unit/core/error/app_error_test.dart` | `localizationKey` presence for all variants, `resolveErrorMessage` delegation |
| `test/unit/core/logging/redacted_logger_test.dart` | Allowlist emission (all levels), EGP/token/balance masking, log injection prevention |
| `test/widget/app/app_test.dart` | Startup smoke, Arabic/English title, RTL/LTR directionality, locale availability, light/dark theme application |
| `test/widget/features/smoke_screen/smoke_screen_test.dart` | English render, Arabic RTL render, no financial amounts, overflow at default text scale |

### Configuration

| File | Purpose |
|---|---|
| `pubspec.yaml` | Dependencies; `flutter: generate: true` |
| `l10n.yaml` | ARB config pointing to `lib/core/localization/l10n/` |
| `analysis_options.yaml` | `strict-casts`, `strict-inference`, `strict-raw-types`; generated files excluded |
| `.github/workflows/ci.yml` | Format check → Analyze → Test → Android debug build |
| `.gitignore` | Standard Flutter ignore rules |

---

## 4. Dependencies

| Package | Version constraint | Role |
|---|---|---|
| `flutter_riverpod` | `^3.3.2` | State management, dependency injection |
| `go_router` | `^17.3.0` | Typed navigation |
| `flutter_localizations` (SDK) | — | Localisation delegates |
| `intl` | `any` | Constrained by `flutter_localizations` |
| `flutter_lints` (dev) | `^6.0.0` | Lint rules |
| `flutter_test` (dev, SDK) | — | Test framework |

No native database driver has been added. DECISION-004 (SQLCipher) remains open and is required before Phase 2.

---

## 5. Architecture

```
lib/
├── main.dart                  ← entry point
├── app/
│   ├── app.dart               ← MaterialApp.router
│   ├── app_config.dart        ← configuration carrier
│   ├── app_providers.dart     ← Riverpod root providers
│   ├── app_router.dart        ← GoRouter
│   └── app_theme.dart         ← ThemeData (light/dark)
├── core/
│   ├── error/
│   │   └── app_error.dart     ← sealed error hierarchy
│   ├── localization/
│   │   ├── l10n/              ← ARB source files
│   │   ├── app_localizations.dart         (generated)
│   │   ├── app_localizations_ar.dart      (generated)
│   │   └── app_localizations_en.dart      (generated)
│   ├── logging/
│   │   ├── log_level.dart
│   │   ├── log_sink.dart
│   │   └── redacted_logger.dart
│   ├── navigation/
│   │   └── route_paths.dart
│   └── utils/
│       └── result.dart
└── features/
    └── smoke_screen/
        └── smoke_screen.dart  ← foundation-only screen
```

Layer dependency direction: `features` → `app` → `core`. No cross-layer reverse imports.  
No financial, authentication, database, or sync code exists anywhere in `lib/`.

---

## 6. Tests

| Suite | Count | Result |
|---|---|---|
| Unit — AppConfig | 8 | Pass |
| Unit — AppError | 7 | Pass |
| Unit — RedactedLogger | 17 | Pass |
| Widget — App | 10 | Pass |
| Widget — SmokeScreen | 10 | Pass |
| **Total** | **52** | **All passed** |

Command: `flutter test` — exit code 0.

---

## 7. Validation Commands and Results

| Step | Command | Exit Code | Notes |
|---|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed .` | 0 | 22 files formatted, 0 changed after auto-format pass |
| Analyse | `flutter analyze --no-pub` | 0 | No issues found |
| Test | `flutter test` | 0 | 52 / 52 passed |
| Android debug APK | `flutter build apk --debug` | 0 | 144 MB (includes debug symbols) |
| Android release APK | `flutter build apk --release` | 0 | 47.3 MB |
| Android App Bundle | `flutter build appbundle --release` | 0 | 46.9 MB |
| iOS debug (no codesign) | `flutter build ios --debug --no-codesign` | 0 | Runner.app built |
| iOS release (no codesign) | `flutter build ios --release --no-codesign` | 0 | Runner.app (15.5 MB) |

---

## 8. Build Artifacts

| Artifact | Path | Size |
|---|---|---|
| Android debug APK | `build/app/outputs/flutter-apk/app-debug.apk` | 144 MB |
| Android release APK | `build/app/outputs/flutter-apk/app-release.apk` | 47.3 MB |
| Android App Bundle (release) | `build/app/outputs/bundle/release/app-release.aab` | 46.9 MB |
| iOS debug app | `build/ios/iphoneos/Runner.app` | — |
| iOS release app | `build/ios/iphoneos/Runner.app` | 15.5 MB |

---

## 9. Git State

```
Branch: main
Commits:
  915f2d4 Phase 1: project foundation         ← HEAD
  aeb5d43 Phase 0: planning documents
  e7bc47b docs: add Phase 0 planning documents

Working tree: clean (git status --short produces no output after commit)
```

---

## 10. Warnings

None. `flutter analyze` reported zero issues. `flutter test` reported zero failures. All build commands exited with code 0.

---

## 11. Open Decisions Carried Forward

| Decision | Status | Required by |
|---|---|---|
| DECISION-004: SQLCipher vs flutter_secure_storage vs plain SQLite | Open | Before Phase 2 begins |

No other decisions were resolved or deferred in Phase 1.

---

## 12. Claim Classification

All statements in this report are **implemented and verified** — every claim is backed by a command that completed with exit code 0 on this machine. No forward-looking or aspirational language is used.

---

## 13. Phase 1 Boundary Confirmation

Phase 1 is complete. Phase 2 (financial ledger) has not started and must not start until DECISION-004 is resolved.

The following are explicitly absent from the Phase 1 codebase:

- No `Account`, `Transaction`, `Entry`, `Ledger`, or `Balance` types
- No Firestore imports or configuration
- No SQLite or Drift imports
- No PIN or biometric authentication
- No seed financial data or test fixtures containing amounts
- No `firebase_*` packages in `pubspec.yaml`
