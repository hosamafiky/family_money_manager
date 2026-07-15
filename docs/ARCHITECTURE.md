# Architecture

**Version:** 0.1.0-phase0  
**Date:** 2026-07-15

---

## 1. Architectural Goals

1. **Financial correctness is paramount.** The architecture must be designed to minimize the risk of accidentally bypassing financial invariants, even in the face of concurrent writes, offline operation, or future feature additions. No architecture eliminates all bypass risk; defense-in-depth is required.
2. **Feature-first organization.** Code is organized by feature domain, not by layer. Each feature is self-contained with its own domain, data, application, and presentation sub-layers.
3. **Domain independence.** Domain logic (financial calculations, invariant enforcement) must not depend on Flutter, Firebase, SQLite, or any external library.
4. **Testability.** Every financial calculation must be testable in pure Dart without any Flutter framework, any network, or any database.
5. **Offline-first.** Local SQLite is the primary database. Cloud sync is optional and additive.
6. **Security by design.** Sensitive operations require authentication. Data is encrypted at rest and in transit.
7. **Localization-first.** All user-visible strings go through the localization system. No hardcoded strings in UI code.

---

## 2. Dependency Graph (planned; to be enforced by code review, linter rules, and import restrictions)

```
presentation  →  application  →  domain
presentation  →  core/ui
application   →  core/database
application   →  core/sync
application   →  core/security
domain        →  (no dependencies; pure Dart only)
core          →  (each core module may depend on other core modules; no feature dependencies)
```

Forbidden:
- `domain` imports Flutter, Firebase, or SQLite
- `presentation` calls repository methods directly (must go through `application`)
- `application` returns database model objects to `presentation` (must map to domain or UI models)

---

## 3. Project Structure

```
family_money_manager/
  lib/
    app/
      app.dart                   // MaterialApp / root widget
      app_config.dart            // branding, package name, currency, locale
      app_theme.dart             // light/dark theme
      app_router.dart            // GoRouter configuration
    core/
      database/
        app_database.dart        // Drift database definition
        database_migrations.dart
        tables/                  // Drift table definitions (one file per table)
      financial/
        money.dart               // Money value type
        money_arithmetic.dart    // add, subtract, percentage calculations
        money_formatter.dart     // formatting for display (EGP, etc.)
        ledger_calculator.dart   // balance computation from ledger entries
        net_worth_calculator.dart
        zakat_calculator.dart
        gold_calculator.dart
      localization/
        app_localizations.dart   // generated
        l10n/
          app_ar.arb
          app_en.arb
      navigation/
        app_router.dart
        route_names.dart
        typed_routes.dart
      security/
        app_lock_service.dart
        biometric_service.dart
        pin_service.dart
        secure_storage_service.dart
        privacy_mode_notifier.dart
      sync/
        sync_queue.dart
        sync_service.dart
        firestore_sync_adapter.dart
        conflict_resolver.dart
        sync_status_notifier.dart
      ui/
        design_system/
          colors.dart
          typography.dart
          spacing.dart
          icons.dart
        widgets/
          money_display.dart
          account_card.dart
          loading_overlay.dart
          error_display.dart
          confirmation_dialog.dart
          protected_fund_warning_dialog.dart
      utils/
        date_utils.dart
        uuid_generator.dart
        logger.dart              // redacted logger
        validators.dart
        result.dart              // Result<T, E> type
    features/
      auth/
        domain/
          auth_repository.dart   // interface
        data/
          firebase_auth_repository.dart
        application/
          auth_notifier.dart
        presentation/
          login_screen.dart
          register_screen.dart
          password_reset_screen.dart
      onboarding/
        domain/
          onboarding_model.dart
        application/
          onboarding_notifier.dart
        presentation/
          onboarding_screen.dart
          language_step.dart
          household_step.dart
          accounts_step.dart
      dashboard/
        domain/
          dashboard_summary.dart
        application/
          dashboard_notifier.dart
        presentation/
          dashboard_screen.dart
          net_worth_card.dart
          account_summary_card.dart
          spending_summary_card.dart
          spouse_wallet_card.dart
          child_fund_card.dart
          recent_transactions_list.dart
      accounts/
        domain/
          financial_account.dart       // domain model
          account_repository.dart      // interface
        data/
          account_dao.dart
          account_repository_impl.dart
        application/
          accounts_notifier.dart
          account_balance_notifier.dart
        presentation/
          accounts_screen.dart
          account_detail_screen.dart
          add_account_screen.dart
          edit_account_screen.dart
      transactions/
        domain/
          operation.dart
          ledger_entry.dart
          income_request.dart
          expense_request.dart
          operation_repository.dart    // interface
        data/
          operation_dao.dart
          ledger_entry_dao.dart
          operation_repository_impl.dart
        application/
          add_income_notifier.dart
          add_expense_notifier.dart
          transactions_list_notifier.dart
        presentation/
          add_income_screen.dart
          add_expense_screen.dart
          transaction_detail_screen.dart
          transactions_list_screen.dart
      transfers/
        domain/
          transfer_request.dart
          transfer_result.dart
          transfer_repository.dart
        data/
          transfer_repository_impl.dart
        application/
          transfer_notifier.dart
        presentation/
          transfer_screen.dart
          transfer_detail_screen.dart
      household/
        domain/
          household.dart
          household_repository.dart
        data/
          household_repository_impl.dart
        application/
          household_notifier.dart
        presentation/
          household_screen.dart
          spouse_wallet_screen.dart
          household_expense_screen.dart
      members/
        domain/
          household_member.dart
        application/
          members_notifier.dart
        presentation/
          members_screen.dart
      budgets/
        domain/
          budget.dart
          budget_calculator.dart
          budget_repository.dart
        data/
          budget_repository_impl.dart
        application/
          budgets_notifier.dart
          budget_detail_notifier.dart
        presentation/
          budgets_screen.dart
          add_budget_screen.dart
          budget_detail_screen.dart
      goals/
        domain/
          goal.dart
          goal_repository.dart
        data/
          goal_repository_impl.dart
        application/
          goals_notifier.dart
          goal_funding_notifier.dart
        presentation/
          goals_screen.dart
          add_goal_screen.dart
          goal_detail_screen.dart
      savings/
        domain/
          savings_account.dart
        application/
          savings_notifier.dart
        presentation/
          savings_screen.dart
      gold/
        domain/
          gold_holding.dart
          gold_repository.dart
        data/
          gold_repository_impl.dart
        application/
          gold_notifier.dart
          buy_gold_notifier.dart
          sell_gold_notifier.dart
        presentation/
          gold_screen.dart
          buy_gold_screen.dart
          sell_gold_screen.dart
          gold_detail_screen.dart
      certificates/
        domain/
          certificate.dart
          certificate_repository.dart
        data/
          certificate_repository_impl.dart
        application/
          certificates_notifier.dart
          create_certificate_notifier.dart
        presentation/
          certificates_screen.dart
          create_certificate_screen.dart
          certificate_detail_screen.dart
      liabilities/
        domain/
          liability.dart
          liability_repository.dart
        data/
          liability_repository_impl.dart
        application/
          liabilities_notifier.dart
          repay_liability_notifier.dart
        presentation/
          liabilities_screen.dart
          add_liability_screen.dart
          repay_liability_screen.dart
          liability_detail_screen.dart
      net_worth/
        domain/
          net_worth_snapshot.dart
        application/
          net_worth_notifier.dart
        presentation/
          net_worth_screen.dart
          net_worth_breakdown.dart
          net_worth_history_chart.dart
      reports/
        domain/
          report_filter.dart
          report_result.dart
          report_repository.dart
        data/
          report_repository_impl.dart
        application/
          reports_notifier.dart
        presentation/
          reports_screen.dart
          spending_report_screen.dart
          cash_flow_report_screen.dart
          asset_trend_screen.dart
      zakat/
        domain/
          zakat_calculation.dart
          zakat_calculator.dart
          zakat_repository.dart
        data/
          zakat_repository_impl.dart
        application/
          zakat_notifier.dart
        presentation/
          zakat_screen.dart
          zakat_setup_screen.dart
          zakat_breakdown_screen.dart
      sadaqah/
        domain/
          sadaqah_record.dart
          sadaqah_repository.dart
        data/
          sadaqah_repository_impl.dart
        application/
          sadaqah_notifier.dart
        presentation/
          sadaqah_screen.dart
          add_sadaqah_screen.dart
      notifications/
        domain/
          notification_rule.dart
        application/
          notification_service.dart
        presentation/
          notifications_screen.dart
      backup/
        domain/
          backup_manifest.dart
          backup_service.dart
        data/
          backup_service_impl.dart
          backup_encryptor.dart
        application/
          backup_notifier.dart
          restore_notifier.dart
        presentation/
          backup_screen.dart
          restore_screen.dart
          import_preview_screen.dart
      settings/
        domain/
          app_settings.dart
          settings_repository.dart
        data/
          settings_repository_impl.dart
        application/
          settings_notifier.dart
        presentation/
          settings_screen.dart
          security_settings_screen.dart
          sync_settings_screen.dart
          category_management_screen.dart
  test/
    unit/
      core/
        financial/
      features/
        accounts/
        transactions/
        transfers/
        household/
        ...
    widget/
      features/
        ...
    integration/
      ...
    helpers/
      test_database.dart
      test_factories.dart
      fake_repositories.dart
  firestore_rules/
    firestore.rules
    test/
      rules_test.js
  docs/
    (all planning documents)
```

---

## 4. State Management

**Choice: Riverpod (v2)**

Rationale:
- Compile-time safety for providers.
- AsyncNotifier for async operations.
- Testable without Flutter context.
- No global mutable state (providers are scoped).
- Native support for keeping UI and state in sync.
- StreamProvider integrates cleanly with Drift database streams.

Pattern:
- `domain/` defines interfaces and models — no Riverpod.
- `data/` implements interfaces — no Riverpod.
- `application/` defines Riverpod providers and Notifiers.
- `presentation/` uses `ref.watch` and `ref.read` on providers.

No `BuildContext.read()` or direct instantiation of notifiers in widgets.

---

## 5. Local Database

**Choice: Drift (formerly Moor)**

Rationale:
- Type-safe SQL queries in Dart.
- Native SQLite support on Android and iOS.
- Code generation for tables, queries, and DAOs.
- Stream support for reactive UI.
- Migration support with version tracking.
- Well-maintained, production-tested.

Alternative considered: `sqflite` directly — rejected because Drift provides type safety and code generation that reduces financial calculation bugs.

**Open:** The SQLite driver (standard vs. SQLCipher encrypted) is an open decision (DECISION-004) that must be resolved before Phase 2 begins. See `DECISIONS.md`. The database driver selection affects `pubspec.yaml`, platform configuration on Android and iOS, key storage, and the backup/restore flow. A platform spike during Phase 1 is recommended before committing to either option.

---

## 6. Navigation

**Choice: GoRouter**

- Typed routes via code generation (`go_router_builder`).
- Deep link support.
- Nested navigation for tab bar.
- Authentication guard middleware.
- App lock guard: redirects to lock screen if app is locked.

---

## 7. Dependency Injection

Riverpod providers serve as the DI container.

- Repositories are instantiated as providers.
- Services are instantiated as providers.
- Test overrides are done via `ProviderContainer` overrides.
- No service locator (GetIt) — Riverpod replaces it.

---

## 8. Error Handling

Central error model:

```dart
sealed class AppError {
  const AppError();
}

final class InsufficientFundsError extends AppError {
  final Money available;
  final Money required;
}

final class DuplicateOperationError extends AppError {
  final String operationId;
}

final class ProtectedFundWithdrawalError extends AppError {
  final String accountId;
}

final class InvalidTransferError extends AppError {
  final String reason;
}

final class DatabaseError extends AppError {
  final String message;
}

final class NetworkError extends AppError {
  final int? statusCode;
}

final class AuthError extends AppError {}

final class BackupError extends AppError {
  final String reason;
}
```

All repository methods return `Result<T, AppError>`.

```dart
sealed class Result<T, E> {
  const Result();
}
final class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}
final class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);
}
```

---

## 9. Logging

A `RedactedLogger` wraps any log output.

Rules:
- NEVER log Money amounts or minor units.
- NEVER log account balances.
- NEVER log auth tokens.
- NEVER log personal names.
- NEVER log AI request or response bodies.
- Log level in production: WARNING and above.
- Log level in debug: INFO and above.
- Log IDs (UUIDs) are acceptable.
- Log operation types are acceptable.
- Log error codes are acceptable.

```dart
class RedactedLogger {
  void info(String message, {Map<String, dynamic>? context});
  void warning(String message, {Map<String, dynamic>? context, Object? error});
  void error(String message, {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace});
}
```

No raw print() in any production code.

---

## 10. Key Packages (Shortlist)

| Package | Purpose | Justification |
|---|---|---|
| `flutter_riverpod` | State management | Compile-safe, testable |
| `riverpod_annotation` | Code generation | Reduces boilerplate |
| `drift` | Local SQLite | Type-safe queries, migrations |
| `drift_flutter` | Drift SQLite support | Platform bindings |
| `go_router` | Navigation | Deep links, typed routes |
| `go_router_builder` | Route code gen | Type-safe navigation |
| `firebase_core` | Firebase base | Required for all Firebase |
| `firebase_auth` | Authentication | User identity |
| `cloud_firestore` | Cloud sync | Optional sync |
| `flutter_secure_storage` | Secure key storage | Keychain/Keystore |
| `local_auth` | Biometric unlock | Face ID, fingerprint |
| `encrypt` | Backup encryption | AES-256 |
| `intl` | i18n/l10n | Date, number, plural formatting |
| `freezed` | Immutable models | Data class generation |
| `freezed_annotation` | Freezed annotation | |
| `json_serializable` | JSON serialization | Schema validation |
| `uuid` | UUID generation | Stable IDs |
| `path_provider` | File paths | Backup file location |
| `fl_chart` | Charts | Net worth / spending trends |
| `speech_to_text` | Voice input | Optional AI entry |
| `flutter_local_notifications` | Local reminders | Budget, recurring alerts |
| `share_plus` | Backup export | Share backup file |

Packages intentionally avoided:
- `get_it` — replaced by Riverpod
- `provider` — replaced by Riverpod
- `hive` / `isar` — replaced by Drift for financial data
- Any live market data package — not in v1
- Any remote AI SDK embedded in app — API proxy required

---

## 11. Security Architecture

See `SECURITY_THREAT_MODEL.md` for full threat model.

Summary:
- App lock: PIN + biometric, auto-lock on background.
- Secure storage: `flutter_secure_storage` for PIN hash, auth tokens.
- PIN never stored raw: bcrypt (or SHA-256 + salt stored in secure storage).
- Screenshots: blocked in production via `FLAG_SECURE` (Android), `ignoresScreenshots: true` (iOS).
- App switcher: blur overlay applied when app backgrounds.
- Firestore rules: deny-by-default; each user can only read/write their own household.

---

## 12. Offline-First Architecture

See `OFFLINE_SYNC_STRATEGY.md` for full strategy.

Summary:
1. All financial operations are written to local SQLite first.
2. Operations are added to the sync queue with status `pending`.
3. When connectivity is available, the sync service uploads pending items.
4. The server validates each item (schema, auth, idempotency).
5. On success: item marked `synced`.
6. On conflict: item marked `conflict`, surfaced to user.
7. The app never blocks on the network for any financial operation.

---

## 13. CI/CD

**GitHub Actions (planned)**

- On every PR:
  - `dart format --set-exit-if-changed .`
  - `flutter analyze`
  - `flutter test` (unit + widget)
  - Firebase Emulator tests (Firestore rules)
- On main merge:
  - All of the above
  - `flutter build apk --release`
  - `flutter build appbundle --release`
  - `flutter build ios --no-codesign` (on macOS runner)
- Code coverage target: >80% for domain and application layers.

---

## 14. Implementation Plan and Phase Boundaries

This section defines the precise scope of each implementation phase to prevent scope creep and out-of-order implementation.

### Phase 0 — Planning (current)
**Deliverables:** All documentation in `docs/`. No code.  
**Gate:** All Phase 0 documents complete and internally consistent.

### Phase 1 — Project Foundation (infrastructure only, no financial code)

**Scope — included:**
- `flutter create .` executed inside the existing project root (preserves `docs/`)
- `pubspec.yaml` with all planned dependencies from Section 10
- `analysis_options.yaml` with strict lints
- `dart_defines.json` / `app_config.dart` for branding, currency, locale
- `l10n.yaml` and stub ARB files (`app_ar.arb`, `app_en.arb`) with placeholder keys
- `AppTheme` with color tokens and typography (no financial widgets)
- `GoRouter` with placeholder route stubs (no financial screens)
- Riverpod `ProviderScope` root (no financial providers)
- `AppError` sealed class hierarchy
- `RedactedLogger` wrapper
- `uuid_generator.dart` utility
- `date_utils.dart` utility
- `result.dart` (Result<T,E> type)
- Drift database package wired up: `AppDatabase` class, `NativeDatabase` connection, WAL pragma, foreign keys pragma — **no table definitions, no financial schema**
- Test helpers: `test/helpers/test_database.dart` (in-memory Drift), `test/helpers/fake_repositories.dart` (empty interfaces)
- GitHub Actions CI skeleton
- README stub

**Scope — explicitly deferred to Phase 2:**
- `Money` value type
- `MoneyFormatter`
- `MoneyArithmetic`
- Any `core/financial/` module implementation
- All Drift table definitions (financial_accounts, ledger_entries, operations, etc.)
- All DAOs
- Any repository interfaces or implementations
- Any financial calculations
- Any ledger logic
- Opening balances, adjustments, reversals, audit events
- Financial invariant tests

**Navigation placeholders:** GoRouter may contain route constants and named paths, but their `builder` must return only a placeholder widget (`const Placeholder()` or a bare `Scaffold` with route name text). No financial data, no account lists, no balance displays.

**Project creation safety note:**  
The directory `/Users/hussam/Desktop/hussam/family_money_manager/` already exists and contains `docs/`. Running `flutter create family_money_manager` from the parent directory would fail (directory exists) or could overwrite files. The correct command is:
```bash
cd /Users/hussam/Desktop/hussam/family_money_manager
flutter create --project-name family_money_manager --org com.familymoney .
```
This must be verified before execution to confirm `docs/` is preserved.

### Phase 2 — Financial Ledger

**Precondition:** SQLCipher decision (DECISION-004) must be made before this phase begins. The database driver choice affects all table definitions.

**Scope — included (Phase 2 only):**
- `Money` value type and arithmetic
- `MoneyFormatter`
- All Drift table definitions from `LOCAL_DATABASE_SCHEMA.md`
- All DAOs and repository implementations
- Ledger calculator and balance computation
- Net-worth calculator
- All operation types: income, expense, transfer, opening balance, adjustment, reversal
- Financial invariant tests (all 18 invariants, all test cases in `TEST_STRATEGY.md` sections 3.1)
- Idempotency constraints (UNIQUE constraints, duplicate detection)

**Gate:** All financial invariant tests must pass before Phase 3 begins. No exceptions.

### Phases 3–12
These phases follow the original specification and are described in the product requirements document. Each phase's scope must be verified against this boundary definition before work begins.
