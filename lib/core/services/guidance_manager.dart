import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for managing text-to-speech guidance feedback.
///
/// This class provides audio guidance for users during the
/// body measurement process, helping them position correctly
/// for accurate measurements.
class GuidanceManager {
  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  // TTS configuration
  double _volume = 1.0;
  double _pitch = 1.0;
  double _speechRate = 0.5;
  String _language = 'en-US';

  /// Returns true if the guidance manager is initialized.
  bool get isInitialized => _isInitialized;

  /// Returns true if currently speaking.
  bool get isSpeaking => _isSpeaking;

  /// Initializes the text-to-speech engine.
  Future<void> initialize() async {
    try {
      _flutterTts = FlutterTts();

      await _flutterTts!.setVolume(_volume);
      await _flutterTts!.setPitch(_pitch);
      await _flutterTts!.setSpeechRate(_speechRate);
      await _flutterTts!.setLanguage(_language);

      _flutterTts!.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts!.setErrorHandler((message) {
        debugPrint('TTS Error: $message');
        _isSpeaking = false;
      });

      _isInitialized = true;
      debugPrint('GuidanceManager initialized');
    } catch (e) {
      debugPrint('GuidanceManager initialization error: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Speaks the given text.
  ///
  /// [text] is the message to speak.
  /// [interrupt] if true, stops any current speech before speaking.
  Future<void> speak(String text, {bool interrupt = true}) async {
    if (!_isInitialized || _flutterTts == null) {
      debugPrint('GuidanceManager not initialized');
      return;
    }

    if (interrupt && _isSpeaking) {
      await stop();
    }

    await _flutterTts!.speak(text);
  }

  /// Stops any current speech.
  Future<void> stop() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
      _isSpeaking = false;
    }
  }

  /// Sets the speech volume.
  ///
  /// [volume] should be between 0.0 and 1.0.
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_flutterTts != null) {
      await _flutterTts!.setVolume(_volume);
    }
  }

  /// Sets the speech pitch.
  ///
  /// [pitch] should be between 0.5 and 2.0.
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    if (_flutterTts != null) {
      await _flutterTts!.setPitch(_pitch);
    }
  }

  /// Sets the speech rate.
  ///
  /// [rate] should be between 0.0 and 1.0.
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    if (_flutterTts != null) {
      await _flutterTts!.setSpeechRate(_speechRate);
    }
  }

  /// Sets the speech language.
  Future<void> setLanguage(String language) async {
    _language = language;
    if (_flutterTts != null) {
      await _flutterTts!.setLanguage(_language);
    }
  }

  /// Provides calibration start guidance.
  Future<void> speakCalibrationStart() async {
    await speak(
      'Welcome to Smart Measurement. '
      'Please stand in front of the camera with your full body visible. '
      'Make sure you have good lighting.',
    );
  }

  /// Provides positioning guidance.
  Future<void> speakPositioningGuidance(PositionFeedback feedback) async {
    switch (feedback) {
      case PositionFeedback.tooClose:
        await speak('Please step back. You are too close to the camera.');
        break;
      case PositionFeedback.tooFar:
        await speak('Please step closer. You are too far from the camera.');
        break;
      case PositionFeedback.moveLeft:
        await speak('Please move to your left.');
        break;
      case PositionFeedback.moveRight:
        await speak('Please move to your right.');
        break;
      case PositionFeedback.turnFront:
        await speak('Please face the camera directly.');
        break;
      case PositionFeedback.raiseArms:
        await speak('Please raise your arms slightly away from your body.');
        break;
      case PositionFeedback.lowerArms:
        await speak('Please lower your arms.');
        break;
      case PositionFeedback.standStraight:
        await speak('Please stand up straight.');
        break;
      case PositionFeedback.perfect:
        await speak('Perfect! Hold this position.');
        break;
      case PositionFeedback.capturing:
        await speak('Capturing measurement. Please hold still.');
        break;
      case PositionFeedback.complete:
        await speak('Measurement complete. Processing results.');
        break;
    }
  }

  /// Provides error feedback.
  Future<void> speakError(String errorMessage) async {
    await speak('Error: $errorMessage');
  }

  /// Disposes of the TTS resources.
  Future<void> dispose() async {
    await stop();
    _flutterTts = null;
    _isInitialized = false;
  }
}

/// Position feedback types for guidance.
enum PositionFeedback {
  tooClose,
  tooFar,
  moveLeft,
  moveRight,
  turnFront,
  raiseArms,
  lowerArms,
  standStraight,
  perfect,
  capturing,
  complete,
}
