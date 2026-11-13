import 'package:dev_overlay_logger/src/core/dev_logger.dart';
import 'package:dev_overlay_logger/src/ui/floating/floating_logger_button.dart';
import 'package:dev_overlay_logger/src/ui/overlay_controller.dart';
import 'package:dev_overlay_logger/src/ui/panel/logger_panel.dart';
import 'package:dev_overlay_logger/src/ui/theme/logger_theme.dart';
import 'package:dev_overlay_logger/src/ui/widgets/toast.dart';
import 'package:flutter/material.dart';

/// Draws the logger above [child].
///
/// Place it in `MaterialApp.builder` so it stays above routes, dialogs and sheets:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => DevLoggerOverlay(child: child!),
/// )
/// ```
///
/// When the logger is disabled or [DevLoggerConfig.showOverlay] is false, this
/// returns [child] and builds nothing else.
class DevLoggerOverlay extends StatefulWidget {
  /// Creates an overlay around [child].
  const DevLoggerOverlay({
    required this.child,
    this.theme = const DevLoggerTheme(),
    super.key,
  });

  /// The app, usually the navigator.
  final Widget child;

  /// Colours. Defaults to the reference design.
  final DevLoggerTheme theme;

  @override
  State<DevLoggerOverlay> createState() => _DevLoggerOverlayState();
}

class _DevLoggerOverlayState extends State<DevLoggerOverlay> {
  OverlayController? _controller;
  OverlayEntry? _entry;

  bool get _active => DevLogger.enabled && DevLogger.config.showOverlay;

  @override
  void initState() {
    super.initState();
    if (!_active) return;
    _controller = OverlayController(
      initialDock: DevLogger.config.initialDock,
      initialHeightFraction: DevLogger.config.initialHeightFraction,
      startMinimized: DevLogger.config.startMinimized,
    );
    DevLogger.attachOverlay(_controller!);
    _entry = OverlayEntry(builder: _buildLayer);
    _controller!.addListener(_onController);
  }

  void _onController() {
    final entry = _entry;
    if (entry != null && entry.mounted) entry.markNeedsBuild();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = _controller;
    if (controller == null) return;
    if (controller.ensureSized(MediaQuery.sizeOf(context), MediaQuery.paddingOf(context))) {
      _onController();
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_onController);
      DevLogger.detachOverlay(controller);
      controller.dispose();
    }
    final entry = _entry;
    if (entry != null && entry.mounted) entry.remove();
    super.dispose();
  }

  Widget _buildLayer(BuildContext context) {
    final controller = _controller!;
    final minimised = controller.mode == OverlayMode.minimized;
    return LoggerThemeScope(
      theme: widget.theme,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!minimised) LoggerPanel(controller: controller),
            if (minimised) FloatingLoggerButton(controller: controller),
            LoggerToast(message: controller.toast),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    if (entry == null) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Overlay(initialEntries: [entry]),
      ],
    );
  }
}
