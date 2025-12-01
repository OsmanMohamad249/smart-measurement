import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
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
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize camera
    await ref.read(cameraInitializerProvider.notifier).initialize();

    // Initialize guidance manager
    final guidanceManager = ref.read(guidanceManagerProvider);
    await guidanceManager.initialize();
    _guidanceInitialized = true;

    // Provide initial guidance
    if (_guidanceInitialized) {
      await guidanceManager.speakCalibrationStart();
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
    final calibrationState = ref.watch(calibrationStateProvider);

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
              child: _buildCameraPreview(cameraState),
            ),
            // Calibration guide and controls
            Expanded(
              flex: 1,
              child: CalibrationGuide(
                calibrationState: calibrationState,
                onStartCalibration: _startCalibration,
                onResetCalibration: _resetCalibration,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(CameraState cameraState) {
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
          child: CameraPreview(controller: cameraState.controller!),
        ),
        // Dynamic polygon overlay placeholder
        const PolygonOverlay(),
        // Positioning indicators
        _buildPositioningIndicators(),
      ],
    );
  }

  Widget _buildPositioningIndicators() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Stand within the guide lines',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _startCalibration() {
    ref.read(calibrationStateProvider.notifier).startCalibration();

    if (_guidanceInitialized) {
      ref
          .read(guidanceManagerProvider)
          .speakPositioningGuidance(PositionFeedback.perfect);
    }
  }

  void _resetCalibration() {
    ref.read(calibrationStateProvider.notifier).resetCalibration();
  }

  void _retryInitialization() {
    ref.read(cameraInitializerProvider.notifier).disposeCamera();
    _initializeServices();
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
                'How to calibrate:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Stand 2-3 meters from the camera'),
              Text('2. Ensure your full body is visible'),
              Text('3. Stand straight with arms slightly away'),
              Text('4. Follow the voice guidance'),
              Text('5. Hold still when capturing'),
              SizedBox(height: 16),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Good lighting improves accuracy'),
              Text('• Wear fitted clothing'),
              Text('• Use a plain background'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
