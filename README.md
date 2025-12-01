# Smart Measurement

A precise AI-powered body measurement app using Flutter & Edge AI.

## Features

- **Smart Calibration**: Calibrate the system for accurate measurements with visual guidance
- **Body Capture**: Capture body images from multiple angles
- **Results Display**: View detailed body measurements

## Architecture

This app follows Clean Architecture principles with Riverpod for state management.

### Project Structure

```
lib/
├── main.dart
├── core/
│   ├── services/
│   │   ├── camera_service.dart      # Camera operations
│   │   ├── tflite_service.dart      # YOLOv8 model inference
│   │   └── guidance_manager.dart    # Text-to-speech feedback
│   └── providers/
│       └── providers.dart           # Riverpod providers
└── features/
    ├── calibration/
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   └── smart_calibration_screen.dart
    │   │   └── widgets/
    │   │       ├── polygon_overlay.dart
    │   │       └── calibration_guide.dart
    │   ├── domain/
    │   └── data/
    ├── capture/
    │   ├── presentation/
    │   │   └── screens/
    │   │       └── capture_screen.dart
    │   ├── domain/
    │   └── data/
    └── results/
        ├── presentation/
        │   └── screens/
        │       └── results_screen.dart
        ├── domain/
        └── data/
```

## Core Services

### CameraService
Manages camera initialization, preview streaming, and image capture for body measurement.

### TFLiteService
Handles YOLOv8 pose estimation model loading and inference for detecting body keypoints.

### GuidanceManager
Provides text-to-speech audio feedback to guide users during the measurement process.

## Dependencies

- `flutter_riverpod`: State management
- `camera`: Camera access and preview
- `flutter_tts`: Text-to-speech for guidance
- `tflite_flutter`: TensorFlow Lite inference
- `permission_handler`: Permission management
- `path_provider`: File system access

## Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Add YOLOv8 pose model to `assets/yolov8_pose.tflite`
4. Run `flutter run`

## Requirements

- Flutter SDK >= 3.0.0
- Android SDK >= 21
- iOS >= 11.0
