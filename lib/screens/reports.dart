import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// التقارير — نهاية كل جلسة وكورس (§8.4 من الوثيقة ⭐)
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionCard('تقرير نهاية جلسة — عينة حية: إنجليزي B2 (جلسة 8 من 24)',
            actionLabel: 'طباعة PDF',
            onAction: () {},
            child: Column(children: [
              Row(children: [
                Expanded(child: StatCard(Icons.check_circle, 'حاضروا الجلسة', '11', color: AppTheme.success)),
                Expanded(child: StatCard(Icons.cancel, 'غائبون', '1', color: AppTheme.danger)),
                Expanded(child: StatCard(Icons.payments, 'إيراد الجلسة', money(180000 / 1), color: AppTheme.seed)),
                Expanded(child: StatCard(Icons.engineering, 'استحقاق المدرس', money(30000), color: AppTheme.gold)),
              ]),
              const SizedBox(height: 14),
              SimpleTable(columns: const ['البند', 'القيمة'],
                rows: const [
                  [Text('المجموعة'), Text('إنجليزي B2 — مسائي أ', style: TextStyle(fontWeight: FontWeight.bold))],
                  [Text('المدرس'), Text('أ. سامر الحلبي')],
                  [Text('عدد الحضور / المسجلين'), Text('11 / 12')],
                  [Text('الإيراد المجمع للجلسة'), Text('7,500 ل.س لكل طالب × 12', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold))],
                  [Text('تكلفة المدرس للجلسة'), Text('15,000 ل.س', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold))],
                ]),
            ])),
        const SizedBox(height: 16),
        SectionCard('تقرير نهاية كورس — عينة: رياضيات تاسع (10 من 20 جلسة)',
            actionLabel: 'طباعة PDF',
            onAction: () {},
            child: Column(children: [
              Row(children: [
                Expanded(child: StatCard(Icons.group, 'الإشغال', '100%', color: AppTheme.danger)),
                Expanded(child: StatCard(Icons.trending_up, 'إيراد الكورس', money(224000), color: AppTheme.success)),
                Expanded(child: StatCard(Icons.school, 'تكلفة المدرس', money(180000), color: AppTheme.gold)),
                Expanded(child: StatCard(Icons.savings, 'صافي الكورس', money(44000), color: AppTheme.purple)),
              ]),
              const SizedBox(height: 14),
              SimpleTable(columns: const ['المؤشر', 'القيمة'],
                rows: const [
                  [Text('متوسط حضور المجموعة'), Text('86%', style: TextStyle(fontWeight: FontWeight.bold))],
                  [Text('متوسط درجات آخر كويز'), Text('76 / 100', style: TextStyle(fontWeight: FontWeight.bold))],
                  [Text('طلاب قائمة الانتظار'), Text('5 — مرشحون لمجموعة جديدة', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold))],
                  [Text('توصية النظام'), Text('فتح مجموعة ثانية مسائية بأ. محمد العلي أو مدرس مكمل', style: TextStyle(color: AppTheme.purple, fontWeight: FontWeight.bold))],
                ]),
            ])),
      ]),
    );
  }
}
