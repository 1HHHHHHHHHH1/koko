# VentureBridge 🤝

تطبيق Flutter لربط رواد الأعمال بالمستثمرين — مدعوم بـ **Supabase**

---

## 🚀 تشغيل المشروع في 3 خطوات فقط

### الخطوة 1 — أنشئ مشروع Supabase مجاني
1. افتح [supabase.com](https://supabase.com) → **New Project**
2. اذهب إلى **Settings → API**
3. انسخ:
   - **Project URL**
   - **anon public key**

### الخطوة 2 — ضع بياناتك في ملف واحد
افتح `lib/core/constants/supabase_constants.dart` وعدّل سطرَين فقط:

```dart
static const String supabaseUrl    = 'https://xxxx.supabase.co';  // ← غيّر هذا
static const String supabaseAnonKey = 'eyJ...';                    // ← وهذا
```

### الخطوة 3 — أنشئ قاعدة البيانات
1. افتح **Supabase → SQL Editor → New query**
2. الصق محتوى ملف `supabase_schema.sql` كاملاً
3. اضغط **RUN** ✅

### الخطوة 4 — شغّل التطبيق
```bash
flutter pub get
flutter run
```

---

## 📁 هيكل المشروع

```
lib/
├── main.dart                          # نقطة البداية + تهيئة Supabase
├── app.dart                           # MaterialApp + Router
├── core/
│   ├── constants/
│   │   ├── supabase_constants.dart    # 🔑 ضع هنا URL و AnonKey
│   │   └── app_constants.dart        # ثوابت التطبيق
│   ├── supabase/
│   │   ├── supabase_service.dart     # كل عمليات DB (بديل ApiService)
│   │   └── supabase_client_provider.dart
│   ├── router/
│   │   └── app_router.dart           # التنقل + حماية الصفحات
│   └── theme/
│       └── app_theme.dart
├── models/                            # User, Project, Investor, ...
├── providers/                         # Riverpod state management
│   ├── auth_provider.dart
│   ├── project_provider.dart
│   ├── investor_provider.dart
│   ├── match_provider.dart
│   ├── likes_provider.dart
│   ├── ratings_provider.dart
│   ├── search_provider.dart
│   └── messaging_provider.dart       # Realtime chat ⚡
├── features/
│   ├── auth/                          # Login, Register, Splash
│   ├── dashboard/                     # Entrepreneur & Investor dashboards
│   ├── browse/                        # Projects, Investors, Detail, Profile
│   ├── messaging/                     # Conversations, Chat (Realtime)
│   ├── search/                        # Search screen
│   └── likes/                         # My Likes
└── widgets/
    ├── cards/                         # ProjectCard, InvestorCard, MatchCard
    └── common/                        # AppDrawer, RatingDisplay
```

---

## ⚡ مميزات Supabase المستخدمة

| الميزة | الاستخدام |
|--------|-----------|
| **Auth** | تسجيل الدخول/إنشاء حساب + حفظ الجلسة تلقائياً |
| **Database** | جميع جداول البيانات |
| **Row Level Security** | حماية بيانات كل مستخدم |
| **Realtime** | الرسائل الفورية في شاشة الدردشة |
| **Storage** | صور البروفايل وملفات pitch deck |

---

## 🔧 إعداد Supabase Dashboard الإضافي

### Redirect URL (مطلوب للـ Email Confirmation)
في **Authentication → URL Configuration** أضف:
```
io.supabase.venturebridge://login-callback
```

### Storage Buckets (اختياري)
في **Storage** أنشئ:
- `avatars` → Public
- `pitch-decks` → Private

---

## 📦 المكتبات المستخدمة

```yaml
supabase_flutter: ^2.5.6    # Backend كامل
flutter_riverpod: ^2.5.1    # State management
go_router: ^14.2.0          # Navigation
equatable: ^2.0.5           # Models
flutter_rating_bar: ^4.0.1  # Rating widget
cached_network_image: ^3.3.1 # تحميل الصور
intl: ^0.19.0               # التواريخ
image_picker: ^1.1.2        # رفع الصور
```
