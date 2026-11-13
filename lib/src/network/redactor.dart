/// Masks header values whose names are on the redact list.
class Redactor {
  Redactor._();

  /// True when [name] is on [names], ignoring case.
  static bool shouldRedact(String name, List<String> names) {
    final lower = name.toLowerCase();
    for (final candidate in names) {
      if (candidate.toLowerCase() == lower) return true;
    }
    return false;
  }

  /// Short preview for the UI: first 4 characters, ellipsis, last 3.
  ///
  /// Values of 8 characters or fewer become `••••`.
  static String preview(String value) {
    if (value.length <= 8) return '••••';
    return '${value.substring(0, 4)}…${value.substring(value.length - 3)}';
  }

  /// Full replacement used in cURL and clipboard exports.
  static const String masked = '<redacted>';

  /// Header map for display. Secret values are [preview]ed.
  static Map<String, String> forDisplay(
    Map<String, String> headers,
    List<String> names,
  ) =>
      headers.map(
        (key, value) => MapEntry(
          key,
          shouldRedact(key, names) ? preview(value) : value,
        ),
      );

  /// Header map for export. Secret values are fully [masked].
  static Map<String, String> forExport(
    Map<String, String> headers,
    List<String> names,
  ) =>
      headers.map(
        (key, value) => MapEntry(
          key,
          shouldRedact(key, names) ? masked : value,
        ),
      );
}
