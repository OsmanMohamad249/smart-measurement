# Technical Specification Document: Smart Tailor App

**Version:** 2.0 (Lightweight Client Architecture)  
**Date:** December 5, 2025  
**Status:** Final Draft for Implementation

---

## 1. Executive Summary

This project aims to build a smart application for taking body measurements for tailoring clothes with high accuracy, focusing on:
- **User Privacy:** No images sent to server
- **Lightweight App:** Removal of heavy libraries like OpenCV
- **Measurement Accuracy:** Integration of SMPL algorithms with bank card calibration

The new architecture is based on the **"Light Client, Heavy Server"** principle, where the phone only collects raw data, while the server handles complex computational and geometric operations.

---

## 2. System Architecture

### 2.1 Mobile App (Flutter Client) - "The Sensor"

| Property | Description |
|----------|-------------|
| **Responsibility** | Video capture, Metadata extraction, Voice guidance for user |
| **Characteristics** | No complex image processing, No OpenCV, Sends small text files (JSON) |

### 2.2 Backend Server (Python Backend) - "The Processor"

| Property | Description |
|----------|-------------|
| **Responsibility** | Data reception, Geometric perspective correction, 3D model building (3D Reconstruction), Measurement extraction in centimeters |
| **Technologies** | GPU Processing, SMPL-X, PyTorch |

---

## 3. Mobile App Technical Specifications

### 3.1 Tech Stack

| Component | Technology |
|-----------|------------|
| **Framework** | Flutter (Dart) |
| **Core Libraries** | |
| - Camera Control | `camera` |
| - Skeleton Extraction | `mediapipe_flutter` |
| - YOLOv8 Model Running | `onnxruntime` |

> ⚠️ **Note:** `opencv_dart` has been removed to reduce size and improve performance.

### 3.2 Processing Pipeline Inside the Phone

The app analyzes each frame as follows:

#### 3.2.1 Card Detection

- **Technology:** YOLOv8 Nano model (Int8 lightweight version)
- **Output:** Four corner coordinates of the card (x, y) only
- **Note:** Sent as-is without correction

#### 3.2.2 Body Analysis (Pose & Segmentation)

- **Technology:** MediaPipe Pose model
- **Output 1:** Skeleton points (33 Landmarks) to determine standing position
- **Output 2:** Segmentation Mask - Binary image separating body from background

#### 3.2.3 Silhouette Extraction - Image Alternative

Since we don't send images, we need to convert the "segmentation mask" into geometric data:

- **Algorithm (Dart):** Apply a simple tracking algorithm (like simplified Marching Squares) on the mask to extract outer points surrounding the body
- **Compression:** Reduce point count (Downsampling) (one point per 10-20 pixels) to produce a lightweight polygon representing body shape and fullness

---

## 4. Data Protocol (API Contract)

Data is collected from **4 shooting angles** (front, back, right, left) in a single JSON file sent to the server.

### Proposed JSON Structure:

```json
{
  "session_id": "scan_unique_id_123",
  "device_info": "iPhone 13 Pro",
  "user_input_height_cm": 172.5,
  "captures": [
    {
      "view_angle": "FRONT",
      "timestamp": 1678900123,
      "pose_landmarks": [
        {"id": 0, "x": 0.51, "y": 0.12, "z": -0.05, "visibility": 0.99}
      ],
      "body_silhouette_polygon": [
        {"x": 0.45, "y": 0.10},
        {"x": 0.46, "y": 0.12}
      ],
      "reference_object": {
        "type": "CARD_ID_1",
        "detected": true,
        "corners": [
          {"x": 210, "y": 500}, 
          {"x": 410, "y": 515}, 
          {"x": 405, "y": 400}, 
          {"x": 205, "y": 385}
        ]
      }
    }
  ]
}
```

---

## 5. Backend Technical Specifications

### 5.1 Tech Stack

| Component | Technology |
|-----------|------------|
| **Language** | Python 3.9+ |
| **Framework** | FastAPI (for high speed) |
| **Processing Libraries** | OpenCV (for geometric operations), PyTorch (for AI), Trimesh (for 3D geometry) |
| **Core Models** | SMPL-X / SHAPY / ViTPose (optional for maximum accuracy) |

### 5.2 Core Processing Algorithm

#### 5.2.1 Geometric Calibration

1. Receive card `corners` from JSON
2. Apply `cv2.getPerspectiveTransform` to calculate scale (Pixels per CM) accurately

#### 5.2.2 Mask Reconstruction

- Draw `body_silhouette_polygon` on black background to restore "body shape" (Binary Mask) that the model sees

#### 5.2.3 Model Optimization

- Use **SMPLify-X Multiview** algorithm
- **Goal:** Find a single 3D mesh that satisfies two conditions:
  1. Its joints match `pose_landmarks`
  2. Its shadow (Projected Silhouette) matches the reconstructed mask (to ensure weight and fullness accuracy)

#### 5.2.4 Virtual Measuring

1. Mesh slicing at specific anatomical points (waist, chest, hips)
2. Calculate perimeter using **Trimesh** library and multiply result by calibration factor extracted from card

---

## 6. User Experience Flow

### 6.1 Setup
The app asks the user to prepare a standard-sized card and wear tight clothes.

### 6.2 Interactive Guidance
- The app uses **TTS (Text-to-Speech)** to guide the user
- Examples: "Step back a little", "Card not visible", "Stay still"
- Once conditions are met (full body visible + card visible), **the app automatically captures data** without pressing a button

### 6.3 Rotation
The app asks the user to rotate right, then back, then left.

### 6.4 Submission
A simple loading screen appears (data size is very small < 50KB).

### 6.5 Result
Display final measurements with the ability to manually edit them if needed.

---

## 7. Implementation Roadmap

### 🔷 Phase 1: Proof of Concept (POC)

| Task | Description |
|------|-------------|
| ✅ Flutter App | Build a simple app that collects MediaPipe points and sends them |
| ✅ Python Script | Build a simple script that receives points and applies them to a ready SMPL model |
| **Goal** | Ensure data flow |

### 🔷 Phase 2: Measurement Accuracy

| Task | Description |
|------|-------------|
| 🔄 YOLOv8 Nano Integration | In the app |
| 🔄 Silhouette Extraction | Apply Silhouette extraction logic |
| 🔄 Calibration Algorithm | Develop calibration algorithm on server |

### 🔷 Phase 3: Production

| Task | Description |
|------|-------------|
| ⏳ UX Improvement | Improve voice guidance |
| ⏳ Security | Secure connection (API Security) |
| ⏳ Deployment | Deploy app and server |

---

## 📝 Additional Notes

- All images stay on device and are never sent to server
- Only JSON data is sent (< 50KB)
- System supports 4 shooting angles for maximum accuracy
- Calibration is done using a standard bank card (85.6mm × 53.98mm)

