# Smart Measurement Master Plan (v8 - Zero-Touch)

> **Goal:** Achieve 99.98% accuracy with a truly Zero-Touch pipeline. No camera frames leave the device; YOLOv8 Nano Pose + Homography math run fully on-device (Edge AI) to keep calibration confidential and instant.

## 1) Tech Stack
- **Framework:** Flutter SDK
- **AI Model:** YOLOv8 Nano Pose (TFLite) tuned for card-corner capture.
- **Math Engine:** `vector_math` + `image` powering Homography and raw image preprocessing.
- **State Management:** Riverpod + code generation for deterministic flows.
- **Guidance:** flutter_tts delivering reactive voice prompts so users never touch the screen.
- **Device Ops:** `permission_handler`, `path_provider` to keep everything local.

## 2) Core Logic
1.  **Smart Calibration**
    - Detect the reference card corners—even under heavy perspective—via YOLOv8 Nano Pose.
    - Apply **Homography/Perspective Correction** to flatten the card and establish geometry.
    - Compute `mm_per_pixel` from the canonical 85.60 mm card width for downstream measurements.
2.  **Body Tracking**
    - Extract and temporally smooth pose landmarks while rejecting invalid card shapes.
3.  **Data Policy**
    - Send only `Landmarks + Scale Factor`; no RGB data is uploaded, ensuring Zero-Touch privacy.
