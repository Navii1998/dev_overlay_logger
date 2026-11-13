import 'package:dev_overlay_logger/dev_overlay_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(DevLogger.reset);

  DevLoggerConfig config({int maxLogs = 1000}) => DevLoggerConfig(
        enabled: true,
        maxLogs: maxLogs,
        captureFlutterErrors: false,
        capturePlatformErrors: false,
      );

  test('ring buffer drops the oldest log', () {
    DevLogger.init(config(maxLogs: 3));
    DevLogger.i('a');
    DevLogger.i('b');
    DevLogger.i('c');
    DevLogger.i('d');
    expect(DevLogger.store.logs.map((entry) => entry.message), ['b', 'c', 'd']);
  });

  test('counters track warnings and errors still in the buffer', () {
    DevLogger.init(config(maxLogs: 2));
    DevLogger.w('slow');
    DevLogger.e('boom');
    expect(DevLogger.store.warningCount.value, 1);
    expect(DevLogger.store.errorCount.value, 1);
    DevLogger.i('next');
    expect(DevLogger.store.warningCount.value, 0);
    expect(DevLogger.store.errorCount.value, 1);
  });

  test('pause drops new lines and clear empties the buffer', () {
    DevLogger.init(config());
    DevLogger.i('kept');
    DevLogger.store.paused = true;
    DevLogger.e('dropped');
    expect(DevLogger.store.logs.map((entry) => entry.message), ['kept']);
    expect(DevLogger.store.errorCount.value, 0);
    DevLogger.store.paused = false;
    DevLogger.store.clearLogs();
    expect(DevLogger.store.logs, isEmpty);
  });

  test('disabled logger allocates nothing', () {
    DevLogger.init(const DevLoggerConfig(enabled: false));
    DevLogger.e('nope');
    expect(DevLogger.enabled, isFalse);
  });
}
