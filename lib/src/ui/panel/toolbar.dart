import 'package:dev_overlay_logger/src/core/dev_logger.dart';
import 'package:dev_overlay_logger/src/core/log_config.dart';
import 'package:dev_overlay_logger/src/ui/overlay_controller.dart';
import 'package:dev_overlay_logger/src/utils/time_format.dart';
import 'package:dev_overlay_logger/src/ui/panel/level_filter_chips.dart';
import 'package:dev_overlay_logger/src/ui/theme/logger_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tabs, search, pause, clear and export. Interactive mode only.
class LoggerToolbar extends StatefulWidget {
  /// Creates the toolbar bound to [controller].
  const LoggerToolbar({required this.controller, super.key});

  /// Overlay state.
  final OverlayController controller;

  @override
  State<LoggerToolbar> createState() => _LoggerToolbarState();
}

class _LoggerToolbarState extends State<LoggerToolbar> {
  late final TextEditingController _search = TextEditingController(text: widget.controller.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LoggerThemeScope.of(context);
    final controller = widget.controller;
    final store = DevLogger.store;
    final logs = controller.tab == LoggerTab.logs;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: controller.dock == DockPosition.bottom
              ? BorderSide(color: Colors.white.withValues(alpha: 0.08))
              : BorderSide.none,
          top: controller.dock == DockPosition.top
              ? BorderSide(color: Colors.white.withValues(alpha: 0.08))
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
        child: Column(
          children: [
            _Tabs(controller: controller, logs: store.logs.length, network: store.network.length),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _Search(controller: _search, theme: theme, onChanged: controller.setQuery)),
                const SizedBox(width: 6),
                ValueListenableBuilder<bool>(
                  valueListenable: store.pausedListenable,
                  builder: (_, paused, __) => _IconButton(
                    icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    tooltip: paused ? 'Resume' : 'Pause',
                    onTap: () {
                      store.paused = !store.paused;
                      controller.showToast(store.paused ? 'Paused' : 'Resumed');
                    },
                  ),
                ),
                const SizedBox(width: 6),
                _IconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Clear',
                  onTap: () {
                    if (logs) {
                      store.clearLogs();
                    } else {
                      store.clearNetwork();
                      controller.selectNetwork(null);
                    }
                    controller.showToast('Cleared');
                  },
                ),
                const SizedBox(width: 6),
                _IconButton(
                  icon: Icons.ios_share_rounded,
                  tooltip: 'Export',
                  onTap: () => _export(context, controller),
                ),
              ],
            ),
            if (logs) ...[
              const SizedBox(height: 6),
              LevelFilterChips(controller: controller),
            ],
          ],
        ),
      ),
    );
  }

  void _export(BuildContext context, OverlayController controller) {
    final store = DevLogger.store;
    final query = controller.query.toLowerCase();
    final text = controller.tab == LoggerTab.logs
        ? store.logs
            .where((entry) {
              if (controller.levelFilter != null && entry.level != controller.levelFilter) {
                return false;
              }
              if (query.isEmpty) return true;
              return entry.message.toLowerCase().contains(query) || entry.tag.toLowerCase().contains(query);
            })
            .map((entry) => '${formatClock(entry.time)} ${entry.level.short} [${entry.tag}] ${entry.message}')
            .join('\n')
        : store.network
            .where((entry) => query.isEmpty || entry.pathAndQuery.toLowerCase().contains(query))
            .map((entry) => '${entry.method} ${entry.uri} ${entry.status ?? '-'} ${entry.duration?.inMilliseconds ?? '-'}ms')
            .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    controller.showToast('Copied to clipboard');
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.controller, required this.logs, required this.network});

  final OverlayController controller;
  final int logs;
  final int network;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            _Tab(
              label: 'Logs ($logs)',
              selected: controller.tab == LoggerTab.logs,
              onTap: () => controller.setTab(LoggerTab.logs),
            ),
            _Tab(
              label: 'Network ($network)',
              selected: controller.tab == LoggerTab.network,
              onTap: () => controller.setTab(LoggerTab.network),
            ),
          ],
        ),
      );
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF3A7BFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF9AA3B5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
}

class _Search extends StatelessWidget {
  const _Search({required this.controller, required this.theme, required this.onChanged});

  final TextEditingController controller;
  final DevLoggerTheme theme;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          height: 30,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: theme.mono.copyWith(fontSize: 12),
            cursorColor: theme.textPrimary,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Filter by text, tag, URL…',
              hintStyle: theme.mono.copyWith(fontSize: 12, color: theme.textMuted),
              prefixIcon: Icon(Icons.search, size: 14, color: theme.textMuted),
              prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        ),
      );
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFCFD5E1)),
          ),
        ),
      );
}
