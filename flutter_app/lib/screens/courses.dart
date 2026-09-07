import 'package:flutter/material.dart';

import '../data/app_session.dart';
import '../data/mock_data.dart';
import '../data/registration_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// شاشة الدورات — مربوطة الآن فعليًا بقاعدة البيانات المحلية.
/// الوضع الحالي الافتراضي: المدير العام بصلاحيات كاملة.
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final store = RegistrationStore.instance;
  final _search = TextEditingController();

  String _system = 'الكل';
  String _period = 'الكل';
  String _type = 'الكل';

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
  void dispose() {
    _search.dispose();
    super.dispose();
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
                const Icon(Icons.storage, size: 34, color: AppTheme.danger),
                const SizedBox(height: 10),
                const Text('تعذر تهيئة قاعدة بيانات الدورات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                const SizedBox(height: 8),
                Text(store.error!, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
                const SizedBox(height: 14),
                PrimaryButton('إعادة المحاولة', icon: Icons.refresh, onPressed: () => store.init()),
              ]),
            ),
          );
        }

        final search = _search.text.trim();
        final typeOptions = <String>{
          'الكل',
          ...kCourseTypes,
          ...store.groups.map((g) => g.type).where((v) => v.trim().isNotEmpty),
        }.toList();

        final groups = store.groups.where((g) {
          final sysOk = _system == 'الكل' || g.system == _system;
          final perOk = _period == 'الكل' || g.period == _period;
          final typeOk = _type == 'الكل' || g.type == _type;
          final text = '${g.name} ${g.subject} ${g.teacher} ${g.room}';
          final searchOk = search.isEmpty || text.contains(search);
          return sysOk && perOk && typeOk && searchOk;
        }).toList();

        final fullCourses = store.groups.where((g) => !g.isHoursSystem).length;
        final hoursSystem = store.groups.where((g) => g.isHoursSystem).length;
        final totalEnrolled = store.groups.fold<int>(0, (s, g) => s + g.enrolled);
        final totalWaiting = store.groups.fold<int>(0, (s, g) => s + g.waiting);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppSession.isGeneralManager
                    ? AppTheme.purple.withOpacity(.07)
                    : AppTheme.seed.withOpacity(.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppSession.isGeneralManager
                      ? AppTheme.purple.withOpacity(.28)
                      : AppTheme.seed.withOpacity(.28),
                ),
              ),
              child: Row(children: [
                Icon(
                  AppSession.isGeneralManager ? Icons.admin_panel_settings : Icons.badge,
                  color: AppSession.isGeneralManager ? AppTheme.purple : AppTheme.seed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('وضع التشغيل الحالي: ${AppSession.currentRole}',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppSession.isGeneralManager ? AppTheme.purple : AppTheme.seed)),
                    const SizedBox(height: 4),
                    Text(
                      AppSession.canViewFinancial
                          ? 'أنت الآن بصلاحيات كاملة، لذلك ستظهر لك التفاصيل المالية داخل ملف الدورة وملف الطالب.'
                          : 'التفاصيل المالية مخفية لهذا الدور، وتظهر فقط للمحاسبة أو المدير العام.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSub),
                    ),
                  ]),
                ),
                TextButton.icon(
                  onPressed: store.isBusy ? null : () => store.refresh(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('تحديث'),
                ),
                const SizedBox(width: 8),
                PrimaryButton(
                  'تهيئة قاعدة فارغة',
                  icon: Icons.cleaning_services_outlined,
                  color: AppTheme.danger,
                  onPressed: store.isBusy ? null : _resetDatabase,
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: StatCard(Icons.auto_stories, 'كورسات كاملة', '$fullCourses', trend: 'مربوطة الآن بقاعدة SQLite محلية')),
              Expanded(child: StatCard(Icons.bolt, 'نظام ساعات', '$hoursSystem', color: AppTheme.gold, trend: 'تمييز مستقل داخل البيانات الحقيقية')),
              Expanded(child: StatCard(Icons.groups, 'إجمالي المسجلين', '$totalEnrolled', color: AppTheme.success)),
              Expanded(child: StatCard(Icons.schedule_send, 'في الانتظار', '$totalWaiting', color: AppTheme.danger)),
            ]),
            const SizedBox(height: 16),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 14, runSpacing: 10, children: [
              _filterGroup('النظام:', ['الكل', ...kSystems], _system, AppTheme.purple,
                  (v) => setState(() => _system = v)),
              _filterGroup('الفترة:', ['الكل', ...kPeriods], _period, AppTheme.seed,
                  (v) => setState(() => _period = v)),
              _filterGroup('النوع:', typeOptions, _type, AppTheme.success,
                  (v) => setState(() => _type = v)),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم الدورة أو المادة أو المدرس...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.line),
                    ),
                  ),
                ),
              ),
            ]),
            const Divider(height: 26),
            Row(children: [
              Text('${groups.length} دورة / مجموعة',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
              const Spacer(),
              PrimaryButton(
                'إنشاء دورة جديدة',
                icon: Icons.add_circle,
                onPressed: () => showSidePanel(
                  context,
                  title: 'إنشاء دورة جديدة',
                  builder: (_) => _CourseForm(onSaved: _snackAndRefresh),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            if (groups.isEmpty)
              Container(
                width: double.infinity,
                decoration: cardDeco(),
                padding: const EdgeInsets.all(28),
                child: Column(children: [
                  const Icon(Icons.school_outlined, size: 42, color: AppTheme.seed),
                  const SizedBox(height: 10),
                  const Text('قاعدة الدورات فارغة حاليًا',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                  const SizedBox(height: 6),
                  const Text(
                    'وهذا مقصود لتبدأ التجربة الحقيقية من الصفر: أنشئ دورة، ثم أضف طالبًا، ثم قدّم طلب التسجيل واعتمده.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textSub),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    'ابدأ بإنشاء أول دورة',
                    icon: Icons.add_box_outlined,
                    onPressed: () => showSidePanel(
                      context,
                      title: 'إنشاء دورة جديدة',
                      builder: (_) => _CourseForm(onSaved: _snackAndRefresh),
                    ),
                  ),
                ]),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 430,
                  mainAxisExtent: 310,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: groups.length,
                itemBuilder: (_, i) => _GroupCard(
                  group: groups[i],
                  onSaved: _snackAndRefresh,
                ),
              ),
          ]),
        );
      },
    );
  }

  Future<void> _resetDatabase() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد تهيئة القاعدة'),
            content: const Text(
              'سيتم حذف جميع الطلاب والمدرسين والمواد والدورات والطلبات والانتظار من القاعدة المحلية نهائيًا، ثم تبدأ من الصفر. هل تتابع؟',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                child: const Text('نعم، فرّغها'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    final result = await store.resetAllLocalData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message), behavior: SnackBarBehavior.floating, width: 520),
    );
  }

  void _snackAndRefresh(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, width: 460),
    );
  }

  Widget _filterGroup(
    String label,
    List<String> items,
    String current,
    Color color,
    void Function(String) onSelect,
  ) {
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
            labelStyle: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: current == f ? color : AppTheme.textSub,
            ),
            side: BorderSide(color: current == f ? color.withOpacity(.5) : AppTheme.line),
            onSelected: (_) => onSelect(f),
          ),
        ),
    ]);
  }
}

class _GroupCard extends StatefulWidget {
  final GroupOption group;
  final void Function(String) onSaved;
  const _GroupCard({required this.group, required this.onSaved});

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final full = g.seatsLeft <= 0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => showSidePanel(
          context,
          title: 'ملف الدورة',
          builder: (_) => _CourseDetailsPanel(groupId: g.id, onSaved: widget.onSaved),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFFFBFDFF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hover ? AppTheme.seed.withOpacity(.45) : AppTheme.line),
            boxShadow: _hover
                ? const [BoxShadow(color: Color(0x080284C7), blurRadius: 12, offset: Offset(0, 3))]
                : const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                  g.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _hover ? AppTheme.seed : AppTheme.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PeriodBadge(g.period),
            ]),
            const SizedBox(height: 6),
            Text('${g.subject} • ${g.teacher}',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              StatusChip(g.system, color: g.isHoursSystem ? AppTheme.gold : AppTheme.seed),
              if (g.type.trim().isNotEmpty) StatusChip(g.type, color: AppTheme.success),
              StatusChip(_statusLabel(g.status), color: _statusColor(g.status)),
              CountBadge('انتظار', g.waiting),
              if (g.financeLocked) const StatusChip('🔒 قفل مالي', color: AppTheme.dark2),
            ]),
            const SizedBox(height: 12),
            FillBar(g.enrolled, g.capacity),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.meeting_room, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 3),
              Text(g.room, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSub)),
            ]),
            const SizedBox(height: 4),
            Text(g.days, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSub)),
            const Spacer(),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('الجلسات', style: TextStyle(fontSize: 10, color: AppTheme.textSub)),
                  Text('${g.executedSessions}/${g.sessionsTotal}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                ]),
              ),
              if (AppSession.canViewFinancial)
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(g.isHoursSystem ? 'رسم الساعة' : 'رسم الدورة',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSub)),
                    Text(money(g.price),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                  ]),
                )
              else
                const Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text('القسم المالي مخفي', style: TextStyle(fontSize: 10.5, color: AppTheme.textSub)),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            if (full)
              const Text('المجموعة مكتملة — أي اعتماد جديد سيتحول إلى الانتظار',
                  style: TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.bold))
            else
              Text('متاح ${g.seatsLeft} مقعد',
                  style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => showSidePanel(
                  context,
                  title: 'تعديل بيانات الدورة',
                  builder: (_) => _CourseForm(existing: g, onSaved: widget.onSaved),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('تعديل'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CourseDetailsPanel extends StatefulWidget {
  final int groupId;
  final void Function(String) onSaved;
  const _CourseDetailsPanel({required this.groupId, required this.onSaved});

  @override
  State<_CourseDetailsPanel> createState() => _CourseDetailsPanelState();
}

class _CourseDetailsPanelState extends State<_CourseDetailsPanel> {
  late Future<CourseDetailsSnapshot> _future;
  final store = RegistrationStore.instance;

  @override
  void initState() {
    super.initState();
    _future = store.loadCourseDetails(widget.groupId);
  }

  Future<void> _reload() async {
    await store.refresh();
    setState(() {
      _future = store.loadCourseDetails(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CourseDetailsSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('تعذر تحميل تفاصيل الدورة: ${snapshot.error}'),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final g = data.group;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                  const SizedBox(height: 4),
                  Text('${g.subject} • ${g.teacher}', style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
                ]),
              ),
              PeriodBadge(g.period),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [
              StatusChip(g.system, color: g.isHoursSystem ? AppTheme.gold : AppTheme.seed),
              if (g.type.trim().isNotEmpty) StatusChip(g.type, color: AppTheme.success),
              StatusChip(_statusLabel(g.status), color: _statusColor(g.status)),
              if (g.financeLocked) const StatusChip('🔒 قفل مالي', color: AppTheme.dark2),
            ]),
            const SizedBox(height: 16),
            Container(
              decoration: cardDeco(),
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('معلومات الدورة',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                const SizedBox(height: 10),
                InfoRow('المدرس', g.teacher),
                InfoRow('الفترة', g.period == 'ظهر' ? 'ع الظهر' : g.period),
                InfoRow('القاعة', g.room),
                InfoRow('الجدول', g.days.isEmpty ? '—' : g.days),
                InfoRow('السعة', '${g.capacity}'),
                InfoRow('المسجلون فعليًا', '${data.students.length}', valueColor: AppTheme.success),
                InfoRow('قائمة الانتظار', '${data.waiting.length}', valueColor: AppTheme.gold),
                InfoRow('الجلسات المنفذة', '${g.executedSessions}/${g.sessionsTotal}'),
                if (AppSession.canViewFinancial) ...[
                  InfoRow(g.isHoursSystem ? 'رسم الساعة' : 'رسم الدورة', money(g.price)),
                  InfoRow('الإيراد المحقق حتى الآن', money(g.accruedRevenue), valueColor: AppTheme.success),
                  InfoRow('نسبة المعلم', g.teacherPct > 0 ? '%${g.teacherPct.toStringAsFixed(0)}' : 'غير محددة بعد'),
                  InfoRow('مستحق المدرس المنفذ', money(g.accruedTeacherComp), valueColor: AppTheme.gold),
                  InfoRow(
                    'طريقة الدفع',
                    g.isHoursSystem ? 'رسم الساعة — دفع عند الجلسة' : 'رسم الدورة — ${g.installments == 1 ? 'كامل الرسم' : '${g.installments} دفعات'}',
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('القسم المالي مخفي لهذا الدور.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSub, fontWeight: FontWeight.bold)),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
            SectionCard(
              'الطلاب المسجلون بالأسماء والمعلومات',
              actionLabel: 'تحديث',
              onAction: _reload,
              child: data.students.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text('لا يوجد طلاب مسجلون في هذه الدورة بعد.',
                            style: TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
                      ),
                    )
                  : Column(
                      children: [
                        for (final s in data.students)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(
                                  child: Text('${s.name} — ${s.code}',
                                      style: const TextStyle(
                                          fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                                ),
                                StatusChip(s.status, color: StatusChip.forStatus(s.status)),
                              ]),
                              const SizedBox(height: 6),
                              Text('الهاتف: ${s.phone}', style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub)),
                              Text('ولي الأمر: ${s.guardian}', style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub)),
                              Text('تاريخ الربط بالدورة: ${_fmtDate(s.enrolledAt)}',
                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub)),
                              if (AppSession.canViewFinancial) ...[
                                const SizedBox(height: 6),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  StatusChip(s.financialStatus, color: s.balanceDue <= 0 ? AppTheme.success : AppTheme.gold),
                                  Text('الإجمالي: ${money(s.totalFee)}',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  Text(
                                    s.balanceDue <= 0 ? 'مسدّد بالكامل' : 'المتبقي: ${money(s.balanceDue)}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: s.balanceDue <= 0 ? AppTheme.success : AppTheme.danger,
                                    ),
                                  ),
                                ]),
                              ],
                            ]),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              'قائمة الانتظار الخاصة بهذه الدورة',
              child: data.waiting.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text('لا يوجد طلاب على الانتظار لهذه الدورة.',
                            style: TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
                      ),
                    )
                  : Column(
                      children: [
                        for (final w in data.waiting)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.gold.withOpacity(.35)),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(
                                  child: Text('${w.name} — ${w.code}',
                                      style: const TextStyle(
                                          fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                                ),
                                const StatusChip('قائمة انتظار', color: AppTheme.gold),
                              ]),
                              const SizedBox(height: 6),
                              Text('الهاتف: ${w.phone}', style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub)),
                              Text('ولي الأمر: ${w.guardian}', style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub)),
                              Text('تاريخ الإدراج: ${_fmtDate(w.createdAt)}',
                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub)),
                            ]),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: PrimaryButton(
                  'تعديل بيانات الدورة',
                  icon: Icons.edit_outlined,
                  onPressed: () => showSidePanel(
                    context,
                    title: 'تعديل بيانات الدورة',
                    builder: (_) => _CourseForm(
                      existing: g,
                      onSaved: (msg) {
                        widget.onSaved(msg);
                        _reload();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton('تحديث الملف', icon: Icons.refresh, color: AppTheme.dark2, onPressed: _reload),
              ),
            ]),
          ],
        );
      },
    );
  }
}

class _CourseForm extends StatefulWidget {
  final GroupOption? existing;
  final void Function(String) onSaved;
  const _CourseForm({this.existing, required this.onSaved});

  @override
  State<_CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<_CourseForm> {
  final store = RegistrationStore.instance;

  late final TextEditingController _name;
  late final TextEditingController _room;
  late final TextEditingController _price;
  late final TextEditingController _capacity;
  late final TextEditingController _sessionsDone;
  late final TextEditingController _sessionsTotal;
  late final TextEditingController _teacherPct;
  late final TextEditingController _time;
  final _newSubjectCtrl = TextEditingController();
  final _newTypeCtrl = TextEditingController();

  String? _subject;
  String? _teacher;
  String _period = 'مسائي';
  String _system = 'كورس كامل';
  String _status = 'open';
  String? _type;
  bool _newSubject = false;
  bool _newType = false;
  bool _financeLocked = false;
  int _installments = 2;
  final Set<String> _days = <String>{};
  String _msg = '';

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _name = TextEditingController(text: g?.name ?? '');
    _room = TextEditingController(text: g?.room ?? 'قاعة 1');
    _price = TextEditingController(text: g == null ? '' : g.price.toStringAsFixed(0));
    _capacity = TextEditingController(text: g == null ? '12' : g.capacity.toString());
    _sessionsDone = TextEditingController(text: g == null ? '0' : g.sessionsDone.toString());
    _sessionsTotal = TextEditingController(text: g == null ? '12' : g.sessionsTotal.toString());
    _teacherPct = TextEditingController(text: g == null ? '30' : g.teacherPct.toStringAsFixed(0));
    _subject = g?.subject;
    _teacher = g == null ? null : _teacherLabel(g.teacher, g.subject);
    _period = g?.period ?? 'مسائي';
    _system = g?.system ?? 'كورس كامل';
    _status = g?.status ?? 'open';
    _type = (g == null || g.type.trim().isEmpty) ? null : g.type;
    _financeLocked = g?.financeLocked ?? false;
    _installments = g == null ? 2 : (g.installments < 1 ? 1 : g.installments);

    final parsed = _parseSchedule(g?.days ?? '');
    _days.addAll(parsed.$1);
    _time = TextEditingController(text: parsed.$2.isEmpty ? _defaultTime(_period) : parsed.$2);
  }

  @override
  void dispose() {
    _name.dispose();
    _room.dispose();
    _price.dispose();
    _capacity.dispose();
    _sessionsDone.dispose();
    _sessionsTotal.dispose();
    _teacherPct.dispose();
    _time.dispose();
    _newSubjectCtrl.dispose();
    _newTypeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectValue = _newSubject ? _newSubjectCtrl.text.trim() : (_subject ?? '');
    final teacherItems = _teacherOptions(subjectValue.isEmpty ? null : subjectValue);
    if (_teacher != null && !teacherItems.contains(_teacher)) {
      teacherItems.insert(0, _teacher!);
    }

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        if (_msg.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gold.withOpacity(.35)),
            ),
            child: Text(_msg, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.gold)),
          ),
          const SizedBox(height: 12),
        ],
        _label('اسم الدورة *'),
        TextField(controller: _name, decoration: _dec('مثال: إنجليزي B1 — مسائي أ')),
        const SizedBox(height: 14),
        _label('نوع الدورة'),
        const SizedBox(height: 6),
        if (!_newType)
          Row(children: [
            Expanded(child: _dropdown(_typeOptions(), _type, (v) => setState(() => _type = v))),
            TextButton.icon(
              onPressed: () => setState(() => _newType = true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('نوع جديد', style: TextStyle(fontSize: 11.5)),
            ),
          ])
        else
          Row(children: [
            Expanded(child: TextField(controller: _newTypeCtrl, decoration: _dec('مثال: تأسيس جامعي'))),
            TextButton(onPressed: () => setState(() => _newType = false), child: const Text('إلغاء')),
          ]),
        const SizedBox(height: 14),
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
        _label('المادة * — تسمية موحدة'),
        const SizedBox(height: 6),
        if (!_newSubject)
          Row(children: [
            Expanded(child: _dropdown(_subjectOptions(), _subject, (v) => setState(() { _subject = v; _teacher = null; }))),
            TextButton.icon(
              onPressed: () => setState(() => _newSubject = true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('مادة جديدة', style: TextStyle(fontSize: 11.5)),
            ),
          ])
        else
          Row(children: [
            Expanded(child: TextField(controller: _newSubjectCtrl, decoration: _dec('اسم المادة الجديدة'))),
            TextButton(onPressed: () => setState(() => _newSubject = false), child: const Text('إلغاء')),
          ]),
        const SizedBox(height: 14),
        _label('المدرس *'),
        const SizedBox(height: 6),
        _dropdown(teacherItems, _teacher, (v) => setState(() => _teacher = v)),
        const SizedBox(height: 14),
        _label('الفترة *'),
        const SizedBox(height: 6),
        Row(children: [
          for (final period in kPeriods)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(period == 'صباحي' ? '☀ صباحي' : (period == 'ظهر' ? '🌤 ظهر' : '🌙 مسائي')),
                selected: _period == period,
                selectedColor: AppTheme.seed.withOpacity(.15),
                onSelected: (_) => setState(() {
                  _period = period;
                  if (_time.text.trim().isEmpty || _time.text.trim() == _defaultTime(_period)) {
                    _time.text = _defaultTime(period);
                  }
                }),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        _label('حالة الدورة'),
        const SizedBox(height: 6),
        _dropdown(const ['open', 'running', 'closed'], _status, (v) => setState(() => _status = v ?? 'open')),
        const SizedBox(height: 14),
        _label('أيام الدوام *'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in const ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'])
              FilterChip(
                label: Text(day),
                selected: _days.contains(day),
                onSelected: (_) => setState(() {
                  if (_days.contains(day)) {
                    _days.remove(day);
                  } else {
                    _days.add(day);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _label('الوقت'),
        TextField(controller: _time, decoration: _dec('مثال: 5:00م أو 1:00 ظهرًا')),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _numberField(_room, 'القاعة', keyboardType: TextInputType.text)),
          const SizedBox(width: 10),
          Expanded(child: _numberField(_capacity, 'السعة')),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _numberField(_sessionsDone, 'الجلسات المنفذة')),
          const SizedBox(width: 10),
          Expanded(child: _numberField(_sessionsTotal, 'إجمالي الجلسات')),
        ]),
        const SizedBox(height: 14),
        if (AppSession.canViewFinancial) ...[
          Row(children: [
            Expanded(child: _numberField(_price, _system == 'نظام ساعات' ? 'رسم الساعة' : 'رسم الدورة')),
            const SizedBox(width: 10),
            Expanded(child: _numberField(_teacherPct, 'نسبة المعلم %')),
          ]),
          if (_system != 'نظام ساعات') ...[
            const SizedBox(height: 14),
            _label('طريقة تحصيل رسم الدورة'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in const [1, 2, 3, 4, 6])
                  ChoiceChip(
                    label: Text(n == 1 ? 'كامل الرسم' : '$n دفعات'),
                    selected: _installments == n,
                    onSelected: (_) => setState(() => _installments = n),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SwitchListTile(
            value: _financeLocked,
            onChanged: (v) => setState(() => _financeLocked = v),
            contentPadding: EdgeInsets.zero,
            title: const Text('قفل مالي لهذه الدورة'),
            subtitle: const Text('يُستخدم لاحقًا لتقييد التعديلات المالية بعد الإغلاق.'),
          ),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: PrimaryButton(
              _editing ? 'حفظ التعديلات' : 'حفظ الدورة',
              icon: Icons.save_outlined,
              onPressed: _save,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2));

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.line),
        ),
      );

  Widget _dropdown(List<String> items, String? value, void Function(String?) onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.line), borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: (value != null && items.contains(value)) ? value : null,
            isExpanded: true,
            hint: const Text('اختر...', style: TextStyle(fontSize: 12.5)),
            items: [
              for (final i in items)
                DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis)),
            ],
            onChanged: onChanged,
          ),
        ),
      );

  Widget _numberField(TextEditingController controller, String label,
          {TextInputType keyboardType = TextInputType.number}) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: _dec(label),
      );

  List<String> _subjectOptions() {
    return <String>{...kSubjectNames, ...store.subjects.map((s) => s.name)}.toList();
  }

  List<String> _typeOptions() {
    return <String>{...kCourseTypes, ...store.groups.map((g) => g.type).where((v) => v.trim().isNotEmpty)}.toList();
  }

  List<String> _teacherOptions(String? subject) {
    final labels = <String>[];
    for (final t in kTeachers) {
      labels.add(_teacherLabel(t.name, t.subject));
    }
    for (final t in store.teachers) {
      labels.add(_teacherLabel(t.name, t.specialization));
    }

    final unique = labels.toSet().toList();
    if (subject == null || subject.trim().isEmpty) return unique;

    final matched = unique.where((t) => _looseMatch(t, subject)).toList();
    final others = unique.where((t) => !_looseMatch(t, subject)).toList();
    return [...matched, ...others];
  }

  String _teacherLabel(String name, String subject) => '$name — $subject';

  (Set<String>, String) _parseSchedule(String schedule) {
    if (schedule.trim().isEmpty) return (<String>{}, '');
    final parts = schedule.split('•');
    final daysPart = parts.first.trim();
    final timePart = parts.length > 1 ? parts.sublist(1).join('•').trim() : '';
    final result = <String>{};
    for (final d in const ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس']) {
      if (daysPart.contains(d)) result.add(d);
    }
    return (result, timePart);
  }

  String _defaultTime(String period) {
    if (period == 'صباحي') return '10:00ص';
    if (period == 'ظهر') return '1:00 ظهرًا';
    return '5:00م';
  }

  bool _looseMatch(String a, String b) {
    final normA = a.replaceAll('اللغة', '').replaceAll('—', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final normB = b.replaceAll('اللغة', '').replaceAll('—', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final aTokens = normA.split(' ').where((e) => e.length > 2).toSet();
    final bTokens = normB.split(' ').where((e) => e.length > 2).toSet();
    return aTokens.intersection(bTokens).isNotEmpty;
  }

  Future<void> _save() async {
    final subject = _newSubject ? _newSubjectCtrl.text.trim() : (_subject ?? '').trim();
    final type = _newType ? _newTypeCtrl.text.trim() : (_type ?? '').trim();
    final teacherName = (_teacher ?? '').split(' — ').first.trim();
    final daysText = _days.toList().join(' + ');
    final timeText = _time.text.trim().isEmpty ? _defaultTime(_period) : _time.text.trim();
    final schedule = _days.isEmpty ? '' : '$daysText • $timeText';

    if (_name.text.trim().isEmpty || subject.isEmpty || teacherName.isEmpty || schedule.isEmpty) {
      setState(() => _msg = '⚠ أكمل: اسم الدورة، المادة، المدرس، وأيام الدوام.');
      return;
    }

    addSubjectIfNew(subject);
    if (type.isNotEmpty) addCourseTypeIfNew(type);

    final result = await store.saveGroup(
      groupId: widget.existing?.id,
      name: _name.text.trim(),
      subject: subject,
      teacher: teacherName,
      period: _period,
      system: _system,
      room: _room.text.trim(),
      days: schedule,
      price: double.tryParse(_price.text) ?? 0.0,
      capacity: int.tryParse(_capacity.text) ?? 12,
      enrolledCount: widget.existing?.enrolled ?? 0,
      waitingCount: widget.existing?.waiting ?? 0,
      status: _status,
      type: type,
      sessionsDone: int.tryParse(_sessionsDone.text) ?? 0,
      sessionsTotal: int.tryParse(_sessionsTotal.text) ?? 12,
      installments: _system == 'نظام ساعات' ? 1 : _installments,
      teacherPct: AppSession.canViewFinancial ? (double.tryParse(_teacherPct.text) ?? 0.0) : (widget.existing?.teacherPct ?? 0.0),
      financeLocked: AppSession.canViewFinancial ? _financeLocked : (widget.existing?.financeLocked ?? false),
    );

    if (!mounted) return;
    if (!result.ok) {
      setState(() => _msg = result.message);
      return;
    }

    widget.onSaved(result.message);
    Navigator.pop(context);
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'running':
      return 'منطلقة';
    case 'closed':
      return 'مغلقة';
    case 'pending':
      return 'بانتظار اعتماد';
    default:
      return 'مفتوحة';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'running':
      return AppTheme.success;
    case 'closed':
      return AppTheme.dark2;
    case 'pending':
      return AppTheme.gold;
    default:
      return AppTheme.seed;
  }
}

String _fmtDate(String raw) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}
