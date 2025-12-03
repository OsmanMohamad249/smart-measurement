"""
YOLO ONNX to TFLite Converter - Clean Implementation
This script properly converts YOLO ONNX models to TFLite format.

Tested with:
- Python 3.8+
- TensorFlow 2.13.0 (stable with Python 3.8-3.11)
- ONNX 1.14.0
- ultralytics (for proper YOLO conversion)

Author: Smart Measurement Team
Date: 2025-12-03
"""

import sys
import os
from pathlib import Path
import subprocess


def check_python_version():
    """Check if Python version is compatible."""
    version = sys.version_info
    print(f"Python version: {version.major}.{version.minor}.{version.micro}")

    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print("❌ Python 3.8+ required!")
        return False

    if version.major == 3 and version.minor > 11:
        print("⚠️  Warning: TensorFlow 2.13 best supports Python 3.8-3.11")

    return True


def install_dependencies():
    """Install compatible versions of required packages."""
    print("\n" + "="*70)
    print("Installing Compatible Dependencies")
    print("="*70)

    # Tested and compatible versions
    packages = [
        'tensorflow==2.13.0',  # Stable, works with Python 3.8-3.11
        'onnx==1.14.0',        # Compatible with TF 2.13
        'tf2onnx==1.15.1',     # For ONNX operations
        'numpy<2.0',           # TF 2.13 requires numpy < 2.0
        'protobuf>=3.20.3,<5.0.0',  # Compatible protobuf
        'ultralytics',         # Official YOLO toolkit
    ]

    print("\n📦 Installing packages:")
    for pkg in packages:
        print(f"   • {pkg}")

    print("\nThis may take a few minutes...\n")

    try:
        subprocess.check_call([
            sys.executable, '-m', 'pip', 'install', '--upgrade', 'pip'
        ])

        subprocess.check_call([
            sys.executable, '-m', 'pip', 'install', '--upgrade', *packages
        ])

        print("\n✅ All dependencies installed successfully!")
        return True

    except subprocess.CalledProcessError as e:
        print(f"\n❌ Failed to install dependencies: {e}")
        return False


def convert_onnx_to_tflite_ultralytics(onnx_path, output_dir):
    """
    Convert YOLO ONNX to TFLite using Ultralytics.
    This is the recommended approach for YOLO models.
    """
    try:
        from ultralytics import YOLO

        print("\n" + "="*70)
        print("Method 1: Ultralytics YOLO Export (Recommended)")
        print("="*70)

        # Load ONNX model
        print(f"\n📂 Loading ONNX model: {onnx_path}")
        model = YOLO(onnx_path, task='detect')

        # Export to TFLite
        print("\n🔄 Converting to TFLite...")
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

        # Export with INT8 quantization for smaller size
        model.export(
            format='tflite',
            imgsz=640,  # Standard YOLO input size
            int8=False,  # Set to True for INT8 quantization (smaller but may reduce accuracy)
            data=None,   # No calibration dataset needed for FP16
        )

        # Find the generated TFLite file
        onnx_dir = Path(onnx_path).parent
        tflite_files = list(onnx_dir.glob('*.tflite'))

        if tflite_files:
            # Move to output directory
            src_tflite = tflite_files[0]
            dst_tflite = output_dir / 'best.tflite'

            import shutil
            shutil.move(str(src_tflite), str(dst_tflite))

            file_size = dst_tflite.stat().st_size / (1024 * 1024)
            print(f"\n✅ TFLite model saved: {dst_tflite}")
            print(f"   Size: {file_size:.2f} MB")

            return dst_tflite
        else:
            print("❌ TFLite file not generated")
            return None

    except ImportError:
        print("⚠️  Ultralytics not available, trying alternative method...")
        return None
    except Exception as e:
        print(f"❌ Ultralytics conversion failed: {e}")
        import traceback
        traceback.print_exc()
        return None


def convert_onnx_to_tflite_manual(onnx_path, output_dir):
    """
    Fallback: Manual conversion using ONNX -> TF -> TFLite.
    Less reliable for YOLO models.
    """
    try:
        import onnx
        import tensorflow as tf
        import tf2onnx

        print("\n" + "="*70)
        print("Method 2: Manual Conversion (Fallback)")
        print("="*70)

        print("\n⚠️  Warning: Manual conversion may not preserve all YOLO operations")
        print("   If this fails, please use Method 1 (Ultralytics)")

        # Load ONNX
        print(f"\n📂 Loading ONNX model: {onnx_path}")
        onnx_model = onnx.load(onnx_path)

        # Convert to TensorFlow SavedModel
        print("\n🔄 Converting ONNX -> TensorFlow SavedModel...")
        output_dir = Path(output_dir)
        saved_model_dir = output_dir / 'saved_model'
        saved_model_dir.mkdir(parents=True, exist_ok=True)

        # This uses tf2onnx for conversion
        from tf2onnx import convert

        # Note: This is complex and may fail for YOLO
        # The proper way is to use onnx-tf or ultralytics

        print("❌ Manual conversion not fully implemented")
        print("   Please install ultralytics: pip install ultralytics")
        return None

    except Exception as e:
        print(f"❌ Manual conversion failed: {e}")
        return None


def main():
    print("="*70)
    print("YOLO ONNX to TFLite Converter")
    print("="*70)

    # Check Python version
    if not check_python_version():
        return 1

    # Check dependencies
    try:
        import tensorflow as tf
        import onnx
        print(f"\n✅ TensorFlow version: {tf.__version__}")
        print(f"✅ ONNX version: {onnx.__version__}")

        try:
            from ultralytics import YOLO
            print(f"✅ Ultralytics available")
            deps_ok = True
        except ImportError:
            print("⚠️  Ultralytics not installed")
            deps_ok = False

    except ImportError as e:
        print(f"\n❌ Missing dependencies: {e}")
        deps_ok = False

    if not deps_ok:
        print("\n" + "="*70)
        response = input("Install missing dependencies now? (y/n): ").strip().lower()
        if response == 'y':
            if not install_dependencies():
                return 1
        else:
            print("\n❌ Cannot proceed without dependencies")
            return 1

    # Paths
    onnx_source = Path(r"C:\Users\HP\PycharmProjects\card-detection-yolo\flutter_app\assets\models\best.onnx")
    output_dir = Path(r"C:\Users\HP\PycharmProjects\smart-measurement\assets\models")

    print(f"\n📂 Source ONNX: {onnx_source}")
    print(f"📂 Output directory: {output_dir}")

    if not onnx_source.exists():
        print(f"\n❌ ONNX model not found: {onnx_source}")
        return 1

    # Try conversion
    tflite_path = convert_onnx_to_tflite_ultralytics(str(onnx_source), str(output_dir))

    if not tflite_path:
        print("\n⚠️  Primary method failed, trying fallback...")
        tflite_path = convert_onnx_to_tflite_manual(str(onnx_source), str(output_dir))

    if tflite_path:
        print("\n" + "="*70)
        print("✅ SUCCESS!")
        print("="*70)
        print(f"\n📦 TFLite model ready: {tflite_path}")
        print("\n📋 Next steps:")
        print("   1. Update pubspec.yaml - ensure best.tflite is in assets")
        print("   2. Remove all ONNX references from Dart code")
        print("   3. Use TFLiteService for inference")
        print("   4. Run: flutter pub get")
        print("   5. Run: flutter run")
        return 0
    else:
        print("\n" + "="*70)
        print("❌ CONVERSION FAILED")
        print("="*70)
        print("\n🔧 Troubleshooting:")
        print("   1. Ensure Python 3.8-3.11 is installed")
        print("   2. Run: pip install ultralytics tensorflow==2.13.0")
        print("   3. Check that ONNX model is valid YOLO format")
        return 1


if __name__ == "__main__":
    sys.exit(main())

