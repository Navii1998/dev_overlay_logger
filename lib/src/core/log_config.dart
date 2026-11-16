import 'package:flutter/foundation.dart';

/// Which edge the overlay panel is anchored to.
enum DockPosition {
  /// Panel hangs from the top. The slab is its bottom edge.
  top,

  /// Panel sits on the bottom. The slab is its top edge.
  bottom,
}

/// Behaviour switches for [DevLogger].
///
/// When [enabled] is false every logger call returns immediately and the
/// overlay renders only its child.
class DevLoggerConfig {
  /// Creates a configuration.
  ///
  /// [enabled] defaults to debug and profile builds.
  const DevLoggerConfig({
    this.enabled = !kReleaseMode,
    this.maxLogs = 1000,
    this.maxNetwork = 300,
    this.captureFlutterErrors = true,
    this.capturePlatformErrors = true,
    this.capturePrint = false,
    this.showOverlay = true,
    this.initialDock = DockPosition.bottom,
    this.initialHeightFraction = 0.5,
    this.startMinimized = true,
    this.showMinimizedButton = true,
    this.redactHeaders = const [
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
    ],
    this.maxBodyChars = 50000,
  });

  /// Master switch. Release builds default this to false.
  final bool enabled;

  /// Oldest log lines are dropped after this many.
  final int maxLogs;

  /// Oldest network calls are dropped after this many.
  final int maxNetwork;

  /// Chain [FlutterError.onError] and record the error first.
  final bool captureFlutterErrors;

  /// Chain [PlatformDispatcher.onError] and record the error first.
  final bool capturePlatformErrors;

  /// When true, [DevLogger.runZoned] mirrors `print` as verbose lines.
  final bool capturePrint;

  /// When false the overlay widget returns its child and draws nothing.
  final bool showOverlay;

  /// Edge the panel opens on.
  final DockPosition initialDock;

  /// When true the overlay opens minimised.
  ///
  /// The floating button is shown unless [showMinimizedButton] is false.
  final bool startMinimized;

  /// When false, minimised mode draws no floating button and does not block taps.
  ///
  /// [DevLogger.show] still restores the panel. Defaults to true.
  final bool showMinimizedButton;

  /// Opening height as a fraction of the screen. `0.5` is the bottom half.
  final double initialHeightFraction;

  /// Header names (case-insensitive) masked in the UI, exports and cURL.
  final List<String> redactHeaders;

  /// Bodies longer than this are truncated until the user taps Show all.
  final int maxBodyChars;
}
