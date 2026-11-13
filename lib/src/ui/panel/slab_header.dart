import 'dart:async';

import 'package:dev_overlay_logger/src/core/dev_logger.dart';
import 'package:dev_overlay_logger/src/core/log_config.dart';
import 'package:dev_overlay_logger/src/ui/dev_overlay_logger_keys.dart';
import 'package:dev_overlay_logger/src/ui/overlay_controller.dart';
import 'package:dev_overlay_logger/src/ui/theme/logger_theme.dart';
import 'package:dev_overlay_logger/src/ui/widgets/count_badge.dart';
import 'package:dev_overlay_logger/src/ui/widgets/hold_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The 44px handle. Always receives gestures, in both locked and interactive mode.
class SlabHeader extends StatefulWidget {
  /// Creates the slab for [controller] on a screen of [screenHeight].
  const SlabHeader({
    required this.controller,
    required this.screenHeight,
    super.key,
  });

  /// Overlay state.
  final OverlayController controller;

  /// Full screen height, used for the 18% minimise threshold and the clamp.
  final double screenHeight;

  @override
  State<SlabHeader> createState() => _SlabHeaderState();
}

enum _Gesture { idle, press, drag }

class _SlabHeaderState extends State<SlabHeader> {
  static const _hold = Duration(milliseconds: 500);
  static const _slop = 6.0;
  static const _minFraction = 0.18;

  _Gesture _gesture = _Gesture.idle;
  Timer? _holdTimer;
  Timer? _progressTimer;
  double _progress = 0;
  double _startY = 0;
  double _startHeight = 0;
  DateTime _downAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastTap;
  bool _willMinimise = false;
  bool _pressing = false;

  @override
  void dispose() {
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _onDown(PointerDownEvent event) {
    _gesture = _Gesture.press;
    _pressing = true;
    _startY = event.position.dy;
    _startHeight = widget.controller.heightPx;
    _downAt = DateTime.now();
    _progress = 0;
    if (widget.controller.mode == OverlayMode.locked) {
      _progressTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (!mounted || _gesture != _Gesture.press) return;
        setState(() {
          _progress = DateTime.now().difference(_downAt).inMilliseconds / _hold.inMilliseconds;
        });
      });
      _holdTimer = Timer(_hold, () {
        if (_gesture != _Gesture.press) return;
        _stopHold();
        widget.controller.activate();
        HapticFeedback.lightImpact();
        DevLogger.v('overlay → interactive', tag: 'DevLogger');
      });
    }
    setState(() {});
  }

  void _onMove(PointerMoveEvent event) {
    if (_gesture == _Gesture.idle) return;
    final invert = widget.controller.dock == DockPosition.top ? -1.0 : 1.0;
    final dy = (_startY - event.position.dy) * invert;
    if (_gesture == _Gesture.press && dy.abs() > _slop) {
      _gesture = _Gesture.drag;
      _stopHold();
    }
    if (_gesture != _Gesture.drag) return;
    final maxHeight = widget.screenHeight - 50;
    final height = (_startHeight + dy).clamp(44.0, maxHeight);
    _willMinimise = height < widget.screenHeight * _minFraction;
    widget.controller.setHeight(height);
    setState(() {});
  }

  void _onUp(PointerEvent event) {
    final wasDrag = _gesture == _Gesture.drag;
    final wasTap = _gesture == _Gesture.press && DateTime.now().difference(_downAt) < _hold;
    _stopHold();
    _gesture = _Gesture.idle;
    _pressing = false;
    if (wasDrag) {
      if (_willMinimise) {
        widget.controller.minimize();
      } else {
        widget.controller.commitHeight();
      }
    } else if (wasTap) {
      final now = DateTime.now();
      final previous = _lastTap;
      if (previous != null && now.difference(previous).inMilliseconds < 300) {
        _lastTap = null;
        widget.controller.minimize();
      } else {
        _lastTap = now;
      }
    }
    _willMinimise = false;
    if (mounted) setState(() {});
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    _progress = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = LoggerThemeScope.of(context);
    final controller = widget.controller;
    final interactive = controller.mode == OverlayMode.interactive;
    final lockedLook = !interactive && !_pressing && _gesture != _Gesture.drag;
    final store = DevLogger.store;

    return Opacity(
      opacity: lockedLook ? theme.lockedHeaderOpacity : 1,
      child: SizedBox(
        key: DevLoggerKeys.slab,
        height: 44,
        child: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onDown,
                onPointerMove: _onMove,
                onPointerUp: _onUp,
                onPointerCancel: _onUp,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _willMinimise
                        ? null
                        : LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [theme.slabTop, theme.slabBottom],
                          ),
                    color: _willMinimise ? const Color(0xE6B91C1C) : null,
                    border: Border(
                      top: BorderSide(
                        color: controller.dock == DockPosition.bottom
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.transparent,
                      ),
                      bottom: BorderSide(
                        color: controller.dock == DockPosition.top
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  child: HoldProgress(progress: _progress),
                ),
              ),
            ),
            Positioned(
              top: controller.dock == DockPosition.bottom ? 5 : null,
              bottom: controller.dock == DockPosition.top ? 5 : null,
              left: 0,
              right: 0,
              child: const IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 38,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x59FFFFFF),
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const IgnorePointer(child: _Title()),
                    const SizedBox(width: 4),
                    IgnorePointer(
                      child: _Counts(storeError: store.errorCount, storeWarning: store.warningCount, storeNetwork: store.networkCount),
                    ),
                    const Spacer(),
                    if (_willMinimise)
                      const IgnorePointer(
                        child: Text(
                          'Release to minimise',
                          style: TextStyle(color: Color(0xFFE6E9F0), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      )
                    else ...[
                      if (!interactive) const IgnorePointer(child: _Hint()),
                      if (interactive)
                        _SlabButton(
                          key: DevLoggerKeys.lock,
                          icon: Icons.lock_rounded,
                          tooltip: 'Back to passive',
                          filled: true,
                          onTap: controller.lock,
                        ),
                      const SizedBox(width: 6),
                      _SlabButton(
                        key: DevLoggerKeys.dock,
                        icon: controller.dock == DockPosition.top
                            ? Icons.vertical_align_bottom_rounded
                            : Icons.vertical_align_top_rounded,
                        tooltip: controller.dock == DockPosition.top ? 'Move to bottom' : 'Move to top',
                        onTap: controller.toggleDock,
                      ),
                      const SizedBox(width: 6),
                      _SlabButton(
                        key: DevLoggerKeys.minimise,
                        icon: controller.dock == DockPosition.top
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        tooltip: 'Minimise',
                        onTap: controller.minimize,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final paused = DevLogger.store.pausedListenable;
    return ValueListenableBuilder<bool>(
      valueListenable: paused,
      builder: (context, isPaused, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isPaused ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isPaused ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'DEV LOGGER',
            style: TextStyle(
              color: Color(0xFFE6E9F0),
              fontFamily: 'monospace',
              fontFamilyFallback: ['Menlo', 'Courier New'],
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({
    required this.storeError,
    required this.storeWarning,
    required this.storeNetwork,
  });

  final ValueNotifier<int> storeError;
  final ValueNotifier<int> storeWarning;
  final ValueNotifier<int> storeNetwork;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: storeError,
            builder: (_, value, __) => CountBadge(
              label: 'E $value',
              background: const Color(0x38EF4444),
              foreground: const Color(0xFFFCA5A5),
            ),
          ),
          const SizedBox(width: 5),
          ValueListenableBuilder<int>(
            valueListenable: storeWarning,
            builder: (_, value, __) => CountBadge(
              label: 'W $value',
              background: const Color(0x38F59E0B),
              foreground: const Color(0xFFFCD34D),
            ),
          ),
          const SizedBox(width: 5),
          ValueListenableBuilder<int>(
            valueListenable: storeNetwork,
            builder: (_, value, __) => CountBadge(
              label: 'API $value',
              background: const Color(0x383A7BFF),
              foreground: const Color(0xFF9CC0FF),
            ),
          ),
        ],
      );
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) => const Text(
        'Hold or drag',
        style: TextStyle(color: Color(0xB3E6E9F0), fontSize: 10.5),
      );
}

class _SlabButton extends StatelessWidget {
  const _SlabButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? const Color(0xFF3A7BFF) : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFE6E9F0)),
          ),
        ),
      );
}
