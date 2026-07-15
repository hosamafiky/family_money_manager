import 'package:flutter/foundation.dart';

/// Sealed hierarchy of expected application failures.
///
/// Phase 1 defines foundation-level errors only. Financial error types
/// (InsufficientFunds, DuplicateOperation, etc.) are deferred to Phase 2.
///
/// No sensitive data (balances, transaction details, tokens, PII) may appear
/// in any [AppError] field. Internal details must stay in application logs
/// behind the [RedactedLogger] before any user-facing message is produced.
@immutable
sealed class AppError {
  const AppError();

  /// A human-readable key used to look up a localized string.
  ///
  /// Must never be displayed raw to the user; always resolve via the
  /// AppLocalizations class before rendering.
  String get localizationKey;
}

/// A network or connectivity failure unrelated to business logic.
final class NetworkError extends AppError {
  const NetworkError({this.code});

  /// Optional HTTP status code or platform error code (no sensitive payload).
  final int? code;

  @override
  String get localizationKey => 'errorNetwork';
}

/// An authentication or session error.
final class AuthError extends AppError {
  const AuthError();

  @override
  String get localizationKey => 'errorAuth';
}

/// A failure reading from or writing to local storage.
final class StorageError extends AppError {
  const StorageError();

  @override
  String get localizationKey => 'errorStorage';
}

/// An unexpected error that does not fit any known category.
///
/// Internal details must be logged via [RedactedLogger] before this is
/// created; never store a raw stack trace or exception message here.
final class UnknownError extends AppError {
  const UnknownError();

  @override
  String get localizationKey => 'errorUnknown';
}

/// Maps an [AppError] to its localized message using [localizedMessage].
///
/// [localizedMessage] is called with the [AppError.localizationKey] and must
/// return the translated string from AppLocalizations. This keeps [AppError]
/// free of any Flutter or BuildContext dependency.
String resolveErrorMessage(
  AppError error, {
  required String Function(String key) localizedMessage,
}) {
  return localizedMessage(error.localizationKey);
}
