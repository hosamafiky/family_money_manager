import 'package:family_money_manager/core/error/app_error.dart';

/// A discriminated union representing either a successful [Ok] value or a
/// failed [Err] with an [AppError].
///
/// Domain functions return [Result] instead of throwing exceptions, keeping
/// error handling explicit and type-safe.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  R when<R>({required R Function(T value) ok, required R Function(AppError error) err}) {
    return switch (this) {
      Ok(:final value) => ok(value),
      Err(:final error) => err(error),
    };
  }

  /// Applies [transform] if [Ok], otherwise propagates the error unchanged.
  Result<U> map<U>(U Function(T value) transform) {
    return switch (this) {
      Ok(:final value) => Ok(transform(value)),
      Err(:final error) => Err(error),
    };
  }
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final AppError error;
  const Err(this.error);
}
