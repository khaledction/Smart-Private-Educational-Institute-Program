import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'mock_data.dart';

class LocalRegistrationDb {
  LocalRegistrationDb._();
  static final LocalRegistrationDb instance = LocalRegistrationDb._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _open() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/maehdi');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final path = '${dir.path}/maehdi_registration.db';
    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
          await _seed(db);
        },
        onOpen: (db) async {
          await _createSchema(db);
          await _seedIfNeeded(db);
        },
      ),
    );

    return db;
  }

  Future<void> _createSchema(DatabaseExecutor db) async {
    const statements = <String>[
      '''
      CREATE TABLE IF NOT EXISTS app_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'نشط'
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL UNIQUE,
        specialization TEXT NOT NULL,
        degree TEXT,
        mobile TEXT,
        whatsapp TEXT
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS groups_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        subject_id INTEGER NOT NULL,
        teacher_id INTEGER NOT NULL,
        period TEXT NOT NULL,
        capacity INTEGER NOT NULL DEFAULT 12,
        enrolled_count INTEGER NOT NULL DEFAULT 0,
        waiting_count INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'open',
        system TEXT NOT NULL DEFAULT 'كورس كامل',
        days TEXT,
        room TEXT,
        price REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (subject_id) REFERENCES subjects(id),
        FOREIGN KEY (teacher_id) REFERENCES teachers(id)
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS registration_requests_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        teacher_id INTEGER,
        period TEXT NOT NULL,
        target_group_id INTEGER,
        status TEXT NOT NULL DEFAULT 'معلق',
        decision_note TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        decided_at TEXT,
        FOREIGN KEY (student_id) REFERENCES students(id),
        FOREIGN KEY (subject_id) REFERENCES subjects(id),
        FOREIGN KEY (teacher_id) REFERENCES teachers(id),
        FOREIGN KEY (target_group_id) REFERENCES groups_local(id)
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS waiting_lists_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        teacher_id INTEGER NOT NULL,
        period TEXT NOT NULL,
        group_id INTEGER,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(student_id, subject_id, teacher_id, period),
        FOREIGN KEY (student_id) REFERENCES students(id),
        FOREIGN KEY (subject_id) REFERENCES subjects(id),
        FOREIGN KEY (teacher_id) REFERENCES teachers(id),
        FOREIGN KEY (group_id) REFERENCES groups_local(id)
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS enrollments_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(student_id, group_id),
        FOREIGN KEY (student_id) REFERENCES students(id),
        FOREIGN KEY (group_id) REFERENCES groups_local(id)
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS audit_logs_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER,
        details TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''',
      '''
      CREATE VIEW IF NOT EXISTS v_registration_requests AS
      SELECT
        r.id,
        s.full_name AS student_name,
        s.code AS student_code,
        sub.name AS subject_name,
        COALESCE(t.full_name, '—') AS teacher_name,
        r.period,
        r.status,
        r.decision_note,
        r.created_at,
        r.decided_at,
        r.student_id,
        r.subject_id,
        r.teacher_id,
        r.target_group_id
      FROM registration_requests_local r
      JOIN students s ON s.id = r.student_id
      JOIN subjects sub ON sub.id = r.subject_id
      LEFT JOIN teachers t ON t.id = r.teacher_id
      ORDER BY r.id DESC
      ''',
      '''
      CREATE VIEW IF NOT EXISTS v_waiting_list AS
      SELECT
        w.id,
        s.full_name AS student_name,
        s.code AS student_code,
        sub.name AS subject_name,
        t.full_name AS teacher_name,
        w.period,
        w.created_at,
        w.student_id,
        w.subject_id,
        w.teacher_id,
        w.group_id
      FROM waiting_lists_local w
      JOIN students s ON s.id = w.student_id
      JOIN subjects sub ON sub.id = w.subject_id
      JOIN teachers t ON t.id = w.teacher_id
      ORDER BY w.id DESC
      ''',
      '''
      CREATE VIEW IF NOT EXISTS v_groups_registration AS
      SELECT
        g.id,
        g.name,
        sub.name AS subject_name,
        t.full_name AS teacher_name,
        g.period,
        g.capacity,
        g.enrolled_count,
        g.waiting_count,
        g.status,
        g.system,
        g.days,
        g.room,
        g.price
      FROM groups_local g
      JOIN subjects sub ON sub.id = g.subject_id
      JOIN teachers t ON t.id = g.teacher_id
      ORDER BY g.id DESC
      ''',
    ];

    for (final statement in statements) {
      await db.execute(statement);
    }
  }

  Future<void> _seedIfNeeded(Database db) async {
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['registration_seed_v1'],
      limit: 1,
    );
    if (rows.isNotEmpty) return;

    await db.transaction((txn) async {
      await _seed(txn);
    });
  }

  Future<void> _seed(DatabaseExecutor db) async {
    final subjectNames = <String>{
      ...kSubjectNames,
      ...kGroups.map((g) => g.subject),
      ...kWaiting.map((w) => _normalizeSeedSubject(w.subject)),
      ...kRequests.map((r) => _normalizeSeedSubject(r.subject)),
    };

    for (final name in subjectNames) {
      await db.insert('subjects', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    for (final student in kStudents) {
      await db.insert(
        'students',
        {'code': student.code, 'full_name': student.name, 'status': student.status},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    for (final teacher in kTeachers) {
      await db.insert(
        'teachers',
        {
          'full_name': teacher.name,
          'specialization': teacher.subject,
          'degree': teacher.degree,
          'mobile': teacher.mobile,
          'whatsapp': teacher.whatsapp,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final subjects = await db.query('subjects');
    final teachers = await db.query('teachers');
    final subjectMap = {
      for (final row in subjects) row['name'] as String: row['id'] as int,
    };
    final teacherMap = {
      for (final row in teachers) row['full_name'] as String: row['id'] as int,
    };

    for (final group in kGroups) {
      final subjectId = _subjectIdForLabel(subjectMap, group.subject);
      final teacherId = teacherMap[group.teacher];
      if (subjectId == null || teacherId == null) continue;
      await db.insert(
        'groups_local',
        {
          'name': group.name,
          'subject_id': subjectId,
          'teacher_id': teacherId,
          'period': group.period,
          'capacity': group.capacity,
          'enrolled_count': group.enrolled,
          'waiting_count': group.waiting,
          'status': group.status,
          'system': group.system,
          'days': group.days,
          'room': group.room,
          'price': group.price.toDouble(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final students = await db.query('students');
    final groups = await db.query('v_groups_registration');
    final studentCodeToId = {
      for (final row in students) row['code'] as String: row['id'] as int,
    };
    final groupMap = {
      for (final row in groups)
        _groupKey(
          subject: row['subject_name'] as String,
          teacher: row['teacher_name'] as String,
          period: row['period'] as String,
        ): row['id'] as int,
    };

    for (final request in kRequests) {
      final studentCode = _extractCode(request.student);
      final teacherName = request.teacher;
      final subjectName = _normalizeSeedSubject(request.subject);
      final studentId = studentCodeToId[studentCode];
      final subjectId = _subjectIdForLabel(subjectMap, subjectName);
      final teacherId = teacherMap[teacherName];
      if (studentId == null || subjectId == null) continue;
      await db.insert(
        'registration_requests_local',
        {
          'student_id': studentId,
          'subject_id': subjectId,
          'teacher_id': teacherId,
          'period': request.period,
          'target_group_id': groupMap[_groupKey(subject: subjectName, teacher: teacherName, period: request.period)],
          'status': request.status,
          'created_at': request.date,
          'decision_note': request.status == 'معتمد'
              ? 'تمت تهيئة الطلب من البيانات التجريبية'
              : (request.status == 'مرفوض' ? 'مرفوض من البيانات التجريبية' : null),
          'decided_at': request.status == 'معلق' ? null : request.date,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    for (final waiting in kWaiting) {
      final studentCode = _extractCode(waiting.student);
      final subjectName = _normalizeSeedSubject(waiting.subject);
      final studentId = studentCodeToId[studentCode];
      final teacherId = teacherMap[waiting.teacher];
      final subjectId = _subjectIdForLabel(subjectMap, subjectName);
      if (studentId == null || teacherId == null || subjectId == null) continue;
      await db.insert(
        'waiting_lists_local',
        {
          'student_id': studentId,
          'subject_id': subjectId,
          'teacher_id': teacherId,
          'period': waiting.period,
          'group_id': groupMap[_groupKey(subject: subjectName, teacher: waiting.teacher, period: waiting.period)],
          'created_at': _seedWaitDate(waiting.since),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await db.insert(
      'app_meta',
      {'key': 'registration_seed_v1', 'value': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _extractCode(String text) {
    final idx = text.lastIndexOf('ST-');
    if (idx == -1) return text.trim();
    return text.substring(idx).trim();
  }

  String _normalizeSeedSubject(String text) {
    if (text.contains('الألمانية')) return 'الألمانية';
    if (text.contains('الإنجليزية')) return 'اللغة الإنجليزية';
    if (text.contains('المحادثة')) return 'المحادثة';
    if (text.contains('المحاسبة')) return 'المحاسبة';
    if (text.contains('الرياضيات')) return 'الرياضيات';
    if (text.contains('الفيزياء')) return 'الفيزياء';
    if (text.contains('تأسيس')) return 'التأسيس';
    return text.trim();
  }

  int? _subjectIdForLabel(Map<String, int> subjectMap, String label) {
    if (subjectMap.containsKey(label)) return subjectMap[label];
    final target = _canonical(label);
    for (final entry in subjectMap.entries) {
      if (_canonical(entry.key) == target) return entry.value;
    }
    for (final entry in subjectMap.entries) {
      if (_looseMatch(entry.key, label)) return entry.value;
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

  String _groupKey({required String subject, required String teacher, required String period}) {
    return '${_canonical(subject)}|${teacher.trim()}|${period.trim()}';
  }

  String _seedWaitDate(String since) {
    final now = DateTime.now();
    if (since.contains('6')) return now.subtract(const Duration(days: 6)).toIso8601String();
    if (since.contains('4')) return now.subtract(const Duration(days: 4)).toIso8601String();
    if (since.contains('3')) return now.subtract(const Duration(days: 3)).toIso8601String();
    if (since.contains('يومين')) return now.subtract(const Duration(days: 2)).toIso8601String();
    if (since.contains('يوم')) return now.subtract(const Duration(days: 1)).toIso8601String();
    return now.toIso8601String();
  }
}
