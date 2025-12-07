import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:sensors_plus/sensors_plus.dart';

class StabilityDetector {
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  final List<GyroscopeEvent> _recentGyroData = [];
  static const int _gyroWindowSize = 5;  // Reduced from 10 for faster response
  static const double _gyroVarianceThreshold = 1.0;  // Increased from 0.5 for more tolerance
  img.Image? _previousFrame;
  static const double _frameDiffThreshold = 0.15;  // Increased from 0.05 for more tolerance
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      _recentGyroData.add(event);
      if (_recentGyroData.length > _gyroWindowSize) {
        _recentGyroData.removeAt(0);
      }
    });
    _isInitialized = true;
  }

  bool isGyroStable() {
    // Allow detection even with fewer samples
    if (_recentGyroData.length < 3) {
      return true;  // Assume stable if not enough data yet
    }
    double sumX = 0, sumY = 0, sumZ = 0;
    double sumX2 = 0, sumY2 = 0, sumZ2 = 0;
    for (final event in _recentGyroData) {
      sumX += event.x;
      sumY += event.y;
      sumZ += event.z;
      sumX2 += event.x * event.x;
      sumY2 += event.y * event.y;
      sumZ2 += event.z * event.z;
    }
    final n = _recentGyroData.length;
    final varianceX = (sumX2 / n) - (sumX / n) * (sumX / n);
    final varianceY = (sumY2 / n) - (sumY / n) * (sumY / n);
    final varianceZ = (sumZ2 / n) - (sumZ / n) * (sumZ / n);
    final maxVariance = [varianceX, varianceY, varianceZ].reduce((a, b) => a > b ? a : b);
    return maxVariance < _gyroVarianceThreshold;
  }

  bool isFrameStable(img.Image currentFrame) {
    if (_previousFrame == null) {
      _previousFrame = currentFrame;
      return false;
    }
    final diff = _calculateFrameDifference(_previousFrame!, currentFrame);
    _previousFrame = currentFrame;
    return diff < _frameDiffThreshold;
  }

  double _calculateFrameDifference(img.Image prev, img.Image curr) {
    if (prev.width != curr.width || prev.height != curr.height) {
      return 1.0;
    }
    int changedPixels = 0;
    final totalSampled = (prev.width ~/ 10) * (prev.height ~/ 10);
    const threshold = 30;
    for (int y = 0; y < prev.height; y += 10) {
      for (int x = 0; x < prev.width; x += 10) {
        final p1 = prev.getPixel(x, y);
        final p2 = curr.getPixel(x, y);
        final diffR = (p1.r - p2.r).abs();
        final diffG = (p1.g - p2.g).abs();
        final diffB = (p1.b - p2.b).abs();
        if (diffR > threshold || diffG > threshold || diffB > threshold) {
          changedPixels++;
        }
      }
    }
    if (totalSampled == 0) {
      return 1.0;
    }
    return changedPixels / totalSampled;
  }

  bool isStable(img.Image? currentFrame) {
    final gyroStable = isGyroStable();
    bool frameStable = true;
    if (currentFrame != null) {
      frameStable = isFrameStable(currentFrame);
    }
    return gyroStable && frameStable;
  }

  double getStabilityScore(img.Image? currentFrame) {
    double score = 0.0;
    if (isGyroStable()) score += 0.5;
    if (currentFrame != null && isFrameStable(currentFrame)) score += 0.5;
    return score;
  }

  void dispose() {
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
    _recentGyroData.clear();
    _previousFrame = null;
    _isInitialized = false;
  }
}
