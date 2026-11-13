import 'package:flutter/material.dart';

/// Colours and text styles for the overlay. Pass a custom instance to
/// [DevLoggerOverlay] to re-skin the logger.
class DevLoggerTheme {
  /// Creates a theme. Every field falls back to the reference design.
  const DevLoggerTheme({
    this.panelBg = const Color(0xFF080B12),
    this.interactiveBg = const Color(0xFF0A0D15),
    this.detailBg = const Color(0xFF0B0E16),
    this.slabTop = const Color(0xFF1E2434),
    this.slabBottom = const Color(0xFF141824),
    this.primary = const Color(0xFF3A7BFF),
    this.textPrimary = const Color(0xFFD6DBE5),
    this.textMuted = const Color(0xFF7C8699),
    this.tagColor = const Color(0xFFA5B4FC),
    this.verbose = const Color(0xFF64748B),
    this.debug = const Color(0xFF0E7490),
    this.info = const Color(0xFF15803D),
    this.warning = const Color(0xFFB45309),
    this.error = const Color(0xFFB91C1C),
    this.warningText = const Color(0xFFFDE68A),
    this.errorText = const Color(0xFFFECACA),
    this.ok = const Color(0xFF4ADE80),
    this.warn = const Color(0xFFFBBF24),
    this.bad = const Color(0xFFF87171),
    this.pending = const Color(0xFF94A3B8),
    this.jsonKey = const Color(0xFF93C5FD),
    this.jsonString = const Color(0xFF86EFAC),
    this.jsonNumber = const Color(0xFFFCD34D),
    this.jsonLiteral = const Color(0xFFF9A8D4),
    this.lockedBackgroundOpacity = 0.30,
    this.lockedHeaderOpacity = 0.70,
    this.lockedContentOpacity = 0.85,
    this.interactiveBackgroundOpacity = 0.94,
  });

  /// Locked panel colour. Drawn at [lockedBackgroundOpacity].
  final Color panelBg;

  /// Interactive panel colour. Drawn at [interactiveBackgroundOpacity].
  final Color interactiveBg;

  /// Network detail sheet background.
  final Color detailBg;

  /// Top stop of the slab gradient.
  final Color slabTop;

  /// Bottom stop of the slab gradient.
  final Color slabBottom;

  /// Buttons, selected tab, POST badge.
  final Color primary;

  /// Default log text.
  final Color textPrimary;

  /// Timestamps and secondary text.
  final Color textMuted;

  /// `[tag]` colour.
  final Color tagColor;

  /// Verbose badge.
  final Color verbose;

  /// Debug badge.
  final Color debug;

  /// Info badge.
  final Color info;

  /// Warning badge.
  final Color warning;

  /// Error badge.
  final Color error;

  /// Warning message text.
  final Color warningText;

  /// Error message text.
  final Color errorText;

  /// 2xx status.
  final Color ok;

  /// 3xx status.
  final Color warn;

  /// 4xx, 5xx and transport failures.
  final Color bad;

  /// In-flight status.
  final Color pending;

  /// JSON object keys.
  final Color jsonKey;

  /// JSON strings.
  final Color jsonString;

  /// JSON numbers.
  final Color jsonNumber;

  /// JSON `true`, `false` and `null`.
  final Color jsonLiteral;

  /// Locked panel background alpha.
  final double lockedBackgroundOpacity;

  /// Locked slab alpha. Goes to 1 while the slab is pressed.
  final double lockedHeaderOpacity;

  /// Locked log-list alpha.
  final double lockedContentOpacity;

  /// Interactive panel background alpha.
  final double interactiveBackgroundOpacity;

  /// Monospace body. No font is bundled; the platform monospace is used.
  TextStyle get mono => TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Menlo', 'Courier New'],
        fontSize: 11,
        height: 1.45,
        color: textPrimary,
      );

  /// Outline so lines stay readable on a white screen behind a locked panel.
  static const List<Shadow> textOutline = [
    Shadow(blurRadius: 2, color: Color(0xFF000000)),
    Shadow(blurRadius: 4, color: Color(0xFF000000)),
    Shadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0xFF000000)),
  ];
}

/// Provides [DevLoggerTheme] to the overlay subtree.
class LoggerThemeScope extends InheritedWidget {
  /// Creates a scope.
  const LoggerThemeScope({required this.theme, required super.child, super.key});

  /// Theme visible to descendants.
  final DevLoggerTheme theme;

  /// Theme for [context], or the default theme when no scope exists.
  static DevLoggerTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LoggerThemeScope>()?.theme ??
      const DevLoggerTheme();

  @override
  bool updateShouldNotify(LoggerThemeScope oldWidget) => theme != oldWidget.theme;
}
