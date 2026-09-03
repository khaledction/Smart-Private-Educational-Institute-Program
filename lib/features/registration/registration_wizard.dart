import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/providers.dart';
import '../../data/models/models.dart';
import '../../data/repositories/institute_repository.dart';

/// ─── Wizard state ────────────────────────────────────────────────────────────

class WizardState {
  final int step;
  final Student? student;
  final Subject? subject;
  final StudyGroup? group;
  final double discount;
  final double amountPaid;

  const WizardState({
    this.step = 0,
    this.student,
    this.subject,
    this.group,
    this.discount = 0,
    this.amountPaid = 0,
  });

  WizardState copyWith({
    int? step,
    Student? student,
    Subject? subject,
    StudyGroup? group,
    double? discount,
    double? amountPaid,
    bool clearSubject = false,
    bool clearGroup = false,
  }) =>
      WizardState(
        step: step ?? this.step,
        student: student ?? this.student,
        subject: clearSubject ? null : (subject ?? this.subject),
        group: clearGroup ? null : (group ?? this.group),
        discount: discount ?? this.discount,
        amountPaid: amountPaid ?? this.amountPaid,
      );
}

final wizardProvider =
    StateProvider.autoDispose<WizardState>((ref) => const WizardState());

/// ─── Screen ──────────────────────────────────────────────────────────────────

class RegistrationWizardScreen extends ConsumerWidget {
  const RegistrationWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final wizard = ref.watch(wizardProvider);

    return Stepper(
      type: MediaQuery.of(context).size.width > 900
          ? StepperType.horizontal
          : StepperType.vertical,
      currentStep: wizard.step,
      controlsBuilder: (context, details) => const SizedBox.shrink(),
      onStepTapped: (i) {
        // Allow going back to completed steps only.
        if (i < wizard.step) {
          ref.read(wizardProvider.notifier).update((w) => w.copyWith(step: i));
        }
      },
      steps: [
        Step(
          title: Text(s.stepStudent),
          isActive: wizard.step >= 0,
          state: wizard.student != null ? StepState.complete : StepState.indexed,
          content: const _StudentStep(),
        ),
        Step(
          title: Text(s.stepSubject),
          isActive: wizard.step >= 1,
          state: wizard.subject != null ? StepState.complete : StepState.indexed,
          content: const _SubjectStep(),
        ),
        Step(
          title: Text(s.stepGroup),
          isActive: wizard.step >= 2,
          state: wizard.group != null ? StepState.complete : StepState.indexed,
          content: const _GroupStep(),
        ),
        Step(
          title: Text(s.stepPayment),
          isActive: wizard.step >= 3,
          content: const _PaymentStep(),
        ),
      ],
    );
  }
}

/// ─── Step 1 : Student identification (barcode / search / create) ────────────

class _StudentStep extends ConsumerStatefulWidget {
  const _StudentStep();

  @override
  ConsumerState<_StudentStep> createState() => _StudentStepState();
}

class _StudentStepState extends ConsumerState<_StudentStep> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _select(Student st) {
    ref
        .read(wizardProvider.notifier)
        .update((w) => w.copyWith(student: st, step: 1));
  }

  /// Barcode scanners "type" the code then send Enter → onSubmitted fires.
  void _onSubmitted(String value, List<Student> students) {
    final match = students.where((st) =>
        st.barcode.toLowerCase() == value.trim().toLowerCase());
    if (match.isNotEmpty) _select(match.first);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final wizard = ref.watch(wizardProvider);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (students) {
        final q = _query.trim().toLowerCase();
        final results = q.isEmpty
            ? students
            : students
                .where((st) =>
                    st.name.toLowerCase().contains(q) ||
                    st.phone.contains(q) ||
                    st.barcode.toLowerCase().contains(q))
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    hintText: s.scanBarcodeHint,
                    helperText: s.scanBarcodeHelp,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                  onSubmitted: (v) => _onSubmitted(v, students),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _showAddStudentDialog(context),
                icon: const Icon(Icons.person_add),
                label: Text(s.addNewStudent),
              ),
            ]),
            const SizedBox(height: 12),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.search_off, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(s.studentNotFound),
                ]),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final st = results[i];
                    final selected = wizard.student?.id == st.id;
                    return Card(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(child: Text(st.name.characters.first)),
                        title: Text(st.name),
                        subtitle: Text('${st.barcode} • ${st.phone}'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => _select(st),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showAddStudentDialog(BuildContext context) async {
    final s = ref.read(stringsProvider);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final gNameCtrl = TextEditingController();
    final gPhoneCtrl = TextEditingController();

    final created = await showDialog<Student>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.addNewStudent),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: s.name),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.required : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneCtrl,
                decoration: InputDecoration(labelText: s.phone),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.required : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: gNameCtrl,
                decoration: InputDecoration(labelText: s.guardianName),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: gPhoneCtrl,
                decoration: InputDecoration(labelText: s.guardianPhone),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              Text('${s.barcode}: (${s.autoGenerated})',
                  style: Theme.of(dialogContext).textTheme.bodySmall),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final st = await ref.read(repositoryProvider).addStudent(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    guardianName: gNameCtrl.text.trim(),
                    guardianPhone: gPhoneCtrl.text.trim(),
                  );
              if (dialogContext.mounted) Navigator.pop(dialogContext, st);
            },
            child: Text(s.save),
          ),
        ],
      ),
    );

    if (created != null) {
      ref.read(dataVersionProvider.notifier).state++;
      _select(created);
    }
  }
}

/// ─── Step 2 : Subject selection ──────────────────────────────────────────────

class _SubjectStep extends ConsumerWidget {
  const _SubjectStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final currency = ref.watch(currencyProvider);
    final wizard = ref.watch(wizardProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final regsAsync = ref.watch(registrationsProvider);
    final groupsAsync = ref.watch(groupsProvider);

    return subjectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (subjects) {
        final regs = regsAsync.value ?? [];
        final groups = groupsAsync.value ?? [];
        final enrolledSubjectIds = <String>{};
        if (wizard.student != null) {
          for (final r in regs.where((r) => r.studentId == wizard.student!.id)) {
            final g = groups.where((g) => g.id == r.groupId);
            if (g.isNotEmpty) enrolledSubjectIds.add(g.first.subjectId);
          }
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.chooseSubject,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: subjects.map((sub) {
              final enrolled = enrolledSubjectIds.contains(sub.id);
              final selected = wizard.subject?.id == sub.id;
              return SizedBox(
                width: 230,
                child: Card(
                  color: selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: enrolled
                        ? null
                        : () => ref.read(wizardProvider.notifier).update((w) =>
                            w.copyWith(
                                subject: sub, step: 2, clearGroup: true)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.menu_book,
                                color: enrolled
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(sub.name(s.ar),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color:
                                              enrolled ? Colors.grey : null)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text('${s.basePrice}: ${money(sub.basePrice, currency)}'),
                          Text('${sub.durationMonths} ${s.months}'),
                          if (enrolled)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Chip(
                                label: Text(s.alreadyEnrolled),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ]);
      },
    );
  }
}

/// ─── Step 3 : Group & teacher (with capacity + conflict detection) ──────────

class _GroupStep extends ConsumerWidget {
  const _GroupStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final currency = ref.watch(currencyProvider);
    final wizard = ref.watch(wizardProvider);
    final groupsAsync = ref.watch(groupsProvider);
    final teachers = ref.watch(teachersProvider).value ?? [];
    final regs = ref.watch(registrationsProvider).value ?? [];
    final subjects = ref.watch(subjectsProvider).value ?? [];

    if (wizard.subject == null) return Text(s.chooseSubject);

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (allGroups) {
        // The "smart" filter: only groups teaching the chosen subject.
        final groups = allGroups
            .where((g) => g.subjectId == wizard.subject!.id)
            .toList();

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${s.chooseGroup} — ${wizard.subject!.name(s.ar)}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...groups.map((g) {
            final teacher = teachers.firstWhere((t) => t.id == g.teacherId,
                orElse: () => const Teacher(id: '?', name: '?', specialization: ''));
            final price = g.effectivePrice(wizard.subject!);
            final conflict = wizard.student == null
                ? null
                : detectConflict(
                    candidate: g,
                    studentId: wizard.student!.id,
                    registrations: regs,
                    groups: allGroups,
                    subjects: subjects,
                  );
            final selectable = !g.isFull && conflict == null;
            final selected = wizard.group?.id == g.id;

            return Card(
              color: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                enabled: selectable,
                onTap: selectable
                    ? () => ref.read(wizardProvider.notifier).update(
                        (w) => w.copyWith(group: g, step: 3, amountPaid: price))
                    : null,
                leading: CircleAvatar(
                  backgroundColor: g.isFull
                      ? Colors.grey.shade300
                      : Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                  child: Icon(Icons.school,
                      color: g.isFull
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary),
                ),
                title: Row(children: [
                  Flexible(child: Text(teacher.name)),
                  const SizedBox(width: 8),
                  if (g.label == 'VIP')
                    Chip(
                      label: Text(s.vip),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.amber.shade100,
                    )
                  else if (g.label.isNotEmpty)
                    Chip(
                        label: Text(g.label),
                        visualDensity: VisualDensity.compact),
                ]),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scheduleText(g, s)),
                    if (conflict != null)
                      Text(
                        '⚠ ${s.conflict} — ${s.conflictWith}: '
                        '${conflict.existingSubject.name(s.ar)} '
                        '(${scheduleText(conflict.existingGroup, s)})',
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(money(price, currency),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    g.isFull
                        ? Text(s.full,
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold))
                        : Text('${g.seatsLeft} ${s.seatsLeft}'),
                  ],
                ),
              ),
            );
          }),
        ]);
      },
    );
  }
}

/// ─── Step 4 : Payment & receipt ──────────────────────────────────────────────

class _PaymentStep extends ConsumerStatefulWidget {
  const _PaymentStep();

  @override
  ConsumerState<_PaymentStep> createState() => _PaymentStepState();
}

class _PaymentStepState extends ConsumerState<_PaymentStep> {
  final _discountCtrl = TextEditingController(text: '0');
  final _paidCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _discountCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final currency = ref.watch(currencyProvider);
    final wizard = ref.watch(wizardProvider);
    final teachers = ref.watch(teachersProvider).value ?? [];

    if (wizard.student == null || wizard.subject == null || wizard.group == null) {
      return Text(s.chooseGroup);
    }

    final group = wizard.group!;
    final subject = wizard.subject!;
    final teacher = teachers.firstWhere((t) => t.id == group.teacherId,
        orElse: () => const Teacher(id: '?', name: '?', specialization: ''));
    final price = group.effectivePrice(subject);
    final discount = double.tryParse(_discountCtrl.text) ?? 0;
    final net = (price - discount).clamp(0, double.infinity).toDouble();
    if (_paidCtrl.text.isEmpty) _paidCtrl.text = net.toStringAsFixed(0);
    final paid = double.tryParse(_paidCtrl.text) ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.invoiceSummary,
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _row(s.student, wizard.student!.name),
            _row(s.subject, subject.name(s.ar)),
            _row(s.teacher, teacher.name),
            _row(s.schedule, scheduleText(group, s)),
            const Divider(),
            _row(s.price, money(price, currency)),
            _row(s.discount, '- ${money(discount, currency)}'),
            _row(s.netTotal, money(net, currency), bold: true),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _discountCtrl,
            decoration: InputDecoration(
                labelText: s.discount, prefixIcon: const Icon(Icons.percent)),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _paidCtrl,
            decoration: InputDecoration(
                labelText: s.amountPaid,
                prefixIcon: const Icon(Icons.payments)),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      if (paid < net)
        Text('${s.remaining}: ${money(net - paid, currency)}',
            style: const TextStyle(
                color: Colors.orange, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _busy ? null : () => _complete(net, discount, paid),
        icon: _busy
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator())
            : const Icon(Icons.receipt_long),
        label: Text(s.completeAndPrint),
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
      ),
    ]);
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ]),
      );

  Future<void> _complete(double net, double discount, double paid) async {
    final s = ref.read(stringsProvider);
    final wizard = ref.read(wizardProvider);
    setState(() => _busy = true);

    final result = await ref.read(repositoryProvider).register(
          studentId: wizard.student!.id,
          groupId: wizard.group!.id,
          price: wizard.group!.effectivePrice(wizard.subject!),
          discount: discount,
          amountPaid: paid,
        );

    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case RegistrationSuccess(:final registration):
        ref.read(dataVersionProvider.notifier).state++;
        await _showReceipt(registration);
        if (mounted) {
          ref.read(wizardProvider.notifier).state = const WizardState();
        }
      case RegistrationFailure(:final reason):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.conflict} ($reason)'),
              backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _showReceipt(Registration reg) async {
    final s = ref.read(stringsProvider);
    final currency = ref.read(currencyProvider);
    final wizard = ref.read(wizardProvider);
    final teachers = ref.read(teachersProvider).value ?? [];
    final teacher = teachers.firstWhere((t) => t.id == wizard.group!.teacherId,
        orElse: () => const Teacher(id: '?', name: '?', specialization: ''));
    final df = intl.DateFormat('yyyy-MM-dd HH:mm');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text(s.registrationSuccess),
        ]),
        content: SizedBox(
          width: 340,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Thermal-receipt style block (esc_pos_utils would print this).
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFBF3),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                    fontFamily: 'monospace', color: Colors.black, fontSize: 13),
                child: Column(children: [
                  Text(s.appTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('================================'),
                  _receiptRow(s.receiptNo, reg.receiptNumber),
                  _receiptRow(s.date, df.format(reg.createdAt)),
                  const Text('--------------------------------'),
                  _receiptRow(s.student, wizard.student!.name),
                  _receiptRow(s.barcode, wizard.student!.barcode),
                  _receiptRow(s.subject, wizard.subject!.name(s.ar)),
                  _receiptRow(s.teacher, teacher.name),
                  _receiptRow(s.schedule, scheduleText(wizard.group!, s)),
                  const Text('--------------------------------'),
                  _receiptRow(s.price, money(reg.price, currency)),
                  _receiptRow(s.discount, money(reg.discount, currency)),
                  _receiptRow(s.netTotal, money(reg.netPrice, currency)),
                  _receiptRow(s.amountPaid, money(reg.amountPaid, currency)),
                  if (reg.remaining > 0)
                    _receiptRow(s.remaining, money(reg.remaining, currency)),
                  const Text('================================'),
                  Text(s.thankYou),
                ]),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // TODO: hook esc_pos_utils / printing package here.
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('🖨️ → esc_pos_utils')));
            },
            icon: const Icon(Icons.print),
            label: Text(s.print),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.done),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            const SizedBox(width: 12),
            Flexible(child: Text(value, textAlign: TextAlign.end)),
          ],
        ),
      );
}
