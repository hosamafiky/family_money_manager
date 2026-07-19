import 'package:family_money_manager/core/logging/log_level.dart';
import 'package:family_money_manager/core/logging/log_sink.dart';

/// A structured logger that rejects or masks sensitive financial and personal
/// data before writing to a [LogSink].
///
/// ## Allowlist approach
///
/// The API does not accept arbitrary key-value maps. Only typed methods exist,
/// ensuring that no financial amount, balance, token, or PII can accidentally
/// reach the log output through this class.
///
/// ## Passive scanning
///
/// All string messages are scanned for common patterns that suggest financial
/// or authentication data (e.g., "1500 EGP", "Bearer `<token>`", "balance: 50")
/// and replaced with placeholder text before the message is forwarded to the
/// sink. This catches accidental leakage in freeform log strings.
///
/// ## Scope of protection
///
/// This class only protects data that flows through it. Callers that bypass
/// [RedactedLogger] and write directly to [print] or a crash reporter
/// receive no protection. See SECURITY_THREAT_MODEL.md T-07.
final class RedactedLogger {
  RedactedLogger(this._tag, {LogSink? sink}) : _sink = sink ?? const DebugPrintSink();

  final String _tag;
  final LogSink _sink;

  // ─── Public typed logging API ──────────────────────────────────────────

  /// Logs a domain operation event.
  ///
  /// Only [operationType] and [operationId] are accepted. Amounts, account
  /// names, balances, and user data are explicitly excluded from this API.
  void logOperation({required String operationType, required String operationId}) {
    _emit(LogLevel.info, 'op=${_sanitize(operationType)} id=${_sanitize(operationId)}');
  }

  /// Logs a navigation event (route name only, no financial context).
  void logNavigation(String routeName) {
    _emit(LogLevel.debug, 'nav=${_sanitize(routeName)}');
  }

  /// Logs an application lifecycle event.
  void logLifecycle(String event) {
    _emit(LogLevel.info, 'lifecycle=${_sanitize(event)}');
  }

  /// Logs a non-sensitive warning message.
  ///
  /// The message is scanned and any detected sensitive patterns are masked.
  void warning(String message) {
    _emit(LogLevel.warning, _redact(message));
  }

  /// Logs an error with a code or tag only — no stack traces, no payloads.
  void error(String errorCode) {
    _emit(LogLevel.error, 'errorCode=${_sanitize(errorCode)}');
  }

  // ─── Internal helpers ──────────────────────────────────────────────────

  void _emit(LogLevel level, String message) {
    _sink.write(level, _tag, message);
  }

  /// Removes characters that could form log-injection payloads.
  static String _sanitize(String input) => input.replaceAll(RegExp(r'[\n\r\t]'), ' ').trim();

  /// Replaces known sensitive patterns with placeholder text.
  ///
  /// ## Scope of this scanner
  ///
  /// This method is a best-effort passive filter applied to freeform
  /// [warning] message strings. It covers the most common patterns that
  /// could accidentally embed financial or authentication data.
  ///
  /// It does NOT protect data that bypasses [RedactedLogger] entirely (e.g.
  /// direct calls to `print`, `debugPrint`, or a crash reporter). See
  /// SECURITY_THREAT_MODEL.md T-07.
  ///
  /// Backup body content and AI response bodies are not accepted anywhere in
  /// the logger API — the typed methods have no payload or body parameter —
  /// so they cannot leak through this class. No regex pattern is required for
  /// those cases.
  static String _redact(String message) {
    return message
        // Currency amounts: "1500 EGP", "١٥٠٠ ج.م", "EGP 1,500.00"
        .replaceAllMapped(
          RegExp(
            r'\b[\d,]+\.?\d*\s*(EGP|ج\.م|جنيه)\b'
            r'|'
            r'\bEGP\s+[\d,]+\.?\d*\b',
            caseSensitive: false,
          ),
          (_) => '[AMOUNT_REDACTED]',
        )
        // Bearer tokens
        .replaceAllMapped(RegExp(r'Bearer\s+[\w\-\.]+', caseSensitive: false), (_) => 'Bearer [TOKEN_REDACTED]')
        // balance: <number>
        .replaceAllMapped(RegExp(r'balance\s*:?\s*[\d,]+\.?\d*', caseSensitive: false), (_) => 'balance:[BALANCE_REDACTED]')
        // transaction: <number> — catches accidental amount-in-message leakage
        .replaceAllMapped(RegExp(r'transaction\s*:?\s*[\d,]+\.?\d*', caseSensitive: false), (_) => 'transaction:[AMOUNT_REDACTED]')
        // child_fund: <number> or child fund: <number>
        .replaceAllMapped(RegExp(r'child[_\s]fund\s*:?\s*[\d,]+\.?\d*', caseSensitive: false), (_) => 'child_fund:[AMOUNT_REDACTED]')
        // Sanitize injection characters
        .replaceAll(RegExp(r'[\n\r]'), ' ');
  }
}
