# تقرير فشل عملية المعايرة (Calibration Failure Report)

## 📋 ملخص المشكلة

التطبيق يفشل في عملية المعايرة بسبب عدم تهيئة خدمة `OnnxInferenceService`. الكاميرا تفتح بشكل صحيح، لكن الرسالة التالية تظهر بشكل متكرر:

```
I/flutter (26910): OnnxInferenceService not initialized
```

## 🔍 التحليل الفني

### 1. المشكلة الرئيسية
مكتبة `onnxruntime` (v1.4.1) لـ Dart/Flutter قد لا تعمل بشكل صحيح على Android بسبب:
- **مشاكل في التوافق**: قد تحتاج لملفات SO الأصلية غير موجودة
- **حجم النموذج**: النموذج ONNX حجمه 12.8 MB قد يسبب مشاكل في الذاكرة
- **عدم التهيئة الصحيحة**: البيئة ONNX Runtime قد لا تُهيّأ بشكل صحيح على Android

### 2. ما تم إنجازه حتى الآن
✅ إضافة معالجة شاملة للأخطاء في `_initializeServices()`
✅ إضافة رسائل تشخيصية تفصيلية في `OnnxInferenceService`
✅ إضافة تهيئة `OrtEnv.instance.init()` قبل إنشاء الجلسة
✅ التحقق من وجود النموذج في `assets/models/best.onnx`
✅ التحقق من إعدادات `pubspec.yaml`

### 3. المشكلة المتبقية
❌ لا يوجد ملف `best.pt` (النموذج الأصلي) لتحويله إلى TFLite
❌ فقط ملف `best.onnx` متوفر
❌ لا يمكن تحويل ONNX مباشرة إلى TFLite

## 💡 الحلول الممكنة

### الحل 1: الحصول على ملف best.pt (الموصى به ⭐)

#### الخطوات:
1. **العودة إلى مشروع التدريب**:
   ```bash
   cd C:\Users\HP\PycharmProjects\card-detection-yolo
   ```

2. **البحث عن النموذج الأصلي**:
   ```bash
   # البحث في مجلدات runs/detect/train
   dir /s best.pt
   ```

3. **إذا وُجد، تحويله إلى TFLite**:
   ```python
   from ultralytics import YOLO
   model = YOLO('path/to/best.pt')
   model.export(format='tflite', imgsz=640)
   ```

4. **نسخ الملف المحول**:
   ```powershell
   Copy-Item "best_saved_model\best_float32.tflite" "C:\Users\HP\PycharmProjects\smart-measurement\assets\models\best.tflite"
   ```

### الحل 2: تحويل ONNX إلى TFLite (معقد)

يتطلب خطوات متعددة:
1. تحويل ONNX → TensorFlow SavedModel
2. تحويل SavedModel → TFLite

```bash
# تثبيت الأدوات المطلوبة
pip install onnx tensorflow onnx-tf

# التحويل
python convert_onnx_to_tflite.py
```

### الحل 3: إصلاح ONNX Runtime (تجريبي)

#### أ) إضافة Native Libraries يدوياً

1. **تحميل ONNX Runtime AAR**:
   ```kotlin
   // في android/app/build.gradle.kts
   dependencies {
       implementation("com.microsoft.onnxruntime:onnxruntime-android:latest.version")
   }
   ```

2. **إعادة بناء التطبيق**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk
   ```

#### ب) استخدام نسخة أحدث من onnxruntime

تحديث `pubspec.yaml`:
```yaml
dependencies:
  onnxruntime: ^1.4.1  # جرب النسخة الأحدث إن وُجدت
```

### الحل 4: استخدام TFLiteService بدلاً من OnnxInferenceService

إذا كان لديك نموذج TFLite جاهز:

#### التعديلات المطلوبة:

**1. في `lib/core/providers/providers.dart`:**
```dart
// استبدال
final onnxInferenceServiceProvider = Provider<OnnxInferenceService>((ref) {
  final service = OnnxInferenceService();
  ref.onDispose(() => service.dispose());
  return service;
});

// بـ
final tfliteServiceProvider = Provider<TFLiteService>((ref) {
  final service = TFLiteService();
  ref.onDispose(() => service.dispose());
  return service;
});
```

**2. في `lib/features/calibration/presentation/screens/smart_calibration_screen.dart`:**
```dart
// استبدال
final onnxService = ref.read(onnxInferenceServiceProvider);
await onnxService.initialize();

// بـ
final tfliteService = ref.read(tfliteServiceProvider);
await tfliteService.initialize();
```

**3. في `lib/core/providers/calibration_controller.dart`:**
```dart
// استبدال
final OnnxInferenceService _onnxService;

// بـ
final TFLiteService _tfliteService;

// وتحديث جميع استدعاءات _onnxService إلى _tfliteService
```

## 🚀 خطة العمل الموصى بها

### الأولوية 1: الحصول على best.pt
1. ✅ فحص مجلد التدريب للعثور على `best.pt`
2. ✅ إذا لم يوجد، إعادة تصدير النموذج من مجلد runs/detect/train
3. ✅ تحويل PT إلى TFLite
4. ✅ التبديل إلى TFLiteService

### الأولوية 2: إصلاح ONNX Runtime
1. ⏳ فحص logcat للحصول على رسالة الخطأ الدقيقة
2. ⏳ إضافة native libraries إذا لزم الأمر
3. ⏳ تحديث المكتبة للنسخة الأحدث

### الأولوية 3: تحويل ONNX مباشرة
1. ⏳ استخدام `onnx-tensorflow` للتحويل
2. ⏳ تحويل SavedModel إلى TFLite
3. ⏳ اختبار النموذج المحول

## 📊 الحالة الحالية

### ما يعمل:
- ✅ التطبيق يبني بنجاح
- ✅ الكاميرا تُهيّأ وتفتح بشكل صحيح
- ✅ صلاحيات الكاميرا تُمنح
- ✅ واجهة المستخدم تعمل
- ✅ الكود منظم بشكل صحيح

### ما لا يعمل:
- ❌ تهيئة OnnxInferenceService
- ❌ معالجة الإطارات من الكاميرا
- ❌ اكتشاف البطاقة المرجعية
- ❌ حساب معامل المعايرة

## 🛠️ الإجراء المطلوب الآن

يرجى تنفيذ أحد الخيارات التالية:

### الخيار A: البحث عن best.pt
```bash
cd C:\Users\HP\PycharmProjects\card-detection-yolo
dir /s best.pt
```

إذا وُجد الملف، قم بإخباري بمساره الكامل.

### الخيار B: إعادة التصدير من التدريب
إذا كان لديك وصول لـ checkpoint التدريب:
```python
from ultralytics import YOLO
model = YOLO('path/to/checkpoint.pt')
model.export(format='tflite', imgsz=640)
```

### الخيار C: فحص أخطاء ONNX بالتفصيل
```bash
flutter run -d R5CN813ZCGN
# ثم في terminal آخر:
adb logcat | grep -i "onnx\|error\|exception"
```

أرسل لي نتيجة logcat لتحليلها.

## 📝 ملاحظات مهمة

1. **TFLite أفضل من ONNX لـ Flutter**:
   - دعم أفضل للأجهزة المحمولة
   - استهلاك ذاكرة أقل
   - سرعة استدلال أعلى
   - توثيق وأمثلة أكثر

2. **حجم النموذج**:
   - ONNX: ~12.8 MB
   - TFLite المتوقع: ~6-8 MB (أصغر)

3. **الأداء المتوقع**:
   - TFLite على Android: ~30-60 FPS
   - ONNX على Android: ~15-30 FPS (إذا عمل)

## 🔗 المراجع المفيدة

- [YOLOv8 Export Documentation](https://docs.ultralytics.com/modes/export/)
- [TFLite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [ONNX Runtime Flutter](https://pub.dev/packages/onnxruntime)
- [Converting ONNX to TFLite](https://github.com/onnx/onnx-tensorflow)

---

**تاريخ التقرير**: 3 ديسمبر 2025  
**الحالة**: في انتظار الحصول على best.pt أو نتائج logcat

