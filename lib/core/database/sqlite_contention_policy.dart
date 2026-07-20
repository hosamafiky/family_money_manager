import 'package:drift/drift.dart'
    show CouldNotRollBackException, DriftWrappedException;

/// SQLite primary result codes that indicate transient writer contention.
///
/// Documented retryable codes (see https://sqlite.org/rescode.html):
/// - [busy] (`SQLITE_BUSY` = 5): the database file is locked by another
///   connection (typical under WAL when `BEGIN IMMEDIATE` waits out
///   `busy_timeout`).
/// - [locked] (`SQLITE_LOCKED` = 6): a table in the database is locked
///   (shared-cache / nested lock scenarios).
///
/// Non-retryable examples (must surface as typed business / validation
/// outcomes, never as infinite lock noise):
/// - `SQLITE_CONSTRAINT` (19) — UNIQUE / FK / CHECK / trigger ABORT
/// - `SQLITE_ABORT` (4) — explicit abort
/// - Application insufficient-funds / validation / injected failures
abstract final class SqliteContentionCodes {
  static const int busy = 5;
  static const int locked = 6;

  static const Set<int> retryable = {busy, locked};
}

/// Thrown when bounded contention retries are exhausted.
///
/// Callers must map this to a typed app result (typically after a final
/// idempotency re-read) and must never forward raw SQLite exceptions.
final class SqliteContentionExhausted implements Exception {
  const SqliteContentionExhausted({this.lastError});

  /// Last underlying error (for diagnostics / tests only — not for UI).
  final Object? lastError;

  @override
  String toString() => 'SqliteContentionExhausted';
}

/// Returns the SQLite primary result code if [error] (or a wrapped cause)
/// looks like a SQLite failure; otherwise `null`.
int? sqlitePrimaryResultCode(Object error) {
  if (error is DriftWrappedException && error.cause != null) {
    return sqlitePrimaryResultCode(error.cause!);
  }
  if (error is CouldNotRollBackException) {
    return sqlitePrimaryResultCode(error.cause);
  }
  // Duck-type sqlite3 SqliteException.resultCode without a hard dependency.
  try {
    final dynamic dyn = error;
    final code = dyn.resultCode;
    if (code is int) return code & 0xFF;
  } catch (_) {
    // Not a SqliteException-shaped object.
  }
  final match = RegExp(
    r'SqliteException\((\d+)\)',
  ).firstMatch(error.toString());
  if (match != null) {
    return int.parse(match.group(1)!) & 0xFF;
  }
  return null;
}

/// Whether [error] is transient SQLITE_BUSY / SQLITE_LOCKED contention.
bool isRetryableSqliteContention(Object error) {
  final code = sqlitePrimaryResultCode(error);
  if (code != null) return SqliteContentionCodes.retryable.contains(code);
  final msg = error.toString().toLowerCase();
  return msg.contains('database is locked') ||
      msg.contains('database table is locked') ||
      msg.contains('sqlite_busy') ||
      msg.contains('sqlite_locked');
}

/// Whether [error] is the Phase 6A.2 non-negative balance trigger abort.
bool isNegativeBalanceAbort(Object error) =>
    error.toString().contains('account balance cannot go negative');

/// If [error] is a negative-balance abort, returns [toInsufficient]; else `null`.
///
/// Debit writers map the abort to a typed insufficient-funds outcome and must
/// not forward raw SQLite exceptions to application callers.
T? mapNegativeBalanceAbortOrNull<T>(Object error, T Function() toInsufficient) {
  if (isNegativeBalanceAbort(error)) return toInsufficient();
  return null;
}

/// Runs an authoritative financial write with bounded SQLITE_BUSY / LOCKED
/// retries.
///
/// Contract for [action]:
/// - Open a **new** writer transaction on every call (Drift `BEGIN IMMEDIATE`).
/// - Recalculate balances and re-read scoped idempotency **inside** that
///   transaction after the write lock is held.
/// - Return typed business outcomes as values (or throw non-retryable domain
///   errors such as insufficient funds). Do not swallow contention — rethrow
///   so this helper can retry.
///
/// Does **not** retry forever: either [maxAttempts] or [deadline] bounds the
/// loop. Exhaustion throws [SqliteContentionExhausted] (never a raw SQLite
/// exception to repository callers that catch this type).
Future<T> runAuthoritativeWriteWithContentionRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 10,
  Duration baseBackoff = const Duration(milliseconds: 25),
  Duration maxBackoff = const Duration(milliseconds: 200),
  Duration? deadline,
}) async {
  assert(maxAttempts >= 1, 'maxAttempts must be >= 1');
  final started = DateTime.now();
  Object? lastError;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    if (deadline != null && DateTime.now().difference(started) >= deadline) {
      break;
    }
    try {
      return await action();
    } catch (e) {
      lastError = e;
      if (!isRetryableSqliteContention(e)) rethrow;
      if (attempt >= maxAttempts) break;
      if (deadline != null && DateTime.now().difference(started) >= deadline) {
        break;
      }
      final delayMs = (baseBackoff.inMilliseconds * attempt).clamp(
        baseBackoff.inMilliseconds,
        maxBackoff.inMilliseconds,
      );
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }

  throw SqliteContentionExhausted(lastError: lastError);
}
