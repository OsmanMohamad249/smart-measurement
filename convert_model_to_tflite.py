"""
Script to convert YOLOv8 ONNX model to TFLite format
This script helps resolve ONNX Runtime initialization issues on Android
"""

import sys
import os
from pathlib import Path

def check_dependencies():
    """Check if required packages are installed"""
    try:
        import ultralytics
        print("✓ ultralytics installed")
        return True
    except ImportError:
        print("✗ ultralytics not installed")
        print("Install it using: pip install ultralytics")
        return False

def convert_model(model_path, output_dir):
    """Convert ONNX/PT model to TFLite"""
    from ultralytics import YOLO

    print(f"\nConverting model: {model_path}")
    print(f"Output directory: {output_dir}")

    # Load the model
    if model_path.endswith('.onnx'):
        print("\nNote: You need the original .pt file to export to TFLite")
        print("ONNX models cannot be directly converted to TFLite")
        print("Please use the original best.pt file")
        return None

    model = YOLO(model_path)

    # Export to TFLite
    print("\nExporting to TFLite...")
    export_path = model.export(
        format='tflite',
        imgsz=640,
        int8=False,  # Use float32 for better accuracy
    )

    print(f"\n✓ Model exported successfully!")
    print(f"TFLite model location: {export_path}")

    return export_path

def copy_to_flutter_assets(tflite_path, flutter_project_path):
    """Copy TFLite model to Flutter assets folder"""
    import shutil

    assets_dir = Path(flutter_project_path) / 'assets' / 'models'
    assets_dir.mkdir(parents=True, exist_ok=True)

    dest_path = assets_dir / 'best.tflite'

    print(f"\nCopying model to Flutter assets...")
    print(f"Source: {tflite_path}")
    print(f"Destination: {dest_path}")

    shutil.copy2(tflite_path, dest_path)

    print(f"\n✓ Model copied successfully!")
    return dest_path

def main():
    print("=" * 60)
    print("YOLOv8 Model Converter: ONNX/PT → TFLite")
    print("=" * 60)

    # Check dependencies
    if not check_dependencies():
        return 1

    # Paths
    yolo_project = Path(r"C:\Users\HP\PycharmProjects\card-detection-yolo")
    flutter_project = Path(r"C:\Users\HP\PycharmProjects\smart-measurement")

    # Look for the model file
    possible_paths = [
        yolo_project / "best.pt",
        yolo_project / "runs" / "detect" / "train" / "weights" / "best.pt",
        yolo_project / "flutter_app" / "assets" / "models" / "best.pt",
    ]

    model_path = None
    for path in possible_paths:
        if path.exists():
            model_path = path
            print(f"\n✓ Found model at: {model_path}")
            break

    if not model_path:
        print("\n✗ Could not find best.pt file")
        print("Searched in:")
        for path in possible_paths:
            print(f"  - {path}")
        print("\nPlease provide the path to your best.pt file:")
        user_input = input("> ").strip()
        if user_input:
            model_path = Path(user_input)
            if not model_path.exists():
                print(f"✗ File not found: {model_path}")
                return 1
        else:
            return 1

    try:
        # Convert model
        tflite_path = convert_model(str(model_path), str(yolo_project))

        if tflite_path:
            # Copy to Flutter assets
            dest_path = copy_to_flutter_assets(tflite_path, flutter_project)

            print("\n" + "=" * 60)
            print("SUCCESS!")
            print("=" * 60)
            print(f"\nTFLite model is ready at:")
            print(f"  {dest_path}")
            print("\nNext steps:")
            print("1. Update pubspec.yaml to include best.tflite in assets")
            print("2. Switch from OnnxInferenceService to TFLiteService")
            print("3. Run 'flutter pub get' and rebuild the app")

            return 0
        else:
            return 1

    except Exception as e:
        print(f"\n✗ Error during conversion: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())

