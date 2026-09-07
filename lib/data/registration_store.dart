import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'local_registration_db.dart';
import 'mock_data.dart';
import 'student_store.dart';

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
  final String mobile;
  final String whatsapp;
  const TeacherOption({
    required this.id,
    required this.name,
    required this.specialization,
    required this.degree,
    required this.mobile,
    required this.whatsapp,
  });

  factory TeacherOption.fromMap(Map<String, Object?> map) => TeacherOption(
        id: map['id'] as int,
        name: map['full_name'] as String,
        specialization: map['specialization'] as String? ?? '',
        degree: map['degree'] as String? ?? '—',
        mobile: map['mobile'] as String? ?? '',
        whatsapp: map['whatsapp'] as String? ?? '',
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
  final String type;
  final int sessionsDone;
  final int sessionsTotal;
  final int installments;
  final double teacherPct;
  final bool financeLocked;

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
    required this.type,
    required this.sessionsDone,
    required this.sessionsTotal,
    required this.installments,
    required this.teacherPct,
    required this.financeLocked,
  });

  int get seatsLeft => capacity - enrolled;
  bool get isFull => seatsLeft <= 0;
  bool get isOpenForRegistration => status == 'open' || status == 'running';
  bool get isCompleted => status == 'completed' || status == 'closed' || (sessionsTotal > 0 && executedSessions >= sessionsTotal);
  bool get isHoursSystem => system == 'نظام ساعات';
  int get executedSessions => sessionsDone < 0 ? 0 : (sessionsDone > sessionsTotal ? sessionsTotal : sessionsDone);
  double get sessionUnitPrice => isHoursSystem ? price : (sessionsTotal == 0 ? 0.0 : price / sessionsTotal);
  double get revenue => isHoursSystem ? price * sessionsTotal * enrolled : price * enrolled;
  double get accruedRevenue => sessionUnitPrice * executedSessions * enrolled;
  double get accruedTeacherComp => teacherPct <= 0 ? 0.0 : accruedRevenue * teacherPct / 100;

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
        type: map['course_type'] as String? ?? '',
        sessionsDone: (map['sessions_done'] as num?)?.round() ?? 0,
        sessionsTotal: (map['sessions_total'] as num?)?.round() ?? 12,
        installments: (map['installments'] as num?)?.round() ?? 1,
        teacherPct: (map['teacher_pct'] as num?)?.toDouble() ?? 0.0,
        financeLocked: ((map['finance_locked'] as num?)?.round() ?? 0) == 1,
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

class ApprovalRoutingPlan {
  final RegistrationRequestItem request;
  final GroupOption? preferredGroup;
  final List<GroupOption> alternatives;
  final String preferredState;

  const ApprovalRoutingPlan({
    required this.request,
    required this.preferredGroup,
    required this.alternatives,
    required this.preferredState,
  });

  bool get canDirectApprove => preferredGroup != null && preferredState == 'available';
  bool get hasAlternatives => alternatives.isNotEmpty;

  String get message {
    switch (preferredState) {
      case 'available':
        return 'الدورة المطلوبة ما زالت مفتوحة ويمكن اعتماد الطالب مباشرة فيها.';
      case 'full':
        return alternatives.isNotEmpty
            ? 'الدورة المطلوبة مكتملة. يمكنك تحويل الطالب إلى دورة بديلة مفتوحة أو وضعه على قائمة انتظار المدرس المطلوب.'
            : 'الدورة المطلوبة مكتملة، ولا توجد بدائل مفتوحة حاليًا. يمكنك وضع الطالب على قائمة الانتظار.';
      case 'closed':
        return alternatives.isNotEmpty
            ? 'الدورة المطلوبة مغلقة حاليًا. يمكنك اختيار دورة بديلة مفتوحة لنفس المادة أو وضع الطالب على قائمة الانتظار مع المدرس المطلوب.'
            : 'الدورة المطلوبة مغلقة حاليًا، ولا توجد بدائل مفتوحة الآن. يمكنك وضع الطالب على قائمة الانتظار.';
      default:
        return alternatives.isNotEmpty
            ? 'لا توجد دورة مطابقة حاليًا لهذا المدرس، لكن توجد بدائل مفتوحة في نفس المادة والفترة.'
            : 'لا توجد دورة مطابقة أو بدائل مفتوحة حاليًا. المتاح الآن هو إبقاء الطلب معلقًا أو وضع الطالب على قائمة الانتظار.';
    }
  }
}

class ActionResult {
  final bool ok;
  final String message;
  final String? status;
  const ActionResult(this.ok, this.message, {this.status});
}


class CourseStudentRecord {
  final int id;
  final String code;
  final String name;
  final String phone;
  final String guardian;
  final String status;
  final double totalFee;
  final double balanceDue;
  final String financialStatus;
  final String enrolledAt;

  const CourseStudentRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.phone,
    required this.guardian,
    required this.status,
    required this.totalFee,
    required this.balanceDue,
    required this.financialStatus,
    required this.enrolledAt,
  });

  factory CourseStudentRecord.fromMap(Map<String, Object?> map) => CourseStudentRecord(
        id: map['id'] as int,
        code: map['code'] as String,
        name: map['full_name'] as String,
        phone: map['phone'] as String? ?? '—',
        guardian: map['guardian'] as String? ?? '—',
        status: map['status'] as String? ?? 'نشط',
        totalFee: (map['total_fee'] as num?)?.toDouble() ?? 0.0,
        balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0.0,
        financialStatus: map['financial_status'] as String? ?? 'قيد الفوترة',
        enrolledAt: (map['enrolled_at'] as Object?).toString(),
      );
}

class CourseWaitingRecord {
  final int id;
  final String code;
  final String name;
  final String phone;
  final String guardian;
  final String status;
  final String createdAt;

  const CourseWaitingRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.phone,
    required this.guardian,
    required this.status,
    required this.createdAt,
  });

  factory CourseWaitingRecord.fromMap(Map<String, Object?> map) => CourseWaitingRecord(
        id: map['id'] as int,
        code: map['code'] as String,
        name: map['full_name'] as String,
        phone: map['phone'] as String? ?? '—',
        guardian: map['guardian'] as String? ?? '—',
        status: map['status'] as String? ?? 'قائمة انتظار',
        createdAt: (map['created_at'] as Object?).toString(),
      );
}

class CourseDetailsSnapshot {
  final GroupOption group;
  final List<CourseStudentRecord> students;
  final List<CourseWaitingRecord> waiting;

  const CourseDetailsSnapshot({
    required this.group,
    required this.students,
    required this.waiting,
  });
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
      await _syncStudentsIfReady();
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


  Future<ActionResult> resetAllLocalData() async {
    try {
      _setBusy(true);
      await _db.resetAllData();
      await refresh();
      await _syncStudentsIfReady();
      return const ActionResult(true, '🧹 تم تفريغ قاعدة البيانات المحلية بالكامل. يمكنك الآن بدء دورة حياة التسجيل من الصفر.');
    } catch (e) {
      return ActionResult(false, 'تعذر تفريغ قاعدة البيانات: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<ActionResult> saveTeacher({
    required String name,
    required String specialization,
    required String degree,
    required String mobile,
    required String whatsapp,
  }) async {
    try {
      _setBusy(true);
      final db = await _db.database;
      final normalizedName = name.trim();
      final normalizedSpec = specialization.trim();
      final normalizedDegree = degree.trim().isEmpty ? '—' : degree.trim();
      final normalizedMobile = mobile.trim();
      final normalizedWhatsapp = whatsapp.trim().isEmpty ? normalizedMobile : whatsapp.trim();

      if (normalizedName.isEmpty || normalizedSpec.isEmpty || normalizedMobile.isEmpty) {
        return const ActionResult(false, 'أكمل الاسم والاختصاص والموبايل قبل حفظ المدرس.');
      }

      final duplicate = await db.query(
        'teachers',
        columns: ['id'],
        where: 'full_name = ?',
        whereArgs: [normalizedName],
        limit: 1,
      );
      if (duplicate.isNotEmpty) {
        return const ActionResult(false, 'يوجد مدرس محفوظ مسبقًا بنفس الاسم.');
      }

      await _ensureSubject(db, normalizedSpec);
      final id = await db.insert(
        'teachers',
        {
          'full_name': normalizedName,
          'specialization': normalizedSpec,
          'degree': normalizedDegree,
          'mobile': normalizedMobile,
          'whatsapp': normalizedWhatsapp,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await _log(db, 'teacher.create', 'teacher', id, 'تم إنشاء مدرس جديد وحفظه في قاعدة البيانات المحلية.');

      await refresh();
      return const ActionResult(true, '✅ تم حفظ المدرس في قاعدة البيانات المحلية.');
    } catch (e) {
      return ActionResult(false, 'تعذر حفظ المدرس: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<ActionResult> saveGroup({
    int? groupId,
    required String name,
    required String subject,
    required String teacher,
    required String period,
    required String system,
    required String room,
    required String days,
    required double price,
    required int capacity,
    required int enrolledCount,
    required int waitingCount,
    required String status,
    required String type,
    required int sessionsDone,
    required int sessionsTotal,
    required int installments,
    required double teacherPct,
    required bool financeLocked,
  }) async {
    try {
      _setBusy(true);
      final db = await _db.database;
      final normalizedName = name.trim();
      final normalizedSubject = subject.trim();
      final normalizedTeacher = teacher.trim();
      final normalizedRoom = room.trim().isEmpty ? 'قاعة 1' : room.trim();
      final normalizedDays = days.trim();
      final normalizedType = type.trim();

      if (normalizedName.isEmpty || normalizedSubject.isEmpty || normalizedTeacher.isEmpty || normalizedDays.isEmpty) {
        return const ActionResult(false, 'أكمل الحقول الأساسية للدورة قبل الحفظ.');
      }

      final duplicate = await db.query(
        'groups_local',
        columns: ['id'],
        where: groupId == null ? 'name = ?' : 'name = ? AND id != ?',
        whereArgs: groupId == null ? [normalizedName] : [normalizedName, groupId],
        limit: 1,
      );
      if (duplicate.isNotEmpty) {
        return const ActionResult(false, 'يوجد اسم دورة محفوظ مسبقًا بنفس التسمية.');
      }

      final subjectId = await _ensureSubject(db, normalizedSubject);
      final teacherId = await _ensureTeacher(db, name: normalizedTeacher, subject: normalizedSubject);

      final payload = <String, Object?>{
        'name': normalizedName,
        'subject_id': subjectId,
        'teacher_id': teacherId,
        'period': period,
        'capacity': capacity < 1 ? 1 : capacity,
        'enrolled_count': enrolledCount < 0 ? 0 : enrolledCount,
        'waiting_count': waitingCount < 0 ? 0 : waitingCount,
        'status': status,
        'system': system,
        'days': normalizedDays,
        'room': normalizedRoom,
        'price': price < 0 ? 0 : price,
        'course_type': normalizedType,
        'sessions_done': sessionsDone < 0 ? 0 : sessionsDone,
        'sessions_total': sessionsTotal < 1 ? 1 : sessionsTotal,
        'installments': installments < 1 ? 1 : installments,
        'teacher_pct': teacherPct < 0 ? 0 : teacherPct,
        'finance_locked': financeLocked ? 1 : 0,
      };

      int savedId;
      if (groupId == null) {
        savedId = await db.insert('groups_local', payload);
        await _log(db, 'group.create', 'group', savedId, 'تم إنشاء دورة جديدة وحفظها في قاعدة البيانات المحلية.');
      } else {
        await db.update('groups_local', payload, where: 'id = ?', whereArgs: [groupId]);
        savedId = groupId;
        await _log(db, 'group.update', 'group', savedId, 'تم تعديل بيانات دورة محفوظة محليًا.');
      }

      await refresh();
      return ActionResult(true, groupId == null ? '✅ تم حفظ الدورة الجديدة في القاعدة المحلية.' : '✅ تم تحديث الدورة وحفظ التعديلات.');
    } catch (e) {
      return ActionResult(false, 'تعذر حفظ الدورة: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<CourseDetailsSnapshot> loadCourseDetails(int groupId) async {
    final group = groups.firstWhere((g) => g.id == groupId);
    final db = await _db.database;

    final studentRows = await db.rawQuery(
      '''
      SELECT
        s.id,
        s.code,
        s.full_name,
        s.phone,
        s.guardian,
        s.status,
        s.total_fee,
        s.balance_due,
        COALESCE(sm.financial_status, CASE WHEN ? = 'نظام ساعات' THEN 'دفع عند الجلسة' ELSE 'قيد الفوترة' END) AS financial_status,
        e.created_at AS enrolled_at
      FROM enrollments_local e
      JOIN students s ON s.id = e.student_id
      LEFT JOIN student_materials_local sm
        ON sm.student_id = s.id
       AND sm.subject = ?
       AND sm.teacher = ?
       AND sm.period = ?
      WHERE e.group_id = ?
      ORDER BY s.full_name
      ''',
      [group.system, group.subject, group.teacher, group.period, groupId],
    );

    final waitingRows = await db.rawQuery(
      '''
      SELECT
        w.id,
        s.code,
        s.full_name,
        s.phone,
        s.guardian,
        s.status,
        w.created_at
      FROM waiting_lists_local w
      JOIN students s ON s.id = w.student_id
      WHERE w.group_id = ?
      ORDER BY w.created_at DESC
      ''',
      [groupId],
    );

    return CourseDetailsSnapshot(
      group: group,
      students: studentRows.map(CourseStudentRecord.fromMap).toList(),
      waiting: waitingRows.map(CourseWaitingRecord.fromMap).toList(),
    );
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
      } else if (group.id != chosen?.id && group.seatsLeft > 0) {
        alternatives.add(group);
      }
    }

    return RegistrationPreview(chosenGroup: chosen, alternatives: alternatives);
  }

  ApprovalRoutingPlan approvalPlanForRequest(RegistrationRequestItem request) {
    final preferredGroup = _resolvePreferredGroup(request);
    final preferredState = _preferredState(preferredGroup);
    final alternatives = <GroupOption>[
      for (final group in groups)
        if (_looseMatch(group.subject, request.subjectName) &&
            group.period == request.period &&
            group.isOpenForRegistration &&
            group.seatsLeft > 0 &&
            group.id != preferredGroup?.id)
          group,
    ];

    return ApprovalRoutingPlan(
      request: request,
      preferredGroup: preferredGroup,
      alternatives: alternatives,
      preferredState: preferredState,
    );
  }

  Future<ActionResult> submitRequestByLabels({
    required int studentId,
    required String subjectName,
    required String teacherName,
    required String period,
  }) async {
    try {
      final db = await _db.database;
      final subjectId = await _ensureSubject(db, subjectName.trim());
      final teacherId = await _ensureTeacher(db, name: teacherName.trim(), subject: subjectName.trim());
      await refresh();
      return await submitRequest(
        studentId: studentId,
        subjectId: subjectId,
        teacherId: teacherId,
        period: period,
      );
    } catch (e) {
      return ActionResult(false, 'تعذر تجهيز طلب المادة: $e');
    }
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
      await _syncStudentsIfReady();
      final message = previewResult.isFull
          ? '⏳ تم حفظ الطلب. المجموعة المطلوبة ممتلئة وسيظهر للإدارة أنه مرشح للانتظار.'
          : (previewResult.hasExactGroup
              ? '✅ تم حفظ الطلب في قاعدة البيانات وإرساله للاعتماد الإداري.'
              : (previewResult.alternatives.isNotEmpty
                  ? '✅ تم حفظ الطلب. لا توجد دورة مطابقة حاليًا للمدرس المطلوب، وستظهر للإدارة دورات بديلة مفتوحة أو خيار وضع الطالب على الانتظار.'
                  : '✅ تم حفظ الطلب للمراجعة. لا توجد دورة مطابقة حاليًا وسيقرر المدير بين الانتظار أو الإبقاء عليه معلقًا.'));
      return ActionResult(true, message, status: 'معلق');
    } catch (e) {
      return ActionResult(false, 'تعذر حفظ الطلب: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<ActionResult> approveRequest(int requestId) async {
    final request = requestById(requestId);
    if (request == null) {
      return const ActionResult(false, 'الطلب غير موجود ضمن البيانات الحالية. حدّث الشاشة ثم حاول مجددًا.');
    }

    final plan = approvalPlanForRequest(request);
    if (!plan.canDirectApprove || plan.preferredGroup == null) {
      return const ActionResult(false, 'لا يمكن الاعتماد المباشر لهذا الطلب. اختر دورة بديلة مفتوحة أو ضع الطالب على قائمة الانتظار.');
    }

    return approveRequestToGroup(
      requestId,
      plan.preferredGroup!.id,
      note: 'تم اعتماد الطلب وتسجيل الطالب في الدورة المطلوبة.',
    );
  }

  Future<ActionResult> approveRequestToGroup(int requestId, int groupId, {String? note}) async {
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

      final group = await _groupByIdFromDb(db, groupId);
      if (group == null) {
        return const ActionResult(false, 'الدورة المحددة غير موجودة.');
      }
      if (!group.isOpenForRegistration) {
        return const ActionResult(false, 'هذه الدورة مغلقة حاليًا. اختر دورة أخرى مفتوحة أو ضع الطالب على الانتظار.');
      }
      if (group.isFull) {
        return const ActionResult(false, 'هذه الدورة امتلأت الآن. حدّث الخيارات ثم اختر بديلًا آخر أو الانتظار.');
      }

      final studentId = row['student_id'] as int;
      final requestedTeacherId = row['teacher_id'] as int?;
      final requestedTeacher = requestedTeacherId == null ? null : teacherById(requestedTeacherId);

      final enrollmentExists = await db.query(
        'enrollments_local',
        columns: ['id'],
        where: 'student_id = ? AND group_id = ?',
        whereArgs: [studentId, group.id],
        limit: 1,
      );
      if (enrollmentExists.isEmpty) {
        await db.insert(
          'enrollments_local',
          {
            'student_id': studentId,
            'group_id': group.id,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        await db.rawUpdate(
          'UPDATE groups_local SET enrolled_count = enrolled_count + 1 WHERE id = ?',
          [group.id],
        );
      }

      final materialExists = await db.query(
        'student_materials_local',
        columns: ['id'],
        where: 'student_id = ? AND subject = ? AND teacher = ? AND period = ? AND schedule = ?',
        whereArgs: [studentId, group.subject, group.teacher, group.period, group.days],
        limit: 1,
      );
      if (materialExists.isEmpty) {
        await db.insert(
          'student_materials_local',
          {
            'student_id': studentId,
            'subject': group.subject,
            'teacher': group.teacher,
            'period': group.period,
            'schedule': group.days,
            'attendance_pct': 0,
            'grade': '—',
            'financial_status': group.system == 'نظام ساعات' ? 'دفع عند الجلسة' : 'قيد الفوترة',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      final studentRows = await db.query(
        'students',
        columns: ['level', 'preferred_system'],
        where: 'id = ?',
        whereArgs: [studentId],
        limit: 1,
      );
      final currentLevel = studentRows.isEmpty ? '' : (studentRows.first['level'] as String? ?? '').trim();
      final currentSystem = studentRows.isEmpty ? '' : (studentRows.first['preferred_system'] as String? ?? '').trim();

      await db.update(
        'students',
        {
          'status': 'نشط',
          'preferred_period': group.period,
          'preferred_system': currentSystem.isEmpty
              ? group.system
              : (currentSystem == group.system ? currentSystem : 'متعدد'),
          'level': currentLevel.isEmpty || currentLevel == '—'
              ? group.subject
              : (currentLevel == group.subject ? currentLevel : 'عدة مواد'),
        },
        where: 'id = ?',
        whereArgs: [studentId],
      );

      final approvalNote = note ??
          (requestedTeacher != null && requestedTeacher.name == group.teacher
              ? 'تم اعتماد الطلب وتسجيل الطالب في الدورة المطلوبة.'
              : 'تم اعتماد الطلب وتحويل الطالب إلى دورة بديلة مفتوحة: ${group.name}.');

      await db.update(
        'registration_requests_local',
        {
          'status': 'معتمد',
          'target_group_id': group.id,
          'decision_note': approvalNote,
          'decided_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [requestId],
      );
      await _log(db, 'registration.approve', 'registration_request', requestId, approvalNote);

      final student = studentById(studentId);
      kNotifications.insert(
        0,
        NotificationItem(
          'تم اعتماد التسجيل',
          '${student?.name ?? 'طالب'} سُجّل في ${group.name} مع ${group.teacher}',
          'الآن',
          'request',
        ),
      );

      await refresh();
      await _syncStudentsIfReady();
      final direct = requestedTeacher != null && requestedTeacher.name == group.teacher;
      return ActionResult(
        true,
        direct
            ? '✅ تم اعتماد الطلب وتسجيل الطالب في الدورة المطلوبة داخل قاعدة البيانات.'
            : '✅ تم اعتماد الطلب وتحويل الطالب إلى دورة بديلة مفتوحة وحُفظ ذلك في القاعدة.',
        status: 'معتمد',
      );
    } catch (e) {
      return ActionResult(false, 'تعذر اعتماد الطلب: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<ActionResult> moveRequestToWaiting(int requestId, {String? note}) async {
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
      if (teacherId == null) {
        return const ActionResult(false, 'لا يوجد مدرس مفضّل محفوظ لهذا الطلب.');
      }

      final request = requestById(requestId);
      final plan = request == null ? null : approvalPlanForRequest(request);
      final preferredGroup = plan?.preferredGroup;
      final waitingGroupId = (preferredGroup != null && preferredGroup.isOpenForRegistration)
          ? preferredGroup.id
          : null;

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
            'group_id': waitingGroupId,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        if (waitingGroupId != null) {
          await db.rawUpdate(
            'UPDATE groups_local SET waiting_count = waiting_count + 1 WHERE id = ?',
            [waitingGroupId],
          );
        }
      }

      await db.update(
        'students',
        {
          'status': 'قائمة انتظار',
          'preferred_period': period,
        },
        where: 'id = ?',
        whereArgs: [studentId],
      );

      final waitingNote = note ??
          (plan?.preferredState == 'closed'
              ? 'بناءً على رغبة الطالب، وُضع على قائمة انتظار المادة مع المدرس المختار لأن الدورة مغلقة حاليًا.'
              : (plan?.preferredState == 'full'
                  ? 'بناءً على رغبة الطالب، وُضع على قائمة انتظار المادة مع المدرس المختار لأن الدورة مكتملة.'
                  : 'بناءً على رغبة الطالب، وُضع على قائمة انتظار المادة مع المدرس المختار.'));

      await db.update(
        'registration_requests_local',
        {
          'status': 'قائمة انتظار',
          'decision_note': waitingNote,
          'decided_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [requestId],
      );
      await _log(db, 'registration.waiting', 'registration_request', requestId, waitingNote);

      final teacher = teacherById(teacherId);
      kNotifications.insert(
        0,
        NotificationItem(
          'طلب نُقل إلى الانتظار',
          'تم وضع الطالب على قائمة انتظار ${teacher?.name ?? 'المدرس'} حسب رغبته.',
          'الآن',
          'waiting',
        ),
      );

      await refresh();
      await _syncStudentsIfReady();
      return const ActionResult(true, '⏳ تم وضع الطالب على قائمة الانتظار وربط ذلك بقاعدة البيانات.', status: 'قائمة انتظار');
    } catch (e) {
      return ActionResult(false, 'تعذر نقل الطلب إلى الانتظار: $e');
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
      await _syncStudentsIfReady();
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

  RegistrationRequestItem? requestById(int id) {
    for (final request in requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  GroupOption? groupById(int id) {
    for (final group in groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  String periodLabel(String value) {
    if (value == 'صباحي') return 'الفترة الصباحية';
    if (value == 'ظهر') return 'فترة الظهر';
    return 'الفترة المسائية';
  }

  GroupOption? _findAnyGroup({required int subjectId, required int? teacherId, required String period}) {
    final subject = subjectById(subjectId);
    final teacher = teacherId == null ? null : teacherById(teacherId);
    if (subject == null || teacher == null) return null;
    for (final group in groups) {
      if (_looseMatch(group.subject, subject.name) && group.teacher == teacher.name && group.period == period) {
        return group;
      }
    }
    return null;
  }

  GroupOption? _resolvePreferredGroup(RegistrationRequestItem request) {
    if (request.targetGroupId != null) {
      final savedGroup = groupById(request.targetGroupId!);
      if (savedGroup != null) return savedGroup;
    }
    return _findAnyGroup(subjectId: request.subjectId, teacherId: request.teacherId, period: request.period);
  }

  String _preferredState(GroupOption? group) {
    if (group == null) return 'missing';
    if (!group.isOpenForRegistration) return 'closed';
    if (group.isFull) return 'full';
    return 'available';
  }

  Future<GroupOption?> _groupByIdFromDb(Database db, int id) async {
    final rows = await db.query('v_groups_registration', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return GroupOption.fromMap(rows.first);
  }

  Future<int> _ensureSubject(Database db, String name) async {
    await db.insert('subjects', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
    final rows = await db.query('subjects', columns: ['id'], where: 'name = ?', whereArgs: [name], limit: 1);
    return rows.first['id'] as int;
  }

  Future<int> _ensureTeacher(Database db, {required String name, required String subject}) async {
    final exists = await db.query('teachers', columns: ['id'], where: 'full_name = ?', whereArgs: [name], limit: 1);
    if (exists.isNotEmpty) {
      return exists.first['id'] as int;
    }

    final source = teacherByName(name);
    await db.insert('teachers', {
      'full_name': name,
      'specialization': source?.subject ?? subject,
      'degree': source?.degree ?? '—',
      'mobile': source?.mobile ?? '',
      'whatsapp': source?.whatsapp ?? source?.mobile ?? '',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final rows = await db.query('teachers', columns: ['id'], where: 'full_name = ?', whereArgs: [name], limit: 1);
    return rows.first['id'] as int;
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

  Future<void> _syncStudentsIfReady() async {
    if (StudentStore.instance.isReady) {
      await StudentStore.instance.refresh();
    }
  }

  void _setBusy(bool value, {bool notify = true}) {
    _busy = value;
    if (notify) notifyListeners();
  }
}
