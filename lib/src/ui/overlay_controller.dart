import 'dart:async';

import 'package:dev_overlay_logger/src/core/log_config.dart';
import 'package:dev_overlay_logger/src/core/log_level.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Which body the panel is showing.
enum LoggerTab {
  /// Developer log lines.
  logs,

  /// Captured HTTP calls.
  network,
}

/// Passive, interactive, or minimised to the floating button.
enum OverlayMode {
  /// Taps pass through the body. Only the slab responds.
  locked,

  /// The panel absorbs taps so the user can filter and copy.
  interactive,

  /// Panel hidden. A floating button remains.
  minimized,
}

/// UI state for the overlay. Not exported.
class OverlayController extends ChangeNotifier {
  /// Creates a controller from the opening config.
  OverlayController({
    DockPosition initialDock = DockPosition.bottom,
    this.initialHeightFraction = 0.5,
    bool startMinimized = true,
  })  : dock = initialDock,
        mode = startMinimized ? OverlayMode.minimized : OverlayMode.locked;

  /// Opening height as a fraction of the screen.
  final double initialHeightFraction;

  /// Current interaction mode.
  OverlayMode mode;

  /// Which edge the panel is anchored to.
  DockPosition dock;

  /// Current panel height in logical pixels.
  double heightPx = 0;

  /// Height restored after minimise. Drag releases below 18% do not update it.
  double lastGoodHeightPx = 0;

  /// Logs or network.
  LoggerTab tab = LoggerTab.logs;

  /// Null means every level.
  LogLevel? levelFilter;

  /// Search text for the current tab.
  String query = '';

  /// Top-left of the floating button.
  Offset fabOffset = Offset.zero;

  /// Network call open in the detail sheet. Null hides the sheet.
  int? selectedNetworkId;

  /// Log rows whose stack or data is expanded.
  final Set<int> expandedLogIds = <int>{};

  /// Toast text. Null hides the toast.
  String? toast;

  bool _sized = false;
  Timer? _toastTimer;

  /// True while the floating button is being dragged (no snap animation).
  bool fabDragging = false;

  /// Sets the opening height and button position once, then clamps on resize.
  bool ensureSized(Size size, EdgeInsets padding) {
    final maxHeight = (size.height - 50).clamp(44.0, size.height);
    if (!_sized) {
      _sized = true;
      heightPx = (size.height * initialHeightFraction).clamp(44.0, maxHeight);
      lastGoodHeightPx = heightPx;
      fabOffset = Offset(
        size.width - 14 - 132,
        (size.height * 0.66).clamp(padding.top + 8, size.height - padding.bottom - 48),
      );
      return true;
    }
    final clamped = heightPx.clamp(44.0, maxHeight);
    final fab = _clampFab(fabOffset, size, padding, const Size(132, 36));
    final changed = clamped != heightPx || fab != fabOffset;
    heightPx = clamped;
    lastGoodHeightPx = lastGoodHeightPx.clamp(44.0, maxHeight);
    fabOffset = fab;
    return changed;
  }

  /// Locked → interactive.
  void activate() {
    if (mode == OverlayMode.interactive) return;
    mode = OverlayMode.interactive;
    showToast('Logger interactive');
    notifyListeners();
  }

  /// Interactive → locked. Closes the detail sheet.
  void lock() {
    mode = OverlayMode.locked;
    selectedNetworkId = null;
    showToast('Locked · taps pass through');
    notifyListeners();
  }

  /// Hides the panel and shows the floating button.
  void minimize() {
    mode = OverlayMode.minimized;
    selectedNetworkId = null;
    notifyListeners();
  }

  /// Floating button → locked panel at [lastGoodHeightPx].
  void restore() {
    mode = OverlayMode.locked;
    heightPx = lastGoodHeightPx;
    notifyListeners();
  }

  /// Switches top and bottom, keeping the height.
  void toggleDock() {
    dock = dock == DockPosition.bottom ? DockPosition.top : DockPosition.bottom;
    showToast(dock == DockPosition.top ? 'Docked to top' : 'Docked to bottom');
    notifyListeners();
  }

  /// Live height while the slab is dragged. Does not update [lastGoodHeightPx].
  void setHeight(double height) {
    heightPx = height;
    notifyListeners();
  }

  /// Remembers [heightPx] after a drag that stayed above the minimise threshold.
  void commitHeight() {
    lastGoodHeightPx = heightPx;
    notifyListeners();
  }

  /// Switches between logs and network.
  void setTab(LoggerTab value) {
    if (tab == value) return;
    tab = value;
    selectedNetworkId = null;
    notifyListeners();
  }

  /// Sets the level chip. Null is ALL.
  void setLevelFilter(LogLevel? level) {
    levelFilter = level;
    notifyListeners();
  }

  /// Sets the search string.
  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  /// Expands or collapses a log row.
  void toggleExpanded(int id) {
    if (!expandedLogIds.add(id)) expandedLogIds.remove(id);
    notifyListeners();
  }

  /// Opens or closes the network detail sheet.
  void selectNetwork(int? id) {
    selectedNetworkId = id;
    notifyListeners();
  }

  /// Moves the floating button.
  void setFabOffset(Offset offset, {required bool dragging}) {
    fabOffset = offset;
    fabDragging = dragging;
    notifyListeners();
  }

  /// Shows [message] for 1.4 seconds.
  void showToast(String message) {
    toast = message;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 1400), () {
      toast = null;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Keeps the button inside the safe area.
  Offset clampFab(Offset offset, Size screen, EdgeInsets padding, Size fabSize) =>
      _clampFab(offset, screen, padding, fabSize);

  Offset _clampFab(Offset offset, Size screen, EdgeInsets padding, Size fabSize) {
    final maxX = (screen.width - fabSize.width - 8).clamp(8.0, screen.width);
    final minY = padding.top + 8;
    final maxY = (screen.height - padding.bottom - fabSize.height - 8).clamp(minY, screen.height);
    return Offset(
      offset.dx.clamp(8.0, maxX),
      offset.dy.clamp(minY, maxY),
    );
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}
