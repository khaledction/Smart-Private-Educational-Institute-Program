import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/models.dart';

/// Administration screen: pricing (subjects / teachers / groups) + discounts.
/// شاشة الإدارة: الأسعار والخصومات.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.sell_outlined), text: s.pricing),
              Tab(icon: const Icon(Icons.discount_outlined), text: s.discounts),
            ],
          ),
        ),
        const Expanded(
          child: TabBarView(children: [_PricingTab(), _DiscountsTab()]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════ PRICING ═══════════════════════════════════

class _PricingTab extends ConsumerWidget {
  const _PricingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final currency = ref.watch(currencyProvider);
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final teachers = ref.watch(teachersProvider).value ?? [];
    final groups = ref.watch(groupsProvider).value ?? [];

    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Subjects / full courses ─────────────────────────────────────────
      _SectionHeader(icon: Icons.menu_book, title: s.subjectsPricing),
      ...subjects.map((sub) => Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book),
              title: Text(sub.name(s.ar)),
              subtitle: Text(
                  '${s.totalHours}: ${sub.totalHours} ${s.hours} • ${sub.durationMonths} ${s.months}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(money(sub.basePrice, currency),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  tooltip: s.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editSubject(context, ref, sub),
                ),
              ]),
            ),
          )),
      const SizedBox(height: 20),

      // ── Teachers session prices ─────────────────────────────────────────
      _SectionHeader(icon: Icons.co_present_outlined, title: s.teachersPricing),
      ...teachers.map((t) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(t.name.characters.first)),
              title: Text(t.name),
              subtitle: Text(t.specialization),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${money(t.sessionPrice, currency)} / ${s.sessionPrice}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  tooltip: s.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editTeacher(context, ref, t),
                ),
              ]),
            ),
          )),
      const SizedBox(height: 20),

      // ── Group price overrides ───────────────────────────────────────────
      _SectionHeader(icon: Icons.groups_outlined, title: s.groupsPricing),
      ...groups.map((g) {
        final subject = subjects.where((x) => x.id == g.subjectId).firstOrNull;
        final teacher = teachers.where((x) => x.id == g.teacherId).firstOrNull;
        final hasOverride = g.priceOverride != null;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text(
                '${subject?.name(s.ar) ?? '?'} — ${teacher?.name ?? '?'}'
                '${g.label.isNotEmpty ? ' (${g.label})' : ''}'),
            subtitle: Text(hasOverride
                ? money(g.priceOverride!, currency)
                : '${s.useSubjectPrice} (${money(subject?.basePrice ?? 0, currency)})'),
            trailing: IconButton(
              tooltip: s.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editGroup(context, ref, g),
            ),
          ),
        );
      }),
    ]);
  }

  Future<void> _editSubject(
      BuildContext context, WidgetRef ref, Subject sub) async {
    final s = ref.read(stringsProvider);
    final priceCtrl =
        TextEditingController(text: sub.basePrice.toStringAsFixed(0));
    final hoursCtrl = TextEditingController(text: '${sub.totalHours}');
    final monthsCtrl = TextEditingController(text: '${sub.durationMonths}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('${s.edit} — ${sub.name(s.ar)}'),
        content: SizedBox(
          width: 340,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: priceCtrl,
              decoration: InputDecoration(
                  labelText: s.coursePrice,
                  prefixIcon: const Icon(Icons.payments_outlined)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: hoursCtrl,
              decoration: InputDecoration(
                  labelText: s.totalHours,
                  prefixIcon: const Icon(Icons.schedule)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: monthsCtrl,
              decoration: InputDecoration(
                  labelText: s.durationMonthsLabel,
                  prefixIcon: const Icon(Icons.calendar_month)),
              keyboardType: TextInputType.number,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: Text(s.save)),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(repositoryProvider).updateSubjectPricing(
            subjectId: sub.id,
            basePrice: double.tryParse(priceCtrl.text) ?? sub.basePrice,
            totalHours: int.tryParse(hoursCtrl.text) ?? sub.totalHours,
            durationMonths:
                int.tryParse(monthsCtrl.text) ?? sub.durationMonths,
          );
      ref.read(dataVersionProvider.notifier).state++;
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.updated)));
      }
    }
  }

  Future<void> _editTeacher(
      BuildContext context, WidgetRef ref, Teacher t) async {
    final s = ref.read(stringsProvider);
    final ctrl = TextEditingController(text: t.sessionPrice.toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('${s.edit} — ${t.name}'),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
                labelText: s.sessionPrice,
                prefixIcon: const Icon(Icons.payments_outlined)),
            keyboardType: TextInputType.number,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: Text(s.save)),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).updateTeacherSessionPrice(
            teacherId: t.id,
            sessionPrice: double.tryParse(ctrl.text) ?? t.sessionPrice,
          );
      ref.read(dataVersionProvider.notifier).state++;
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.updated)));
      }
    }
  }

  Future<void> _editGroup(
      BuildContext context, WidgetRef ref, StudyGroup g) async {
    final s = ref.read(stringsProvider);
    final ctrl = TextEditingController(
        text: g.priceOverride?.toStringAsFixed(0) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(s.edit),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
                labelText: s.priceOverrideLabel,
                prefixIcon: const Icon(Icons.payments_outlined)),
            keyboardType: TextInputType.number,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: Text(s.save)),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).updateGroupPriceOverride(
            groupId: g.id,
            priceOverride: double.tryParse(ctrl.text),
          );
      ref.read(dataVersionProvider.notifier).state++;
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.updated)));
      }
    }
  }
}

// ═══════════════════════════════ DISCOUNTS ══════════════════════════════════

class _DiscountsTab extends ConsumerWidget {
  const _DiscountsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final currency = ref.watch(currencyProvider);
    final rulesAsync = ref.watch(discountRulesProvider);
    final students = ref.watch(studentsProvider).value ?? [];
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final teachers = ref.watch(teachersProvider).value ?? [];
    final groups = ref.watch(groupsProvider).value ?? [];

    String targetName(DiscountRule r) {
      switch (r.scope) {
        case DiscountScope.student:
          return students.where((x) => x.id == r.targetId).firstOrNull?.name ??
              r.targetId;
        case DiscountScope.subject:
          return subjects
                  .where((x) => x.id == r.targetId)
                  .firstOrNull
                  ?.name(s.ar) ??
              r.targetId;
        case DiscountScope.teacher:
          return teachers.where((x) => x.id == r.targetId).firstOrNull?.name ??
              r.targetId;
        case DiscountScope.group:
          final g = groups.where((x) => x.id == r.targetId).firstOrNull;
          if (g == null) return r.targetId;
          final sub =
              subjects.where((x) => x.id == g.subjectId).firstOrNull;
          return '${sub?.name(s.ar) ?? '?'} (${g.label})';
      }
    }

    String scopeName(DiscountScope sc) => switch (sc) {
          DiscountScope.student => s.scopeStudent,
          DiscountScope.group => s.scopeGroup,
          DiscountScope.subject => s.scopeSubject,
          DiscountScope.teacher => s.scopeTeacher,
        };

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(s.addDiscount),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rules) => rules.isEmpty
            ? Center(child: Text(s.noDiscounts))
            : ListView(padding: const EdgeInsets.all(16), children: [
                ...rules.map((r) => Card(
                      child: ListTile(
                        leading: Icon(
                          switch (r.scope) {
                            DiscountScope.student => Icons.person_outline,
                            DiscountScope.group => Icons.groups_outlined,
                            DiscountScope.subject => Icons.menu_book_outlined,
                            DiscountScope.teacher =>
                              Icons.co_present_outlined,
                          },
                          color: r.active ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                            '${scopeName(r.scope)}: ${targetName(r)}'),
                        subtitle: Text([
                          r.type == DiscountType.percent
                              ? '${r.value.toStringAsFixed(0)} %'
                              : money(r.value, currency),
                          if (r.note.isNotEmpty) r.note,
                        ].join(' • ')),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Switch(
                            value: r.active,
                            onChanged: (v) async {
                              await ref
                                  .read(repositoryProvider)
                                  .setDiscountRuleActive(r.id, v);
                              ref.read(dataVersionProvider.notifier).state++;
                            },
                          ),
                          IconButton(
                            tooltip: s.delete,
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (dctx) => AlertDialog(
                                  title: Text(s.confirmDelete),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dctx, false),
                                        child: Text(s.cancel)),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dctx, true),
                                        child: Text(s.delete)),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await ref
                                    .read(repositoryProvider)
                                    .deleteDiscountRule(r.id);
                                ref
                                    .read(dataVersionProvider.notifier)
                                    .state++;
                              }
                            },
                          ),
                        ]),
                      ),
                    )),
                const SizedBox(height: 80),
              ]),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final students = ref.read(studentsProvider).value ?? [];
    final subjects = ref.read(subjectsProvider).value ?? [];
    final teachers = ref.read(teachersProvider).value ?? [];
    final groups = ref.read(groupsProvider).value ?? [];

    var scope = DiscountScope.student;
    var type = DiscountType.percent;
    String? targetId;
    final valueCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setState) {
          List<DropdownMenuItem<String>> targetItems() {
            switch (scope) {
              case DiscountScope.student:
                return students
                    .map((x) => DropdownMenuItem(
                        value: x.id, child: Text(x.name)))
                    .toList();
              case DiscountScope.subject:
                return subjects
                    .map((x) => DropdownMenuItem(
                        value: x.id, child: Text(x.name(s.ar))))
                    .toList();
              case DiscountScope.teacher:
                return teachers
                    .map((x) => DropdownMenuItem(
                        value: x.id, child: Text(x.name)))
                    .toList();
              case DiscountScope.group:
                return groups.map((g) {
                  final sub = subjects
                      .where((x) => x.id == g.subjectId)
                      .firstOrNull;
                  return DropdownMenuItem(
                      value: g.id,
                      child:
                          Text('${sub?.name(s.ar) ?? '?'} (${g.label})'));
                }).toList();
            }
          }

          return AlertDialog(
            title: Text(s.addDiscount),
            content: SizedBox(
              width: 380,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<DiscountScope>(
                  initialValue: scope,
                  decoration: InputDecoration(labelText: s.discountScope),
                  items: [
                    DropdownMenuItem(
                        value: DiscountScope.student,
                        child: Text(s.scopeStudent)),
                    DropdownMenuItem(
                        value: DiscountScope.group,
                        child: Text(s.scopeGroup)),
                    DropdownMenuItem(
                        value: DiscountScope.subject,
                        child: Text(s.scopeSubject)),
                    DropdownMenuItem(
                        value: DiscountScope.teacher,
                        child: Text(s.scopeTeacher)),
                  ],
                  onChanged: (v) => setState(() {
                    scope = v!;
                    targetId = null;
                  }),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: targetId,
                  decoration: InputDecoration(labelText: s.target),
                  items: targetItems(),
                  onChanged: (v) => setState(() => targetId = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<DiscountType>(
                  initialValue: type,
                  decoration: InputDecoration(labelText: s.discountTypeLabel),
                  items: [
                    DropdownMenuItem(
                        value: DiscountType.percent, child: Text(s.percent)),
                    DropdownMenuItem(
                        value: DiscountType.fixed,
                        child: Text(s.fixedAmount)),
                  ],
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: valueCtrl,
                  decoration: InputDecoration(
                      labelText: s.valueLabel,
                      prefixIcon: Icon(type == DiscountType.percent
                          ? Icons.percent
                          : Icons.payments_outlined)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(labelText: s.noteLabel),
                ),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dctx, false),
                  child: Text(s.cancel)),
              FilledButton(
                onPressed: targetId == null
                    ? null
                    : () => Navigator.pop(dctx, true),
                child: Text(s.save),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true && targetId != null) {
      await ref.read(repositoryProvider).addDiscountRule(
            scope: scope,
            targetId: targetId!,
            type: type,
            value: double.tryParse(valueCtrl.text) ?? 0,
            note: noteCtrl.text.trim(),
          );
      ref.read(dataVersionProvider.notifier).state++;
    }
  }
}

// ─── Shared ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ]),
      );
}
