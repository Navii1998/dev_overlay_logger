import 'package:dev_overlay_logger/src/core/log_level.dart';
import 'package:dev_overlay_logger/src/ui/overlay_controller.dart';
import 'package:dev_overlay_logger/src/ui/theme/logger_theme.dart';
import 'package:flutter/material.dart';

/// Single-select level chips. Shown on the Logs tab only.
class LevelFilterChips extends StatelessWidget {
  /// Creates the chip row bound to [controller].
  const LevelFilterChips({required this.controller, super.key});

  /// Overlay state. [OverlayController.levelFilter] null means ALL.
  final OverlayController controller;

  @override
  Widget build(BuildContext context) {
    final theme = LoggerThemeScope.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'ALL',
            selected: controller.levelFilter == null,
            color: const Color(0xFF475569),
            theme: theme,
            onTap: () => controller.setLevelFilter(null),
          ),
          for (final level in LogLevel.values)
            _Chip(
              label: level.chipLabel,
              selected: controller.levelFilter == level,
              color: _color(theme, level),
              theme: theme,
              onTap: () => controller.setLevelFilter(level),
            ),
        ],
      ),
    );
  }

  Color _color(DevLoggerTheme theme, LogLevel level) => switch (level) {
        LogLevel.verbose => theme.verbose,
        LogLevel.debug => theme.debug,
        LogLevel.info => theme.info,
        LogLevel.warning => theme.warning,
        LogLevel.error => theme.error,
      };
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final DevLoggerTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 5),
        child: GestureDetector(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : theme.textMuted,
                  fontFamily: 'monospace',
                  fontFamilyFallback: const ['Menlo', 'Courier New'],
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
}
