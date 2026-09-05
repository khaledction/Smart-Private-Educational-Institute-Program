import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'local_registration_db.dart';
import 'mock_data.dart';

class StudentOption {
  final int id;
  final String code;
  final String name;
  final String status;
  const StudentOption({required this.id, required this.code, required this.name, required this.status});

  String get label => '$name — $code';

  factory StudentOption.fromMap(Map<String, Object?> map) => StudentOption(
        id: map['id'] as int,
        code: map['code'] as String,
        name: map['full_name'] as String,
        status: map['status'] as String? ?? 'نشط',
      );
}

class SubjectOption {
  final int id;
  final String name;
  const SubjectOption({required this.id, required this.name});

  factory SubjectOption.fromMap(Map<String, Object?> map) => SubjectOption(
        id: map['id'] as int,
        name: map['name'] as String,
      );
}

class TeacherOption {
  final int id;
  final String name;
  final String specialization;
  final String degree;
  const TeacherOption({required this.id, required this.name, required this.specialization, required this.degree});

  factory TeacherOption.fromMap(Map<String, Object?> map) => TeacherOption(
        id: map['id'] as int,
        name: map['full_name'] as String,
        specialization: map['specialization'] as String? ?? '',
        degree: map['degree'] as String? ?? '—',
      );
}

class GroupOption {
  final int id;
  final String name;
  final String subject;
  final String teacher;
  final String period;
  final int capacity;
  final int enrolled;
  final int waiting;
  final String status;
  final String system;
  final String days;
  final String room;
  final double price;

  const GroupOption({
    required this.id,
    required this.name,
    required this.subject,
    required this.teacher,
    required this.period,
    required this.capacity,
    required this.enrolled,
    required this.waiting,
    required this.status,
    required this.system,
    required this.days,
    required this.room,
    required this.price,
  });

  int get seatsLeft => capacity - enrolled;
  bool get isFull => seatsLeft <= 0;
  bool get isOpenForRegistration => status == 'open' || status == 'running';

  factory GroupOption.fromMap(Map<String, Object?> map) => GroupOption(
        id: map['id'] as int,
        name: map['name'] as String,
        subject: map['subject_name'] as String,
        teacher: map['teacher_name'] as String,
        period: map['period'] as String,
        capacity: map['capacity'] as int? ?? 0,
        enrolled: map['enrolled_count'] as int? ?? 0,
        waiting: map['waiting_count'] as int? ?? 0,
        status: map['status'] as String? ?? 'open',
        system: map['system'] as String? ?? 'كورس كامل',
        days: map['days'] as String? ?? '',
        room: map['room'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
      );
}

class RegistrationRequestItem {
  final int id;
  final int studentId;
  final int subjectId;
  final int? teacherId;
  final int? targetGroupId;
  final String studentName;
  final String studentCode;
  final String subjectName;
  final String teacherName;
  final String period;
  String status;
  String? decisionNote;
  final String createdAt;
  String? decidedAt;

  RegistrationRequestItem({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.teacherId,
    required this.targetGroupId,
    required this.studentName,
    required this.studentCode,
    required this.subjectName,
    required this.teacherName,
    required this.period,
    required this.status,
    required this.createdAt,
    this.decisionNote,
    this.decidedAt,
  });

  String get studentLabel => '$studentName — $studentCode';

  factory RegistrationRequestItem.fromMap(Map<String, Object?> map) => RegistrationRequestItem(
        id: map['id'] as int,
        studentId: map['student_id'] as int,
        subjectId: map['subject_id'] as int,
        teacherId: map['teacher_id'] as int?,
        targetGroupId: map['target_group_id'] as int?,
        studentName: map['student_name'] as String,
        studentCode: map['student_code'] as String,
        subjectName: map['subject_name'] as String,
        teacherName: map['teacher_name'] as String? ?? '—',
        period: map['period'] as String,
        status: map['status'] as String? ?? 'معلق',
        createdAt: (map['created_at'] as Object?).toString(),
        decisionNote: map['decision_note'] as String?,
        decidedAt: map['decided_at'] as String?,
      );
}

class WaitingItem {
  final int id;
  final int studentId;
  final int subjectId;
  final int teacherId;
  final int? groupId;
  final String studentName;
  final String studentCode;
  final String subjectName;
  final String teacherName;
  final String period;
  final String createdAt;

  WaitingItem({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.teacherId,
    required this.groupId,
    required this.studentName,
    required this.studentCode,
    required this.subjectName,
    required this.teacherName,
    required this.period,
    required this.createdAt,
  });

  String get studentLabel => '$studentName — $studentCode';

  factory WaitingItem.fromMap(Map<String, Object?> map) => WaitingItem(
        id: map['id'] as int,
        studentId: map['student_id'] as int,
        subjectId: map['subject_id'] as int,
        teacherId: map['teacher_id'] as int,
        groupId: map['group_id'] as int?,
        studentName: map['student_name'] as String,
        studentCode: map['student_code'] as String,
        subjectName: map['subject_name'] as String,
        teacherName: map['teacher_name'] as String,
        period: map['period'] as String,
        createdAt: (map['created_at'] as Object?).toString(),
      );
}

class RegistrationPreview {
  final GroupOption? chosenGroup;
  final List<GroupOption> alternatives;
  const RegistrationPreview({required this.chosenGroup, required this.alternatives});

  bool get hasExactGroup => chosenGroup != null;
  bool get isFull => chosenGroup != null && chosenGroup!.isFull;
}

class ActionResult {
  final bool ok;
  final String message;
  final String? status;
  const ActionResult(this.ok, this.message, {this.status});
}

class RegistrationStore extends ChangeNotifier {
  RegistrationStore._();
  static final RegistrationStore instance = RegistrationStore._();

  final LocalRegistrationDb _db = LocalRegistrationDb.instance;

  bool _ready = false;
  bool _busy = false;
  String? _error;

  List<StudentOption> students = const [];
  List<SubjectOption> subjects = const [];
  List<TeacherOption> teachers = const [];
  List<GroupOption> groups = const [];
  List<RegistrationRequestItem> requests = const [];
  List<WaitingItem> waiting = const [];

  bool get isReady => _ready;
  bool get isBusy => _busy;
  String? get error => _error;
  int get pendingCount => requests.where((r) => r.status == 'معلق').length;
  int get waitingCount => waiting.length;

  Future<void> init() async {
    if (_ready) return;
    try {
      _setBusy(true);
      await _db.init();
      await refresh();
      _ready = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setBusy(false, notify: true);
    }
  }

  Future<void> refresh() async {
    final db = await _db.database;
    students = (await db.query('students', orderBy: 'full_name'))
        .map(StudentOption.fromMap)
        .toList();
    subjects = (await db.query('subjects', orderBy: 'name'))
        .map(SubjectOption.fromMap)
        .toList();
    teachers = (await db.query('teachers', orderBy: 'full_name'))
        .map(TeacherOption.fromMap)
        .toList();
    groups = (await db.query('v_groups_registration'))
        .map(GroupOption.fromMap)
        .toList();
    requests = (await db.query('v_registration_requests'))
        .map(RegistrationRequestItem.fromMap)
        .toList();
    waiting = (await db.query('v_waiting_list'))
        .map(WaitingItem.fromMap)
        .toList();
    notifyListeners();
  }

  List<TeacherOption> teachersForSubject(int? subjectId) {
    if (subjectId == null) return teachers;
    final subject = subjectById(subjectId);
    if (subject == null) return teachers;
    return teachers.where((t) => _looseMatch(t.specialization, subject.name)).toList();
  }

  RegistrationPreview preview({required int? subjectId, required int? teacherId, required String period}) {
    if (subjectId == null || teacherId == null) {
      return const RegistrationPreview(chosenGroup: null, alternatives: []);
    }
    final subject = subjectById(subjectId);
    final teacher = teacherById(teacherId);
    if (subject == null || teacher == null) {
      return const RegistrationPreview(chosenGroup: null, alternatives: []);
    }

    GroupOption? chosen;
    final alternatives = <GroupOption>[];
    for (final group in groups) {
      if (!_looseMatch(group.subject, subject.name) || group.period != period || !group.isOpenForRegistration) {
        continue;
      }
      if (group.teacher == teacher.name && chosen == null) {
        chosen = group;
      } else if (group.teacher != teacher.name && group.seatsLeft > 0) {
        alternatives.add(group);
      }
    }

    return RegistrationPreview(chosenGroup: chosen, alternatives: alternatives);
  }

  Future<ActionResult> submitRequest({
    required int studentId,
    required int subjectId,
    required int teacherId,
    required String period,
  }) async {
    try {
      _setBusy(true);
      final db = await _db.database;
      final existing = await db.query(
        'registration_requests_local',
        columns: ['id', 'status'],
        where: 'student_id = ? AND subject_id = ? AND teacher_id = ? AND period = ? AND status IN (?, ?, ?)',
        whereArgs: [studentId, subjectId, teacherId, period, 'معلق', 'معتمد', 'قائمة انتظار'],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final status = existing.first['status'] as String? ?? 'معلق';
        return ActionResult(false, 'يوجد طلب سابق محفوظ بنفس البيانات وحالته الحالية: $status');
      }
      final previewResult = preview(subjectId: subjectId, teacherId: teacherId, period: period);
      final requestId = await db.insert('registration_requests_local', {
        'student_id': studentId,
        'subject_id': subjectId,
        'teacher_id': teacherId,
        'period': period,
        'target_group_id': previewResult.chosenGroup?.id,
        'status': 'معلق',
        'decision_note': previewResult.isFull ? 'المقعد غير متاح حاليًا — مرشح للانتظار عند الاعتماد' : null,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _log(db, 'registration.submit', 'registration_request', requestId,
          'تم إنشاء طلب تسجيل جديد بانتظار الاعتماد الإداري.');

      final student = studentById(studentId);
      final teacher = teacherById(teacherId);
      final subject = subjectById(subjectId);
      if (student != null && teacher != null && subject != null) {
        kNotifications.insert(
          0,
          NotificationItem(
            'طلب تسجيل جديد',
            '${student.name} طلب ${subject.name} — ${periodLabel(period)} مع ${teacher.name}',
            'الآن',
            'request',
          ),
        );
      }

      await refresh();
      final message = previewResult.isFull
          ? '⏳ تم حفظ الطلب. المجموعة المطلوبة ممتلئة وسيظهر للإدارة أنه مرشح للانتظار.'
          : '✅ تم حفظ الطلب في قاعدة البيانات وإرساله للاعتماد الإداري.';
      return ActionResult(true, message, status: 'معلق');
    } catch (e) {
      return ActionResult(false, 'تعذر حفظ الطلب: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<ActionResult> approveRequest(int requestId) async {
    try {
      _setBusy(true);
      final db = await _db.database;
      final rows = await db.query(
        'registration_requests_local',
        where: 'id = ?',
        whereArgs: [requestId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const ActionResult(false, 'الطلب غير موجود.');
      }
      final row = rows.first;
      final currentStatus = row['status'] as String? ?? 'معلق';
      if (currentStatus != 'معلق') {
        return ActionResult(false, 'هذا الطلب حالته الحالية: $currentStatus');
      }

      final studentId = row['student_id'] as int;
      final subjectId = row['subject_id'] as int;
      final teacherId = row['teacher_id'] as int?;
      final period = row['period'] as String;
      final matchedGroup = _findGroup(subjectId: subjectId, teacherId: teacherId, period: period);

      if (teacherId == null) {
        return const ActionResult(false, 'لا يوجد مدرس مفضّل محفوظ لهذا الطلب.');
      }

      if (matchedGroup == null || matchedGroup.isFull) {
        final waitingExists = await db.query(
          'waiting_lists_local',
          columns: ['id'],
          where: 'student_id = ? AND subject_id = ? AND teacher_id = ? AND period = ?',
          whereArgs: [studentId, subjectId, teacherId, period],
          limit: 1,
        );
        if (waitingExists.isEmpty) {
          await db.insert(
            'waiting_lists_local',
            {
              'student_id': studentId,
              'subject_id': subjectId,
              'teacher_id': teacherId,
              'period': period,
              'group_id': matchedGroup?.id,
              'created_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          if (matchedGroup != null) {
            await db.rawUpdate(
              'UPDATE groups_local SET waiting_count = waiting_count + 1 WHERE id = ?',
              [matchedGroup.id],
            );
          }
        }

        await db.update(
          'registration_requests_local',
          {
            'status': 'قائمة انتظار',
            'decision_note': 'المجموعة مكتملة — أضيف الطالب إلى قائمة انتظار المدرس.',
            'decided_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [requestId],
        );
        await _log(db, 'registration.waiting', 'registration_request', requestId,
            'تم نقل الطلب إلى قائمة الانتظار بسبب اكتمال المجموعة.');

        final teacher = teacherById(teacherId);
        kNotifications.insert(
          0,
          NotificationItem(
            'طلب نُقل إلى الانتظار',
            'تم تحويل الطلب إلى قائمة انتظار ${teacher?.name ?? 'المدرس'} لعدم توفر مقعد.',
            'الآن',
            'waiting',
          ),
        );

        await refresh();
        return const ActionResult(true, '⏳ المجموعة ممتلئة، تم نقل الطالب إلى قائمة الانتظار وحفظ ذلك دائمًا.', status: 'قائمة انتظار');
      }

      final enrollmentExists = await db.query(
        'enrollments_local',
        columns: ['id'],
        where: 'student_id = ? AND group_id = ?',
        whereArgs: [studentId, matchedGroup.id],
        limit: 1,
      );
      if (enrollmentExists.isEmpty) {
        await db.insert(
          'enrollments_local',
          {
            'student_id': studentId,
            'group_id': matchedGroup.id,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        await db.rawUpdate(
          'UPDATE groups_local SET enrolled_count = enrolled_count + 1 WHERE id = ?',
          [matchedGroup.id],
        );
      }
      await db.update(
        'registration_requests_local',
        {
          'status': 'معتمد',
          'target_group_id': matchedGroup.id,
          'decision_note': 'تم اعتماد الطلب وتسجيل الطالب في المجموعة.',
          'decided_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [requestId],
      );
      await _log(db, 'registration.approve', 'registration_request', requestId,
          'تم اعتماد الطلب وربط الطالب بمجموعة فعلية.');

      final teacher = teacherById(teacherId);
      final student = studentById(studentId);
      kNotifications.insert(
        0,
        NotificationItem(
          'تم اعتماد التسجيل',
          '${student?.name ?? 'طالب'} سُجّل مع ${teacher?.name ?? 'المدرس'} في ${periodLabel(period)}',
          'الآن',
          'request',
        ),
      );

      await refresh();
      return const ActionResult(true, '✅ تم اعتماد الطلب وتسجيل الطالب في المجموعة داخل قاعدة البيانات.', status: 'معتمد');
    } catch (e) {
      return ActionResult(false, 'تعذر اعتماد الطلب: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<ActionResult> rejectRequest(int requestId) async {
    try {
      _setBusy(true);
      final db = await _db.database;
      await db.update(
        'registration_requests_local',
        {
          'status': 'مرفوض',
          'decision_note': 'تم رفض الطلب من الإدارة.',
          'decided_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [requestId],
      );
      await _log(db, 'registration.reject', 'registration_request', requestId,
          'تم رفض طلب التسجيل من الإدارة.');
      kNotifications.insert(
        0,
        NotificationItem('تم رفض طلب', 'تم رفض أحد طلبات التسجيل من الإدارة.', 'الآن', 'request'),
      );
      await refresh();
      return const ActionResult(true, 'تم رفض الطلب وتسجيل القرار في قاعدة البيانات.', status: 'مرفوض');
    } catch (e) {
      return ActionResult(false, 'تعذر رفض الطلب: $e');
    } finally {
      _setBusy(false);
    }
  }

  StudentOption? studentById(int id) {
    for (final student in students) {
      if (student.id == id) return student;
    }
    return null;
  }

  SubjectOption? subjectById(int id) {
    for (final subject in subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  TeacherOption? teacherById(int id) {
    for (final teacher in teachers) {
      if (teacher.id == id) return teacher;
    }
    return null;
  }

  String periodLabel(String value) {
    if (value == 'صباحي') return 'الفترة الصباحية';
    if (value == 'ظهر') return 'فترة الظهر';
    return 'الفترة المسائية';
  }

  GroupOption? _findGroup({required int subjectId, required int? teacherId, required String period}) {
    final subject = subjectById(subjectId);
    final teacher = teacherId == null ? null : teacherById(teacherId);
    if (subject == null || teacher == null) return null;
    for (final group in groups) {
      if (_looseMatch(group.subject, subject.name) && group.teacher == teacher.name && group.period == period && group.isOpenForRegistration) {
        return group;
      }
    }
    return null;
  }

  bool _looseMatch(String a, String b) {
    final aTokens = _canonical(a).split(' ').where((e) => e.length > 2).toSet();
    final bTokens = _canonical(b).split(' ').where((e) => e.length > 2).toSet();
    return aTokens.intersection(bTokens).isNotEmpty;
  }

  String _canonical(String value) {
    return value
        .replaceAll('اللغة', '')
        .replaceAll('/', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .replaceAll('—', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _log(Database db, String action, String entityType, int entityId, String details) async {
    await db.insert('audit_logs_local', {
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
      'created_at': DateTime.now().toIso8601String(),
    });
    addAudit(action, '$entityType#$entityId', details, user: 'النظام المحلي');
  }

  void _setBusy(bool value, {bool notify = true}) {
    _busy = value;
    if (notify) notifyListeners();
  }
}
