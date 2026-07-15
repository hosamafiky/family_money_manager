import 'package:family_money_manager/core/logging/log_level.dart';
import 'package:flutter/foundation.dart';

/// Defines where log output is written.
///
/// The default development implementation uses [debugPrint]. In tests the
/// injectable [TestLogSink] captures records for assertion. A production-grade
/// analytics or crash-reporting sink should be injected for release builds.
abstract interface class LogSink {
  void write(LogLevel level, String tag, String message);
}

/// Default sink that writes to [debugPrint] (Flutter's rate-limited output).
///
/// Suitable for development. For production builds, replace this with a sink
/// that forwards to a crash reporter (e.g. Firebase Crashlytics) or discards
/// output, depending on data-retention policy. [debugPrint] is not a no-op
/// in release builds; it writes to the system console with throttling.
final class DebugPrintSink implements LogSink {
  const DebugPrintSink();

  @override
  void write(LogLevel level, String tag, String message) {
    debugPrint('[$tag][${level.name.toUpperCase()}] $message');
  }
}
