# DECISION-004 Spike — Database Option Compilation Check

**Status:** Disposable. This directory exists only to record compilation evidence for DECISION-004.

**DO NOT:**
- Import anything from this directory into `lib/`
- Treat this spike as defining production architecture
- Add financial schema, user data, or real database paths here
- Retain this directory after the product owner resolves DECISION-004

**Spike goal:** verify that candidate packages resolve and compile against
Flutter 3.44.4 / Dart 3.12.2 on macOS arm64, before committing to any option.

## Options evaluated

| # | Packages | Encryption | EOL risk |
|---|---|---|---|
| 1 | `drift_flutter` | None | Low |
| 2 | `sqflite_sqlcipher` + `drift` | SQLCipher | Medium (sqflite backend in drift 2.x, see notes) |
| 3 | `sqlcipher_flutter_libs` | SQLCipher | HIGH — `0.7.0+eol` |
| 4 | `sqlite3_flutter_libs` | None | HIGH — `0.6.0+eol` |

Options 3 and 4 are eliminated by the `+eol` suffix found during `flutter pub add --dry-run`.

## Evidence recorded in DECISION-004 assessment doc

See `docs/DECISIONS.md` and `docs/DECISION_004_ASSESSMENT.md`.
