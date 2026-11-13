import 'dart:convert';

import 'package:dev_overlay_logger/src/network/redactor.dart';

/// Builds a copy-pasteable cURL command.
class CurlBuilder {
  CurlBuilder._();

  /// `curl -X METHOD 'url' -H 'Name: value' --data-raw 'body'`.
  ///
  /// Secret headers are fully masked unless [includeSecrets] is true.
  static String build({
    required String method,
    required Uri uri,
    Map<String, String> headers = const {},
    Object? body,
    List<String> redactHeaders = const [],
    bool includeSecrets = false,
  }) {
    final buffer = StringBuffer("curl -X $method '${_quote(uri.toString())}'");
    final visible = includeSecrets
        ? headers
        : Redactor.forExport(headers, redactHeaders);
    visible.forEach((key, value) {
      buffer.write(" -H '${_quote('$key: $value')}'");
    });
    final raw = _body(body);
    if (raw != null && raw.isNotEmpty) {
      buffer.write(" --data-raw '${_quote(raw)}'");
    }
    return buffer.toString();
  }

  static String? _body(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } on Object {
      return body.toString();
    }
  }

  /// Escapes a string so it is safe inside single quotes.
  static String _quote(String value) => value.replaceAll("'", r"'\''");
}
