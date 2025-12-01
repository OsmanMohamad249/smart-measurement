import 'package:flutter_test/flutter_test.dart';
import 'package:smart_measurement/core/services/camera_service.dart';

void main() {
  group('CameraService', () {
    late CameraService cameraService;

    setUp(() {
      cameraService = CameraService();
    });

    test('initial state should not be initialized', () {
      expect(cameraService.isInitialized, false);
      expect(cameraService.controller, isNull);
    });

    test('previewWidget should return null when not initialized', () {
      expect(cameraService.previewWidget, isNull);
    });
  });
}
