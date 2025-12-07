import 'package:flutter_test/flutter_test.dart';
import 'package:smart_measurement/core/services/auto_capture_manager.dart';

void main() {
  late AutoCaptureManager autoCaptureManager;

  setUp(() {
    autoCaptureManager = AutoCaptureManager(
      countdownSeconds: 3,
      stabilityHoldTime: const Duration(milliseconds: 500),
    );
  });

  group('AutoCaptureManager', () {
    test('Initial state is waiting', () {
      expect(autoCaptureManager.state, equals(CaptureState.waiting));
    });

    test('Transitions to holding when conditions are met', () {
      autoCaptureManager.checkConditions(
        isStable: true,
        isCardDetected: true,
        isGoodQuality: true,
      );
      expect(autoCaptureManager.state, equals(CaptureState.holding));
    });

    test('Starts countdown after holding period', () async {
      autoCaptureManager.checkConditions(
        isStable: true,
        isCardDetected: true,
        isGoodQuality: true,
      );

      await Future.delayed(const Duration(milliseconds: 550));

      expect(autoCaptureManager.state, equals(CaptureState.countingDown));
    });

    test('Resets if conditions fail during holding', () async {
      autoCaptureManager.checkConditions(
        isStable: true,
        isCardDetected: true,
        isGoodQuality: true,
      );
      expect(autoCaptureManager.state, equals(CaptureState.holding));

      autoCaptureManager.checkConditions(
        isStable: false,
        isCardDetected: true,
        isGoodQuality: true,
      );
      expect(autoCaptureManager.state, equals(CaptureState.waiting));
    });

    test('onCountdownTick callback is fired correctly', () async {
      final List<int> ticks = [];
      autoCaptureManager.onCountdownTick = (tick) => ticks.add(tick);

      autoCaptureManager.checkConditions(
        isStable: true,
        isCardDetected: true,
        isGoodQuality: true,
      );

      await Future.delayed(const Duration(seconds: 4));

      expect(ticks, orderedEquals([3, 2, 1]));
    });

    test('onCapture callback is fired and state transitions to completed', () async {
      bool captured = false;
      autoCaptureManager.onCapture = () => captured = true;

      final states = <CaptureState>[];
      autoCaptureManager.onStateChanged = (state) => states.add(state);

      autoCaptureManager.checkConditions(
        isStable: true,
        isCardDetected: true,
        isGoodQuality: true,
      );

      await Future.delayed(const Duration(seconds: 4));

      expect(captured, isTrue);
      expect(states, containsAllInOrder([
        CaptureState.holding,
        CaptureState.countingDown,
        CaptureState.capturing,
        CaptureState.completed,
      ]));
    });

    test('reset() method resets the state correctly', () async {
      autoCaptureManager.checkConditions(
        isStable: true,
        isCardDetected: true,
        isGoodQuality: true,
      );

      autoCaptureManager.reset();

      expect(autoCaptureManager.state, equals(CaptureState.waiting));
    });
  });
}
