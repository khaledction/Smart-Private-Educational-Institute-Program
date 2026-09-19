import 'package:flutter/material.dart';

import '../data/app_session.dart';
import '../data/mock_data.dart';
import '../data/registration_store.dart';
import '../data/student_store.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// لوحة القيادة الرئيسية — نظرة شاملة فورية (§9.2 من الوثيقة)
class DashboardScreen extends StatelessWidget {
  final void Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final regStore = RegistrationStore.instance;
    final studentStore = StudentStore.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([regStore, studentStore, AppSession.instance]),
      builder: (context, _) {
        final groups = regStore.isReady ? regStore.groups : const <GroupOption>[];
        final pendingGroups = groups.where((g) => g.status == 'pending').toList();
        final activeStudents = studentStore.isReady
            ? studentStore.activeCount
            : kStudents.where((s) => s.status == 'نشط').length;
        final pendingReq = regStore.isReady ? regStore.pendingCount : kRequests.where((r) => r.status == 'معلق').length;
        final waitingTotal = regStore.isReady ? regStore.waitingCount : kWaiting.length;
        final revenueMonth = kInvoices.fold<double>(0.0, (s, i) => s + i.paid);
        final overdue = kInvoices
            .where((i) => i.status == 'متأخر')
            .fold<double>(0.0, (s, i) => s + ((i.total - i.paid) > 0 ? (i.total - i.paid) : 0.0));
        final currentGroups = regStore.isReady
            ? groups.where((g) => g.status == 'open' || g.status == 'running').length
            : kGroups.where((g) => g.status == 'running').length;
        final totalGroups = regStore.isReady ? groups.length : kGroups.length;
        final todaySessions = kSessions.length;
        final lowInventory = kInventory.where((i) => i.low).length;
        final subjectDistributionTotal = kSubjectDistribution.fold<double>(0.0, (s, item) => s + item.$2).round();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: StatCard(Icons.school, 'طلاب نشطون', '$activeStudents', trend: '+3 هذا الأسبوع')),
                  Expanded(child: StatCard(Icons.auto_stories, 'دورات فعّالة', '$currentGroups / $totalGroups', color: AppTheme.purple)),
                  Expanded(child: StatCard(Icons.pending_actions, 'طلبات تسجيل معلقة', '$pendingReq', color: AppTheme.gold)),
                  Expanded(child: StatCard(Icons.schedule_send, 'قوائم الانتظار', '$waitingTotal', color: AppTheme.danger)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: StatCard(Icons.payments, 'إيرادات أيلول', money(revenueMonth), color: AppTheme.success, trend: '+12% عن آب')),
                  Expanded(child: StatCard(Icons.account_balance_wallet, 'مستحقات متأخرة', money(overdue), color: AppTheme.danger)),
                  Expanded(child: StatCard(Icons.calendar_month, 'جلسات اليوم', '$todaySessions', color: AppTheme.purple)),
                  Expanded(child: StatCard(Icons.inventory_2, 'أصناف تحت الحد', '$lowInventory', color: AppTheme.gold)),
                ],
              ),
              if (AppSession.canApproveCourses) ...[
                const SizedBox(height: 20),
                SectionCard(
                  'اعتماد الدورات الجديدة من لوحة القيادة',
                  actionLabel: pendingGroups.isEmpty ? null : 'فتح شاشة الدورات',
                  onAction: pendingGroups.isEmpty ? null : () => onNavigate?.call(3),
                  child: pendingGroups.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'لا توجد حاليًا دورات جديدة بانتظار اعتماد الإدارة.',
                            style: TextStyle(fontSize: 12.5, color: AppTheme.textSub),
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withOpacity(.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.gold.withOpacity(.22)),
                              ),
                              child: const Text(
                                'أي دورة ينشئها مستخدم الدورات تظهر هنا أولًا. يستطيع المدير مراجعة السعة ورسم الدورة أو الساعة وعدد الأقساط وقيمة القسط أو عدد الساعات ونسبة المدرس، ثم التعديل والاعتماد لتصبح متاحة لإضافة الطلاب.',
                                style: TextStyle(fontSize: 12.5, color: AppTheme.dark2, height: 1.6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final group in pendingGroups)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.line),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                group.name,
                                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.dark),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${group.subject} • ${group.teacher} • ${group.period == 'ظهر' ? 'ظهر' : group.period}',
                                                style: const TextStyle(fontSize: 12, color: AppTheme.textSub),
                                              ),
                                            ],
                                          ),
                                        ),
                                        StatusChip('بانتظار الموافقة', color: AppTheme.gold),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: [
                                        _ApprovalInfoChip('السعة', '${group.capacity} طالب'),
                                        _ApprovalInfoChip(group.isHoursSystem ? 'رسم الساعة' : 'رسم الدورة', money(group.price)),
                                        _ApprovalInfoChip(
                                          group.isHoursSystem ? 'عدد الساعات' : 'عدد الأقساط',
                                          group.isHoursSystem
                                              ? '${group.sessionsTotal} ساعة'
                                              : (group.installments == 1 ? 'كامل الرسم' : '${group.installments} أقساط'),
                                        ),
                                        _ApprovalInfoChip(
                                          group.isHoursSystem ? 'إجمالي رسم الطالب' : 'قيمة القسط',
                                          money(group.isHoursSystem ? group.studentTotalPlannedFee : group.installmentAmount),
                                        ),
                                        _ApprovalInfoChip('نسبة المدرس', '%${group.teacherPct.toStringAsFixed(0)}'),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        PrimaryButton(
                                          'تعديل من لوحة القيادة',
                                          icon: Icons.edit_outlined,
                                          color: AppTheme.dark2,
                                          onPressed: () => showSidePanel(
                                            context,
                                            title: 'مراجعة واعتماد دورة جديدة',
                                            builder: (_) => _DashboardPendingApprovalPanel(
                                              group: group,
                                              onDone: (msg) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, width: 560),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        PrimaryButton(
                                          'اعتماد مباشر',
                                          icon: Icons.verified_outlined,
                                          color: AppTheme.success,
                                          onPressed: () async {
                                            final result = await regStore.approveGroup(group.id);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(result.message), behavior: SnackBarBehavior.floating, width: 560),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: SectionCard('الإيرادات — آخر 6 أشهر (مليون ل.س)', child: BarsChart(kRevenueMonths)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SectionCard(
                      'توزيع الطلاب على المواد',
                      child: Row(
                        children: [
                          DonutChart(kSubjectDistribution, centerValue: '$subjectDistributionTotal', centerLabel: 'طالب'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                for (final (name, v, c) in kSubjectDistribution)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(name, style: const TextStyle(fontSize: 11.5))),
                                        Text('$v', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: SectionCard(
                      'تنبيهات ذكية',
                      actionLabel: 'عرض الكل',
                      onAction: AppSession.canAccessRegistration ? () => onNavigate?.call(2) : null,
                      child: Column(children: [for (final n in kNotifications.take(4)) _AlertTile(n)]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: SectionCard(
                      'إجراءات سريعة',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (AppSession.canAccessRegistration)
                            PrimaryButton('طلب تسجيل جديد', icon: Icons.person_add_alt_1, onPressed: () => onNavigate?.call(2)),
                          if (AppSession.canAccessCourses)
                            PrimaryButton('مجموعة جديدة', icon: Icons.add_circle, onPressed: () => onNavigate?.call(3), color: AppTheme.dark2),
                          if (AppSession.canAccessStudents)
                            PrimaryButton('ملفات الطلاب', icon: Icons.groups_2, onPressed: () => onNavigate?.call(1), color: AppTheme.seed),
                          if (AppSession.canAccessAccountingArea)
                            PrimaryButton('سداد قسط', icon: Icons.point_of_sale, onPressed: () => onNavigate?.call(8), color: AppTheme.gold),
                          if (AppSession.canAccessAccountingArea)
                            PrimaryButton('إضافة صرفية', icon: Icons.receipt_long, onPressed: () => onNavigate?.call(9), color: AppTheme.purple),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ApprovalInfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _ApprovalInfoChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.line),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
    );
  }
}

class _DashboardPendingApprovalPanel extends StatefulWidget {
  final GroupOption group;
  final void Function(String) onDone;
  const _DashboardPendingApprovalPanel({required this.group, required this.onDone});

  @override
  State<_DashboardPendingApprovalPanel> createState() => _DashboardPendingApprovalPanelState();
}

class _DashboardPendingApprovalPanelState extends State<_DashboardPendingApprovalPanel> {
  final store = RegistrationStore.instance;
  late final TextEditingController _capacity;
  late final TextEditingController _price;
  late final TextEditingController _sessionsTotal;
  late final TextEditingController _teacherPct;
  late int _installments;
  String _message = '';
  bool _saving = false;

  GroupOption get group => widget.group;

  @override
  void initState() {
    super.initState();
    _capacity = TextEditingController(text: group.capacity.toString());
    _price = TextEditingController(text: group.price.toStringAsFixed(0));
    _sessionsTotal = TextEditingController(text: group.sessionsTotal.toString());
    _teacherPct = TextEditingController(text: group.teacherPct.toStringAsFixed(0));
    _installments = group.installments < 1 ? 1 : group.installments;
  }

  @override
  void dispose() {
    _capacity.dispose();
    _price.dispose();
    _sessionsTotal.dispose();
    _teacherPct.dispose();
    super.dispose();
  }

  double get _priceValue => double.tryParse(_price.text.trim()) ?? 0.0;
  int get _sessionsValue => int.tryParse(_sessionsTotal.text.trim()) ?? group.sessionsTotal;
  int get _capacityValue => int.tryParse(_capacity.text.trim()) ?? group.capacity;
  double get _teacherPctValue => double.tryParse(_teacherPct.text.trim()) ?? group.teacherPct;

  Future<void> _save({required bool approveNow}) async {
    setState(() {
      _saving = true;
      _message = '';
    });
    final saveResult = await store.saveGroup(
      groupId: group.id,
      name: group.name,
      subject: group.subject,
      teacher: group.teacher,
      period: group.period,
      system: group.system,
      room: group.room,
      days: group.days,
      price: _priceValue,
      capacity: _capacityValue,
      enrolledCount: group.enrolled,
      waitingCount: group.waiting,
      status: 'pending',
      type: group.type,
      sessionsDone: group.sessionsDone,
      sessionsTotal: _sessionsValue,
      installments: group.isHoursSystem ? 1 : _installments,
      teacherPct: _teacherPctValue,
      financeLocked: group.financeLocked,
    );
    if (!saveResult.ok) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = saveResult.message;
      });
      return;
    }

    var finalMessage = saveResult.message;
    if (approveNow) {
      final approveResult = await store.approveGroup(group.id);
      finalMessage = '${saveResult.message}\n${approveResult.message}';
      if (!approveResult.ok) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _message = approveResult.message;
        });
        return;
      }
    }

    if (!mounted) return;
    widget.onDone(finalMessage);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final installmentAmount = group.isHoursSystem
        ? _priceValue * (_sessionsValue <= 0 ? 0 : _sessionsValue)
        : (_installments <= 1 ? _priceValue : (_priceValue / _installments));

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.gold.withOpacity(.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppTheme.dark)),
              const SizedBox(height: 6),
              Text('${group.subject} • ${group.teacher} • ${group.period}', style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
              const SizedBox(height: 4),
              const Text(
                'هذه الدورة أُنشئت من قسم الدورات وما تزال بانتظار قرار الإدارة. يمكنك تعديل الإعدادات التالية ثم الحفظ فقط أو الحفظ مع الاعتماد.',
                style: TextStyle(fontSize: 12, color: AppTheme.dark2, height: 1.5),
              ),
            ],
          ),
        ),
        if (_message.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.danger.withOpacity(.22)),
            ),
            child: Text(_message, style: const TextStyle(fontSize: 12.5, color: AppTheme.danger, fontWeight: FontWeight.bold)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextField(controller: _capacity, keyboardType: TextInputType.number, decoration: fieldDeco('عدد الطلاب / السعة'))),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: fieldDeco(group.isHoursSystem ? 'رسم الساعة' : 'رسم الدورة'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _sessionsTotal,
                keyboardType: TextInputType.number,
                decoration: fieldDeco(group.isHoursSystem ? 'عدد الساعات المعتمدة' : 'إجمالي الجلسات'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _teacherPct,
                keyboardType: TextInputType.number,
                decoration: fieldDeco('نسبة المدرس %'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (!group.isHoursSystem) ...[
          const SizedBox(height: 14),
          const Text('عدد الأقساط', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in const [1, 2, 3, 4, 6])
                ChoiceChip(
                  label: Text(n == 1 ? 'كامل الرسم' : '$n أقساط'),
                  selected: _installments == n,
                  onSelected: (_) => setState(() => _installments = n),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.panel2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.isHoursSystem ? 'ملخص نظام الساعات قبل الاعتماد' : 'ملخص رسم الدورة قبل الاعتماد',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark)),
              const SizedBox(height: 8),
              InfoRow('السعة المعتمدة', '${_capacityValue <= 0 ? 1 : _capacityValue} طالب'),
              InfoRow(group.isHoursSystem ? 'رسم الساعة' : 'رسم الدورة', money(_priceValue)),
              if (group.isHoursSystem) ...[
                InfoRow('عدد الساعات', '${_sessionsValue <= 0 ? 1 : _sessionsValue} ساعة'),
                InfoRow('إجمالي رسم الطالب', money(installmentAmount), valueColor: AppTheme.purple),
              ] else ...[
                InfoRow('عدد الأقساط', _installments == 1 ? 'كامل الرسم' : '$_installments أقساط'),
                InfoRow('قيمة القسط', money(installmentAmount), valueColor: AppTheme.gold),
              ],
              InfoRow('نسبة المدرس', '%${_teacherPctValue.toStringAsFixed(0)}'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('إلغاء'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                _saving ? 'جارٍ الحفظ...' : 'حفظ التعديل فقط',
                icon: Icons.save_outlined,
                color: AppTheme.dark2,
                onPressed: _saving ? null : () => _save(approveNow: false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                _saving ? 'جارٍ الاعتماد...' : 'حفظ ثم اعتماد',
                icon: Icons.verified_outlined,
                color: AppTheme.success,
                onPressed: _saving ? null : () => _save(approveNow: true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final NotificationItem n;
  const _AlertTile(this.n);

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (n.type) {
      'request' => (Icons.person_add_alt, AppTheme.seed),
      'waiting' => (Icons.schedule_send, AppTheme.purple),
      'payment' => (Icons.credit_card, AppTheme.gold),
      'stock' => (Icons.inventory_2, AppTheme.danger),
      _ => (Icons.warning_amber, AppTheme.danger),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.dark)),
                Text(n.body, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSub), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(n.time, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSub)),
        ],
      ),
    );
  }
}
