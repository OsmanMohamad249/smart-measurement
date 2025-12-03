import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/providers/calibration_controller.dart';
import '../../../../core/services/guidance_manager.dart';
import '../widgets/polygon_overlay.dart';
import '../widgets/calibration_guide.dart';

/// Main screen for smart calibration with camera preview and guidance.
///
/// This screen provides real-time camera preview with a dynamic polygon
/// overlay for positioning guidance during body measurement calibration.
class SmartCalibrationScreen extends ConsumerStatefulWidget {
  const SmartCalibrationScreen({super.key});

  @override
  ConsumerState<SmartCalibrationScreen> createState() =>
      _SmartCalibrationScreenState();
}

class _SmartCalibrationScreenState
    extends ConsumerState<SmartCalibrationScreen> {
  bool _guidanceInitialized = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndInitialize();
  }

  Future<void> _requestPermissionsAndInitialize() async {
    // Request camera permission first
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available on device');
        return;
      }
      // If we got here, permission was granted
      await _initializeServices();
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera permission denied. Please enable it in settings.'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _requestPermissionsAndInitialize,
            ),
          ),
        );
      }
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize camera
      debugPrint('Initializing camera...');
      await ref.read(cameraInitializerProvider.notifier).initialize();
      debugPrint('Camera initialized successfully');

      // Initialize TFLite inference service
      debugPrint('Initializing TFLite service...');
      final tfliteService = ref.read(tfliteServiceProvider);
      await tfliteService.initialize();
      debugPrint('TFLite service initialized: ${tfliteService.isInitialized}');

      // Initialize guidance manager
      debugPrint('Initializing guidance manager...');
      final guidanceManager = ref.read(guidanceManagerProvider);
      await guidanceManager.initialize();
      _guidanceInitialized = true;
      debugPrint('Guidance manager initialized');

      // Provide initial guidance
      if (_guidanceInitialized) {
        await guidanceManager.speakCalibrationStart();
      }
    } catch (e, stackTrace) {
      debugPrint('Error initializing services: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Initialization error: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    ref.read(cameraInitializerProvider.notifier).disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraInitializerProvider);
    final calibrationController = ref.watch(calibrationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Calibration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera preview with overlay
            Expanded(
              flex: 3,
              child: _buildCameraPreview(cameraState, calibrationController),
            ),
            // Calibration status and controls
            Expanded(
              flex: 1,
              child: _buildCalibrationControls(calibrationController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(
    CameraState cameraState,
    CalibrationControllerState calibrationController,
  ) {
    if (cameraState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    if (cameraState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                cameraState.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retryInitialization,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!cameraState.isInitialized || cameraState.controller == null) {
      return const Center(
        child: Text('Camera not available'),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CameraPreview(cameraState.controller!),
        ),
        // Polygon overlay showing detected card corners
        if (calibrationController.detectedCorners != null)
          PolygonOverlay(corners: calibrationController.detectedCorners),
        // Status indicators
        _buildStatusIndicators(calibrationController),
      ],
    );
  }

  Widget _buildStatusIndicators(CalibrationControllerState state) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _getStatusColor(state.status).withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.statusMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.status == CalibrationStatus.calibrating && state.progress > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CalibrationStatus status) {
    switch (status) {
      case CalibrationStatus.idle:
        return Colors.blue;
      case CalibrationStatus.calibrating:
        return Colors.orange;
      case CalibrationStatus.completed:
        return Colors.green;
      case CalibrationStatus.error:
        return Colors.red;
    }
  }

  Widget _buildCalibrationControls(CalibrationControllerState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.isCalibrated) ...[
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Scale: ${state.mmPerPixel?.toStringAsFixed(4)} mm/px',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _proceedToCapture,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _resetCalibration,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recalibrate'),
                ),
              ],
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: state.status == CalibrationStatus.calibrating
                  ? null
                  : _startCalibration,
              icon: state.status == CalibrationStatus.calibrating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera),
              label: Text(
                state.status == CalibrationStatus.calibrating
                    ? 'Calibrating...'
                    : 'Start Calibration',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            if (state.status == CalibrationStatus.error) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _retryCalibration,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _startCalibration() {
    ref.read(calibrationControllerProvider.notifier).startCalibration();
  }

  void _resetCalibration() {
    ref.read(calibrationControllerProvider.notifier).resetCalibration();
  }

  void _retryCalibration() {
    ref.read(calibrationControllerProvider.notifier).retryCalibration();
  }

  void _retryInitialization() {
    _requestPermissionsAndInitialize();
  }

  void _proceedToCapture() {
    // Navigate to capture screen
    Navigator.pushNamed(context, '/capture');
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibration Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to Calibrate:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Place a standard ID card (85.6mm × 53.98mm) on a flat surface'),
              SizedBox(height: 4),
              Text('2. Ensure good lighting and avoid shadows'),
              SizedBox(height: 4),
              Text('3. Tap "Start Calibration" and hold the camera steady'),
              SizedBox(height: 4),
              Text('4. The app will detect the card corners automatically'),
              SizedBox(height: 4),
              Text('5. Wait for the progress bar to complete'),
              SizedBox(height: 12),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Keep the card flat and fully visible'),
              Text('• Avoid reflective surfaces'),
              Text('• Maintain a steady hand for accurate detection'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
}
