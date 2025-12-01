import 'package:flutter/material.dart';
import '../../../../core/providers/providers.dart';

/// Widget for displaying calibration guidance and controls.
///
/// Shows the current calibration status, instructions, and action buttons.
class CalibrationGuide extends StatelessWidget {
  final CalibrationState calibrationState;
  final VoidCallback onStartCalibration;
  final VoidCallback onResetCalibration;

  const CalibrationGuide({
    super.key,
    required this.calibrationState,
    required this.onStartCalibration,
    required this.onResetCalibration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status indicator
          _buildStatusIndicator(context),
          const SizedBox(height: 12),
          // Status message
          Text(
            _getStatusMessage(),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final (icon, color) = _getStatusIconAndColor();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          _getStepTitle(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  (IconData, Color) _getStatusIconAndColor() {
    switch (calibrationState.currentStep) {
      case CalibrationStep.initial:
        return (Icons.play_circle_outline, Colors.blue);
      case CalibrationStep.positioning:
        return (Icons.person_outline, Colors.orange);
      case CalibrationStep.capturing:
        return (Icons.camera, Colors.green);
      case CalibrationStep.processing:
        return (Icons.hourglass_empty, Colors.purple);
      case CalibrationStep.complete:
        return (Icons.check_circle, Colors.green);
      case CalibrationStep.error:
        return (Icons.error_outline, Colors.red);
    }
  }

  String _getStepTitle() {
    switch (calibrationState.currentStep) {
      case CalibrationStep.initial:
        return 'Ready to Calibrate';
      case CalibrationStep.positioning:
        return 'Position Yourself';
      case CalibrationStep.capturing:
        return 'Capturing...';
      case CalibrationStep.processing:
        return 'Processing...';
      case CalibrationStep.complete:
        return 'Calibration Complete';
      case CalibrationStep.error:
        return 'Error';
    }
  }

  String _getStatusMessage() {
    if (calibrationState.statusMessage != null) {
      return calibrationState.statusMessage!;
    }

    switch (calibrationState.currentStep) {
      case CalibrationStep.initial:
        return 'Tap "Start Calibration" to begin';
      case CalibrationStep.positioning:
        return 'Stand in the frame with your full body visible';
      case CalibrationStep.capturing:
        return 'Hold still while we capture your measurements';
      case CalibrationStep.processing:
        return 'Analyzing measurement data...';
      case CalibrationStep.complete:
        return 'You\'re all set! Proceed to capture measurements.';
      case CalibrationStep.error:
        return 'Something went wrong. Please try again.';
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (calibrationState.currentStep) {
      case CalibrationStep.initial:
        return ElevatedButton.icon(
          onPressed: onStartCalibration,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Calibration'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 48),
          ),
        );
      case CalibrationStep.positioning:
      case CalibrationStep.capturing:
      case CalibrationStep.processing:
        return OutlinedButton.icon(
          onPressed: onResetCalibration,
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(200, 48),
          ),
        );
      case CalibrationStep.complete:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onResetCalibration,
              icon: const Icon(Icons.refresh),
              label: const Text('Recalibrate'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to capture screen
                // TODO: Implement navigation
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue'),
            ),
          ],
        );
      case CalibrationStep.error:
        return ElevatedButton.icon(
          onPressed: onResetCalibration,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 48),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        );
    }
  }
}
