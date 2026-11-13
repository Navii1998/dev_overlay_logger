import 'package:flutter/material.dart';

/// Small count chip used on the slab and the floating button.
class CountBadge extends StatelessWidget {
  /// Creates a badge.
  const CountBadge({
    required this.label,
    required this.background,
    required this.foreground,
    super.key,
  });

  /// Text, for example `E 2` or `API 4`.
  final String label;

  /// Chip fill.
  final Color background;

  /// Chip text.
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Menlo', 'Courier New'],
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      );
}
