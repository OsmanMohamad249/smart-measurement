import 'package:flutter/material.dart';

/// Displays a circular ring that reflects how stable the device is.
/// The ring animates between red (unstable), yellow (medium), and green (stable).
class StabilityRing extends StatelessWidget {
  final double stabilityScore; // Expected range: 0.0 - 1.0
  final double diameter;
  final double minStrokeWidth;
  final double maxStrokeWidth;
  final Duration animationDuration;

  const StabilityRing({
    super.key,
    required this.stabilityScore,
    this.diameter = 260,
    this.minStrokeWidth = 3,
    this.maxStrokeWidth = 9,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  Color _colorForScore(double score) {
    if (score >= 0.9) return Colors.green;
    if (score >= 0.75) return Colors.yellow.shade700;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final clampedScore = stabilityScore.clamp(0.0, 1.0);
    final targetColor = _colorForScore(clampedScore);
    final strokeWidth =
        minStrokeWidth + (maxStrokeWidth - minStrokeWidth) * clampedScore;

    return Center(
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: targetColor,
            width: strokeWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: targetColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
