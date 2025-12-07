import 'dart:async';
import 'package:flutter/material.dart';
enum CaptureState { waiting, holding, countingDown, capturing, completed }
class AutoCaptureManager {
  final int _countdownDuration;
  final Duration _stabilityHoldTime;
  int _currentCountdown;
  int _missedFrameCount = 0;
  Timer? _countdownTimer;
  Timer? _holdTimer;
  CaptureState _state = CaptureState.waiting;
  // Track consecutive detections before starting countdown
  int _consecutiveDetections = 0;
  static const int _requiredConsecutiveDetections = 3; // Need 3 good frames
  AutoCaptureManager({
    int countdownSeconds = 3,
    Duration stabilityHoldTime = const Duration(milliseconds: 300),
  })  : _countdownDuration = countdownSeconds,
        _stabilityHoldTime = stabilityHoldTime,
        _currentCountdown = countdownSeconds;
  CaptureState get state => _state;
  int get countdownValue => _currentCountdown;
  void Function(int seconds)? onCountdownTick;
  VoidCallback? onCapture;
  void Function(CaptureState state)? onStateChanged;
  /// Evaluates whether all capture preconditions are satisfied.
  void checkConditions({
    required bool isStable,
    required bool isCardDetected,
    required bool isGoodQuality,
  }) {
    if (_state == CaptureState.capturing || _state == CaptureState.completed) {
      return;
    }
    // Only require card detection - trust the model
    final cardOk = isCardDetected;
    if (cardOk) {
      _consecutiveDetections++;
      debugPrint('AutoCapture: Card detected ($_consecutiveDetections/$_requiredConsecutiveDetections)');
      if (_state == CaptureState.waiting) {
        if (_consecutiveDetections >= _requiredConsecutiveDetections) {
          debugPrint('AutoCapture: Starting countdown');
          _startHoldTimer();
        }
      }
    } else {
      // Lost detection - reset if we haven't started counting yet
      if (_state == CaptureState.waiting) {
        _consecutiveDetections = 0;
      }
      // During countdown, allow brief losses (don't reset immediately)
      if (_state == CaptureState.countingDown || _state == CaptureState.holding) {
        _missedFrameCount++;
        if (_missedFrameCount > 5) {
          _resetCountdown();
        }
        // Don't reset if within tolerance
      } else {
        _resetCountdown();
      }
    }
  }
  void _startHoldTimer() {
    _transitionTo(CaptureState.holding);
    _holdTimer?.cancel();
    _holdTimer = Timer(_stabilityHoldTime, () {
      if (_state == CaptureState.holding) {
        _startCountdown();
      }
    });
  }
  void _startCountdown() {
    _transitionTo(CaptureState.countingDown);
    _currentCountdown = _countdownDuration;
    _notifyTick();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentCountdown--;
      if (_currentCountdown > 0) {
        _notifyTick();
      } else {
        timer.cancel();
        _triggerCapture();
      }
    });
  }
  void _resetCountdown() {
    if (_state == CaptureState.waiting) {
      return;
    }
    _holdTimer?.cancel();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _currentCountdown = _countdownDuration;
    _transitionTo(CaptureState.waiting);
    _notifyTick();
  }
  void _triggerCapture() {
    _transitionTo(CaptureState.capturing);
    onCapture?.call();
    _transitionTo(CaptureState.completed);
  }
  void reset() {
    _holdTimer?.cancel();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _currentCountdown = _countdownDuration;
    _missedFrameCount = 0;
    _consecutiveDetections = 0;
    _transitionTo(CaptureState.waiting);
    _notifyTick();
  }
  void _notifyTick() {
    onCountdownTick?.call(_state == CaptureState.countingDown ? _currentCountdown : -1);
  }
  void _transitionTo(CaptureState next) {
    if (_state == next) return;
    _state = next;
    onStateChanged?.call(_state);
  }
  void dispose() {
    _holdTimer?.cancel();
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }
}
