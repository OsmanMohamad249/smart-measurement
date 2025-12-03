# 🔧 حل مشكلة Out of Memory أثناء البناء

## ❌ المشكلة

عند محاولة بناء التطبيق، يظهر الخطأ التالي:
```
Out of memory.
There is insufficient memory for the Java Runtime Environment to continue.
Native memory allocation (malloc) failed to allocate 227616 bytes.
The Dart compiler exited unexpectedly.
```

### الأسباب المحتملة:
1. **Gradle يستخدم ذاكرة كبيرة جداً** (كان مضبوط على 8GB)
2. **عمليات Dart/Gradle سابقة لا تزال تعمل** في الخلفية
3. **ذاكرة النظام غير كافية** بسبب تطبيقات أخرى مفتوحة
4. **ملفات cache قديمة** تستهلك الذاكرة

---

## ✅ الحلول المُطبّقة

### 1. تنظيف ملفات البناء السابقة
```bash
flutter clean
```

### 2. تحديث إعدادات Gradle للذاكرة
**الملف:** `android/gradle.properties`

**قبل:**
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G
```

**بعد:**
```properties
org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
org.gradle.daemon=true
org.gradle.parallel=false
```

**الفرق:**
- خفض الذاكرة من 8GB إلى 2GB
- خفض MetaSpace من 4GB إلى 512MB
- تعطيل البناء المتوازي لتوفير الذاكرة

### 3. إيقاف العمليات المعلقة
```powershell
# إيقاف جميع عمليات Java/Gradle/Dart
Get-Process | Where {$_.ProcessName -like "*java*"} | Stop-Process -Force
```

### 4. حذف ملفات الخطأ القديمة
```powershell
Remove-Item android/hs_err_pid*.log
Remove-Item android/replay_pid*.log
```

---

## 🚀 طريقة البناء الموصى بها

### الخيار 1: بناء APK مباشرة (أقل استهلاك للذاكرة)
```bash
flutter clean
flutter pub get
flutter build apk --debug --no-tree-shake-icons
```

ثم تثبيت يدوياً:
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### الخيار 2: Hot Restart بدلاً من Hot Reload
```bash
flutter run --no-fast-start
```

### الخيار 3: إذا استمرت المشكلة - أغلق التطبيقات الأخرى
قبل البناء، أغلق:
- المتصفحات (Chrome, Edge)
- Android Studio / VS Code (إذا كانت مفتوحة)
- التطبيقات الثقيلة الأخرى

---

## 📝 نصائح لتجنب المشكلة مستقبلاً

### 1. استخدم Flutter في Release Mode للاختبار النهائي
```bash
flutter build apk --release
```
يستخدم ذاكرة أقل من Debug mode.

### 2. زد ذاكرة Windows Virtual Memory
- `Settings` → `System` → `About` → `Advanced system settings`
- `Performance` → `Settings` → `Advanced` → `Virtual Memory`
- اضبط على "Automatically manage" أو زد الحجم يدوياً

### 3. نظّف Cache بشكل دوري
```bash
flutter clean
flutter pub cache repair
```

### 4. راقب استهلاك الذاكرة
```powershell
# أثناء البناء، راقب:
Get-Process java,dart | Select ProcessName,WS
```

---

## 🔍 استكشاف الأخطاء

### إذا استمرت مشكلة الذاكرة:

**1. تحقق من ذاكرة النظام المتاحة:**
```powershell
Get-CimInstance Win32_OperatingSystem | Select FreePhysicalMemory,TotalVisibleMemorySize
```

**2. أعد تشغيل الكمبيوتر:**
هذا يحرر جميع الذاكرة المحجوزة من العمليات السابقة.

**3. قسّم البناء إلى خطوات:**
```bash
# بدلاً من flutter run، نفذ:
flutter pub get
flutter build bundle
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.smartmeasurement.app/.MainActivity
```

**4. استخدم build variants أخف:**
في `build.gradle.kts`:
```kotlin
buildTypes {
    debug {
        minifyEnabled = false
        shrinkResources = false
    }
}
```

---

## ⚙️ الإعدادات الموصى بها

### للأجهزة ذات الذاكرة المنخفضة (< 8GB RAM):
```properties
# android/gradle.properties
org.gradle.jvmargs=-Xmx1536M -XX:MaxMetaspaceSize=256m
org.gradle.daemon=true
org.gradle.parallel=false
org.gradle.configureondemand=false
```

### للأجهزة ذات الذاكرة المتوسطة (8-16GB RAM):
```properties
# android/gradle.properties
org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=512m
org.gradle.daemon=true
org.gradle.parallel=true
```

### للأجهزة ذات الذاكرة العالية (> 16GB RAM):
```properties
# android/gradle.properties
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.workers.max=4
```

---

## 📊 الحالة الحالية

✅ **تم تطبيق الإصلاحات:**
- خفض استهلاك ذاكرة Gradle إلى 2GB
- تنظيف ملفات البناء القديمة
- إيقاف العمليات المعلقة

🔄 **الخطوة التالية:**
محاولة البناء مرة أخرى باستخدام:
```bash
flutter build apk --debug --no-tree-shake-icons
```

---

**التاريخ:** 3 ديسمبر 2025  
**الحالة:** 🔧 قيد المعالجة  
**التقدم:** 50% (Smart Calibration مكتمل، في انتظار إصلاح مشكلة الذاكرة)

