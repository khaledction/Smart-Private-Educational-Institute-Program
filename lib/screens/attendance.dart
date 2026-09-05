import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// الحضور والغياب — لكل مجموعة على حدة (§6 من الوثيقة ⭐)
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _group = kAttendance.first.group;

  @override
  Widget build(BuildContext context) {
    final a = kAttendance.firstWhere((x) => x.group == _group);
    final total = a.present + a.absent + a.late + a.excused;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.line)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _group,
                isExpanded: true,
                items: [for (final x in kAttendance) DropdownMenuItem(value: x.group, child: Text(x.group, style: const TextStyle(fontSize: 13)))],
                onChanged: (v) => setState(() => _group = v!),
              ),
            ),
          )),
          const SizedBox(width: 14),
          PrimaryButton('حفظ كشف اليوم', icon: Icons.save, onPressed: () {}),
          const SizedBox(width: 10),
          PrimaryButton('إشعار أولياء الأمور', icon: Icons.notifications_active, color: AppTheme.gold, onPressed: () {}),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: StatCard(Icons.group, 'المسجلون', '$total')),
          Expanded(child: StatCard(Icons.check_circle, 'حاضرون', '${a.present}', color: AppTheme.success)),
          Expanded(child: StatCard(Icons.cancel, 'غائبون', '${a.absent}', color: AppTheme.danger)),
          Expanded(child: StatCard(Icons.schedule, 'متأخرون', '${a.late}', color: AppTheme.gold)),
          Expanded(child: StatCard(Icons.medical_services, 'بعذر', '${a.excused}', color: AppTheme.purple)),
        ]),
        const SizedBox(height: 18),
        SectionCard('كشف الحضور — جلسة اليوم', child: SimpleTable(
          columns: const ['الطالب', 'وسيلة التسجيل', 'الحالة', 'تغيير'],
          rows: [
            for (final s in kStudents.take(6))
              [
                Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text('رابط ذكي', style: TextStyle(fontSize: 12, color: AppTheme.textSub)),
                StatusChip(s.attendanceAvg >= 80 ? 'حاضر' : 'غائب',
                    color: s.attendanceAvg >= 80 ? AppTheme.success : AppTheme.danger),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final (lbl, c) in [('حاضر', AppTheme.success), ('غائب', AppTheme.danger), ('متأخر', AppTheme.gold)])
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: c.withOpacity(.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: c.withOpacity(.3))),
                          child: Text(lbl, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c)),
                        ),
                      ),
                    ),
                ]),
              ],
          ])),
      ]),
    );
  }
}
