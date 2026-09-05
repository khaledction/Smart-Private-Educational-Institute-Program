import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// لوحة القيادة الرئيسية — نظرة شاملة فورية (§9.2 من الوثيقة)
class DashboardScreen extends StatelessWidget {
  final void Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final activeStudents = kStudents.where((s) => s.status == 'نشط').length;
    final pendingReq = kRequests.where((r) => r.status == 'معلق').length;
    const waitingTotal = 8; // مجموع قوائم الانتظار الحالية
    const revenueMonth = 2700000.0;
    const overdue = 85000.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: StatCard(Icons.school, 'طلاب نشطون', '$activeStudents',
              trend: '+3 هذا الأسبوع')),
          Expanded(child: StatCard(Icons.auto_stories, 'مجموعات منطلقة',
              '${kGroups.where((g) => g.status == "running").length} / ${kGroups.length}',
              color: AppTheme.purple)),
          Expanded(child: StatCard(Icons.pending_actions, 'طلبات تسجيل معلقة', '$pendingReq',
              color: AppTheme.gold)),
          Expanded(child: StatCard(Icons.schedule_send, 'قوائم الانتظار', '$waitingTotal',
              color: AppTheme.danger)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: StatCard(Icons.payments, 'إيرادات أيلول', money(revenueMonth),
              color: AppTheme.success, trend: '+12% عن آب')),
          Expanded(child: StatCard(Icons.account_balance_wallet, 'مستحقات متأخرة', money(overdue),
              color: AppTheme.danger)),
          Expanded(child: StatCard(Icons.calendar_month, 'جلسات اليوم',
              '${kSessions.length}', color: AppTheme.purple)),
          Expanded(child: StatCard(Icons.inventory_2, 'أصناف تحت الحد',
              '${kInventory.where((i) => i.low).length}', color: AppTheme.gold)),
        ]),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: SectionCard('الإيرادات — آخر 6 أشهر (مليون ل.س)', child: BarsChart(kRevenueMonths)),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SectionCard('توزيع الطلاب على المواد', child: Row(children: [
              DonutChart(kSubjectDistribution, centerValue: '89', centerLabel: 'طالب'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (final (name, v, c) in kSubjectDistribution)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(name, style: const TextStyle(fontSize: 11.5))),
                          Text('$v', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                  ],
                ),
              ),
            ])),
          ),
        ]),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 2,
            child: SectionCard('تنبيهات ذكية',
                actionLabel: 'عرض الكل',
                onAction: () => onNavigate?.call(2),
                child: Column(children: [
                  for (final n in kNotifications.take(4))
                    _AlertTile(n),
                ])),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: SectionCard('إجراءات سريعة', child: Wrap(spacing: 10, runSpacing: 10, children: [
              PrimaryButton('طلب تسجيل جديد', icon: Icons.person_add_alt_1, onPressed: () => onNavigate?.call(2)),
              PrimaryButton('مجموعة جديدة', icon: Icons.add_circle, onPressed: () => onNavigate?.call(3), color: AppTheme.dark2),
              PrimaryButton('تسجيل حضور', icon: Icons.fact_check, onPressed: () => onNavigate?.call(6), color: AppTheme.success),
              PrimaryButton('سداد قسط', icon: Icons.point_of_sale, onPressed: () => onNavigate?.call(8), color: AppTheme.gold),
              PrimaryButton('إضافة صرفية', icon: Icons.receipt_long, onPressed: () => onNavigate?.call(9), color: AppTheme.purple),
            ])),
          ),
        ]),
      ]),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final NotificationItem n;
  const _AlertTile(this.n);

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (n.type) {
      'request' => (Icons.person_add_alt, AppTheme.seed),
      'waiting' => (Icons.schedule_send, AppTheme.purple),
      'payment' => (Icons.credit_card, AppTheme.gold),
      'stock' => (Icons.inventory_2, AppTheme.danger),
      _ => (Icons.warning_amber, AppTheme.danger),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark)),
          Text(n.body, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Text(n.time, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSub)),
      ]),
    );
  }
}
