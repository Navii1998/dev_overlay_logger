import 'package:dev_overlay_logger/src/core/dev_logger.dart';
import 'package:dev_overlay_logger/src/ui/overlay_controller.dart';
import 'package:dev_overlay_logger/src/ui/panel/network_row.dart';
import 'package:flutter/material.dart';

/// Network calls, newest first.
class NetworkList extends StatefulWidget {
  /// Creates the list bound to [controller].
  const NetworkList({required this.controller, super.key});

  /// Overlay state (search and the selected call).
  final OverlayController controller;

  @override
  State<NetworkList> createState() => _NetworkListState();
}

class _NetworkListState extends State<NetworkList> {
  @override
  void initState() {
    super.initState();
    DevLogger.store.addListener(_onStore);
  }

  @override
  void dispose() {
    DevLogger.store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final query = controller.query.toLowerCase();
    final entries = DevLogger.store.network.reversed.where((entry) {
      if (query.isEmpty) return true;
      return entry.pathAndQuery.toLowerCase().contains(query) ||
          entry.method.toLowerCase().contains(query) ||
          '${entry.status ?? ''}'.contains(query);
    }).toList();
    var maxDuration = Duration.zero;
    for (final entry in entries) {
      final duration = entry.duration;
      if (duration != null && duration > maxDuration) maxDuration = duration;
    }
    final locked = controller.mode != OverlayMode.interactive;
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      itemCount: entries.length,
      itemBuilder: (_, index) {
        final entry = entries[index];
        return NetworkRow(
          entry: entry,
          maxDuration: maxDuration,
          interactive: !locked,
          locked: locked,
          onTap: () => controller.selectNetwork(entry.id),
        );
      },
    );
  }
}
