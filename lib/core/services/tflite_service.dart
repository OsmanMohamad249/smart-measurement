import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../utils/geometry_utils.dart';

/// Service for TensorFlow Lite model inference with YOLOv8.
class TFLiteService {
  bool _isInitialized = false;
  Interpreter? _interpreter;
  List<int>? _inputShape;
  List<int>? _outputShape;

  static const int inputSize = 640;
  static const double confidenceThreshold = 0.5;

  bool get isInitialized => _isInitialized;

  Future<void> initialize({String modelPath = 'assets/yolov8_pose.tflite'}) async {
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(modelPath, options: options);
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
      _isInitialized = true;
      debugPrint('TFLiteService initialized with model: $modelPath');
    } catch (e) {
      _isInitialized = false;
      debugPrint('TFLiteService initialization error: $e');
      rethrow;
    }
  }

  Future<CalibrationResult?> runInference(CameraImage image) async {
    if (!_isInitialized || _interpreter == null) {
      debugPrint('TFLiteService not initialized');
      return null;
    }

    try {
      final inputBuffer = await _preprocessImage(image);
      final outputLength =
          _outputShape?.fold<int>(1, (value, dim) => value * dim) ?? 0;
      if (outputLength == 0) {
        debugPrint('TFLiteService output shape unavailable');
        return null;
      }

      final outputBuffer = Float32List(outputLength);
      _interpreter!.run(inputBuffer, outputBuffer);

      final corners =
          _extractCardCorners(outputBuffer, image.width, image.height);
      if (!GeometryUtils.isCardShapeValid(corners)) {
        debugPrint('Discarded inference due to invalid card geometry');
        return null;
      }

      final scaleFactor = GeometryUtils.calculateScaleFactor(corners);
      final keypoints =
          _extractKeypoints(outputBuffer, image.width, image.height);
      final boundingBox =
          _calculateBoundingBox(keypoints, image.width, image.height);
      final confidence = _averageConfidence(keypoints);

      final poseResult = PoseDetectionResult(
        keypoints: keypoints,
        boundingBox: boundingBox,
        confidence: confidence,
      );

      return CalibrationResult(
        poseResult: poseResult,
        cardCorners: corners,
        scaleFactor: scaleFactor,
      );
    } catch (e) {
      debugPrint('TFLiteService inference error: $e');
      return null;
    }
  }

  Future<Float32List> _preprocessImage(CameraImage image) async {
    final payload = _SerializableCameraImage.fromCameraImage(image);
    final rgbaBytes = await compute(_convertYuv420ToRgbaBytes, payload);
    final rgbaImage = img.Image.fromBytes(
      width: payload.width,
      height: payload.height,
      bytes: rgbaBytes,
      numChannels: 4,
    );

    final resized = img.copyResize(
      rgbaImage,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.average,
    );

    final Float32List input = Float32List(inputSize * inputSize * 3);
    int bufferIndex = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[bufferIndex++] = img.getRed(pixel) / 255.0;
        input[bufferIndex++] = img.getGreen(pixel) / 255.0;
        input[bufferIndex++] = img.getBlue(pixel) / 255.0;
      }
    }

    return input;
  }

  List<Point<double>> _extractCardCorners(
    Float32List output,
    int frameWidth,
    int frameHeight,
  ) {
    if (output.length < 8) {
      return const <Point<double>>[];
    }

    final corners = <Point<double>>[];
    for (int i = 0; i < 4; i++) {
      final x = output[i * 2].clamp(0.0, 1.0) * frameWidth;
      final y = output[i * 2 + 1].clamp(0.0, 1.0) * frameHeight;
      corners.add(Point<double>(x, y));
    }
    return corners;
  }

  List<Keypoint> _extractKeypoints(
    Float32List output,
    int frameWidth,
    int frameHeight,
  ) {
    const int offset = 8; // first 8 values are the card corners
    const int valuesPerKeypoint = 3; // x, y, confidence

    if (output.length <= offset) {
      return const <Keypoint>[];
    }

    final availableValues = output.length - offset;
    final keypointCount =
        min(Keypoint.keypointNames.length, availableValues ~/ valuesPerKeypoint);

    final keypoints = <Keypoint>[];
    for (int i = 0; i < keypointCount; i++) {
      final baseIndex = offset + i * valuesPerKeypoint;
      final x = output[baseIndex].clamp(0.0, 1.0) * frameWidth;
      final y = output[baseIndex + 1].clamp(0.0, 1.0) * frameHeight;
      final confidence = output[baseIndex + 2].clamp(0.0, 1.0);

      if (confidence < confidenceThreshold) {
        continue;
      }

      keypoints.add(
        Keypoint(
          id: i,
          name: Keypoint.keypointNames[i],
          x: x,
          y: y,
          confidence: confidence,
        ),
      );
    }

    return keypoints;
  }

  BoundingBox _calculateBoundingBox(
    List<Keypoint> keypoints,
    int frameWidth,
    int frameHeight,
  ) {
    if (keypoints.isEmpty) {
      return BoundingBox(
        x: 0,
        y: 0,
        width: frameWidth.toDouble(),
        height: frameHeight.toDouble(),
      );
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final keypoint in keypoints) {
      minX = min(minX, keypoint.x);
      minY = min(minY, keypoint.y);
      maxX = max(maxX, keypoint.x);
      maxY = max(maxY, keypoint.y);
    }

    return BoundingBox(
      x: minX,
      y: minY,
      width: max(0, maxX - minX),
      height: max(0, maxY - minY),
    );
  }

  double _averageConfidence(List<Keypoint> keypoints) {
    if (keypoints.isEmpty) return 0;
    final total =
        keypoints.fold<double>(0, (previousValue, element) => previousValue + element.confidence);
    return total / keypoints.length;
  }

  Future<BodyMeasurements?> extractMeasurements(
    PoseDetectionResult result, {
    required double referenceHeight,
  }) async {
    if (result.keypoints.isEmpty || referenceHeight <= 0) {
      return null;
    }

    final heightPixels = result.boundingBox.height;
    if (heightPixels <= 0) {
      return null;
    }

    final mmPerPixel = referenceHeight / heightPixels;
    return BodyMeasurements(
      height: referenceHeight,
      shoulderWidth: result.boundingBox.width * mmPerPixel * 0.4,
      chestCircumference: result.boundingBox.width * mmPerPixel * 0.9,
      waistCircumference: result.boundingBox.width * mmPerPixel * 0.8,
      hipCircumference: result.boundingBox.width * mmPerPixel,
      armLength: result.boundingBox.height * mmPerPixel * 0.45,
      legLength: result.boundingBox.height * mmPerPixel * 0.55,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

/// Result of pose detection inference.
class PoseDetectionResult {
  final List<Keypoint> keypoints;
  final BoundingBox boundingBox;
  final double confidence;

  const PoseDetectionResult({
    required this.keypoints,
    required this.boundingBox,
    required this.confidence,
  });
}

/// A single keypoint in pose detection.
class Keypoint {
  final int id;
  final String name;
  final double x;
  final double y;
  final double confidence;

  const Keypoint({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.confidence,
  });

  /// YOLOv8 pose keypoint names.
  static const List<String> keypointNames = [
    'nose',
    'left_eye',
    'right_eye',
    'left_ear',
    'right_ear',
    'left_shoulder',
    'right_shoulder',
    'left_elbow',
    'right_elbow',
    'left_wrist',
    'right_wrist',
    'left_hip',
    'right_hip',
    'left_knee',
    'right_knee',
    'left_ankle',
    'right_ankle',
  ];
}

/// Bounding box for detected person.
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Body measurements extracted from pose detection.
class BodyMeasurements {
  final double height;
  final double shoulderWidth;
  final double chestCircumference;
  final double waistCircumference;
  final double hipCircumference;
  final double armLength;
  final double legLength;

  const BodyMeasurements({
    required this.height,
    required this.shoulderWidth,
    required this.chestCircumference,
    required this.waistCircumference,
    required this.hipCircumference,
    required this.armLength,
    required this.legLength,
  });

  @override
  String toString() {
    return 'BodyMeasurements('
        'height: $height cm, '
        'shoulderWidth: $shoulderWidth cm, '
        'chestCircumference: $chestCircumference cm, '
        'waistCircumference: $waistCircumference cm, '
        'hipCircumference: $hipCircumference cm, '
        'armLength: $armLength cm, '
        'legLength: $legLength cm)';
  }
}

class CalibrationResult {
  final PoseDetectionResult poseResult;
  final List<Point<double>> cardCorners;
  final double scaleFactor;

  const CalibrationResult({
    required this.poseResult,
    required this.cardCorners,
    required this.scaleFactor,
  });
}

Uint8List _convertYuv420ToRgbaBytes(_SerializableCameraImage payload) {
  final width = payload.width;
  final height = payload.height;
  final yPlane = payload.planes[0];
  final uPlane = payload.planes[1];
  final vPlane = payload.planes[2];

  final rgbaBytes = Uint8List(width * height * 4);
  int index = 0;

  for (int y = 0; y < height; y++) {
    final uvRow = (y >> 1) * uPlane.bytesPerRow;
    for (int x = 0; x < width; x++) {
      final uvColumn = (x >> 1) * uPlane.bytesPerPixel;

      final yValue = yPlane.bytes[y * yPlane.bytesPerRow + x];
      final uValue = uPlane.bytes[uvRow + uvColumn];
      final vValue = vPlane.bytes[uvRow + uvColumn];

      final c = yValue - 16;
      final d = uValue - 128;
      final e = vValue - 128;

      int r = (1.164 * c + 1.596 * e).round();
      int g = (1.164 * c - 0.392 * d - 0.813 * e).round();
      int b = (1.164 * c + 2.017 * d).round();

      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);

      rgbaBytes[index++] = r;
      rgbaBytes[index++] = g;
      rgbaBytes[index++] = b;
      rgbaBytes[index++] = 255;
    }
  }

  return rgbaBytes;
}

class _SerializableCameraImage {
  final int width;
  final int height;
  final List<_SerializablePlane> planes;

  _SerializableCameraImage({
    required this.width,
    required this.height,
    required this.planes,
  });

  factory _SerializableCameraImage.fromCameraImage(CameraImage image) {
    return _SerializableCameraImage(
      width: image.width,
      height: image.height,
      planes: image.planes
          .map(
            (plane) => _SerializablePlane(
              bytes: Uint8List.fromList(plane.bytes),
              bytesPerRow: plane.bytesPerRow,
              bytesPerPixel: plane.bytesPerPixel ?? 1,
            ),
          )
          .toList(),
    );
  }
}

class _SerializablePlane {
  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;

  _SerializablePlane({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });
}
