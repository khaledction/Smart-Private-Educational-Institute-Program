import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// المحاسبة الكاملة — حساب لكل مادة/طالب/معلم/موظف + الصرفيات (§8.3، §8.4 ⭐)
class AccountingScreen extends StatelessWidget {
  const AccountingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const totalRevenue = 2096000.0;
    const totalCost = 900000.0;
    const totalExpenses = 1895000.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: StatCard(Icons.trending_up, 'إيرادات المواد', money(totalRevenue), color: AppTheme.success)),
            Expanded(child: StatCard(Icons.school, 'تكاليف المدرسين', money(totalCost), color: AppTheme.gold)),
            Expanded(child: StatCard(Icons.receipt_long, 'الصرفيات الشهر', money(totalExpenses), color: AppTheme.danger)),
            Expanded(child: StatCard(Icons.savings, 'صافي التشغيل', money(totalRevenue - totalCost - totalExpenses),
                color: AppTheme.purple)),
          ]),
          const SizedBox(height: 16),
          const SizedBox(height: 14),
          // حساب المواد
          SectionCard('ربحية كل مادة — إيراداتها − تكاليفها',
              child: SimpleTable(columns: const ['المادة', 'الإيرادات', 'تكلفة المدرسين', 'صافي الربح', 'الهامش'],
                rows: [
                  for (final s in kSubjectAccounts)
                    [
                      Text(s.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(money(s.revenue), style: const TextStyle(color: AppTheme.success)),
                      Text(money(s.cost), style: const TextStyle(color: AppTheme.danger)),
                      Text(money(s.net),
                          style: TextStyle(fontWeight: FontWeight.bold,
                              color: s.net > 0 ? AppTheme.success : AppTheme.danger)),
                      Text('%${(s.net / (s.revenue == 0 ? 1 : s.revenue) * 100).toStringAsFixed(0)}'),
                    ],
                ])),
          const SizedBox(height: 14),
          // المستخلصات
          SectionCard('مستخلصات المعلمين — استحقاق الجلسات',
              actionLabel: 'صرف مستخلص',
              onAction: () {},
              child: SimpleTable(columns: const ['المعلم', 'المستخلص', 'الإجمالي', 'الخصومات/السلف', 'الصافي', 'الحالة'],
                rows: [
                  for (final p in kTeacherPayouts)
                    [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(p.role),
                      Text(money(p.gross)),
                      Text(money(p.deductions), style: const TextStyle(color: AppTheme.danger)),
                      Text(money(p.net), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
                      StatusChip(p.status, color: StatusChip.forStatus(p.status)),
                    ],
                ])),
          const SizedBox(height: 14),
          // الرواتب
          SectionCard('رواتب الموظفين غير المعلمين',
              child: SimpleTable(columns: const ['الموظف', 'البيان', 'الراتب/البدلات', 'الخصومات', 'الصافي', 'الحالة'],
                rows: [
                  for (final p in kStaffPayouts)
                    [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(p.role),
                      Text(money(p.gross)),
                      Text(money(p.deductions)),
                      Text(money(p.net), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
                      StatusChip(p.status, color: StatusChip.forStatus(p.status)),
                    ],
                ])),
          const SizedBox(height: 14),
          // الصرفيات
          SectionCard('سجل الصرفيات — مصنفة ومرتبطة بالفرع',
              actionLabel: 'صرفية جديدة',
              onAction: () {},
              child: SimpleTable(columns: const ['التصنيف', 'البيان', 'المبلغ', 'التاريخ', 'بواسطة'],
                rows: [
                  for (final e in kExpenses)
                    [
                      StatusChip(e.category, color: AppTheme.seed),
                      Text(e.desc, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(money(e.amount), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                      Text(e.date),
                      Text(e.by, style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
                    ],
                ])),
        ]),
    );
  }
}
