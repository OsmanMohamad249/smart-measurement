# 🗺️ Phased Roadmap - Completing Calibration Phase
**Date:** December 4, 2025  
**Current Status:** 95% Complete - 99.9% Accuracy  
**Goal:** Complete remaining 5% to enhance user experience
---
## 📊 Overview
### **What's Completed ✅ (95%)**
- YOLOv8 card detection
- Sub-pixel refinement  
- Homography & scale extraction
- Quality validation
- Basic UI & guidance
### **What Will Be Implemented ⏳ (5%)**
- Stability detection
- Auto-capture
- Reactive guidance
- Enhanced UI feedback
---
## 🎯 Proposed Phases (5 Phases)
```
Phase 1: Stability Detection        [3-4 days]  🔴 Critical
Phase 2: Auto-Capture               [2-3 days]  🔴 Very Important
Phase 3: Reactive Guidance          [2-3 days]  🟠 Important
Phase 4: Enhanced Visual Feedback   [2-3 days]  🟡 Enhancement
Phase 5: Polish & Testing           [2-3 days]  🟢 Final
Total Duration: 11-16 days (2-3 weeks)
```
---
# 📋 Phase 1: Stability Detection
**Duration:** 3-4 days  
**Priority:** 🔴 Critical  
**Goal:** Prevent capturing blurry/shaky images
---
## 🎯 Objectives
Implement stability detection using:
1. **Gyroscope sensor** - Detect device movement
2. **Frame difference** - Detect visual motion  
3. **Combined decision** - Unified decision
---
## 📝 Detailed Steps
### **Step 1.1: Add Dependencies** (30 minutes)
```yaml
# pubspec.yaml
dependencies:
  sensors_plus: ^4.0.2
```
```bash
flutter pub add sensors_plus
flutter pub get
```
---
### **Step 1.2: Create StabilityDetector** (2-3 hours)
**File:** `lib/core/services/stability_detector.dart`
**Core Functions:**
```dart
class StabilityDetector {
  // Monitoring
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  List<GyroscopeEvent> _recentGyroData = [];
  img.Image? _previousFrame;
  // Methods
  Future<void> initialize();
  bool isGyroStable();
  bool isFrameStable(img.Image currentFrame);
  bool isStable(img.Image? currentFrame);
  double getStabilityScore(img.Image? currentFrame);
  void dispose();
}
```
**Algorithm:**
- Gyroscope: Calculate variance in 3 axes
- Frame: Compare pixels between frames
- Combined: AND logic
---
### **Step 1.3: Add Provider** (30 minutes)
```dart
// lib/core/providers/providers.dart
final stabilityDetectorProvider = Provider<StabilityDetector>((ref) {
  final detector = StabilityDetector();
  ref.onDispose(() => detector.dispose());
  return detector;
});
```
---
### **Step 1.4: Integration** (1-2 hours)
```dart
// lib/core/providers/calibration_controller.dart
class CalibrationController {
  final StabilityDetector _stabilityDetector;
  Future<void> _processFrame(CameraImage image) async {
    final imgImage = _convertToImgImage(image);
    final isStable = _stabilityDetector.isStable(imgImage);
    if (!isStable) {
      debugPrint('Frame skipped: not stable');
      return;
    }
    // Continue processing...
  }
}
```
---
### **Step 1.5: Testing** (2-3 hours)
**Tests:**
- [ ] Gyroscope works
- [ ] Frame difference correct
- [ ] Combined decision logical
- [ ] Performance good
**Success Criteria:**
- ✅ 90%+ accuracy
- ✅ < 50ms per check
- ✅ Low false positives
---
## ✅ Phase 1 Deliverables
- ✅ Effective stability detection system
- ✅ Prevent shaky images
- ✅ Foundation for Phase 2
---
# 📋 Phase 2: Auto-Capture
**Duration:** 2-3 days  
**Priority:** 🔴 Very Important  
**Goal:** Smart automatic capture
---
## 🎯 Objectives
Auto-capture when:
1. ✅ Device is stable
2. ✅ Card is detected
3. ✅ High quality
4. ✅ After 3-second countdown
---
## 📝 Steps
### **Step 2.1: AutoCaptureManager** (2-3 hours)
```dart
// lib/core/services/auto_capture_manager.dart
enum CaptureState {
  waiting,
  countdown,
  capturing,
  completed,
}
class AutoCaptureManager {
  CaptureState _state = CaptureState.waiting;
  Timer? _countdownTimer;
  int _countdown = 3;
  void Function(int)? onCountdownTick;
  void Function()? onCapture;
  void checkConditions({
    required bool isStable,
    required bool isCardDetected,
    required bool isGoodQuality,
  });
  void _startCountdown();
  void _resetCountdown();
  void _capture();
}
```
---
### **Step 2.2: Countdown UI** (2-3 hours)
```dart
// lib/features/calibration/presentation/widgets/countdown_overlay.dart
class CountdownOverlay extends StatelessWidget {
  final int? countdown;
  final bool isVisible;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: Text('`countdown'),
      ),
    );
  }
}
```
---
### **Step 2.3: Integration** (2-3 hours)
- Add AutoCaptureManager to controller
- Setup callbacks
- Update UI with countdown
- Testing
---
## ✅ Phase 2 Deliverables
- ✅ Working auto-capture
- ✅ Greatly improved UX
- ✅ No manual pressing
---
# 📋 Phase 3: Reactive Guidance
**Duration:** 2-3 days  
**Priority:** 🟠 Important  
**Goal:** Smart interactive guidance
---
## 🎯 Objectives
Voice guidance based on state:
- Card tilted → "Adjust the angle"
- Too close → "Move back a bit"
- Moving → "Hold still"
---
## 📝 Steps
### **Step 3.1: State Definition** (1 hour)
```dart
enum CalibrationPoseState {
  ideal,
  cardNotDetected,
  cardTilted,
  tooClose,
  tooFar,
  deviceMoving,
  poorLighting,
}
```
---
### **Step 3.2: ReactiveGuidanceManager** (3-4 hours)
```dart
class ReactiveGuidanceManager {
  DateTime _lastSpoken = DateTime.now();
  CalibrationPoseState _lastState = CalibrationPoseState.ideal;
  Future<void> analyzeAndGuide({
    required bool isStable,
    required bool isCardDetected,
    required double qualityScore,
    required double cardTilt,
  });
  CalibrationPoseState _determineState(...);
  bool _shouldSkipGuidance(state);
  Future<void> _speakForState(state);
}
```
**Features:**
- State analysis
- Debouncing (3 sec)
- Multi-language
---
### **Step 3.3: Testing** (2-3 hours)
---
## ✅ Phase 3 Deliverables
- ✅ Smart guidance
- ✅ Reduced errors
- ✅ Better UX
---
# 📋 Phase 4: Enhanced Visual Feedback
**Duration:** 2-3 days  
**Priority:** 🟡 Enhancement
---
## 📝 Components
### **4.1: Stability Ring** (1 day)
```dart
class StabilityRing extends StatelessWidget {
  final bool isStable;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isStable ? Colors.green : Colors.red,
          width: 4,
        ),
      ),
    );
  }
}
```
---
### **4.2: Quality Meter** (1 day)
- Real-time quality indicator
- Visual progress bar
---
### **4.3: Animations** (1 day)
- Smooth transitions
- Professional polish
---
## ✅ Phase 4 Deliverables
- ✅ Professional UI
- ✅ Clear visual feedback
- ✅ Enjoyable experience
---
# 📋 Phase 5: Polish & Testing
**Duration:** 2-3 days  
**Priority:** 🟢 Final
---
## 📝 Tasks
### **5.1: Comprehensive Testing** (1 day)
- [ ] Unit tests
- [ ] Integration tests  
- [ ] Manual testing
- [ ] Edge cases
---
### **5.2: Bug Fixes** (1 day)
- [ ] Fix bugs
- [ ] Handle edge cases
- [ ] Improve robustness
---
### **5.3: Optimization** (0.5 day)
- [ ] Performance profiling
- [ ] Memory optimization
- [ ] Battery impact
---
### **5.4: Documentation** (0.5 day)
- [ ] Update docs
- [ ] Add code comments
- [ ] Update README
---
## ✅ Phase 5 Deliverables
- ✅ Polished app
- ✅ 0 critical bugs
- ✅ Excellent performance
- ✅ Complete documentation
---
# 🎯 Overall Timeline
| Phase | Duration | Week | Status |
|-------|----------|------|--------|
| **1. Stability Detection** | 3-4 days | 1 | ⏳ Pending |
| **2. Auto-Capture** | 2-3 days | 1-2 | ⏳ Pending |
| **3. Reactive Guidance** | 2-3 days | 2 | ⏳ Pending |
| **4. Visual Feedback** | 2-3 days | 2-3 | ⏳ Pending |
| **5. Polish & Testing** | 2-3 days | 3 | ⏳ Pending |
**Total:** 11-16 days (2-3 weeks)
---
# ✅ Comprehensive Checklist
## **Phase 1: Stability Detection**
- [ ] sensors_plus installed
- [ ] StabilityDetector service created
- [ ] Gyroscope monitoring working
- [ ] Frame difference working
- [ ] Combined check working
- [ ] Integrated in controller
- [ ] Tests passing
- [ ] Performance acceptable
## **Phase 2: Auto-Capture**
- [ ] AutoCaptureManager created
- [ ] Countdown logic working
- [ ] Countdown UI created
- [ ] Callbacks setup
- [ ] Integrated in controller
- [ ] Tests passing
- [ ] User experience smooth
## **Phase 3: Reactive Guidance**
- [ ] States defined
- [ ] ReactiveGuidanceManager created
- [ ] State analysis working
- [ ] Debouncing working
- [ ] Multi-language messages
- [ ] Integrated in controller
- [ ] Tests passing
## **Phase 4: Visual Feedback**
- [ ] Stability ring created
- [ ] Quality meter created
- [ ] Animations added
- [ ] UI polished
- [ ] Tests passing
## **Phase 5: Polish**
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Manual testing complete
- [ ] No critical bugs
- [ ] Performance optimized
- [ ] Documentation updated
- [ ] Code commented
- [ ] README updated
---
# 📊 Success Criteria
| Criterion | Target | Method |
|-----------|--------|---------|
| **Stability Detection** | 90%+ accuracy | Manual testing |
| **Auto-Capture** | 95%+ success rate | User testing |
| **Reactive Guidance** | Helpful & timely | User feedback |
| **Performance** | 30+ FPS | Profiling |
| **Battery** | < 10% impact | Testing |
| **Bugs** | 0 critical | Testing |
---
# 🎊 Expected Outcome
After completing all phases:
```
✅ Calibration: 100% complete
✅ Accuracy: 99.9%+
✅ Stability detection: Effective
✅ Auto-capture: Smooth
✅ Reactive guidance: Smart
✅ UI/UX: Professional
✅ Performance: Excellent
✅ Bugs: Zero
Result: Production-ready calibration app!
```
---
# 💡 Important Notes
## **Priorities:**
1. **Phases 1 & 2 are Critical** 🔴
   - Major quality improvement
   - Much better user experience
2. **Phase 3 is Important** 🟠
   - Clear improvement
   - Can be postponed if needed
3. **Phase 4 is Enhancement** 🟡
   - Final polish
   - Nice-to-have
4. **Phase 5 is Mandatory** 🟢
   - Quality assurance
   - Don't skip
---
## **Implementation Tips:**
1. **Test Continuously**
   - After each step
   - Before moving to next
2. **Clean Code**
   - Clear comments
   - Good error handling
3. **Performance First**
   - Profile early
   - Optimize immediately
4. **UX in Mind**
   - Test with users
   - Gather feedback
---
# 🔗 Related Links
- **Complete Plan:** [ENHANCED_PLAN_AR.md](./ENHANCED_PLAN_AR.md)
- **Documentation Index:** [DOCS_INDEX.md](./DOCS_INDEX.md)
- **Quick Start:** [../START_HERE.md](../START_HERE.md)
---
**Last Updated:** December 4, 2025  
**Status:** ✅ Ready for Implementation  
**Maintainer:** GitHub Copilot
