/// Byte count as `B` or `KB`.
String formatBytes(int? bytes, {int fractionDigits = 1}) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';
  return '${(bytes / 1024).toStringAsFixed(fractionDigits)} KB';
}
