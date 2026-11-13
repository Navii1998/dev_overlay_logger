/// Lifecycle of a captured HTTP call.
enum NetworkState {
  /// Request sent, no response yet.
  pending,

  /// Response received with status below 400.
  success,

  /// Status 400+, timeout, or connection failure.
  failed,
}

/// One captured HTTP call. Fields that describe the response are filled in
/// when the call completes. The store notifies listeners after each update.
class NetworkEntry {
  /// Creates a call that has just started.
  NetworkEntry({
    required this.id,
    required this.startTime,
    required this.method,
    required this.uri,
    required this.requestHeaders,
    this.requestBody,
    this.tag = 'Dio',
    this.retry,
  });

  /// Monotonic id assigned by the store.
  int id;

  /// When the request was sent.
  final DateTime startTime;

  /// HTTP method, upper case (`GET`, `POST`, …).
  final String method;

  /// Full request URI.
  final Uri uri;

  /// Request headers as sent. The UI masks secret values.
  final Map<String, String> requestHeaders;

  /// Request body. `FormData`, bytes and streams are stored as placeholders.
  final Object? requestBody;

  /// Tag written on the matching log lines. `Dio` for the Dio adapter.
  final String tag;

  /// Re-issues the call when the adapter stored a Dio instance. Null hides
  /// the Retry button.
  final Future<void> Function()? retry;

  /// Response status. Null while [state] is [NetworkState.pending].
  int? status;

  /// Response headers. Empty until the call finishes.
  Map<String, String> responseHeaders = const {};

  /// Response body.
  Object? responseBody;

  /// Time from start to complete or fail.
  Duration? duration;

  /// Response body size in bytes.
  int? responseSizeBytes;

  /// Timeout, connection, or HTTP error text.
  String? errorMessage;

  /// Current lifecycle.
  NetworkState state = NetworkState.pending;

  /// Path plus query, matching the overlay rows (`/streams?type=past`).
  String get pathAndQuery {
    final path = uri.path.isEmpty ? '/' : uri.path;
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
}
