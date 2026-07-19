# Phase 3A Implementation Report

**Commit**: phase 3A: household identities, account management, and Arabic-first UI  
**Date**: 2026-07-16  
**Branch**: main

---

## Summary

Phase 3A delivers the complete foundation for the Family Money Manager UI: account management, household member management, Arabic-first navigation, and the application-layer plumbing (use cases, typed results, money formatter, Riverpod providers).

---

## Validation Results (Phase 3A commit)

| Command                                             | Exit Code | Result               |
| --------------------------------------------------- | --------- | -------------------- |
| `dart format --output=none --set-exit-if-changed .` | 0         | 0 files changed      |
| `flutter analyze`                                   | 0         | No issues found      |
| `flutter test`                                      | 0         | 458/458 tests passed |

> **Note (Phase 3A.1 correction):** The following claims from this report were overstated or required hardening:
>
> - The `CreateAccountUseCase` had no DB-level idempotency payload check (only operation-level idempotency existed in the ledger layer).
> - The household cardinality triggers (one primary_user, one spouse per household) existed only at the application layer; DB-level triggers were added in Phase 3A.1.
> - The `type` and `currency_code` columns had no DB-level immutability trigger; repo-layer exclusion was the only guard.
> - `BalanceQueryResult` existed but was not tested against all scenarios (archived accounts, cross-household isolation).
> - The schema version was v3; Phase 3A.1 bumps it to v4 with the above additions.
>
> See `docs/PHASE_3A_1_REPORT.md` for the full hardening report.

---

## Test Count History

| Phase             | Commit          | Tests   |
| ----------------- | --------------- | ------- |
| Phase 1 end       | —               | 106     |
| Phase 2           | `7d4a9b9`       | 259     |
| Phase 2A complete | `52e814d`       | 390     |
| Phase 3A complete | _(this commit)_ | **458** |

Phase 3A added **68 new tests** (390 → 458).

---

## Files Created

### Core Application Layer

- `lib/core/application/app_result.dart` — Sealed class for typed use-case results (`AppOk`, `AppValidationFailure`, `AppDuplicateConflict`, `AppNotFound`, `AppIsolationViolation`, `AppClassificationImmutabilityViolation`, `AppPersistenceFailure`, `AppUnexpectedFailure`)
- `lib/core/database/database_providers.dart` — Riverpod `appDatabaseProvider`
- `lib/core/database/tables/household_members_table.dart` — `HouseholdMembers` Drift table
- `lib/core/presentation/money_input_formatter.dart` — Arabic-Indic-aware money parser/formatter with `MoneyParseResult` sealed class

### Balance Domain

- `lib/features/balance/domain/balance_result.dart` — `BalanceQueryResult` sealed class (`BalanceFound`, `BalanceAccountNotFound`)

### Household Feature

- `lib/features/household/domain/household_member.dart` — `HouseholdMember` domain entity, `MemberRole`, `MemberLifecycle` enums
- `lib/features/household/domain/household_identity.dart` — `HouseholdIdentity` domain entity
- `lib/features/household/data/household_repository.dart` — `HouseholdRepository` abstract interface + domain errors
- `lib/features/household/data/drift_household_repository.dart` — Drift implementation with spouse uniqueness constraint
- `lib/features/household/application/household_use_cases.dart` — `GetHouseholdUseCase`, `ListMembersUseCase`, `AddMemberUseCase`, `RenameMemberUseCase`, `ArchiveMemberUseCase`
- `lib/features/household/presentation/providers/household_providers.dart` — Riverpod providers for household layer
- `lib/features/household/presentation/household_members_screen.dart` — Members list grouped by role (primary user, spouse, children)

### Accounts Feature

- `lib/features/accounts/application/create_account_use_case.dart` — `CreateAccountUseCase` (atomic account + opening balance in one transaction)
- `lib/features/accounts/application/account_use_cases.dart` — `ListAccountsUseCase`, `ArchiveAccountUseCase`, `UpdateAccountMetadataUseCase`
- `lib/features/accounts/presentation/providers/account_providers.dart` — Riverpod providers for account layer
- `lib/features/accounts/presentation/accounts_screen.dart` — Accounts list with spendable/protected grouping and totals
- `lib/features/accounts/presentation/account_creation_screen.dart` — Account creation form with type-constrained owner, opening balance, currency selection
- `lib/features/accounts/presentation/account_detail_screen.dart` — Account detail view with archive functionality

### Shell & Settings

- `lib/features/shell/app_shell.dart` — `AppShell` with `BottomNavigationBar` (Accounts, Members, Settings)
- `lib/features/settings/settings_screen.dart` — Minimal settings screen (language + theme toggles)

### Tests

- `test/helpers/fake_account_repository.dart` — In-memory `AccountRepository` fake
- `test/helpers/fake_balance_repository.dart` — In-memory `BalanceRepository` fake
- `test/helpers/fake_household_repository.dart` — In-memory `HouseholdRepository` fake
- `test/helpers/fake_ledger_repository.dart` — In-memory `LedgerRepository` fake
- `test/helpers/fake_app_database.dart` — In-memory `AppDatabase` helper
- `test/unit/features/household/household_member_test.dart` — Domain entity validation tests
- `test/unit/core/presentation/money_input_formatter_test.dart` — Parser/formatter tests including Arabic-Indic digits
- `test/unit/features/accounts/create_account_use_case_test.dart` — Use case validation tests
- `test/unit/features/household/household_use_cases_test.dart` — Household use case validation and business rule tests
- `test/widget/features/accounts/accounts_screen_test.dart` — Widget tests for loading/empty/error/populated states

---

## Files Modified

| File                                                      | Change                                                                                                           |
| --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `analysis_options.yaml`                                   | Converted linter rules to map format; disabled `prefer_initializing_formals` (false positive for private fields) |
| `docs/PHASE_2A_REPORT.md`                                 | Corrected test count history (Phase 1: 106, Phase 2: 259, Phase 2A: 390)                                         |
| `lib/app/app_router.dart`                                 | Added `StatefulShellRoute.indexedStack` for 3-tab navigation; initial location `/accounts`                       |
| `lib/core/database/app_database.dart`                     | Added `HouseholdMembers` table; bumped `schemaVersion` to 3; added v2→v3 migration                               |
| `lib/core/database/app_database.g.dart`                   | Regenerated by `build_runner`                                                                                    |
| `lib/core/localization/app_localizations.dart`            | Added 70+ abstract getters for Phase 3A strings                                                                  |
| `lib/core/localization/app_localizations_ar.dart`         | Arabic translations for all new strings                                                                          |
| `lib/core/localization/app_localizations_en.dart`         | English translations for all new strings                                                                         |
| `lib/features/balance/domain/balance_repository.dart`     | Added `balanceForAccount` typed method                                                                           |
| `lib/features/balance/data/drift_balance_repository.dart` | Implemented `balanceForAccount` with proper household isolation                                                  |
| `test/widget/app/app_test.dart`                           | Updated initial route assertions to `/accounts`                                                                  |

---

## Key Technical Decisions

### Typed Application Results (`AppResult<T>`)

All use cases return `AppResult<T>` sealed classes instead of throwing exceptions. Widgets pattern-match on the result variants and display localized messages via `messageKey`. No raw exception text is ever exposed to the UI.

### Atomic Account Creation

`CreateAccountUseCase` wraps account creation + opening balance recording in a single `AppDatabase.transaction`. A failure in either step leaves no partial state.

### Household Isolation

`DriftBalanceRepository.balanceForAccount` now returns a typed `BalanceQueryResult` instead of silently returning `0` for unknown accounts or cross-household access. This eliminates the "zero = not found" ambiguity.

### Phase 3A Household ID

A constant `householdId = 'household-v1'` is used throughout Phase 3A screens. Multi-household support is explicitly deferred to a later phase.

### Schema Migration v2→v3

The `household_members` table is created in the `v2→v3` migration. The existing `households` table (created in v1) is untouched.

### Arabic-First UI

All placeholder text, labels, and empty states default to Arabic. RTL is handled by `Directionality` via the locale mechanism already in place.

### `unnecessary_underscores` Lint Fix

Dart 3+ allows `_` as a repeated wildcard in function parameters. All `(_, __) =>` callbacks were changed to `(_, _) =>`.

### `deprecated_member_use` for DropdownButtonFormField

`DropdownButtonFormField.value` is deprecated in Flutter 3.33+ in favour of `initialValue`. Since the dropdowns in account creation require controlled behaviour (value updates from external `setState`), the deprecated `value:` is retained with `// ignore: deprecated_member_use` to preserve correct functionality until the migration to `DropdownMenu` in a later phase.

---

## Phase 3A Limitations (by design)

- Single household (`household-v1`) — multi-household deferred
- No income, expense, or transfer entry UI
- No ledger history in account detail (empty state placeholder)
- Spouse login is V1-note only (no separate auth)
- Settings screen is minimal (language + theme only)
