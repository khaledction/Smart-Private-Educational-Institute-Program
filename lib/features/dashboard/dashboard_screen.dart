import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/providers.dart';
import '../../data/models/models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final currency = ref.watch(currencyProvider);
    final regs = ref.watch(registrationsProvider).value ?? [];
    final students = ref.watch(studentsProvider).value ?? [];
    final groups = ref.watch(groupsProvider).value ?? [];
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final teachers = ref.watch(teachersProvider).value ?? [];

    final now = DateTime.now();
    final todayRevenue = regs
        .where((r) =>
            r.createdAt.year == now.year &&
            r.createdAt.month == now.month &&
            r.createdAt.day == now.day)
        .fold<double>(0, (sum, r) => sum + r.amountPaid);

    // Most requested subjects (by enrolled counts of their groups)
    final subjectCounts = <String, int>{};
    for (final g in groups) {
      subjectCounts[g.subjectId] =
          (subjectCounts[g.subjectId] ?? 0) + g.enrolledCount;
    }
    final topSubjects = subjectCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final teacherCounts = <String, int>{};
    for (final g in groups) {
      teacherCounts[g.teacherId] =
          (teacherCounts[g.teacherId] ?? 0) + g.enrolledCount;
    }
    final topTeachers = teacherCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxSubjectCount =
        topSubjects.isEmpty ? 1 : topSubjects.first.value.clamp(1, 1 << 30);

    Subject? subjectById(String id) {
      final it = subjects.where((x) => x.id == id);
      return it.isEmpty ? null : it.first;
    }

    Teacher? teacherById(String id) {
      final it = teachers.where((x) => x.id == id);
      return it.isEmpty ? null : it.first;
    }

    final df = intl.DateFormat('MM-dd HH:mm');
    final recent = regs.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 14, runSpacing: 14, children: [
          _StatCard(
              icon: Icons.payments,
              color: Colors.green,
              label: s.todayRevenue,
              value: money(todayRevenue, currency)),
          _StatCard(
              icon: Icons.people,
              color: Colors.blue,
              label: s.totalStudents,
              value: '${students.length}'),
          _StatCard(
              icon: Icons.grid_view,
              color: Colors.purple,
              label: s.activeGroups,
              value: '${groups.length}'),
          _StatCard(
              icon: Icons.receipt_long,
              color: Colors.orange,
              label: s.totalRegistrations,
              value: '${regs.length}'),
        ]),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 800;
          final children = [
            Expanded(
              flex: wide ? 1 : 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.topSubjects,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        ...topSubjects.take(6).map((e) {
                          final sub = subjectById(e.key);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(sub?.name(s.ar) ?? e.key),
                                        Text('${e.value}'),
                                      ]),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: e.value / maxSubjectCount,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ]),
                          );
                        }),
                      ]),
                ),
              ),
            ),
            SizedBox(width: wide ? 14 : 0, height: wide ? 0 : 14),
            Expanded(
              flex: wide ? 1 : 0,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.topTeachers,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        ...topTeachers.take(6).map((e) {
                          final t = teacherById(e.key);
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                                radius: 16,
                                child: Text((t?.name ?? '?')
                                    .replaceAll('أ. ', '')
                                    .characters
                                    .first)),
                            title: Text(t?.name ?? e.key),
                            trailing: Text('${e.value}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          );
                        }),
                      ]),
                ),
              ),
            ),
          ];
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: children)
              : Column(
                  children: children
                      .map((w) => w is Expanded ? w.child : w)
                      .toList());
        }),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.recentActivity,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...recent.take(8).map((r) {
                final st = students.where((x) => x.id == r.studentId);
                final g = groups.where((x) => x.id == r.groupId);
                final sub = g.isEmpty ? null : subjectById(g.first.subjectId);
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.receipt),
                  title: Text(
                      '${st.isEmpty ? '?' : st.first.name} — ${sub?.name(s.ar) ?? ''}'),
                  subtitle: Text('${r.receiptNumber} • ${df.format(r.createdAt)}'),
                  trailing: Text(money(r.amountPaid, currency),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54)),
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}
