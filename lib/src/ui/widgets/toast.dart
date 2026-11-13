import 'package:flutter/material.dart';

/// Dark pill near the top of the screen. Shown for 1.4 seconds.
class LoggerToast extends StatelessWidget {
  /// Creates a toast. A null [message] draws nothing.
  const LoggerToast({required this.message, super.key});

  /// Toast text.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    return Positioned(
      top: 60,
      left: 24,
      right: 24,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}
