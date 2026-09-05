import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// الامتحانات والتقييم — تحديد المواعيد والدرجات (§7 من الوثيقة)
class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final upcoming = kExams.where((e) => e.status != 'منتهي').toList();
    final done = kExams.where((e) => e.status == 'منتهي').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: StatCard(Icons.quiz, 'امتحانات هذا الشهر', '${kExams.length}')),
          Expanded(child: StatCard(Icons.event_available, 'قادمة', '${upcoming.length}', color: AppTheme.gold)),
          Expanded(child: StatCard(Icons.verified, 'منتهية', '${done.length}', color: AppTheme.success)),
          Expanded(child: StatCard(Icons.workspace_premium, 'شهادات صدرت', '14', color: AppTheme.purple)),
        ]),
        const SizedBox(height: 18),
        SectionCard('الجدول القادم — تحديد الإدارة',
            actionLabel: 'امتحان جديد',
            onAction: () {},
            child: SimpleTable(columns: const ['الامتحان', 'المجموعة', 'النوع', 'التاريخ', 'الحالة'],
              rows: [
                for (final e in upcoming)
                  [
                    Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(e.group),
                    StatusChip(e.type, color: AppTheme.purple),
                    Text(e.date),
                    StatusChip(e.status, color: StatusChip.forStatus(e.status)),
                  ],
              ]),
        ),
        const SizedBox(height: 16),
        SectionCard('النتائج المنتهية', child: SimpleTable(
          columns: const ['الامتحان', 'المجموعة', 'النوع', 'التاريخ', 'المتوسط', 'الحالة'],
          rows: [
            for (final e in done)
              [
                Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(e.group),
                StatusChip(e.type, color: AppTheme.purple),
                Text(e.date),
                Text('${e.avg.toStringAsFixed(0)} / 100',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
                const StatusChip('منتهي', color: AppTheme.success),
              ],
          ]),
        ),
      ]),
    );
  }
}
