# الخطة التقنية المحسَّنة — رحلة القياس الذكي (الإصدار v8 - Zero-Touch)

> **الهدف:** تحقيق أتمتة كاملة (Zero-Touch) بدقة قياس مستهدفة **99.98%**، مع التزام صارم بعدم إرسال أي صورة إلى السيرفر. جميع مهام الرؤية الحاسوبية تنفَّذ على الجهاز (Edge AI) باستخدام YOLOv8 Nano Pose وتصحيح Homography.

## 1) المكدس التقني (Tech Stack)
- **Framework:** Flutter SDK
- **AI Model:** YOLOv8 Nano Pose (TFLite) - مدرَّب خصيصاً لكشف زوايا البطاقة.
- **Math Engine:** `vector_math` + `image` (لتصحيح المنظور وتوليد Homography).
- **State Management:** Riverpod + Riverpod Generator.
- **Guidance:** flutter_tts (توجيه صوتي تفاعلي يحافظ على Zero-Touch).
- **Device Ops:** `permission_handler`, `path_provider` لضبط التخزين والصلاحيات.

## 2) الخوارزمية الجوهرية (Core Logic)
1.  **المعايرة الذكية (Smart Calibration):**
    - التقاط زوايا البطاقة حتى لو كانت مائلة بواسطة YOLOv8 Nano Pose.
    - تطبيق **Homography/Perspective Correction** للحصول على بطاقة مسطحة.
    - حساب `mm_per_pixel` بدقة عالية انطلاقاً من العرض القياسي للبطاقة (85.60 مم).
2.  **تتبع الجسم (Body Tracking):**
    - استخراج نقاط الجسم (Landmarks) وتطبيق فلترة زمنية لمنع الاهتزاز.
    - التحقق من صلاحية شكل البطاقة قبل قبول النتائج لضمان Zero-Touch دقيق.
3.  **سياسة البيانات (Payload):**
    - عدم إرسال الصور إطلاقاً؛ يتم إرسال `Landmarks + Scale Factor` فقط إلى السيرفر لاستنتاج شبكة 3D.
