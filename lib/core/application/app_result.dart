/// Typed application-layer result returned by all use cases.
///
/// Widgets pattern-match on this type to display localized messages.
/// No raw exception text is exposed to the UI.
sealed class AppResult<T> {
  const AppResult();
}

final class AppOk<T> extends AppResult<T> {
  final T value;
  const AppOk(this.value);
}

final class AppValidationFailure<T> extends AppResult<T> {
  final String field;
  final String messageKey; // localization key
  const AppValidationFailure({required this.field, required this.messageKey});
}

final class AppDuplicateConflict<T> extends AppResult<T> {
  final String messageKey;
  const AppDuplicateConflict({required this.messageKey});
}

final class AppNotFound<T> extends AppResult<T> {
  const AppNotFound();
}

final class AppIsolationViolation<T> extends AppResult<T> {
  const AppIsolationViolation();
}

final class AppClassificationImmutabilityViolation<T> extends AppResult<T> {
  final String field;
  const AppClassificationImmutabilityViolation({required this.field});
}

final class AppPersistenceFailure<T> extends AppResult<T> {
  const AppPersistenceFailure();
}

final class AppUnexpectedFailure<T> extends AppResult<T> {
  const AppUnexpectedFailure();
}
