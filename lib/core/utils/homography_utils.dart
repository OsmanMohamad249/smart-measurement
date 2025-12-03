import 'dart:math';
import 'package:vector_math/vector_math_64.dart';

/// Homography and perspective transformation utilities for Zero-Touch calibration.
///
/// This class provides methods to compute homography matrices from detected
/// card corners and perform perspective transformations for accurate measurements.
class HomographyUtils {
  /// ISO/IEC 7810 ID-1 card width in millimeters.
  static const double cardWidthMm = 85.60;

  /// ISO/IEC 7810 ID-1 card height in millimeters.
  static const double cardHeightMm = 53.98;

  /// Computes a 3×3 homography matrix mapping detected card corners to a
  /// canonical rectangle.
  ///
  /// [srcCorners] - Detected card corners in image pixel coordinates,
  ///                ordered as [top-left, top-right, bottom-right, bottom-left].
  /// [dstWidthPx] - Desired canonical plane width in pixels.
  /// [dstHeightPx] - Desired canonical plane height in pixels.
  ///
  /// Returns a Matrix3 representing the homography transformation.
  static Matrix3 computeHomography(
    List<Vector2> srcCorners,
    int dstWidthPx,
    int dstHeightPx,
  ) {
    if (srcCorners.length != 4) {
      throw ArgumentError('srcCorners must contain exactly 4 points');
    }

    // Define canonical destination corners
    final List<Vector2> dst = [
      Vector2(0.0, 0.0), // top-left
      Vector2(dstWidthPx.toDouble(), 0.0), // top-right
      Vector2(dstWidthPx.toDouble(), dstHeightPx.toDouble()), // bottom-right
      Vector2(0.0, dstHeightPx.toDouble()), // bottom-left
    ];

    // Build the linear system using Direct Linear Transform (DLT)
    final List<List<double>> a = [];
    for (int i = 0; i < 4; i++) {
      final double x = srcCorners[i].x;
      final double y = srcCorners[i].y;
      final double u = dst[i].x;
      final double v = dst[i].y;

      // Two equations per correspondence point
      a.add([x, y, 1, 0, 0, 0, -u * x, -u * y, -u]);
      a.add([0, 0, 0, x, y, 1, -v * x, -v * y, -v]);
    }

    // Solve using DLT to find homography
    final Matrix3 hMat = _solveDLT(a);
    return hMat;
  }

  /// Solves the Direct Linear Transform (DLT) system to compute homography.
  ///
  /// This method builds the A^T * A matrix and finds the eigenvector
  /// corresponding to the smallest eigenvalue using power iteration.
  static Matrix3 _solveDLT(List<List<double>> a) {
    // Convert the 8×9 matrix A to 9×9 matrix A^T * A
    final List<List<double>> ata = List.generate(9, (_) => List.filled(9, 0.0));
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 9; j++) {
        for (int k = 0; k < 9; k++) {
          ata[j][k] += a[i][j] * a[i][k];
        }
      }
    }

    // Find the eigenvector corresponding to the smallest eigenvalue
    // using inverse power iteration
    List<double> v = List.generate(9, (i) => i == 8 ? 1.0 : 0.0);

    // Perform power iteration to find the smallest eigenvector
    for (int iter = 0; iter < 1000; iter++) {
      final List<double> w = List.filled(9, 0.0);
      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          w[i] += ata[i][j] * v[j];
        }
      }

      // Normalize the result
      final double norm = sqrt(w.map((e) => e * e).reduce((a, b) => a + b));
      for (int i = 0; i < 9; i++) {
        v[i] = w[i] / (norm == 0 ? 1 : norm);
      }
    }

    // Normalize so h[8] = 1
    if (v[8].abs() < 1e-8) v[8] = 1e-8;
    for (int i = 0; i < 9; i++) {
      v[i] = v[i] / v[8];
    }

    // Construct the 3×3 homography matrix
    return Matrix3(
      v[0], v[1], v[2],
      v[3], v[4], v[5],
      v[6], v[7], v[8],
    );
  }

  /// Computes mm_per_pixel by measuring the top edge length in pixel space.
  ///
  /// [srcCorners] - Detected card corners ordered as [tl, tr, br, bl].
  ///
  /// Returns the scale factor in millimeters per pixel.
  static double computeMmPerPixelFromCorners(List<Vector2> srcCorners) {
    if (srcCorners.length != 4) {
      throw ArgumentError('srcCorners must contain exactly 4 points');
    }

    final Vector2 tl = srcCorners[0];
    final Vector2 tr = srcCorners[1];
    final Vector2 br = srcCorners[2];
    final Vector2 bl = srcCorners[3];

    // Calculate pixel widths at top and bottom edges
    final double topEdgePixels = (tr - tl).length;
    final double bottomEdgePixels = (br - bl).length;

    // Average the two edges to compensate for perspective
    final double avgPixelWidth = (topEdgePixels + bottomEdgePixels) / 2;

    if (avgPixelWidth == 0) {
      throw Exception('Zero pixel width detected - invalid card corners');
    }

    // Compute scale: mm per pixel
    return cardWidthMm / avgPixelWidth;
  }

  /// Applies homography transformation to a point.
  ///
  /// [h] - The 3×3 homography matrix.
  /// [point] - The input point in source coordinates.
  ///
  /// Returns the transformed point in destination coordinates.
  static Vector2 transformPoint(Matrix3 h, Vector2 point) {
    final Vector3 src = Vector3(point.x, point.y, 1.0);
    final Vector3 dst = h * src;

    // Normalize by the homogeneous coordinate
    if (dst.z.abs() < 1e-8) {
      throw Exception('Invalid homography transformation - division by zero');
    }

    return Vector2(dst.x / dst.z, dst.y / dst.z);
  }

  /// Validates that detected corners form a reasonable quadrilateral
  /// based on aspect ratio and area constraints.
  ///
  /// [corners] - List of 4 corner points.
  /// [minArea] - Minimum acceptable area in pixels².
  /// [aspectTolerance] - Maximum deviation from expected aspect ratio (as fraction).
  ///
  /// Returns true if the corners represent a valid card shape.
  static bool validateCardCorners(
    List<Vector2> corners, {
    double minArea = 2000,
    double aspectTolerance = 0.3,
  }) {
    if (corners.length != 4) return false;

    // Calculate edge lengths
    final double topEdge = (corners[1] - corners[0]).length;
    final double bottomEdge = (corners[2] - corners[3]).length;
    final double leftEdge = (corners[3] - corners[0]).length;
    final double rightEdge = (corners[2] - corners[1]).length;

    // Check for degenerate edges
    if (topEdge < 5 || bottomEdge < 5 || leftEdge < 5 || rightEdge < 5) {
      return false;
    }

    // Calculate average width and height
    final double avgWidth = (topEdge + bottomEdge) / 2;
    final double avgHeight = (leftEdge + rightEdge) / 2;

    // Check aspect ratio
    final double observedAspect = avgWidth / avgHeight;
    final double expectedAspect = cardWidthMm / cardHeightMm;
    final double aspectDelta = (observedAspect - expectedAspect).abs() / expectedAspect;

    if (aspectDelta > aspectTolerance) {
      return false;
    }

    // Calculate area using shoelace formula
    final double area = _calculatePolygonArea(corners);
    return area >= minArea;
  }

  /// Calculates the area of a polygon using the shoelace formula.
  static double _calculatePolygonArea(List<Vector2> points) {
    double sum = 0;
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      sum += (current.x * next.y) - (next.x * current.y);
    }
    return sum.abs() / 2;
  }

  /// Computes the perspective-corrected distance between two points
  /// after applying homography transformation.
  ///
  /// Useful for accurate measurements after removing perspective distortion.
  static double transformedDistance(
    Matrix3 h,
    Vector2 point1,
    Vector2 point2,
  ) {
    final Vector2 transformed1 = transformPoint(h, point1);
    final Vector2 transformed2 = transformPoint(h, point2);
    return (transformed2 - transformed1).length;
  }
}

