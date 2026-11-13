import 'dart:async';
import 'dart:developer' as developer;

import 'package:dev_overlay_logger/src/core/capture.dart';
import 'package:dev_overlay_logger/src/core/log_config.dart';
import 'package:dev_overlay_logger/src/core/log_entry.dart';
import 'package:dev_overlay_logger/src/core/log_level.dart';
import 'package:dev_overlay_logger/src/core/log_store.dart';
import 'package:dev_overlay_logger/src/ui/overlay_controller.dart';

/// Static entry point for the in-app logger.
///
/// Call [init] once at startup. When [DevLoggerConfig.enabled] is false every
/// method returns immediately and allocates nothing.
class DevLogger {
  DevLogger._();

  static DevLoggerConfig _config = const DevLoggerConfig(enabled: false);
  static LogStore? _store;
  static OverlayController? _overlay;

  /// Active configuration. Defaults to disabled until [init].
  static DevLoggerConfig get config => _config;

  /// True after [init] with `enabled: true`.
  static bool get enabled => _config.enabled && _store != null;

  /// The live buffers. Throws if [init] was not called with logging enabled.
  static LogStore get store {
    final current = _store;
    if (current == null) {
      throw StateError('DevLogger.init was not called with enabled: true');
    }
    return current;
  }

  /// Starts the logger. Safe to call again; the previous store is discarded.
  static void init(DevLoggerConfig config) {
    ErrorCapture.restore();
    _store?.dispose();
    _store = null;
    _config = config;
    if (!config.enabled) return;
    _store = LogStore(maxLogs: config.maxLogs, maxNetwork: config.maxNetwork);
    if (config.captureFlutterErrors || config.capturePlatformErrors) {
      ErrorCapture.install(
        flutterErrors: config.captureFlutterErrors,
        platformErrors: config.capturePlatformErrors,
        onError: (message, {required tag, error, stackTrace}) => e(
          message,
          tag: tag,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Verbose line.
  static void v(String message, {String tag = 'App', Object? data}) =>
      log(LogLevel.verbose, message, tag: tag, data: data);

  /// Debug line.
  static void d(String message, {String tag = 'App', Object? data}) =>
      log(LogLevel.debug, message, tag: tag, data: data);

  /// Info line.
  static void i(String message, {String tag = 'App', Object? data}) =>
      log(LogLevel.info, message, tag: tag, data: data);

  /// Warning line.
  static void w(String message, {String tag = 'App', Object? data}) =>
      log(LogLevel.warning, message, tag: tag, data: data);

  /// Error line.
  static void e(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) =>
      log(
        LogLevel.error,
        message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
        data: data,
      );

  /// Writes one line at [level]. Also forwards to `dart:developer` `log`
  /// so the line still appears in the IDE console.
  static void log(
    LogLevel level,
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) {
    if (!_config.enabled || _store == null) return;
    developer.log(
      message,
      name: tag,
      level: _developerLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
    _store!.addLog(
      LogEntry(
        id: 0,
        time: DateTime.now(),
        level: level,
        tag: tag,
        message: message,
        error: error,
        stackTrace: stackTrace,
        data: _asMap(data),
      ),
    );
  }

  /// Runs [body] in a zone that mirrors `print` as verbose lines tagged `print`.
  ///
  /// Does nothing extra unless [DevLoggerConfig.capturePrint] is true.
  static R runZoned<R>(R Function() body) {
    if (!_config.enabled || !_config.capturePrint) return body();
    return _runPrintZone(body);
  }

  static R _runPrintZone<R>(R Function() body) => Zone.current.fork(
        specification: ZoneSpecification(
          print: (self, parent, zone, line) {
            parent.print(zone, line);
            DevLogger.v(line, tag: 'print');
          },
        ),
      ).run(body);

  /// Restores the panel at its last height, in locked mode.
  static void show() => _overlay?.restore();

  /// Minimises the panel to the floating button.
  static void hide() => _overlay?.minimize();

  /// Minimises the panel to the floating button.
  static void minimize() => _overlay?.minimize();

  /// Called by [DevLoggerOverlay] when it mounts.
  static void attachOverlay(OverlayController controller) {
    _overlay = controller;
  }

  /// Called by [DevLoggerOverlay] when it unmounts.
  static void detachOverlay(OverlayController controller) {
    if (identical(_overlay, controller)) _overlay = null;
  }

  /// Drops the store and restores error handlers. Used by tests.
  static void reset() {
    ErrorCapture.restore();
    _overlay = null;
    _store?.dispose();
    _store = null;
    _config = const DevLoggerConfig(enabled: false);
  }

  static int _developerLevel(LogLevel level) => switch (level) {
        LogLevel.verbose => 500,
        LogLevel.debug => 700,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      };

  static Map<String, Object?>? _asMap(Object? data) {
    if (data == null) return null;
    if (data is Map<String, Object?>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value as Object?));
    }
    return {'value': data};
  }
}
