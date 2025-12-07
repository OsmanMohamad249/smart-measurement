import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smart_measurement/core/services/guidance_manager.dart';
import 'package:smart_measurement/core/services/reactive_guidance_manager.dart';

import 'reactive_guidance_manager_test.mocks.dart';

@GenerateMocks([GuidanceManager])
void main() {
  late ReactiveGuidanceManager guidanceManager;
  late MockGuidanceManager mockGuidanceManager;

  setUp(() {
    mockGuidanceManager = MockGuidanceManager();
    when(mockGuidanceManager.speak(any)).thenAnswer((_) async {});
    guidanceManager = ReactiveGuidanceManager(mockGuidanceManager);
  });

  group('ReactiveGuidanceManager', () {
    test('should not provide guidance when state is ideal', () async {
      await guidanceManager.analyzeAndGuide(
        isStable: true,
        isCardDetected: true,
        qualityScore: 0.95,
        cardTilt: 5,
        stabilityScore: 0.95,
      );

      verifyNever(mockGuidanceManager.speak(any));
    });

    test('should provide guidance for unstable device', () async {
      await guidanceManager.analyzeAndGuide(
        isStable: false,
        isCardDetected: true,
        qualityScore: 0.95,
        cardTilt: 5,
        stabilityScore: 0.6,
      );

      verify(mockGuidanceManager.speak(any)).called(1);
    });

    test('should provide guidance for tilted card', () async {
      await guidanceManager.analyzeAndGuide(
        isStable: true,
        isCardDetected: true,
        qualityScore: 0.95,
        cardTilt: 20,
        stabilityScore: 0.95,
      );

      verify(mockGuidanceManager.speak(any)).called(1);
    });

    test('should not spam guidance due to debouncing', () async {
      // First call - should trigger guidance
      await guidanceManager.analyzeAndGuide(
        isStable: false,
        isCardDetected: true,
        qualityScore: 0.9,
        cardTilt: 5,
        stabilityScore: 0.6,
      );
      verify(mockGuidanceManager.speak(any)).called(1);
      clearInteractions(mockGuidanceManager);

      // Second immediate call - should NOT trigger guidance due to debouncing
      await guidanceManager.analyzeAndGuide(
        isStable: false,
        isCardDetected: true,
        qualityScore: 0.9,
        cardTilt: 5,
        stabilityScore: 0.6,
      );

      // Should NOT have been called again
      verifyNever(mockGuidanceManager.speak(any));
    });

    test('should not provide guidance if state does not change after debounce', () async {
      // First call - should trigger guidance
      await guidanceManager.analyzeAndGuide(
        isStable: false,
        isCardDetected: true,
        qualityScore: 0.9,
        cardTilt: 5,
        stabilityScore: 0.6,
      );
      verify(mockGuidanceManager.speak(any)).called(1);
      clearInteractions(mockGuidanceManager);

      // Wait for debounce period to pass
      await Future.delayed(const Duration(seconds: 5));

      // Second call with the same state - should NOT trigger guidance
      await guidanceManager.analyzeAndGuide(
        isStable: false,
        isCardDetected: true,
        qualityScore: 0.9,
        cardTilt: 5,
        stabilityScore: 0.6,
      );

      // Should NOT have been called again because state hasn't changed
      verifyNever(mockGuidanceManager.speak(any));
    });
  });
}
