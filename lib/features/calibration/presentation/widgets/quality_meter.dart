import 'package:flutter/material.dart';

/// Visualizes the current card-detection quality score (0.0 - 1.0).
class QualityMeter extends StatelessWidget {
  final double qualityScore;
  final double width;
  final double height;
  final Duration animationDuration;

  const QualityMeter({
    super.key,
    required this.qualityScore,
    this.width = 220,
    this.height = 18,
    this.animationDuration = const Duration(milliseconds: 350),
  });

  Color _colorForScore(double score) {
    if (score >= 0.9) return Colors.green;
    if (score >= 0.75) return Colors.yellow.shade700;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final clampedScore = qualityScore.clamp(0.0, 1.0);
    final color = _colorForScore(clampedScore);

    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: clampedScore),
              duration: animationDuration,
              curve: Curves.easeOut,
              builder: (context, animatedValue, _) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: animatedValue,
                      child: Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(height / 2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(clampedScore * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

