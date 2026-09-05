import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// المدرسون v3.6 — الإشغال + التقييم + فصل المستحق عن المصروف للمدرسين
class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: StatCard(Icons.co_present, 'عدد المدرسين', '${kTeachers.length}')),
          Expanded(child: StatCard(Icons.groups, 'الطلاب لديهم',
              '${kTeachers.fold<int>(0, (s, t) => s + t.enrolled)}', color: AppTheme.success)),
          Expanded(child: StatCard(Icons.hourglass_top, 'في انتظار مقعد',
              '${kTeachers.fold<int>(0, (s, t) => s + t.waiting)}', color: AppTheme.gold)),
          Expanded(child: StatCard(
              Icons.account_balance,
              'قيد الصرف للمدرسين',
              money(kTeachers.fold<double>(0, (s, t) => s + pendingCompForTeacher(t.name))),
              color: AppTheme.purple)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Text('كادر المدرسين (${kTeachers.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.dark)),
          const Spacer(),
          PrimaryButton('إضافة مدرس جديد', icon: Icons.person_add_alt,
              onPressed: () => showSidePanel(context, title: 'إضافة مدرس جديد',
                  builder: (_) => _NewTeacherForm(onSaved: () => setState(() {})))),
        ]),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420, mainAxisExtent: 276, crossAxisSpacing: 14, mainAxisSpacing: 14),
          itemCount: kTeachers.length,
          itemBuilder: (_, i) => _TeacherCard(kTeachers[i]),
        ),
      ]),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final Teacher t;
  const _TeacherCard(this.t);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.seed.withOpacity(.12),
            child: Text(t.name.substring(3, 4),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.seed)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.dark),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(t.subject, style: const TextStyle(fontSize: 11, color: AppTheme.textSub),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          StatusChip(t.degree, color: AppTheme.dark2),
          StatusChip('${t.groups} مجموعات', color: AppTheme.seed),
          CountBadge('انتظار', t.waiting),
          // أعلام العمل — أيقونات مع Tooltip
          if (t.worksGov)
            Tooltip(message: 'يعمل بقطاع حكومي', child: Icon(Icons.account_balance, size: 15, color: AppTheme.purple)),
          if (t.worksOther)
            Tooltip(message: 'يعمل بمعاهد أخرى', child: Icon(Icons.business_center, size: 15, color: AppTheme.gold)),
        ]),
        const SizedBox(height: 10),
        FillBar(t.enrolled, t.capacity),
        const Spacer(),
        // تقييم الإدارة — يظهر للإدارة فقط (المستخدم الحالي: المدير العام)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.line)),
          child: Row(children: [
            Tooltip(message: 'تقييم الإدارة — يظهر للإدارة فقط',
                child: Icon(Icons.admin_panel_settings, size: 14, color: AppTheme.purple)),
            const SizedBox(width: 5),
            Text('تقييم الإدارة:', style: const TextStyle(fontSize: 10.5, color: AppTheme.textSub)),
            const SizedBox(width: 4),
            for (var i = 1; i <= 5; i++)
              Icon(i <= t.mgmtRating.round() ? Icons.star : Icons.star_border,
                  size: 13, color: const Color(0xFFF59E0B)),
            const Spacer(),
            Text(t.mgmtRating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
          ]),
        ),
        // التعويضات المعتمدة له (من إشعارات المدير العام)
        Builder(builder: (_) {
          final approved = approvedCompForTeacher(t.name);
          final paid = paidCompForTeacher(t.name);
          final pending = pendingCompForTeacher(t.name);
          if (approved <= 0 && paid <= 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(color: AppTheme.gold.withOpacity(.07), borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.payments, size: 13, color: AppTheme.gold),
                  const SizedBox(width: 5),
                  Expanded(child: Text('المعتمد للمحاسبة: ' + money(approved),
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.gold))),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: Text('مصروف فعليًا: ' + money(paid),
                      style: const TextStyle(fontSize: 10.2, fontWeight: FontWeight.bold, color: AppTheme.purple))),
                  const SizedBox(width: 8),
                  Expanded(child: Text('قيد الصرف: ' + money(pending),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 10.2, fontWeight: FontWeight.bold, color: AppTheme.danger))),
                ]),
              ]),
            ),
          );
        }),
        const Divider(height: 14),
        Row(children: [
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('المستحق المنفذ', style: TextStyle(fontSize: 10, color: AppTheme.textSub)),
              Text(money(approvedCompForTeacher(t.name)),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dark)),
            ]))),
          const SizedBox(width: 8),
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerEnd,
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('المصروف / المتبقي', style: TextStyle(fontSize: 10, color: AppTheme.textSub)),
              Text(money(paidCompForTeacher(t.name)) + ' / ' + money(pendingCompForTeacher(t.name)),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: pendingCompForTeacher(t.name) > 0 ? AppTheme.gold : AppTheme.success)),
            ]))),
        ]),
      ]),
    );
  }
}

// ==================== نموذج إضافة مدرس جديد ====================
class _NewTeacherForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _NewTeacherForm({required this.onSaved});

  @override
  State<_NewTeacherForm> createState() => _NewTeacherFormState();
}

class _NewTeacherFormState extends State<_NewTeacherForm> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _whatsapp = TextEditingController();
  final _nationalId = TextEditingController();
  String? _specialization, _degree;
  bool _worksGov = false, _worksOther = false;
  double _mgmtRating = 3;
  bool _newSpec = false;
  final _newSpecCtrl = TextEditingController();
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
    _name.dispose(); _mobile.dispose(); _whatsapp.dispose();
    _nationalId.dispose(); _newSpecCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final spec = _newSpec ? _newSpecCtrl.text.trim() : _specialization;
    if (_name.text.trim().isEmpty || spec == null || spec.isEmpty || _degree == null || _mobile.text.trim().isEmpty) {
      setState(() => _msg = '⚠ أكمل: الاسم الثلاثي، الاختصاص، الشهادة، والموبايل');
      return;
    }
    // يضاف تلقائيًا لقوائم المدرسين في القوائم المنزلقة + المادة لقائمة المواد
    addSubjectIfNew(spec);
    kTeachers.add(Teacher(
      _name.text.trim(), spec, 0, 0, 12, 0, 0, 'لكل جلسة', 0, 0, 0,
      degree: _degree!, mobile: _mobile.text.trim(),
      whatsapp: _whatsapp.text.trim().isEmpty ? _mobile.text.trim() : _whatsapp.text.trim(),
      nationalId: _nationalId.text.trim(),
      worksGov: _worksGov, worksOther: _worksOther, mgmtRating: _mgmtRating,
    ));
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(22), children: [
      _field('الاسم الثلاثي *', _name, 'مثال: محمد أحمد العلي'),
      const SizedBox(height: 14),
      // الاختصاص — من قائمة المواد الموحدة أو مادة جديدة
      const Text('الاختصاص (المادة) *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
      const SizedBox(height: 6),
      if (!_newSpec)
        Row(children: [
          Expanded(child: _dropdown([for (final s in kSubjectNames) s], _specialization, (v) => setState(() => _specialization = v))),
          TextButton.icon(
            onPressed: () => setState(() => _newSpec = true),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('مادة جديدة', style: TextStyle(fontSize: 11.5)),
          ),
        ])
      else
        Row(children: [
          Expanded(child: TextField(
            controller: _newSpecCtrl,
            decoration: InputDecoration(hintText: 'اسم المادة الجديدة', isDense: true, filled: true, fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.line))),
          )),
          TextButton(onPressed: () => setState(() => _newSpec = false), child: const Text('إلغاء', style: TextStyle(fontSize: 11.5))),
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
      // أسئلة العمل
      Container(
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.line)),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          _yesNo('هل يعمل بقطاع الحكومي؟', _worksGov, (v) => setState(() => _worksGov = v)),
          const Divider(height: 18),
          _yesNo('هل يعمل بمعاهد أخرى؟', _worksOther, (v) => setState(() => _worksOther = v)),
        ]),
      ),
      const SizedBox(height: 16),
      // تقييم الإدارة — خمس نجوم
      Container(
        decoration: BoxDecoration(color: AppTheme.purple.withOpacity(.06), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.purple.withOpacity(.25))),
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
                icon: Icon(i <= _mgmtRating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF59E0B), size: 30),
                onPressed: () => setState(() => _mgmtRating = i.toDouble()),
              ),
          ]),
        ]),
      ),
      const SizedBox(height: 18),
      if (_msg.isNotEmpty)
        Padding(padding: const EdgeInsets.only(bottom: 10),
            child: Text(_msg, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold))),
      PrimaryButton('حفظ المدرس وإضافته لقوائم الاختيار', icon: Icons.save, onPressed: _save),
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
            onSelected: (_) => onChanged(v),
          ),
        ),
    ]);
  }

  Widget _field(String label, TextEditingController c, String hint, {bool number = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: number ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(hintText: hint, isDense: true, filled: true, fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.line))),
        ),
      ]);

  Widget _dropdown(List<String> items, String? value, void Function(String?) onChanged) =>
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
      );
}
