# Smart Measurement - بنية المشروع النهائية

## 📁 الهيكل العام للمشروع

```
smart-measurement/
├── 📄 .gitignore                  # قواعد تجاهل Git
├── 📄 .metadata                   # بيانات Flutter الوصفية
├── 📄 analysis_options.yaml       # إعدادات تحليل Dart
├── 📄 Copyright                   # حقوق النشر
├── 📄 pubspec.yaml               # ملف التبعيات الرئيسي
├── 📄 README.md                  # التوثيق الرئيسي
├── 📄 CLEANUP_SUMMARY.md        # ملخص عملية التنظيف
├── 📄 PROJECT_STRUCTURE.md      # هذا الملف
│
├── 📂 .git/                      # مجلد Git (إدارة الإصدارات)
│
├── 📂 android/                   # مشروع Android الأصلي
│   ├── 📂 app/
│   │   ├── 📂 src/
│   │   │   ├── 📂 main/
│   │   │   │   ├── 📂 kotlin/com/smartmeasurement/app/
│   │   │   │   │   └── 📄 MainActivity.kt
│   │   │   │   ├── 📂 res/              # الموارد (أيقونات، ألوان، إلخ)
│   │   │   │   └── 📄 AndroidManifest.xml
│   │   │   ├── 📂 debug/
│   │   │   │   └── 📄 AndroidManifest.xml
│   │   │   └── 📂 profile/
│   │   │       └── 📄 AndroidManifest.xml
│   │   └── 📄 build.gradle.kts   # إعدادات بناء التطبيق
│   │
│   ├── 📂 gradle/
│   │   └── 📂 wrapper/
│   │       ├── 📄 gradle-wrapper.jar
│   │       └── 📄 gradle-wrapper.properties
│   │
│   ├── 📄 build.gradle.kts       # إعدادات Gradle الرئيسية
│   ├── 📄 settings.gradle.kts    # إعدادات المشروع
│   ├── 📄 gradle.properties      # خصائص Gradle
│   ├── 📄 gradlew               # سكريبت Gradle (Unix)
│   ├── 📄 gradlew.bat           # سكريبت Gradle (Windows)
│   └── 📄 local.properties      # المسارات المحلية
│
├── 📂 assets/                    # موارد التطبيق
│   ├── 📄 .gitkeep
│   └── 📂 models/                # نماذج AI
│       ├── 📄 card_detector.onnx # ✅ نموذج YOLOv8 ONNX (~12MB)
│       ├── 📄 best.onnx          # ✅ نموذج YOLO-Pose ONNX
│       ├── 📄 labels.txt         # تصنيفات النموذج
│       └── 📄 README.md          # وصف النماذج
│
└── 📂 lib/                       # كود Dart الرئيسي
    ├── 📄 main.dart             # نقطة دخول التطبيق
    │
    ├── 📂 core/                 # الوظائف الأساسية المشتركة
    │   │
    │   ├── 📂 providers/        # مزودات Riverpod
    │   │   ├── 📄 calibration_controller.dart  # متحكم المعايرة
    │   │   └── 📄 providers.dart               # المزودات الرئيسية
    │   │
    │   ├── 📂 services/         # الخدمات الأساسية
    │   │   ├── 📄 camera_service.dart         # ✅ خدمة الكاميرا
    │   │   ├── 📄 guidance_manager.dart       # ✅ إدارة الإرشادات الصوتية
    │   │   ├── 📄 onnx_inference_service.dart # ✅ خدمة ONNX (استدلال AI)
    │   │   └── 📄 services.dart               # تصدير الخدمات
    │   │
    │   └── 📂 utils/            # أدوات مساعدة
    │       ├── 📄 geometry_utils.dart         # حسابات هندسية
    │       └── 📄 homography_utils.dart       # تحويلات المنظور
    │
    └── 📂 features/             # الميزات الرئيسية (معمارية Feature-First)
        │
        ├── 📂 calibration/      # ميزة المعايرة
        │   └── 📂 presentation/
        │       ├── 📂 screens/
        │       │   └── 📄 smart_calibration_screen.dart  # شاشة المعايرة
        │       └── 📂 widgets/
        │           ├── 📄 calibration_guide.dart         # دليل المعايرة
        │           └── 📄 polygon_overlay.dart           # تراكب المضلع
        │
        ├── 📂 capture/          # ميزة التقاط الصور
        │   └── 📂 presentation/
        │       └── 📂 screens/
        │           └── 📄 capture_screen.dart            # شاشة الالتقاط
        │
        └── 📂 results/          # ميزة عرض النتائج
            └── 📂 presentation/
                └── 📂 screens/
                    └── 📄 results_screen.dart            # شاشة النتائج
```

---

## 🔧 الملفات الرئيسية وشرحها

### 📱 التطبيق الرئيسي
| الملف | الوصف |
|-------|-------|
| `lib/main.dart` | نقطة دخول التطبيق، تهيئة Riverpod والمسارات |

### 🎯 الخدمات الأساسية
| الملف | الوصف | الحالة |
|-------|-------|--------|
| `camera_service.dart` | إدارة الكاميرا والتقاط الإطارات | ✅ نشط |
| `onnx_inference_service.dart` | استدلال AI باستخدام ONNX (كشف البطاقة) | ✅ نشط |
| `guidance_manager.dart` | التوجيه الصوتي للمستخدم (TTS) | ✅ نشط |

### 🧮 الأدوات المساعدة
| الملف | الوصف |
|-------|-------|
| `geometry_utils.dart` | حسابات هندسية (المسافات، الزوايا، إلخ) |
| `homography_utils.dart` | تحويلات المنظور والتحقق من صحة النقاط |

### 🎨 الواجهات (Features)
| الميزة | الشاشة | الوصف |
|--------|--------|-------|
| **Calibration** | `smart_calibration_screen.dart` | معايرة الجسم مع كشف البطاقة |
| **Capture** | `capture_screen.dart` | التقاط صور القياسات |
| **Results** | `results_screen.dart` | عرض نتائج القياسات |

---

## 📦 التبعيات الرئيسية

### Production Dependencies:
```yaml
flutter_riverpod: ^2.6.1      # إدارة الحالة
camera: ^0.10.6                # الكاميرا
onnxruntime: ^1.19.0           # استدلال AI (ONNX Runtime)
flutter_tts: ^3.8.5            # تحويل النص إلى كلام
image: ^4.1.3                  # معالجة الصور
vector_math: ^2.1.4            # عمليات رياضية متجهة
permission_handler: ^11.4.0    # أذونات التطبيق
path_provider: ^2.1.2          # الوصول إلى المسارات
```

### Dev Dependencies:
```yaml
flutter_lints: ^3.0.2         # قواعد Lint
build_runner: ^2.5.4          # مولد الكود
riverpod_generator: ^2.6.5    # توليد مزودات Riverpod
mockito: ^5.4.6               # مكتبة الاختبار
build_test: ^2.2.3            # اختبار البناء
```

---

## 🚀 نموذج AI المستخدم

### نموذج ONNX:
- **الملف:** `assets/models/card_detector.onnx`
- **النوع:** YOLOv8 Object Detection
- **الهدف:** كشف البطاقة والحواف (Card Corners)
- **الحجم:** ~6 MB
- **الدقة:** عالية (تم التدريب على بيانات مخصصة)
- **المصدر:** https://github.com/OsmanMohamad249/card-detection-yolo

### التصنيفات:
- **الملف:** `assets/models/labels.txt`
- يحتوي على تصنيفات الكائنات التي يمكن للنموذج اكتشافها

---

## 🏗️ معمارية التطبيق

### نمط التصميم:
- **Feature-First Architecture** - كل ميزة في مجلد مستقل
- **Provider Pattern** - باستخدام Riverpod لإدارة الحالة
- **Service Layer** - طبقة خدمات منفصلة للوظائف الأساسية
- **Clean Architecture** - فصل المنطق عن واجهة المستخدم

### تدفق البيانات:
```
UI (Screens) 
    ↓
Providers (State Management)
    ↓
Services (Business Logic)
    ↓
Utils (Helper Functions)
```

---

## ✅ الملفات التي تم إزالتها

### ❌ خدمات قديمة:
- `onnx_inference_service.dart` - تم استبداله بـ TFLite
- `tflite_service.dart.old` - نسخة قديمة

### ❌ أدوات غير مستخدمة:
- `tensor_data_fix.dart` - حلول مؤقتة
- `tflite_patch.dart` - تصحيحات مؤقتة

### ❌ مستندات قديمة:
- جميع ملفات `*.md` القديمة (25+ ملف)
- مجلد `docs/` بالكامل

### ❌ ملفات مؤقتة:
- جميع ملفات `*.log`
- جميع ملفات `*.ps1`, `*.py`, `*.txt`
- مجلدات `temp_tflite/`, `temp_tflite_extract/`

---

## 🎯 الحالة الحالية

| العنصر | الحالة |
|--------|--------|
| **البنية** | ✅ نظيفة ومنظمة |
| **التبعيات** | ✅ محدثة ومتوافقة |
| **نموذج AI** | ✅ TFLite جاهز |
| **الخدمات** | ✅ TFLite فقط (لا ONNX) |
| **الكود** | ✅ خالي من التعارضات |
| **الوثائق** | ✅ محدثة |

---

## 📝 ملاحظات مهمة

1. **TFLite فقط:**
   - تم إزالة ONNX Runtime بالكامل
   - الاستدلال يتم عبر TFLite فقط
   - أداء أفضل وحجم APK أصغر

2. **البنية النظيفة:**
   - لا توجد ملفات مكررة
   - لا توجد خدمات غير مستخدمة
   - كود واضح وسهل الصيانة

3. **جاهز للإنتاج:**
   - جميع الملفات الضرورية موجودة
   - التبعيات متوافقة
   - يمكن البناء مباشرة

---

**آخر تحديث:** 4 ديسمبر 2025  
**الحالة:** ✅ جاهز للتطوير والبناء

