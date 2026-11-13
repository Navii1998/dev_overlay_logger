/// `HH:mm:ss.SSS` in local time.
String formatClock(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}'
      '.${time.millisecond.toString().padLeft(3, '0')}';
}

/// `142 ms`, or `…` when the call has not finished.
String formatDuration(Duration? duration) {
  if (duration == null) return '…';
  return '${duration.inMilliseconds} ms';
}
