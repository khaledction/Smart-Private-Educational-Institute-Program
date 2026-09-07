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


  Future<String> databasePath() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/maehdi');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return '${dir.path}/maehdi_registration.db';
  }

  Future<void> resetAllData() async {
    final db = await database;
    await _clearAllTables(db);
    await db.insert(
      'app_meta',
      {'key': 'empty_start_v39_done', 'value': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Database> _open() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final path = await databasePath();
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _createSchema(db);
          if (oldVersion < 2) {
            await _migrateToV2(db);
          }
          if (oldVersion < 3) {
            await _migrateToV3(db);
          }
        },
        onOpen: (db) async {
          await _createSchema(db);
          await _migrateToV2(db);
          await _migrateToV3(db);
          await _ensureOneTimeEmptyStart(db);
        },
      ),
    );
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
        status TEXT NOT NULL DEFAULT 'نشط',
        phone TEXT,
        guardian TEXT,
        level TEXT,
        total_fee REAL NOT NULL DEFAULT 0,
        balance_due REAL NOT NULL DEFAULT 0,
        preferred_period TEXT,
        preferred_system TEXT
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
        course_type TEXT DEFAULT '',
        sessions_done INTEGER NOT NULL DEFAULT 0,
        sessions_total INTEGER NOT NULL DEFAULT 12,
        installments INTEGER NOT NULL DEFAULT 1,
        teacher_pct REAL NOT NULL DEFAULT 0,
        finance_locked INTEGER NOT NULL DEFAULT 0,
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
      CREATE TABLE IF NOT EXISTS student_materials_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        subject TEXT NOT NULL,
        teacher TEXT NOT NULL,
        period TEXT NOT NULL,
        schedule TEXT,
        attendance_pct INTEGER NOT NULL DEFAULT 0,
        grade TEXT DEFAULT '—',
        financial_status TEXT DEFAULT 'قيد التفعيل',
        UNIQUE(student_id, subject, teacher, period, schedule),
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
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
        g.price,
        g.course_type,
        g.sessions_done,
        g.sessions_total,
        g.installments,
        g.teacher_pct,
        g.finance_locked
      FROM groups_local g
      JOIN subjects sub ON sub.id = g.subject_id
      JOIN teachers t ON t.id = g.teacher_id
      ORDER BY g.id DESC
      ''',
      '''
      CREATE VIEW IF NOT EXISTS v_students AS
      SELECT
        s.id,
        s.code,
        s.full_name,
        s.status,
        s.phone,
        s.guardian,
        s.level,
        s.total_fee,
        s.balance_due,
        s.preferred_period,
        s.preferred_system,
        COALESCE((SELECT COUNT(*) FROM student_materials_local sm WHERE sm.student_id = s.id), 0) AS materials_count,
        COALESCE((SELECT ROUND(AVG(sm.attendance_pct)) FROM student_materials_local sm WHERE sm.student_id = s.id), 0) AS attendance_avg
      FROM students s
      ORDER BY s.full_name
      ''',
      '''
      CREATE VIEW IF NOT EXISTS v_student_materials AS
      SELECT
        sm.id,
        sm.student_id,
        sm.subject,
        sm.teacher,
        sm.period,
        sm.schedule,
        sm.attendance_pct,
        sm.grade,
        sm.financial_status
      FROM student_materials_local sm
      ORDER BY sm.id DESC
      ''',
    ];

    for (final statement in statements) {
      await db.execute(statement);
    }
  }

  Future<void> _migrateToV2(DatabaseExecutor db) async {
    final columns = await _tableColumns(db, 'students');
    if (!columns.contains('phone')) {
      await db.execute('ALTER TABLE students ADD COLUMN phone TEXT');
    }
    if (!columns.contains('guardian')) {
      await db.execute('ALTER TABLE students ADD COLUMN guardian TEXT');
    }
    if (!columns.contains('level')) {
      await db.execute('ALTER TABLE students ADD COLUMN level TEXT');
    }
    if (!columns.contains('total_fee')) {
      await db.execute('ALTER TABLE students ADD COLUMN total_fee REAL NOT NULL DEFAULT 0');
    }
    if (!columns.contains('balance_due')) {
      await db.execute('ALTER TABLE students ADD COLUMN balance_due REAL NOT NULL DEFAULT 0');
    }
    if (!columns.contains('preferred_period')) {
      await db.execute('ALTER TABLE students ADD COLUMN preferred_period TEXT');
    }
    if (!columns.contains('preferred_system')) {
      await db.execute('ALTER TABLE students ADD COLUMN preferred_system TEXT');
    }

    await db.execute('DROP VIEW IF EXISTS v_students');
    await db.execute('DROP VIEW IF EXISTS v_student_materials');
    await db.execute('DROP VIEW IF EXISTS v_groups_registration');
    await _createSchema(db);
  }

  Future<void> _migrateToV3(DatabaseExecutor db) async {
    final groupColumns = await _tableColumns(db, 'groups_local');
    if (!groupColumns.contains('course_type')) {
      await db.execute("ALTER TABLE groups_local ADD COLUMN course_type TEXT DEFAULT ''");
    }
    if (!groupColumns.contains('sessions_done')) {
      await db.execute('ALTER TABLE groups_local ADD COLUMN sessions_done INTEGER NOT NULL DEFAULT 0');
    }
    if (!groupColumns.contains('sessions_total')) {
      await db.execute('ALTER TABLE groups_local ADD COLUMN sessions_total INTEGER NOT NULL DEFAULT 12');
    }
    if (!groupColumns.contains('installments')) {
      await db.execute('ALTER TABLE groups_local ADD COLUMN installments INTEGER NOT NULL DEFAULT 1');
    }
    if (!groupColumns.contains('teacher_pct')) {
      await db.execute('ALTER TABLE groups_local ADD COLUMN teacher_pct REAL NOT NULL DEFAULT 0');
    }
    if (!groupColumns.contains('finance_locked')) {
      await db.execute('ALTER TABLE groups_local ADD COLUMN finance_locked INTEGER NOT NULL DEFAULT 0');
    }

    await db.execute('DROP VIEW IF EXISTS v_groups_registration');
    await _createSchema(db);
  }

  Future<void> _ensureOneTimeEmptyStart(Database db) async {
    const key = 'empty_start_v39_done';
    final rows = await db.query('app_meta', columns: ['value'], where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isNotEmpty) return;
    await _clearAllTables(db);
    await db.insert(
      'app_meta',
      {'key': key, 'value': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _clearAllTables(Database db) async {
    await db.transaction((txn) async {
      await txn.delete('waiting_lists_local');
      await txn.delete('enrollments_local');
      await txn.delete('registration_requests_local');
      await txn.delete('student_materials_local');
      await txn.delete('groups_local');
      await txn.delete('students');
      await txn.delete('teachers');
      await txn.delete('subjects');
      await txn.delete('audit_logs_local');
      await txn.delete('app_meta');
      await txn.execute('DELETE FROM sqlite_sequence');
    });
  }

  Future<Set<String>> _tableColumns(DatabaseExecutor db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((e) => (e['name'] as String).trim()).toSet();
  }

  Future<void> _seedIfNeeded(Database db) async {
    await _seedCoreDataIfNeeded(db);
    await _seedStudentProfilesIfNeeded(db);
    await _seedRegistrationIfNeeded(db);
  }

  Future<void> _seedAll(DatabaseExecutor db) async {
    await _seedCoreData(db);
    await _seedStudentProfiles(db);
    await _seedRegistrationData(db);
  }

  Future<void> _seedCoreDataIfNeeded(Database db) async {
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['core_seed_v1'],
      limit: 1,
    );
    if (rows.isEmpty) {
      await db.transaction((txn) async {
        await _seedCoreData(txn);
      });
    }
  }

  Future<void> _seedStudentProfilesIfNeeded(Database db) async {
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['student_profiles_seed_v1'],
      limit: 1,
    );
    if (rows.isEmpty) {
      await db.transaction((txn) async {
        await _seedStudentProfiles(txn);
      });
    }
  }

  Future<void> _seedRegistrationIfNeeded(Database db) async {
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['registration_seed_v1'],
      limit: 1,
    );
    if (rows.isEmpty) {
      await db.transaction((txn) async {
        await _seedRegistrationData(txn);
      });
    }
  }

  Future<void> _seedCoreData(DatabaseExecutor db) async {
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
        {
          'code': student.code,
          'full_name': student.name,
          'status': student.status,
          'phone': student.phone,
          'guardian': student.guardian,
          'level': student.level,
          'total_fee': student.totalFee,
          'balance_due': student.balanceDue,
          'preferred_period': student.materials.isNotEmpty ? student.materials.first.period : 'مسائي',
          'preferred_system': _inferStudentSystem(student),
        },
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

    await db.insert(
      'app_meta',
      {'key': 'core_seed_v1', 'value': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _seedStudentProfiles(DatabaseExecutor db) async {
    final students = await db.query('students');
    final studentCodeToId = {
      for (final row in students) row['code'] as String: row['id'] as int,
    };

    for (final student in kStudents) {
      await db.update(
        'students',
        {
          'phone': student.phone,
          'guardian': student.guardian,
          'level': student.level,
          'total_fee': student.totalFee,
          'balance_due': student.balanceDue,
          'preferred_period': student.materials.isNotEmpty ? student.materials.first.period : 'مسائي',
          'preferred_system': _inferStudentSystem(student),
        },
        where: "code = ? AND (phone IS NULL OR phone = '' OR guardian IS NULL OR guardian = '' OR level IS NULL OR level = '')",
        whereArgs: [student.code],
      );

      final studentId = studentCodeToId[student.code];
      if (studentId == null) continue;
      for (final material in student.materials) {
        await db.insert(
          'student_materials_local',
          {
            'student_id': studentId,
            'subject': material.subject,
            'teacher': material.teacher,
            'period': material.period,
            'schedule': material.schedule,
            'attendance_pct': material.attendancePct,
            'grade': material.grade,
            'financial_status': material.financial,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    await db.insert(
      'app_meta',
      {'key': 'student_profiles_seed_v1', 'value': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _seedRegistrationData(DatabaseExecutor db) async {
    final students = await db.query('students');
    final groups = await db.query('v_groups_registration');
    final subjects = await db.query('subjects');
    final teachers = await db.query('teachers');

    final studentCodeToId = {
      for (final row in students) row['code'] as String: row['id'] as int,
    };
    final subjectMap = {
      for (final row in subjects) row['name'] as String: row['id'] as int,
    };
    final teacherMap = {
      for (final row in teachers) row['full_name'] as String: row['id'] as int,
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

  String _inferStudentSystem(Student student) {
    final source = '${student.level} ${student.materials.map((m) => m.subject).join(' ')}';
    return source.contains('ساعات') ? 'نظام ساعات' : 'كورس كامل';
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
