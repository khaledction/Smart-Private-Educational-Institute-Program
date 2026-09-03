# 🎓 Smart Private Educational Institute Program | نظام المعهد الذكي المتكامل

An **Educational ERP** built with Flutter — turning administrative chaos into a smart, smooth, error-free workflow.

نظام إدارة موارد تعليمية مبني بـ Flutter — يحوّل الفوضى الإدارية إلى نظام ذكي وسلس يقلّل الخطأ البشري.

**Bilingual (AR/EN with full RTL) • Riverpod • Supabase-ready • Material 3**

---

## ✨ Features | الميزات

| Feature | الميزة |
|---|---|
| 4-step Registration Wizard (POS & Reception) | معالج تسجيل من 4 خطوات (نقطة البيع والاستقبال) |
| Barcode identification (scanner types + Enter) | تعريف الطالب بالباركود (القارئ يكتب ويضغط Enter) |
| Smart teacher filtering per subject | فلترة ذكية للمدرسين حسب المادة |
| Capacity guard (full groups are locked) | حارس السعة (المجموعات الممتلئة تُقفل تلقائياً) |
| **Schedule conflict detection** | **كشف تعارض المواعيد بين مجموعات الطالب** |
| Price override per group (VIP groups) | سعر خاص لكل مجموعة (مجموعات VIP) |
| Discounts + partial payments + remaining balance | خصومات + دفعات جزئية + رصيد متبقٍ |
| Thermal-style receipt preview | معاينة إيصال بنمط الطابعة الحرارية |
| Analytics dashboard (revenue, top subjects/teachers) | لوحة تحكم (الإيرادات، أكثر المواد/المدرسين طلباً) |
| AR ⇄ EN toggle with full RTL | تبديل عربي ⇄ إنجليزي مع دعم RTL كامل |

## 🏗 Architecture | البنية

```
lib/
├── main.dart                     # Entry + Supabase init (commented)
├── core/
│   ├── providers.dart            # Riverpod providers + conflict detection
│   ├── strings.dart              # Bilingual AR/EN string table
│   └── theme.dart                # Material 3 theme
├── data/
│   ├── models/models.dart        # Student, Subject, Teacher, StudyGroup(TimeSlot), Registration
│   ├── seed_data.dart            # Demo data
│   └── repositories/
│       ├── institute_repository.dart   # Abstract contract
│       ├── mock_repository.dart        # In-memory (active by default)
│       └── supabase_repository.dart    # Supabase implementation
└── features/
    ├── shell/home_shell.dart     # NavigationRail + language toggle
    ├── registration/registration_wizard.dart  # ⭐ The 4-step Stepper
    ├── dashboard/dashboard_screen.dart
    ├── students/students_screen.dart
    ├── groups/groups_screen.dart
    └── receipts/receipts_screen.dart
supabase/schema.sql               # Full PostgreSQL schema + atomic register_student()
```

## 🚀 Run | التشغيل

```bash
flutter pub get
flutter run -d chrome     # or: windows / android
```

The app starts with **demo data (mock repository)** — no backend needed.

## 🔌 Connect Supabase | ربط قاعدة البيانات

1. Create a project at [supabase.com](https://supabase.com), then run `supabase/schema.sql` in the SQL Editor.
2. In `lib/main.dart` uncomment and fill:
   ```dart
   await Supabase.initialize(url: 'https://YOUR-PROJECT.supabase.co', anonKey: 'YOUR-ANON-KEY');
   ```
3. In `lib/core/providers.dart` swap one line:
   ```dart
   final repositoryProvider =
       Provider<InstituteRepository>((ref) => SupabaseInstituteRepository());
   ```

> السعة محمية داخل قاعدة البيانات نفسها عبر دالة `register_student()` بقفل صفّي (`FOR UPDATE`) — لا يمكن تجاوز سعة المجموعة حتى مع جهازي استقبال يعملان في نفس اللحظة.

## 🗺 Roadmap | الخطوات القادمة

- [ ] 🖨 Thermal printing via `esc_pos_utils` (hook ready in the receipt dialog)
- [ ] 📷 Camera barcode scanning via `mobile_scanner` (USB scanners already work)
- [ ] ✅ Smart attendance by barcode at classroom doors + parent notifications
- [ ] 👨‍👩‍👧 Parent portal (schedule, grades, payment status)
- [ ] 🏷 Sibling / early-bird discount codes
- [ ] 🔐 Role-based auth (admin / receptionist) with Supabase Auth + RLS

## 🧰 Stack

Flutter 3.35 • Dart 3.9 • flutter_riverpod 3 • supabase_flutter • intl • uuid • Material 3
