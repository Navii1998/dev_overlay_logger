import 'dart:convert';

/// Pretty JSON for a decoded value or a JSON string. Anything else is [toString].
String prettyJson(Object? value) {
  if (value == null) return '';
  final decoded = _decode(value);
  try {
    return const JsonEncoder.withIndent('  ').convert(decoded);
  } on Object {
    return decoded.toString();
  }
}

Object? _decode(Object? value) {
  if (value is! String) return value;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return value;
  if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return value;
  try {
    return jsonDecode(trimmed);
  } on FormatException {
    return value;
  }
}
