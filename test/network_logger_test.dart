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

  test('setCaptureEnabled pauses capture and resumes into the same store', () {
    DevLogger.e('kept');
    final store = DevLogger.store;
    expect(store.errorCount.value, 1);
    expect(DevLogger.captureEnabledValue, isTrue);

    DevLogger.setCaptureEnabled(false);
    expect(DevLogger.captureEnabledValue, isFalse);
    expect(DevLogger.enabled, isFalse);
    DevLogger.d('dropped');
    NetworkLogger.record(
      method: 'GET',
      uri: Uri.parse('https://api.example.com/v1/dropped'),
      status: 200,
    );
    expect(store.logs.map((entry) => entry.message), ['kept']);
    expect(store.network, isEmpty);
    expect(store.errorCount.value, 1);
    expect(identical(DevLogger.store, store), isTrue);

    DevLogger.setCaptureEnabled(true);
    expect(DevLogger.captureEnabledValue, isTrue);
    expect(DevLogger.enabled, isTrue);
    DevLogger.d('again');
    NetworkLogger.record(
      method: 'POST',
      uri: Uri.parse('https://api.example.com/v1/again'),
      status: 201,
    );
    expect(identical(DevLogger.store, store), isTrue);
    expect(store.logs.map((entry) => entry.message), contains('again'));
    expect(store.network.single.uri.path, '/v1/again');
    expect(store.errorCount.value, 1);
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
