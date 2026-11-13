import 'dart:convert';

import 'package:dev_overlay_logger/src/network/network_logger.dart';
import 'package:dio/dio.dart';

/// Dio adapter. This is the only file in the package that imports `dio`.
///
/// ```dart
/// dio.interceptors.add(DevLoggerDioInterceptor());
/// ```
///
/// Retry reuses [client]. Set it to the same `Dio` the interceptor was added
/// to. When it is null the detail sheet hides the Retry button.
class DevLoggerDioInterceptor extends Interceptor {
  /// Creates an interceptor. [tag] is written on the matching log lines.
  DevLoggerDioInterceptor({this.tag = 'Dio', this.client});

  /// Log tag. Defaults to `Dio`.
  final String tag;

  /// Client used by the Retry button. Null hides the button.
  Dio? client;

  static const _idKey = 'dev_overlay_logger_id';
  static const _watchKey = 'dev_overlay_logger_sw';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final watch = Stopwatch()..start();
    options.extra[_watchKey] = watch;
    final id = NetworkLogger.start(
      method: options.method,
      uri: options.uri,
      headers: _stringHeaders(options.headers),
      body: _safeBody(options.data),
      tag: tag,
      retry: client == null ? null : () => _retry(options),
    );
    options.extra[_idKey] = id;
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final id = response.requestOptions.extra[_idKey] as int? ?? -1;
    final watch = response.requestOptions.extra[_watchKey] as Stopwatch?;
    watch?.stop();
    NetworkLogger.complete(
      id,
      status: response.statusCode ?? 0,
      headers: _flatten(response.headers),
      body: _safeBody(response.data),
      sizeBytes: _size(response),
      elapsed: watch?.elapsed,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final id = err.requestOptions.extra[_idKey] as int? ?? -1;
    final watch = err.requestOptions.extra[_watchKey] as Stopwatch?;
    watch?.stop();
    NetworkLogger.fail(
      id,
      status: err.response?.statusCode,
      message: _message(err),
      body: _safeBody(err.response?.data),
      elapsed: watch?.elapsed,
    );
    handler.next(err);
  }

  Future<void> _retry(RequestOptions options) async {
    final dio = client;
    if (dio == null) return;
    final extra = Map<String, dynamic>.from(options.extra)
      ..remove(_idKey)
      ..remove(_watchKey);
    await dio.fetch<dynamic>(options.copyWith(extra: extra));
  }

  static Map<String, String> _stringHeaders(Map<String, dynamic> headers) {
    final out = <String, String>{};
    headers.forEach((key, value) {
      if (value == null) return;
      out[key] = value is Iterable ? value.join(', ') : value.toString();
    });
    return out;
  }

  static Map<String, String> _flatten(Headers headers) => {
        for (final entry in headers.map.entries) entry.key: entry.value.join(', '),
      };

  static Object? _safeBody(Object? data) {
    if (data == null) return null;
    if (data is FormData) {
      return '<FormData: ${data.fields.length} fields, ${data.files.length} files>';
    }
    if (data is List<int>) return '<bytes: ${data.length}>';
    if (data is Stream) return '<stream>';
    return data;
  }

  static int? _size(Response<dynamic> response) {
    final header = response.headers.value(Headers.contentLengthHeader);
    final parsed = header == null ? null : int.tryParse(header);
    if (parsed != null) return parsed;
    final data = response.data;
    if (data == null) return null;
    if (data is List<int>) return data.length;
    try {
      return utf8.encode(data.toString()).length;
    } on Object {
      return null;
    }
  }

  static String _message(DioException err) => switch (err.type) {
        DioExceptionType.connectionTimeout => 'Connection timeout',
        DioExceptionType.sendTimeout => 'Send timeout',
        DioExceptionType.receiveTimeout => 'Receive timeout',
        DioExceptionType.badCertificate => 'Bad certificate',
        DioExceptionType.badResponse =>
          'Bad response ${err.response?.statusCode ?? ''}'.trim(),
        DioExceptionType.cancel => 'Cancelled',
        DioExceptionType.connectionError => 'No connection',
        DioExceptionType.unknown => err.message ?? 'Network error',
      };
}
