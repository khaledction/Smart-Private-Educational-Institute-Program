import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// الطلاب — قائمة بجدول تفاعلي + إضافة طالب فعليًا + ملف بتبويبات (§2.1، §9.2)
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _query = '';
  Student? _selected;

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return _Profile(s: _selected!, onBack: () => setState(() => _selected = null));
    }

    final list = kStudents.where((s) =>
        s.name.contains(_query) || s.code.toLowerCase().contains(_query.toLowerCase())).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو رقم الطالب...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.line)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.line)),
              ),
            ),
          ),
          const Spacer(),
          PrimaryButton('إضافة طالب جديد', icon: Icons.person_add_alt_1,
              onPressed: () => _openNewStudentPanel()),
        ]),
        const SizedBox(height: 16),
        // الجدول التفاعلي — الضغط على اسم الطالب يفتح ملفه
        SimpleTable(
          columns: const ['الرقم', 'الاسم', 'المادة/الفترة', 'الهاتف', 'ولي الأمر', 'الحالة', 'الحضور', 'المبلغ الإجمالي', 'المواد'],
          customColumns: [
            for (final c in const ['الرقم', 'الاسم', 'المادة/الفترة', 'الهاتف', 'ولي الأمر', 'الحالة', 'الحضور', 'المبلغ الإجمالي', 'المواد'])
              DataColumn(label: Text(c)),
          ],
          rows: [
            for (final s in list)
              [
                Text(s.code, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.seed)),
                _NameLink(s: s, onTap: () => setState(() => _selected = s)),
                Text(_subjectPeriod(s)),
                Text(s.phone),
                Text(s.guardian),
                StatusChip(s.status, color: StatusChip.forStatus(s.status)),
                Text('${s.attendanceAvg}%', style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: s.attendanceAvg >= 85 ? AppTheme.success : (s.attendanceAvg >= 60 ? AppTheme.gold : AppTheme.danger))),
                Text(money(s.totalFee), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dark)),
                Text('${s.materials.length}'),
              ],
          ],
        ),
      ]),
    );
  }

  String _subjectPeriod(Student s) {
    if (s.materials.isEmpty) return '${s.level} / —';
    final m = s.materials.first;
    return '${m.subject} / ${m.period}';
  }

  // ===== لوحة إضافة طالب منزلقة =====
  void _openNewStudentPanel() {
    showSidePanel(context, title: 'إضافة طالب جديد', builder: (_) => _NewStudentForm(onSaved: () {
      setState(() {}); // تحديث الجدول فورًا
    }));
  }
}

/// اسم الطالب كرابط بتفاعل hover
class _NameLink extends StatefulWidget {
  final Student s;
  final VoidCallback onTap;
  const _NameLink({required this.s, required this.onTap});

  @override
  State<_NameLink> createState() => _NameLinkState();
}

class _NameLinkState extends State<_NameLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'اضغط لعرض ملف الطالب وسجله',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _hover ? AppTheme.seed.withOpacity(.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.s.name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _hover ? AppTheme.seed : AppTheme.dark,
                      decoration: _hover ? TextDecoration.underline : null,
                      decorationColor: AppTheme.seed)),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 13, color: _hover ? AppTheme.seed : Colors.transparent),
            ]),
          ),
        ),
      ),
    );
  }
}


/// ==================== ملف الطالب بتبويبات ====================
class _Profile extends StatelessWidget {
  final Student s;
  final VoidCallback onBack;
  const _Profile({required this.s, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final invoices = kInvoices.where((i) => i.student == s.name.split(' ').first).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('العودة لقائمة الطلاب')),
        const SizedBox(height: 6),
        Container(
          decoration: cardDeco(),
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            CircleAvatar(radius: 34, backgroundColor: AppTheme.seed.withOpacity(.12),
                child: Text(s.name.substring(0, 1), style: const TextStyle(fontSize: 26, color: AppTheme.seed, fontWeight: FontWeight.bold))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dark)),
              const SizedBox(height: 4),
              Text('رقم: ${s.code} • الهاتف: ${s.phone}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
              Text('ولي الأمر: ${s.guardian}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusChip(s.status, color: StatusChip.forStatus(s.status)),
              const SizedBox(height: 8),
              Text('المبلغ الإجمالي: ${money(s.totalFee)}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark)),
              Text(s.balanceDue <= 0 ? 'مسدّد بالكامل ✓' : 'المتبقي: ${money(s.balanceDue)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: s.balanceDue <= 0 ? AppTheme.success : AppTheme.danger)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        if (s.materials.isEmpty)
          Container(
            decoration: cardDeco(),
            padding: const EdgeInsets.all(30),
            child: Center(child: Text('لم يُسجَّل في مواد بعد — أضف تسجيله من شاشة (التسجيل والانتظار)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          )
        else ...[
          const Text('المواد المسجَّل بها',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.dark)),
          const SizedBox(height: 10),
          SimpleTable(columns: const ['المادة', 'المدرس', 'الفترة', 'الجدول', 'الحضور', 'الدرجة', 'المالية'],
            rows: [
              for (final m in s.materials)
                [
                  Text(m.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(m.teacher),
                  PeriodBadge(m.period),
                  Text(m.schedule),
                  Text('${m.attendancePct}%', style: TextStyle(fontWeight: FontWeight.bold,
                      color: m.attendancePct >= 85 ? AppTheme.success : AppTheme.gold)),
                  Text(m.grade),
                  StatusChip(m.financial, color: m.financial == 'مسدّد' ? AppTheme.success : AppTheme.gold),
                ],
            ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: StatCard(Icons.fact_check, 'متوسط الحضور', '${s.attendanceAvg}%',
                color: s.attendanceAvg >= 85 ? AppTheme.success : AppTheme.gold)),
            const SizedBox(width: 14),
            Expanded(child: StatCard(Icons.auto_stories, 'عدد المواد', '${s.materials.length}',
                color: AppTheme.purple)),
          ]),
        ],
      ]),
    );
  }
}

// ==================== نموذج الطالب الجديد ====================
class _NewStudentForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _NewStudentForm({required this.onSaved});

  @override
  State<_NewStudentForm> createState() => _NewStudentFormState();
}

class _NewStudentFormState extends State<_NewStudentForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _guardian = TextEditingController();
  final _fee = TextEditingController();
  String? _subject, _period = 'مسائي', _system = 'كورس كامل';
  String _msg = '';

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _guardian.dispose(); _fee.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty || _subject == null) {
      setState(() => _msg = '⚠ أكمل الاسم والهاتف والمادة أولًا');
      return;
    }
    final fee = double.tryParse(_fee.text) ?? 0;
    final code = 'ST-${1054 + kStudents.length}';
    kStudents.add(Student(code, _name.text.trim(), _subject!, _phone.text.trim(),
        _guardian.text.trim().isEmpty ? '—' : _guardian.text.trim(),
        'نشط', fee, fee, []));
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(22), children: [
      _field('الاسم الكامل *', _name, 'مثال: محمد أحمد العلي'),
      const SizedBox(height: 14),
      _field('رقم الهاتف *', _phone, '09XX XXX XXX'),
      const SizedBox(height: 14),
      _field('اسم ولي الأمر', _guardian, 'للقاصرين إلزامي'),
      const SizedBox(height: 14),
      _dropdown('المادة المطلوبة *', kSubjectNames, _subject,
          (v) => setState(() => _subject = v)),
      const SizedBox(height: 14),
      const Text('نظام الدراسة', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
      const SizedBox(height: 8),
      Row(children: [
        for (final sys in kSystems)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(sys),
              selected: _system == sys,
              selectedColor: AppTheme.seed.withOpacity(.15),
              onSelected: (_) => setState(() => _system = sys),
            ),
          ),
      ]),
      if (_system == 'نظام ساعات')
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.success.withOpacity(.07), borderRadius: BorderRadius.circular(10)),
          child: const Text('💵 نظام ساعات: الدفع فوري لكل جلسة قبل الدخول', style: TextStyle(fontSize: 11.5, color: AppTheme.success, fontWeight: FontWeight.bold)),
        )
      else
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.purple.withOpacity(.07), borderRadius: BorderRadius.circular(10)),
          child: const Text('💳 كورس كامل: الدفع بأقساط تحددها الإدارة', style: TextStyle(fontSize: 11.5, color: AppTheme.purple, fontWeight: FontWeight.bold)),
        ),
      const SizedBox(height: 14),
      const Text('الفترة المفضلة', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
      const SizedBox(height: 8),
      Row(children: [
        for (final p in kPeriods)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(p == 'صباحي' ? '☀ صباحي' : (p == 'ظهر' ? '🌤 ع الظهر' : '🌙 مسائي')),
              selected: _period == p,
              selectedColor: AppTheme.seed.withOpacity(.15),
              onSelected: (_) => setState(() => _period = p),
            ),
          ),
      ]),
      const SizedBox(height: 14),
      _field('المبلغ الإجمالي (ل.س)', _fee, 'مثال: 180000'),
      const SizedBox(height: 18),
      if (_msg.isNotEmpty)
        Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_msg, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold))),
      PrimaryButton('حفظ الطالب وتفعيل سجله', icon: Icons.save, onPressed: _save),
    ]);
  }

  Widget _field(String label, TextEditingController c, String hint) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: label.contains('المبلغ') ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.line)),
          ),
        ),
      ]);

  Widget _dropdown(String label, List<String> items, String? value, void Function(String?) onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: AppTheme.line), borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (value != null && items.contains(value)) ? value : null,
              isExpanded: true,
              hint: const Text('اختر...', style: TextStyle(fontSize: 12.5)),
              items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12.5)))],
              onChanged: onChanged,
            ),
          ),
        ),
      ]);
}
