# دليل التحويل من ONNX إلى TFLite - المشروع النظيف

## ✅ التنظيف المكتمل

تم حذف جميع مراجع ONNX من المشروع واستبدالها بـ TFLite:

### الملفات المحذوفة:
- ❌ `lib/core/services/onnx_inference_service.dart` (تم الحذف)
- ❌ `convert_onnx_to_tflite.py` (تم الحذف)
- ❌ `manual_onnx_to_tflite.py` (تم الحذف)
- ❌ `assets/models/best_v1.onnx` (تم الحذف)

### الملفات المحدثة:
- ✅ `lib/core/services/tflite_service.dart` (تم إنشاؤه جديد)
- ✅ `lib/core/providers/providers.dart` (استبدال `onnxInferenceServiceProvider` بـ `tfliteServiceProvider`)
- ✅ `lib/core/providers/calibration_controller.dart` (استبدال `OnnxInferenceService` بـ `TFLiteService`)
- ✅ `lib/features/calibration/presentation/screens/smart_calibration_screen.dart` (تحديث التهيئة)
- ✅ `pubspec.yaml` (إزالة `onnxruntime`, إبقاء `tflite_flutter: ^0.10.4`)

---

## 🔄 خطوات التحويل من ONNX إلى TFLite

### المتطلبات:

1. **Python 3.8 - 3.11** (يُفضل 3.10)
2. **المكتبات المتوافقة:**

```bash
# إنشاء بيئة افتراضية نظيفة
python -m venv venv_tflite
.\venv_tflite\Scripts\Activate.ps1

# تثبيت المكتبات المتوافقة
pip install --upgrade pip
pip install tensorflow==2.13.0
pip install onnx==1.14.0
pip install numpy<2.0
pip install ultralytics
```

### الطريقة 1: استخدام Ultralytics (موصى بها لـ YOLO)

```python
from ultralytics import YOLO

# تحميل نموذج ONNX
model = YOLO('C:/Users/HP/PycharmProjects/card-detection-yolo/flutter_app/assets/models/best.onnx')

# التصدير إلى TFLite
model.export(
    format='tflite',
    imgsz=640,
    int8=False  # استخدم True للحصول على حجم أصغر مع دقة أقل قليلاً
)

# سيتم حفظ الملف كـ best.tflite في نفس المجلد
```

### الطريقة 2: استخدام TensorFlow مباشرة

إذا كان النموذج ONNX يحتوي على عمليات غير مدعومة:

```python
import onnx
from onnx_tf.backend import prepare
import tensorflow as tf

# 1. تحميل ONNX
onnx_model = onnx.load('best.onnx')

# 2. تحويل إلى TensorFlow SavedModel
tf_rep = prepare(onnx_model)
tf_rep.export_graph('saved_model')

# 3. تحويل SavedModel إلى TFLite
converter = tf.lite.TFLiteConverter.from_saved_model('saved_model')
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# 4. حفظ TFLite
with open('best.tflite', 'wb') as f:
    f.write(tflite_model)
```

---

## 📋 خطوات ما بعد التحويل

### 1. نسخ النموذج المُحوّل

```powershell
Copy-Item ".\best.tflite" -Destination "C:\Users\HP\PycharmProjects\smart-measurement\assets\models\best.tflite"
```

### 2. التحقق من الملفات

تأكد من وجود:
- ✅ `assets/models/best.tflite`
- ✅ `assets/models/labels.txt`

### 3. تنظيف Flutter

```powershell
cd C:\Users\HP\PycharmProjects\smart-measurement
flutter clean
flutter pub get
```

### 4. التشغيل

```powershell
flutter run -d windows  # للاختبار على Windows
flutter run  # لجهاز Android المتصل
```

---

## 🔧 تكوين TFLiteService

تم تكوين `TFLiteService` للعمل مع:

- **حجم الإدخال:** 640x640 (YOLO standard)
- **القنوات:** RGB (3 قنوات)
- **التطبيع:** [0, 1] range
- **الإخراج:** اكتشاف نقاط الجسم (17 keypoint لكل شخص)

### تخصيص النموذج:

إذا كان نموذج YOLO الخاص بك مختلف، قم بتعديل:

```dart
// في tflite_service.dart
static const int _inputSize = 640; // حجم مدخل نموذجك
static const int _numChannels = 3; // عدد القنوات

// في _postProcessOutput
final numKeypoints = 17; // عدد النقاط في نموذجك
final keypointStartIdx = 5; // بداية النقاط في مصفوفة الإخراج
```

---

## 🐛 استكشاف الأخطاء

### خطأ: "Model not found"
```dart
// تأكد من أن الملف في pubspec.yaml
assets:
  - assets/models/best.tflite
  - assets/models/labels.txt

// ثم شغّل
flutter clean
flutter pub get
```

### خطأ: "TFLite interpreter failed"
```
- تأكد من صحة تنسيق TFLite
- تحقق من توافق الإصدارات
- جرب إعادة التحويل مع int8=False
```

### خطأ: "Unexpected output shape"
```dart
// في tflite_service.dart, عدّل _postProcessOutput
// بناءً على شكل إخراج نموذجك الفعلي
final outputTensor = _interpreter!.getOutputTensor(0);
debugPrint('Output shape: ${outputTensor.shape}');
```

---

## 📊 توافق الإصدارات المختبرة

| المكتبة | الإصدار | الحالة |
|---------|---------|--------|
| Flutter | 3.0+ | ✅ مدعوم |
| tflite_flutter | 0.10.4 | ✅ مدعوم |
| TensorFlow (Python) | 2.13.0 | ✅ موصى به |
| ONNX (Python) | 1.14.0 | ✅ متوافق |
| Ultralytics | Latest | ✅ الأفضل |
| Python | 3.8-3.11 | ✅ مدعوم |
| Android minSdk | 26+ | ✅ مطلوب |

---

## 📝 ملاحظات مهمة

1. **عدم استخدام ONNX في Flutter:**
   - مكتبة `onnxruntime` لـ Flutter غير مستقرة
   - TFLite أفضل للأداء والاستقرار على الأجهزة المحمولة

2. **حجم النموذج:**
   - ONNX: ~12 MB
   - TFLite (FP32): ~12 MB
   - TFLite (INT8): ~3-4 MB (مع quantization)

3. **الأداء:**
   - TFLite أسرع على Android (GPU delegation)
   - دعم أفضل للأجهزة المحمولة

4. **التحويل:**
   - يتم التحويل مرة واحدة على الكمبيوتر
   - يتم استخدام TFLite مباشرة في التطبيق

---

## ✅ الخطوة التالية

**بعد إتمام التحويل:**

1. شغّل سكريبت التحويل: `python convert_yolo_to_tflite.py`
2. انسخ `best.tflite` إلى `assets/models/`
3. شغّل `flutter clean && flutter pub get`
4. اختبر التطبيق: `flutter run`

**إذا واجهت مشاكل في التحويل:**
- تواصل معي وسأساعدك في إيجاد حل بديل
- يمكن استخدام خدمة تحويل عبر الإنترنت
- أو تحويل النموذج باستخدام Google Colab

---

تاريخ التحديث: 2025-12-03
الحالة: ✅ الكود جاهز، ينتظر تحويل النموذج

