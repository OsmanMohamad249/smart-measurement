# ONNX Integration Troubleshooting Guide

## المشكلة الحالية (Current Issue)

التطبيق يعرض الرسالة التالية بشكل متكرر:
```
I/flutter: OnnxInferenceService not initialized
```

هذا يعني أن خدمة ONNX Runtime لم يتم تهيئتها بشكل صحيح.

## الأسباب المحتملة (Possible Causes)

### 1. عدم تهيئة بيئة ONNX Runtime
**الحل**: تم إضافة `OrtEnv.instance.init()` في دالة التهيئة.

### 2. مشاكل في دعم Android لمكتبة onnxruntime
مكتبة `onnxruntime` للـ Dart/Flutter قد تواجه مشاكل في التوافق مع Android.

### 3. حجم النموذج الكبير
النموذج `best.onnx` حجمه حوالي 12 MB، قد يسبب مشاكل في الذاكرة.

## الحلول المقترحة (Proposed Solutions)

### الحل 1: تحويل النموذج من ONNX إلى TFLite

#### الخطوات:

1. **تحويل النموذج باستخدام Python**:
```python
# استخدام الكود الموجود في convert_onnx_to_tflite.py
python convert_onnx_to_tflite.py
```

2. **نسخ الملف المحول**:
```powershell
Copy-Item "best.tflite" "assets/models/"
```

3. **تحديث الكود لاستخدام TFLiteService بدلاً من OnnxInferenceService**:
   - تعديل `calibration_controller.dart`
   - استخدام `tfliteServiceProvider` بدلاً من `onnxInferenceServiceProvider`

### الحل 2: فحص تفصيلي لأخطاء ONNX

#### الخطوة 1: تشغيل التطبيق مع logcat
```bash
flutter run -d <DEVICE_ID> --verbose
```

#### الخطوة 2: فحص سجلات Android
```bash
adb logcat | grep -i "onnx\|error\|exception"
```

#### الخطوة 3: التحقق من رسائل التشخيص
ابحث عن:
- `OnnxInferenceService: Starting initialization...`
- `OnnxInferenceService: ONNX Runtime environment initialized`
- `OnnxInferenceService: Model loaded, size: ...`
- أي رسائل خطأ

### الحل 3: استخدام TFLite مباشرة

بما أن لدينا بالفعل `tflite_flutter` في المشروع، يمكننا:

1. **تحويل النموذج**:
```bash
# في مجلد card-detection-yolo
yolo export model=best.pt format=tflite imgsz=640
```

2. **نسخ النموذج المحول**:
```powershell
Copy-Item "C:\Users\HP\PycharmProjects\card-detection-yolo\best_saved_model\best_float32.tflite" "C:\Users\HP\PycharmProjects\smart-measurement\assets\models\best.tflite"
```

3. **تفعيل TFLiteService**:
   - استخدام `TFLiteService` الموجود بالفعل في المشروع
   - تحديث `providers.dart` لاستخدام `tfliteServiceProvider`

## التحقق من التهيئة (Initialization Check)

### رسائل النجاح المتوقعة:
```
I/flutter: Initializing camera...
I/flutter: Camera initialized successfully
I/flutter: Initializing ONNX service...
I/flutter: OnnxInferenceService: Starting initialization...
I/flutter: OnnxInferenceService: Initializing ONNX Runtime environment...
I/flutter: OnnxInferenceService: ONNX Runtime environment initialized
I/flutter: OnnxInferenceService: Loading model from assets/models/best.onnx
I/flutter: OnnxInferenceService: Model loaded, size: 12802374 bytes
I/flutter: OnnxInferenceService: Creating ONNX session...
I/flutter: OnnxInferenceService: ONNX session created
I/flutter: ✓ OnnxInferenceService initialized successfully!
I/flutter: ONNX service initialized: true
I/flutter: Initializing guidance manager...
I/flutter: Guidance manager initialized
```

### رسائل الفشل:
إذا ظهرت رسالة:
```
✗ OnnxInferenceService initialization error: ...
```

تحقق من:
1. وجود الملف `assets/models/best.onnx`
2. إضافة الملف في `pubspec.yaml`
3. دعم Android لمكتبة onnxruntime

## الإجراء الموصى به (Recommended Action)

**استخدام TFLite بدلاً من ONNX** لأن:
1. TFLite لديه دعم أفضل لـ Flutter/Android
2. TFLite أسرع في الاستدلال
3. TFLite يستهلك ذاكرة أقل
4. لدينا بالفعل `tflite_flutter` في المشروع

## خطوات التنفيذ السريعة

### 1. تحويل النموذج (إذا لم يكن موجوداً)
```bash
cd C:\Users\HP\PycharmProjects\card-detection-yolo
yolo export model=best.pt format=tflite imgsz=640
```

### 2. نسخ النموذج
```powershell
Copy-Item "C:\Users\HP\PycharmProjects\card-detection-yolo\best_float32.tflite" "C:\Users\HP\PycharmProjects\smart-measurement\assets\models\best.tflite"
```

### 3. تحديث pubspec.yaml
```yaml
flutter:
  assets:
    - assets/models/
    - assets/models/best.onnx
    - assets/models/best.tflite  # إضافة هذا السطر
    - assets/models/labels.txt
```

### 4. التبديل إلى TFLiteService
في `calibration_controller.dart`، تغيير:
```dart
final onnxService = ref.read(onnxInferenceServiceProvider);
```

إلى:
```dart
final tfliteService = ref.read(tfliteServiceProvider);
```

## الحالة الحالية

- ✅ تم إضافة معالجة شاملة للأخطاء
- ✅ تم إضافة رسائل تشخيصية تفصيلية
- ✅ تم إضافة تهيئة `OrtEnv.instance.init()`
- ⏳ في انتظار فحص رسائل logcat لتحديد السبب الدقيق
- 🔄 يُنصح بالتحول إلى TFLite كخطوة تالية

## المراجع

- [onnxruntime package](https://pub.dev/packages/onnxruntime)
- [tflite_flutter package](https://pub.dev/packages/tflite_flutter)
- [YOLOv8 Export Formats](https://docs.ultralytics.com/modes/export/)

