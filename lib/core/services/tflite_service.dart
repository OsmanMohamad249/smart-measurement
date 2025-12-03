import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../utils/tensor_data_fix.dart';

/// Simple point class for card corners
class CardPoint {
  final double x;
  final double y;

  const CardPoint(this.x, this.y);
}

/// Result from TFLite pose detection inference
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

  bool get isValid => keypoints.isNotEmpty && confidence > 0.3;
}

/// TFLite-based pose detection service
/// Replaces OnnxInferenceService with clean TFLite implementation
class TFLiteService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  // Model configuration
  static const String _modelPath = 'assets/models/best.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';

  // YOLO model input/output specs (adjust based on your model)
  static const int _inputSize = 640; // Standard YOLO input
  static const int _numChannels = 3; // RGB

  bool get isInitialized => _isInitialized;

  /// Initialize the TFLite interpreter and load model
  Future<void> initialize() async {
    try {
      debugPrint('TFLiteService: Initializing...');

      // Load labels
      await _loadLabels();

      // Load model
      _interpreter = await Interpreter.fromAsset(_modelPath);

      // Print model info
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      debugPrint('TFLiteService: Input tensors:');
      for (var tensor in inputTensors) {
        debugPrint('  Shape: ${tensor.shape}, Type: ${tensor.type}');
      }

      debugPrint('TFLiteService: Output tensors:');
      for (var tensor in outputTensors) {
        debugPrint('  Shape: ${tensor.shape}, Type: ${tensor.type}');
      }

      _isInitialized = true;
      debugPrint('TFLiteService: Initialized successfully');

    } catch (e) {
      debugPrint('TFLiteService initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Load labels from assets
  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData.split('\n').where((label) => label.trim().isNotEmpty).toList();
      debugPrint('TFLiteService: Loaded ${_labels.length} labels');
    } catch (e) {
      debugPrint('TFLiteService: Failed to load labels: $e');
      _labels = ['person']; // Default for pose detection
    }
  }

  /// Run inference on a camera image
  Future<PoseDetectionResult> runInference(CameraImage cameraImage) async {
    if (!_isInitialized || _interpreter == null) {
      debugPrint('TFLiteService not initialized');
      throw Exception('TFLiteService not initialized. Call initialize() first.');
    }

    try {
      // Convert CameraImage to img.Image
      final image = _convertCameraImage(cameraImage);
      if (image == null) {
        throw Exception('Failed to convert camera image');
      }

      // Preprocess image
      final input = _preprocessImage(image);

      // Prepare output buffers
      final output = _prepareOutputBuffer();

      // Run inference
      _interpreter!.run(input, output);

      // Post-process results
      final result = _postProcessOutput(output);

      return result;

    } catch (e) {
      debugPrint('TFLiteService inference error: $e');
      rethrow;
    }
  }

  /// Convert CameraImage to img.Image
  img.Image? _convertCameraImage(CameraImage cameraImage) {
    try {
      // Get image dimensions
      final width = cameraImage.width;
      final height = cameraImage.height;

      // Create image based on format
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        // YUV420 format (most common on Android)
        final yPlane = cameraImage.planes[0];
        final uPlane = cameraImage.planes[1];
        final vPlane = cameraImage.planes[2];

        final image = img.Image(width: width, height: height);

        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final yIndex = y * yPlane.bytesPerRow + x;
            final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);

            final yValue = yPlane.bytes[yIndex];
            final uValue = uPlane.bytes[uvIndex];
            final vValue = vPlane.bytes[uvIndex];

            // YUV to RGB conversion
            final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
            final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
            final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

            image.setPixelRgb(x, y, r, g, b);
          }
        }

        return image;
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        // BGRA format (common on iOS)
        final bytes = cameraImage.planes[0].bytes;
        return img.Image.fromBytes(
          width: width,
          height: height,
          bytes: bytes.buffer,
          order: img.ChannelOrder.bgra,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Preprocess image to model input format
  Float32List _preprocessImage(img.Image image) {
    // Resize to model input size
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to normalized float array [1, height, width, channels]
    final input = Float32List(1 * _inputSize * _inputSize * _numChannels);
    int pixelIndex = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);

        // Normalize to [0, 1] range
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  /// Prepare output buffer based on model output shape
  Map<int, Object> _prepareOutputBuffer() {
    // Get output tensor info
    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape;

    debugPrint('TFLiteService: Output shape: $outputShape');

    // For YOLO detection: typically [1, num_detections, num_classes + 5]
    // For pose: might be [1, num_persons, num_keypoints, 3]

    // Allocate buffer - adjust based on your model
    final outputData = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List.filled(outputShape.length > 2 ? outputShape[2] : 1, 0.0),
      ),
    );

    return {0: outputData};
  }

  /// Post-process model output to extract keypoints and card corners
  PoseDetectionResult _postProcessOutput(Map<int, Object> output) {
    final predictions = output[0] as List;

    // Parse predictions to keypoints and card corners
    // This depends on your specific model output format
    final keypoints = <Map<String, dynamic>>[];
    final cardCorners = <CardPoint>[];
    double maxConfidence = 0.0;

    // For YOLO object detection (card detection)
    // Format typically: [batch, detections, (x, y, w, h, conf, ...)]
    for (var detection in predictions[0] as List) {
      final detectionList = detection as List;

      if (detectionList.isEmpty) continue;

      // For YOLO: [x_center, y_center, width, height, confidence, ...]
      final xCenter = (detectionList[0] as num).toDouble();
      final yCenter = (detectionList[1] as num).toDouble();
      final width = (detectionList[2] as num).toDouble();
      final height = (detectionList[3] as num).toDouble();
      final confidence = (detectionList[4] as num).toDouble();

      if (confidence > maxConfidence) {
        maxConfidence = confidence;
      }

      if (confidence > 0.3) { // Confidence threshold
        // Convert bounding box to corners
        // Top-left, top-right, bottom-right, bottom-left
        final x1 = xCenter - width / 2;
        final y1 = yCenter - height / 2;
        final x2 = xCenter + width / 2;
        final y2 = yCenter + height / 2;

        cardCorners.addAll([
          CardPoint(x1, y1), // Top-left
          CardPoint(x2, y1), // Top-right
          CardPoint(x2, y2), // Bottom-right
          CardPoint(x1, y2), // Bottom-left
        ]);

        // If model outputs keypoints (for pose detection)
        // Extract keypoints (adjust based on your model)
        if (detectionList.length > 5) {
          final numKeypoints = 17; // COCO format: 17 keypoints
          final keypointStartIdx = 5; // After bbox and confidence

          for (int i = 0; i < numKeypoints; i++) {
            if (keypointStartIdx + i * 3 + 2 < detectionList.length) {
              final kpX = (detectionList[keypointStartIdx + i * 3] as num).toDouble();
              final kpY = (detectionList[keypointStartIdx + i * 3 + 1] as num).toDouble();
              final kpConf = (detectionList[keypointStartIdx + i * 3 + 2] as num).toDouble();

              keypoints.add({
                'index': i,
                'x': kpX,
                'y': kpY,
                'confidence': kpConf,
              });
            }
          }
        }

        // For card detection, we only need the first detection
        break;
      }
    }

    return PoseDetectionResult(
      keypoints: keypoints,
      confidence: maxConfidence,
      timestamp: DateTime.now(),
      cardCorners: cardCorners,
    );
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    debugPrint('TFLiteService: Disposed');
  }
}

