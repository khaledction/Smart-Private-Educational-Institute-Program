import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/models.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final currency = ref.watch(currencyProvider);
    final groups = ref.watch(groupsProvider).value ?? [];
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final teachers = ref.watch(teachersProvider).value ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: groups.map((g) {
        final subIt = subjects.where((x) => x.id == g.subjectId);
        final sub = subIt.isEmpty ? null : subIt.first;
        final tIt = teachers.where((x) => x.id == g.teacherId);
        final teacher = tIt.isEmpty
            ? const Teacher(id: '?', name: '?', specialization: '')
            : tIt.first;
        final occupancy = g.maxCapacity == 0
            ? 0.0
            : g.enrolledCount / g.maxCapacity;
        final price = sub == null ? 0.0 : g.effectivePrice(sub);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    '${sub?.name(s.ar) ?? '?'} — ${teacher.name}'
                    '${g.label.isEmpty ? '' : ' (${g.label == 'VIP' ? s.vip : g.label})'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(money(price, currency),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              Text(scheduleText(g, s)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: occupancy,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(6),
                    color: g.isFull ? Colors.red : null,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${s.occupancy}: ${g.enrolledCount}/${g.maxCapacity}'
                  '${g.isFull ? ' — ${s.full}' : ''}',
                  style: TextStyle(
                      color: g.isFull ? Colors.red : Colors.black54,
                      fontWeight:
                          g.isFull ? FontWeight.bold : FontWeight.normal),
                ),
              ]),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
