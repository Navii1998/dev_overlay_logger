import 'package:flutter/material.dart';

/// Blue fill that sweeps left to right across the slab during the unlock hold.
class HoldProgress extends StatelessWidget {
  /// Creates a progress fill. [progress] is 0 to 1.
  const HoldProgress({required this.progress, super.key});

  /// Fraction of the slab that is filled.
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        heightFactor: 1,
        child: const ColoredBox(color: Color(0x593A7BFF)),
      ),
    );
  }
}
