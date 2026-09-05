import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// الدورات والمجموعات v3.6 — اعتماد مالي كامل + دفتر ثلاثي + قفل مالي + تحذير هامش
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _system = 'الكل';
  String _period = 'الكل';
  String _type = 'الكل';

  @override
  Widget build(BuildContext context) {
    final groups = kGroups.where((g) {
      final sysOk = _system == 'الكل' || g.system == _system;
      final perOk = _period == 'الكل' || g.period == _period;
      final typOk = _type == 'الكل' || g.type == _type;
      return sysOk && perOk && typOk;
    }).toList();

    final pending = kGroups.where((g) => g.status == 'pending').toList();
    final fullCourses = kGroups.where((g) => !g.isHoursSystem).length;
    final hoursSystem = kGroups.where((g) => g.isHoursSystem).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: StatCard(Icons.auto_stories, 'كورسات كاملة (أقساط)', '$fullCourses',
              trend: 'دفع بأقساط تحددها الإدارة')),
          Expanded(child: StatCard(Icons.bolt, 'نظام ساعات (دفع فوري)', '$hoursSystem',
              trend: 'الدفع قبل كل جلسة', color: AppTheme.gold)),
          Expanded(child: StatCard(Icons.groups, 'إجمالي المسجلين',
              '${kGroups.fold<int>(0, (s, g) => s + g.enrolled)}', color: AppTheme.success)),
          Expanded(child: StatCard(Icons.schedule_send, 'في قوائم الانتظار',
              '${kGroups.fold<int>(0, (s, g) => s + g.waiting)}', color: AppTheme.danger)),
        ]),
        const SizedBox(height: 16),
        // ===== لافتة الدورات بانتظار موافقة المدير العام =====
        if (pending.isNotEmpty) ...[
          _PendingBanner(
            count: pending.length,
            onOpen: () => showSidePanel(context, title: 'موافقة المدير العام على الدورات الجديدة',
                builder: (_) => _ApprovalPanel(onChanged: () => setState(() {}))),
          ),
          const SizedBox(height: 12),
        ],
        // ===== الفلاتر: النظام × الفترة × النوع =====
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 14, runSpacing: 8, children: [
          _filterGroup('النظام:', ['الكل', ...kSystems], _system, AppTheme.purple,
              (v) => setState(() => _system = v)),
          _filterGroup('الفترة:', ['الكل', ...kPeriods], _period, AppTheme.seed,
              (v) => setState(() => _period = v)),
          _filterGroup('النوع:', ['الكل', ...kCourseTypes], _type, AppTheme.success,
              (v) => setState(() => _type = v)),
        ]),
        const Divider(height: 26),
        Row(children: [
          Text('${groups.length} مجموعة',
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
          const Spacer(),
          PrimaryButton('إنشاء دورة جديدة', icon: Icons.add_circle,
              onPressed: () => showSidePanel(context, title: 'إنشاء دورة جديدة',
                  builder: (_) => _CourseForm(onSaved: () => setState(() {})))),
        ]),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 430, mainAxisExtent: 276, crossAxisSpacing: 14, mainAxisSpacing: 14),
          itemCount: groups.length,
          itemBuilder: (_, i) => _GroupCard(groups[i], onSaved: () => setState(() {})),
        ),
      ]),
    );
  }

  Widget _filterGroup(String label, List<String> items, String current, Color color,
      void Function(String) onSelect) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
      const SizedBox(width: 6),
      for (final f in items)
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: ChoiceChip(
            label: Text(
              f == 'الكل'
                  ? 'الكل'
                  : (f == 'صباحي' ? '☀ صباحي' : (f == 'ظهر' ? '🌤 ظهر' : (f == 'مسائي' ? '🌙 مسائي' : f))),
              style: const TextStyle(fontSize: 11.5),
            ),
            selected: current == f,
            selectedColor: color.withOpacity(.15),
            labelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold,
                color: current == f ? color : AppTheme.textSub),
            side: BorderSide(color: current == f ? color.withOpacity(.5) : AppTheme.line),
            onSelected: (_) => onSelect(f),
          ),
        ),
    ]);
  }
}

// ==================== البطاقة التفاعلية ====================
class _GroupCard extends StatefulWidget {
  final Group g;
  final VoidCallback onSaved;
  const _GroupCard(this.g, {required this.onSaved});

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.g;
    final full = g.seatsLeft <= 0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => showSidePanel(context, title: 'تفاصيل الدورة وتعديلها',
            builder: (_) => _CourseForm(existing: g, onSaved: widget.onSaved)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          // تأثير hover هادئ: تظليل خفيف + حدود أنعم + ظل خفيف جدًا
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFFFBFDFF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hover ? AppTheme.seed.withOpacity(.45) : AppTheme.line),
            boxShadow: _hover
                ? const [BoxShadow(color: Color(0x080284C7), blurRadius: 12, offset: Offset(0, 3))]
                : const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(g.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: _hover ? AppTheme.seed : AppTheme.dark),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                PeriodBadge(g.period),
              ]),
              const SizedBox(height: 5),
              Text('${g.subject} • ${g.teacher}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                // نظام الدراسة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: g.isHoursSystem ? AppTheme.gold.withOpacity(.12) : AppTheme.seed.withOpacity(.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: g.isHoursSystem ? AppTheme.gold.withOpacity(.4) : AppTheme.seed.withOpacity(.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(g.isHoursSystem ? Icons.bolt : Icons.auto_stories, size: 12,
                        color: g.isHoursSystem ? AppTheme.gold : AppTheme.seed),
                    const SizedBox(width: 4),
                    Text(g.system, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold,
                        color: g.isHoursSystem ? AppTheme.gold : AppTheme.seed)),
                  ]),
                ),
                if (g.type.isNotEmpty)
                  StatusChip(g.type, color: AppTheme.success),
                StatusChip(
                    g.status == 'running'
                        ? 'منطلقة'
                        : (g.status == 'pending'
                            ? 'بانتظار اعتماد'
                            : (g.status == 'closed' ? 'مغلقة' : 'مفتوحة')),
                    color: g.status == 'running'
                        ? AppTheme.success
                        : (g.status == 'pending'
                            ? AppTheme.gold
                            : (g.status == 'closed' ? AppTheme.dark2 : AppTheme.seed))),
                if (g.financeLocked)
                  StatusChip('🔒 قفل مالي', color: AppTheme.dark2),
                CountBadge('انتظار', g.waiting),
              ]),
              const SizedBox(height: 10),
              FillBar(g.enrolled, g.capacity),
              const Spacer(),
              Row(children: [
                Icon(Icons.meeting_room, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Text(g.room, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSub)),
                const SizedBox(width: 8),
                Expanded(child: Text(g.days, style: const TextStyle(fontSize: 10, color: AppTheme.textSub),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const Divider(height: 14),
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.isHoursSystem ? 'رسم الساعة' : 'رسم الدورة',
                      style: const TextStyle(fontSize: 9.5, color: AppTheme.textSub)),
                  Text(money(g.price),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (g.isHoursSystem ? AppTheme.success : AppTheme.purple).withOpacity(.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    g.isHoursSystem ? '💵 دفع فوري/جلسة' : '💳 ${g.installments == 1 ? "كامل الرسم" : "${g.installments} أقساط"}',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold,
                        color: g.isHoursSystem ? AppTheme.success : AppTheme.purple),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${g.sessionsDone}/${g.sessionsTotal}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSub)),
              ]),
              const SizedBox(height: 6),
              if (full)
                const Text('المجموعة مكتملة — التسجيل بقائمة الانتظار',
                    style: TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.bold))
              else
                Text('متاح ${g.seatsLeft} مقعد',
                    style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold)),
            ]),
            // ===== زر التعديل الهادئ — الزاوية اليسرى السفلية =====
            Positioned(
              bottom: 0,
              left: 0,
              child: Tooltip(message: 'تعديل بيانات الدورة',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showSidePanel(context, title: 'تعديل بيانات الدورة',
                      builder: (_) => _CourseForm(existing: g, onSaved: widget.onSaved)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _hover ? AppTheme.seed.withOpacity(.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_outlined,
                        size: 15, color: _hover ? AppTheme.seed : Colors.grey.shade400),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ==================== نموذج الدورة: إنشاء + تعديل ====================
class _CourseForm extends StatefulWidget {
  final Group? existing;      // غير فارغ = وضع التعديل
  final VoidCallback onSaved;
  const _CourseForm({this.existing, required this.onSaved});

  @override
  State<_CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<_CourseForm> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _sessions;
  String? _subject, _teacher, _period, _system, _type;
  int _installments = 2;
  late final Set<String> _days;
  String _msg = '';
  bool _newSubject = false, _newType = false;
  final _newSubjectCtrl = TextEditingController();
  final _newTypeCtrl = TextEditingController();

  bool get _editing => widget.existing != null;

  /// فلترة وفرز المدرسين: المختصون بالمادة المختارة أولًا، ثم البقية
  List<String> _teachersFor(String? subject) {
    if (subject == null) return [for (final t in kTeachers) '${t.name} — ${t.subject}'];
    final keys = subject
        .replaceAll('اللغة', '')
        .split(' ')
        .where((k) => k.trim().length > 2)
        .toList();
    bool matches(Teacher t) => keys.any((k) => t.subject.contains(k));
    final matched = kTeachers.where(matches).map((t) => '${t.name} — ${t.subject}').toList();
    final others = kTeachers.where((t) => !matches(t)).map((t) => '${t.name} — ${t.subject}').toList();
    return [...matched, ...others]; // المختصون في الأعلى (فرز)
  }

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _name = TextEditingController(text: g?.name ?? '');
    _price = TextEditingController(text: g == null ? '' : g.price.toStringAsFixed(0));
    _sessions = TextEditingController(text: g == null ? '' : g.sessionsTotal.toString());
    _subject = g?.subject;
    _period = g?.period ?? 'مسائي';
    _system = g?.system ?? 'كورس كامل';
    _type = (g?.type.isEmpty ?? true) ? null : g!.type;
    _installments = g?.installments == 0 ? 2 : (g?.installments ?? 2);
    if (_installments < 1) _installments = 1;
    _days = g == null ? <String>{} : _daysFrom(g.days);
    _teacher = g == null ? null : '${g.teacher} — ${_teacherSubject(g.teacher)}';
  }

  String _teacherSubject(String name) {
    for (final t in kTeachers) { if (t.name == name) return t.subject; }
    return '';
  }

  Set<String> _daysFrom(String days) {
    final s = <String>{};
    for (final d in ['السبت','الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس']) {
      if (days.contains(d)) s.add(d);
    }
    return s;
  }

  @override
  void dispose() {
    _name.dispose(); _price.dispose(); _sessions.dispose();
    _newSubjectCtrl.dispose(); _newTypeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_editing && widget.existing!.financeLocked) {
      setState(() => _msg = '🔒 هذه الدورة مقفلة ماليًا. افتح القفل أولًا بصلاحية المدير العام إن أردت تعديل الجانب المالي.');
      return;
    }
    final subject = _newSubject ? _newSubjectCtrl.text.trim() : _subject;
    if (_name.text.trim().isEmpty || subject == null || subject.isEmpty ||
        _teacher == null || _days.isEmpty || _type == null) {
      setState(() => _msg = '⚠ أكمل: الاسم، النوع، المادة، المدرس، واختر الأيام');
      return;
    }
    addSubjectIfNew(subject);
    addCourseTypeIfNew(_type!);
    final price = (double.tryParse(_price.text) ?? 0).round();
    final total = int.tryParse(_sessions.text) ?? 12;
    final days = _days.join(' + ');
    final timeByPeriod = _period == 'صباحي' ? '10:00ص' : (_period == 'ظهر' ? '1:00 ظهرًا' : '5:00م');
    final teacherName = _teacher!.split(' — ').first;
    final newGroup = Group(
      _name.text.trim(), subject, teacherName, _period!, 
      widget.existing?.enrolled ?? 0, widget.existing?.capacity ?? 12,
      widget.existing?.waiting ?? 0,
      widget.existing?.status ?? 'pending', widget.existing?.room ?? 'قاعة 1',
      '$days • $timeByPeriod', price, widget.existing?.sessionsDone ?? 0, total,
      _system!, _system == 'نظام ساعات' ? 0 : _installments,
      type: _type!, teacherPct: widget.existing?.teacherPct ?? 0,
      financeLocked: widget.existing?.financeLocked ?? false,
    );
    if (!_editing) {
      kNotifications.insert(0, NotificationItem(
          'دورة جديدة بانتظار موافقة المدير العام',
          newGroup.name + ' — أضافها مدير الدورات، بانتظار الاعتماد وتحديد نسبة المعلم',
          'الآن', 'approval'));
      addAudit('إنشاء دورة', newGroup.name, 'تم إنشاء دورة جديدة بانتظار اعتماد المدير العام وتحديد نسبة المعلم.');
    }
    setState(() {
      if (_editing) {
        final i = kGroups.indexOf(widget.existing!);
        if (i != -1) kGroups[i] = newGroup;
      } else {
        kGroups.add(newGroup);
      }
    });
    if (_editing) {
      addAudit('تعديل دورة', newGroup.name, 'تم تعديل بيانات الدورة مع الحفاظ على سجلها المالي الحالي.');
    }
    widget.onSaved();
    Navigator.pop(context);
  }

  void _lockFinance() {
    final g = widget.existing;
    if (g == null || g.financeLocked) return;
    final i = kGroups.indexOf(g);
    if (i == -1) return;
    kGroups[i] = Group(
      g.name, g.subject, g.teacher, g.period, g.enrolled, g.capacity, g.waiting, 'closed',
      g.room, g.days, g.price, g.sessionsDone, g.sessionsTotal, g.system, g.installments,
      type: g.type, teacherPct: g.teacherPct, financeLocked: true,
    );
    addAudit('قفل مالي', g.name, 'تم قفل الدورة ماليًا عند الإغلاق لمنع أي تعديل مالي لاحق.');
    kNotifications.insert(0, NotificationItem(
      'قفل مالي لدورة',
      g.name + ' — تم قفل الدفتر المالي للدورة',
      'الآن', 'audit'));
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final teachers = _teachersFor(_newSubject ? null : _subject);
    // إن كان المدرس المحفوظ غير موجود بالقائمة (تعديل) أعد إدراجه أولًا
    if (_teacher != null && !teachers.contains(_teacher)) teachers.insert(0, _teacher!);

    return ListView(padding: const EdgeInsets.all(22), children: [
      if (_editing)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.existing!.financeLocked
                ? AppTheme.dark2.withOpacity(.06)
                : (widget.existing!.status == 'pending' ? AppTheme.gold.withOpacity(.07) : AppTheme.seed.withOpacity(.06)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.existing!.financeLocked
                  ? AppTheme.dark2.withOpacity(.28)
                  : (widget.existing!.status == 'pending' ? AppTheme.gold.withOpacity(.35) : Colors.transparent),
            ),
          ),
          child: Text(
            widget.existing!.financeLocked
                ? '🔒 هذه الدورة مقفلة ماليًا — أي تعديل مالي لاحق يحتاج فتح القفل بصلاحية المدير العام.'
                : (widget.existing!.status == 'pending'
                    ? '⏳ بانتظار موافقة المدير العام — يُعتمد ويُحدد فيها نسبة المعلم من لوحة الاعتماد'
                    : '✏ وضع التعديل — غيّر ما تشاء ثم اضغط حفظ'),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold,
                color: widget.existing!.financeLocked
                    ? AppTheme.dark2
                    : (widget.existing!.status == 'pending' ? AppTheme.gold : AppTheme.seed))),
        ),
      _label('اسم المجموعة *'),
      TextField(controller: _name, decoration: _dec('مثال: إنجليزي B1 — مسائي ج')),
      const SizedBox(height: 14),

      // ===== نوع الدورة =====
      _label('نوع الدورة *'),
      const SizedBox(height: 6),
      if (!_newType)
        Row(children: [
          Expanded(child: _dropdown([...kCourseTypes], _type, (v) => setState(() => _type = v))),
          TextButton.icon(
            onPressed: () => setState(() => _newType = true),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('نوع جديد', style: TextStyle(fontSize: 11.5)),
          ),
        ])
      else
        Row(children: [
          Expanded(child: TextField(
            controller: _newTypeCtrl,
            decoration: InputDecoration(hintText: 'مثال: تأسيس جامعي', isDense: true, filled: true, fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.line))),
          )),
          TextButton(onPressed: () => setState(() => _newType = false), child: const Text('إلغاء', style: TextStyle(fontSize: 11.5))),
        ]),
      const SizedBox(height: 14),

      // ===== نظام الدراسة =====
      _label('نظام الدراسة *'),
      const SizedBox(height: 6),
      Row(children: [
        for (final sys in kSystems)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(sys == 'كورس كامل' ? '📚 كورس كامل' : '⚡ نظام ساعات'),
              selected: _system == sys,
              selectedColor: (sys == 'كورس كامل' ? AppTheme.seed : AppTheme.gold).withOpacity(.15),
              onSelected: (_) => setState(() => _system = sys),
            ),
          ),
      ]),
      const SizedBox(height: 14),

      // ===== المادة (سجل موحد) =====
      _label('المادة * — تسمية موحدة'),
      const SizedBox(height: 6),
      if (!_newSubject)
        Row(children: [
          Expanded(child: _dropdown([...kSubjectNames], _subject, (v) => setState(() { _subject = v; _teacher = null; }))),
          TextButton.icon(
            onPressed: () => setState(() => _newSubject = true),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('مادة جديدة', style: TextStyle(fontSize: 11.5)),
          ),
        ])
      else
        Row(children: [
          Expanded(child: TextField(
            controller: _newSubjectCtrl,
            decoration: InputDecoration(hintText: 'اسم المادة الجديدة', isDense: true, filled: true, fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.line))),
          )),
          TextButton(onPressed: () => setState(() => _newSubject = false), child: const Text('إلغاء', style: TextStyle(fontSize: 11.5))),
        ]),
      const SizedBox(height: 14),

      // ===== المدرس — مفلتر حسب المادة =====
      Row(children: [
        _label('المدرس * — المختصون بالمادة أولًا'),
        const SizedBox(width: 6),
        Tooltip(message: 'القائمة مرتبة: مدرسو هذه المادة في الأعلى، ثم بقية الكادر',
          child: Icon(Icons.filter_list, size: 15, color: AppTheme.textSub)),
      ]),
      const SizedBox(height: 6),
      _dropdown(teachers, _teacher, (v) => setState(() => _teacher = v)),
      const SizedBox(height: 14),

      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(_system == 'نظام ساعات' ? 'رسم الساعة (ل.س) *' : 'رسم الدورة (ل.س) *'),
          const SizedBox(height: 6),
          TextField(controller: _price, keyboardType: TextInputType.number,
              decoration: _dec(_system == 'نظام ساعات' ? '15000' : '180000')),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(_system == 'نظام ساعات' ? 'عدد الجلسات المتاحة' : 'عدد الحصص/الساعات *'),
          const SizedBox(height: 6),
          TextField(controller: _sessions, keyboardType: TextInputType.number, decoration: _dec('24')),
        ])),
      ]),
      const SizedBox(height: 14),

      if (_system == 'كورس كامل') ...[
        _label('سياسة الدفع (تحددها الإدارة)'),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final (lbl, n) in [('كامل الرسم', 1), ('قسطان', 2), ('3 أقساط', 3), ('4 أقساط', 4)])
            ChoiceChip(
              label: Text(lbl, style: const TextStyle(fontSize: 11.5)),
              selected: _installments == n,
              selectedColor: AppTheme.purple.withOpacity(.15),
              onSelected: (_) => setState(() => _installments = n),
            ),
        ]),
        const SizedBox(height: 14),
      ],

      _label('الفترة *'),
      const SizedBox(height: 6),
      Row(children: [
        for (final p in kPeriods)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(p == 'صباحي' ? '☀ صباحية' : (p == 'ظهر' ? '🌤 ع الظهر' : '🌙 مسائية')),
              selected: _period == p,
              selectedColor: AppTheme.seed.withOpacity(.15),
              onSelected: (_) => setState(() => _period = p),
            ),
          ),
      ]),
      const SizedBox(height: 16),

      _label('أيام الانعقاد *'),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final d in ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'])
          FilterChip(
            label: Text(d, style: const TextStyle(fontSize: 11.5)),
            selected: _days.contains(d),
            selectedColor: AppTheme.seed.withOpacity(.18),
            onSelected: (v) => setState(() { v ? _days.add(d) : _days.remove(d); }),
          ),
      ]),
      const SizedBox(height: 20),

      if (_editing) ...[
        const SizedBox(height: 14),
        _finSummary(),
      ],
      const SizedBox(height: 18),
      if (_msg.isNotEmpty)
        Padding(padding: const EdgeInsets.only(bottom: 10),
            child: Text(_msg, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold))),
      PrimaryButton(
          _editing
              ? (widget.existing!.financeLocked ? 'الدورة مقفلة ماليًا' : 'حفظ التعديلات')
              : 'حفظ الدورة وإتاحة التسجيل بها',
          icon: _editing ? (widget.existing!.financeLocked ? Icons.lock : Icons.save) : Icons.add_circle,
          onPressed: _editing && widget.existing!.financeLocked
              ? () => setState(() => _msg = '🔒 الدورة مقفلة ماليًا. افتح القفل بصلاحية المدير العام قبل أي تعديل.')
              : _save),
    ]);
  }

  Widget _finSummary() {
    final g = widget.existing!;
    final teacher = teacherByName(g.teacher);
    final degree = teacher?.degree ?? '—';
    final paid = paidCompForCourse(g.name);
    final approved = approvedCompForCourse(g.name);
    final pending = approved - paid;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.purple.withOpacity(.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.purple.withOpacity(.25))),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.calculate, size: 15, color: AppTheme.purple),
          const SizedBox(width: 6),
          const Text('الملخص المالي — سياسات v3.6 المعتمدة',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.purple)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          StatusChip('استحقاق بالجلسة المنفذة', color: AppTheme.seed),
          StatusChip('سقف نسبة ≤ 50%', color: AppTheme.success),
          StatusChip('معتمد ≠ مصروف', color: AppTheme.gold),
          if (g.financeLocked) StatusChip('🔒 مقفلة ماليًا', color: AppTheme.dark2),
        ]),
        const SizedBox(height: 8),
        InfoRow('المدرس', g.teacher + ' — ' + degree),
        InfoRow('الإيراد التعاقدي الكامل', money(g.revenue)),
        InfoRow('الإيراد المحقق حتى الآن', money(g.accruedRevenue), valueColor: AppTheme.success),
        InfoRow('الإيراد المؤجل', money(g.deferredRevenue), valueColor: AppTheme.textSub),
        InfoRow('نسبة المعلم', g.teacherPct > 0 ? '%${g.teacherPct.toStringAsFixed(0)}' : 'لم تُحدد بعد (من صلاحية المدير العام)'),
        InfoRow('مستحق المدرس المنفذ', money(g.accruedTeacherComp), valueColor: AppTheme.gold),
        InfoRow('المصروف فعليًا', money(paid), valueColor: AppTheme.purple),
        InfoRow('المتبقي قيد الصرف', money(pending > 0 ? pending : 0), valueColor: pending > 0 ? AppTheme.danger : AppTheme.success),
        InfoRow('هامش المعهد الحالي', '%${g.instituteMarginPct.toStringAsFixed(0)}',
            valueColor: g.instituteMarginPct > 70 ? AppTheme.gold : AppTheme.success),
        if (g.instituteMarginPct > 70) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.gold.withOpacity(.07), borderRadius: BorderRadius.circular(10)),
            child: const Text(
              'تنبيه: هامش المعهد أعلى من 70% — راجع النسبة قبل تثبيت السياسة المالية للدورة.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.gold),
            ),
          ),
        ],
        if (!g.financeLocked) ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PrimaryButton('قفل الدورة ماليًا عند الإغلاق',
                icon: Icons.lock_outline, color: AppTheme.dark2, onPressed: _lockFinance),
          ),
        ] else ...[
          const SizedBox(height: 10),
          const Text('🔒 القفل المالي فعال — يمنع تعديل السعر، النسبة، والمصروفات بأثر رجعي.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
        ],
      ]),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2));
  InputDecoration _dec(String hint) => InputDecoration(
      hintText: hint, isDense: true, filled: true, fillColor: AppTheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.line)));

  Widget _dropdown(List<String> items, String? value, void Function(String?) onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.line), borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: (value != null && items.contains(value)) ? value : null,
            isExpanded: true,
            hint: const Text('اختر...', style: TextStyle(fontSize: 12.5)),
            items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis))],
            onChanged: onChanged,
          ),
        ),
      );
}


// ==================== لافتة الانتظار ====================
class _PendingBanner extends StatelessWidget {
  final int count;
  final VoidCallback onOpen;
  const _PendingBanner({required this.count, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withOpacity(.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        const Icon(Icons.gavel, color: AppTheme.gold),
        const SizedBox(width: 10),
        Expanded(child: Text(
          '⏳ ' + count.toString() + ' دورة/دورات أنشأها مدير الدورات — بانتظار موافقتك: اعتماد مع تحديد نسبة المعلم، أو تعديل، أو رفض',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.gold))),
        PrimaryButton('مراجعة واعتماد', icon: Icons.gavel, color: AppTheme.gold, onPressed: onOpen),
      ]),
    );
  }
}

// ==================== لوحة موافقة المدير العام ====================
class _ApprovalPanel extends StatefulWidget {
  final VoidCallback onChanged;
  const _ApprovalPanel({required this.onChanged});

  @override
  State<_ApprovalPanel> createState() => _ApprovalPanelState();
}

class _ApprovalPanelState extends State<_ApprovalPanel> {
  final Map<String, double> _pct = {};

  double pctOf(Group g) => _pct[g.name] ?? 30;

  void _approve(Group g) {
    final pct = pctOf(g);
    if (pct > 50) return;
    final i = kGroups.indexOf(g);
    Group approved = g;
    if (i != -1) {
      approved = Group(g.name, g.subject, g.teacher, g.period, g.enrolled, g.capacity,
          g.waiting, 'open', g.room, g.days, g.price, g.sessionsDone, g.sessionsTotal,
          g.system, g.installments, type: g.type, teacherPct: pct, financeLocked: g.financeLocked);
      kGroups[i] = approved;
    }
    final teacher = teacherByName(g.teacher);
    final amount = approved.accruedTeacherComp;
    kCompNotices.insert(0, CompNotice('2026-09-05', g.teacher,
        teacher == null ? '—' : teacher.degree, g.name, g.system,
        approved.executedSessions, g.enrolled, pct, amount, 'معتمد'));
    if (marginNeedsWarning(pct)) {
      addAudit('مراجعة هامش', g.name,
          'هامش المعهد الحالي ${ (100 - pct).toStringAsFixed(0)}% وتجاوز عتبة 70% قبل الاعتماد.');
    }
    addAudit('اعتماد مالي', g.name,
        'تم اعتماد نسبة ${pct.toStringAsFixed(0)}% وربط المستحق بالجلسات المنفذة فقط.');
    kNotifications.insert(0, NotificationItem('إشعار محاسبة — تعويض مدرس معتمد',
        g.teacher + ' — ' + g.name + ' بنسبة %' + pct.toStringAsFixed(0) + ' = ' + fmt(amount) + ' ل.س (على الجلسات المنفذة)',
        'الآن', 'payment'));
    widget.onChanged();
    setState(() {});
    if (kGroups.where((x) => x.status == 'pending').isEmpty) Navigator.pop(context);
  }

  void _reject(Group g) {
    kGroups.remove(g);
    addAudit('رفض دورة', g.name, 'تم رفض الدورة من لوحة اعتماد المدير العام.');
    widget.onChanged();
    setState(() {});
    if (kGroups.where((x) => x.status == 'pending').isEmpty) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pending = kGroups.where((g) => g.status == 'pending').toList();
    if (pending.isEmpty) {
      return const Center(child: Text('لا دورات معلقة — كلها معتمدة ✓',
          style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)));
    }
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.purple.withOpacity(.06), borderRadius: BorderRadius.circular(10)),
        child: const Text(
          'بصلاحية المدير العام: حدد نسبة المعلم من رسوم الدورة ضمن سقف أعلى 50%.\n'
          '📚 كورس كامل: الاستحقاق المنفذ = نسبة × ((رسم الدورة ÷ عدد الجلسات) × الجلسات المنفذة × عدد الطلاب)\n'
          '⚡ نظام ساعات: الاستحقاق المنفذ = نسبة × (رسم الساعة × الجلسات المنفذة × عدد الطلاب)\n'
          'يُنشأ سجل تدقيق تلقائي، ويظهر تنبيه عندما يتجاوز هامش المعهد 70%، ثم يصل إشعار للمحاسبة فور الاعتماد.',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purple)),
      ),
      const SizedBox(height: 14),
      for (final g in pending)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: cardDeco(),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(g.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.dark))),
              StatusChip(g.system, color: g.isHoursSystem ? AppTheme.gold : AppTheme.seed),
            ]),
            const SizedBox(height: 4),
            Text(g.subject + ' • ' + g.type,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSub)),
            const SizedBox(height: 6),
            InfoRow('المدرس', g.teacher),
            InfoRow(g.isHoursSystem ? 'رسم الساعة × الجلسات المتاحة' : 'رسم الدورة', money(g.price) + (g.isHoursSystem ? ' × ${g.sessionsTotal} جلسة' : '')),
            InfoRow('الطلاب الحاليون', '${g.enrolled}'),
            InfoRow('الإيراد التعاقدي', money(g.revenue)),
            InfoRow('الإيراد المحقق حتى الآن', money(g.accruedRevenue), valueColor: AppTheme.success),
            const SizedBox(height: 8),
            Row(children: [
              const Text('نسبة المعلم:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
              const Spacer(),
              Text('%' + pctOf(g).toStringAsFixed(0),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.purple)),
            ]),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final p in [20.0, 25.0, 30.0, 35.0, 40.0, 50.0])
                ChoiceChip(
                  label: Text('%' + p.toStringAsFixed(0), style: const TextStyle(fontSize: 11.5)),
                  selected: pctOf(g) == p,
                  selectedColor: AppTheme.purple.withOpacity(.15),
                  onSelected: (_) => setState(() => _pct[g.name] = p),
                ),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.gold.withOpacity(.07), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.payments, size: 16, color: AppTheme.gold),
                const SizedBox(width: 8),
                Text('مستحق المدرس المنفذ الآن: ' + money(g.accruedRevenue * pctOf(g) / 100),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                const Spacer(),
                Text('صافي المعهد المحقق: ' + money(g.accruedRevenue * (100 - pctOf(g)) / 100),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.success)),
              ]),
            ),
            if (marginNeedsWarning(pctOf(g)))
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(.06), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'تنبيه قبل الاعتماد: هامش المعهد الحالي %' + (100 - pctOf(g)).toStringAsFixed(0) + ' وهو أعلى من 70%. راجع النسبة أو دوّن سبب الاعتماد في السجل.',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.danger),
                ),
              ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: PrimaryButton('اعتماد وتحديد النسبة', icon: Icons.check_circle,
                  color: AppTheme.success, onPressed: () => _approve(g))),
              const SizedBox(width: 8),
              Expanded(child: PrimaryButton('رفض الدورة', icon: Icons.cancel,
                  color: AppTheme.danger, onPressed: () => _reject(g))),
            ]),
          ]),
        ),
    ]);
  }
}
