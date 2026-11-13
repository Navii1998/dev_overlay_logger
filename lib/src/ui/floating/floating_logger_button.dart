import 'dart:ui';

import 'package:dev_overlay_logger/src/core/dev_logger.dart';
import 'package:dev_overlay_logger/src/ui/dev_overlay_logger_keys.dart';
import 'package:dev_overlay_logger/src/ui/overlay_controller.dart';
import 'package:dev_overlay_logger/src/ui/widgets/count_badge.dart';
import 'package:flutter/material.dart';

/// Minimised logger. Drag snaps it to the nearest side. A tap restores the panel.
class FloatingLoggerButton extends StatefulWidget {
  /// Creates the button bound to [controller].
  const FloatingLoggerButton({required this.controller, super.key});

  /// Overlay state, including the button offset.
  final OverlayController controller;

  @override
  State<FloatingLoggerButton> createState() => _FloatingLoggerButtonState();
}

class _FloatingLoggerButtonState extends State<FloatingLoggerButton> with SingleTickerProviderStateMixin {
  final GlobalKey _boxKey = GlobalKey();
  Offset? _dragOrigin;
  Offset? _pointerOrigin;
  bool _moved = false;
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  int _lastErrors = 0;

  @override
  void initState() {
    super.initState();
    _lastErrors = DevLogger.store.errorCount.value;
    DevLogger.store.errorCount.addListener(_onErrors);
  }

  @override
  void dispose() {
    DevLogger.store.errorCount.removeListener(_onErrors);
    _flash.dispose();
    super.dispose();
  }

  void _onErrors() {
    final count = DevLogger.store.errorCount.value;
    if (count > _lastErrors && widget.controller.mode == OverlayMode.minimized) {
      _flash.forward(from: 0).whenComplete(() => _flash.forward(from: 0));
    }
    _lastErrors = count;
  }

  void _onDown(PointerDownEvent event) {
    _pointerOrigin = event.position;
    _dragOrigin = widget.controller.fabOffset;
    _moved = false;
  }

  void _onMove(PointerMoveEvent event) {
    final origin = _pointerOrigin;
    final start = _dragOrigin;
    if (origin == null || start == null) return;
    final delta = event.position - origin;
    if (!_moved && delta.distance < 5) return;
    _moved = true;
    final size = _fabSize;
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final next = widget.controller.clampFab(start + delta, screen, padding, size);
    widget.controller.setFabOffset(next, dragging: true);
  }

  void _onUp(PointerEvent event) {
    final size = _fabSize;
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    if (!_moved) {
      widget.controller.restore();
    } else {
      final mid = widget.controller.fabOffset.dx + size.width / 2;
      final left = mid < screen.width / 2 ? 14.0 : screen.width - size.width - 14;
      final snapped = widget.controller.clampFab(
        Offset(left, widget.controller.fabOffset.dy),
        screen,
        padding,
        size,
      );
      widget.controller.setFabOffset(snapped, dragging: false);
    }
    _pointerOrigin = null;
    _dragOrigin = null;
    _moved = false;
  }

  Size get _fabSize {
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size ?? const Size(132, 36);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final store = DevLogger.store;
    return AnimatedPositioned(
      key: DevLoggerKeys.fab,
      duration: controller.fabDragging ? Duration.zero : const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      left: controller.fabOffset.dx,
      top: controller.fabOffset.dy,
      child: AnimatedBuilder(
        animation: _flash,
        builder: (context, child) {
          final ring = _flash.value > 0.15 && _flash.value < 0.7;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (ring) const BoxShadow(color: Color(0x99EF4444), blurRadius: 0, spreadRadius: 4),
                const BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: child,
          );
        },
        child: Listener(
          onPointerDown: _onDown,
          onPointerMove: _onMove,
          onPointerUp: _onUp,
          onPointerCancel: _onUp,
          child: ClipRRect(
            key: _boxKey,
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xE0111622),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: store.pausedListenable,
                        builder: (_, paused, __) => Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: paused ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'LOGS',
                        style: TextStyle(
                          color: Color(0xFFE6E9F0),
                          fontFamily: 'monospace',
                          fontFamilyFallback: ['Menlo', 'Courier New'],
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 7),
                      ValueListenableBuilder<int>(
                        valueListenable: store.errorCount,
                        builder: (_, value, __) => CountBadge(
                          label: '$value',
                          background: const Color(0x38EF4444),
                          foreground: const Color(0xFFFCA5A5),
                        ),
                      ),
                      const SizedBox(width: 5),
                      ValueListenableBuilder<int>(
                        valueListenable: store.warningCount,
                        builder: (_, value, __) => CountBadge(
                          label: '$value',
                          background: const Color(0x38F59E0B),
                          foreground: const Color(0xFFFCD34D),
                        ),
                      ),
                      const SizedBox(width: 5),
                      ValueListenableBuilder<int>(
                        valueListenable: store.networkCount,
                        builder: (_, value, __) => CountBadge(
                          label: '$value',
                          background: const Color(0x383A7BFF),
                          foreground: const Color(0xFF9CC0FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
