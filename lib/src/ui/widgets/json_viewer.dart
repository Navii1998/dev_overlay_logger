import 'package:dev_overlay_logger/src/ui/theme/logger_theme.dart';
import 'package:dev_overlay_logger/src/utils/json_pretty.dart';
import 'package:flutter/material.dart';

/// Selectable, syntax-coloured JSON. Truncates at [maxChars] until Show all.
class JsonViewer extends StatefulWidget {
  /// Creates a viewer for [value].
  const JsonViewer({
    required this.value,
    required this.maxChars,
    this.emptyText = '(no body)',
    super.key,
  });

  /// Map, list, JSON string, or any other object.
  final Object? value;

  /// Character budget before truncation.
  final int maxChars;

  /// Shown when [value] is null or empty.
  final String emptyText;

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = LoggerThemeScope.of(context);
    final raw = prettyJson(widget.value);
    if (raw.isEmpty) {
      return Text(widget.emptyText, style: theme.mono.copyWith(color: theme.textMuted));
    }
    final truncated = raw.length > widget.maxChars;
    final shown = _showAll || !truncated ? raw : raw.substring(0, widget.maxChars);
    final colorize = _showAll || !truncated;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText.rich(
          colorize ? _colorize(shown, theme) : TextSpan(text: shown, style: theme.mono),
          style: theme.mono,
        ),
        if (truncated && !_showAll)
          TextButton(
            onPressed: () => setState(() => _showAll = true),
            child: const Text('Show all'),
          ),
      ],
    );
  }

  TextSpan _colorize(String source, DevLoggerTheme theme) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'"(?:\\.|[^"\\])*"|\b(?:true|false|null)\b|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?|.',
      dotAll: true,
    );
    for (final match in pattern.allMatches(source)) {
      final token = match.group(0)!;
      var style = theme.mono;
      if (token.startsWith('"')) {
        final next = source.indexOf(RegExp(r'\S'), match.end);
        final isKey = next >= 0 && source[next] == ':';
        style = theme.mono.copyWith(color: isKey ? theme.jsonKey : theme.jsonString);
      } else if (token == 'true' || token == 'false' || token == 'null') {
        style = theme.mono.copyWith(color: theme.jsonLiteral);
      } else if (RegExp(r'^-?\d').hasMatch(token)) {
        style = theme.mono.copyWith(color: theme.jsonNumber);
      }
      spans.add(TextSpan(text: token, style: style));
    }
    return TextSpan(children: spans, style: theme.mono);
  }
}
