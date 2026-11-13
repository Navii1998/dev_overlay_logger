import 'package:dev_overlay_logger/src/core/network_entry.dart';
import 'package:dev_overlay_logger/src/ui/theme/logger_theme.dart';
import 'package:dev_overlay_logger/src/utils/size_format.dart';
import 'package:dev_overlay_logger/src/utils/time_format.dart';
import 'package:flutter/material.dart';

/// One network call: method, path, status, then time, duration, size and a bar.
class NetworkRow extends StatelessWidget {
  /// Creates a row.
  const NetworkRow({
    required this.entry,
    required this.maxDuration,
    required this.interactive,
    required this.locked,
    required this.onTap,
    super.key,
  });

  /// The call to show.
  final NetworkEntry entry;

  /// Slowest visible call, used to scale the duration bar.
  final Duration maxDuration;

  /// When false the row does not respond to taps.
  final bool interactive;

  /// Locked rows draw the text outline.
  final bool locked;

  /// Opens the detail sheet.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = LoggerThemeScope.of(context);
    final shadows = locked ? DevLoggerTheme.textOutline : const <Shadow>[];
    final pending = entry.state == NetworkState.pending;
    final statusColor = _statusColor(theme);
    final failed = entry.state == NetworkState.failed;
    final maxMs = maxDuration.inMilliseconds <= 0 ? 1 : maxDuration.inMilliseconds;
    final width = pending ? 0.0 : (entry.duration?.inMilliseconds ?? 0) / maxMs * 80;

    return GestureDetector(
      onTap: interactive ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _MethodBadge(method: entry.method),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.pathAndQuery,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.mono.copyWith(shadows: shadows),
                  ),
                ),
                const SizedBox(width: 8),
                if (pending)
                  SizedBox(
                    width: 9,
                    height: 9,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: theme.pending),
                  )
                else
                  Text(
                    '${entry.status ?? 'ERR'}',
                    style: theme.mono.copyWith(color: statusColor, fontWeight: FontWeight.w700, shadows: shadows),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const SizedBox(width: 50),
                Text(formatClock(entry.startTime), style: theme.mono.copyWith(color: theme.textMuted, fontSize: 10, shadows: shadows)),
                const SizedBox(width: 10),
                Text(
                  pending ? '…' : formatDuration(entry.duration),
                  style: theme.mono.copyWith(color: theme.textMuted, fontSize: 10, shadows: shadows),
                ),
                const SizedBox(width: 10),
                Text(
                  pending ? '' : formatBytes(entry.responseSizeBytes),
                  style: theme.mono.copyWith(color: theme.textMuted, fontSize: 10, shadows: shadows),
                ),
                const SizedBox(width: 8),
                Container(
                  width: width.clamp(pending ? 0 : 4, 80),
                  height: 3,
                  decoration: BoxDecoration(
                    color: failed ? const Color(0xFFEF4444) : theme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(DevLoggerTheme theme) {
    final status = entry.status;
    if (entry.state == NetworkState.pending || status == null) return theme.pending;
    if (status < 300) return theme.ok;
    if (status < 400) return theme.warn;
    return theme.bad;
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (method) {
      'GET' => (const Color(0x3322C55E), const Color(0xFF86EFAC)),
      'POST' => (const Color(0x403A7BFF), const Color(0xFF9CC0FF)),
      'PUT' => (const Color(0x33F59E0B), const Color(0xFFFCD34D)),
      'PATCH' => (const Color(0x33C4B5FD), const Color(0xFFC4B5FD)),
      _ => (const Color(0x38EF4444), const Color(0xFFFCA5A5)),
    };
    return Container(
      constraints: const BoxConstraints(minWidth: 42),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(4)),
      child: Text(
        method,
        style: TextStyle(color: foreground, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
