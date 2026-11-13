import 'dart:async';

import 'package:dev_overlay_logger/src/core/log_entry.dart';
import 'package:dev_overlay_logger/src/core/log_level.dart';
import 'package:dev_overlay_logger/src/core/network_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Ring buffers for log lines and network calls.
///
/// List listeners are notified at most once per frame. [errorCount],
/// [warningCount] and [networkCount] update immediately so the slab badges
/// can rebuild without rebuilding the lists.
class LogStore extends ChangeNotifier {
  /// Creates empty buffers.
  LogStore({this.maxLogs = 1000, this.maxNetwork = 300});

  /// Maximum log lines kept. Oldest are dropped.
  final int maxLogs;

  /// Maximum network calls kept. Oldest are dropped.
  final int maxNetwork;

  final List<LogEntry> _logs = [];
  final List<NetworkEntry> _network = [];
  int _nextId = 0;
  bool _notifyScheduled = false;

  final StreamController<LogEntry> _onLog = StreamController<LogEntry>.broadcast();

  /// Fires for every log line that is kept (not dropped by [paused]).
  Stream<LogEntry> get onLog => _onLog.stream;

  /// Log lines, oldest first.
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Network calls, oldest first. The UI shows newest first.
  List<NetworkEntry> get network => List.unmodifiable(_network);

  /// Error lines currently in the buffer.
  final ValueNotifier<int> errorCount = ValueNotifier<int>(0);

  /// Warning lines currently in the buffer.
  final ValueNotifier<int> warningCount = ValueNotifier<int>(0);

  /// Network calls currently in the buffer.
  final ValueNotifier<int> networkCount = ValueNotifier<int>(0);

  /// When true, new lines and new calls are discarded.
  final ValueNotifier<bool> pausedListenable = ValueNotifier<bool>(false);

  /// Whether capture is paused.
  bool get paused => pausedListenable.value;

  set paused(bool value) {
    if (pausedListenable.value == value) return;
    pausedListenable.value = value;
  }

  /// Appends a log line, dropping the oldest when over [maxLogs].
  void addLog(LogEntry entry) {
    if (paused) return;
    final stored = LogEntry(
      id: ++_nextId,
      time: entry.time,
      level: entry.level,
      tag: entry.tag,
      message: entry.message,
      error: entry.error,
      stackTrace: entry.stackTrace,
      data: entry.data,
    );
    _logs.add(stored);
    _bump(stored.level, 1);
    if (_logs.length > maxLogs) {
      _bump(_logs.removeAt(0).level, -1);
    }
    if (!_onLog.isClosed) _onLog.add(stored);
    _scheduleNotify();
  }

  /// Starts a network call. Returns -1 when [paused] so the caller can skip it.
  int addNetwork(NetworkEntry entry) {
    if (paused) return -1;
    entry.id = ++_nextId;
    _network.add(entry);
    if (_network.length > maxNetwork) {
      _network.removeAt(0);
    }
    networkCount.value = _network.length;
    _scheduleNotify();
    return entry.id;
  }

  /// Returns the call with [id], or null if it was dropped.
  NetworkEntry? findNetwork(int id) {
    for (final entry in _network) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Notifies listeners that an existing call changed.
  void touchNetwork() => _scheduleNotify();

  /// Removes every log line and resets the level counters.
  void clearLogs() {
    _logs.clear();
    errorCount.value = 0;
    warningCount.value = 0;
    _scheduleNotify();
  }

  /// Removes every network call.
  void clearNetwork() {
    _network.clear();
    networkCount.value = 0;
    _scheduleNotify();
  }

  int _nonNegative(int value) => value < 0 ? 0 : value;

  void _bump(LogLevel level, int delta) {
    switch (level) {
      case LogLevel.error:
        errorCount.value = _nonNegative(errorCount.value + delta);
      case LogLevel.warning:
        warningCount.value = _nonNegative(warningCount.value + delta);
      case LogLevel.verbose:
      case LogLevel.debug:
      case LogLevel.info:
        break;
    }
  }

  void _scheduleNotify() {
    if (!hasListeners || _notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _notifyScheduled = false;
      if (hasListeners) notifyListeners();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    errorCount.dispose();
    warningCount.dispose();
    networkCount.dispose();
    pausedListenable.dispose();
    unawaited(_onLog.close());
    super.dispose();
  }
}
