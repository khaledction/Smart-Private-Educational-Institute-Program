import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'local_registration_db.dart';
import 'mock_data.dart';

class StudentMaterialRecord {
  final int id;
  final int studentId;
  final String subject;
  final String teacher;
  final String period;
  final String schedule;
  final int attendancePct;
  final String grade;
  final String financialStatus;

  const StudentMaterialRecord({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.teacher,
    required this.period,
    required this.schedule,
    required this.attendancePct,
    required this.grade,
    required this.financialStatus,
  });

  factory StudentMaterialRecord.fromMap(Map<String, Object?> map) => StudentMaterialRecord(
        id: map['id'] as int,
        studentId: map['student_id'] as int,
        subject: map['subject'] as String? ?? '—',
        teacher: map['teacher'] as String? ?? '—',
        period: map['period'] as String? ?? 'مسائي',
        schedule: map['schedule'] as String? ?? '—',
        attendancePct: (map['attendance_pct'] as num?)?.round() ?? 0,
        grade: map['grade'] as String? ?? '—',
        financialStatus: map['financial_status'] as String? ?? 'قيد التفعيل',
      );
}

class StudentRecord {
  final int id;
  final String code;
  final String name;
  final String level;
  final String phone;
  final String guardian;
  final String status;
  final double totalFee;
  final double balanceDue;
  final String preferredPeriod;
  final String preferredSystem;
  final int materialsCount;
  final int attendanceAvg;
  final List<StudentMaterialRecord> materials;

  const StudentRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.level,
    required this.phone,
    required this.guardian,
    required this.status,
    required this.totalFee,
    required this.balanceDue,
    required this.preferredPeriod,
    required this.preferredSystem,
    required this.materialsCount,
    required this.attendanceAvg,
    required this.materials,
  });

  factory StudentRecord.fromMap(Map<String, Object?> map, List<StudentMaterialRecord> materials) => StudentRecord(
        id: map['id'] as int,
        code: map['code'] as String,
        name: map['full_name'] as String,
        level: map['level'] as String? ?? '—',
        phone: map['phone'] as String? ?? '—',
        guardian: map['guardian'] as String? ?? '—',
        status: map['status'] as String? ?? 'نشط',
        totalFee: (map['total_fee'] as num?)?.toDouble() ?? 0.0,
        balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0.0,
        preferredPeriod: map['preferred_period'] as String? ?? 'مسائي',
        preferredSystem: map['preferred_system'] as String? ?? 'كورس كامل',
        materialsCount: (map['materials_count'] as num?)?.round() ?? materials.length,
        attendanceAvg: (map['attendance_avg'] as num?)?.round() ?? 0,
        materials: materials,
      );
}

class StudentActionResult {
  final bool ok;
  final String message;
  final int? studentId;
  final String? studentCode;
  const StudentActionResult(this.ok, this.message, {this.studentId, this.studentCode});
}

class StudentStore extends ChangeNotifier {
  StudentStore._();
  static final StudentStore instance = StudentStore._();

  final LocalRegistrationDb _db = LocalRegistrationDb.instance;

  bool _ready = false;
  bool _busy = false;
  String? _error;
  List<StudentRecord> students = const [];

  bool get isReady => _ready;
  bool get isBusy => _busy;
  String? get error => _error;
  int get activeCount => students.where((s) => s.status == 'نشط').length;

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
    final studentRows = await db.query('v_students');
    final materialRows = await db.query('v_student_materials');

    final byStudent = <int, List<StudentMaterialRecord>>{};
    for (final row in materialRows) {
      final material = StudentMaterialRecord.fromMap(row);
      byStudent.putIfAbsent(material.studentId, () => <StudentMaterialRecord>[]).add(material);
    }

    students = [
      for (final row in studentRows)
        StudentRecord.fromMap(row, byStudent[row['id'] as int] ?? const []),
    ];
    notifyListeners();
  }

  Future<StudentActionResult> addStudent({
    required String name,
    required String phone,
    required String guardian,
    required String subject,
    required String period,
    required String system,
    required double fee,
  }) async {
    return _createStudentProfile(
      name: name,
      phone: phone,
      guardian: guardian,
      subject: subject,
      period: period,
      system: system,
      fee: fee,
    );
  }

  Future<StudentActionResult> createStudentProfile({
    required String name,
    required String phone,
    required String guardian,
    required String subject,
    required String period,
    required String system,
  }) async {
    return _createStudentProfile(
      name: name,
      phone: phone,
      guardian: guardian,
      subject: subject,
      period: period,
      system: system,
      fee: 0,
    );
  }

  Future<StudentActionResult> _createStudentProfile({
    required String name,
    required String phone,
    required String guardian,
    required String subject,
    required String period,
    required String system,
    required double fee,
  }) async {
    try {
      _setBusy(true);
      final db = await _db.database;
      final normalizedName = name.trim();
      final normalizedPhone = phone.trim();
      final normalizedGuardian = guardian.trim().isEmpty ? '—' : guardian.trim();
      final normalizedSubject = subject.trim();

      final duplicate = await db.query(
        'students',
        columns: ['id'],
        where: 'full_name = ? AND phone = ?',
        whereArgs: [normalizedName, normalizedPhone],
        limit: 1,
      );
      if (duplicate.isNotEmpty) {
        return const StudentActionResult(false, 'يوجد طالب محفوظ بنفس الاسم ورقم الهاتف.');
      }

      await db.insert('subjects', {'name': normalizedSubject}, conflictAlgorithm: ConflictAlgorithm.ignore);

      final nextCode = await _nextStudentCode(db);
      final id = await db.insert('students', {
        'code': nextCode,
        'full_name': normalizedName,
        'status': 'نشط',
        'phone': normalizedPhone,
        'guardian': normalizedGuardian,
        'level': normalizedSubject,
        'total_fee': fee,
        'balance_due': fee,
        'preferred_period': period,
        'preferred_system': system,
      });

      await _log(db, 'student.create', 'student', id,
          fee > 0
              ? 'تم إنشاء سجل طالب جديد وحفظه محليًا مع تفعيل ملفه وربط الرسم الأولي.'
              : 'تم إنشاء سجل طالب جديد وحفظه محليًا مع فتح ملفه لإضافة مواد متعددة.');

      kNotifications.insert(
        0,
        NotificationItem('طالب جديد', '$normalizedName أُضيف إلى سجلات الطلاب المحلية.', 'الآن', 'request'),
      );

      await refresh();
      return StudentActionResult(
        true,
        fee > 0
            ? '✅ تم حفظ الطالب برقم $nextCode داخل قاعدة البيانات المحلية.'
            : '✅ تم إنشاء ملف الطالب برقم $nextCode، ويمكنك الآن متابعة إضافة المواد.',
        studentId: id,
        studentCode: nextCode,
      );
    } catch (e) {
      return StudentActionResult(false, 'تعذر حفظ الطالب: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<StudentActionResult> addRequestedAmount({
    required int studentId,
    required String subject,
    required String period,
    required String system,
    required double amount,
  }) async {
    try {
      _setBusy(true);
      final db = await _db.database;
      final rows = await db.query(
        'students',
        columns: ['code', 'total_fee', 'balance_due', 'level', 'preferred_system'],
        where: 'id = ?',
        whereArgs: [studentId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const StudentActionResult(false, 'الطالب غير موجود.');
      }

      final row = rows.first;
      final currentTotal = (row['total_fee'] as num?)?.toDouble() ?? 0.0;
      final currentBalance = (row['balance_due'] as num?)?.toDouble() ?? 0.0;
      final currentLevel = (row['level'] as String? ?? '').trim();
      final currentSystem = (row['preferred_system'] as String? ?? '').trim();
      final normalizedSubject = subject.trim();
      final normalizedSystem = system.trim();

      await db.update(
        'students',
        {
          'level': currentLevel.isEmpty || currentLevel == '—'
              ? normalizedSubject
              : (currentLevel == normalizedSubject ? currentLevel : 'عدة مواد'),
          'preferred_period': period,
          'preferred_system': currentSystem.isEmpty
              ? normalizedSystem
              : (currentSystem == normalizedSystem ? currentSystem : 'متعدد'),
          'total_fee': currentTotal + amount,
          'balance_due': currentBalance + amount,
        },
        where: 'id = ?',
        whereArgs: [studentId],
      );

      await _log(db, 'student.fee.append', 'student', studentId,
          'تمت إضافة مبلغ ${amount.toStringAsFixed(0)} ل.س إلى ذمة الطالب بسبب مادة جديدة: $normalizedSubject.');

      await refresh();
      return StudentActionResult(
        true,
        '✅ تم تحديث المطلوب من الطالب بعد إضافة مادة $normalizedSubject.',
        studentId: studentId,
        studentCode: row['code'] as String?,
      );
    } catch (e) {
      return StudentActionResult(false, 'تعذر تحديث المطلوب من الطالب: $e');
    } finally {
      _setBusy(false);
    }
  }

  StudentRecord? byId(int id) {
    for (final student in students) {
      if (student.id == id) return student;
    }
    return null;
  }

  Future<String> _nextStudentCode(Database db) async {
    final rows = await db.query('students', columns: ['code']);
    var maxCode = 1053;
    for (final row in rows) {
      final code = (row['code'] as String? ?? '').trim();
      final match = RegExp(r'^ST-(\d+)$').firstMatch(code);
      if (match == null) continue;
      final value = int.tryParse(match.group(1)!) ?? 0;
      if (value > maxCode) maxCode = value;
    }
    return 'ST-${maxCode + 1}';
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
