import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// الفواتير والأقساط والحسومات (§8.1، §8.2 من الوثيقة ⭐)
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const totalBilled = 1380000.0;
    const totalPaid = 1125000.0;
    final overdue = kInvoices.where((i) => i.status == 'متأخر').length;

    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(children: [
            Expanded(child: StatCard(Icons.receipt_long, 'إجمالي المفوتر', money(totalBilled))),
            Expanded(child: StatCard(Icons.point_of_sale, 'المحصّل', money(totalPaid), color: AppTheme.success)),
            Expanded(child: StatCard(Icons.hourglass_bottom, 'المتبقي', money(totalBilled - totalPaid), color: AppTheme.gold)),
            Expanded(child: StatCard(Icons.warning_amber, 'فواتير متأخرة', '$overdue', color: AppTheme.danger)),
          ]),
          const SizedBox(height: 16),
          // الفواتير
          SimpleTable(columns: const ['الطالب', 'الفاتورة', 'الإجمالي', 'المدفوع', 'المتبقي', 'الأقساط', 'الاستحقاق', 'الحالة', ''],
            rows: [
              for (final i in kInvoices)
                [
                  Text(i.student, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(i.number, style: const TextStyle(color: AppTheme.seed, fontWeight: FontWeight.bold)),
                  Text(money(i.total)),
                  Text(money(i.paid), style: const TextStyle(color: AppTheme.success)),
                  Text(money(i.total - i.paid), style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: i.total - i.paid > 0 ? AppTheme.danger : AppTheme.success)),
                  Text('${i.installments}'),
                  Text(i.due),
                  StatusChip(i.status, color: StatusChip.forStatus(i.status)),
                  const Icon(Icons.print, size: 18, color: AppTheme.textSub),
                ],
            ]),
          const SizedBox(height: 14),
          // تبويب الحسومات
          SectionCard('نظام الحسم المرن — دورة كاملة / مجموعة / طالب + نسبة ومدة',
              actionLabel: 'إضافة حسم',
              onAction: () {},
              child: SimpleTable(columns: const ['الحسم', 'النطاق', 'الهدف', 'النسبة', 'المدة / العدد', 'المانح'],
                rows: [
                  for (final d in kDiscounts)
                    [
                      Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      StatusChip(d.scope, color: AppTheme.purple),
                      Text(d.target),
                      Text('%${d.pct.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 14)),
                      Text(d.duration),
                      Text(d.by, style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
                    ],
                ])),
        ]),
      );
  }
}
