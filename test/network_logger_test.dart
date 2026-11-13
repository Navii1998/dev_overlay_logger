import 'package:dev_overlay_logger/dev_overlay_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    DevLogger.init(
      const DevLoggerConfig(
        enabled: true,
        captureFlutterErrors: false,
        capturePlatformErrors: false,
      ),
    );
  });
  tearDown(DevLogger.reset);

  test('start then complete updates the same call and writes D and I lines', () {
    final id = NetworkLogger.start(
      method: 'get',
      uri: Uri.parse('https://api.example.com/v1/streams?type=past'),
    );
    NetworkLogger.complete(id, status: 200, body: '{"ok":true}', elapsed: const Duration(milliseconds: 610));

    final call = DevLogger.store.network.single;
    expect(call.id, id);
    expect(call.status, 200);
    expect(call.state, NetworkState.success);
    expect(call.duration!.inMilliseconds, 610);
    expect(
      DevLogger.store.logs.map((entry) => '${entry.level.short} ${entry.message}'),
      [
        'D → GET /v1/streams?type=past',
        'I ← 200 GET /v1/streams?type=past (610ms)',
      ],
    );
  });

  test('status 400 and fail() are error lines', () {
    final failed = NetworkLogger.start(
      method: 'GET',
      uri: Uri.parse('https://api.example.com/v1/streams/5/products'),
    );
    NetworkLogger.complete(failed, status: 500, elapsed: const Duration(milliseconds: 820));

    final timedOut = NetworkLogger.start(
      method: 'GET',
      uri: Uri.parse('https://api.example.com/v1/cart'),
    );
    NetworkLogger.fail(timedOut, message: 'Connection timeout');

    expect(DevLogger.store.network.first.state, NetworkState.failed);
    expect(DevLogger.store.network.last.state, NetworkState.failed);
    expect(DevLogger.store.network.last.errorMessage, 'Connection timeout');
    expect(DevLogger.store.errorCount.value, 2);
  });
}
