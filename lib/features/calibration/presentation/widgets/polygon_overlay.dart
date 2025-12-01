import 'package:flutter/material.dart';

/// Dynamic polygon overlay widget for body positioning guidance.
///
/// This widget displays a customizable polygon overlay on the camera preview
/// to guide users in positioning themselves correctly for body measurement.
/// The polygon can be updated dynamically based on pose detection results.
class PolygonOverlay extends StatefulWidget {
  /// Points defining the polygon vertices.
  final List<Offset>? polygonPoints;

  /// Color of the polygon border.
  final Color borderColor;

  /// Width of the polygon border.
  final double borderWidth;

  /// Fill color of the polygon (with transparency).
  final Color? fillColor;

  /// Whether to show the default body outline guide.
  final bool showDefaultGuide;

  /// Whether the current position is correct.
  final bool isPositionCorrect;

  const PolygonOverlay({
    super.key,
    this.polygonPoints,
    this.borderColor = Colors.greenAccent,
    this.borderWidth = 3.0,
    this.fillColor,
    this.showDefaultGuide = true,
    this.isPositionCorrect = false,
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
          painter: PolygonOverlayPainter(
            polygonPoints: widget.polygonPoints,
            borderColor: widget.isPositionCorrect
                ? Colors.green
                : widget.borderColor.withOpacity(_pulseAnimation.value),
            borderWidth: widget.borderWidth,
            fillColor: widget.fillColor,
            showDefaultGuide: widget.showDefaultGuide,
            pulseValue: _pulseAnimation.value,
          ),
        );
      },
    );
  }
}

/// Custom painter for drawing the polygon overlay.
class PolygonOverlayPainter extends CustomPainter {
  final List<Offset>? polygonPoints;
  final Color borderColor;
  final double borderWidth;
  final Color? fillColor;
  final bool showDefaultGuide;
  final double pulseValue;

  // Layout constants for bracket positioning
  static const double _bracketLengthRatio = 0.08;
  static const double _horizontalMarginRatio = 0.1;
  static const double _topMarginRatio = 0.08;
  static const double _bottomMarginRatio = 0.92;
  static const double _bracketStrokeMultiplier = 1.5;

  PolygonOverlayPainter({
    this.polygonPoints,
    required this.borderColor,
    required this.borderWidth,
    this.fillColor,
    required this.showDefaultGuide,
    required this.pulseValue,
  });

  /// Creates a stroke paint with the standard configuration.
  Paint _createStrokePaint({double? strokeWidth}) {
    return Paint()
      ..color = borderColor
      ..strokeWidth = strokeWidth ?? borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (polygonPoints != null && polygonPoints!.isNotEmpty) {
      _drawCustomPolygon(canvas, size);
    } else if (showDefaultGuide) {
      _drawDefaultBodyGuide(canvas, size);
    }
  }

  void _drawCustomPolygon(Canvas canvas, Size size) {
    if (polygonPoints == null || polygonPoints!.length < 3) return;

    final paint = _createStrokePaint();

    final path = Path();
    path.moveTo(
      polygonPoints![0].dx * size.width,
      polygonPoints![0].dy * size.height,
    );

    for (int i = 1; i < polygonPoints!.length; i++) {
      path.lineTo(
        polygonPoints![i].dx * size.width,
        polygonPoints![i].dy * size.height,
      );
    }
    path.close();

    // Draw fill if specified
    if (fillColor != null) {
      final fillPaint = Paint()
        ..color = fillColor!
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    // Draw border
    canvas.drawPath(path, paint);
  }

  void _drawDefaultBodyGuide(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final topY = size.height * 0.1;
    final bottomY = size.height * 0.9;
    final bodyWidth = size.width * 0.35;

    final paint = _createStrokePaint();

    // Draw body outline guide
    final path = Path();

    // Head (oval)
    final headCenterY = topY + size.height * 0.05;
    final headRadius = size.width * 0.08;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, headCenterY),
        width: headRadius * 1.4,
        height: headRadius * 1.8,
      ),
      paint,
    );

    // Neck
    final neckTopY = headCenterY + headRadius * 0.9;
    final neckBottomY = neckTopY + size.height * 0.03;
    final neckWidth = size.width * 0.05;
    path.moveTo(centerX - neckWidth, neckTopY);
    path.lineTo(centerX - neckWidth, neckBottomY);
    path.moveTo(centerX + neckWidth, neckTopY);
    path.lineTo(centerX + neckWidth, neckBottomY);

    // Shoulders
    final shoulderY = neckBottomY;
    final shoulderWidth = bodyWidth;
    path.moveTo(centerX - neckWidth, shoulderY);
    path.lineTo(centerX - shoulderWidth, shoulderY + size.height * 0.02);
    path.moveTo(centerX + neckWidth, shoulderY);
    path.lineTo(centerX + shoulderWidth, shoulderY + size.height * 0.02);

    // Arms (guide lines)
    final armStartY = shoulderY + size.height * 0.02;
    final armEndY = shoulderY + size.height * 0.25;
    final armSpread = bodyWidth * 1.3;
    
    // Left arm
    path.moveTo(centerX - shoulderWidth, armStartY);
    path.lineTo(centerX - armSpread, armEndY);
    
    // Right arm
    path.moveTo(centerX + shoulderWidth, armStartY);
    path.lineTo(centerX + armSpread, armEndY);

    // Torso
    final torsoTopY = shoulderY + size.height * 0.02;
    final torsoBottomY = torsoTopY + size.height * 0.3;
    final waistWidth = bodyWidth * 0.7;
    
    // Left side of torso
    path.moveTo(centerX - shoulderWidth, torsoTopY);
    path.quadraticBezierTo(
      centerX - waistWidth,
      (torsoTopY + torsoBottomY) / 2,
      centerX - waistWidth * 0.9,
      torsoBottomY,
    );
    
    // Right side of torso
    path.moveTo(centerX + shoulderWidth, torsoTopY);
    path.quadraticBezierTo(
      centerX + waistWidth,
      (torsoTopY + torsoBottomY) / 2,
      centerX + waistWidth * 0.9,
      torsoBottomY,
    );

    // Hips
    final hipWidth = bodyWidth * 0.85;
    path.moveTo(centerX - waistWidth * 0.9, torsoBottomY);
    path.lineTo(centerX - hipWidth, torsoBottomY + size.height * 0.03);
    path.moveTo(centerX + waistWidth * 0.9, torsoBottomY);
    path.lineTo(centerX + hipWidth, torsoBottomY + size.height * 0.03);

    // Legs
    final legTopY = torsoBottomY + size.height * 0.03;
    final legBottomY = bottomY - size.height * 0.02;
    final legWidth = bodyWidth * 0.25;
    final legSpread = bodyWidth * 0.4;
    
    // Left leg
    path.moveTo(centerX - hipWidth, legTopY);
    path.lineTo(centerX - legSpread - legWidth, legBottomY);
    path.moveTo(centerX - hipWidth * 0.5, legTopY);
    path.lineTo(centerX - legSpread + legWidth, legBottomY);
    
    // Right leg
    path.moveTo(centerX + hipWidth, legTopY);
    path.lineTo(centerX + legSpread + legWidth, legBottomY);
    path.moveTo(centerX + hipWidth * 0.5, legTopY);
    path.lineTo(centerX + legSpread - legWidth, legBottomY);

    canvas.drawPath(path, paint);

    // Draw corner brackets
    _drawCornerBrackets(canvas, size, paint);
  }

  void _drawCornerBrackets(Canvas canvas, Size size, Paint paint) {
    final bracketLength = size.width * _bracketLengthRatio;
    final margin = size.width * _horizontalMarginRatio;
    final topMargin = size.height * _topMarginRatio;
    final bottomMargin = size.height * _bottomMarginRatio;

    final bracketPaint = _createStrokePaint(
      strokeWidth: borderWidth * _bracketStrokeMultiplier,
    );

    // Top-left bracket
    canvas.drawLine(
      Offset(margin, topMargin + bracketLength),
      Offset(margin, topMargin),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(margin, topMargin),
      Offset(margin + bracketLength, topMargin),
      bracketPaint,
    );

    // Top-right bracket
    canvas.drawLine(
      Offset(size.width - margin, topMargin + bracketLength),
      Offset(size.width - margin, topMargin),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(size.width - margin, topMargin),
      Offset(size.width - margin - bracketLength, topMargin),
      bracketPaint,
    );

    // Bottom-left bracket
    canvas.drawLine(
      Offset(margin, bottomMargin - bracketLength),
      Offset(margin, bottomMargin),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(margin, bottomMargin),
      Offset(margin + bracketLength, bottomMargin),
      bracketPaint,
    );

    // Bottom-right bracket
    canvas.drawLine(
      Offset(size.width - margin, bottomMargin - bracketLength),
      Offset(size.width - margin, bottomMargin),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(size.width - margin, bottomMargin),
      Offset(size.width - margin - bracketLength, bottomMargin),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(PolygonOverlayPainter oldDelegate) {
    return oldDelegate.polygonPoints != polygonPoints ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.showDefaultGuide != showDefaultGuide;
  }
}
