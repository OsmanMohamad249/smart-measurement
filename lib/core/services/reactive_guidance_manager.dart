import 'package:flutter/foundation.dart';
import '../models/calibration_pose_state.dart';
import 'guidance_manager.dart';

/// Analyzes real-time calibration data to provide reactive voice guidance.
class ReactiveGuidanceManager {
  final GuidanceManager _guidanceManager;
  DateTime? _lastSpoken;
  CalibrationPoseState _lastState = CalibrationPoseState.ideal;

  // Debounce duration to prevent spamming the user.
  final Duration _debounceDuration = const Duration(seconds: 4);

  ReactiveGuidanceManager(this._guidanceManager);

  /// Analyzes the current calibration conditions and provides voice feedback if necessary.
  Future<void> analyzeAndGuide({
    required bool isStable,
    required bool isCardDetected,
    required double qualityScore,
    required double cardTilt,
    required double stabilityScore,
  }) async {
    final currentState = _determineState(
      isStable: isStable,
      isCardDetected: isCardDetected,
      qualityScore: qualityScore,
      cardTilt: cardTilt,
      stabilityScore: stabilityScore,
    );

    if (_shouldSpeak(currentState)) {
      _lastState = currentState;
      _lastSpoken = DateTime.now();
      await _speakForState(currentState);
    }
  }

  /// Determines the most critical [CalibrationPoseState] from the current data.
  CalibrationPoseState _determineState({
    required bool isStable,
    required bool isCardDetected,
    required double qualityScore,
    required double cardTilt,
    required double stabilityScore,
  }) {
    if (!isStable || stabilityScore < 0.7) return CalibrationPoseState.deviceMoving;
    if (!isCardDetected) return CalibrationPoseState.cardNotDetected;
    if (cardTilt > 15.0) return CalibrationPoseState.cardTilted;
    if (qualityScore < 0.85) return CalibrationPoseState.poorLighting;
    // Placeholder for tooClose/tooFar logic
    return CalibrationPoseState.ideal;
  }

  /// Decides whether to provide guidance based on state changes and debouncing.
  bool _shouldSpeak(CalibrationPoseState currentState) {
    // Don't speak if the state is ideal
    if (currentState == CalibrationPoseState.ideal) {
      return false;
    }

    // Always speak if the state has changed
    if (currentState != _lastState) {
      return true;
    }

    // If state hasn't changed, check debounce
    if (_lastSpoken != null) {
      final timeSinceLastSpoken = DateTime.now().difference(_lastSpoken!);
      if (timeSinceLastSpoken < _debounceDuration) {
        return false;
      }
    }

    return false;
  }

  /// Speaks the appropriate guidance message for the given state.
  Future<void> _speakForState(CalibrationPoseState state) async {
    String message;
    switch (state) {
      case CalibrationPoseState.deviceMoving:
        message = 'Please hold your device steady.';
        break;
      case CalibrationPoseState.cardNotDetected:
        message = 'Make sure the card is fully visible.';
        break;
      case CalibrationPoseState.cardTilted:
        message = 'Please hold the card straight.';
        break;
      case CalibrationPoseState.poorLighting:
        message = 'Find a brighter area for better accuracy.';
        break;
      case CalibrationPoseState.tooClose:
        message = 'Please take a step back.';
        break;
      case CalibrationPoseState.tooFar:
        message = 'Please take a step closer.';
        break;
      case CalibrationPoseState.ideal:
        // This message is unlikely to be spoken due to the logic in _shouldSpeak,
        // but it's good practice to have it.
        message = 'Hold steady, capturing now.';
        break;
    }
    debugPrint('ReactiveGuidance: $message');
    await _guidanceManager.speak(message);
  }

  void dispose() {
    // Clean up any resources if needed
  }
}
