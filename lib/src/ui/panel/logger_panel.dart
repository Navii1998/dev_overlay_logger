import 'dart:ui';

import 'package:dev_overlay_logger/src/core/dev_logger.dart';
import 'package:dev_overlay_logger/src/core/log_config.dart';
import 'package:dev_overlay_logger/src/ui/dev_overlay_logger_keys.dart';
import 'package:dev_overlay_logger/src/ui/overlay_controller.dart';
import 'package:dev_overlay_logger/src/ui/panel/logs_list.dart';
import 'package:dev_overlay_logger/src/ui/panel/network_detail_sheet.dart';
import 'package:dev_overlay_logger/src/ui/panel/network_list.dart';
import 'package:dev_overlay_logger/src/ui/panel/slab_header.dart';
import 'package:dev_overlay_logger/src/ui/panel/toolbar.dart';
import 'package:dev_overlay_logger/src/ui/theme/logger_theme.dart';
import 'package:flutter/material.dart';

/// The docked panel: slab, optional toolbar, list, and the detail sheet.
class LoggerPanel extends StatelessWidget {
  /// Creates the panel.
  const LoggerPanel({required this.controller, super.key});

  /// Overlay state.
  final OverlayController controller;

  @override
  Widget build(BuildContext context) {
    final theme = LoggerThemeScope.of(context);
    final media = MediaQuery.of(context);
    final interactive = controller.mode == OverlayMode.interactive;
    final dockTop = controller.dock == DockPosition.top;
    final keyboard = interactive && !dockTop ? media.viewInsets.bottom : 0.0;
    final maxHeight = (media.size.height - keyboard - 50).clamp(44.0, media.size.height);
    final height = controller.heightPx.clamp(44.0, maxHeight);
    final selectedId = interactive ? controller.selectedNetworkId : null;
    final selected = selectedId == null ? null : DevLogger.store.findNetwork(selectedId);

    final background = interactive
        ? theme.interactiveBg.withValues(alpha: theme.interactiveBackgroundOpacity)
        : theme.panelBg.withValues(alpha: theme.lockedBackgroundOpacity);

    return Positioned(
      key: DevLoggerKeys.panel,
      left: 0,
      right: 0,
      top: dockTop ? 0 : null,
      bottom: dockTop ? null : keyboard,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !interactive,
              child: interactive
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: ColoredBox(color: background),
                    )
                  : ColoredBox(color: background),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: dockTop ? media.padding.top : 0),
            child: Column(
              verticalDirection: dockTop ? VerticalDirection.up : VerticalDirection.down,
              children: [
                SlabHeader(controller: controller, screenHeight: media.size.height),
                Expanded(
                  child: IgnorePointer(
                    ignoring: !interactive,
                    child: Opacity(
                      opacity: interactive ? 1 : theme.lockedContentOpacity,
                      child: Column(
                        children: [
                          if (interactive) LoggerToolbar(controller: controller),
                          Expanded(
                            child: controller.tab == LoggerTab.logs
                                ? LogsList(controller: controller)
                                : NetworkList(controller: controller),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selected != null)
            Positioned(
              top: dockTop ? media.padding.top : 44,
              bottom: dockTop ? 44 : 0,
              left: 0,
              right: 0,
              child: NetworkDetailSheet(
                entry: selected,
                onClose: () => controller.selectNetwork(null),
                onToast: controller.showToast,
              ),
            ),
        ],
      ),
    );
  }
}
