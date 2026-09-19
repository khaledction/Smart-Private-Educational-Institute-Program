import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// الجدولة والجلسات — شبكة أسبوعية: 6 أيام × 3 فترات (صباحي/ظهر/مسائي)
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  Color _perColor(String p) => p == 'صباحي'
      ? const Color(0xFFB45309)
      : (p == 'ظهر' ? const Color(0xFF0F766E) : const Color(0xFF4338CA));
  Color _perBg(String p) => p == 'صباحي'
      ? const Color(0xFFFFF7ED)
      : (p == 'ظهر' ? const Color(0xFFF0FDFA) : const Color(0xFFEEF2FF));
  Color _perBorder(String p) => p == 'صباحي'
      ? const Color(0xFFFDBA74)
      : (p == 'ظهر' ? const Color(0xFF5EEAD4) : const Color(0xFFA5B4FC));
  String _perIcon(String p) => p == 'صباحي' ? '☀' : (p == 'ظهر' ? '🌤' : '🌙');

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(24), children: [
      Container(
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.success.withOpacity(.25)),
        ),
        padding: const EdgeInsets.all(14),
        child: const Row(children: [
          Icon(Icons.verified_user, color: AppTheme.success, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(
            'محرك منع التعارض مفعّل: المدرس × القاعة × المجموعة × توفر المدرس — لا يمكن حفظ أي جدولة متعارضة',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.success))),
        ]),
      ),
      const SizedBox(height: 18),
      // رأس الأعمدة
      Row(children: [
        const SizedBox(width: 84),
        Expanded(child: Center(child: Text('☀ الفترة الصباحية',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFFB45309))))),
        const SizedBox(width: 8),
        Expanded(child: Center(child: Text('🌤 فترة الظهر',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F766E))))),
        const SizedBox(width: 8),
        Expanded(child: Center(child: Text('🌙 الفترة المسائية',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF4338CA))))),
      ]),
      const SizedBox(height: 10),
      // صفوف الأيام
      for (var d = 0; d < kWeekDays.length; d++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            height: 96,
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(width: 84, child: Center(child: Text(kWeekDays[d],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.dark2)))),
              Expanded(child: _cell(kSessions.where((s) => s.day == d && s.period == 'صباحي').toList(), 'صباحي')),
              const SizedBox(width: 8),
              Expanded(child: _cell(kSessions.where((s) => s.day == d && s.period == 'ظهر').toList(), 'ظهر')),
              const SizedBox(width: 8),
              Expanded(child: _cell(kSessions.where((s) => s.day == d && s.period == 'مسائي').toList(), 'مسائي')),
            ]),
          ),
        ),
      const SizedBox(height: 18),
      SectionCard('جلسات اليوم — جاهزة لتسجيل الحضور',
          child: SimpleTable(columns: const ['المجموعة', 'الفترة', 'القاعة', 'الوقت', 'الحالة'],
            rows: [
              for (final s in kSessions.take(5))
                [
                  Text(s.group, style: const TextStyle(fontWeight: FontWeight.bold)),
                  PeriodBadge(s.period),
                  Text(s.room),
                  Text(s.time),
                  const StatusChip('قادمة', color: AppTheme.seed),
                ],
            ])),
    ]);
  }

  Widget _cell(List<SessionSlot> slots, String period) {
    if (slots.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.line.withOpacity(.6)),
        ),
        child: const Center(child: Text('—', style: TextStyle(color: AppTheme.textSub))),
      );
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _perBg(period).withOpacity(.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _perBorder(period).withOpacity(.5)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (final s in slots)
          Row(children: [
            Text(_perIcon(s.period), style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Expanded(child: Text(s.group,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.dark),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('${s.time} • ${s.room}', style: const TextStyle(fontSize: 9.5, color: AppTheme.textSub)),
          ]),
      ]),
    );
  }
}
