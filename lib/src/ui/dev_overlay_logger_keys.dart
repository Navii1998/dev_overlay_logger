import 'package:flutter/foundation.dart';

/// Keys used by the overlay and by widget tests.
abstract final class DevLoggerKeys {
  /// The resize slab.
  static const slab = ValueKey<String>('dev_overlay_logger_slab');

  /// The panel bounds.
  static const panel = ValueKey<String>('dev_overlay_logger_panel');

  /// The minimised floating button.
  static const fab = ValueKey<String>('dev_overlay_logger_fab');

  /// Returns the panel to locked mode.
  static const lock = ValueKey<String>('dev_overlay_logger_lock');

  /// Switches the dock edge.
  static const dock = ValueKey<String>('dev_overlay_logger_dock');

  /// Minimises the panel.
  static const minimise = ValueKey<String>('dev_overlay_logger_minimise');
}
