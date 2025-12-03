# Google Colab Notebook for YOLO ONNX to TFLite Conversion

## Instructions:
1. Go to https://colab.research.google.com/
2. Create a new notebook
3. Copy each code cell below into separate cells
4. Run cells in order

---

## Cell 1: Install Dependencies

```python
!pip install -q tensorflow==2.13.0
!pip install -q onnx==1.14.0
!pip install -q 'numpy<2.0'
!pip install -q ultralytics

print("✅ All dependencies installed")
```

---

## Cell 2: Upload ONNX Model

```python
from google.colab import files
import shutil

print("📤 Please upload your ONNX model (best.onnx)")
uploaded = files.upload()

# Get the uploaded file name
onnx_file = list(uploaded.keys())[0]
print(f"✅ Uploaded: {onnx_file}")
```

---

## Cell 3: Method 1 - Ultralytics (Recommended)

```python
from ultralytics import YOLO

print("🔄 Converting ONNX to TFLite using Ultralytics...")

try:
    # Load ONNX model
    model = YOLO(onnx_file, task='detect')
    
    # Export to TFLite
    model.export(
        format='tflite',
        imgsz=640,
        int8=False  # Set to True for smaller model with slight accuracy loss
    )
    
    print("✅ Conversion successful!")
    print("📦 TFLite model created")
    
except Exception as e:
    print(f"❌ Conversion failed: {e}")
    print("Trying alternative method...")
```

---

## Cell 4: Download TFLite Model

```python
from google.colab import files
import glob

# Find the generated TFLite file
tflite_files = glob.glob('*.tflite')

if tflite_files:
    tflite_file = tflite_files[0]
    print(f"📥 Downloading {tflite_file}...")
    files.download(tflite_file)
    print("✅ Download complete!")
    print(f"📋 File size: {os.path.getsize(tflite_file) / (1024*1024):.2f} MB")
else:
    print("❌ No TFLite file found")
```

---

## Cell 5: Verify TFLite Model (Optional)

```python
import tensorflow as tf

if tflite_files:
    interpreter = tf.lite.Interpreter(model_path=tflite_file)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("📊 Model Information:")
    print("\n🔹 Input:")
    for inp in input_details:
        print(f"   Shape: {inp['shape']}, Type: {inp['dtype']}")
    
    print("\n🔹 Output:")
    for out in output_details:
        print(f"   Shape: {out['shape']}, Type: {out['dtype']}")
    
    print("\n✅ Model is valid!")
```

---

## After Download:

1. Save the downloaded `best.tflite` (or similar name)
2. Copy it to your Flutter project:
   ```
   C:\Users\HP\PycharmProjects\smart-measurement\assets\models\best.tflite
   ```
3. Run Flutter:
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

---

## Alternative: Direct TensorFlow Conversion (if Ultralytics fails)

```python
# Only use this if Method 1 fails

import onnx
import tensorflow as tf
from onnx_tf.backend import prepare

try:
    # Install onnx-tf
    !pip install -q onnx-tf
    
    # Load ONNX
    onnx_model = onnx.load(onnx_file)
    
    # Convert to TensorFlow
    tf_rep = prepare(onnx_model)
    tf_rep.export_graph('saved_model')
    
    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_saved_model('saved_model')
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    # Save
    with open('best_manual.tflite', 'wb') as f:
        f.write(tflite_model)
    
    print("✅ Manual conversion successful!")
    files.download('best_manual.tflite')
    
except Exception as e:
    print(f"❌ Manual conversion failed: {e}")
    print("Please use Method 1 (Ultralytics)")
```

---

## Troubleshooting:

- **Upload fails**: Check file size (Colab has limits)
- **Conversion fails**: Ensure ONNX model is valid YOLO format
- **Shape mismatch**: Check model was exported correctly from training
- **Runtime error**: Try with `int8=True` for simpler conversion


