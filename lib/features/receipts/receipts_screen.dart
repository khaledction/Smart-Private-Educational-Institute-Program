import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/providers.dart';

class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final currency = ref.watch(currencyProvider);
    final regs = (ref.watch(registrationsProvider).value ?? []).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final students = ref.watch(studentsProvider).value ?? [];
    final groups = ref.watch(groupsProvider).value ?? [];
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final df = intl.DateFormat('yyyy-MM-dd HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: regs.length,
      itemBuilder: (context, i) {
        final r = regs[i];
        final stIt = students.where((x) => x.id == r.studentId);
        final gIt = groups.where((x) => x.id == r.groupId);
        final subIt = gIt.isEmpty
            ? const Iterable.empty()
            : subjects.where((x) => x.id == gIt.first.subjectId);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: r.remaining > 0
                  ? Colors.orange.withValues(alpha: .15)
                  : Colors.green.withValues(alpha: .15),
              child: Icon(
                r.remaining > 0 ? Icons.hourglass_bottom : Icons.check,
                color: r.remaining > 0 ? Colors.orange : Colors.green,
              ),
            ),
            title: Text(
                '${r.receiptNumber} — ${stIt.isEmpty ? '?' : stIt.first.name}'),
            subtitle: Text(
                '${subIt.isEmpty ? '?' : (subIt.first as dynamic).name(s.ar)} • ${df.format(r.createdAt)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(money(r.amountPaid, currency),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (r.remaining > 0)
                  Text('${s.remaining}: ${money(r.remaining, currency)}',
                      style:
                          const TextStyle(color: Colors.orange, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}
