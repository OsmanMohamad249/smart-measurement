import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;

/// Simple point class for card corners
class CardPoint {
  final double x;
  final double y;

  const CardPoint(this.x, this.y);
}

/// Result from ONNX pose detection inference
class PoseDetectionResult {
  final List<Map<String, dynamic>> keypoints;
  final double confidence;
  final DateTime timestamp;
  final List<CardPoint> cardCorners;

  PoseDetectionResult({
    required this.keypoints,
    required this.confidence,
    required this.timestamp,
    this.cardCorners = const [],
  });

  // Require higher confidence and valid corners
  bool get isValid => cardCorners.length == 4 && confidence > 0.5;
}

/// ONNX Runtime-based card detection service using trained YOLOv8-pose model
class OnnxInferenceService {
  OrtSession? _session;
  List<String> _labels = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _useFallbackDetection = false;

  // Model configuration - matches trained model
  static const String _modelPath = 'assets/models/best.onnx';
  static const String _labelsPath = 'assets/models/labels.txt';

  // YOLOv8-pose model uses NCHW format (channels first)
  final int _inputHeight = 416;
  final int _inputWidth = 416;
  final int _inputChannels = 3;
  String _inputName = 'images';
  String _outputName = 'output0';

  // Frame skipping for performance - reduced for faster detection
  int _frameCount = 0;
  static const int _processEveryNthFrame = 1; // Process every frame for faster response

  // Last detection cache - with stability tracking
  PoseDetectionResult? _lastValidResult;
  DateTime? _lastDetectionTime;
  List<List<CardPoint>>? _cornerHistory;
  static const int _smoothingWindow = 5;

  // Stability parameters - relaxed for faster detection
  static const double _maxCornerMovement = 0.12; // Increased tolerance
  int _stableFrameCount = 0;
  static const int _requiredStableFrames = 2; // Reduced from 3

  bool get isInitialized => _isInitialized;
  bool get usingFallback => _useFallbackDetection;

  /// Initialize the ONNX Runtime and load model
  Future<void> initialize() async {
    try {
      debugPrint('OnnxInferenceService: Initializing...');
      debugPrint('OnnxInferenceService: Model path: $_modelPath');
      _cornerHistory = [];
      await _loadLabels();

      // Initialize ONNX Runtime environment
      OrtEnv.instance.init();

      // Create session options
      final sessionOptions = OrtSessionOptions()
        ..setInterOpNumThreads(2)
        ..setIntraOpNumThreads(4);

      try {
        debugPrint('OnnxInferenceService: Attempting to load model from asset...');

        // Load model data from asset
        final modelData = await rootBundle.load(_modelPath);
        final buffer = modelData.buffer;
        final bytes = buffer.asUint8List(modelData.offsetInBytes, modelData.lengthInBytes);

        debugPrint('OnnxInferenceService: Model data loaded, size: ${bytes.length} bytes');

        // Create ONNX session
        _session = OrtSession.fromBuffer(bytes, sessionOptions);
        debugPrint('OnnxInferenceService: Session created successfully!');

        // Get input/output info
        final inputs = _session!.inputNames;
        final outputs = _session!.outputNames;

        if (inputs.isNotEmpty) {
          _inputName = inputs.first;
          debugPrint('OnnxInferenceService: Input name: $_inputName');
        }

        if (outputs.isNotEmpty) {
          _outputName = outputs.first;
          debugPrint('OnnxInferenceService: Output name: $_outputName');
        }

        debugPrint('OnnxInferenceService: Model loaded - Input: ${_inputHeight}x${_inputWidth}x$_inputChannels');
        _useFallbackDetection = false;

      } catch (modelError, stackTrace) {
        debugPrint('OnnxInferenceService: ❌ Model loading failed: $modelError');
        debugPrint('OnnxInferenceService: Stack trace: $stackTrace');
        _useFallbackDetection = true;
        _session?.release();
        _session = null;
      }

      _isInitialized = true;
      debugPrint('OnnxInferenceService: Initialized (mode: ${_useFallbackDetection ? "❌ Fallback - NO DETECTION" : "✅ ONNX"})');

    } catch (e, stackTrace) {
      debugPrint('OnnxInferenceService initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      _useFallbackDetection = true;
      _isInitialized = true;
    }
  }

  /// Load labels from assets
  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData.split('\n').where((label) => label.trim().isNotEmpty).toList();
      debugPrint('OnnxInferenceService: Loaded ${_labels.length} labels');
    } catch (e) {
      debugPrint('OnnxInferenceService: Failed to load labels: $e');
      _labels = ['card'];
    }
  }

  /// Run inference on a camera image
  Future<PoseDetectionResult?> runInference(CameraImage cameraImage) async {
    if (!_isInitialized) return null;

    // Skip frames for performance
    _frameCount++;
    if (_frameCount % _processEveryNthFrame != 0) {
      if (_lastValidResult != null && _lastDetectionTime != null) {
        final age = DateTime.now().difference(_lastDetectionTime!).inMilliseconds;
        if (age < 300) {
          return _lastValidResult;
        }
      }
      return null;
    }

    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      if (_useFallbackDetection || _session == null) {
        debugPrint('OnnxInferenceService: No model available');
        return _emptyResult();
      }

      // Convert camera image
      final image = _convertCameraImage(cameraImage);
      if (image == null) return null;

      // Run ONNX inference
      try {
        final input = _preprocessImage(image);

        // Create input tensor
        final inputTensor = OrtValueTensor.createTensorWithDataList(
          input,
          [1, _inputChannels, _inputHeight, _inputWidth],
        );

        // Run inference
        final runOptions = OrtRunOptions();
        final outputs = await _session!.runAsync(
          runOptions,
          {_inputName: inputTensor},
        );

        // Parse output - outputs is a List<OrtValue?>
        if (outputs == null || outputs.isEmpty) {
          return _emptyResult();
        }

        final outputTensor = outputs.first;
        if (outputTensor == null) {
          return _emptyResult();
        }

        final outputData = outputTensor.value as List;
        final result = _parseYoloPoseOutput(outputData);

        // Apply stability filtering
        final stableResult = _applyStabilityFilter(result);

        // Cache valid results
        if (stableResult.isValid) {
          _lastValidResult = stableResult;
          _lastDetectionTime = DateTime.now();
          debugPrint('OnnxInferenceService: Stable card detected! confidence=${stableResult.confidence.toStringAsFixed(3)}');
        }

        // Release tensors
        inputTensor.release();
        outputTensor.release();
        runOptions.release();

        return stableResult;

      } catch (e) {
        debugPrint('OnnxInferenceService: Inference error: $e');
        return _emptyResult();
      }

    } catch (e) {
      debugPrint('OnnxInferenceService inference error: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert camera image to img.Image
  img.Image? _convertCameraImage(CameraImage cameraImage) {
    try {
      final width = cameraImage.width;
      final height = cameraImage.height;

      const downsample = 2;
      final outWidth = width ~/ downsample;
      final outHeight = height ~/ downsample;

      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        final yPlane = cameraImage.planes[0];
        final uPlane = cameraImage.planes[1];
        final vPlane = cameraImage.planes[2];

        final image = img.Image(width: outWidth, height: outHeight);

        for (int y = 0; y < outHeight; y++) {
          final srcY = y * downsample;
          for (int x = 0; x < outWidth; x++) {
            final srcX = x * downsample;

            final yIndex = srcY * yPlane.bytesPerRow + srcX;
            final uvIndex = (srcY ~/ 2) * uPlane.bytesPerRow + (srcX ~/ 2);

            if (yIndex >= yPlane.bytes.length || uvIndex >= uPlane.bytes.length) continue;

            final yValue = yPlane.bytes[yIndex];
            final uValue = uPlane.bytes[uvIndex];
            final vValue = vPlane.bytes[uvIndex];

            final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
            final g = (yValue - 0.344 * (uValue - 128) - 0.714 * (vValue - 128)).clamp(0, 255).toInt();
            final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

            image.setPixelRgb(x, y, r, g, b);
          }
        }

        return image;
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        final plane = cameraImage.planes[0];
        final image = img.Image(width: outWidth, height: outHeight);

        for (int y = 0; y < outHeight; y++) {
          final srcY = y * downsample;
          for (int x = 0; x < outWidth; x++) {
            final srcX = x * downsample;
            final idx = (srcY * width + srcX) * 4;

            if (idx + 3 < plane.bytes.length) {
              final b = plane.bytes[idx];
              final g = plane.bytes[idx + 1];
              final r = plane.bytes[idx + 2];
              image.setPixelRgb(x, y, r, g, b);
            }
          }
        }
        return image;
      }

      debugPrint('OnnxInferenceService: Unsupported image format: ${cameraImage.format.group}');
      return null;
    } catch (e) {
      debugPrint('OnnxInferenceService: Image conversion error: $e');
      return null;
    }
  }

  /// Preprocess image for ONNX model (NCHW format)
  Float32List _preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width: _inputWidth,
      height: _inputHeight,
      interpolation: img.Interpolation.nearest,
    );

    final input = Float32List(1 * _inputChannels * _inputHeight * _inputWidth);

    // NCHW format - channels first
    int idx = 0;
    // Red channel
    for (int y = 0; y < _inputHeight; y++) {
      for (int x = 0; x < _inputWidth; x++) {
        final pixel = resized.getPixel(x, y);
        input[idx++] = pixel.r / 255.0;
      }
    }
    // Green channel
    for (int y = 0; y < _inputHeight; y++) {
      for (int x = 0; x < _inputWidth; x++) {
        final pixel = resized.getPixel(x, y);
        input[idx++] = pixel.g / 255.0;
      }
    }
    // Blue channel
    for (int y = 0; y < _inputHeight; y++) {
      for (int x = 0; x < _inputWidth; x++) {
        final pixel = resized.getPixel(x, y);
        input[idx++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  /// Parse YOLOv8-OBB output format: [6, 8400]
  /// Row 0: cx (center x)
  /// Row 1: cy (center y)
  /// Row 2: w (width)
  /// Row 3: h (height)
  /// Row 4: confidence
  /// Row 5: angle (rotation in radians)

  PoseDetectionResult _parseYoloPoseOutput(List output) {
    final cardCorners = <CardPoint>[];
    double maxConfidence = 0.0;

    try {
      if (output.isEmpty) return _emptyResult();

      final batch = output[0];
      if (batch is! List || batch.isEmpty) return _emptyResult();

      final numValues = batch.length;
      final numDetections = (batch[0] is List) ? (batch[0] as List).length : 0;

      debugPrint('OnnxInferenceService: Parsing OBB output [$numValues, $numDetections]');

      // ✅ CRITICAL: Higher confidence threshold to avoid false positives
      // Card detection must be VERY confident - not just any rectangle
      const double confThreshold = 0.70; // Increased from 0.40 to 0.70

      // ✅ CRITICAL: Standard credit/ID card dimensions for validation
      // Standard card: 85.6mm x 53.98mm = aspect ratio ~1.586
      const double cardAspectRatio = 1.586;
      const double aspectRatioTolerance = 0.25; // Allow ±25% variation
      const double minAspectRatio = cardAspectRatio * (1 - aspectRatioTolerance);
      const double maxAspectRatio = cardAspectRatio * (1 + aspectRatioTolerance);

      // ✅ CRITICAL: Card size validation
      // Card should occupy reasonable portion of frame (not too small, not too large)
      const double minAreaPercent = 8.0;  // At least 8% of frame
      const double maxAreaPercent = 60.0; // At most 60% of frame

      double bestConf = 0.0;
      int bestIdx = -1;
      double bestCx = 0, bestCy = 0, bestW = 0, bestH = 0, bestAngle = 0;

      // Find the detection with HIGHEST confidence above threshold
      // AND validate it's actually a card (correct aspect ratio + size)
      for (int i = 0; i < numDetections; i++) {
        final conf = _getOutputValue(batch, 4, i);
        if (conf < confThreshold) continue;

        final cx = _getOutputValue(batch, 0, i);
        final cy = _getOutputValue(batch, 1, i);
        final w = _getOutputValue(batch, 2, i);
        final h = _getOutputValue(batch, 3, i);

        // ✅ Validate minimum size
        if (w < 50 || h < 30) {
          debugPrint('OnnxInferenceService: ❌ Rejected - too small: ${w.toStringAsFixed(0)}x${h.toStringAsFixed(0)}');
          continue;
        }

        // ✅ CRITICAL: Validate aspect ratio matches card dimensions
        final detectedAspectRatio = math.max(w, h) / math.min(w, h);
        if (detectedAspectRatio < minAspectRatio || detectedAspectRatio > maxAspectRatio) {
          debugPrint('OnnxInferenceService: ❌ Rejected - wrong aspect ratio: ${detectedAspectRatio.toStringAsFixed(2)} (expected: ${cardAspectRatio.toStringAsFixed(2)} ±${(aspectRatioTolerance*100).toStringAsFixed(0)}%)');
          continue;
        }

        // ✅ CRITICAL: Validate card area
        final areaPercent = (w * h) / (_inputWidth * _inputHeight) * 100;
        if (areaPercent < minAreaPercent || areaPercent > maxAreaPercent) {
          debugPrint('OnnxInferenceService: ❌ Rejected - wrong size: ${areaPercent.toStringAsFixed(1)}% (expected: $minAreaPercent%-$maxAreaPercent%)');
          continue;
        }

        // ✅ CRITICAL: Card should be reasonably centered (not at extreme edge)
        final centerX = cx / _inputWidth;
        final centerY = cy / _inputHeight;
        if (centerX < 0.15 || centerX > 0.85 || centerY < 0.15 || centerY > 0.85) {
          debugPrint('OnnxInferenceService: ❌ Rejected - too close to edge: center=(${(centerX*100).toStringAsFixed(0)}%, ${(centerY*100).toStringAsFixed(0)}%)');
          continue;
        }

        // ✅ All validations passed - this is a strong candidate
        if (conf > bestConf) {
          bestConf = conf;
          bestIdx = i;
          bestCx = cx;
          bestCy = cy;
          bestW = w;
          bestH = h;
          bestAngle = numValues > 5 ? _getOutputValue(batch, 5, i) : 0.0;
        }
      }

      maxConfidence = bestConf;

      // If we found a VALIDATED detection, use it
      if (bestIdx >= 0) {
        final aspectRatio = math.max(bestW, bestH) / math.min(bestW, bestH);
        final areaPercent = (bestW * bestH) / (_inputWidth * _inputHeight) * 100;

        debugPrint('OnnxInferenceService: ✅ VALID CARD DETECTED - conf=${bestConf.toStringAsFixed(2)}, '
            'pos=(${bestCx.toStringAsFixed(0)}, ${bestCy.toStringAsFixed(0)}), '
            'size=${bestW.toStringAsFixed(0)}x${bestH.toStringAsFixed(0)}, '
            'aspect=${aspectRatio.toStringAsFixed(2)}, area=${areaPercent.toStringAsFixed(1)}%');

        // Convert OBB (center, width, height, angle) to 4 corners
        final corners = _obbToCorners(bestCx, bestCy, bestW, bestH, bestAngle);

        for (final corner in corners) {
          // Normalize to [0, 1] range
          final x = (corner[0] / _inputWidth).clamp(0.0, 1.0);
          final y = (corner[1] / _inputHeight).clamp(0.0, 1.0);
          cardCorners.add(CardPoint(x, y));
        }
      } else {
        // Debug: show why detection failed
        int totalDetections = 0;
        int lowConfidence = 0;
        int wrongAspect = 0;
        int wrongSize = 0;

        for (int i = 0; i < numDetections; i++) {
          final conf = _getOutputValue(batch, 4, i);
          if (conf > 0.1) {
            totalDetections++;
            if (conf < confThreshold) {
              lowConfidence++;
            } else {
              final w = _getOutputValue(batch, 2, i);
              final h = _getOutputValue(batch, 3, i);
              final ar = math.max(w, h) / math.min(w, h);
              final area = (w * h) / (_inputWidth * _inputHeight) * 100;

              if (ar < minAspectRatio || ar > maxAspectRatio) wrongAspect++;
              if (area < minAreaPercent || area > maxAreaPercent) wrongSize++;
            }
          }
        }

        if (totalDetections > 0) {
          debugPrint('OnnxInferenceService: ❌ No valid card: $totalDetections detections - '
              '$lowConfidence low conf, $wrongAspect wrong aspect, $wrongSize wrong size');
        }
      }

    } catch (e) {
      debugPrint('OnnxInferenceService: Parse error: $e');
      return _emptyResult();
    }

    return PoseDetectionResult(
      keypoints: [],
      confidence: maxConfidence,
      timestamp: DateTime.now(),
      cardCorners: cardCorners,
    );
  }

  /// Convert OBB (oriented bounding box) to 4 corner points
  /// Returns corners in order: top-left, top-right, bottom-right, bottom-left
  List<List<double>> _obbToCorners(double cx, double cy, double w, double h, double angle) {
    // Half dimensions
    final hw = w / 2;
    final hh = h / 2;

    // Corner offsets before rotation (relative to center)
    final offsets = [
      [-hw, -hh], // top-left
      [hw, -hh],  // top-right
      [hw, hh],   // bottom-right
      [-hw, hh],  // bottom-left
    ];

    // Rotate each corner around center
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final corners = <List<double>>[];
    for (final offset in offsets) {
      final rx = offset[0] * cosA - offset[1] * sinA;
      final ry = offset[0] * sinA + offset[1] * cosA;
      corners.add([cx + rx, cy + ry]);
    }

    return corners;
  }

  double _getOutputValue(List batch, int row, int col) {
    try {
      if (row < batch.length && batch[row] is List) {
        final rowList = batch[row] as List;
        if (col < rowList.length) {
          return (rowList[col] as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint('OnnxInferenceService: Error getting value at [$row, $col]: $e');
    }
    return 0.0;
  }

  PoseDetectionResult _emptyResult() {
    return PoseDetectionResult(
      keypoints: [],
      confidence: 0.0,
      timestamp: DateTime.now(),
      cardCorners: [],
    );
  }

  /// Apply stability filter to smooth detections
  PoseDetectionResult _applyStabilityFilter(PoseDetectionResult result) {
    if (result.cardCorners.length != 4) {
      _stableFrameCount = 0;
      return result;
    }

    _cornerHistory ??= [];
    _cornerHistory!.add(result.cardCorners);

    if (_cornerHistory!.length > _smoothingWindow) {
      _cornerHistory!.removeAt(0);
    }

    if (_cornerHistory!.length < 2) {
      return result;
    }

    // Check movement stability
    final prevCorners = _cornerHistory![_cornerHistory!.length - 2];
    double maxMovement = 0.0;

    for (int i = 0; i < 4; i++) {
      final dx = result.cardCorners[i].x - prevCorners[i].x;
      final dy = result.cardCorners[i].y - prevCorners[i].y;
      final movement = math.sqrt(dx * dx + dy * dy);
      maxMovement = math.max(maxMovement, movement);
    }

    if (maxMovement < _maxCornerMovement) {
      _stableFrameCount++;
    } else {
      _stableFrameCount = math.max(0, _stableFrameCount - 1);
    }

    // Average corners if stable
    if (_stableFrameCount >= _requiredStableFrames && _cornerHistory!.length >= 3) {
      final avgCorners = <CardPoint>[];
      for (int i = 0; i < 4; i++) {
        double sumX = 0, sumY = 0;
        for (final corners in _cornerHistory!) {
          sumX += corners[i].x;
          sumY += corners[i].y;
        }
        avgCorners.add(CardPoint(
          sumX / _cornerHistory!.length,
          sumY / _cornerHistory!.length,
        ));
      }

      return PoseDetectionResult(
        keypoints: result.keypoints,
        confidence: result.confidence,
        timestamp: result.timestamp,
        cardCorners: avgCorners,
      );
    }

    return result;
  }

  /// Dispose resources
  void dispose() {
    _session?.release();
    _session = null;
    _isInitialized = false;
    debugPrint('OnnxInferenceService: Disposed');
  }
}

