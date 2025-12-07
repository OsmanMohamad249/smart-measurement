import 'package:flutter/material.dart';

class CountdownOverlay extends StatelessWidget {
  const CountdownOverlay({
    super.key,
    required this.countdown,
    required this.isVisible,
  });

  final int countdown;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible || countdown <= 0) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Center(
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              '$countdown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

