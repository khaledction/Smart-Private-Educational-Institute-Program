import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// التقارير v3.6 — تقارير الجلسة والكورس وفق السياسات المالية المعتمدة
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final english = kGroups.where((g) => g.name == 'إنجليزي B2 — مسائي أ').first;
    final math = kGroups.where((g) => g.name == 'رياضيات تاسع — مسائي').first;
    final englishSessionRevenue = english.enrolled * english.sessionUnitPrice;
    final englishSessionTeacher = english.teacherPct <= 0 ? 0 : englishSessionRevenue * english.teacherPct / 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionCard(
          'تقرير نهاية جلسة — عينة حية: ${english.name} (جلسة ${english.executedSessions} من ${english.sessionsTotal})',
          actionLabel: 'طباعة PDF',
          onAction: () {},
          child: Column(children: [
            Row(children: [
              Expanded(child: StatCard(Icons.check_circle, 'حاضروا الجلسة', '11', color: AppTheme.success)),
              Expanded(child: StatCard(Icons.cancel, 'غائبون', '1', color: AppTheme.danger)),
              Expanded(child: StatCard(Icons.payments, 'إيراد الجلسة المنفذة', money(englishSessionRevenue), color: AppTheme.seed)),
              Expanded(child: StatCard(Icons.engineering, 'مستحق المدرس للجلسة', money(englishSessionTeacher), color: AppTheme.gold)),
            ]),
            const SizedBox(height: 14),
            SimpleTable(columns: const ['البند', 'القيمة'], rows: [
              [const Text('المجموعة'), Text(english.name, style: const TextStyle(fontWeight: FontWeight.bold))],
              [const Text('المدرس'), Text(english.teacher)],
              [const Text('عدد الحضور / المسجلين'), const Text('11 / 12')],
              [const Text('الإيراد المعترف به للجلسة'), Text('${fmt(english.sessionUnitPrice)} ل.س لكل طالب × ${english.enrolled}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold))],
              [const Text('استحقاق المدرس للجلسة'), Text('%${english.teacherPct.toStringAsFixed(0)} × ${fmt(englishSessionRevenue)} = ${fmt(englishSessionTeacher)} ل.س', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))],
              [const Text('السياسة المطبقة'), const Text('لا يُصرف أي استحقاق قبل تنفيذ الجلسة فعليًا', style: TextStyle(color: AppTheme.purple, fontWeight: FontWeight.bold))],
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        SectionCard(
          'تقرير متابعة كورس — دفتر ثلاثي: ${math.name} (${math.executedSessions} من ${math.sessionsTotal} جلسة)',
          actionLabel: 'طباعة PDF',
          onAction: () {},
          child: Column(children: [
            Row(children: [
              Expanded(child: StatCard(Icons.request_quote, 'الإيراد التعاقدي', money(math.revenue), color: AppTheme.seed)),
              Expanded(child: StatCard(Icons.trending_up, 'الإيراد المحقق', money(math.accruedRevenue), color: AppTheme.success)),
              Expanded(child: StatCard(Icons.school, 'مستحق المدرس المنفذ', money(math.accruedTeacherComp), color: AppTheme.gold)),
              Expanded(child: StatCard(Icons.savings, 'صافي المعهد المحقق', money(math.instituteNetAccrued), color: AppTheme.purple)),
            ]),
            const SizedBox(height: 14),
            SimpleTable(columns: const ['المؤشر', 'القيمة'], rows: [
              [const Text('متوسط حضور المجموعة'), const Text('86%', style: TextStyle(fontWeight: FontWeight.bold))],
              [const Text('متوسط درجات آخر كويز'), const Text('76 / 100', style: TextStyle(fontWeight: FontWeight.bold))],
              [const Text('الإيراد المؤجل حتى استكمال الجلسات'), Text(money(math.deferredRevenue), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSub))],
              [const Text('الهامش الحالي للمعهد'), Text('%${math.instituteMarginPct.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: math.instituteMarginPct > 70 ? AppTheme.gold : AppTheme.success))],
              [const Text('طلاب قائمة الانتظار'), const Text('5 — مرشحون لمجموعة جديدة', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold))],
              [const Text('توصية النظام'), const Text('فتح مجموعة ثانية مسائية بأ. محمد العلي أو مدرس مكمل', style: TextStyle(color: AppTheme.purple, fontWeight: FontWeight.bold))],
            ]),
          ]),
        ),
      ]),
    );
  }
}
