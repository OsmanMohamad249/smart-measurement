# Smart Measurement Master Plan (v8 - Zero-Touch)

> **Goal:** Deliver full automation (Zero-Touch) with **99.98% measurement accuracy**. No images ever leave the device; all computer-vision runs on-device (Edge AI).

## 1) Tech Stack
- **Framework:** Flutter SDK
- **AI Model:** YOLOv8 Nano Pose (TFLite) trained for card-corner detection.
- **Math Engine:** `vector_math` + `image` for Homography-based perspective correction.
- **State Management:** Riverpod.
- **Guidance:** flutter_tts for reactive voice prompts.

## 2) Core Logic
1.  **Smart Calibration**
    - Detect tilted card corners.
    - Apply perspective correction to flatten the reference card.
    - Derive precise `mm_per_pixel`.
2.  **Body Tracking**
    - Extract pose landmarks and smooth temporally.
3.  **Payload**
    - Transmit only `Landmarks` JSON plus the scale factor to the server.
