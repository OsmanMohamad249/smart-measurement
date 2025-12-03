import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';
import '../services/camera_service.dart';
import '../services/tflite_service.dart';
import '../services/guidance_manager.dart';
import '../utils/homography_utils.dart';
import 'providers.dart'; // Import to access provider definitions

/// Controller for the Smart Calibration process.
///
/// This controller orchestrates the entire calibration pipeline:
/// 1. Captures camera frames
/// 2. Runs YOLO inference to detect card corners
/// 3. Validates corner geometry
/// 4. Computes homography and mm_per_pixel scale
/// 5. Persists calibration result for downstream measurements
class CalibrationController extends StateNotifier<CalibrationControllerState> {
  final CameraService _cameraService;
  final TFLiteService _tfliteService;
  final GuidanceManager _guidanceManager;

  Timer? _stabilityTimer;
  bool _isProcessingFrame = false;
  
  // Temporal smoothing for corner detection
  final List<List<Vector2>> _recentCorners = [];
  static const int _smoothingWindow = 5;
  static const int _requiredStableFrames = 10;
  int _stableFrameCount = 0;

  CalibrationController({
    required CameraService cameraService,
    required TFLiteService tfliteService,
    required GuidanceManager guidanceManager,
  })  : _cameraService = cameraService,
        _tfliteService = tfliteService,
        _guidanceManager = guidanceManager,
        super(const CalibrationControllerState());

  /// Starts the calibration process.
  Future<void> startCalibration() async {
    if (state.status == CalibrationStatus.calibrating) {
      debugPrint('Calibration already in progress');
      return;
    }

    state = state.copyWith(
      status: CalibrationStatus.calibrating,
      statusMessage: 'Initializing calibration...',
      progress: 0.0,
    );

    await _guidanceManager.speak('Place the reference card flat on a surface');

    // Start processing camera frames
    _startFrameProcessing();
  }

  /// Starts processing camera frames for card detection.
  void _startFrameProcessing() {
    _cameraService.startImageStream(_processFrame);
  }

  /// Processes a single camera frame for card corner detection.
  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessingFrame) return;
    if (state.status != CalibrationStatus.calibrating) return;

    _isProcessingFrame = true;

    try {
      // Run YOLO inference to detect card corners using TFLite
      final calibrationResult = await _tfliteService.runInference(image);

      if (calibrationResult == null) {
        _isProcessingFrame = false;
        return;
      }

      final corners = calibrationResult.cardCorners;
      
      // Convert CardPoint to Vector2 for homography calculations
      final cornerVectors = corners
          .map((p) => Vector2(p.x, p.y))
          .toList()
          .cast<Vector2>();

      // Validate corner geometry using homography utils
      if (!HomographyUtils.validateCardCorners(cornerVectors)) {
        state = state.copyWith(
          statusMessage: 'Card not detected clearly - adjust position',
          detectedCorners: null,
        );
        _stableFrameCount = 0;
        _isProcessingFrame = false;
        return;
      }

      // Add to temporal smoothing buffer
      _recentCorners.add(cornerVectors);
      if (_recentCorners.length > _smoothingWindow) {
        _recentCorners.removeAt(0);
      }

      // Check stability (corners should be consistent across frames)
      if (_areCornerStable()) {
        _stableFrameCount++;
        final progress = min(1.0, _stableFrameCount / _requiredStableFrames);
        
        state = state.copyWith(
          statusMessage: 'Hold steady... ${(_stableFrameCount / _requiredStableFrames * 100).toInt()}%',
          detectedCorners: cornerVectors,
          progress: progress,
        );

        if (_stableFrameCount >= _requiredStableFrames) {
          await _finalizeCalibration(cornerVectors);
        }
      } else {
        _stableFrameCount = 0;
        state = state.copyWith(
          statusMessage: 'Hold card steady',
          detectedCorners: cornerVectors,
          progress: 0.0,
        );
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Checks if detected corners are stable across recent frames.
  bool _areCornerStable() {
    if (_recentCorners.length < _smoothingWindow) return false;

    // Calculate variance of corner positions
    for (int i = 0; i < 4; i++) {
      double sumX = 0, sumY = 0;
      double sumX2 = 0, sumY2 = 0;

      for (final corners in _recentCorners) {
        sumX += corners[i].x;
        sumY += corners[i].y;
        sumX2 += corners[i].x * corners[i].x;
        sumY2 += corners[i].y * corners[i].y;
      }

      final n = _recentCorners.length;
      final meanX = sumX / n;
      final meanY = sumY / n;
      final varianceX = (sumX2 / n) - (meanX * meanX);
      final varianceY = (sumY2 / n) - (meanY * meanY);

      // Corners should not move more than 5 pixels
      const double maxVariance = 25.0; // 5 pixels squared
      if (varianceX > maxVariance || varianceY > maxVariance) {
        return false;
      }
    }

    return true;
  }

  /// Finalizes calibration by computing homography and scale factor.
  Future<void> _finalizeCalibration(List<Vector2> corners) async {
    await _cameraService.stopImageStream();

    state = state.copyWith(
      statusMessage: 'Processing calibration...',
      progress: 1.0,
    );

    await _guidanceManager.speak('Calibration complete');

    try {
      // Compute smoothed corners (average of recent detections)
      final smoothedCorners = _computeSmoothedCorners();

      // Compute homography matrix
      const int canonicalWidth = 640;
      const int canonicalHeight = 400; // Maintains card aspect ratio
      final homography = HomographyUtils.computeHomography(
        smoothedCorners,
        canonicalWidth,
        canonicalHeight,
      );

      // Compute mm_per_pixel scale factor
      final mmPerPixel = HomographyUtils.computeMmPerPixelFromCorners(smoothedCorners);

      // Store calibration result
      state = state.copyWith(
        status: CalibrationStatus.completed,
        statusMessage: 'Calibration successful! Scale: ${mmPerPixel.toStringAsFixed(4)} mm/px',
        mmPerPixel: mmPerPixel,
        homographyMatrix: homography,
        detectedCorners: smoothedCorners,
        progress: 1.0,
      );

      debugPrint('Calibration completed: $mmPerPixel mm/pixel');
    } catch (e) {
      _handleCalibrationError('Calibration computation failed: $e');
    }
  }

  /// Computes smoothed corner positions by averaging recent detections.
  List<Vector2> _computeSmoothedCorners() {
    final smoothed = <Vector2>[];
    
    for (int i = 0; i < 4; i++) {
      double sumX = 0, sumY = 0;
      
      for (final corners in _recentCorners) {
        sumX += corners[i].x;
        sumY += corners[i].y;
      }
      
      final n = _recentCorners.length;
      smoothed.add(Vector2(sumX / n, sumY / n));
    }
    
    return smoothed;
  }

  /// Handles calibration errors.
  void _handleCalibrationError(String message) {
    state = state.copyWith(
      status: CalibrationStatus.error,
      statusMessage: message,
      progress: 0.0,
    );
    _guidanceManager.speak('Calibration failed. Please try again.');
    debugPrint('Calibration error: $message');
  }

  /// Resets calibration state.
  void resetCalibration() {
    _cameraService.stopImageStream();
    _stabilityTimer?.cancel();
    _recentCorners.clear();
    _stableFrameCount = 0;
    _isProcessingFrame = false;

    state = const CalibrationControllerState();
  }

  /// Retries calibration after an error.
  Future<void> retryCalibration() async {
    resetCalibration();
    await Future.delayed(const Duration(milliseconds: 500));
    await startCalibration();
  }

  @override
  void dispose() {
    _cameraService.stopImageStream();
    _stabilityTimer?.cancel();
    super.dispose();
  }
}

/// State for the calibration controller.
class CalibrationControllerState {
  final CalibrationStatus status;
  final String statusMessage;
  final double progress;
  final double? mmPerPixel;
  final Matrix3? homographyMatrix;
  final List<Vector2>? detectedCorners;

  const CalibrationControllerState({
    this.status = CalibrationStatus.idle,
    this.statusMessage = 'Ready to calibrate',
    this.progress = 0.0,
    this.mmPerPixel,
    this.homographyMatrix,
    this.detectedCorners,
  });

  CalibrationControllerState copyWith({
    CalibrationStatus? status,
    String? statusMessage,
    double? progress,
    double? mmPerPixel,
    Matrix3? homographyMatrix,
    List<Vector2>? detectedCorners,
  }) {
    return CalibrationControllerState(
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      progress: progress ?? this.progress,
      mmPerPixel: mmPerPixel ?? this.mmPerPixel,
      homographyMatrix: homographyMatrix ?? this.homographyMatrix,
      detectedCorners: detectedCorners ?? this.detectedCorners,
    );
  }

  bool get isCalibrated => status == CalibrationStatus.completed && mmPerPixel != null;
}

/// Calibration status enumeration.
enum CalibrationStatus {
  idle,
  calibrating,
  completed,
  error,
}

/// Provider for calibration controller.
final calibrationControllerProvider =
    StateNotifierProvider.autoDispose<CalibrationController, CalibrationControllerState>(
  (ref) {
    final cameraService = ref.watch(cameraServiceProvider);
    final tfliteService = ref.watch(tfliteServiceProvider);
    final guidanceManager = ref.watch(guidanceManagerProvider);

    return CalibrationController(
      cameraService: cameraService,
      tfliteService: tfliteService,
      guidanceManager: guidanceManager,
    );
  },
);

