import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Service for managing camera operations.
///
/// This service provides camera initialization, preview streaming,
/// and image capture functionality for body measurement.
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  /// Returns true if the camera service is initialized and ready.
  bool get isInitialized => _isInitialized;

  /// Returns the current camera controller.
  CameraController? get controller => _controller;

  /// Returns the current camera preview widget.
  Widget? get previewWidget {
    if (_controller != null && _isInitialized) {
      return CameraPreview(controller: _controller!);
    }
    return null;
  }

  /// Initializes the camera service with the specified resolution.
  ///
  /// [resolutionPreset] determines the quality of the camera preview.
  /// Defaults to [ResolutionPreset.high].
  Future<void> initialize({
    ResolutionPreset resolutionPreset = ResolutionPreset.high,
  }) async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw CameraException('NO_CAMERAS', 'No cameras available on device');
      }

      // Use the back camera for body measurement
      final CameraDescription camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        resolutionPreset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('CameraService initialization error: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Starts the image stream for real-time processing.
  ///
  /// [onImage] callback is called for each frame captured.
  Future<void> startImageStream(
    void Function(CameraImage image) onImage,
  ) async {
    if (_controller == null || !_isInitialized) {
      throw CameraException(
        'NOT_INITIALIZED',
        'Camera service not initialized',
      );
    }
    await _controller!.startImageStream(onImage);
  }

  /// Stops the image stream.
  Future<void> stopImageStream() async {
    if (_controller != null && _isInitialized) {
      await _controller!.stopImageStream();
    }
  }

  /// Captures a single image and returns the file path.
  Future<XFile?> captureImage() async {
    if (_controller == null || !_isInitialized) {
      return null;
    }
    try {
      return await _controller!.takePicture();
    } catch (e) {
      debugPrint('CameraService capture error: $e');
      return null;
    }
  }

  /// Disposes of the camera resources.
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}

/// Camera preview widget.
class CameraPreview extends StatelessWidget {
  final CameraController controller;

  const CameraPreview({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return CameraPreviewWidget(controller: controller);
  }
}

/// Actual camera preview implementation.
class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreviewFromController(controller: controller),
    );
  }
}

/// Camera preview from controller.
class CameraPreviewFromController extends StatelessWidget {
  final CameraController controller;

  const CameraPreviewFromController({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return controller.buildPreview();
  }
}
