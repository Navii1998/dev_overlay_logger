import 'package:dev_overlay_logger/src/core/dev_logger.dart';
import 'package:dev_overlay_logger/src/ui/overlay_controller.dart';
import 'package:dev_overlay_logger/src/ui/panel/log_row.dart';
import 'package:flutter/material.dart';

/// Filtered log list. Sticks to the newest line unless the user has scrolled up.
class LogsList extends StatefulWidget {
  /// Creates the list bound to [controller].
  const LogsList({required this.controller, super.key});

  /// Overlay state (filter, search, expanded rows).
  final OverlayController controller;

  @override
  State<LogsList> createState() => _LogsListState();
}

class _LogsListState extends State<LogsList> {
  final ScrollController _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    DevLogger.store.addListener(_onStore);
  }

  @override
  void dispose() {
    DevLogger.store.removeListener(_onStore);
    _scroll.dispose();
    super.dispose();
  }

  void _onStore() {
    if (!mounted) return;
    final count = DevLogger.store.logs.length;
    final stick = _shouldStick();
    setState(() {});
    if (count == _lastCount || !stick) {
      _lastCount = count;
      return;
    }
    _lastCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  bool _shouldStick() {
    if (widget.controller.mode != OverlayMode.interactive) return true;
    if (!_scroll.hasClients) return true;
    final position = _scroll.position;
    return position.maxScrollExtent - position.pixels < 30;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final query = controller.query.toLowerCase();
    final entries = DevLogger.store.logs.where((entry) {
      if (controller.levelFilter != null && entry.level != controller.levelFilter) return false;
      if (query.isEmpty) return true;
      return entry.message.toLowerCase().contains(query) || entry.tag.toLowerCase().contains(query);
    }).toList();
    final locked = controller.mode != OverlayMode.interactive;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      itemCount: entries.length,
      itemBuilder: (_, index) {
        final entry = entries[index];
        return LogRow(
          entry: entry,
          expanded: controller.expandedLogIds.contains(entry.id),
          interactive: !locked,
          locked: locked,
          onTap: () => controller.toggleExpanded(entry.id),
        );
      },
    );
  }
}
