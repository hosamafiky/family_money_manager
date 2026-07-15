import 'package:family_money_manager/core/logging/log_level.dart';

/// Defines where log output is written.
///
/// The default production implementation uses [debugPrint]. In tests the
/// injectable [TestLogSink] captures records for assertion.
abstract interface class LogSink {
  void write(LogLevel level, String tag, String message);
}

/// Default sink that writes to [debugPrint] (Flutter's debug output).
///
/// In release builds [debugPrint] is a no-op, so no log reaches the console
/// automatically. An explicit analytics or crash-reporting sink should be
/// injected for observability needs.
final class DebugPrintSink implements LogSink {
  const DebugPrintSink();

  @override
  void write(LogLevel level, String tag, String message) {
    // ignore: avoid_print
    print('[$tag][${level.name.toUpperCase()}] $message');
  }
}
