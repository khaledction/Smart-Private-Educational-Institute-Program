import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart' as intl;

import '../data/models/models.dart';
import '../data/repositories/institute_repository.dart';
import '../data/repositories/mock_repository.dart';
import 'strings.dart';

// ─── App settings ────────────────────────────────────────────────────────────

final localeProvider = StateProvider<Locale>((ref) => const Locale('ar'));

final currencyProvider = StateProvider<String>((ref) => 'ل.س');

final stringsProvider = Provider<S>((ref) {
  final locale = ref.watch(localeProvider);
  return S(locale.languageCode == 'ar');
});

String money(double v, String currency) =>
    '${intl.NumberFormat('#,##0', 'en').format(v)} $currency';

// ─── Data layer ──────────────────────────────────────────────────────────────

/// Swap with SupabaseInstituteRepository() when your backend is ready.
final repositoryProvider =
    Provider<InstituteRepository>((ref) => MockInstituteRepository());

/// Bumped after every mutation to refresh all data providers.
final dataVersionProvider = StateProvider<int>((ref) => 0);

final studentsProvider = FutureProvider<List<Student>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(repositoryProvider).getStudents();
});

final subjectsProvider = FutureProvider<List<Subject>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(repositoryProvider).getSubjects();
});

final teachersProvider = FutureProvider<List<Teacher>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(repositoryProvider).getTeachers();
});

final groupsProvider = FutureProvider<List<StudyGroup>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(repositoryProvider).getGroups();
});

final registrationsProvider = FutureProvider<List<Registration>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(repositoryProvider).getRegistrations();
});

// ─── Domain helpers ──────────────────────────────────────────────────────────

class ConflictInfo {
  final StudyGroup existingGroup;
  final Subject existingSubject;
  const ConflictInfo(this.existingGroup, this.existingSubject);
}

/// Detects a schedule conflict between [candidate] and the groups the
/// student is already registered in.
ConflictInfo? detectConflict({
  required StudyGroup candidate,
  required String studentId,
  required List<Registration> registrations,
  required List<StudyGroup> groups,
  required List<Subject> subjects,
}) {
  final studentGroupIds = registrations
      .where((r) => r.studentId == studentId)
      .map((r) => r.groupId)
      .toSet();

  for (final g in groups) {
    if (!studentGroupIds.contains(g.id) || g.id == candidate.id) continue;
    for (final slotA in candidate.schedule) {
      for (final slotB in g.schedule) {
        if (slotA.overlaps(slotB)) {
          final subj = subjects.firstWhere((s) => s.id == g.subjectId);
          return ConflictInfo(g, subj);
        }
      }
    }
  }
  return null;
}

String scheduleText(StudyGroup g, S s) => g.schedule
    .map((slot) => '${s.day(slot.dayOfWeek)} ${s.time(slot.hour, slot.minute)}')
    .join(' • ');
