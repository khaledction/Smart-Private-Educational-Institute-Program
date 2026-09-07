import 'package:flutter/material.dart';

import '../data/app_session.dart';
import '../data/mock_data.dart';
import '../data/registration_store.dart';
import '../data/student_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// الطلاب — الآن مربوطون بقاعدة البيانات المحلية
/// إضافة طالب + بحث + ملف طالب محفوظ دائمًا
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final store = StudentStore.instance;
  String _query = '';
  StudentRecord? _selected;

  @override
  void initState() {
    super.initState();
    if (store.isReady) {
      store.refresh();
    } else {
      store.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.isReady && store.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }
        if (store.error != null && !store.isReady) {
          return Center(
            child: Container(
              width: 620,
              padding: const EdgeInsets.all(20),
              decoration: cardDeco(),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.people_alt, size: 34, color: AppTheme.danger),
                const SizedBox(height: 10),
                const Text('تعذر تحميل سجلات الطلاب المحلية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                const SizedBox(height: 8),
                Text(store.error!, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
                const SizedBox(height: 14),
                PrimaryButton('إعادة المحاولة', icon: Icons.refresh, onPressed: () => store.init()),
              ]),
            ),
          );
        }

        if (_selected != null) {
          final current = store.byId(_selected!.id);
          if (current == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selected = null);
            });
            return const SizedBox.shrink();
          }
          return _Profile(s: current, onBack: () => setState(() => _selected = null));
        }

        final list = store.students.where((s) {
          final q = _query.trim().toLowerCase();
          if (q.isEmpty) return true;
          return s.name.toLowerCase().contains(q) || s.code.toLowerCase().contains(q);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.seed.withOpacity(.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.seed.withOpacity(.2)),
              ),
              child: Row(children: [
                const Icon(Icons.storage, color: AppTheme.seed),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'سجلات الطلاب تعمل الآن على قاعدة بيانات محلية. أي طالب جديد تحفظه هنا سيبقى بعد إغلاق البرنامج، ويظهر لاحقًا في شاشة التسجيل أيضًا.',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.seed, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: store.isBusy ? null : () => store.refresh(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('تحديث', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
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
              PrimaryButton('إضافة طالب جديد', icon: Icons.person_add_alt_1, onPressed: _openNewStudentPanel),
            ]),
            const SizedBox(height: 16),
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
                    Text(AppSession.canViewFinancial ? money(s.totalFee) : '—', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dark)),
                    Text('${s.materialsCount}'),
                  ],
              ],
            ),
          ]),
        );
      },
    );
  }

  String _subjectPeriod(StudentRecord s) {
    if (s.materials.isEmpty) return '${s.level} / ${s.preferredPeriod == 'ظهر' ? 'ع الظهر' : s.preferredPeriod}';
    final m = s.materials.first;
    return '${m.subject} / ${m.period}';
  }

  void _openNewStudentPanel() {
    showSidePanel(context, title: 'إضافة طالب جديد', builder: (_) => _NewStudentForm(onSaved: () {
      setState(() {});
    }));
  }
}

class _NameLink extends StatefulWidget {
  final StudentRecord s;
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

class _Profile extends StatelessWidget {
  final StudentRecord s;
  final VoidCallback onBack;
  const _Profile({required this.s, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final invoices = kInvoices.where((i) => i.student == s.name.split(' ').first).toList();
    void openAddMaterialPanel() {
      showSidePanel(
        context,
        title: 'إضافة مادة جديدة للطالب',
        builder: (_) => _AddStudentMaterialRequestForm(student: s),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_forward, size: 18), label: const Text('العودة لقائمة الطلاب')),
        const SizedBox(height: 6),
        Container(
          decoration: cardDeco(),
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppTheme.seed.withOpacity(.12),
              child: Text(s.name.substring(0, 1), style: const TextStyle(fontSize: 26, color: AppTheme.seed, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dark)),
              const SizedBox(height: 4),
              Text('رقم: ${s.code} • الهاتف: ${s.phone}', style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
              Text('ولي الأمر: ${s.guardian}', style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
              Text('النظام المفضل: ${s.preferredSystem} • الفترة: ${s.preferredPeriod == 'ظهر' ? 'ع الظهر' : s.preferredPeriod}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusChip(s.status, color: StatusChip.forStatus(s.status)),
              const SizedBox(height: 8),
              Text(
                AppSession.canViewFinancial ? 'المبلغ الإجمالي: ${money(s.totalFee)}' : 'المبلغ الإجمالي: مخفي لهذا الدور',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark),
              ),
              Text(
                !AppSession.canViewFinancial
                    ? 'الرصيد: مخفي'
                    : (s.balanceDue <= 0 ? 'مسدّد بالكامل ✓' : 'المتبقي: ${money(s.balanceDue)}'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: !AppSession.canViewFinancial
                      ? AppTheme.textSub
                      : (s.balanceDue <= 0 ? AppTheme.success : AppTheme.danger),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        if (s.materials.isEmpty)
          Container(
            decoration: cardDeco(),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Center(
                  child: Text(
                    'لم يُسجَّل في مواد بعد — يمكنك من هنا إضافة مادة جديدة للطالب وإرسالها للاعتماد مباشرة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton('إضافة مادة جديدة', icon: Icons.add_circle_outline, onPressed: openAddMaterialPanel),
              ],
            ),
          )
        else ...[
          Row(children: [
            const Text('المواد المسجَّل بها', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.dark)),
            const Spacer(),
            PrimaryButton('إضافة مادة جديدة', icon: Icons.add_circle_outline, onPressed: openAddMaterialPanel),
          ]),
          const SizedBox(height: 10),
          SimpleTable(
            columns: const ['المادة', 'المدرس', 'الفترة', 'الجدول', 'الحضور', 'الدرجة', 'المالية'],
            rows: [
              for (final m in s.materials)
                [
                  Text(m.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(m.teacher),
                  PeriodBadge(m.period),
                  Text(m.schedule),
                  Text('${m.attendancePct}%', style: TextStyle(fontWeight: FontWeight.bold, color: m.attendancePct >= 85 ? AppTheme.success : AppTheme.gold)),
                  Text(m.grade),
                  AppSession.canViewFinancial
                      ? StatusChip(m.financialStatus, color: m.financialStatus == 'مسدّد' ? AppTheme.success : AppTheme.gold)
                      : const Text('مخفي', style: TextStyle(fontSize: 11.5, color: AppTheme.textSub)),
                ],
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: StatCard(Icons.fact_check, 'متوسط الحضور', '${s.attendanceAvg}%', color: s.attendanceAvg >= 85 ? AppTheme.success : AppTheme.gold)),
            const SizedBox(width: 14),
            Expanded(child: StatCard(Icons.auto_stories, 'عدد المواد', '${s.materialsCount}', color: AppTheme.purple)),
          ]),
        ],
        if (AppSession.canViewFinancial && invoices.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            'فواتير مرتبطة بالعرض الحالي',
            child: SimpleTable(
              columns: const ['الفاتورة', 'الإجمالي', 'المدفوع', 'المتبقي', 'الحالة'],
              rows: [
                for (final i in invoices)
                  [
                    Text(i.number, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.seed)),
                    Text(money(i.total)),
                    Text(money(i.paid), style: const TextStyle(color: AppTheme.success)),
                    Text(money(i.total - i.paid), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                    StatusChip(i.status, color: StatusChip.forStatus(i.status)),
                  ],
              ],
            ),
          ),
        ],
      ]),
    );
  }
}

class _AddStudentMaterialRequestForm extends StatefulWidget {
  final StudentRecord student;
  const _AddStudentMaterialRequestForm({required this.student});

  @override
  State<_AddStudentMaterialRequestForm> createState() => _AddStudentMaterialRequestFormState();
}

class _AddStudentMaterialRequestFormState extends State<_AddStudentMaterialRequestForm> {
  final regStore = RegistrationStore.instance;

  int? _subjectId;
  int? _teacherId;
  late String _period;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    _period = widget.student.preferredPeriod.isEmpty ? 'مسائي' : widget.student.preferredPeriod;
    if (regStore.isReady) {
      regStore.refresh();
    } else {
      regStore.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: regStore,
      builder: (context, _) {
        if (!regStore.isReady && regStore.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }

        final subjectItems = regStore.subjects;
        final teacherItems = regStore.teachersForSubject(_subjectId);
        final preview = regStore.preview(subjectId: _subjectId, teacherId: _teacherId, period: _period);

        return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.seed.withOpacity(.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.seed.withOpacity(.22)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.student.name,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.dark)),
            const SizedBox(height: 4),
            Text('رقم الطالب: ${widget.student.code}', style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
            Text('يمكنك من هنا طلب إضافة مادة جديدة لهذا الطالب دون مغادرة ملفه.',
                style: const TextStyle(fontSize: 12, color: AppTheme.seed, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 16),
        if (subjectItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDeco(),
            child: const Text(
              'لا توجد مواد محفوظة حاليًا في القاعدة. أنشئ دورة أولًا من شاشة الدورات لتظهر المادة والمدرس هنا.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSub),
            ),
          )
        else ...[
          _dropdownInt(
            label: 'المادة الجديدة',
            value: _subjectId,
            items: [for (final s in subjectItems) (s.id, s.name)],
            onChanged: (v) => setState(() {
              _subjectId = v;
              _teacherId = null;
            }),
          ),
          const SizedBox(height: 14),
          _dropdownInt(
            label: 'المدرس المفضل',
            value: _teacherId,
            items: [for (final t in teacherItems) (t.id, '${t.name} — ${t.specialization}')],
            onChanged: (v) => setState(() => _teacherId = v),
          ),
          const SizedBox(height: 14),
          const Text('الفترة المفضلة', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
          const SizedBox(height: 8),
          Row(children: [
            for (final p in kPeriods)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(p == 'صباحي' ? '☀ صباحي' : (p == 'ظهر' ? '🌤 ظهر' : '🌙 مسائي')),
                  selected: _period == p,
                  selectedColor: AppTheme.seed.withOpacity(.15),
                  onSelected: (_) => setState(() => _period = p),
                ),
              ),
          ]),
          const SizedBox(height: 14),
          if (_subjectId != null && _teacherId != null)
            _StudentProfilePreviewCard(preview: preview),
          if (preview.alternatives.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('بدائل مفتوحة متاحة عند الاعتماد',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final alt in preview.alternatives)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.success.withOpacity(.22)),
                    ),
                    child: Text('${alt.name} • ${alt.teacher} • متاح ${alt.seatsLeft} مقعد',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.success)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (_msg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_msg, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
            ),
          PrimaryButton(
            regStore.isBusy ? 'جارٍ الحفظ...' : 'إرسال طلب إضافة المادة',
            icon: Icons.send,
            onPressed: (_subjectId == null || _teacherId == null || regStore.isBusy)
                ? null
                : () async {
                    final result = await regStore.submitRequest(
                      studentId: widget.student.id,
                      subjectId: _subjectId!,
                      teacherId: _teacherId!,
                      period: _period,
                    );
                    if (!mounted) return;
                    if (!result.ok) {
                      setState(() => _msg = result.message);
                      return;
                    }
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    messenger.showSnackBar(
                      SnackBar(content: Text(result.message), behavior: SnackBarBehavior.floating, width: 520),
                    );
                  },
          ),
        ],
      ],
    );
      },
    );
  }

  Widget _dropdownInt({
    required String label,
    required int? value,
    required List<(int, String)> items,
    required void Function(int?) onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSub, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.line), borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: (value != null && items.any((i) => i.$1 == value)) ? value : null,
            isExpanded: true,
            hint: const Text('اختر...', style: TextStyle(fontSize: 12.5)),
            items: [
              for (final item in items)
                DropdownMenuItem<int>(
                  value: item.$1,
                  child: Text(item.$2, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }
}

class _StudentProfilePreviewCard extends StatelessWidget {
  final RegistrationPreview preview;
  const _StudentProfilePreviewCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    final hasGroup = preview.hasExactGroup;
    final full = preview.isFull;
    return Container(
      decoration: BoxDecoration(
        color: hasGroup
            ? (full ? AppTheme.danger.withOpacity(.06) : AppTheme.success.withOpacity(.06))
            : AppTheme.gold.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasGroup
              ? (full ? AppTheme.danger.withOpacity(.3) : AppTheme.success.withOpacity(.3))
              : AppTheme.gold.withOpacity(.3),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Icon(
          hasGroup ? (full ? Icons.lock_clock : Icons.check_circle) : Icons.info_outline,
          color: hasGroup ? (full ? AppTheme.danger : AppTheme.success) : AppTheme.gold,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            !hasGroup
                ? (preview.alternatives.isNotEmpty
                    ? 'لا توجد مجموعة مطابقة تمامًا لهذا المدرس/الفترة، لكن توجد بدائل مفتوحة ستظهر عند الاعتماد.'
                    : 'لا توجد مجموعة مطابقة حاليًا، وسيحفظ الطلب للمراجعة أو الانتظار.')
                : (full
                    ? 'المجموعة المطلوبة مكتملة، ويمكن لاحقًا وضع الطالب على الانتظار أو تحويله إلى بديل مفتوح.'
                    : 'المجموعة المطلوبة متاحة ويمكن اعتماد الطلب مباشرة عند المراجعة.'),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: hasGroup ? (full ? AppTheme.danger : AppTheme.success) : AppTheme.gold,
            ),
          ),
        ),
      ]),
    );
  }
}

class _NewStudentForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _NewStudentForm({required this.onSaved});

  @override
  State<_NewStudentForm> createState() => _NewStudentFormState();
}

class _NewStudentFormState extends State<_NewStudentForm> {
  final store = StudentStore.instance;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _guardian = TextEditingController();
  final _fee = TextEditingController();
  String? _subject;
  String _period = 'مسائي';
  String _system = 'كورس كامل';
  String _msg = '';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _guardian.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty || _subject == null) {
      setState(() => _msg = '⚠ أكمل الاسم والهاتف والمادة أولًا');
      return;
    }
    final fee = double.tryParse(_fee.text) ?? 0.0;
    final result = await store.addStudent(
      name: _name.text,
      phone: _phone.text,
      guardian: _guardian.text,
      subject: _subject!,
      period: _period,
      system: _system,
      fee: fee,
    );
    if (!mounted) return;
    if (!result.ok) {
      setState(() => _msg = result.message);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    widget.onSaved();
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text(result.message), behavior: SnackBarBehavior.floating, width: 420),
    );
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
      _dropdown('المادة المطلوبة *', kSubjectNames, _subject, (v) => setState(() => _subject = v)),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(_msg, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
        ),
      PrimaryButton(store.isBusy ? 'جارٍ الحفظ...' : 'حفظ الطالب وتفعيل سجله', icon: Icons.save, onPressed: store.isBusy ? null : _save),
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

  Widget _dropdown(String label, List<String> items, String? value, void Function(String?) onChanged) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
