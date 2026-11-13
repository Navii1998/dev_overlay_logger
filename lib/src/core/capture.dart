import 'package:flutter/foundation.dart';

/// Receives an error the capture hooks observed.
typedef ErrorSink = void Function(
  String message, {
  required String tag,
  Object? error,
  StackTrace? stackTrace,
});

/// Installs error hooks that log first and then call the previous handler.
class ErrorCapture {
  ErrorCapture._();

  static FlutterExceptionHandler? _previousFlutter;
  static bool Function(Object, StackTrace)? _previousPlatform;
  static bool _installedFlutter = false;
  static bool _installedPlatform = false;
  static bool _handling = false;

  /// Chains the framework and platform error handlers.
  static void install({
    required bool flutterErrors,
    required bool platformErrors,
    required ErrorSink onError,
  }) {
    if (flutterErrors && !_installedFlutter) {
      _installedFlutter = true;
      _previousFlutter = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!_handling) {
          _handling = true;
          onError(
            details.exceptionAsString(),
            tag: 'FlutterError',
            error: details.exception,
            stackTrace: details.stack,
          );
          _handling = false;
        }
        _previousFlutter?.call(details);
      };
    }
    if (platformErrors && !_installedPlatform) {
      _installedPlatform = true;
      _previousPlatform = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (error, stack) {
        if (!_handling) {
          _handling = true;
          onError(
            error.toString(),
            tag: 'Platform',
            error: error,
            stackTrace: stack,
          );
          _handling = false;
        }
        return _previousPlatform?.call(error, stack) ?? false;
      };
    }
  }

  /// Puts the previous handlers back. Safe to call when nothing was installed.
  static void restore() {
    if (_installedFlutter) {
      FlutterError.onError = _previousFlutter;
      _previousFlutter = null;
      _installedFlutter = false;
    }
    if (_installedPlatform) {
      PlatformDispatcher.instance.onError = _previousPlatform;
      _previousPlatform = null;
      _installedPlatform = false;
    }
    _handling = false;
  }
}
