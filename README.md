# Smart Measurement App 📏🎯

تطبيق Flutter متقدم لقياسات الجسم بدقة عالية باستخدام الذكاء الاصطناعي والكاميرا.

---

## ⚠️ مهم جداً: تثبيت Flutter SDK

**إذا ظهرت لك رسالة "flutter is not recognized":**

Flutter SDK غير مثبت على جهازك! يجب تثبيته أولاً:

### 🚀 الحل السريع:
```powershell
.\install-flutter.ps1 -AddToPath
```

**أو** راجع الدليل الكامل: [FLUTTER_INSTALLATION_REQUIRED.md](FLUTTER_INSTALLATION_REQUIRED.md)

---

---

## ✨ الميزات الرئيسية

### 🎯 معايرة ذكية (Smart Calibration)
- كشف تلقائي للبطاقة المرجعية باستخدام نموذج YOLOv8
- التحقق من صحة زوايا البطاقة الأربع
- إرشادات صوتية تفاعلية أثناء المعايرة
- تراكب مرئي لتوجيه المستخدم

### 📸 التقاط دقيق (Body Capture)
- التقاط صور الجسم من زوايا متعددة
- معالجة فورية للصور
- ضمان جودة الصورة

### 📊 عرض النتائج (Results Display)
- عرض القياسات بدقة عالية
- مقارنة النتائج بمرور الوقت
- واجهة سهلة الاستخدام

---

## 🚀 البدء السريع

### المتطلبات الأساسية:
- **Flutter SDK:** 3.0.0 أو أحدث
- **Android Studio** أو **VS Code**
- **جهاز اختبار:** Android (API 26+) أو iOS

### التثبيت والتشغيل:

```bash
# 1. استنساخ المشروع
git clone https://github.com/your-username/smart-measurement.git
cd smart-measurement

# 2. تثبيت التبعيات
flutter pub get

# 3. تشغيل التطبيق
flutter run

# 4. (اختياري) بناء APK للإصدار
flutter build apk --release
```

### ⚠️ إذا ظهرت مشكلة "flutter is not recognized":

استخدم المسار الكامل لـ Flutter:

```powershell
# Windows PowerShell
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat run
```

**أو** أضف Flutter للجلسة الحالية:

```powershell
$env:PATH = "C:\src\flutter\bin;$env:PATH"
flutter pub get
```

📖 **للتفاصيل الكاملة:** راجع [FLUTTER_USAGE_GUIDE.md](FLUTTER_USAGE_GUIDE.md)

---

## 🏗️ البنية المعمارية

### التقنيات المستخدمة:
- **Frontend:** Flutter (Dart)
- **State Management:** Riverpod 2.6.1
- **AI/ML:** ONNX Runtime (YOLOv8 للكشف عن البطاقة)
- **Camera:** Camera Plugin 0.10.6
- **TTS:** Flutter TTS 3.8.5
- **Image Processing:** Image Package 4.1.3

### نمط التصميم:
- **Feature-First Architecture**
- **Provider Pattern** (Riverpod)
- **Service Layer Pattern**
- **Clean Architecture Principles**

للحصول على وصف تفصيلي للبنية، راجع: [📁 PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)

---

## 📦 التبعيات الرئيسية

| المكتبة | الإصدار | الاستخدام |
|---------|---------|------------|
| `flutter_riverpod` | 2.6.1 | إدارة الحالة |
| `camera` | 0.10.6 | الكاميرا |
| `onnxruntime` | 1.19.0 | استدلال AI (ONNX) |
| `flutter_tts` | 3.8.5 | تحويل النص إلى كلام |
| `image` | 4.1.3 | معالجة الصور |
| `vector_math` | 2.1.4 | عمليات رياضية |
| `permission_handler` | 11.4.0 | أذونات التطبيق |

---

## 🤖 نموذج AI

### YOLOv8 Card Detection Model:
- **النوع:** Object Detection
- **الصيغة:** ONNX
- **الحجم:** ~12 MB
- **الوظيفة:** كشف البطاقة المرجعية وزواياها الأربع
- **المصدر:** [card-detection-yolo](https://github.com/OsmanMohamad249/card-detection-yolo)
- **الموقع:** `assets/models/card_detector.onnx`

---

## 📂 هيكل المشروع

```
lib/
├── main.dart                     # نقطة الدخول
│
├── core/                         # الوظائف الأساسية
│   ├── providers/               # مزودات Riverpod
│   ├── services/                # خدمات (Camera, ONNX, TTS)
│   └── utils/                   # أدوات مساعدة
│
└── features/                    # الميزات (Feature-First)
    ├── calibration/            # ميزة المعايرة
    ├── capture/                # ميزة الالتقاط
    └── results/                # ميزة النتائج
```

---

## 🧹 حالة المشروع

### ✅ تم التنظيف:
- ✅ استخدام ONNX Runtime للاستدلال
- ❌ حذف جميع الملفات المؤقتة والقديمة
- ❌ إزالة المستندات المكررة (25+ ملف)
- ✅ بنية نظيفة ومنظمة

للتفاصيل الكاملة، راجع: [🧹 CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md)

---

## 🛠️ الأوامر المفيدة

```bash
# تحديث التبعيات
flutter pub get

# تنظيف المشروع
flutter clean

# تحليل الكود
flutter analyze

# تشغيل الاختبارات
flutter test

# بناء APK (Debug)
flutter build apk --debug

# بناء APK (Release)
flutter build apk --release

# بناء AAB (Google Play)
flutter build appbundle --release
```

---

## 📱 الأذونات المطلوبة

### Android (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS (`Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>هذا التطبيق يحتاج إلى الكاميرا لالتقاط صور القياسات</string>
```

---

## 🎯 خارطة الطريق

- [x] ✅ معايرة ذكية مع كشف البطاقة
- [x] ✅ كشف نقاط الجسم الرئيسية (Pose Detection)
- [x] ✅ إرشادات صوتية تفاعلية
- [ ] ⏳ حساب القياسات الدقيقة
- [ ] ⏳ حفظ واسترجاع النتائج
- [ ] ⏳ مقارنة القياسات بمرور الوقت
- [ ] ⏳ تصدير التقارير (PDF)

---

## 🐛 الإبلاغ عن المشاكل

إذا واجهت أي مشكلة، يرجى:
1. التحقق من [CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md) للملفات المحذوفة
2. التحقق من [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) للبنية الصحيحة
3. فتح Issue على GitHub مع:
   - وصف المشكلة
   - خطوات إعادة إنتاج المشكلة
   - رسائل الخطأ
   - معلومات البيئة (Flutter version, OS, etc.)

---

## 📄 الترخيص

هذا المشروع مرخص تحت رخصة [COPYRIGHT](Copyright).

---

## 👨‍💻 المساهمة

المساهمات مرحب بها! يرجى:
1. عمل Fork للمشروع
2. إنشاء فرع جديد (`git checkout -b feature/amazing-feature`)
3. تنفيذ التغييرات (`git commit -m 'Add amazing feature'`)
4. رفع التغييرات (`git push origin feature/amazing-feature`)
5. فتح Pull Request

---

## 📞 التواصل

للأسئلة أو الاستفسارات، يمكنك التواصل عبر:
- **GitHub Issues:** [فتح Issue](https://github.com/your-username/smart-measurement/issues)
- **Email:** your-email@example.com

---

**آخر تحديث:** 4 ديسمبر 2025  
**الحالة:** ✅ جاهز للتطوير والبناء  
**الإصدار:** 1.0.0+1

---

**صنع بـ ❤️ باستخدام Flutter & AI**

