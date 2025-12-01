import 'package:flutter_test/flutter_test.dart';
import 'package:smart_measurement/core/services/guidance_manager.dart';

void main() {
  group('GuidanceManager', () {
    late GuidanceManager guidanceManager;

    setUp(() {
      guidanceManager = GuidanceManager();
    });

    tearDown(() async {
      await guidanceManager.dispose();
    });

    test('initial state should not be initialized', () {
      expect(guidanceManager.isInitialized, false);
      expect(guidanceManager.isSpeaking, false);
    });
  });

  group('PositionFeedback', () {
    test('should have all position feedback types', () {
      expect(PositionFeedback.values.length, 11);
      expect(PositionFeedback.values, contains(PositionFeedback.tooClose));
      expect(PositionFeedback.values, contains(PositionFeedback.tooFar));
      expect(PositionFeedback.values, contains(PositionFeedback.moveLeft));
      expect(PositionFeedback.values, contains(PositionFeedback.moveRight));
      expect(PositionFeedback.values, contains(PositionFeedback.turnFront));
      expect(PositionFeedback.values, contains(PositionFeedback.raiseArms));
      expect(PositionFeedback.values, contains(PositionFeedback.lowerArms));
      expect(PositionFeedback.values, contains(PositionFeedback.standStraight));
      expect(PositionFeedback.values, contains(PositionFeedback.perfect));
      expect(PositionFeedback.values, contains(PositionFeedback.capturing));
      expect(PositionFeedback.values, contains(PositionFeedback.complete));
    });
  });
}
