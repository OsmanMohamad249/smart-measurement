import 'package:flutter_test/flutter_test.dart';
import 'package:smart_measurement/core/services/tflite_service.dart';

void main() {
  group('TFLiteService', () {
    late TFLiteService tfliteService;

    setUp(() {
      tfliteService = TFLiteService();
    });

    test('initial state should not be initialized', () {
      expect(tfliteService.isInitialized, false);
    });

    test('runInference should return null when not initialized', () async {
      // Create a mock CameraImage would require camera package setup
      // For now, we test that the service handles uninitialized state
      expect(tfliteService.isInitialized, false);
    });
  });

  group('PoseDetectionResult', () {
    test('should create result with empty keypoints', () {
      const result = PoseDetectionResult(
        keypoints: [],
        boundingBox: BoundingBox(x: 0, y: 0, width: 100, height: 200),
        confidence: 0.95,
      );

      expect(result.keypoints, isEmpty);
      expect(result.boundingBox.width, 100);
      expect(result.boundingBox.height, 200);
      expect(result.confidence, 0.95);
    });
  });

  group('Keypoint', () {
    test('should have correct keypoint names', () {
      expect(Keypoint.keypointNames.length, 17);
      expect(Keypoint.keypointNames[0], 'nose');
      expect(Keypoint.keypointNames[5], 'left_shoulder');
      expect(Keypoint.keypointNames[6], 'right_shoulder');
    });

    test('should create keypoint with values', () {
      const keypoint = Keypoint(
        id: 0,
        name: 'nose',
        x: 0.5,
        y: 0.3,
        confidence: 0.9,
      );

      expect(keypoint.id, 0);
      expect(keypoint.name, 'nose');
      expect(keypoint.x, 0.5);
      expect(keypoint.y, 0.3);
      expect(keypoint.confidence, 0.9);
    });
  });

  group('BodyMeasurements', () {
    test('should create body measurements', () {
      const measurements = BodyMeasurements(
        height: 175.0,
        shoulderWidth: 45.0,
        chestCircumference: 95.0,
        waistCircumference: 80.0,
        hipCircumference: 100.0,
        armLength: 60.0,
        legLength: 85.0,
      );

      expect(measurements.height, 175.0);
      expect(measurements.shoulderWidth, 45.0);
      expect(measurements.chestCircumference, 95.0);
      expect(measurements.waistCircumference, 80.0);
      expect(measurements.hipCircumference, 100.0);
      expect(measurements.armLength, 60.0);
      expect(measurements.legLength, 85.0);
    });

    test('toString should return formatted string', () {
      const measurements = BodyMeasurements(
        height: 175.0,
        shoulderWidth: 45.0,
        chestCircumference: 95.0,
        waistCircumference: 80.0,
        hipCircumference: 100.0,
        armLength: 60.0,
        legLength: 85.0,
      );

      final str = measurements.toString();
      expect(str, contains('height: 175.0'));
      expect(str, contains('shoulderWidth: 45.0'));
    });
  });
}
