import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// المخزون والأصول — تنبيهات النقص وحركة الأصناف (مطوّر من المقال §المخزون)
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final low = kInventory.where((i) => i.low).toList();
    const stockValue = 10800000.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: StatCard(Icons.inventory_2, 'عدد الأصناف', '${kInventory.length}')),
          Expanded(child: StatCard(Icons.paid, 'قيمة المخزون', money(stockValue), color: AppTheme.success)),
          Expanded(child: StatCard(Icons.warning_amber, 'تحت الحد الأدنى', '${low.length}', color: AppTheme.danger)),
          Expanded(child: StatCard(Icons.devices, 'أصول مؤمنة (عهدة)', '${kInventory.where((i) => i.isAsset).length}', color: AppTheme.purple)),
        ]),
        const SizedBox(height: 16),
        if (low.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.danger.withOpacity(.3)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.notification_important, color: AppTheme.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'تنبيه تلقائي: ${low.map((l) => l.item).join(' • ')} — أطلق طلب شراء قبل النفاد',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.danger))),
              PrimaryButton('طلب شراء', icon: Icons.shopping_cart, onPressed: () {}),
            ]),
          ),
        const SizedBox(height: 16),
        SectionCard('الأصناف والكميات',
            actionLabel: 'صنف جديد',
            onAction: () {},
            child: SimpleTable(columns: const ['الصنف', 'التصنيف', 'المتوفر', 'الحد الأدنى', 'تكلفة الوحدة', 'الحالة', ''],
              rows: [
                for (final i in kInventory)
                  [
                    Text(i.item, style: const TextStyle(fontWeight: FontWeight.bold)),
                    StatusChip(i.category, color: AppTheme.seed),
                    Text('${i.qty}'),
                    Text('${i.min}'),
                    Text(money(i.unitCost)),
                    i.low
                        ? const StatusChip('تحت الحد', color: AppTheme.danger)
                        : const StatusChip('سليم', color: AppTheme.success),
                    Icon(i.isAsset ? Icons.verified_user : Icons.swap_horiz, size: 17, color: AppTheme.textSub),
                  ],
              ])),
      ]),
    );
  }
}
