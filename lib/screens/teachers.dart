import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/registration_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// شاشة المدرسين — مربوطة فعليًا الآن بقاعدة البيانات المحلية.
/// زر التهيئة هنا سيؤثر مباشرة على العناصر الظاهرة في الشاشة.
class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final store = RegistrationStore.instance;
  bool _resettingDb = false;
  String _dbMessage = '';
  Color _dbMessageColor = AppTheme.textSub;

  @override
  void initState() {
    super.initState();
    if (store.isReady) {
      store.refresh();
    } else {
      store.init();
    }
  }

  Future<void> _resetDatabase() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تهيئة قاعدة فارغة'),
            content: const Text(
              'سيتم حذف كل البيانات المحلية نهائيًا من قاعدة التسجيل: الطلاب، المواد، المدرسون، الدورات، الطلبات، والانتظار. هذا الزر مؤقت للتجربة. هل تريد المتابعة؟',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                child: const Text('نعم، هيّئ قاعدة فارغة'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    setState(() {
      _resettingDb = true;
      _dbMessage = '';
    });

    final result = await store.resetAllLocalData();
    if (!mounted) return;

    setState(() {
      _resettingDb = false;
      _dbMessage = result.message;
      _dbMessageColor = result.ok ? AppTheme.success : AppTheme.danger;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                const Icon(Icons.groups_2_outlined, size: 34, color: AppTheme.danger),
                const SizedBox(height: 10),
                const Text('تعذر تهيئة شاشة المدرسين',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                const SizedBox(height: 8),
                Text(store.error!, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
                const SizedBox(height: 14),
                PrimaryButton('إعادة المحاولة', icon: Icons.refresh, onPressed: () => store.init()),
              ]),
            ),
          );
        }

        final teachers = [
          for (final t in store.teachers) _TeacherVm.fromStore(t, store),
        ]..sort((a, b) => a.name.compareTo(b.name));

        final totalEnrolled = teachers.fold<int>(0, (s, t) => s + t.enrolled);
        final totalWaiting = teachers.fold<int>(0, (s, t) => s + t.waiting);
        final totalPending = teachers.fold<double>(0.0, (s, t) => s + pendingCompForTeacher(t.name));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final statWidth = width >= 1200
                    ? (width - 42) / 4
                    : (width >= 760 ? (width - 14) / 2 : width);
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(width: statWidth, child: StatCard(Icons.co_present, 'عدد المدرسين', '${teachers.length}')),
                    SizedBox(width: statWidth, child: StatCard(Icons.groups, 'الطلاب لديهم', '$totalEnrolled', color: AppTheme.success)),
                    SizedBox(width: statWidth, child: StatCard(Icons.hourglass_top, 'في انتظار مقعد', '$totalWaiting', color: AppTheme.gold)),
                    SizedBox(width: statWidth, child: StatCard(Icons.account_balance, 'قيد الصرف للمدرسين', money(totalPending), color: AppTheme.purple)),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.danger.withOpacity(.18)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: const [
                  Icon(Icons.storage_outlined, color: AppTheme.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'زر مؤقت: تهيئة قاعدة فارغة. بما أن هذه الشاشة مربوطة الآن فعليًا بقاعدة البيانات، فستختفي منها السجلات مباشرة بعد التفريغ.',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.danger, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: _resettingDb ? null : _resetDatabase,
                    icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                    label: Text(_resettingDb ? 'جارٍ التهيئة...' : 'تهيئة قاعدة فارغة', style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ]),
            ),
            if (_dbMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _dbMessage,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _dbMessageColor),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('كادر المدرسين (${teachers.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                TextButton.icon(
                  onPressed: store.isBusy ? null : () => store.refresh(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('تحديث', style: TextStyle(fontSize: 12)),
                ),
                PrimaryButton(
                  'إضافة مدرس جديد',
                  icon: Icons.person_add_alt,
                  onPressed: () => showSidePanel(
                    context,
                    title: 'إضافة مدرس جديد',
                    builder: (_) => _NewTeacherForm(onSaved: () => store.refresh()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (teachers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: cardDeco(),
                child: Column(children: const [
                  Icon(Icons.groups_2_outlined, size: 34, color: AppTheme.textSub),
                  SizedBox(height: 10),
                  Text('لا يوجد مدرسون محفوظون حاليًا في قاعدة البيانات المحلية.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                  SizedBox(height: 6),
                  Text('يمكنك البدء بإضافة مدرس جديد، أو ستظهر الأسماء تلقائيًا عند إنشاء دورات وربطها بمدرسين.',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textSub), textAlign: TextAlign.center),
                ]),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final cardWidth = width >= 1260
                      ? (width - 28) / 3
                      : (width >= 840 ? (width - 14) / 2 : width);
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final teacher in teachers)
                        SizedBox(width: cardWidth, child: _TeacherCard(teacher)),
                    ],
                  );
                },
              ),
          ]),
        );
      },
    );
  }
}

class _TeacherVm {
  final String name;
  final String subject;
  final String degree;
  final String mobile;
  final String whatsapp;
  final bool worksGov;
  final bool worksOther;
  final double mgmtRating;
  final int groups;
  final int enrolled;
  final int capacity;
  final int waiting;

  const _TeacherVm({
    required this.name,
    required this.subject,
    required this.degree,
    required this.mobile,
    required this.whatsapp,
    required this.worksGov,
    required this.worksOther,
    required this.mgmtRating,
    required this.groups,
    required this.enrolled,
    required this.capacity,
    required this.waiting,
  });

  double get occupancy => capacity == 0 ? 0.0 : enrolled / capacity;

  factory _TeacherVm.fromStore(TeacherOption option, RegistrationStore store) {
    final groupRows = store.groups.where((g) => g.teacher.trim() == option.name.trim()).toList();
    final waitingRows = store.waiting.where((w) => w.teacherName.trim() == option.name.trim()).toList();
    final source = teacherByName(option.name);
    return _TeacherVm(
      name: option.name,
      subject: option.specialization,
      degree: option.degree.trim().isEmpty ? (source?.degree ?? '—') : option.degree,
      mobile: option.mobile.trim().isNotEmpty ? option.mobile.trim() : (source?.mobile.isNotEmpty == true ? source!.mobile : '—'),
      whatsapp: option.whatsapp.trim().isNotEmpty ? option.whatsapp.trim() : (source?.whatsapp.isNotEmpty == true ? source!.whatsapp : '—'),
      worksGov: source?.worksGov ?? false,
      worksOther: source?.worksOther ?? false,
      mgmtRating: source?.mgmtRating ?? 4.0,
      groups: groupRows.length,
      enrolled: groupRows.fold<int>(0, (s, g) => s + g.enrolled),
      capacity: groupRows.fold<int>(0, (s, g) => s + g.capacity),
      waiting: waitingRows.length,
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final _TeacherVm t;
  const _TeacherCard(this.t);

  @override
  Widget build(BuildContext context) {
    final approved = approvedCompForTeacher(t.name);
    final paid = paidCompForTeacher(t.name);
    final pending = pendingCompForTeacher(t.name);
    final avatarText = _safeAvatarText(t.name);

    return Container(
      decoration: cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.seed.withOpacity(.12),
            child: Text(avatarText,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.seed)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.dark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(t.subject,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          StatusChip(t.degree, color: AppTheme.dark2),
          StatusChip('${t.groups} مجموعات', color: AppTheme.seed),
          CountBadge('انتظار', t.waiting),
          if (t.worksGov)
            const Tooltip(message: 'يعمل بقطاع حكومي', child: Icon(Icons.account_balance, size: 15, color: AppTheme.purple)),
          if (t.worksOther)
            const Tooltip(message: 'يعمل بمعاهد أخرى', child: Icon(Icons.business_center, size: 15, color: AppTheme.gold)),
        ]),
        const SizedBox(height: 10),
        FillBar(t.enrolled, t.capacity),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.phone_iphone, size: 14, color: AppTheme.textSub),
              const SizedBox(width: 6),
              Expanded(
                child: Text('الموبايل: ${t.mobile}',
                    style: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.bold, color: AppTheme.dark2),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.chat_outlined, size: 14, color: AppTheme.textSub),
              const SizedBox(width: 6),
              Expanded(
                child: Text('الواتساب: ${t.whatsapp}',
                    style: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.bold, color: AppTheme.dark2),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.line),
          ),
          child: Row(children: [
            const Tooltip(
              message: 'تقييم الإدارة — يظهر للإدارة فقط',
              child: Icon(Icons.admin_panel_settings, size: 14, color: AppTheme.purple),
            ),
            const SizedBox(width: 5),
            const Text('تقييم الإدارة:', style: TextStyle(fontSize: 10.5, color: AppTheme.textSub)),
            const SizedBox(width: 4),
            for (var i = 1; i <= 5; i++)
              Icon(i <= t.mgmtRating.round() ? Icons.star : Icons.star_border,
                  size: 13, color: const Color(0xFFF59E0B)),
            const Spacer(),
            Text(t.mgmtRating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
          ]),
        ),
        if (approved > 0 || paid > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(color: AppTheme.gold.withOpacity(.07), borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.payments, size: 13, color: AppTheme.gold),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text('المعتمد للمحاسبة: ${money(approved)}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(
                    child: Text('مصروف فعليًا: ${money(paid)}',
                        style: const TextStyle(fontSize: 10.2, fontWeight: FontWeight.bold, color: AppTheme.purple)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('قيد الصرف: ${money(pending)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 10.2, fontWeight: FontWeight.bold, color: AppTheme.danger)),
                  ),
                ]),
              ]),
            ),
          ),
        const Divider(height: 14),
        Row(children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('المستحق المنفذ', style: TextStyle(fontSize: 10, color: AppTheme.textSub)),
                Text(money(approved),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dark)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('المصروف / المتبقي', style: TextStyle(fontSize: 10, color: AppTheme.textSub)),
                Text('${money(paid)} / ${money(pending)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: pending > 0 ? AppTheme.gold : AppTheme.success)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  String _safeAvatarText(String name) {
    final cleaned = name.replaceAll('أ.', '').trim();
    if (cleaned.isEmpty) return 'م';
    return cleaned.substring(0, 1);
  }
}

class _NewTeacherForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _NewTeacherForm({required this.onSaved});

  @override
  State<_NewTeacherForm> createState() => _NewTeacherFormState();
}

class _NewTeacherFormState extends State<_NewTeacherForm> {
  final store = RegistrationStore.instance;

  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _whatsapp = TextEditingController();
  final _nationalId = TextEditingController();
  final _newSpecCtrl = TextEditingController();

  String? _specialization;
  String? _degree;
  bool _worksGov = false;
  bool _worksOther = false;
  double _mgmtRating = 3;
  bool _newSpec = false;
  bool _saving = false;
  String _msg = '';

  static const _degrees = [
    'دكتوراه',
    'جامعة خمس سنوات',
    'جامعة اربع سنوات',
    'ماجستير تأهيل وتخصص',
    'ماجستير تأهيل أكاديمي',
    'دبلوم تأهيل تربوي',
    'دبلوم تأهيل وتخصص',
    'معهد متوسط',
  ];

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _whatsapp.dispose();
    _nationalId.dispose();
    _newSpecCtrl.dispose();
    super.dispose();
  }

  List<String> _subjectOptions() {
    final items = <String>{...kSubjectNames, ...store.subjects.map((s) => s.name)}.toList();
    items.sort();
    return items;
  }

  Future<void> _save() async {
    final spec = _newSpec ? _newSpecCtrl.text.trim() : (_specialization ?? '').trim();
    final name = _name.text.trim();
    final mobile = _mobile.text.trim();
    final whatsapp = _whatsapp.text.trim().isEmpty ? mobile : _whatsapp.text.trim();

    if (name.isEmpty || spec.isEmpty || _degree == null || mobile.isEmpty) {
      setState(() => _msg = '⚠ أكمل: الاسم الثلاثي، الاختصاص، الشهادة، والموبايل');
      return;
    }

    setState(() {
      _saving = true;
      _msg = '';
    });

    final result = await store.saveTeacher(
      name: name,
      specialization: spec,
      degree: _degree!,
      mobile: mobile,
      whatsapp: whatsapp,
    );
    if (!mounted) return;

    if (!result.ok) {
      setState(() {
        _saving = false;
        _msg = result.message;
      });
      return;
    }

    addSubjectIfNew(spec);
    if (teacherByName(name) == null) {
      kTeachers.add(
        Teacher(
          name,
          spec,
          0,
          0,
          12,
          0,
          _mgmtRating,
          'لكل جلسة',
          0,
          0,
          0,
          degree: _degree!,
          mobile: mobile,
          whatsapp: whatsapp,
          nationalId: _nationalId.text.trim(),
          worksGov: _worksGov,
          worksOther: _worksOther,
          mgmtRating: _mgmtRating,
        ),
      );
    }

    final messenger = ScaffoldMessenger.of(context);
    widget.onSaved();
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(22), children: [
      _field('الاسم الثلاثي *', _name, 'مثال: محمد أحمد العلي'),
      const SizedBox(height: 14),
      const Text('الاختصاص (المادة) *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
      const SizedBox(height: 6),
      if (!_newSpec)
        Row(children: [
          Expanded(child: _dropdown(_subjectOptions(), _specialization, (v) => setState(() => _specialization = v))),
          TextButton.icon(
            onPressed: _saving ? null : () => setState(() => _newSpec = true),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('مادة جديدة', style: TextStyle(fontSize: 11.5)),
          ),
        ])
      else
        Row(children: [
          Expanded(
            child: TextField(
              controller: _newSpecCtrl,
              enabled: !_saving,
              decoration: InputDecoration(
                hintText: 'اسم المادة الجديدة',
                isDense: true,
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.line)),
              ),
            ),
          ),
          TextButton(onPressed: _saving ? null : () => setState(() => _newSpec = false), child: const Text('إلغاء', style: TextStyle(fontSize: 11.5))),
        ]),
      const SizedBox(height: 14),
      const Text('الشهادة *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
      const SizedBox(height: 6),
      _dropdown(_degrees, _degree, (v) => setState(() => _degree = v)),
      const SizedBox(height: 14),
      _field('رقم الموبايل *', _mobile, '09XX XXX XXX', number: true),
      const SizedBox(height: 14),
      _field('رقم الواتساب', _whatsapp, 'إن تركه فارغًا = نفس الموبايل', number: true),
      const SizedBox(height: 14),
      _field('الرقم الوطني', _nationalId, 'الرقم الوطني / الهوية', number: true),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.line)),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          _yesNo('هل يعمل بقطاع الحكومي؟', _worksGov, (v) => setState(() => _worksGov = v)),
          const Divider(height: 18),
          _yesNo('هل يعمل بمعاهد أخرى؟', _worksOther, (v) => setState(() => _worksOther = v)),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.purple.withOpacity(.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.purple.withOpacity(.25)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.admin_panel_settings, size: 16, color: AppTheme.purple),
            const SizedBox(width: 6),
            const Text('تقييم الإدارة (من 5 نجوم)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.purple)),
            const Spacer(),
            const Icon(Icons.lock, size: 12, color: AppTheme.textSub),
            const Text('يظهر للإدارة فقط', style: TextStyle(fontSize: 10, color: AppTheme.textSub)),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                icon: Icon(i <= _mgmtRating ? Icons.star : Icons.star_border, color: const Color(0xFFF59E0B), size: 30),
                onPressed: _saving ? null : () => setState(() => _mgmtRating = i.toDouble()),
              ),
          ]),
        ]),
      ),
      const SizedBox(height: 18),
      if (_msg.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(_msg, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
        ),
      PrimaryButton(
        _saving ? 'جارٍ حفظ المدرس...' : 'حفظ المدرس وإضافته لقوائم الاختيار',
        icon: Icons.save,
        onPressed: _saving ? null : _save,
      ),
    ]);
  }

  Widget _yesNo(String label, bool value, void Function(bool) onChanged) {
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.dark2))),
      for (final (lbl, v, c) in [('نعم', true, AppTheme.success), ('لا', false, AppTheme.textSub)])
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: ChoiceChip(
            label: Text(lbl, style: TextStyle(fontSize: 11.5, color: value == v ? c : AppTheme.textSub)),
            selected: value == v,
            selectedColor: c.withOpacity(.15),
            onSelected: _saving ? null : (_) => onChanged(v),
          ),
        ),
    ]);
  }

  Widget _field(String label, TextEditingController c, String hint, {bool number = false}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            enabled: !_saving,
            keyboardType: number ? TextInputType.phone : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.line)),
            ),
          ),
        ],
      );

  Widget _dropdown(List<String> items, String? value, void Function(String?) onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.line), borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: (value != null && items.contains(value)) ? value : null,
            isExpanded: true,
            hint: const Text('اختر...', style: TextStyle(fontSize: 12.5)),
            items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12.5)))],
            onChanged: _saving ? null : onChanged,
          ),
        ),
      );
}
