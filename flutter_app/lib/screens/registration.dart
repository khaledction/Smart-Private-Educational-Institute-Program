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
    if (!store.isReady) {
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
                  onPressed: store.isBusy
                      ? null
                      : () async {
                          final result = await store.approveRequest(r.id);
                          onSnack(result.message);
                        },
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
                'عند اعتماد طلبٍ لمجموعة مكتملة، يُنقل الطالب تلقائيًا إلى قائمة انتظار المدرس نفسه ويُحفظ ذلك في القاعدة المحلية.',
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
                ? 'لا توجد مجموعة مطابقة تمامًا حاليًا لهذا المدرس/الفترة. سيُحفظ الطلب ويظهر للإدارة للمراجعة أو توجيهه لاحقًا.'
                : (full
                    ? 'المجموعة المطلوبة مكتملة. عند الاعتماد سيُنقل الطالب تلقائيًا إلى قائمة الانتظار.'
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
