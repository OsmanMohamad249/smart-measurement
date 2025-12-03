import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;

/// Dynamic polygon overlay widget for card corner visualization.
///
/// This widget displays detected card corners on the camera preview
/// to provide visual feedback during calibration.
class PolygonOverlay extends StatefulWidget {
  /// Detected card corners (top-left, top-right, bottom-right, bottom-left).
  final List<Vector2>? corners;

  /// Color of the corner markers and connecting lines.
  final Color borderColor;

  /// Width of the border lines.
  final double borderWidth;

  /// Fill color of the polygon (with transparency).
  final Color? fillColor;

  /// Whether the corners represent a valid card shape.
  final bool isValid;

  const PolygonOverlay({
    super.key,
    this.corners,
    this.borderColor = Colors.greenAccent,
    this.borderWidth = 3.0,
    this.fillColor,
    this.isValid = false,
  });

  @override
  State<PolygonOverlay> createState() => _PolygonOverlayState();
}

class _PolygonOverlayState extends State<PolygonOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: CardCornersPainter(
            corners: widget.corners,
            borderColor: widget.isValid
                ? Colors.green
                : widget.borderColor.withValues(alpha: _pulseAnimation.value),
            borderWidth: widget.borderWidth,
            fillColor: widget.fillColor,
            pulseValue: _pulseAnimation.value,
          ),
        );
      },
    );
  }
}

/// Custom painter for drawing detected card corners.
class CardCornersPainter extends CustomPainter {
  final List<Vector2>? corners;
  final Color borderColor;
  final double borderWidth;
  final Color? fillColor;
  final double pulseValue;

  const CardCornersPainter({
    required this.corners,
    required this.borderColor,
    required this.borderWidth,
    required this.fillColor,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners == null || corners!.length != 4) return;

    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor ?? borderColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Draw filled polygon
    final path = Path();
    path.moveTo(corners![0].x, corners![0].y);
    for (int i = 1; i < corners!.length; i++) {
      path.lineTo(corners![i].x, corners![i].y);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Draw corner circles
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    for (final corner in corners!) {
      canvas.drawCircle(
        Offset(corner.x, corner.y),
        8.0 * pulseValue,
        cornerPaint,
      );

      // Draw white center
      canvas.drawCircle(
        Offset(corner.x, corner.y),
        4.0,
        Paint()..color = Colors.white,
      );
    }

    // Draw corner labels
    _drawCornerLabels(canvas, size);
  }

  void _drawCornerLabels(Canvas canvas, Size size) {
    if (corners == null || corners!.length != 4) return;

    final labels = ['TL', 'TR', 'BR', 'BL'];
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < corners!.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 3,
              color: Colors.black,
            ),
          ],
        ),
      );

      textPainter.layout();

      final offset = Offset(
        corners![i].x - textPainter.width / 2,
        corners![i].y - textPainter.height - 12,
      );

      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(CardCornersPainter oldDelegate) {
    return corners != oldDelegate.corners ||
        borderColor != oldDelegate.borderColor ||
        pulseValue != oldDelegate.pulseValue;
  }
}

