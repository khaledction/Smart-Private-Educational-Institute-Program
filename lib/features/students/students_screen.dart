import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/providers.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final regs = ref.watch(registrationsProvider).value ?? [];
    final groups = ref.watch(groupsProvider).value ?? [];
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final df = intl.DateFormat('yyyy-MM-dd');

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (students) {
        final q = _query.trim().toLowerCase();
        final list = q.isEmpty
            ? students
            : students
                .where((st) =>
                    st.name.toLowerCase().contains(q) ||
                    st.phone.contains(q) ||
                    st.barcode.toLowerCase().contains(q))
                .toList();

        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '${s.search}…',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final st = list[i];
                final myRegs =
                    regs.where((r) => r.studentId == st.id).toList();
                final subjectNames = myRegs.map((r) {
                  final g = groups.where((g) => g.id == r.groupId);
                  if (g.isEmpty) return '?';
                  final sub =
                      subjects.where((x) => x.id == g.first.subjectId);
                  return sub.isEmpty ? '?' : sub.first.name(s.ar);
                }).join('، ');

                return Card(
                  child: ExpansionTile(
                    leading: CircleAvatar(child: Text(st.name.characters.first)),
                    title: Text(st.name),
                    subtitle: Text(
                        '${st.barcode} • ${st.phone}${subjectNames.isEmpty ? '' : ' • $subjectNames'}'),
                    children: [
                      ListTile(
                        dense: true,
                        title: Text('${s.guardianName}: ${st.guardianName.isEmpty ? '—' : st.guardianName}'),
                        subtitle: Text(
                            '${s.guardianPhone}: ${st.guardianPhone.isEmpty ? '—' : st.guardianPhone}\n${s.enrolledSince}: ${df.format(st.createdAt)}'),
                        isThreeLine: true,
                      ),
                      ...myRegs.map((r) {
                        final g = groups.where((g) => g.id == r.groupId);
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.schedule),
                          title: Text(g.isEmpty ? '?' : scheduleText(g.first, s)),
                          trailing: Text(r.receiptNumber),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }
}
