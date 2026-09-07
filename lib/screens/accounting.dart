import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// المحاسبة v3.6 — اعتماد كل الحلول المالية:
/// 1) الاستحقاق بالجلسة المنفذة
/// 2) دفتر ثلاثي لكل دورة
/// 3) سقف نسبة المعلم ≤ 50% + Audit
/// 4) تنبيه عند هامش المعهد > 70%
/// 5) فصل المستحق عن المصروف
/// 6) قفل الدورة المالية عند الإغلاق
class AccountingScreen extends StatelessWidget {
  const AccountingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = kGroups.where((g) => g.status != 'pending').toList();
    final contractRevenue = groups.fold<double>(0.0, (s, g) => s + g.revenue);
    final accruedRevenue = groups.fold<double>(0.0, (s, g) => s + g.accruedRevenue);
    final accruedTeacher = groups.fold<double>(0.0, (s, g) => s + g.accruedTeacherComp);
    final paidTeacher = kCompNotices.fold<double>(0.0, (s, n) => s + n.paidAmount);
    final pendingTeacher = accruedTeacher - paidTeacher;
    final totalExpenses = kExpenses.fold<double>(0.0, (s, e) => s + e.amount);
    final operatingNet = accruedRevenue - accruedTeacher - totalExpenses;

    final revenueBySubject = <String, double>{};
    final costBySubject = <String, double>{};
    for (final g in groups) {
      revenueBySubject[g.subject] = (revenueBySubject[g.subject] ?? 0.0) + g.accruedRevenue;
      costBySubject[g.subject] = (costBySubject[g.subject] ?? 0.0) + g.accruedTeacherComp;
    }
    final subjects = {...revenueBySubject.keys, ...costBySubject.keys}.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: StatCard(Icons.request_quote, 'الإيراد التعاقدي', money(contractRevenue), color: AppTheme.seed)),
          Expanded(child: StatCard(Icons.trending_up, 'الإيراد المحقق', money(accruedRevenue), color: AppTheme.success)),
          Expanded(child: StatCard(Icons.payments, 'مستحق المدرسين المنفّذ', money(accruedTeacher), color: AppTheme.gold)),
          Expanded(child: StatCard(Icons.account_balance_wallet, 'المصروف فعليًا للمدرسين', money(paidTeacher), color: AppTheme.purple)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: StatCard(Icons.hourglass_top, 'قيد الصرف', money(pendingTeacher > 0 ? pendingTeacher : 0), color: AppTheme.gold)),
          Expanded(child: StatCard(Icons.history_toggle_off, 'إيراد مؤجل', money(contractRevenue - accruedRevenue), color: AppTheme.seed)),
          Expanded(child: StatCard(Icons.receipt_long, 'الصرفيات الشهر', money(totalExpenses), color: AppTheme.danger)),
          Expanded(child: StatCard(Icons.savings, 'صافي التشغيل', money(operatingNet), color: operatingNet >= 0 ? AppTheme.success : AppTheme.danger)),
        ]),
        const SizedBox(height: 16),

        SectionCard(
          'السياسات المالية المعتمدة — v3.6',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _PolicyPill('1', 'الاستحقاق بالجلسة المنفذة', AppTheme.seed),
              _PolicyPill('2', 'دفتر ثلاثي لكل دورة', AppTheme.purple),
              _PolicyPill('3', 'سقف نسبة المعلم ≤ 50%', AppTheme.success),
              _PolicyPill('4', 'تنبيه عندما يتجاوز هامش المعهد 70%', AppTheme.gold),
              _PolicyPill('5', 'فصل المستحق عن المصروف', AppTheme.danger),
              _PolicyPill('6', 'قفل الدورة المالية عند الإغلاق', AppTheme.dark2),
            ],
          ),
        ),
        const SizedBox(height: 14),

        SectionCard(
          'دفتر الدورة الثلاثي — تعاقدي / محقق / مصروف',
          child: SimpleTable(
            columns: const ['الدورة', 'النظام', 'التعاقدي', 'المحقق', 'مستحق المدرس', 'المصروف', 'المؤجل', 'القفل'],
            rows: [
              for (final g in groups)
                [
                  Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  StatusChip(g.system, color: g.isHoursSystem ? AppTheme.gold : AppTheme.seed),
                  Text(money(g.revenue)),
                  Text(money(g.accruedRevenue), style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                  Text(money(g.accruedTeacherComp), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                  Text(money(paidCompForCourse(g.name)), style: const TextStyle(color: AppTheme.purple, fontWeight: FontWeight.bold)),
                  Text(money(g.deferredRevenue), style: const TextStyle(color: AppTheme.textSub)),
                  StatusChip(g.financeLocked ? 'مقفلة' : 'مفتوحة', color: g.financeLocked ? AppTheme.dark2 : AppTheme.seed),
                ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        SectionCard(
          'إشعارات تعويض المدرسين — معتمد ≠ مصروف',
          actionLabel: 'تصريف كمستخلص شهري',
          onAction: () {},
          child: SimpleTable(
            columns: const ['التاريخ', 'المدرس', 'الدورة', 'جلسات منفذة', 'الطلاب', 'النسبة', 'المستحق', 'المصروف', 'المتبقي', 'الحالة'],
            rows: [
              for (final n in kCompNotices)
                [
                  Text(n.date),
                  Text(n.teacher, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(n.course),
                  Text('${n.hours}'),
                  Text('${n.students}'),
                  Text('%${n.pct.toStringAsFixed(0)}'),
                  Text(money(n.amount), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                  Text(money(n.paidAmount), style: const TextStyle(color: AppTheme.purple, fontWeight: FontWeight.bold)),
                  Text(money(n.pendingAmount), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                  StatusChip(n.status, color: n.status == 'مصروف' ? AppTheme.success : AppTheme.gold),
                ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        SectionCard(
          'ربحية كل مادة — على أساس الجلسات المنفذة فقط',
          child: SimpleTable(
            columns: const ['المادة', 'الإيراد المحقق', 'تكلفة المدرسين', 'صافي الربح', 'الهامش'],
            rows: [
              for (final subject in subjects)
                [
                  Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(money(revenueBySubject[subject] ?? 0.0), style: const TextStyle(color: AppTheme.success)),
                  Text(money(costBySubject[subject] ?? 0.0), style: const TextStyle(color: AppTheme.danger)),
                  Text(
                    money((revenueBySubject[subject] ?? 0.0) - (costBySubject[subject] ?? 0.0)),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dark),
                  ),
                  Text(
                    '%${_marginPct(revenueBySubject[subject] ?? 0.0, costBySubject[subject] ?? 0.0).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _marginPct(revenueBySubject[subject] ?? 0.0, costBySubject[subject] ?? 0.0) > 70
                          ? AppTheme.gold
                          : AppTheme.textSub,
                    ),
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        SectionCard(
          'سجل التدقيق المالي (Audit Log)',
          child: SimpleTable(
            columns: const ['الوقت', 'المستخدم', 'العملية', 'الهدف', 'التفاصيل'],
            rows: [
              for (final a in kAuditLog.take(8))
                [
                  Text(a.time),
                  Text(a.user, style: const TextStyle(fontWeight: FontWeight.bold)),
                  StatusChip(a.action, color: AppTheme.purple),
                  Text(a.target),
                  Text(a.details, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub)),
                ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        SectionCard(
          'مستخلصات المعلمين — استحقاق الجلسات المنفذة',
          actionLabel: 'صرف مستخلص',
          onAction: () {},
          child: SimpleTable(
            columns: const ['المعلم', 'المستخلص', 'الإجمالي', 'الخصومات/السلف', 'الصافي', 'الحالة'],
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
            ],
          ),
        ),
        const SizedBox(height: 14),

        SectionCard(
          'رواتب الموظفين غير المعلمين',
          child: SimpleTable(
            columns: const ['الموظف', 'البيان', 'الراتب/البدلات', 'الخصومات', 'الصافي', 'الحالة'],
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
            ],
          ),
        ),
        const SizedBox(height: 14),

        SectionCard(
          'سجل الصرفيات — مصنفة ومرتبطة بالفرع',
          actionLabel: 'صرفية جديدة',
          onAction: () {},
          child: SimpleTable(
            columns: const ['التصنيف', 'البيان', 'المبلغ', 'التاريخ', 'بواسطة'],
            rows: [
              for (final e in kExpenses)
                [
                  StatusChip(e.category, color: AppTheme.seed),
                  Text(e.desc, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(money(e.amount), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                  Text(e.date),
                  Text(e.by, style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
                ],
            ],
          ),
        ),
      ]),
    );
  }

  double _marginPct(double revenue, double cost) {
    if (revenue == 0) return 0.0;
    return ((revenue - cost) / revenue) * 100;
  }
}

class _PolicyPill extends StatelessWidget {
  final String index;
  final String text;
  final Color color;
  const _PolicyPill(this.index, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: color,
          child: Text(index, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}
