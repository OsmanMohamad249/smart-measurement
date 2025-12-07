# 🚀 دليل الاستخدام السريع - Smart Measurement

## ⚠️ المشاكل الشائعة والحلول

### مشكلة 1: Flutter غير موجود في PATH

إذا ظهرت لك رسالة الخطأ:
```
flutter : The term 'flutter' is not recognized as the name of a cmdlet...
```

### مشكلة 2: إصدار Dart SDK قديم

إذا ظهرت لك رسالة الخطأ:
```
Because smart_measurement depends on build_test >=2.2.3 which requires SDK version >=3.6.0 <4.0.0, version solving failed.
```

**الحل:**
```powershell
# تحديث Flutter SDK إلى أحدث إصدار
C:\src\flutter\bin\flutter.bat upgrade

# ثم تثبيت التبعيات
C:\src\flutter\bin\flutter.bat pub get
```

---

## ✅ الحلول المتاحة:

### الحل 1: استخدام المسار الكامل (موصى به للاستخدام السريع)

بدلاً من كتابة `flutter`، استخدم المسار الكامل:

```powershell
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat clean
C:\src\flutter\bin\flutter.bat run
C:\src\flutter\bin\flutter.bat build apk --release
```

#### مثال:
```powershell
# بدلاً من:
flutter pub get

# استخدم:
C:\src\flutter\bin\flutter.bat pub get
```

---

### الحل 2: إضافة Flutter إلى PATH مؤقتاً (للجلسة الحالية فقط)

في نفس نافذة PowerShell، نفذ:

```powershell
$env:PATH = "C:\src\flutter\bin;$env:PATH"
```

بعد ذلك يمكنك استخدام أوامر Flutter عادياً:
```powershell
flutter pub get
flutter run
flutter build apk
```

⚠️ **ملاحظة:** هذا الحل مؤقت فقط للجلسة الحالية!

---

### الحل 3: استخدام السكريبتات المساعدة (الأسهل)

#### أ. للتثبيت السريع للتبعيات:
```powershell
.\pub-get.ps1
```

#### ب. للوصول إلى قائمة كاملة:
```powershell
.\flutter-helper.ps1
```

سيعرض لك قائمة تفاعلية:
```
1. flutter pub get        - تثبيت التبعيات
2. flutter clean          - تنظيف المشروع
3. flutter analyze        - تحليل الكود
4. flutter run            - تشغيل التطبيق
5. flutter build apk      - بناء APK (Debug)
6. flutter build apk --release - بناء APK (Release)
7. flutter doctor         - فحص إعدادات Flutter
8. الكل (clean + pub get + analyze)
```

---

### الحل 4: إضافة Flutter إلى PATH بشكل دائم (مستحسن)

#### الخطوات:

1. **افتح System Environment Variables:**
   - اضغط `Win + R`
   - اكتب: `sysdm.cpl`
   - اضغط Enter

2. **انتقل إلى Environment Variables:**
   - علامة التبويب "Advanced"
   - انقر "Environment Variables..."

3. **عدّل متغير Path:**
   - في "User variables" أو "System variables"
   - ابحث عن متغير `Path`
   - انقر "Edit..."

4. **أضف مسار Flutter:**
   - انقر "New"
   - أضف: `C:\src\flutter\bin`
   - انقر "OK" على جميع النوافذ

5. **أعد تشغيل PowerShell**

6. **تحقق من التثبيت:**
   ```powershell
   flutter --version
   ```

---

## 🎯 الأوامر الشائعة

### تثبيت التبعيات:
```powershell
C:\src\flutter\bin\flutter.bat pub get
```

### تنظيف المشروع:
```powershell
C:\src\flutter\bin\flutter.bat clean
```

### تحليل الكود:
```powershell
C:\src\flutter\bin\flutter.bat analyze
```

### تشغيل التطبيق:
```powershell
C:\src\flutter\bin\flutter.bat run
```

### بناء APK (Release):
```powershell
C:\src\flutter\bin\flutter.bat build apk --release
```

### فحص إعدادات Flutter:
```powershell
C:\src\flutter\bin\flutter.bat doctor -v
```

---

## 📝 سير العمل الموصى به

### 1. التحضير الأولي:
```powershell
# أضف Flutter للجلسة الحالية
$env:PATH = "C:\src\flutter\bin;$env:PATH"

# تنظيف وتثبيت
flutter clean
flutter pub get
flutter analyze
```

### 2. التطوير:
```powershell
# تشغيل على الجهاز
flutter run

# أو استخدم Hot Reload في الـ IDE
```

### 3. البناء للإصدار:
```powershell
# بناء APK
flutter build apk --release

# الملف سيكون في:
# build\app\outputs\flutter-apk\app-release.apk
```

---

## 🔧 استكشاف الأخطاء

### إذا فشل `flutter pub get`:
```powershell
# 1. تنظيف المشروع
flutter clean

# 2. حذف ملف pubspec.lock
Remove-Item pubspec.lock -ErrorAction SilentlyContinue

# 3. إعادة المحاولة
flutter pub get
```

### إذا ظهرت أخطاء في التحليل:
```powershell
# تشغيل التحليل الشامل
flutter analyze

# قراءة الأخطاء وإصلاحها واحداً تلو الآخر
```

### إذا فشل البناء:
```powershell
# 1. تنظيف شامل
flutter clean

# 2. حذف مجلدات Gradle
Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue

# 3. إعادة التثبيت والبناء
flutter pub get
flutter build apk --release
```

---

## 📚 موارد إضافية

- **التوثيق الرسمي:** https://flutter.dev/docs
- **أوامر Flutter CLI:** https://flutter.dev/docs/reference/flutter-cli
- **بنية المشروع:** راجع `PROJECT_STRUCTURE.md`
- **ملخص التنظيف:** راجع `CLEANUP_SUMMARY.md`

---

## ⚡ نصائح سريعة

### اختصار PowerShell:
أضف هذه الدالة في ملف PowerShell Profile الخاص بك:

```powershell
function fl {
    C:\src\flutter\bin\flutter.bat $args
}
```

بعد ذلك يمكنك استخدام:
```powershell
fl pub get
fl run
fl build apk --release
```

### للبحث عن ملف Profile:
```powershell
$PROFILE
```

---

**آخر تحديث:** 4 ديسمبر 2025  
**الحالة:** ✅ جاهز للاستخدام

