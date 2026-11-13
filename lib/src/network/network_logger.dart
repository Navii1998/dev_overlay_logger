import 'dart:convert';

import 'package:dev_overlay_logger/src/core/dev_logger.dart';
import 'package:dev_overlay_logger/src/core/network_entry.dart';

/// Adapter-agnostic network capture.
///
/// Dio uses [DevLoggerDioInterceptor]. Other clients call [start] before the
/// request and [complete] or [fail] when it finishes, or [record] when they
/// only learn about the call afterwards.
class NetworkLogger {
  NetworkLogger._();

  /// Records a request that just started. Returns an id for [complete] / [fail].
  ///
  /// Returns -1 when the logger is off or paused.
  static int start({
    required String method,
    required Uri uri,
    Map<String, String> headers = const {},
    Object? body,
    String tag = 'Dio',
    Future<void> Function()? retry,
  }) {
    if (!DevLogger.enabled) return -1;
    final entry = NetworkEntry(
      id: 0,
      startTime: DateTime.now(),
      method: method.toUpperCase(),
      uri: uri,
      requestHeaders: Map<String, String>.from(headers),
      requestBody: body,
      tag: tag,
      retry: retry,
    );
    final id = DevLogger.store.addNetwork(entry);
    if (id < 0) return id;
    DevLogger.d('→ ${entry.method} ${entry.pathAndQuery}', tag: tag);
    return id;
  }

  /// Fills in a successful or HTTP-error response for [id].
  ///
  /// Status codes of 400 and above are stored as failures and logged at error.
  static void complete(
    int id, {
    required int status,
    Map<String, String> headers = const {},
    Object? body,
    int? sizeBytes,
    Duration? elapsed,
  }) {
    final entry = _entry(id);
    if (entry == null) return;
    entry
      ..status = status
      ..responseHeaders = Map<String, String>.from(headers)
      ..responseBody = body
      ..responseSizeBytes = sizeBytes ?? _sizeOf(body)
      ..duration = elapsed ?? DateTime.now().difference(entry.startTime)
      ..state = status >= 400 ? NetworkState.failed : NetworkState.success;
    DevLogger.store.touchNetwork();
    final line =
        '← $status ${entry.method} ${entry.pathAndQuery} (${entry.duration!.inMilliseconds}ms)';
    if (status >= 400) {
      DevLogger.e(line, tag: entry.tag, error: 'HTTP $status');
    } else {
      DevLogger.i(line, tag: entry.tag);
    }
  }

  /// Marks [id] as failed. [status] is set when the server did respond.
  static void fail(
    int id, {
    int? status,
    String message = 'Request failed',
    Object? body,
    Duration? elapsed,
    StackTrace? stackTrace,
  }) {
    final entry = _entry(id);
    if (entry == null) return;
    entry
      ..status = status
      ..responseBody = body
      ..errorMessage = message
      ..duration = elapsed ?? DateTime.now().difference(entry.startTime)
      ..state = NetworkState.failed
      ..responseSizeBytes = entry.responseSizeBytes ?? _sizeOf(body);
    DevLogger.store.touchNetwork();
    final statusText = status == null ? '' : '$status ';
    DevLogger.e(
      '← $statusText${entry.method} ${entry.pathAndQuery} (${entry.duration!.inMilliseconds}ms)',
      tag: entry.tag,
      error: message,
      stackTrace: stackTrace,
    );
  }

  /// Records a call that has already finished.
  ///
  /// Used by clients that log after the response, so there is no pending row.
  /// A null [status] with [errorMessage] is a transport failure.
  static void record({
    required String method,
    required Uri uri,
    Map<String, String> headers = const {},
    Object? requestBody,
    Map<String, String> responseHeaders = const {},
    Object? responseBody,
    int? status,
    Duration? elapsed,
    int? sizeBytes,
    String? errorMessage,
    String tag = 'HTTP',
    StackTrace? stackTrace,
  }) {
    final id = start(
      method: method,
      uri: uri,
      headers: headers,
      body: requestBody,
      tag: tag,
    );
    if (id < 0) return;
    final failed = status == null || status >= 400 || errorMessage != null;
    if (failed) {
      fail(
        id,
        status: status,
        message: errorMessage ?? (status == null ? 'Request failed' : 'HTTP $status'),
        body: responseBody,
        elapsed: elapsed,
        stackTrace: stackTrace,
      );
      return;
    }
    complete(
      id,
      status: status,
      headers: responseHeaders,
      body: responseBody,
      sizeBytes: sizeBytes,
      elapsed: elapsed,
    );
  }

  static NetworkEntry? _entry(int id) {
    if (id < 0 || !DevLogger.enabled) return null;
    return DevLogger.store.findNetwork(id);
  }

  static int? _sizeOf(Object? body) {
    if (body == null) return null;
    try {
      final text = body is String ? body : jsonEncode(body);
      return utf8.encode(text).length;
    } on Object {
      return body.toString().length;
    }
  }
}
