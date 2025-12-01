# الخطة التقنية المحسَّنة — رحلة القياس الذكي (الإصدار v8 - Zero-Touch)

> **الهدف:** تحقيق أتمتة كاملة (Zero-Touch) بدقة قياس مستهدفة **99.98%**. لا يتم إرسال أي صور إلى السيرفر. يتم تنفيذ الرؤية الحاسوبية بالكامل على الجهاز (Edge AI).

## 1) المكدس التقني (Tech Stack)
- **Framework:** Flutter SDK
- **AI Model:** YOLOv8 Nano Pose (TFLite) - مدرب خصيصاً لكشف زوايا البطاقة.
- **Math Engine:** `vector_math` + `image` (لتصحيح المنظور Homography).
- **State Management:** Riverpod.
- **Guidance:** flutter_tts (توجيه صوتي تفاعلي).

## 2) الخوارزمية الجوهرية (Core Logic)
1.  **المعايرة الذكية (Smart Calibration):**
    - كشف زوايا البطاقة (حتى لو مائلة).
    - تطبيق **Perspective Correction** هندسياً.
    - حساب `mm_per_pixel` بدقة متناهية.
2.  **تتبع الجسم (Body Tracking):**
    - استخراج نقاط الجسم وتطبيق فلتر تنعيم (Smoothing).
3.  **البيانات (Payload):**
    - إرسال `Landmarks` + `Scale Factor` فقط للسيرفر.
