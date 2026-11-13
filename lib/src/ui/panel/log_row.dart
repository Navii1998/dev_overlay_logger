import 'package:dev_overlay_logger/src/core/log_entry.dart';
import 'package:dev_overlay_logger/src/core/log_level.dart';
import 'package:dev_overlay_logger/src/ui/theme/logger_theme.dart';
import 'package:dev_overlay_logger/src/utils/json_pretty.dart';
import 'package:dev_overlay_logger/src/utils/time_format.dart';
import 'package:flutter/material.dart';

/// One log line: time, level badge, tag, message. Tap expands the stack.
class LogRow extends StatelessWidget {
  /// Creates a row.
  const LogRow({
    required this.entry,
    required this.expanded,
    required this.interactive,
    required this.locked,
    required this.onTap,
    super.key,
  });

  /// The line to show.
  final LogEntry entry;

  /// Whether the stack and data are visible.
  final bool expanded;

  /// When false the row does not respond to taps.
  final bool interactive;

  /// Locked rows use the stronger error tint and the text outline.
  final bool locked;

  /// Toggles [expanded].
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = LoggerThemeScope.of(context);
    final shadows = locked ? DevLoggerTheme.textOutline : const <Shadow>[];
    final messageColor = switch (entry.level) {
      LogLevel.warning => theme.warningText,
      LogLevel.error => theme.errorText,
      _ => theme.textPrimary,
    };
    final border = switch (entry.level) {
      LogLevel.warning => const Color(0xFFF59E0B),
      LogLevel.error => const Color(0xFFEF4444),
      _ => Colors.transparent,
    };
    final fill = switch (entry.level) {
      LogLevel.error => Color(locked ? 0x2EEF4444 : 0x14EF4444),
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: interactive ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
            decoration: BoxDecoration(
              color: fill,
              border: Border(left: BorderSide(color: border, width: 2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatClock(entry.time), style: theme.mono.copyWith(color: theme.textMuted, shadows: shadows)),
                const SizedBox(width: 6),
                _Badge(level: entry.level, theme: theme),
                const SizedBox(width: 6),
                Text('[${entry.tag}]', style: theme.mono.copyWith(color: theme.tagColor, shadows: shadows)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(entry.message, style: theme.mono.copyWith(color: messageColor, shadows: shadows)),
                ),
              ],
            ),
          ),
        ),
        if (expanded && entry.hasDetails)
          Container(
            margin: const EdgeInsets.fromLTRB(32, 2, 10, 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0x59000000),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SelectableText(
              [
                if (entry.error != null) entry.error.toString(),
                if (entry.stackTrace != null) entry.stackTrace.toString(),
                if (entry.data != null) prettyJson(entry.data),
              ].where((part) => part.isNotEmpty).join('\n'),
              style: theme.mono.copyWith(color: const Color(0xFFFCA5A5), fontSize: 10),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.level, required this.theme});

  final LogLevel level;
  final DevLoggerTheme theme;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      LogLevel.verbose => theme.verbose,
      LogLevel.debug => theme.debug,
      LogLevel.info => theme.info,
      LogLevel.warning => theme.warning,
      LogLevel.error => theme.error,
    };
    return Container(
      width: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      child: Text(
        level.short,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, height: 1.3),
      ),
    );
  }
}
