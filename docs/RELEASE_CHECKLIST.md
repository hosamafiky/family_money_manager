# Release Checklist

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## Pre-Release Gate (Every Phase)

These checks must pass before any code is considered complete for the phase:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-warnings
flutter test
```

And where applicable:

```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
flutter build ios --debug --no-codesign
flutter build ios --release --no-codesign
```

---

## Phase Gate Checklist

### Phase 1 (Foundation)

- [ ] Project creates and runs on Android emulator
- [ ] Project creates and runs on iOS simulator
- [ ] Arabic RTL renders correctly on both platforms
- [ ] English LTR renders correctly on both platforms
- [ ] Theme applied (colors, typography)
- [ ] GoRouter navigates between placeholder screens
- [ ] Riverpod providers initialize without error
- [ ] Drift database opens successfully
- [ ] RedactedLogger does not output financial amounts
- [ ] `flutter analyze` passes with zero warnings
- [ ] `dart format` passes
- [ ] `flutter test` passes

### Phase 2 (Financial Ledger)

- [ ] All financial invariant tests pass (see FINANCIAL_INVARIANTS.md)
- [ ] Money type: no double used for any persisted amount
- [ ] Transfer tests: source and destination balance sum unchanged
- [ ] Child fund withdrawal: rejected without audit
- [ ] Historical balance: correct at multiple date points
- [ ] Idempotency: duplicate operation ID rejected
- [ ] Net worth tests: all 9 scenarios in FINANCIAL_INVARIANTS.md INV-009

### Phase 3 (Household Model)

- [ ] Spouse wallet balance formula verified by tests
- [ ] Child fund protected withdrawal warning renders in Arabic
- [ ] Child fund audit: immutable (update/delete rejected)
- [ ] Expense scope correctly filters in reports

### Phase 4 (Core UI)

- [ ] Dashboard loads without error on both platforms
- [ ] Add income flow complete
- [ ] Add expense flow complete
- [ ] Transfer flow complete
- [ ] All amounts displayed in Arabic-Indic numerals in Arabic locale
- [ ] Privacy mode hides all amounts
- [ ] App switcher blur works on Android and iOS
- [ ] Offline indicator shown when connectivity lost

### Phase 5 (Budgets and Goals)

- [ ] Transfer not counted in budget spending
- [ ] Budget warning triggers at configured threshold
- [ ] Goal funding creates transfer to goal reserve

### Phase 6 (Banks, Certificates, Gold)

- [ ] Certificate principal not in bank balance simultaneously
- [ ] Gold weight stored as milligrams (integer)
- [ ] Making charges recorded as expense

### Phase 7 (Liabilities)

- [ ] Net worth = assets − liabilities verified in UI
- [ ] Repayment: principal and interest separated

### Phase 8 (Reports)

- [ ] Transfers excluded from all income/expense reports
- [ ] Arabic numerals in report figures

### Phase 9 (Zakat)

- [ ] Disclaimer displayed in Arabic and English
- [ ] Zakat not auto-calculated without user confirmation
- [ ] Sadaqah: linked expense not double-counted

### Phase 10 (Voice/AI)

- [ ] AI output treated as untrusted input (validated before display)
- [ ] AI confirmation required before any write
- [ ] App works identically with AI disabled
- [ ] No AI API key embedded in app binary

### Phase 11 (Security, Backup)

- [ ] PIN lock works: wrong PIN → backoff
- [ ] Biometric unlock works
- [ ] Auto-lock on background configured
- [ ] Backup file encrypted (cannot open without password)
- [ ] Restore requires PIN re-authentication
- [ ] Import: invalid schema version rejected

### Phase 12 (Hardening)

- [ ] Firebase Emulator rules tests: all pass
- [ ] Performance: dashboard loads < 500ms on mid-range device
- [ ] Accessibility: no semantic label violations
- [ ] RTL review: all screens correct in Arabic
- [ ] Dependency audit: no known CVEs in dependencies
- [ ] Android release build signed and testable
- [ ] iOS release build signed (TestFlight or AdHoc)
- [ ] Manual device test: Android (minimum API 26)
- [ ] Manual device test: iOS (minimum iOS 15)

---

## App Store Release Checklist

### Android (Google Play)

- [ ] App ID matches: `com.familymoney.manager`
- [ ] Version name and code set in `pubspec.yaml`
- [ ] App signing keystore configured (not committed to git)
- [ ] Minification enabled (ProGuard/R8)
- [ ] `FLAG_SECURE` set on the Activity (prevents screenshots)
- [ ] Internet permission declared (for sync)
- [ ] `USE_BIOMETRIC` permission declared
- [ ] All required permissions declared with purpose
- [ ] 64-bit APK included (arm64-v8a)
- [ ] Target SDK = latest stable
- [ ] App bundle (`.aab`) generated for Play submission
- [ ] Google Play data safety form completed (financial data, no ads tracking)
- [ ] Store listing: Arabic and English
- [ ] Screenshots: Arabic RTL and English LTR
- [ ] Privacy policy URL set

### iOS (App Store)

- [ ] Bundle ID matches: `com.familymoney.manager`
- [ ] Version and build number set
- [ ] Signing certificates and provisioning profiles configured
- [ ] `NSFaceIDUsageDescription` in Info.plist
- [ ] `NSCameraUsageDescription` in Info.plist (for receipt photos)
- [ ] Bitcode: N/A (Flutter projects do not use Bitcode)
- [ ] Export compliance: encryption used (answer yes, AES for backup)
- [ ] App Store listing: Arabic and English
- [ ] Screenshots: Arabic RTL and English LTR
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`)
- [ ] No private API usage

---

## Security Pre-Release

- [ ] `flutter_secure_storage`: PIN hash stored correctly
- [ ] No raw PIN in any log
- [ ] No balance in any log
- [ ] No auth token in any log
- [ ] Firestore rules deployed and tested
- [ ] Firebase App Check enabled (v2)
- [ ] No debug keys or test credentials in production build
- [ ] `.env` files excluded from git (`.gitignore` verified)
- [ ] Backup encryption key never logged

---

## Data Safety

- [ ] Privacy policy written and published
- [ ] Data collected: financial records (not shared with third parties)
- [ ] Data stored: locally + optionally on Firebase (user-controlled)
- [ ] Data not used for ads or analytics
- [ ] Firebase Analytics: disabled or configured with minimal data
- [ ] Crashlytics: disabled (financial apps should minimize third-party data collection) or enabled with explicit user consent

---

## Rollback Plan

- [ ] Version N-1 APK kept available for emergency rollback
- [ ] Firestore rules version-controlled in git
- [ ] Database migration is reversible (or migration rollback tested)
- [ ] Emergency: local-only mode available without cloud dependency
