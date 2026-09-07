import 'package:flutter/material.dart';

import '../data/registration_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// التسجيل وقوائم الانتظار — الآن مربوط بقاعدة بيانات SQLite محلية
/// المرحلة الحالية: حفظ دائم لطلبات التسجيل + الاعتماد + قوائم الانتظار
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final store = RegistrationStore.instance;

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, width: 420));

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
                const Icon(Icons.storage, size: 34, color: AppTheme.danger),
                const SizedBox(height: 10),
                const Text('تعذر تهيئة قاعدة البيانات المحلية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                const SizedBox(height: 8),
                Text(store.error!, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
                const SizedBox(height: 14),
                PrimaryButton('إعادة المحاولة', icon: Icons.refresh, onPressed: () => store.init()),
              ]),
            ),
          );
        }

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
                  Tab(height: 46, text: 'طلبات التسجيل (${store.requests.length})'),
                  Tab(height: 46, text: 'قوائم الانتظار (${store.waiting.length})'),
                  const Tab(height: 46, text: 'طلب جديد'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: TabBarView(children: [
                _RequestsTab(onSnack: _snack),
                _WaitingTab(onSnack: _snack),
                _NewRequestTab(onSnack: _snack),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final void Function(String) onSnack;
  const _RequestsTab({required this.onSnack});

  Future<void> _handleApprove(BuildContext context, RegistrationRequestItem request) async {
    final store = RegistrationStore.instance;
    final plan = store.approvalPlanForRequest(request);
    if (plan.canDirectApprove) {
      final result = await store.approveRequest(request.id);
      onSnack(result.message);
      return;
    }

    showSidePanel(
      context,
      title: 'توجيه اعتماد الطلب',
      builder: (_) => _ApprovalRoutingPanel(request: request, plan: plan, onSnack: onSnack),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = RegistrationStore.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
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
                'هذه الشاشة تحفظ الطلبات فعليًا داخل قاعدة بيانات SQLite محلية. أي طلب جديد أو اعتماد أو رفض سيبقى بعد إغلاق البرنامج.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.seed, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: store.isBusy ? null : () => store.refresh(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('تحديث', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed: store.isBusy
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('تهيئة قاعدة فارغة'),
                              content: const Text('سيتم حذف كل البيانات المحلية نهائيًا: طلاب، دورات، طلبات، وانتظار. هل تريد المتابعة؟'),
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
                      onSnack(result.message);
                    },
              icon: const Icon(Icons.cleaning_services_outlined, size: 16),
              label: const Text('تهيئة فارغة', style: TextStyle(fontSize: 12)),
            ),
          ]),
        ),
        for (final r in store.requests)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: cardDeco(),
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.purple.withOpacity(.1),
                child: const Icon(Icons.person_outline, color: AppTheme.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.studentLabel,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                  const SizedBox(height: 3),
                  Text('يرغب بـ: ${r.subjectName}  •  المدرس: ${r.teacherName}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
                  if ((r.decisionNote ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(r.decisionNote!, style: const TextStyle(fontSize: 11.5, color: AppTheme.purple)),
                  ],
                ]),
              ),
              PeriodBadge(r.period),
              const SizedBox(width: 10),
              Text(_fmtDate(r.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.textSub)),
              const SizedBox(width: 10),
              if (r.status == 'معلق') ...[
                IconButton(
                  tooltip: 'اعتماد',
                  onPressed: store.isBusy ? null : () => _handleApprove(context, r),
                  icon: const Icon(Icons.check_circle, color: AppTheme.success),
                ),
                IconButton(
                  tooltip: 'رفض',
                  onPressed: store.isBusy
                      ? null
                      : () async {
                          final result = await store.rejectRequest(r.id);
                          onSnack(result.message);
                        },
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

class _WaitingTab extends StatelessWidget {
  final void Function(String) onSnack;
  const _WaitingTab({required this.onSnack});

  @override
  Widget build(BuildContext context) {
    final store = RegistrationStore.instance;
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
            Expanded(
              child: Text(
                'إذا كانت الدورة المطلوبة مكتملة أو مغلقة، تستطيع الإدارة الآن اختيار دورة بديلة مفتوحة أو وضع الطالب على قائمة انتظار المدرس نفسه، ويُحفظ القرار محليًا.',
                style: TextStyle(fontSize: 12, color: AppTheme.gold, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SimpleTable(
          columns: const ['الطالب', 'المادة', 'المدرس المطلوب', 'الفترة', 'تاريخ الإضافة', 'إجراء'],
          rows: [
            for (final w in store.waiting)
              [
                Text(w.studentLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(w.subjectName),
                Text(w.teacherName),
                PeriodBadge(w.period),
                Text(_fmtDate(w.createdAt), style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub)),
                ElevatedButton(
                  onPressed: () => onSnack('🔔 عند توفر مقعد لدى ${w.teacherName} سيُشعَر الطالب ${w.studentName}.'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.seed.withOpacity(.1),
                    foregroundColor: AppTheme.seed,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('إشعار عند التوفر', style: TextStyle(fontSize: 11.5)),
                ),
              ],
          ],
        ),
      ]),
    );
  }
}

class _ApprovalRoutingPanel extends StatefulWidget {
  final RegistrationRequestItem request;
  final ApprovalRoutingPlan plan;
  final void Function(String) onSnack;
  const _ApprovalRoutingPanel({required this.request, required this.plan, required this.onSnack});

  @override
  State<_ApprovalRoutingPanel> createState() => _ApprovalRoutingPanelState();
}

class _ApprovalRoutingPanelState extends State<_ApprovalRoutingPanel> {
  final store = RegistrationStore.instance;

  Future<void> _approveAlternative(GroupOption group) async {
    final note = group.teacher == widget.request.teacherName
        ? 'تم اعتماد الطلب وتسجيل الطالب في دورة مفتوحة مع المدرس المطلوب.'
        : 'تم اعتماد الطلب بتحويل الطالب إلى دورة بديلة مفتوحة: ${group.name}.';
    final result = await store.approveRequestToGroup(widget.request.id, group.id, note: note);
    if (!mounted) return;
    if (result.ok) {
      Navigator.pop(context);
    }
    widget.onSnack(result.message);
  }

  Future<void> _moveToWaiting() async {
    final result = await store.moveRequestToWaiting(widget.request.id);
    if (!mounted) return;
    if (result.ok) {
      Navigator.pop(context);
    }
    widget.onSnack(result.message);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final preferred = plan.preferredGroup;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gold.withOpacity(.28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.request.studentLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dark)),
            const SizedBox(height: 4),
            Text('الطلب الأصلي: ${widget.request.subjectName} • ${widget.request.teacherName} • ${store.periodLabel(widget.request.period)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
            const SizedBox(height: 8),
            Text(plan.message,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.gold)),
          ]),
        ),
        if (preferred != null) ...[
          const SizedBox(height: 14),
          SectionCard(
            'الدورة المطلوبة أصلًا',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(preferred.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dark)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                StatusChip(preferred.system, color: preferred.isHoursSystem ? AppTheme.gold : AppTheme.seed),
                StatusChip(
                  preferred.status == 'closed'
                      ? 'مغلقة'
                      : (preferred.isFull ? 'مكتملة' : (preferred.status == 'running' ? 'منطلقة' : 'مفتوحة')),
                  color: preferred.status == 'closed'
                      ? AppTheme.danger
                      : (preferred.isFull ? AppTheme.gold : AppTheme.success),
                ),
              ]),
              const SizedBox(height: 8),
              Text('المدرس: ${preferred.teacher}', style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
              Text('الجدول: ${preferred.days}', style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
              Text('المقاعد المتاحة: ${preferred.seatsLeft > 0 ? preferred.seatsLeft : 0}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: preferred.seatsLeft > 0 ? AppTheme.success : AppTheme.danger)),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        SectionCard(
          'الدورات المفتوحة البديلة',
          child: plan.alternatives.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('لا توجد حاليًا دورات مفتوحة بديلة لنفس المادة والفترة.',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
                )
              : Column(
                  children: [
                    for (final alt in plan.alternatives)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.success.withOpacity(.2)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(
                              child: Text(alt.name,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                            ),
                            PeriodBadge(alt.period),
                          ]),
                          const SizedBox(height: 6),
                          Text('${alt.subject} • ${alt.teacher}', style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub)),
                          Text('متاح ${alt.seatsLeft} مقعد',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.success)),
                          const SizedBox(height: 8),
                          PrimaryButton(
                            'اعتماد في هذه الدورة',
                            icon: Icons.open_in_new,
                            color: AppTheme.success,
                            onPressed: store.isBusy ? null : () => _approveAlternative(alt),
                          ),
                        ]),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          'وضع الطالب على قائمة انتظار المدرس المطلوب',
          icon: Icons.hourglass_top,
          color: AppTheme.gold,
          onPressed: store.isBusy ? null : _moveToWaiting,
        ),
        const SizedBox(height: 8),
        Text(
          'هذا الخيار يحافظ على رغبة الطالب الأصلية: نفس المادة ونفس المدرس المفضل، حتى لو كانت الدورة مغلقة أو مكتملة الآن.',
          style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub),
        ),
      ],
    );
  }
}

class _NewRequestTab extends StatefulWidget {
  final void Function(String) onSnack;
  const _NewRequestTab({required this.onSnack});

  @override
  State<_NewRequestTab> createState() => _NewRequestTabState();
}

class _NewRequestTabState extends State<_NewRequestTab> {
  final store = RegistrationStore.instance;

  int? _studentId;
  int? _subjectId;
  int? _teacherId;
  String _period = 'مسائي';

  @override
  Widget build(BuildContext context) {
    final teachers = store.teachersForSubject(_subjectId);
    final preview = store.preview(subjectId: _subjectId, teacherId: _teacherId, period: _period);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: cardDeco(),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('طلب تسجيل جديد — حفظ دائم',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.dark)),
          const SizedBox(height: 6),
          const Text(
            'هذه النسخة تحفظ الطلب داخل قاعدة SQLite محلية، ثم يظهر فورًا في تبويب الطلبات ويستمر بعد إغلاق البرنامج.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSub),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: _dropdownInt(
                label: 'الطالب',
                value: _studentId,
                items: [for (final s in store.students) (s.id, s.label)],
                onChanged: (v) => setState(() => _studentId = v),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _dropdownInt(
                label: 'المادة',
                value: _subjectId,
                items: [for (final s in store.subjects) (s.id, s.name)],
                onChanged: (v) => setState(() {
                  _subjectId = v;
                  _teacherId = null;
                }),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _dropdownInt(
                label: 'المدرس المفضل',
                value: _teacherId,
                items: [for (final t in teachers) (t.id, '${t.name} — ${t.specialization}')],
                onChanged: (v) => setState(() => _teacherId = v),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: AppTheme.line), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(children: [
                  const Text('الفترة المفضلة:', style: TextStyle(fontSize: 12.5, color: AppTheme.textSub)),
                  const Spacer(),
                  for (final p in const ['صباحي', 'ظهر', 'مسائي'])
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(
                          p == 'صباحي' ? '☀ صباحي' : (p == 'ظهر' ? '🌤 ظهر' : '🌙 مسائي'),
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: _period == p,
                        selectedColor: AppTheme.seed.withOpacity(.2),
                        onSelected: (_) => setState(() => _period = p),
                      ),
                    ),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          if (_teacherId != null && _subjectId != null)
            _PreviewCard(preview: preview),
          const SizedBox(height: 16),
          if (preview.alternatives.isNotEmpty) ...[
            const Text('مدرسون/مجموعات بديلة متاحة في نفس المادة والفترة',
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
                      border: Border.all(color: AppTheme.success.withOpacity(.25)),
                    ),
                    child: Text('${alt.teacher} • ${alt.name} • متاح ${alt.seatsLeft} مقعد',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.success)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          PrimaryButton(
            store.isBusy ? 'جارٍ الحفظ...' : 'إرسال الطلب للاعتماد الإداري',
            icon: Icons.send,
            onPressed: (_studentId == null || _subjectId == null || _teacherId == null || store.isBusy)
                ? null
                : () async {
                    final result = await store.submitRequest(
                      studentId: _studentId!,
                      subjectId: _subjectId!,
                      teacherId: _teacherId!,
                      period: _period,
                    );
                    widget.onSnack(result.message);
                    if (!result.ok) return;
                    setState(() {
                      _studentId = null;
                      _subjectId = null;
                      _teacherId = null;
                      _period = 'مسائي';
                    });
                  },
          ),
        ]),
      ),
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

class _PreviewCard extends StatelessWidget {
  final RegistrationPreview preview;
  const _PreviewCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    final full = preview.isFull;
    final hasGroup = preview.hasExactGroup;
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
                    ? 'لا توجد مجموعة مطابقة تمامًا حاليًا لهذا المدرس/الفترة، لكن توجد بدائل مفتوحة وستظهر للإدارة عند الاعتماد مع خيار وضع الطالب على الانتظار.'
                    : 'لا توجد مجموعة مطابقة تمامًا حاليًا لهذا المدرس/الفترة. سيُحفظ الطلب ويظهر للإدارة للمراجعة أو توجيهه لاحقًا.')
                : (full
                    ? 'المجموعة المطلوبة مكتملة. عند الاعتماد ستظهر بدائل مفتوحة إن وُجدت، أو يمكن وضع الطالب على قائمة الانتظار.'
                    : 'توجد مجموعة متاحة ويمكن عند الاعتماد تسجيل الطالب مباشرة.'),
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

String _fmtDate(String raw) {
  try {
    final dt = DateTime.parse(raw).toLocal();
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
  } catch (_) {
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw;
  }
}
