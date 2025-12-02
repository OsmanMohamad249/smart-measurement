import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/camera_service.dart';
import '../services/tflite_service.dart';
import '../services/guidance_manager.dart';

/// Provider for the CameraService.
final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the TFLiteService.
final tfliteServiceProvider = Provider<TFLiteService>((ref) {
  final service = TFLiteService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the GuidanceManager.
final guidanceManagerProvider = Provider<GuidanceManager>((ref) {
  final manager = GuidanceManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// State notifier for camera initialization.
final cameraInitializerProvider =
    StateNotifierProvider<CameraInitializerNotifier, CameraState>((ref) {
  final cameraService = ref.watch(cameraServiceProvider);
  return CameraInitializerNotifier(cameraService);
});

/// State for camera initialization.
class CameraState {
  final bool isInitialized;
  final bool isLoading;
  final String? error;
  final CameraController? controller;

  const CameraState({
    this.isInitialized = false,
    this.isLoading = false,
    this.error,
    this.controller,
  });

  CameraState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? error,
    CameraController? controller,
  }) {
    return CameraState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      controller: controller ?? this.controller,
    );
  }
}

/// Notifier for camera initialization state.
class CameraInitializerNotifier extends StateNotifier<CameraState> {
  final CameraService _cameraService;

  CameraInitializerNotifier(this._cameraService) : super(const CameraState());

  /// Initializes the camera.
  Future<void> initialize() async {
    if (state.isInitialized || state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _cameraService.initialize();
      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        controller: _cameraService.controller,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialized: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Disposes of the camera.
  Future<void> disposeCamera() async {
    await _cameraService.dispose();
    state = const CameraState();
  }
}

/// Provider for calibration state.
final calibrationStateProvider =
    StateNotifierProvider<CalibrationStateNotifier, CalibrationState>((ref) {
  return CalibrationStateNotifier();
});

/// State for calibration process.
class CalibrationState {
  final CalibrationStep currentStep;
  final bool isCalibrated;
  final double? referenceHeight;
  final List<PoseDetectionResult> calibrationData;
  final String? statusMessage;
  final double? mmPerPixel;

  const CalibrationState({
    this.currentStep = CalibrationStep.initial,
    this.isCalibrated = false,
    this.referenceHeight,
    this.calibrationData = const [],
    this.statusMessage,
    this.mmPerPixel,
  });

  CalibrationState copyWith({
    CalibrationStep? currentStep,
    bool? isCalibrated,
    double? referenceHeight,
    List<PoseDetectionResult>? calibrationData,
    String? statusMessage,
    double? Function()? mmPerPixel,
  }) {
    return CalibrationState(
      currentStep: currentStep ?? this.currentStep,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      referenceHeight: referenceHeight ?? this.referenceHeight,
      calibrationData: calibrationData ?? this.calibrationData,
      statusMessage: statusMessage ?? this.statusMessage,
      mmPerPixel: mmPerPixel != null ? mmPerPixel() : this.mmPerPixel,
    );
  }
}

/// Steps in the calibration process.
enum CalibrationStep {
  initial,
  positioning,
  capturing,
  processing,
  complete,
  error,
}

/// Notifier for calibration state.
class CalibrationStateNotifier extends StateNotifier<CalibrationState> {
  CalibrationStateNotifier() : super(const CalibrationState());

  /// Starts the calibration process.
  void startCalibration() {
    state = state.copyWith(
      currentStep: CalibrationStep.positioning,
      statusMessage: 'Position yourself in front of the camera',
      mmPerPixel: () => null,
    );
  }

  /// Updates the current step.
  void setStep(CalibrationStep step, {String? message}) {
    state = state.copyWith(
      currentStep: step,
      statusMessage: message,
    );
  }

  /// Sets the reference height for calibration.
  void setReferenceHeight(double height) {
    state = state.copyWith(referenceHeight: height);
  }

  /// Adds calibration data.
  void addCalibrationData(PoseDetectionResult result) {
    state = state.copyWith(
      calibrationData: [...state.calibrationData, result],
    );
  }

  /// Persists the computed scale factor (mm per pixel).
  void setScaleFactor(double scaleFactor) {
    state = state.copyWith(mmPerPixel: () => scaleFactor);
  }

  /// Completes calibration.
  void completeCalibration({double? mmPerPixel}) {
    state = state.copyWith(
      currentStep: CalibrationStep.complete,
      isCalibrated: true,
      statusMessage: 'Calibration complete',
      mmPerPixel: () => mmPerPixel ?? state.mmPerPixel,
    );
  }

  /// Resets calibration.
  void resetCalibration() {
    state = const CalibrationState();
  }

  /// Sets an error state.
  void setError(String message) {
    state = state.copyWith(
      currentStep: CalibrationStep.error,
      statusMessage: message,
    );
  }
}
