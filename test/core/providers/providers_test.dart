import 'package:flutter_test/flutter_test.dart';
import 'package:smart_measurement/core/providers/providers.dart';

void main() {
  group('CameraState', () {
    test('default state should have correct values', () {
      const state = CameraState();

      expect(state.isInitialized, false);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.controller, isNull);
    });

    test('copyWith should create new instance with updated values', () {
      const state = CameraState();
      final newState = state.copyWith(isLoading: true);

      expect(newState.isLoading, true);
      expect(newState.isInitialized, false);
    });
  });

  group('CalibrationState', () {
    test('default state should have correct values', () {
      const state = CalibrationState();

      expect(state.currentStep, CalibrationStep.initial);
      expect(state.isCalibrated, false);
      expect(state.referenceHeight, isNull);
      expect(state.calibrationData, isEmpty);
      expect(state.statusMessage, isNull);
    });

    test('copyWith should create new instance with updated values', () {
      const state = CalibrationState();
      final newState = state.copyWith(
        currentStep: CalibrationStep.positioning,
        statusMessage: 'Test message',
      );

      expect(newState.currentStep, CalibrationStep.positioning);
      expect(newState.statusMessage, 'Test message');
      expect(newState.isCalibrated, false);
    });
  });

  group('CalibrationStep', () {
    test('should have all calibration steps', () {
      expect(CalibrationStep.values.length, 6);
      expect(CalibrationStep.values, contains(CalibrationStep.initial));
      expect(CalibrationStep.values, contains(CalibrationStep.positioning));
      expect(CalibrationStep.values, contains(CalibrationStep.capturing));
      expect(CalibrationStep.values, contains(CalibrationStep.processing));
      expect(CalibrationStep.values, contains(CalibrationStep.complete));
      expect(CalibrationStep.values, contains(CalibrationStep.error));
    });
  });

  group('CalibrationStateNotifier', () {
    late CalibrationStateNotifier notifier;

    setUp(() {
      notifier = CalibrationStateNotifier();
    });

    test('startCalibration should change step to positioning', () {
      notifier.startCalibration();

      expect(notifier.state.currentStep, CalibrationStep.positioning);
      expect(notifier.state.statusMessage, isNotNull);
    });

    test('setStep should update current step and message', () {
      notifier.setStep(CalibrationStep.capturing, message: 'Capturing...');

      expect(notifier.state.currentStep, CalibrationStep.capturing);
      expect(notifier.state.statusMessage, 'Capturing...');
    });

    test('setReferenceHeight should update reference height', () {
      notifier.setReferenceHeight(175.0);

      expect(notifier.state.referenceHeight, 175.0);
    });

    test('completeCalibration should set complete state', () {
      notifier.completeCalibration();

      expect(notifier.state.currentStep, CalibrationStep.complete);
      expect(notifier.state.isCalibrated, true);
    });

    test('resetCalibration should reset to initial state', () {
      notifier.startCalibration();
      notifier.setReferenceHeight(175.0);
      notifier.resetCalibration();

      expect(notifier.state.currentStep, CalibrationStep.initial);
      expect(notifier.state.isCalibrated, false);
      expect(notifier.state.referenceHeight, isNull);
    });

    test('setError should set error state', () {
      notifier.setError('Test error');

      expect(notifier.state.currentStep, CalibrationStep.error);
      expect(notifier.state.statusMessage, 'Test error');
    });
  });
}
