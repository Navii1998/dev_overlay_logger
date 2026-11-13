import 'dart:typed_data';

import 'package:dev_overlay_logger/dev_overlay_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    DevLogger.init(
      const DevLoggerConfig(
        enabled: true,
        captureFlutterErrors: false,
        capturePlatformErrors: false,
        redactHeaders: ['authorization'],
      ),
    );
  });
  tearDown(DevLogger.reset);

  test('records status, duration and the raw authorization header', () async {
    final dio = Dio()
      ..httpClientAdapter = _Adapter((_) async {
        return ResponseBody.fromString(
          '{"ok":true}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });
    dio.interceptors.add(DevLoggerDioInterceptor(client: dio));

    await dio.get<dynamic>(
      'https://api.example.com/v1/items',
      options: Options(headers: {'Authorization': 'Bearer super-secret-token'}),
    );

    final call = DevLogger.store.network.single;
    expect(call.status, 200);
    expect(call.state, NetworkState.success);
    expect(call.duration, isNotNull);
    expect(call.requestHeaders['Authorization'], 'Bearer super-secret-token');
    expect(call.retry, isNotNull);
    expect(
      DevLogger.store.logs.map((entry) => entry.message).first,
      '→ GET /v1/items',
    );
  });

  test('a timeout is a failed call with a readable message', () async {
    final dio = Dio()
      ..httpClientAdapter = _Adapter(
        (options) => Future<ResponseBody>.error(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
            message: 'timed out',
          ),
        ),
      );
    dio.interceptors.add(DevLoggerDioInterceptor());

    await expectLater(
      dio.get<dynamic>('https://api.example.com/v1/slow'),
      throwsA(isA<DioException>()),
    );

    final call = DevLogger.store.network.single;
    expect(call.state, NetworkState.failed);
    expect(call.errorMessage, 'Connection timeout');
  });

  test('FormData is stored as a placeholder', () async {
    final dio = Dio()..httpClientAdapter = _Adapter((_) async => ResponseBody.fromString('{}', 201));
    dio.interceptors.add(DevLoggerDioInterceptor());
    final form = FormData.fromMap({
      'title': 'schedule',
      'file': MultipartFile.fromBytes([1, 2, 3], filename: 'a.jpg'),
    });
    await dio.post<dynamic>('https://api.example.com/v1/upload', data: form);
    expect(DevLogger.store.network.single.requestBody, '<FormData: 1 fields, 1 files>');
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this._handle);

  final Future<ResponseBody> Function(RequestOptions options) _handle;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _handle(options);

  @override
  void close({bool force = false}) {}
}
