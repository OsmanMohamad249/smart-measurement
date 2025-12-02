import 'dart:math';

/// Collection of geometric helpers for Zero-Touch calibration.
class GeometryUtils {
  /// ISO/IEC 7810 ID-1 width in millimeters used for scaling.
  static const double _cardWidthMm = 85.60;

  /// ISO/IEC 7810 ID-1 height in millimeters (useful for validation heuristics).
  static const double _cardHeightMm = 53.98;

  /// Calculates the `mm_per_pixel` scale factor for the detected card corners.
  ///
  /// The [corners] list must contain exactly 4 points ordered clockwise starting
  /// from the top-left corner. The method compensates for perspective by
  /// averaging opposite edges before converting pixels to millimeters.
  static double calculateScaleFactor(List<Point<double>> corners) {
    if (!isCardShapeValid(corners)) {
      throw ArgumentError('Invalid card corners passed to calculateScaleFactor');
    }

    final topEdge = _distance(corners[0], corners[1]);
    final bottomEdge = _distance(corners[2], corners[3]);
    final avgWidthPixels = (topEdge + bottomEdge) / 2;

    final leftEdge = _distance(corners[0], corners[3]);
    final rightEdge = _distance(corners[1], corners[2]);
    final avgHeightPixels = (leftEdge + rightEdge) / 2;

    if (avgWidthPixels <= 0 || avgHeightPixels <= 0) {
      throw StateError('Degenerate card geometry detected.');
    }

    final scaleFromWidth = _cardWidthMm / avgWidthPixels;
    final scaleFromHeight = _cardHeightMm / avgHeightPixels;
    return (scaleFromWidth + scaleFromHeight) / 2;
  }

  /// Basic sanity checks to ensure the quadrilateral resembles a real card
  /// before we trust it for calibration.
  static bool isCardShapeValid(
    List<Point<double>> corners, {
    double minArea = 2000,
    double aspectTolerance = 0.25,
  }) {
    if (corners.length != 4) return false;

    final topEdge = _distance(corners[0], corners[1]);
    final bottomEdge = _distance(corners[2], corners[3]);
    final leftEdge = _distance(corners[0], corners[3]);
    final rightEdge = _distance(corners[1], corners[2]);

    if (topEdge < 5 || bottomEdge < 5 || leftEdge < 5 || rightEdge < 5) {
      return false;
    }

    final avgWidth = (topEdge + bottomEdge) / 2;
    final avgHeight = (leftEdge + rightEdge) / 2;
    final observedAspect = avgWidth / avgHeight;
    final expectedAspect = _cardWidthMm / _cardHeightMm;

    final aspectDelta = (observedAspect - expectedAspect).abs() / expectedAspect;
    if (aspectDelta > aspectTolerance) {
      return false;
    }

    final area = _polygonArea(corners);
    return area >= minArea;
  }

  static double _distance(Point<double> a, Point<double> b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  static double _polygonArea(List<Point<double>> points) {
    double sum = 0;
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      sum += (current.x * next.y) - (next.x * current.y);
    }
    return sum.abs() / 2;
  }
}
