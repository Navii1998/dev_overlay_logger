import 'package:dev_overlay_logger/src/core/log_level.dart';

/// One immutable developer log line.
class LogEntry {
  /// Creates a log line.
  const LogEntry({
    required this.id,
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
    this.data,
  });

  /// Monotonic id assigned by the store.
  final int id;

  /// When the line was recorded.
  final DateTime time;

  /// Severity.
  final LogLevel level;

  /// Source label, for example `Router` or `Bloc`. Defaults to `App`.
  final String tag;

  /// Human-readable text.
  final String message;

  /// Caught object, when this line is an error.
  final Object? error;

  /// Stack trace captured with [error].
  final StackTrace? stackTrace;

  /// Optional structured payload shown when the row is expanded.
  final Map<String, Object?>? data;

  /// True when the row has something to expand.
  bool get hasDetails =>
      error != null || stackTrace != null || (data != null && data!.isNotEmpty);
}
