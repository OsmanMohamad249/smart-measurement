# دمج نموذج YOLO المُدرَّب - دليل خطوة بخطوة

## 📦 الخطوة 1: الحصول على النموذج

### استنساخ المستودع:
```powershell
cd C:\Users\HP\PycharmProjects
git clone https://github.com/OsmanMohamad249/card-detection-yolo
cd card-detection-yolo
```

---

## 🔄 الخطوة 2: تحويل النموذج إلى TFLite (إن لم يكن جاهزًا)

### إذا كان النموذج بصيغة PyTorch (.pt):
```python
from ultralytics import YOLO

# تحميل النموذج المُدرَّب
model = YOLO('path/to/your/best.pt')

# تصدير إلى TFLite
model.export(format='tflite', imgsz=320, int8=False)
```

### البدائل الأخرى:
- **TFLite FP16**: `model.export(format='tflite', imgsz=320, half=True)`
- **TFLite INT8 (Quantized)**: يتطلب representative dataset

---

## 📁 الخطوة 3: نسخ النموذج إلى المشروع

```powershell
# إنشاء مجلد models إن لم يكن موجودًا
cd C:\Users\HP\PycharmProjects\smart-measurement
New-Item -ItemType Directory -Force -Path assets\models

# نسخ ملف النموذج
Copy-Item C:\Users\HP\PycharmProjects\card-detection-yolo\*.tflite assets\models\yolov8_pose.tflite
```

---

## ⚙️ الخطوة 4: التحقق من تنسيق مخرجات النموذج

### تشغيل سكريبت الاختبار:
```python
import numpy as np
import tensorflow as tf

# تحميل النموذج
interpreter = tf.lite.Interpreter(model_path="assets/models/yolov8_pose.tflite")
interpreter.allocate_tensors()

# فحص الشكل الداخلي للمخرجات
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input Shape:", input_details[0]['shape'])
print("Output Shape:", output_details[0]['shape'])
print("Output Type:", output_details[0]['dtype'])

# اختبار بصورة عشوائية
input_shape = input_details[0]['shape']
test_input = np.random.rand(*input_shape).astype(np.float32)

interpreter.set_tensor(input_details[0]['index'], test_input)
interpreter.invoke()

output = interpreter.get_tensor(output_details[0]['index'])
print("Sample Output:", output.shape)
print("First 20 values:", output.flatten()[:20])
```

### الشكل المتوقع:
- **Input**: `[1, 320, 320, 3]` أو `[1, 640, 640, 3]`
- **Output** (YOLOv8 Pose): `[1, 56, 8400]` أو مشابه
  - 56 = 4 (bbox) + 1 (confidence) + 51 (17 keypoints × 3)
  - 8400 = عدد anchors

---

## 🔧 الخطوة 5: تحديث parsing logic في `tflite_service.dart`

### فتح الملف:
```powershell
code lib\core\services\tflite_service.dart
```

### تحديث `_extractCardCorners`:
```dart
List<Point<double>> _extractCardCorners(
  Float32List output,
  int frameWidth,
  int frameHeight,
) {
  // TODO: ضبط هذا بناءً على شكل مخرجات النموذج الفعلي
  
  // مثال: إذا كان Output shape = [1, 56, 8400]
  // نحتاج لإيجاد أعلى confidence detection ثم استخراج أول 4 keypoints
  
  // الكود الحالي يفترض أن أول 8 قيم هي الزوايا (x1,y1,x2,y2,x3,y3,x4,y4)
  // قد تحتاج لتعديل هذا حسب تنسيق النموذج
  
  if (output.length < 8) {
    return const <Point<double>>[];
  }

  final corners = <Point<double>>[];
  for (int i = 0; i < 4; i++) {
    final x = output[i * 2].clamp(0.0, 1.0) * frameWidth;
    final y = output[i * 2 + 1].clamp(0.0, 1.0) * frameHeight;
    corners.add(Point<double>(x, y));
  }
  return corners;
}
```

### إذا كان النموذج يُخرج إحداثيات مطلقة:
```dart
final x = output[i * 2].clamp(0.0, inputSize.toDouble()) * frameWidth / inputSize;
final y = output[i * 2 + 1].clamp(0.0, inputSize.toDouble()) * frameHeight / inputSize;
```

---

## 🧪 الخطوة 6: اختبار التكامل

### تشغيل التطبيق:
```powershell
flutter clean
flutter pub get
flutter run
```

### نقاط التحقق:
- [ ] النموذج يتم تحميله بنجاح (تحقق من logs)
- [ ] الكاميرا تعمل
- [ ] زر "Start Calibration" يبدأ المعالجة
- [ ] رسائل الحالة تظهر بشكل صحيح
- [ ] الزوايا تظهر على الشاشة عند الكشف

### في حالة وجود أخطاء:
```dart
// في tflite_service.dart، أضف debugging:
debugPrint('Output length: ${output.length}');
debugPrint('First 20 values: ${output.sublist(0, min(20, output.length))}');
debugPrint('Detected corners: $corners');
```

---

## 🎨 الخطوة 7: ضبط المعاملات للأداء الأمثل

### في `tflite_service.dart`:
```dart
static const int inputSize = 320; // جرب 320, 416, 640
static const double confidenceThreshold = 0.5; // جرب 0.3 - 0.7
```

### في `calibration_controller.dart`:
```dart
static const int _smoothingWindow = 5; // عدد الإطارات للتنعيم
static const int _requiredStableFrames = 10; // الإطارات المطلوبة قبل التأكيد
```

### في `homography_utils.dart`:
```dart
static bool validateCardCorners(
  List<Vector2> corners, {
  double minArea = 2000, // الحد الأدنى للمساحة
  double aspectTolerance = 0.3, // تساهل نسبة الأبعاد
})
```

---

## 🐛 استكشاف الأخطاء الشائعة

### خطأ: "Model not found"
```powershell
# تأكد من وجود الملف:
Test-Path assets\models\yolov8_pose.tflite

# تأكد من إضافته في pubspec.yaml:
flutter:
  assets:
    - assets/models/
```

### خطأ: "Output shape mismatch"
- افحص شكل المخرجات باستخدام السكريبت في الخطوة 4
- عدّل `_extractCardCorners` بناءً على الشكل الفعلي

### الزوايا لا تظهر:
- تحقق من `confidenceThreshold` (جرب تقليله)
- تحقق من `validateCardCorners` (جرب زيادة `aspectTolerance`)
- أضف debug prints في `_processFrame`

### الكشف بطيء:
- قلل `inputSize` إلى 320
- استخدم نموذج INT8 quantized
- قلل عدد threads في InterpreterOptions

---

## ✅ Checklist النهائي

- [ ] النموذج منسوخ في `assets/models/yolov8_pose.tflite`
- [ ] `pubspec.yaml` محدّث
- [ ] `_extractCardCorners` معدّل حسب تنسيق المخرجات
- [ ] التطبيق يعمل بدون أخطاء
- [ ] الكشف يعمل على بطاقة حقيقية
- [ ] `mm_per_pixel` يُحسب بشكل صحيح
- [ ] الانتقال إلى شاشة Capture يعمل

---

## 📞 الدعم

إذا واجهت مشاكل:
1. تحقق من logs باستخدام `flutter logs`
2. تأكد من أن النموذج مدرب بشكل صحيح (على بطاقات مشابهة)
3. جرب النموذج في Python أولاً للتأكد من جودته

---

**بعد إتمام هذه الخطوات، ستكون جاهزًا للانتقال إلى المرحلة التالية: Body Tracking!** 🚀

