import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// التسجيل وقوائم الانتظار — قلب نظام الاختيار الحر (§3 من الوثيقة ⭐)
/// طلب الطالب (مادة + مدرس + فترة) → اعتماد الإدارة → قائمة انتظار المدرس
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, width: 380));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          decoration: cardDeco(),
          child: TabBar(
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(height: 46, text: 'طلبات التسجيل (${kRequests.length})'),
              Tab(height: 46, text: 'قوائم الانتظار (${kWaiting.length})'),
              Tab(height: 46, text: 'طلب جديد'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: TabBarView(children: [
            _RequestsTab(onSnack: _snack, refresh: () => setState(() {})),
            _WaitingTab(onSnack: _snack),
            _NewRequestTab(onSnack: _snack),
          ]),
        ),
      ]),
    );
  }
}

// ==================== تبويب الطلبات ====================
class _RequestsTab extends StatefulWidget {
  final void Function(String) onSnack;
  final VoidCallback refresh;
  const _RequestsTab({required this.onSnack, required this.refresh});

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        for (final r in kRequests)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: cardDeco(),
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(radius: 20, backgroundColor: AppTheme.purple.withOpacity(.1),
                child: const Icon(Icons.person_outline, color: AppTheme.purple, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.student, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                const SizedBox(height: 3),
                Text('يرغب بـ: ${r.subject}  •  المدرس: ${r.teacher}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
              ])),
              PeriodBadge(r.period),
              const SizedBox(width: 10),
              Text(r.date, style: const TextStyle(fontSize: 11, color: AppTheme.textSub)),
              const SizedBox(width: 10),
              if (r.status == 'معلق') ...[
                IconButton(
                  tooltip: 'اعتماد',
                  onPressed: () => setState(() { r.status = 'معتمد'; widget.onSnack('✅ تم الاعتماد وإشعار الطالب'); widget.refresh(); }),
                  icon: const Icon(Icons.check_circle, color: AppTheme.success),
                ),
                IconButton(
                  tooltip: 'رفض',
                  onPressed: () => setState(() { r.status = 'مرفوض'; widget.onSnack('تم الرفض مع إشعار الطالب'); widget.refresh(); }),
                  icon: const Icon(Icons.cancel, color: AppTheme.danger),
                ),
              ] else
                StatusChip(r.status, color: StatusChip.forStatus(r.status)),
            ]),
          ),
      ]),
    );
  }
}

// ==================== تبويب قوائم الانتظار ====================
class _WaitingTab extends StatefulWidget {
  final void Function(String) onSnack;
  const _WaitingTab({required this.onSnack});

  @override
  State<_WaitingTab> createState() => _WaitingTabState();
}

class _WaitingTabState extends State<_WaitingTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.gold.withOpacity(.3)),
          ),
          padding: const EdgeInsets.all(14),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppTheme.gold, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text(
              'قائمة انتظار لكل مدرس: عند اكتمال مجموعة المدرس المطلوب يوضع الطالب هنا تلقائيًا، وعند فتح مقعد يُشعَر أول القائمة فورًا — وإن بقيت المجموعة مكتملة يقترح النظام مدرسًا بديلًا.',
              style: TextStyle(fontSize: 12, color: AppTheme.gold, fontWeight: FontWeight.bold))),
          ]),
        ),
        const SizedBox(height: 14),
        SimpleTable(columns: const ['الطالب', 'المادة', 'المدرس المطلوب', 'الفترة', 'على الانتظار', 'إجراء'],
          rows: [
            for (final w in kWaiting)
              [
                Text(w.student, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(w.subject),
                Text(w.teacher),
                PeriodBadge(w.period),
                Text(w.since, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub)),
                ElevatedButton(
                  onPressed: () => widget.onSnack('🔔 سيُشعَر الطالب فور توفر مقعد لدى ${w.teacher}'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.seed.withOpacity(.1),
                      foregroundColor: AppTheme.seed,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12)),
                  child: const Text('إشعار عند التوفر', style: TextStyle(fontSize: 11.5)),
                ),
              ],
          ]),
      ]),
    );
  }
}

// ==================== تبويب طلب جديد ====================
class _NewRequestTab extends StatefulWidget {
  final void Function(String) onSnack;
  const _NewRequestTab({required this.onSnack});

  @override
  State<_NewRequestTab> createState() => _NewRequestTabState();
}

class _NewRequestTabState extends State<_NewRequestTab> {
  String? _student, _subject, _teacher;
  String _period = 'مسائي';

  @override
  Widget build(BuildContext context) {
    final teachersForSubject = kTeachers.where((t) => _subject == null || t.subject.contains(_subject!)).toList();
    final chosenGroup = kGroups.where((g) => g.teacher == _teacher && g.period == _period).toList();
    final full = chosenGroup.isNotEmpty && chosenGroup.first.seatsLeft <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: cardDeco(),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('طلب تسجيل جديد — اختيار حر',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.dark)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _dropdown('الطالب', kStudents.map((s) => '${s.name} — ${s.code}').toList(),
                _student, (v) => setState(() => _student = v))),
            const SizedBox(width: 14),
            Expanded(child: _dropdown('المادة', kGroups.map((g) => g.subject).toSet().toList(),
                _subject, (v) => setState(() { _subject = v; _teacher = null; }))),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _dropdown('المدرس المفضل', [for (final t in teachersForSubject) t.name],
                _teacher, (v) => setState(() => _teacher = v))),
            const SizedBox(width: 14),
            Expanded(child: Container(
              decoration: BoxDecoration(border: Border.all(color: AppTheme.line), borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(children: [
                const Text('الفترة المفضلة:', style: TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
                const Spacer(),
                for (final p in kPeriods)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(p == 'صباحي' ? '☀ صباحي' : (p == 'ظهر' ? '🌤 ظهر' : '🌙 مسائي'),
                          style: const TextStyle(fontSize: 11)),
                      selected: _period == p,
                      selectedColor: AppTheme.seed.withOpacity(.2),
                      onSelected: (_) => setState(() => _period = p),
                    ),
                  ),
              ]),
            )),
          ]),
          const SizedBox(height: 18),
          if (_teacher != null)
            Container(
              decoration: BoxDecoration(
                color: full ? AppTheme.danger.withOpacity(.06) : AppTheme.success.withOpacity(.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: full ? AppTheme.danger.withOpacity(.3) : AppTheme.success.withOpacity(.3)),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(full ? Icons.lock_clock : Icons.check_circle, color: full ? AppTheme.danger : AppTheme.success, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(full
                    ? 'مجموعة ${_teacher!} في هذه الفترة مكتملة — سيوضع الطالب على قائمة الانتظار تلقائيًا'
                    : 'تتوفر مقاعد مع ${_teacher!} في هذه الفترة — يمكن اعتماد التسجيل فورًا',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: full ? AppTheme.danger : AppTheme.success))),
              ]),
            ),
          const SizedBox(height: 18),
          PrimaryButton('إرسال الطلب للاعتماد الإداري', icon: Icons.send,
            onPressed: (_student == null || _subject == null || _teacher == null)
                ? null
                : () => widget.onSnack(full
                    ? '⏳ أُضيف لقائمة انتظار ${_teacher!}'
                    : '✅ أُرسل الطلب للإدارة — سيُشعَر الطالب بالقرار')),
        ]),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String? value, void Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSub, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.line), borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: (value != null && items.contains(value)) ? value : null,
            isExpanded: true,
            hint: Text('اختر...', style: const TextStyle(fontSize: 12.5)),
            items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12.5)))],
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }
}
