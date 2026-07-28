# CLAUDE.md — Flutter Engineering Constitution

This file defines the mandatory engineering rules for AI-assisted work in this Flutter repository. Treat these rules as the default contract for every task unless a repository-local instruction explicitly overrides them.

## 1. Mission

Build production-grade Flutter software that is:

- correct, maintainable, testable, accessible, secure, and performant;
- easy for another engineer to understand without hidden context;
- structured so features can evolve independently;
- explicit about state, side effects, dependencies, errors, and ownership;
- consistent with current Dart and Flutter conventions.

Never optimize for producing the most code. Optimize for the smallest complete, robust change.

---

## 2. Operating Rules for Claude

### Before changing code

1. Read the relevant files, nearby tests, `pubspec.yaml`, `analysis_options.yaml`, and existing architectural patterns.
2. Search the repository before introducing a new abstraction, dependency, helper, model, extension, or naming convention.
3. Identify the feature boundary, data flow, source of truth, side effects, and affected tests.
4. Prefer the repository's established pattern when it is sound. Do not introduce a parallel architecture.
5. For ambiguous requirements, make the smallest reasonable assumption and state it in the final response.

### While changing code

1. Keep the patch focused. Do not refactor unrelated code.
2. Preserve public behavior unless the task explicitly changes it.
3. Do not leave placeholders, dead code, commented-out code, fake implementations, or untracked TODOs.
4. Do not suppress analyzer warnings merely to make checks pass.
5. Do not hand-edit generated files.
6. Add or update tests with every behavior change and bug fix.
7. Run formatting, analysis, and the most relevant tests before declaring completion.

### When reporting completion

State:

- what changed;
- architectural decisions made;
- validation commands run and their results;
- remaining risks, assumptions, or intentionally deferred work.

Never claim a command passed unless it was actually run successfully.

---

## 3. Required Validation Commands

Use the project's pinned Flutter SDK when one exists, such as FVM.

```bash
# Prefer these when FVM is configured
fvm flutter pub get
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze
fvm flutter test

# Otherwise
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

For generated code, run the repository's established generator command. A common default is:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run targeted tests during development, then the full relevant suite before completion. Use profile mode and DevTools for performance conclusions; do not judge performance from debug mode.

---

## 4. Architecture Standard

Use a feature-first, layered architecture with clear dependency direction.

```text
lib/
├── app/                         # App bootstrap, routing, theme, DI composition
├── core/                        # Truly cross-cutting, feature-agnostic code
│   ├── config/
│   ├── error/
│   ├── logging/
│   ├── network/
│   ├── persistence/
│   ├── routing/
│   ├── theme/
│   └── widgets/
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── data_sources/
│       │   ├── dto/
│       │   ├── mappers/
│       │   └── repositories/
│       ├── domain/              # Add when business complexity justifies it
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── use_cases/
│       └── presentation/
│           ├── controllers/     # ViewModels, Notifiers, Blocs, Cubits, etc.
│           ├── pages/
│           ├── state/
│           └── widgets/
└── main.dart
```

Do not create empty layers to imitate “clean architecture.” Architecture must earn its complexity.

### Dependency direction

Allowed dependency flow:

```text
presentation -> domain -> data abstractions
                     ^
                     |
              data implementations
```

In a simpler feature without a domain layer:

```text
presentation -> repository abstraction -> repository implementation -> data source
```

Mandatory boundaries:

- Presentation code must not call HTTP clients, databases, platform channels, or storage APIs directly.
- Widgets must not contain business rules or data-access orchestration.
- Data sources handle one external system and expose transport-shaped data.
- Repositories are the source of truth for feature data and coordinate data sources, caching, mapping, and consistency.
- Domain entities must not depend on Flutter, JSON, database schemas, or transport concerns.
- DTOs must not leak into presentation code.
- Dependency injection belongs in the composition root, not scattered service locators.
- Cross-feature imports are forbidden unless they target an explicitly public contract.
- `core/` is not a dumping ground. Code belongs there only when it is stable and genuinely shared.

### Layer responsibilities

#### Presentation

- Render immutable UI state.
- Convert user intent into controller/ViewModel actions.
- Handle navigation and transient UI effects at the UI boundary.
- Contain no networking, persistence, JSON mapping, or business decisions.

#### Controller / ViewModel / State holder

- Own screen or feature UI state.
- Orchestrate repositories and use cases.
- Expose explicit actions and immutable state.
- Prevent duplicate requests and stale-response races where relevant.
- Translate domain outcomes into presentation-ready state, without returning widgets or `BuildContext`.

#### Domain

- Hold business concepts, policies, invariants, and use cases.
- Remain framework-independent.
- Be introduced when it reduces complexity, not by default for trivial CRUD.

#### Data

- Perform I/O through data sources.
- Map DTOs to domain models.
- Define caching, synchronization, pagination, retry, and consistency behavior.
- Translate low-level exceptions into typed application failures.

---

## 5. State Management Rules

Use the state-management solution already selected by the repository. Do not add another state-management package for convenience.

Regardless of library:

- State must be immutable.
- Maintain one authoritative source of truth.
- Model meaningful states explicitly; do not encode them through unrelated booleans.
- Prefer a sealed state or immutable state object over combinations such as `isLoading`, `hasError`, and nullable data that can become contradictory.
- State transitions occur only through the owning controller.
- Keep ephemeral widget-local state local, such as animation, focus, tab, hover, and temporary form visibility.
- Keep durable business state outside widgets.
- Do not store `BuildContext`, widgets, controllers owned by views, or navigation objects in application state.
- Dispose subscriptions, controllers, timers, and listeners deterministically.
- Use selectors or narrowly scoped listeners to reduce rebuilds.
- Treat one-off effects—snackbars, dialogs, navigation—as effects, not durable state, unless replay is intended.

Example state shape:

```dart
sealed class ProfileState {
  const ProfileState();
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile);

  final Profile profile;
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure(this.failure);

  final AppFailure failure;
}
```

---

## 6. Dart Code Quality Rules

Follow Effective Dart and let `dart format` own formatting.

### Types and null safety

- Use sound null safety rigorously.
- Avoid `dynamic`; use it only at a validated external boundary and convert immediately.
- Avoid `Object?` when a specific type, sealed hierarchy, record, or generic constraint can express the contract.
- Do not use `!` unless an invariant makes null impossible and that invariant is obvious or asserted.
- Prefer non-nullable fields and valid construction over late initialization.
- Use `late` only when lifecycle guarantees initialization before access.
- Return empty collections instead of `null` unless absence is semantically distinct.
- Use exhaustive pattern matching for sealed types.

### Immutability

- Prefer `final` locals and fields.
- Prefer `const` constructors and literals where valid.
- Use immutable models and state.
- Defensively expose unmodifiable collections when callers must not mutate internal state.
- Implement value equality for entities, DTOs, and states where equality has semantic meaning.

### Functions and classes

- Keep functions small and single-purpose.
- Prefer guard clauses over deeply nested conditionals.
- Prefer composition over inheritance.
- Avoid utility classes with unrelated static methods.
- Avoid boolean parameters that obscure intent; use named parameters, enums, or separate methods.
- Use named parameters for calls with multiple arguments or unclear positional meaning.
- Make invalid states unrepresentable where practical.
- Do not create interfaces with only one speculative implementation unless a boundary, test seam, or volatility justifies them.

### Naming

- Names must describe intent, not implementation trivia.
- Use nouns for types and values, verbs for actions, and predicates beginning with `is`, `has`, `can`, or `should`.
- Avoid vague names: `data`, `item`, `manager`, `helper`, `utils`, `common`, `process`, `handle`, `temp`.
- Do not include type names redundantly, such as `userString` or `itemsList`.
- Avoid unexplained abbreviations.

### Documentation

- Document public APIs and non-obvious architectural decisions.
- Explain why, invariants, constraints, and trade-offs—not what readable code already says.
- Keep comments accurate or remove them.
- Use `TODO(owner-or-ticket): actionable description` only for accepted deferred work.

---

## 7. Flutter UI Rules

### Widgets

- Widgets describe UI; they do not perform business orchestration.
- Split large widgets by responsibility and rebuild boundary, not by arbitrary line count.
- Prefer small private widget classes over large helper methods returning widgets when identity, keys, tests, or rebuild isolation matter.
- Use `const` wherever possible.
- Never trigger network requests, database writes, navigation, dialogs, or state mutations directly from `build()`.
- Keep `build()` deterministic and free of side effects.
- Do not create expensive objects in `build()` when they can be reused safely.
- Use keys intentionally, especially for reorderable/stateful collections. Do not add keys everywhere.
- Pass the minimum data and callbacks a widget needs.

### Layout and responsiveness

- Do not hard-code a single device size.
- Design for constrained width, text scaling, orientation, keyboard insets, safe areas, and platform differences.
- Use `LayoutBuilder` for parent constraints and `MediaQuery` for window-level properties.
- Prefer adaptive breakpoints based on available space, not device labels.
- Avoid deeply nested `Container`; use purpose-specific widgets such as `Padding`, `Align`, `ColoredBox`, `DecoratedBox`, and `SizedBox`.
- Use lazy builders for long or unbounded collections.
- Prevent unbounded constraints and accidental intrinsic layout passes.

### Theme and design system

- Use `ThemeData`, `ColorScheme`, `TextTheme`, and project design tokens.
- Do not scatter raw colors, font sizes, radii, shadows, or spacing values through feature widgets.
- Do not access theme values through global mutable state.
- Support light/dark themes when the product requires them.
- Keep reusable components API-driven and avoid feature-specific assumptions in shared widgets.

### Accessibility and localization

- Every interactive element must have an accessible label or meaningful semantics.
- Ensure adequate touch target sizes and contrast.
- Preserve logical focus and traversal order.
- Support screen readers and keyboard navigation where applicable.
- Do not convey meaning by color alone.
- Do not hard-code user-facing strings when localization is enabled.
- Use generated localization APIs and locale-aware date, number, and plural formatting.
- Test with large text scales and long translated strings.

---

## 8. Async, Concurrency, and Lifecycle Rules

- Await futures unless intentionally detached.
- Mark intentionally detached futures explicitly with `unawaited(...)` and ensure errors are handled.
- Never use `async void` except framework-required callbacks.
- After an `await`, verify widget lifecycle before using `BuildContext`:

```dart
if (!context.mounted) return;
```

- Cancel stale searches, requests, subscriptions, timers, and streams when the owning lifecycle ends.
- Debounce or throttle only when behavior requires it; document the UX reason.
- Protect against out-of-order responses when multiple requests can overlap.
- Do not catch an exception merely to ignore it.
- Preserve stack traces when rethrowing; use `rethrow` rather than `throw error`.
- Timeouts, retry, and backoff must be explicit and appropriate to the operation. Never retry non-idempotent operations blindly.

---

## 9. Error Handling Rules

Use typed failures at architectural boundaries.

- Low-level exceptions stay inside infrastructure/data code.
- Repositories translate transport, storage, parsing, and platform exceptions into application failures.
- Controllers expose safe, actionable UI states.
- UI displays user-appropriate messages and retry actions.
- Logs contain diagnostic context but never secrets or sensitive personal data.
- Distinguish expected failures from programmer errors.
- Do not wrap every statement in `try/catch`.
- Do not show raw exception strings to users.
- Do not silently replace corrupted or invalid data with defaults unless product behavior explicitly requires it.

Example:

```dart
sealed class AppFailure {
  const AppFailure();
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({this.isOffline = false});

  final bool isOffline;
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure();
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(this.issues);

  final Map<String, String> issues;
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure();
}
```

---

## 10. Data, Networking, and Persistence

### DTO and mapping rules

- Parse external input defensively at the boundary.
- Keep DTOs separate from domain entities when schemas can change independently.
- Centralize mapping logic; do not scatter JSON parsing across repositories and widgets.
- Validate required fields and define behavior for unknown enum values.
- Never trust server, deep-link, local-storage, or platform-channel input.
- Use explicit serialization tests for important models.

### Repository rules

A repository must define:

- the source of truth;
- cache policy and invalidation;
- online/offline behavior;
- freshness semantics;
- pagination behavior;
- write consistency and conflict behavior;
- error translation.

Do not return a raw HTTP response, database row, document snapshot, or plugin-specific type above the data layer.

### Networking

- Centralize base URLs, headers, authentication, timeouts, and safe logging.
- Keep authentication refresh logic coordinated to avoid refresh storms.
- Do not log tokens, authorization headers, passwords, payment data, or full sensitive payloads.
- Make cancellation and timeout behavior explicit for long-running calls.
- Use idempotency protection for retried writes when supported.

### Persistence

- Store only what is required.
- Use secure platform-backed storage for secrets and tokens; ordinary preferences are not secret storage.
- Version local schemas and migrations.
- Test migrations and destructive fallback decisions.
- Encrypt sensitive data when the threat model requires it.

---

## 11. Dependency Rules

Before adding a package:

1. Confirm the standard library, Flutter SDK, or an existing dependency cannot solve the problem cleanly.
2. Check maintenance, platform support, license, API stability, transitive dependencies, and repository compatibility.
3. Prefer focused packages over broad frameworks.
4. Add the package at the narrowest required scope: dependency, dev dependency, or platform-specific implementation.
5. Document unusual package choices.
6. Never upgrade unrelated dependencies in a focused feature or bug-fix patch.
7. Commit lockfile changes for applications according to repository policy.

Do not introduce a dependency solely to avoid writing a few clear lines of code.

---

## 12. Testing Standard

Use a balanced test strategy:

- Unit tests for domain logic, mappers, validators, repositories, controllers, and state transitions.
- Widget tests for rendering, interaction, semantics, loading, empty, success, and failure states.
- Integration tests for critical user journeys and infrastructure integration.
- Golden tests only where stable visual regression coverage provides meaningful value.

### Mandatory test principles

- Every bug fix includes a regression test that fails before the fix.
- Test observable behavior, not private implementation details.
- Follow Arrange–Act–Assert or Given–When–Then consistently.
- Use descriptive test names that state condition and expected outcome.
- Keep tests deterministic; control time, randomness, network, storage, and platform boundaries.
- Prefer lightweight fakes over mocks when they provide clearer behavior.
- Mock boundaries, not value objects or simple pure functions.
- Avoid broad `pumpAndSettle()` use when ongoing animations or timers can hide problems; pump intentionally.
- Assert important accessibility semantics in widget tests.
- Do not reduce coverage by deleting meaningful tests to make a change pass.

Suggested layout:

```text
test/
├── core/
├── features/
│   └── <feature>/
│       ├── data/
│       ├── domain/
│       └── presentation/
integration_test/
```

---

## 13. Performance Rules

Correctness and clarity come first, then measured optimization.

- Measure with Flutter DevTools in profile mode before and after non-trivial optimization.
- Minimize rebuild scope using widget extraction, immutable inputs, and state selectors.
- Prefer `const` widgets where possible.
- Use lazy list/grid constructors for large collections.
- Avoid expensive synchronous computation on the UI isolate.
- Move genuinely heavy CPU work off the UI isolate using an appropriate isolate mechanism.
- Cache only when invalidation and memory cost are understood.
- Resize and decode images near their display requirements when practical.
- Avoid unnecessary opacity layers, clipping, saveLayer-triggering effects, and intrinsic layout passes in hot paths.
- Do not optimize with speculative complexity.

A performance claim must include a measurement, device/profile context, and relevant before/after evidence.

---

## 14. Security and Privacy Rules

- Never commit secrets, API keys, certificates, private endpoints, or credentials.
- Do not treat values embedded in a client app as secret.
- Use environment/configuration mechanisms already established by the repository.
- Validate and sanitize all external input.
- Use allowlists for deep links, redirects, file types, and platform messages where applicable.
- Escape or safely render untrusted rich content.
- Apply least privilege to permissions and request them contextually.
- Do not log sensitive information.
- Redact diagnostic data.
- Protect authenticated operations server-side; client-side checks are UX, not authorization.
- Consider rooted/jailbroken devices and local tampering according to the product threat model, without relying on obscurity.

Immediately flag any discovered credential or serious security issue rather than propagating it.

---

## 15. Routing and Navigation

- Centralize route definitions and deep-link parsing.
- Use typed route parameters when supported by the selected router.
- Validate external route input.
- Keep navigation decisions at the presentation/application boundary.
- Do not pass large mutable objects through routes; pass stable identifiers and load authoritative data.
- Define authentication redirects and restoration behavior explicitly.
- Ensure back navigation works predictably across Android, iOS, web, and nested navigation.

---

## 16. Forms and Validation

- Separate field presentation, local input state, validation, and submission orchestration.
- Use domain-relevant validation, not only UI-level checks.
- Display actionable field-level errors.
- Prevent duplicate submissions.
- Preserve user input across recoverable failures.
- Normalize data deliberately; do not unexpectedly mutate user input.
- Do not trust client validation as server authorization or integrity enforcement.

---

## 17. Generated Code

- Never manually modify files marked as generated.
- Keep source annotations/configuration and generated output consistent.
- Regenerate after changing source models, routes, localization, assets, or DI declarations.
- Include generated output in version control only if repository policy requires it.
- Do not hide generator failures or resolve them by deleting unrelated output.

Common generated patterns may include:

```text
*.g.dart
*.freezed.dart
*.gr.dart
*.config.dart
generated_plugin_registrant.dart
```

Repository conventions take precedence over this illustrative list.

---

## 18. Git and Change Discipline

- Make atomic, reviewable changes.
- Do not reformat unrelated files.
- Do not rename or move files unless the task benefits from it.
- Preserve backward compatibility for public APIs unless a breaking change is explicit.
- Include migration notes for breaking schema, storage, route, or API changes.
- Never overwrite user work.
- Never use destructive Git operations without explicit instruction.
- Do not commit unless explicitly requested.

Recommended commit style when requested:

```text
feat(profile): add editable avatar flow
fix(auth): prevent duplicate token refresh
refactor(cart): isolate pricing policy
 test(search): cover stale response handling
```

---

## 19. Forbidden Patterns

Do not introduce:

- business logic inside widgets;
- network/database/plugin calls from presentation widgets;
- global mutable state;
- service locator calls spread throughout feature code;
- multiple competing state-management systems;
- DTOs or plugin-specific types leaking into UI/domain code;
- `BuildContext` stored beyond its safe lifecycle;
- side effects in `build()`;
- swallowed exceptions;
- raw exception messages shown to users;
- secrets in source code or logs;
- blanket analyzer ignores;
- arbitrary delays used to fix race conditions;
- indiscriminate `pumpAndSettle()`;
- giant “manager,” “helper,” or “utils” classes;
- speculative abstractions;
- duplicated design tokens or hard-coded user-facing strings;
- unrelated cleanup inside focused patches;
- claims of validation without executed commands.

---

## 20. Decision Heuristics

When several solutions are valid, prefer—in order:

1. Correctness and user safety.
2. Existing project conventions.
3. Simplicity and explicitness.
4. Testability.
5. Clear ownership and dependency direction.
6. Maintainability and ease of change.
7. Accessibility and localization readiness.
8. Measured performance.
9. Reuse supported by real duplication.
10. Novelty last.

Use an abstraction only when it removes meaningful duplication, protects a volatile boundary, expresses a domain concept, or creates a necessary test seam.

---

## 21. Definition of Done

A change is complete only when all applicable items are true:

- [ ] Requirements and edge cases are implemented.
- [ ] Architecture boundaries are preserved.
- [ ] No unrelated behavior changed.
- [ ] Code is formatted.
- [ ] Static analysis passes without new warnings.
- [ ] Relevant tests were added or updated.
- [ ] Relevant tests pass.
- [ ] Generated code is current.
- [ ] Loading, empty, error, retry, and success states are handled where relevant.
- [ ] Accessibility and localization impacts were considered.
- [ ] Async lifecycle, cancellation, and duplicate-action risks were considered.
- [ ] Security and privacy impacts were considered.
- [ ] Performance-sensitive changes were measured where relevant.
- [ ] Documentation was updated where behavior or architecture changed.
- [ ] No secrets, debug logs, dead code, placeholders, or unexplained TODOs remain.

---

## 22. Task-Specific Response Template

Use this structure for non-trivial completion messages:

```markdown
## Implemented
- ...

## Architecture
- ...

## Validation
- `flutter analyze` — passed
- `flutter test test/features/...` — passed

## Notes
- Assumption: ...
- Remaining risk: ...
```

Keep the report factual and concise.

---

## 23. Repository-Specific Overrides

Place project-specific decisions below this line. These override generic preferences above but must preserve correctness, testability, and clear boundaries.

### Project profile

- Flutter SDK: `<pin version or describe FVM policy>`
- Dart SDK: `<version constraint>`
- Supported platforms: `<android / ios / web / desktop>`
- State management: `<Riverpod / Bloc / Provider / other>`
- Routing: `<go_router / auto_route / Navigator / other>`
- Networking: `<Dio / http / generated client / other>`
- Persistence: `<Drift / Isar / Hive / SharedPreferences / other>`
- Serialization: `<json_serializable / freezed / other>`
- Dependency injection: `<constructor injection / provider graph / get_it / other>`
- Localization: `<gen_l10n / other>`
- Analytics/crash reporting: `<tool and privacy rules>`
- CI commands: `<exact commands>`

### Project exceptions

Document each exception with its reason, scope, and intended review date.

---

## 24. Reference Basis

These rules align with the official Flutter architecture guidance, Flutter testing and performance guidance, Flutter accessibility recommendations, Flutter AI-rule guidance, and Effective Dart. Repository-specific constraints remain authoritative when explicitly documented.
