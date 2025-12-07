import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:image/image.dart' as img;
import '../services/camera_service.dart';
import '../services/onnx_inference_service.dart';
import '../services/guidance_manager.dart';
import '../services/reactive_guidance_manager.dart';
import '../services/stability_detector.dart';
import '../services/auto_capture_manager.dart';
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
  final OnnxInferenceService _onnxService;
  final GuidanceManager _guidanceManager;
  final StabilityDetector _stabilityDetector;
  final AutoCaptureManager _autoCaptureManager;
  final ReactiveGuidanceManager _reactiveGuidanceManager;
  List<Vector2>? _latestCorners;

  bool _isProcessingFrame = false;
  int _frameSkipCounter = 0;
  static const int _frameSkipInterval = 2; // Process every 2nd frame - ONNX handles additional skipping internally

  CalibrationController({
    required CameraService cameraService,
    required OnnxInferenceService onnxService,
    required GuidanceManager guidanceManager,
    required StabilityDetector stabilityDetector,
    required AutoCaptureManager autoCaptureManager,
    required ReactiveGuidanceManager reactiveGuidanceManager,
  })  : _cameraService = cameraService,
        _onnxService = onnxService,
        _guidanceManager = guidanceManager,
        _stabilityDetector = stabilityDetector,
        _autoCaptureManager = autoCaptureManager,
        _reactiveGuidanceManager = reactiveGuidanceManager,
        super(const CalibrationControllerState()) {
    _setupAutoCapture();
  }

  void _setupAutoCapture() {
    _autoCaptureManager.onStateChanged = (captureState) {
      state = state.copyWith(captureState: captureState);
    };
    _autoCaptureManager.onCountdownTick = (countdown) {
      state = state.copyWith(countdownValue: countdown);
    };
    _autoCaptureManager.onCapture = () {
      // ✅ CRITICAL: Only finalize if we have valid corners
      if (_latestCorners != null && _latestCorners!.length == 4) {
        debugPrint('CalibrationController: ✅ Auto-capture triggered with valid corners');
        _finalizeCalibration(_latestCorners!);
      } else {
        debugPrint('CalibrationController: ❌ Auto-capture blocked - no valid corners');
        // Reset auto-capture to wait for valid detection
        _autoCaptureManager.reset();
      }
    };
  }

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
      stabilityScore: 0.0,
    );

    // ✅ FIXED: Card should be held at chest level, not on a surface
    await _guidanceManager.speak(
      'Hold the reference card at chest level in front of your body. '
      'Stand straight, 2 meters from the camera.'
    );

    await _stabilityDetector.initialize();

    // Start processing camera frames
    _startFrameProcessing();
  }

  /// Starts processing camera frames for card detection.
  void _startFrameProcessing() {
    _cameraService.startImageStream(_processFrame);
  }

  /// Processes a single camera frame for card corner detection.
  Future<void> _processFrame(CameraImage image) async {
    // Skip frames to improve performance
    _frameSkipCounter++;
    if (_frameSkipCounter < _frameSkipInterval) {
      return;
    }
    _frameSkipCounter = 0;

    if (_isProcessingFrame || !_cameraService.isInitialized) return;
    if (state.status != CalibrationStatus.calibrating) return;

    _isProcessingFrame = true;

    try {
      // Run YOLO inference to detect card corners using ONNX Runtime
      final calibrationResult = await _onnxService.runInference(image);

      if (calibrationResult == null) {
        debugPrint('CalibrationController: No inference result');
        _isProcessingFrame = false;
        return;
      }

      debugPrint('CalibrationController: Inference result - corners=${calibrationResult.cardCorners.length}, conf=${calibrationResult.confidence.toStringAsFixed(3)}');

      final imgImage = _convertCameraImageToImage(image);
      final isDeviceStable = _stabilityDetector.isStable(imgImage);
      final stabilityScore = _stabilityDetector.getStabilityScore(imgImage);

      state = state.copyWith(stabilityScore: stabilityScore);

      // Removed strict stability check - just warn
      if (!isDeviceStable) {
        debugPrint('CalibrationController: Device not stable, but continuing...');
      }

      final corners = calibrationResult.cardCorners;
      
      // Check if card was detected
      if (corners.isEmpty || corners.length < 4) {
        // ✅ CRITICAL: Clear latestCorners to prevent false calibration
        _latestCorners = null;
        _autoCaptureManager.checkConditions(
          isStable: false,
          isCardDetected: false,
          isGoodQuality: false,
        );
        state = state.copyWith(
          statusMessage: 'Position card in frame',
          detectedCorners: null,
        );
        debugPrint('CalibrationController: No card corners detected');
        _isProcessingFrame = false;
        return;
      }

      debugPrint('CalibrationController: Card detected with ${corners.length} corners');

      // Convert CardPoint to Vector2 for homography calculations
      final cornerVectors = corners
          .map((p) => Vector2(p.x, p.y))
          .toList()
          .cast<Vector2>();

      // ✅ CRITICAL: Use high confidence threshold to ensure REAL card detection
      // The model must be VERY confident this is an actual card, not just any rectangle
      const double minConfidenceThreshold = 0.70; // Increased from 0.40 to 0.70

      // ✅ CRITICAL: Validate corner geometry before accepting
      // Convert normalized coordinates to pixel coordinates for validation
      const int modelInputSize = 640;
      final pixelCornersForValidation = cornerVectors.map((c) => Vector2(
        c.x * modelInputSize,
        c.y * modelInputSize,
      )).toList();

      // Validate corners form a proper card shape with correct aspect ratio
      final bool validGeometry = HomographyUtils.validateCardCorners(
        pixelCornersForValidation,
        minArea: 5000, // Minimum 5000 pixels² to ensure card is not too small
        aspectTolerance: 0.25, // ±25% tolerance on aspect ratio
      );

      final isCardDetected = corners.length == 4 &&
                             calibrationResult.confidence >= minConfidenceThreshold &&
                             validGeometry; // ✅ CRITICAL: Must pass geometry validation

      if (!isCardDetected) {
        // ✅ CRITICAL: Clear latestCorners to prevent false calibration
        _latestCorners = null;
        _autoCaptureManager.checkConditions(
          isStable: false,
          isCardDetected: false,
          isGoodQuality: false,
        );

        // More informative status message
        String statusMsg;
        if (corners.length != 4) {
          statusMsg = 'No card detected. Please show your ID/credit card.';
        } else if (calibrationResult.confidence < minConfidenceThreshold) {
          statusMsg = 'Card not clear enough. Hold card steady and ensure good lighting.';
        } else if (!validGeometry) {
          statusMsg = 'Invalid card shape. Ensure full card is visible and not distorted.';
        } else {
          statusMsg = 'Position card in frame';
        }

        state = state.copyWith(
          statusMessage: statusMsg,
          detectedCorners: null,
        );
        debugPrint('CalibrationController: Card detection failed - '
            'corners=${corners.length}, conf=${calibrationResult.confidence.toStringAsFixed(3)}, '
            'validGeometry=$validGeometry');
        _isProcessingFrame = false;
        return;
      }

      // ✅ Only set latestCorners AFTER validation passes
      _latestCorners = cornerVectors;

      debugPrint('CalibrationController: Valid card detected! conf=${calibrationResult.confidence.toStringAsFixed(3)}');

      // Only compute homography if we have valid corners
      double quality = 0.0;
      try {
        // Convert normalized coordinates to pixel coordinates for homography
        const int modelInputSize = 640;
        final pixelCorners = cornerVectors.map((c) => Vector2(
          c.x * modelInputSize,
          c.y * modelInputSize,
        )).toList();

        final homography = HomographyUtils.computeHomography(pixelCorners, 640, 400);
        quality = HomographyUtils.validateHomographyQuality(homography, pixelCorners);
      } catch (e) {
        debugPrint('Homography computation failed: $e');
        quality = 0.7; // Default to acceptable quality if computation fails
      }

      // Lowered quality threshold from 0.9 to 0.6 for faster capture
      final isGoodQuality = quality > 0.6;

      _autoCaptureManager.checkConditions(
        isStable: isDeviceStable,
        isCardDetected: isCardDetected,
        isGoodQuality: isGoodQuality,
      );

      // Convert to pixel coords for tilt calculation
      const int modelInputSize = 640;
      final pixelCornersForTilt = cornerVectors.map((c) => Vector2(
        c.x * modelInputSize,
        c.y * modelInputSize,
      )).toList();

      _reactiveGuidanceManager.analyzeAndGuide(
        isStable: isDeviceStable,
        isCardDetected: isCardDetected,
        qualityScore: quality,
        cardTilt: HomographyUtils.calculateCardTilt(pixelCornersForTilt),
        stabilityScore: stabilityScore,
      );

      // Update UI with detected corners
      state = state.copyWith(
        detectedCorners: cornerVectors,
        qualityScore: quality, // Update quality score in state
      );

    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Finalizes calibration by computing homography and scale factor.
  Future<void> _finalizeCalibration(List<Vector2> corners) async {
    // ✅ CRITICAL: Validate corners before proceeding
    if (corners.length != 4) {
      debugPrint('CalibrationController: ❌ Cannot finalize - invalid corners count: ${corners.length}');
      _handleCalibrationError('Invalid card detection. Please try again.');
      return;
    }

    // Validate corner values are reasonable (normalized 0-1)
    for (int i = 0; i < corners.length; i++) {
      if (corners[i].x < 0 || corners[i].x > 1 || corners[i].y < 0 || corners[i].y > 1) {
        debugPrint('CalibrationController: ❌ Invalid corner $i: (${corners[i].x}, ${corners[i].y})');
        _handleCalibrationError('Invalid card position. Please try again.');
        return;
      }
    }

    await _cameraService.stopImageStream();

    state = state.copyWith(
      statusMessage: 'Processing calibration...',
      progress: 1.0,
    );

    await _guidanceManager.speak('Calibration complete');

    try {
      // ✅ Convert normalized coordinates (0-1) to pixel coordinates
      // Using 640x640 as the model input size
      const int modelInputSize = 640;
      final pixelCorners = corners.map((c) => Vector2(
        c.x * modelInputSize,
        c.y * modelInputSize,
      )).toList();

      debugPrint('CalibrationController: Pixel corners:');
      for (int i = 0; i < pixelCorners.length; i++) {
        debugPrint('  Corner $i: (${pixelCorners[i].x.toStringAsFixed(1)}, ${pixelCorners[i].y.toStringAsFixed(1)})');
      }

      // ✅ Compute mm_per_pixel directly from corner positions
      // This is simpler and more accurate than using homography for scale
      final mmPerPixel = HomographyUtils.computeMmPerPixelFromCorners(pixelCorners);

      debugPrint('CalibrationController: Computed mm_per_pixel = ${mmPerPixel.toStringAsFixed(4)}');

      // ✅ Also compute homography for potential perspective corrections
      const int canonicalWidth = 640;
      const int canonicalHeight = 400; // Maintains card aspect ratio (85.6:53.98)
      final homography = HomographyUtils.computeHomography(
        pixelCorners,
        canonicalWidth,
        canonicalHeight,
      );

      // ✅ Validate homography quality
      final quality = HomographyUtils.validateHomographyQuality(
        homography,
        pixelCorners,
      );

      if (quality < 0.90) {
        debugPrint('Warning: Low homography quality: ${(quality * 100).toStringAsFixed(1)}%');
      }


      // Store calibration result
      state = state.copyWith(
        status: CalibrationStatus.completed,
        statusMessage: 'Calibration successful! Scale: ${mmPerPixel.toStringAsFixed(4)} mm/px (Quality: ${(quality * 100).toStringAsFixed(0)}%)',
        mmPerPixel: mmPerPixel,
        homographyMatrix: homography,
        detectedCorners: corners,
        progress: 1.0,
      );

      debugPrint('✅ Calibration completed successfully:');
      debugPrint('  mm_per_pixel: $mmPerPixel');
      debugPrint('  Quality: ${(quality * 100).toStringAsFixed(1)}%');
    } catch (e) {
      _handleCalibrationError('Calibration computation failed: $e');
    }
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
    _isProcessingFrame = false;
    _autoCaptureManager.reset();
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
    super.dispose();
  }

  img.Image _convertCameraImageToImage(CameraImage image) {
    // use Y plane bytes for luminance comparison
    final plane = image.planes.first;
    final width = image.width;
    final height = image.height;
    final imageBytes = Uint8List(width * height * 4);

    for (int i = 0; i < width * height; i++) {
      final yValue = plane.bytes[i];
      imageBytes[i * 4] = yValue; // R
      imageBytes[i * 4 + 1] = yValue; // G
      imageBytes[i * 4 + 2] = yValue; // B
      imageBytes[i * 4 + 3] = 255; // A
    }

    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: imageBytes.buffer,
      numChannels: 4,
    );
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
  final double? stabilityScore;
  final CaptureState captureState;
  final int? countdownValue;
  final double? qualityScore;

  const CalibrationControllerState({
    this.status = CalibrationStatus.idle,
    this.statusMessage = 'Ready to calibrate',
    this.progress = 0.0,
    this.mmPerPixel,
    this.homographyMatrix,
    this.detectedCorners,
    this.stabilityScore,
    this.captureState = CaptureState.waiting,
    this.countdownValue,
    this.qualityScore,
  });

  CalibrationControllerState copyWith({
    CalibrationStatus? status,
    String? statusMessage,
    double? progress,
    double? mmPerPixel,
    Matrix3? homographyMatrix,
    List<Vector2>? detectedCorners,
    double? stabilityScore,
    CaptureState? captureState,
    int? countdownValue,
    double? qualityScore,
  }) {
    return CalibrationControllerState(
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      progress: progress ?? this.progress,
      mmPerPixel: mmPerPixel ?? this.mmPerPixel,
      homographyMatrix: homographyMatrix ?? this.homographyMatrix,
      detectedCorners: detectedCorners ?? this.detectedCorners,
      stabilityScore: stabilityScore ?? this.stabilityScore,
      captureState: captureState ?? this.captureState,
      countdownValue: countdownValue ?? this.countdownValue,
      qualityScore: qualityScore ?? this.qualityScore,
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
    final onnxService = ref.watch(onnxInferenceServiceProvider);
    final guidanceManager = ref.watch(guidanceManagerProvider);
    final stabilityDetector = ref.watch(stabilityDetectorProvider);
    final autoCaptureManager = ref.watch(autoCaptureManagerProvider);
    final reactiveGuidanceManager = ref.watch(reactiveGuidanceManagerProvider);

    return CalibrationController(
      cameraService: cameraService,
      onnxService: onnxService,
      guidanceManager: guidanceManager,
      stabilityDetector: stabilityDetector,
      autoCaptureManager: autoCaptureManager,
      reactiveGuidanceManager: reactiveGuidanceManager,
    );
  },
);
